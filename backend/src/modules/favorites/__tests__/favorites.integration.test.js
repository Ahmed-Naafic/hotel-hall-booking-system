import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import * as applicationService from '../../hotels/application.service.js'
import * as hotelService from '../../hotels/hotel.service.js'

/**
 * Integration tests for Favorites (Customer Mobile "save a Hotel") — real
 * Prisma queries, a real server, real requests through `authenticate`/
 * `requireAccountType`, same pattern as nearby.integration.test.js.
 */

let server
let baseUrl
let adminStubUserId

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

async function del(path, headers = {}) {
  const res = await fetch(`${baseUrl}${path}`, { method: 'DELETE', headers })
  const text = await res.text()
  return { status: res.status, body: text ? JSON.parse(text) : undefined }
}

async function put(path, headers = {}) {
  const res = await fetch(`${baseUrl}${path}`, { method: 'PUT', headers })
  const text = await res.text()
  return { status: res.status, body: text ? JSON.parse(text) : undefined }
}

function authHeader(token) {
  return { Authorization: `Bearer ${token}` }
}

async function registerAndLogin(accountType) {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  // BDR-018: Full Name is required at registration for a CUSTOMER account only.
  const fullName = accountType === 'CUSTOMER' ? 'Test Customer' : undefined
  await post('/api/v1/auth/register', { mobileNumber, password, accountType, fullName })
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

async function prismaOpenApplicationId(hotelId) {
  const application = await prisma.hotelApplication.findFirst({
    where: { hotelId, status: 'OPEN' },
    orderBy: { createdAt: 'desc' },
  })
  return application.id
}

function completeHotelProfile(overrides = {}) {
  return {
    name: 'Favorites Test Hotel',
    description: 'A Hotel used only for Favorites integration tests.',
    location: { latitude: -1.286389, longitude: 36.817223, address: 'Test Address' },
    contactPhone: '+15550001111',
    ...overrides,
  }
}

/** Registers, completes profile, and approves — returns the Hotel id. */
async function approveHotel() {
  const { accessToken } = await registerAndLogin('HOTEL_MANAGER')
  const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))
  const hotelId = created.data.id
  await patch(`/api/v1/hotels/${hotelId}`, completeHotelProfile(), authHeader(accessToken))
  await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
  const hotel = await hotelService.getHotelById(hotelId)
  await applicationService.recordDecision(hotel, await prismaOpenApplicationId(hotelId), 'APPROVED', adminStubUserId)
  return hotelId
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

describe('Favorites (save/unsave/list Hotels)', () => {
  test('rejects an unauthenticated save request', async () => {
    const hotelId = await approveHotel()
    const res = await put(`/api/v1/favorites/hotels/${hotelId}`)
    assert.equal(res.status, 401)
  })

  test('rejects a save request from a HOTEL_MANAGER account', async () => {
    const hotelId = await approveHotel()
    const { accessToken } = await registerAndLogin('HOTEL_MANAGER')
    const res = await put(`/api/v1/favorites/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(res.status, 403)
  })

  test('rejects a malformed hotelId', async () => {
    const { accessToken } = await registerAndLogin('CUSTOMER')
    const res = await put('/api/v1/favorites/hotels/not-a-uuid', authHeader(accessToken))
    assert.equal(res.status, 400)
    assert.equal(res.body.error, 'VALIDATION_ERROR')
  })

  test('returns 404 when saving a Hotel that does not exist', async () => {
    const { accessToken } = await registerAndLogin('CUSTOMER')
    const res = await put('/api/v1/favorites/hotels/00000000-0000-0000-0000-000000000000', authHeader(accessToken))
    assert.equal(res.status, 404)
  })

  test('a Customer can save a Hotel and see it in their saved list', async () => {
    const hotelId = await approveHotel()
    const { accessToken } = await registerAndLogin('CUSTOMER')

    const saveRes = await put(`/api/v1/favorites/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(saveRes.status, 200)
    assert.equal(saveRes.body.data.saved, true)

    const listRes = await get('/api/v1/favorites/hotels', authHeader(accessToken))
    assert.equal(listRes.status, 200)
    assert.equal(listRes.body.data.includes(hotelId), true)
  })

  test('saving the same Hotel twice is idempotent (no duplicate, no error)', async () => {
    const hotelId = await approveHotel()
    const { accessToken } = await registerAndLogin('CUSTOMER')

    await put(`/api/v1/favorites/hotels/${hotelId}`, authHeader(accessToken))
    const secondSave = await put(`/api/v1/favorites/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(secondSave.status, 200)

    const listRes = await get('/api/v1/favorites/hotels', authHeader(accessToken))
    assert.equal(listRes.body.data.filter((id) => id === hotelId).length, 1)
  })

  test('a Customer can unsave a Hotel and it disappears from their saved list', async () => {
    const hotelId = await approveHotel()
    const { accessToken } = await registerAndLogin('CUSTOMER')

    await put(`/api/v1/favorites/hotels/${hotelId}`, authHeader(accessToken))
    const unsaveRes = await del(`/api/v1/favorites/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(unsaveRes.status, 204)

    const listRes = await get('/api/v1/favorites/hotels', authHeader(accessToken))
    assert.equal(listRes.body.data.includes(hotelId), false)
  })

  test('unsaving a Hotel that was never saved is a no-op, not an error', async () => {
    const hotelId = await approveHotel()
    const { accessToken } = await registerAndLogin('CUSTOMER')
    const res = await del(`/api/v1/favorites/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(res.status, 204)
  })

  test("one Customer's saved Hotels are isolated from another Customer's", async () => {
    const hotelId = await approveHotel()
    const customerA = await registerAndLogin('CUSTOMER')
    const customerB = await registerAndLogin('CUSTOMER')

    await put(`/api/v1/favorites/hotels/${hotelId}`, authHeader(customerA.accessToken))

    const listB = await get('/api/v1/favorites/hotels', authHeader(customerB.accessToken))
    assert.equal(listB.body.data.includes(hotelId), false)

    const listA = await get('/api/v1/favorites/hotels', authHeader(customerA.accessToken))
    assert.equal(listA.body.data.includes(hotelId), true)
  })

  test('a saved Hotel remains saved even if it later becomes ineligible for ordinary browsing', async () => {
    const hotelId = await approveHotel()
    const { accessToken } = await registerAndLogin('CUSTOMER')
    await put(`/api/v1/favorites/hotels/${hotelId}`, authHeader(accessToken))

    await prisma.hotel.update({ where: { id: hotelId }, data: { status: 'SUSPENDED' } })

    const listRes = await get('/api/v1/favorites/hotels', authHeader(accessToken))
    assert.equal(listRes.status, 200)
    assert.equal(listRes.body.data.includes(hotelId), true)
  })
})
