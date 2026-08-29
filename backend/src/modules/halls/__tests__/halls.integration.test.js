import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import * as hallService from '../hall.service.js'
import * as profileService from '../profile.service.js'
import * as hotelService from '../../hotels/hotel.service.js'
import * as applicationService from '../../hotels/application.service.js'

/**
 * Integration tests (testing-standards.md §6) — real Prisma queries
 * against a real test database, real server. Covers WBS-02–WBS-06: the
 * platform-wide browse endpoint (`GET /api/v1/halls`) and the own-Hotel-
 * scoped endpoints (`POST`/`GET`/`PATCH /hotels/:hotelId/halls[/:id]`,
 * `GET /hotels/:hotelId/halls`), unblocked by Hotel Management's Hotel
 * Ownership Query Interface (Approved Technical Design v1.5).
 *
 * `WBS-04`'s call into Hotel Management's Eligibility Query Interface, and
 * WBS-05's calls into its Hotel Ownership Query Interface, are exercised
 * here against real Hotel records moved through real status transitions
 * (reaching `APPROVED_ACTIVE`), never a mocked response (Implementation
 * Plan §8).
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
  await post('/api/v1/auth/register', { mobileNumber, password, accountType: 'HOTEL_MANAGER' })
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

/** Registers, completes, submits, and approves a Hotel — reaching APPROVED_ACTIVE. */
async function createApprovedHotel(accessToken) {
  const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))
  const hotelId = created.data.id
  await patch(`/api/v1/hotels/${hotelId}`, completeHotelProfile(), authHeader(accessToken))
  await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
  const hotel = await hotelService.getHotelById(hotelId)
  await applicationService.recordDecision(hotel, await prismaOpenApplicationId(hotelId), 'APPROVED', adminStubUserId)
  return hotelId
}

function completeHotelProfile() {
  return {
    name: 'Grand Test Hotel',
    description: 'A comfortable city hotel with flexible halls.',
    location: 'Downtown',
    contactPhone: '+15550001111',
  }
}

/** Registers a Hotel that never reaches Approved/Active — remains REGISTERED. */
async function createUnapprovedHotel(accessToken) {
  const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))
  return created.data.id
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
  await prisma.$disconnect()
})

describe('Hall Component — creation and retrieval (WBS-02)', () => {
  test('creates a Hall belonging to exactly one Hotel (BR-HALL-01)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)

    const hall = await hallService.createHall({ hotelId, profileData: { name: 'The Ivory Room' } })
    assert.equal(hall.hotelId, hotelId)
    assert.equal(hall.profileData.name, 'The Ivory Room')

    const fetched = await hallService.getHallById(hall.id)
    assert.equal(fetched.id, hall.id)
  })

  test('a Hall may be created before the owning Hotel is approved (BR-HALL-02, BR-HOTEL-04)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const hotel = await hotelService.getHotelById(hotelId)
    assert.equal(hotel.status, 'REGISTERED')

    const hall = await hallService.createHall({ hotelId })
    assert.ok(hall.id)
  })

  test('getHallForHotel scopes retrieval to the owning Hotel (BR-HALL-10)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const { accessToken: otherToken } = await registerAndLoginHotelManager()
    const otherHotelId = await createUnapprovedHotel(otherToken)

    const hall = await hallService.createHall({ hotelId })
    await assert.rejects(() => hallService.getHallForHotel(hall.id, otherHotelId))
    const own = await hallService.getHallForHotel(hall.id, hotelId)
    assert.equal(own.id, hall.id)
  })
})

describe('Profile Component — updates (WBS-03)', () => {
  test('updates apply directly, no review step (BR-HALL-07)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId, profileData: { name: 'Original' } })

    const updated = await profileService.updateHallProfile(hall, { name: 'Renamed', capacity: 200 })
    assert.equal(updated.profileData.name, 'Renamed')
    assert.equal(updated.profileData.capacity, 200)
  })
})

