import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import * as hallService from '../hall.service.js'
import * as hotelService from '../../hotels/hotel.service.js'
import * as applicationService from '../../hotels/application.service.js'

/**
 * Integration tests for Large Halls (Customer Mobile, approved V1 business
 * rules) — real Prisma queries against a real test database, same
 * `createApp()` + real `fetch` pattern as halls.integration.test.js.
 */

let server
let baseUrl
let adminStubUserId

function uniqueMobileNumber() {
  const suffix = Math.floor(100000000 + Math.random() * 899999999)
  return `+1${suffix}`
}

async function get(path, headers = {}) {
  const res = await fetch(`${baseUrl}${path}`, { headers })
  const text = await res.text()
  return { status: res.status, body: text ? JSON.parse(text) : undefined }
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
  const loginRes = await post('/api/v1/auth/login', { mobileNumber, password })
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

function completeHotelProfile() {
  return {
    name: 'Large Halls Test Hotel',
    description: 'A Hotel used only for Large Halls integration tests.',
    location: { latitude: -1.286389, longitude: 36.817223, address: 'Downtown, Nairobi' },
    contactPhone: '+15550001111',
  }
}

async function prismaOpenApplicationId(hotelId) {
  const application = await prisma.hotelApplication.findFirst({
    where: { hotelId, status: 'OPEN' },
    orderBy: { createdAt: 'desc' },
  })
  return application.id
}

// Every Hotel this file creates, so `after` can remove it and its Halls
// again. Large Halls ranks across the whole table with no pagination, so
// Halls left behind by a previous run permanently shrink the top-`limit`
// window every later run is asserting inside — the suite would slowly
// break itself without this.
const createdHotelIds = []

/** Registers, completes, submits, and approves a Hotel — reaching APPROVED_ACTIVE. */
async function createApprovedHotel() {
  const { accessToken } = await registerAndLoginHotelManager()
  const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))
  const hotelId = created.data.id
  createdHotelIds.push(hotelId)
  await patch(`/api/v1/hotels/${hotelId}`, completeHotelProfile(), authHeader(accessToken))
  await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
  const hotel = await hotelService.getHotelById(hotelId)
  await applicationService.recordDecision(hotel, await prismaOpenApplicationId(hotelId), 'APPROVED', adminStubUserId)
  return hotelId
}

async function createUnapprovedHotel() {
  const { accessToken } = await registerAndLoginHotelManager()
  const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))
  createdHotelIds.push(created.data.id)
  return created.data.id
}

function createHallDirect(hotelId, capacity, extraProfile = {}) {
  return hallService.createHall({ hotelId, profileData: { name: `Hall ${capacity}`, capacity, ...extraProfile } })
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

  // Halls first: `Hall.hotel` is a required relation with no cascade, so a
  // Hotel with Halls cannot be deleted. Everything else this file creates
  // off a Hotel (applications, media) cascades with it. Scoped strictly to
  // ids this run recorded — never a blanket delete, since this database is
  // shared with manual testing.
  if (createdHotelIds.length > 0) {
    await prisma.hall.deleteMany({ where: { hotelId: { in: createdHotelIds } } })
    await prisma.hotel.deleteMany({ where: { id: { in: createdHotelIds } } })
  }
})

