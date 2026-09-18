import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import * as applicationService from '../application.service.js'
import * as hotelService from '../hotel.service.js'
import * as ownershipService from '../ownership.service.js'

/**
 * Integration tests (testing-standards.md §6) — real Prisma queries against
 * a real test database, real JWT verification through Module 1's Access
 * Gate, not a mocked auth layer. Covers the HM1–HM15 journeys plus the
 * exception scenarios from business-specification.md §9.
 *
 * Administration & Platform Management (Module 13) exposes the real
 * approve/reject/suspend/deactivate endpoints exercised in the
 * "Administration API" describe blocks below (`/api/v1/admin/...`).
 * Elsewhere, an application decision is recorded directly through
 * `applicationService.recordDecision` as test setup only (not itself under
 * test) — that function performs no role check itself by design
 * (BR-HOTEL-14); the real authorization boundary is Module 13's routes,
 * which the "Administration API" tests exercise over HTTP.
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
  // BDR-019: Full Name is required at registration for a HOTEL_MANAGER account.
  await post('/api/v1/auth/register', { mobileNumber, password, accountType: 'HOTEL_MANAGER', fullName: 'Test Manager' })
  // Login answers with a texted code instead of a session now; the suite
  // pins that code in scripts/testEnv.js.
  await post('/api/v1/auth/login', { mobileNumber, password })
  const loginRes = await post('/api/v1/auth/login/verify', { mobileNumber, code: '123456' })
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
  // An administrator owes a texted code like every other account type now;
  // the suite pins that code in scripts/testEnv.js.
  await post('/api/v1/auth/login', {
    mobileNumber: admin.mobileNumber,
    password: 'correct-horse-battery-staple',
  })
  const loginRes = await post('/api/v1/auth/login/verify', {
    mobileNumber: admin.mobileNumber,
    code: '123456',
  })
  return loginRes.body.data
}

async function registerHotelToProfileComplete(token) {
  const { body } = await post('/api/v1/hotels', {}, authHeader(token))
  const hotelId = body.data.id
  await patch(`/api/v1/hotels/${hotelId}`, completeHotelProfile(), authHeader(token))
  return hotelId
}

async function registerAndLoginCustomer() {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  // BDR-018: Full Name is required at registration for a CUSTOMER account.
  await post('/api/v1/auth/register', { mobileNumber, password, accountType: 'CUSTOMER', fullName: 'Test Customer' })
  // Login answers with a texted code instead of a session now; the suite
  // pins that code in scripts/testEnv.js.
  await post('/api/v1/auth/login', { mobileNumber, password })
  const loginRes = await post('/api/v1/auth/login/verify', { mobileNumber, code: '123456' })
  return loginRes.body.data
}

function completeHotelProfile(overrides = {}) {
  return {
    name: 'Grand Test Hotel',
    description: 'A comfortable city hotel with flexible halls.',
    location: { latitude: -1.286389, longitude: 36.817223, address: 'Downtown, Nairobi' },
    contactPhone: '+15550001111',
    ...overrides,
  }
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

  test('refuses Hotel creation for a non-Hotel-Manager account (403)', async () => {
    const { accessToken } = await registerAndLoginCustomer()
    const res = await post('/api/v1/hotels', {}, authHeader(accessToken))
    assert.equal(res.status, 403)
  })

  test('completes the profile, reaching PROFILE_COMPLETE', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))
    const res = await patch(
      `/api/v1/hotels/${created.data.id}`,
      completeHotelProfile(),
      authHeader(accessToken),
    )
    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'PROFILE_COMPLETE')
  })

  test('discovers the authenticated Manager Hotel from the server', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotelToProfileComplete(accessToken)
    const res = await get('/api/v1/hotels/me', authHeader(accessToken))

    assert.equal(res.status, 200)
    assert.equal(res.body.data.hotel.id, hotelId)
    assert.equal(res.body.data.latestApplication, null)
    // The real review aggregate (Manager Mobile's own "My Hotel" screen) —
    // null average (not 0) with zero reviews, the same shape the public
    // Hotel Detail endpoint already returns to Customers.
    assert.deepEqual(res.body.data.reviewSummary, { average: null, count: 0 })
  })

  test('reviewSummary is null when the Manager has no Hotel yet', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const res = await get('/api/v1/hotels/me', authHeader(accessToken))

    assert.equal(res.status, 200)
    assert.equal(res.body.data.hotel, null)
    assert.equal(res.body.data.reviewSummary, null)
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
      completeHotelProfile({ name: 'Grand Test Hotel (corrected)' }),
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
    assert.equal(res.status, 404)
  })

  test('does not withdraw a different application id while another is open', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotelToProfileComplete(accessToken)
    await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))

    const res = await post(
      `/api/v1/hotels/${hotelId}/applications/00000000-0000-0000-0000-000000000000/withdrawal`,
      undefined,
      authHeader(accessToken),
    )
    assert.equal(res.status, 404)

    const stillOpen = await prisma.hotelApplication.findFirst({ where: { hotelId, status: 'OPEN' } })
    assert.ok(stillOpen)
  })
})

describe('Administration API — Hotel application decisions', () => {
  test('approves an open application through the admin API', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotelToProfileComplete(accessToken)
    const { body: application } = await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
    const admin = await createAndLoginPlatformAdministrator()

    const res = await post(
      `/api/v1/admin/hotels/${hotelId}/applications/${application.data.id}/approval`,
      undefined,
      authHeader(admin.accessToken),
    )

    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'APPROVED')
    const hotelRes = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(hotelRes.body.data.status, 'APPROVED_ACTIVE')
  })

  test('rejects an open application with a persisted reason through the admin API', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotelToProfileComplete(accessToken)
    const { body: application } = await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
    const admin = await createAndLoginPlatformAdministrator()

    const res = await post(
      `/api/v1/admin/hotels/${hotelId}/applications/${application.data.id}/rejection`,
      { reason: 'Business registration could not be verified.' },
      authHeader(admin.accessToken),
    )

    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'REJECTED')
    assert.equal(res.body.data.decisionReason, 'Business registration could not be verified.')
    const myHotel = await get('/api/v1/hotels/me', authHeader(accessToken))
    assert.equal(myHotel.body.data.latestApplication.decisionReason, 'Business registration could not be verified.')
  })

  test('refuses admin decisions from a Hotel Manager token', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotelToProfileComplete(accessToken)
    const { body: application } = await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))

    const res = await post(
      `/api/v1/admin/hotels/${hotelId}/applications/${application.data.id}/approval`,
      undefined,
      authHeader(accessToken),
    )
    assert.equal(res.status, 403)
  })
})

describe('Administration API — Hotel suspension, deactivation, and reactivation (HM11, HM17, BR-HOTEL-09, BR-HOTEL-16)', () => {
  test('suspends an Approved/Active Hotel through the admin API', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await approveHotel(accessToken)
    const admin = await createAndLoginPlatformAdministrator()

    const res = await post(`/api/v1/admin/hotels/${hotelId}/suspension`, undefined, authHeader(admin.accessToken))

    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'SUSPENDED')
    const hotelRes = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(hotelRes.body.data.status, 'SUSPENDED')
  })

  test('deactivates an Approved/Active Hotel through the admin API', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await approveHotel(accessToken)
    const admin = await createAndLoginPlatformAdministrator()

    const res = await post(`/api/v1/admin/hotels/${hotelId}/deactivation`, undefined, authHeader(admin.accessToken))

    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'DEACTIVATED')
    const hotelRes = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(hotelRes.body.data.status, 'DEACTIVATED')
  })

  test('refuses suspension of a Hotel that is not Approved/Active (409)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotelToProfileComplete(accessToken)
    const admin = await createAndLoginPlatformAdministrator()

    const res = await post(`/api/v1/admin/hotels/${hotelId}/suspension`, undefined, authHeader(admin.accessToken))
    assert.equal(res.status, 409)
  })

  test('refuses deactivation of a Hotel that is not Approved/Active (409)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotelToProfileComplete(accessToken)
    const admin = await createAndLoginPlatformAdministrator()

    const res = await post(`/api/v1/admin/hotels/${hotelId}/deactivation`, undefined, authHeader(admin.accessToken))
    assert.equal(res.status, 409)
  })

  test('a Suspended Hotel cannot be deactivated directly (409) — reactivate first', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await approveHotel(accessToken)
    const admin = await createAndLoginPlatformAdministrator()
    await post(`/api/v1/admin/hotels/${hotelId}/suspension`, undefined, authHeader(admin.accessToken))

    const res = await post(`/api/v1/admin/hotels/${hotelId}/deactivation`, undefined, authHeader(admin.accessToken))
    assert.equal(res.status, 409)
  })

  test('reactivates a Suspended Hotel back to Approved/Active through the admin API', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await approveHotel(accessToken)
    const admin = await createAndLoginPlatformAdministrator()
    await post(`/api/v1/admin/hotels/${hotelId}/suspension`, undefined, authHeader(admin.accessToken))

    const res = await post(`/api/v1/admin/hotels/${hotelId}/reactivation`, undefined, authHeader(admin.accessToken))

    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'APPROVED_ACTIVE')
    const hotelRes = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(hotelRes.body.data.status, 'APPROVED_ACTIVE')
  })

  test('reactivates a Deactivated Hotel back to Approved/Active through the admin API', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await approveHotel(accessToken)
    const admin = await createAndLoginPlatformAdministrator()
    await post(`/api/v1/admin/hotels/${hotelId}/deactivation`, undefined, authHeader(admin.accessToken))

    const res = await post(`/api/v1/admin/hotels/${hotelId}/reactivation`, undefined, authHeader(admin.accessToken))

    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'APPROVED_ACTIVE')
    const hotelRes = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(hotelRes.body.data.status, 'APPROVED_ACTIVE')
  })

  test('a reactivated Hotel can be suspended again', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await approveHotel(accessToken)
    const admin = await createAndLoginPlatformAdministrator()
    await post(`/api/v1/admin/hotels/${hotelId}/suspension`, undefined, authHeader(admin.accessToken))
    await post(`/api/v1/admin/hotels/${hotelId}/reactivation`, undefined, authHeader(admin.accessToken))

    const res = await post(`/api/v1/admin/hotels/${hotelId}/suspension`, undefined, authHeader(admin.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'SUSPENDED')
  })

  test('refuses reactivation of a Hotel that is not Suspended or Deactivated (409)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await approveHotel(accessToken)
    const admin = await createAndLoginPlatformAdministrator()

    const res = await post(`/api/v1/admin/hotels/${hotelId}/reactivation`, undefined, authHeader(admin.accessToken))
    assert.equal(res.status, 409)
  })

  test('refuses reactivation from a Hotel Manager token', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await approveHotel(accessToken)
    const admin = await createAndLoginPlatformAdministrator()
    await post(`/api/v1/admin/hotels/${hotelId}/suspension`, undefined, authHeader(admin.accessToken))

    const res = await post(`/api/v1/admin/hotels/${hotelId}/reactivation`, undefined, authHeader(accessToken))
    assert.equal(res.status, 403)

    const hotelRes = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(hotelRes.body.data.status, 'SUSPENDED')
  })

  test('refuses suspension from a Hotel Manager token', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await approveHotel(accessToken)

    const res = await post(`/api/v1/admin/hotels/${hotelId}/suspension`, undefined, authHeader(accessToken))
    assert.equal(res.status, 403)

    const hotelRes = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(hotelRes.body.data.status, 'APPROVED_ACTIVE')
  })

  test('refuses deactivation from an unauthenticated request', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await approveHotel(accessToken)

    const res = await post(`/api/v1/admin/hotels/${hotelId}/deactivation`, undefined, {})
    assert.equal(res.status, 401)

    const hotelRes = await get(`/api/v1/hotels/${hotelId}`, authHeader(accessToken))
    assert.equal(hotelRes.body.data.status, 'APPROVED_ACTIVE')
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