describe('Platform-wide browse (GET /api/v1/halls, WBS-06, BR-HALL-08)', () => {
  test('a Hall belonging to an unapproved Hotel is Hidden — never returned (BR-HALL-03)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId, profileData: { name: 'Hidden Hall' } })

    const res = await get(`/api/v1/halls?hotelId=${hotelId}`)
    assert.equal(res.status, 200)
    assert.ok(!res.body.data.some((h) => h.id === hall.id))
  })

  test('a Hall belonging to an Approved/Active Hotel is Visible (BR-HALL-04, BDR-009, no account required)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createApprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId, profileData: { name: 'Visible Hall' } })

    const res = await get(`/api/v1/halls?hotelId=${hotelId}`)
    assert.equal(res.status, 200)
    assert.ok(res.body.data.some((h) => h.id === hall.id))
  })

  test('response uses cursor pagination, not offset (Technical Design v1.2)', async () => {
    const res = await get('/api/v1/halls?limit=1')
    assert.equal(res.status, 200)
    assert.ok('limit' in res.body.pagination)
    assert.ok('hasNext' in res.body.pagination)
    assert.ok('nextCursor' in res.body.pagination)
    assert.ok(!('page' in res.body.pagination), 'must not use offset pagination fields')
    assert.ok(!('total' in res.body.pagination), 'must not use offset pagination fields')
  })

  test('rejects a malformed hotelId filter (400)', async () => {
    const res = await get('/api/v1/halls?hotelId=not-a-uuid')
    assert.equal(res.status, 400)
  })
})

describe('POST /api/v1/hotels/:hotelId/halls (WBS-05, HL1/HL2, BR-HALL-02)', () => {
  test('the owning Hotel Manager creates a Hall (201)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)

    const res = await post(
      `/api/v1/hotels/${hotelId}/halls`,
      { profileData: { name: 'The Gallery', capacity: 80 } },
      authHeader(accessToken),
    )
    assert.equal(res.status, 201)
    assert.equal(res.body.data.hotelId, hotelId)
    assert.equal(res.body.data.profileData.name, 'The Gallery')
  })

  test('creation succeeds regardless of the owning Hotel\'s own status (BR-HALL-02)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createApprovedHotel(accessToken)

    const res = await post(
      `/api/v1/hotels/${hotelId}/halls`,
      { profileData: { name: 'The Gallery', capacity: 80 } },
      authHeader(accessToken),
    )
    assert.equal(res.status, 201)
  })

  test('rejects an unauthenticated request (401)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)

    const res = await post(`/api/v1/hotels/${hotelId}/halls`, {})
    assert.equal(res.status, 401)
  })

  test('a Hotel Manager cannot create a Hall under a Hotel they do not own (404, not 403, BR-HALL-10)', async () => {
    const { accessToken: ownerToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(ownerToken)
    const { accessToken: otherToken } = await registerAndLoginHotelManager()

    const res = await post(
      `/api/v1/hotels/${hotelId}/halls`,
      { profileData: { name: 'The Gallery', capacity: 80 } },
      authHeader(otherToken),
    )
    assert.equal(res.status, 404)
  })

  test('rejects a malformed profileData shape (400)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)

    const res = await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: 'not-an-object' }, authHeader(accessToken))
    assert.equal(res.status, 400)
  })

  test('rejects a missing Hall Name (400, BDR-016)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)

    const res = await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: { capacity: 50 } }, authHeader(accessToken))
    assert.equal(res.status, 400)
    assert.equal(res.body.error, 'VALIDATION_ERROR')
    assert.ok(res.body.details.some((d) => d.field === 'name'))
  })

  test('rejects a missing Capacity (400, BDR-016)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)

    const res = await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: { name: 'The Gallery' } }, authHeader(accessToken))
    assert.equal(res.status, 400)
    assert.ok(res.body.details.some((d) => d.field === 'capacity'))
  })

  test('rejects an invalid (non-positive) Capacity (400, BDR-016)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)

    const res = await post(
      `/api/v1/hotels/${hotelId}/halls`,
      { profileData: { name: 'The Gallery', capacity: -5 } },
      authHeader(accessToken),
    )
    assert.equal(res.status, 400)
    assert.ok(res.body.details.some((d) => d.field === 'capacity'))
  })

  test('rejects a non-numeric Capacity (400, BDR-016)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)

    const res = await post(
      `/api/v1/hotels/${hotelId}/halls`,
      { profileData: { name: 'The Gallery', capacity: 'a lot' } },
      authHeader(accessToken),
    )
    assert.equal(res.status, 400)
    assert.ok(res.body.details.some((d) => d.field === 'capacity'))
  })

  test('accepts optional Description and Location/Area alongside the required fields (BDR-016)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)

    const res = await post(
      `/api/v1/hotels/${hotelId}/halls`,
      { profileData: { name: 'The Gallery', capacity: 80, description: 'A bright, airy room.', location: 'Second floor' } },
      authHeader(accessToken),
    )
    assert.equal(res.status, 201)
    assert.equal(res.body.data.profileData.description, 'A bright, airy room.')
    assert.equal(res.body.data.profileData.location, 'Second floor')
  })

  test('accepts custom key/value fields alongside the required fields, without substituting for them (BDR-016)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)

    const res = await post(
      `/api/v1/hotels/${hotelId}/halls`,
      { profileData: { name: 'The Gallery', capacity: 80, amenities: 'Projector, Stage' } },
      authHeader(accessToken),
    )
    assert.equal(res.status, 201)
    assert.equal(res.body.data.profileData.name, 'The Gallery')
    assert.equal(res.body.data.profileData.capacity, 80)
    assert.equal(res.body.data.profileData.amenities, 'Projector, Stage')
  })
})

