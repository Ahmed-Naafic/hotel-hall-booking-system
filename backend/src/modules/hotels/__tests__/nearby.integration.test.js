import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import * as applicationService from '../application.service.js'
import * as hotelService from '../hotel.service.js'
import { haversineDistanceKm } from '../../../shared/utils/geo.js'

/**
 * Integration tests for Nearby Hotels (Customer Mobile, approved V1
 * business rules) — real Prisma queries against a real test database, same
 * `createApp()` + real `fetch` pattern as hotels.integration.test.js.
 */

let server
let baseUrl
let adminStubUserId

const EARTH_RADIUS_KM = 6371
const BASE = { latitude: -1.286389, longitude: 36.817223 }

function uniqueMobileNumber() {
  const suffix = Math.floor(100000000 + Math.random() * 899999999)
  return `+1${suffix}`
}

async function post(path, body, headers = {}) {
  const res = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...headers },
    body: body === undefined ? undefined : JSON.stringify(body),
  })
  const text = await res.text()
  return { status: res.status, body: text ? JSON.parse(text) : undefined }
}

async function get(path, headers = {}) {
  const res = await fetch(`${baseUrl}${path}`, { headers })
  const text = await res.text()
  return { status: res.status, body: text ? JSON.parse(text) : undefined }
}

async function patch(path, body, headers = {}) {
  const res = await fetch(`${baseUrl}${path}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', ...headers },
    body: body === undefined ? undefined : JSON.stringify(body),
  })
  const text = await res.text()
  return { status: res.status, body: text ? JSON.parse(text) : undefined }
}

function authHeader(token) {
  return { Authorization: `Bearer ${token}` }
}

async function registerAndLoginHotelManager() {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  // BDR-019: Full Name is required at registration for a HOTEL_MANAGER account.
  await post('/api/v1/auth/register', { mobileNumber, password, accountType: 'HOTEL_MANAGER', fullName: 'Test Manager' })
  // Login answers with a texted code instead of a session now; the suite
  // pins that code in scripts/testEnv.js.
  await post('/api/v1/auth/login', { mobileNumber, password })
  const loginRes = await post('/api/v1/auth/login/verify', { mobileNumber, code: '123456' })
  return loginRes.body.data
}

async function createPlatformAdministrator() {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  const argon2 = await import('argon2')
  const passwordHash = await argon2.hash(password)
  return prisma.user.create({
    data: { mobileNumber, passwordHash, accountType: 'PLATFORM_ADMINISTRATOR', isVerified: true },
  })
}

function completeHotelProfile(overrides = {}) {
  return {
    name: 'Nearby Test Hotel',
    description: 'A Hotel used only for Nearby Hotels integration tests.',
    location: { latitude: BASE.latitude, longitude: BASE.longitude, address: 'Test Address' },
    contactPhone: '+15550001111',
    ...overrides,
  }
}

async function prismaOpenApplicationId(hotelId) {
  const application = await prisma.hotelApplication.findFirst({
    where: { hotelId, status: 'OPEN' },
    orderBy: { createdAt: 'desc' },
  })
  return application.id
}

/** Registers, completes profile with the given location override, and approves — returns the Hotel id. */
async function approveHotelAt(locationOverride) {
  const { accessToken } = await registerAndLoginHotelManager()
  const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))
  const hotelId = created.data.id
  await patch(
    `/api/v1/hotels/${hotelId}`,
    completeHotelProfile(locationOverride ? { location: locationOverride } : {}),
    authHeader(accessToken),
  )
  await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
  const hotel = await hotelService.getHotelById(hotelId)
  await applicationService.recordDecision(hotel, await prismaOpenApplicationId(hotelId), 'APPROVED', adminStubUserId)
  return hotelId
}

/** A point exactly `km` due north of BASE — exact for the Haversine formula (pure meridian travel). */
function pointNorthOfBase(km) {
  const dLatRad = km / EARTH_RADIUS_KM
  return { latitude: BASE.latitude + (dLatRad * 180) / Math.PI, longitude: BASE.longitude, address: 'Offset Address' }
}

before(async () => {
  const app = createApp()
  server = app.listen(0)
  await new Promise((resolve) => server.once('listening', resolve))
  const { port } = server.address()
  baseUrl = `http://127.0.0.1:${port}`

  const admin = await createPlatformAdministrator()
  adminStubUserId = admin.id
})

after(async () => {
  await new Promise((resolve) => server.close(resolve))
})