describe('GET /halls/large-capacity', () => {
  test('requires no authentication', async () => {
    const res = await get('/api/v1/halls/large-capacity')
    assert.equal(res.status, 200)
  })

  test('rejects an invalid limit', async () => {
    const res = await get('/api/v1/halls/large-capacity?limit=0')
    assert.equal(res.status, 400)
  })

  test('the largest Hall appears first among several of differing capacity', async () => {
    // Capacities well above anything else on the platform, so all three stay
    // inside the top-`limit` window this ranking returns regardless of what
    // else the database holds — the relative order is what's under test.
    const hotelId = await createApprovedHotel()
    const small = await createHallDirect(hotelId, 90050)
    const large = await createHallDirect(hotelId, 90900)
    const medium = await createHallDirect(hotelId, 90300)

    const res = await get('/api/v1/halls/large-capacity?limit=100')
    assert.equal(res.status, 200)
    const order = res.body.data.map((h) => h.id).filter((id) => [small.id, large.id, medium.id].includes(id))
    assert.deepEqual(order, [large.id, medium.id, small.id])
  })

  test('the response includes the Hall capacity and the owning Hotel name', async () => {
    const hotelId = await createApprovedHotel()
    const hotel = await hotelService.getHotelById(hotelId)
    const hall = await createHallDirect(hotelId, 777)

    const res = await get('/api/v1/halls/large-capacity?limit=100')
    const match = res.body.data.find((h) => h.id === hall.id)
    assert.ok(match, 'expected the Hall to appear')
    assert.equal(match.profileData.capacity, 777)
    assert.equal(match.hotel.id, hotelId)
    assert.equal(match.hotel.name, hotel.profileData.name)
  })

  test('Halls with equal capacity use a deterministic secondary ordering (by id)', async () => {
    // Equal, and high enough to stay inside the ranked window (see above) —
    // the id tiebreak is what's under test, not the capacity.
    const hotelId = await createApprovedHotel()
    const a = await createHallDirect(hotelId, 90200)
    const b = await createHallDirect(hotelId, 90200)
    const expectedOrder = [a.id, b.id].sort()

    const res1 = await get('/api/v1/halls/large-capacity?limit=100')
    const res2 = await get('/api/v1/halls/large-capacity?limit=100')
    const order1 = res1.body.data.map((h) => h.id).filter((id) => [a.id, b.id].includes(id))
    const order2 = res2.body.data.map((h) => h.id).filter((id) => [a.id, b.id].includes(id))
    assert.deepEqual(order1, expectedOrder)
    assert.deepEqual(order2, expectedOrder, 'ordering must be stable across repeated requests')
  })

  test('a Hall belonging to a non-APPROVED_ACTIVE Hotel is excluded', async () => {
    const hotelId = await createUnapprovedHotel()
    const hall = await createHallDirect(hotelId, 5000)

    const res = await get('/api/v1/halls/large-capacity?limit=100')
    assert.equal(res.body.data.some((h) => h.id === hall.id), false)
  })

  test('a Hall without a photo still appears', async () => {
    const hotelId = await createApprovedHotel()
    const hall = await createHallDirect(hotelId, 640)

    const res = await get('/api/v1/halls/large-capacity?limit=100')
    const match = res.body.data.find((h) => h.id === hall.id)
    assert.ok(match, 'a Hall without a photo must still qualify')
    assert.deepEqual(match.photos, [])
  })

  test('a Hall without any Booking still appears (no booking requirement)', async () => {
    const hotelId = await createApprovedHotel()
    const hall = await createHallDirect(hotelId, 410)
    const bookingCount = await prisma.booking.count({ where: { hallId: hall.id } })
    assert.equal(bookingCount, 0)

    const res = await get('/api/v1/halls/large-capacity?limit=100')
    assert.equal(res.body.data.some((h) => h.id === hall.id), true)
  })

  test('no duplicate Halls appear in the response', async () => {
    const hotelId = await createApprovedHotel()
    await createHallDirect(hotelId, 850)

    const res = await get('/api/v1/halls/large-capacity?limit=100')
    const ids = res.body.data.map((h) => h.id)
    assert.equal(ids.length, new Set(ids).size)
  })

  test('existing GET /halls platform-wide browse remains functional and now also carries the Hotel name', async () => {
    const hotelId = await createApprovedHotel()
    const hotel = await hotelService.getHotelById(hotelId)
    const hall = await createHallDirect(hotelId, 120)

    const res = await get(`/api/v1/halls?hotelId=${hotelId}`)
    assert.equal(res.status, 200)
    const match = res.body.data.find((h) => h.id === hall.id)
    assert.ok(match)
    assert.equal(match.hotel.name, hotel.profileData.name)
  })

  test('existing GET /hotels/:hotelId/halls/:id (single-Hotel scoped) response shape is unaffected', async () => {
    const hotelId = await createApprovedHotel()
    const hall = await createHallDirect(hotelId, 95)

    const res = await get(`/api/v1/hotels/${hotelId}/halls/${hall.id}`)
    assert.equal(res.status, 200)
    assert.equal(res.body.data.id, hall.id)
  })
})