describe('GET /api/v1/hotels/:hotelId/halls/:id (WBS-05, HL2/HL5/HL6, Technical Design §14.3)', () => {
  test('the owning Hotel Manager sees a Hidden Hall (200)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const { body: created } = await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: { name: 'Test Hall', capacity: 50 } }, authHeader(accessToken))

    const res = await get(`/api/v1/hotels/${hotelId}/halls/${created.data.id}`, authHeader(accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.id, created.data.id)
  })

  test('an unauthenticated caller never sees a Hidden Hall (404, never leaked)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const { body: created } = await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: { name: 'Test Hall', capacity: 50 } }, authHeader(accessToken))

    const res = await get(`/api/v1/hotels/${hotelId}/halls/${created.data.id}`)
    assert.equal(res.status, 404)
  })

  test('a different Hotel Manager never sees a Hidden Hall (404, never leaked)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const { body: created } = await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: { name: 'Test Hall', capacity: 50 } }, authHeader(accessToken))
    const { accessToken: otherToken } = await registerAndLoginHotelManager()

    const res = await get(`/api/v1/hotels/${hotelId}/halls/${created.data.id}`, authHeader(otherToken))
    assert.equal(res.status, 404)
  })

  test('an unauthenticated caller sees a Visible Hall (200, no account required, BDR-009)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createApprovedHotel(accessToken)
    const { body: created } = await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: { name: 'Test Hall', capacity: 50 } }, authHeader(accessToken))

    const res = await get(`/api/v1/hotels/${hotelId}/halls/${created.data.id}`)
    assert.equal(res.status, 200)
    assert.equal(res.body.data.id, created.data.id)
  })

  test('returns 404 for a nonexistent Hall id', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)

    const res = await get(`/api/v1/hotels/${hotelId}/halls/00000000-0000-0000-0000-000000000000`, authHeader(accessToken))
    assert.equal(res.status, 404)
  })
})