describe('GET /hotels/public/nearby', () => {
  test('rejects a request with missing coordinates', async () => {
    const res = await get('/api/v1/hotels/public/nearby')
    assert.equal(res.status, 400)
    assert.equal(res.body.error, 'VALIDATION_ERROR')
  })

  test('rejects a request with invalid latitude/longitude', async () => {
    const res = await get('/api/v1/hotels/public/nearby?latitude=999&longitude=999')
    assert.equal(res.status, 400)
  })

  test('rejects non-numeric coordinate values', async () => {
    const res = await get('/api/v1/hotels/public/nearby?latitude=abc&longitude=xyz')
    assert.equal(res.status, 400)
  })

  test('returns an empty list when no Hotel is within 5km (runs before any Hotel is seeded near BASE)', async () => {
    // A point far enough from BASE (~1000km+) that none of this file's later fixtures can collide with it.
    const res = await get('/api/v1/hotels/public/nearby?latitude=51.5072&longitude=-0.1276')
    assert.equal(res.status, 200)
    assert.deepEqual(res.body.data, [])
  })

  test('valid coordinates with a Hotel just inside 5km returns it with correct distance', async () => {
    const hotelId = await approveHotelAt(pointNorthOfBase(4.5))
    const res = await get(`/api/v1/hotels/public/nearby?latitude=${BASE.latitude}&longitude=${BASE.longitude}`)
    assert.equal(res.status, 200)
    const match = res.body.data.find((h) => h.id === hotelId)
    assert.ok(match, 'expected the Hotel 4.5km away to be included')
    assert.ok(Math.abs(match.distanceKm - 4.5) < 0.05, `expected ~4.5km, got ${match.distanceKm}`)
  })

  test('a Hotel just outside 5km is excluded', async () => {
    const hotelId = await approveHotelAt(pointNorthOfBase(5.5))
    const res = await get(`/api/v1/hotels/public/nearby?latitude=${BASE.latitude}&longitude=${BASE.longitude}`)
    assert.equal(res.status, 200)
    assert.equal(res.body.data.some((h) => h.id === hotelId), false)
  })

  test('a Hotel just inside the 4.99km boundary is included; just outside 5.01km is excluded', async () => {
    const insideId = await approveHotelAt(pointNorthOfBase(4.99))
    const outsideId = await approveHotelAt(pointNorthOfBase(5.01))
    const res = await get(`/api/v1/hotels/public/nearby?latitude=${BASE.latitude}&longitude=${BASE.longitude}`)
    assert.equal(res.status, 200)
    assert.equal(res.body.data.some((h) => h.id === insideId), true)
    assert.equal(res.body.data.some((h) => h.id === outsideId), false)
  })

  test('multiple Hotels are sorted nearest-first', async () => {
    const farId = await approveHotelAt(pointNorthOfBase(4))
    const nearId = await approveHotelAt(pointNorthOfBase(1))
    const midId = await approveHotelAt(pointNorthOfBase(2.5))
    const res = await get(`/api/v1/hotels/public/nearby?latitude=${BASE.latitude}&longitude=${BASE.longitude}`)
    assert.equal(res.status, 200)
    const order = res.body.data.map((h) => h.id).filter((id) => [farId, nearId, midId].includes(id))
    assert.deepEqual(order, [nearId, midId, farId])
  })

  test('a non-APPROVED_ACTIVE Hotel (still UNDER_REVIEW) is excluded even with valid coordinates', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))
    const hotelId = created.data.id
    await patch(`/api/v1/hotels/${hotelId}`, completeHotelProfile(pointNorthOfBase(1)), authHeader(accessToken))
    await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
    // Deliberately not approved — stays UNDER_REVIEW.

    const res = await get(`/api/v1/hotels/public/nearby?latitude=${BASE.latitude}&longitude=${BASE.longitude}`)
    assert.equal(res.status, 200)
    assert.equal(res.body.data.some((h) => h.id === hotelId), false)
  })

  test('an APPROVED_ACTIVE Hotel with missing/invalid coordinates is excluded, not treated as a match', async () => {
    const hotelId = await approveHotelAt(pointNorthOfBase(1))
    // Corrupt the location to the legacy pre-BDR-017 plain-string shape directly (bypassing profile
    // validation, which is intentional here — simulating pre-existing data, not a new write path).
    await prisma.hotel.update({
      where: { id: hotelId },
      data: { profileData: { name: 'Nearby Test Hotel', location: 'Just a plain address string' } },
    })

    const res = await get(`/api/v1/hotels/public/nearby?latitude=${BASE.latitude}&longitude=${BASE.longitude}`)
    assert.equal(res.status, 200)
    assert.equal(res.body.data.some((h) => h.id === hotelId), false)
  })

  test('the returned distanceKm matches an independent Haversine computation', async () => {
    const point = pointNorthOfBase(3)
    const hotelId = await approveHotelAt(point)
    const res = await get(`/api/v1/hotels/public/nearby?latitude=${BASE.latitude}&longitude=${BASE.longitude}`)
    const match = res.body.data.find((h) => h.id === hotelId)
    const expected = haversineDistanceKm({
      lat1: BASE.latitude,
      lon1: BASE.longitude,
      lat2: point.latitude,
      lon2: point.longitude,
    })
    assert.ok(Math.abs(match.distanceKm - expected) < 0.05)
  })

  test('search narrows nearby results by Hotel name (case-insensitive)', async () => {
    const matchId = await approveHotelAt(pointNorthOfBase(1))
    await prisma.hotel.update({ where: { id: matchId }, data: { profileData: { ...(await hotelService.getHotelById(matchId)).profileData, name: 'The Grand Palazzo' } } })
    const otherId = await approveHotelAt(pointNorthOfBase(2))

    const res = await get(`/api/v1/hotels/public/nearby?latitude=${BASE.latitude}&longitude=${BASE.longitude}&search=palazzo`)
    assert.equal(res.status, 200)
    assert.equal(res.body.data.some((h) => h.id === matchId), true)
    assert.equal(res.body.data.some((h) => h.id === otherId), false)
  })

  test('rejects a search string over 200 characters (400)', async () => {
    const res = await get(`/api/v1/hotels/public/nearby?latitude=${BASE.latitude}&longitude=${BASE.longitude}&search=${'a'.repeat(201)}`)
    assert.equal(res.status, 400)
  })

  test('existing GET /hotels/public behavior is unaffected by this feature', async () => {
    const hotelId = await approveHotelAt(pointNorthOfBase(1))
    const res = await get('/api/v1/hotels/public')
    assert.equal(res.status, 200)
    assert.ok(Array.isArray(res.body.data))
    assert.equal(res.body.data.some((h) => h.id === hotelId), true)
    // No distanceKm leaks onto the unrelated, unauthenticated public-browse endpoint.
    assert.equal(res.body.data[0].distanceKm, undefined)
  })
})
