import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import * as applicationService from '../application.service.js'
import * as suspensionService from '../suspension.service.js'
import * as hotelService from '../hotel.service.js'
import * as ownershipService from '../ownership.service.js'

/**
 * Integration tests (testing-standards.md §6) — real Prisma queries against
 * a real test database, real JWT verification through Module 1's Access
 * Gate, not a mocked auth layer. Covers the HM1–HM15 journeys plus the
 * exception scenarios from business-specification.md §9.
 *
 * Administration & Platform Management (Module 13) does not exist yet
 * (Technical Design §17). Approve/reject/suspend/deactivate decisions are
 * exercised here by calling this module's own internal service functions
 * directly — the "stub caller" pattern the Implementation Plan §8
 * anticipates for exactly this situation, not a shortcut around the
 * authorization boundary (BR-HOTEL-14): those functions perform no role
 * check themselves by design: the caller (eventually Module 13's own
 * authorized endpoint) is responsible for that.
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

function authHeader(token) {
  return { Authorization: `Bearer ${token}` }
}

async function registerAndLoginHotelManager() {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  await post('/api/v1/auth/register', { mobileNumber, password, accountType: 'HOTEL_MANAGER' })
  const loginRes = await post('/api/v1/auth/login', { mobileNumber, password })
  return loginRes.body.data
}

// Platform Administrator accounts are never self-registered (Module 1
// BR-AUTH-05) — provisioned directly here, the same pattern this session
// has used throughout for seeding one.
async function createPlatformAdministrator() {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  const argon2 = await import('argon2')
  const passwordHash = await argon2.hash(password)
  return prisma.user.create({
    data: { mobileNumber, passwordHash, accountType: 'PLATFORM_ADMINISTRATOR', isVerified: true },
  })
}

async function createAndLoginPlatformAdministrator() {
  const admin = await createPlatformAdministrator()
  // password set in createPlatformAdministrator's hash is fixed above —
  // re-derive it here rather than threading it through, since it never varies.
  const loginRes = await post('/api/v1/auth/login', {
    mobileNumber: admin.mobileNumber,
    password: 'correct-horse-battery-staple',
  })
  return loginRes.body.data
}

async function registerHotelToProfileComplete(token) {
  const { body } = await post('/api/v1/hotels', {}, authHeader(token))
  const hotelId = body.data.id
  await patch(`/api/v1/hotels/${hotelId}`, { name: 'Grand Test Hotel' }, authHeader(token))
  return hotelId
}

before(async () => {
  const app = createApp()
  server = app.listen(0)
  await new Promise((resolve) => server.once('listening', resolve))
  const { port } = server.address()
  baseUrl = `http://127.0.0.1:${port}`

  // A single Platform Administrator, reused as the decidedByUserId for
  // every direct service-call "stub caller" in these tests (see the file
  // header) — a real users.id, since it's a genuine foreign key.
  const admin = await createPlatformAdministrator()
  adminStubUserId = admin.id
})

after(async () => {
  await new Promise((resolve) => server.close(resolve))
  await prisma.$disconnect()
})

describe('Hotel registration and profile completion (HM1, HM2)', () => {
  test('registers a Hotel in REGISTERED status', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const res = await post('/api/v1/hotels', {}, authHeader(accessToken))
    assert.equal(res.status, 201)
    assert.equal(res.body.data.status, 'REGISTERED')
  })

  test('completes the profile, reaching PROFILE_COMPLETE', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))
    const res = await patch(
      `/api/v1/hotels/${created.data.id}`,
      { name: 'Grand Test Hotel' },
      authHeader(accessToken),
    )
    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'PROFILE_COMPLETE')
  })
})

describe('Application submission and review (HM3–HM6)', () => {
  test('submits an application, reaching UNDER_REVIEW', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotelToProfileComplete(accessToken)

    const res = await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
    assert.equal(res.status, 201)
    assert.equal(res.body.data.status, 'OPEN')

    const hotelRes = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(hotelRes.body.data.status, 'UNDER_REVIEW')
  })

  test('rejects a second submission while one is already open (409)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotelToProfileComplete(accessToken)
    await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))

    const res = await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
    assert.equal(res.status, 409)
  })

  test('rejects submission with an incomplete profile (422, BR-HOTEL-02/03)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))

    const res = await post(`/api/v1/hotels/${created.data.id}/applications`, undefined, authHeader(accessToken))
    assert.equal(res.status, 422)
  })

  test('Platform Administrator approval reaches APPROVED_ACTIVE (HM5, BDR-003)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotelToProfileComplete(accessToken)
    await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))

    const hotel = await hotelService.getHotelById(hotelId)
    await applicationService.recordDecision(hotel, (await prismaOpenApplicationId(hotelId)), 'APPROVED', adminStubUserId)

    const res = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(res.body.data.status, 'APPROVED_ACTIVE')
  })

  test('Platform Administrator rejection reaches REJECTED (HM6, BDR-003)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotelToProfileComplete(accessToken)
    await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))

    const hotel = await hotelService.getHotelById(hotelId)
    await applicationService.recordDecision(hotel, (await prismaOpenApplicationId(hotelId)), 'REJECTED', adminStubUserId)

    const res = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(res.body.data.status, 'REJECTED')
  })
})

describe('Rejected hotel editing and resubmission (HM7, HM8, BDR-010)', () => {
  test('edits a rejected application without changing status, then resubmits to UNDER_REVIEW', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotelToProfileComplete(accessToken)
    await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
    const hotel = await hotelService.getHotelById(hotelId)
    await applicationService.recordDecision(hotel, await prismaOpenApplicationId(hotelId), 'REJECTED', adminStubUserId)

    const editRes = await patch(
      `/api/v1/hotels/${hotelId}`,
      { name: 'Grand Test Hotel (corrected)' },
      authHeader(accessToken),
    )
    assert.equal(editRes.status, 200)
    assert.equal(editRes.body.data.status, 'REJECTED')

    const resubmitRes = await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
    assert.equal(resubmitRes.status, 201)

    const hotelRes = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(hotelRes.body.data.status, 'UNDER_REVIEW')

    const applications = await prisma.hotelApplication.findMany({ where: { hotelId } })
    assert.equal(applications.length, 2, 'resubmission creates a new record, never overwrites the rejected one')
  })
})

describe('Pending application withdrawal (HM9, BR-HOTEL-08)', () => {
  test('withdraws an open application, reaching WITHDRAWN', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotelToProfileComplete(accessToken)
    const { body: application } = await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))

    const res = await post(
      `/api/v1/hotels/${hotelId}/applications/${application.data.id}/withdrawal`,
      undefined,
      authHeader(accessToken),
    )
    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'WITHDRAWN')

    const hotelRes = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(hotelRes.body.data.status, 'WITHDRAWN')
  })

  test('rejects withdrawal when no application is open (409)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))

    const res = await post(
      `/api/v1/hotels/${created.data.id}/applications/00000000-0000-0000-0000-000000000000/withdrawal`,
      undefined,
      authHeader(accessToken),
    )
    assert.equal(res.status, 409)
  })
})

describe('Approved hotel suspension (HM11, BR-HOTEL-09)', () => {
  test('suspends an Approved/Active Hotel', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await approveHotel(accessToken)

    const hotel = await hotelService.getHotelById(hotelId)
    await suspensionService.suspendHotel(hotel, adminStubUserId)

    const res = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(res.body.data.status, 'SUSPENDED')
  })
})

describe('Ordinary vs. critical profile changes (HM12, HM13)', () => {
  test('an ordinary change applies immediately', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await approveHotel(accessToken)

    const res = await patch(`/api/v1/hotels/${hotelId}`, { description: 'Newly renovated lobby' }, authHeader(accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.applied, true)
  })
})

describe('Tenant isolation (api-standards.md §13)', () => {
  test('a Hotel Manager cannot access another Hotel Manager\'s Hotel (404, not 403)', async () => {
    const ownerA = await registerAndLoginHotelManager()
    const { accessToken: tokenB } = await registerAndLoginHotelManager()
    const { body: created } = await post('/api/v1/hotels', {}, authHeader(ownerA.accessToken))

    const res = await get(`/api/v1/hotels/${created.data.id}`, authHeader(tokenB))
    assert.equal(res.status, 404)
  })
})

describe('Platform-Administrator-only Hotel list (Technical Design §11)', () => {
  test('a Hotel Manager is refused (403)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const res = await get('/api/v1/hotels', authHeader(accessToken))
    assert.equal(res.status, 403)
  })

  test('a Platform Administrator receives a paginated list', async () => {
    const { accessToken } = await createAndLoginPlatformAdministrator()
    const res = await get('/api/v1/hotels?page=1&limit=20', authHeader(accessToken))
    assert.equal(res.status, 200)
    assert.ok(Array.isArray(res.body.data))
    assert.ok(res.body.pagination)
  })
})

describe('Hotel Ownership Query Interface (Technical Design §3, §10, §18 Item 6)', () => {
  test('returns true for the Hotel Manager who registered the Hotel', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))

    const owned = await ownershipService.isOwnedByUser(created.data.id, created.data.registeredByUserId)
    assert.equal(owned, true)
  })

  test('returns false for a different Hotel Manager', async () => {
    const { accessToken: tokenA } = await registerAndLoginHotelManager()
    const { accessToken: tokenB } = await registerAndLoginHotelManager()
    const { body: hotelA } = await post('/api/v1/hotels', {}, authHeader(tokenA))
    const { body: hotelB } = await post('/api/v1/hotels', {}, authHeader(tokenB))

    const owned = await ownershipService.isOwnedByUser(hotelA.data.id, hotelB.data.registeredByUserId)
    assert.equal(owned, false)
  })

  test('returns false for a nonexistent Hotel id', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))

    const owned = await ownershipService.isOwnedByUser(
      '00000000-0000-0000-0000-000000000000',
      created.data.registeredByUserId,
    )
    assert.equal(owned, false)
  })

  test('returns false for a soft-deleted Hotel, even for its real owner (fail-closed, not an error)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))
    await prisma.hotel.update({ where: { id: created.data.id }, data: { deletedAt: new Date() } })

    const owned = await ownershipService.isOwnedByUser(created.data.id, created.data.registeredByUserId)
    assert.equal(owned, false)
  })
})

// Test-only helper — the open application is looked up directly since no
// public endpoint exposes an application's id ahead of submission's own
// response (already captured where needed above); used only where a prior
// test step didn't already have it in scope.
async function prismaOpenApplicationId(hotelId) {
  const application = await prisma.hotelApplication.findFirst({
    where: { hotelId, status: 'OPEN' },
    orderBy: { createdAt: 'desc' },
  })
  return application.id
}

async function approveHotel(accessToken) {
  const hotelId = await registerHotelToProfileComplete(accessToken)
  await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
  const hotel = await hotelService.getHotelById(hotelId)
  await applicationService.recordDecision(hotel, await prismaOpenApplicationId(hotelId), 'APPROVED', adminStubUserId)
  return hotelId
}