describe('PATCH /api/v1/hotels/:hotelId/halls/:id (WBS-05, HL3, BR-HALL-07)', () => {
  test('the owning Hotel Manager updates a Hall (200, applies immediately)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const { body: created } = await post(
      `/api/v1/hotels/${hotelId}/halls`,
      { profileData: { name: 'Original', capacity: 50 } },
      authHeader(accessToken),
    )

    const res = await patch(
      `/api/v1/hotels/${hotelId}/halls/${created.data.id}`,
      { name: 'Renamed' },
      authHeader(accessToken),
    )
    assert.equal(res.status, 200)
    assert.equal(res.body.data.profileData.name, 'Renamed')
  })

  test('a different Hotel Manager cannot update the Hall (404, not 403)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const { body: created } = await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: { name: 'Test Hall', capacity: 50 } }, authHeader(accessToken))
    const { accessToken: otherToken } = await registerAndLoginHotelManager()

    const res = await patch(`/api/v1/hotels/${hotelId}/halls/${created.data.id}`, { name: 'Hijacked' }, authHeader(otherToken))
    assert.equal(res.status, 404)
  })

  test('rejects an unauthenticated request (401)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const { body: created } = await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: { name: 'Test Hall', capacity: 50 } }, authHeader(accessToken))

    const res = await patch(`/api/v1/hotels/${hotelId}/halls/${created.data.id}`, { name: 'x' })
    assert.equal(res.status, 401)
  })

  test('rejects an empty update body (400)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const { body: created } = await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: { name: 'Test Hall', capacity: 50 } }, authHeader(accessToken))

    const res = await patch(`/api/v1/hotels/${hotelId}/halls/${created.data.id}`, {}, authHeader(accessToken))
    assert.equal(res.status, 400)
  })

  test('updates Capacity, Description, and Location/Area (BDR-016)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const { body: created } = await post(
      `/api/v1/hotels/${hotelId}/halls`,
      { profileData: { name: 'Original', capacity: 50 } },
      authHeader(accessToken),
    )

    const res = await patch(
      `/api/v1/hotels/${hotelId}/halls/${created.data.id}`,
      { capacity: 120, description: 'Newly renovated.', location: 'Ground floor' },
      authHeader(accessToken),
    )
    assert.equal(res.status, 200)
    assert.equal(res.body.data.profileData.capacity, 120)
    assert.equal(res.body.data.profileData.description, 'Newly renovated.')
    assert.equal(res.body.data.profileData.location, 'Ground floor')
    // Untouched fields are preserved (merge, not replace).
    assert.equal(res.body.data.profileData.name, 'Original')
  })

  test('manages a custom field without touching the standard fields (BDR-016)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const { body: created } = await post(
      `/api/v1/hotels/${hotelId}/halls`,
      { profileData: { name: 'Original', capacity: 50 } },
      authHeader(accessToken),
    )

    const res = await patch(
      `/api/v1/hotels/${hotelId}/halls/${created.data.id}`,
      { amenities: 'Stage, Sound System' },
      authHeader(accessToken),
    )
    assert.equal(res.status, 200)
    assert.equal(res.body.data.profileData.amenities, 'Stage, Sound System')
    assert.equal(res.body.data.profileData.name, 'Original')
    assert.equal(res.body.data.profileData.capacity, 50)
  })

  test('rejects clearing Hall Name to empty (400, BDR-016)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const { body: created } = await post(
      `/api/v1/hotels/${hotelId}/halls`,
      { profileData: { name: 'Original', capacity: 50 } },
      authHeader(accessToken),
    )

    const res = await patch(`/api/v1/hotels/${hotelId}/halls/${created.data.id}`, { name: '' }, authHeader(accessToken))
    assert.equal(res.status, 400)
    assert.ok(res.body.details.some((d) => d.field === 'name'))
  })

  test('rejects an invalid Capacity on update (400, BDR-016)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    const { body: created } = await post(
      `/api/v1/hotels/${hotelId}/halls`,
      { profileData: { name: 'Original', capacity: 50 } },
      authHeader(accessToken),
    )

    const res = await patch(`/api/v1/hotels/${hotelId}/halls/${created.data.id}`, { capacity: 0 }, authHeader(accessToken))
    assert.equal(res.status, 400)
    assert.ok(res.body.details.some((d) => d.field === 'capacity'))
  })
})

describe('GET /api/v1/hotels/:hotelId/halls (WBS-05, Technical Design §11)', () => {
  test('the owning Hotel Manager sees every Hall, including Hidden ones', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: { name: 'Test Hall', capacity: 50 } }, authHeader(accessToken))
    await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: { name: 'Test Hall', capacity: 50 } }, authHeader(accessToken))

    const res = await get(`/api/v1/hotels/${hotelId}/halls`, authHeader(accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.length, 2)
    assert.equal(res.body.pagination.total, 2)
  })

  test('an unauthenticated caller sees an empty page for an ineligible Hotel (200, never leaked as 404 per-Hall)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)
    await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: { name: 'Test Hall', capacity: 50 } }, authHeader(accessToken))

    const res = await get(`/api/v1/hotels/${hotelId}/halls`)
    assert.equal(res.status, 200)
    assert.deepEqual(res.body.data, [])
    assert.equal(res.body.pagination.total, 0)
  })

  test('an unauthenticated caller sees every Hall of an eligible Hotel (BDR-009)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createApprovedHotel(accessToken)
    await post(`/api/v1/hotels/${hotelId}/halls`, { profileData: { name: 'Test Hall', capacity: 50 } }, authHeader(accessToken))

    const res = await get(`/api/v1/hotels/${hotelId}/halls`)
    assert.equal(res.status, 200)
    assert.equal(res.body.data.length, 1)
  })

  test('returns 404 for a nonexistent Hotel id', async () => {
    const res = await get('/api/v1/hotels/00000000-0000-0000-0000-000000000000/halls')
    assert.equal(res.status, 404)
  })

  test('response uses offset pagination, not cursor (coding-standards.md §6, distinct from GET /api/v1/halls)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await createUnapprovedHotel(accessToken)

    const res = await get(`/api/v1/hotels/${hotelId}/halls`, authHeader(accessToken))
    assert.equal(res.status, 200)
    assert.ok('page' in res.body.pagination)
    assert.ok('total' in res.body.pagination)
    assert.ok('totalPages' in res.body.pagination)
    assert.ok(!('nextCursor' in res.body.pagination), 'must not use cursor pagination fields')
  })
})
