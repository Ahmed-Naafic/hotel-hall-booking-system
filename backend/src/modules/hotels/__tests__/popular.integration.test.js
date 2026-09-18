import { test, describe, before, after, afterEach } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import * as applicationService from '../application.service.js'
import * as hotelService from '../hotel.service.js'

/**
 * Integration tests for Popular Hotels (Customer Mobile, approved V1
 * business rules) — real Prisma queries against a real test database, same
 * `createApp()` + real `fetch` pattern as hotels.integration.test.js and
 * nearby.integration.test.js.
 *
 * Bookings are inserted directly via Prisma (not through the full booking
 * workflow) so each test can place a Booking in an exact status with an
 * exact qualifying timestamp — a legitimate simulation of pre-existing
 * data, the same technique nearby.integration.test.js uses to simulate a
 * legacy plain-string location.
 */

let server
let baseUrl
let adminStubUserId

const DAY_MS = 24 * 60 * 60 * 1000

// The Popular Hotels endpoint defaults to a top-20 result and this test
// suite runs against a real, never-truncated dev database that keeps
// accumulating qualifying Hotels from every past test run — as of writing,
// well over 100 of them. Every assertion below that needs to find its own
// freshly created Hotel in the response therefore asks for a generously
// large page (`?limit=1000`, far above any realistic accumulated pool) so
// the result is never a ranking accident. This does not change production
// behavior — `limit` is an existing, unbounded, caller-supplied query
// parameter (`hotelValidation.validatePopularHotels`).
const POPULAR_LIST_QUERY = '?limit=1000'

// Isolation: every row this file creates (Bookings, Hotels — along with
// their Halls, which the schema does not cascade-delete from Hotel — and
// the Customer/Hotel Manager Users used to create them) is tracked here and
// deleted in `afterEach`, so this suite stops contributing further to the
// shared dev database's Popular Hotels pool on every run. The one exception
// is `adminStubUserId`, shared by the whole file and cleaned up once in the
// top-level `after()` instead. Deletion order matters and is enforced by
// the schema's own foreign keys, not just convention: Bookings first (no
// cascade from either Hotel or Hall), then Halls (no cascade from Hotel —
// `HotelMedia`/`HotelApplication`/`Review` *do* cascade from Hotel, so
// deleting the Hotel itself is enough for those), then Hotels, then Users.
let createdBookingIds = []
let createdHotelIds = []
let createdUserIds = []

afterEach(async () => {
  await prisma.booking.deleteMany({ where: { id: { in: createdBookingIds } } })
  await prisma.hall.deleteMany({ where: { hotelId: { in: createdHotelIds } } })
  await prisma.hotel.deleteMany({ where: { id: { in: createdHotelIds } } })
  await prisma.user.deleteMany({ where: { id: { in: createdUserIds } } })
  createdBookingIds = []
  createdHotelIds = []
  createdUserIds = []
})

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
  createdUserIds.push(loginRes.body.data.user.id)
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
    name: 'Popular Test Hotel',
    description: 'A Hotel used only for Popular Hotels integration tests.',
    location: { latitude: -1.286389, longitude: 36.817223, address: 'Downtown, Nairobi' },
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

/** Registers, completes profile, and approves a Hotel — returns its id. */
async function approveHotel() {
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

async function addPhoto(hotelId) {
  return prisma.hotelMedia.create({
    data: { hotelId, type: 'PHOTO', storagePath: `hotels/${hotelId}/photos/test.jpg` },
  })
}

async function addHall(hotelId) {
  return prisma.hall.create({ data: { hotelId, profileData: { name: 'Test Hall', capacity: 100 } } })
}

/** A fully eligible Hotel: APPROVED_ACTIVE, ≥1 photo, ≥1 Hall. Returns { hotelId, hallId }. */
async function eligibleHotel() {
  const hotelId = await approveHotel()
  await addPhoto(hotelId)
  const hall = await addHall(hotelId)
  return { hotelId, hallId: hall.id }
}

async function createCustomer() {
  const mobileNumber = uniqueMobileNumber()
  const customer = await prisma.user.create({
    data: { mobileNumber, passwordHash: 'x', accountType: 'CUSTOMER', isVerified: true },
  })
  createdUserIds.push(customer.id)
  return customer
}

// Each Hall has a real, enforced non-overlap constraint on (hallId, period)
// regardless of Booking status — a genuine business rule, not something
// this test works around. Every direct-inserted Booking here gets its own
// slot, offset by this ever-increasing counter, purely so multiple
// qualifying-popularity fixtures on the same Hall don't collide on time.
let slotCounter = 0
function nextSlot() {
  slotCounter += 1
  const startsAt = new Date(Date.UTC(2020, 0, 1, 0, 0, 0) + slotCounter * 4 * 60 * 60 * 1000)
  return { startsAt, endsAt: new Date(startsAt.getTime() + 3 * 60 * 60 * 1000) }
}

/**
 * Inserts a Booking row directly with an explicit status and an explicit
 * qualifying timestamp — bypassing the booking workflow entirely, the same
 * "simulate pre-existing data" technique nearby.integration.test.js uses.
 */
async function createBookingDirect({ hotelId, hallId, customerUserId, status, updatedAt, completedAt }) {
  const { startsAt, endsAt } = nextSlot()
  const booking = await prisma.booking.create({
    data: {
      customerUserId,
      hotelId,
      hallId,
      startsAt,
      endsAt,
      numberOfGuests: 10,
      eventType: 'OTHER',
      status,
      paymentDeadlineAt: new Date(startsAt.getTime() + DAY_MS),
      totalRentCents: 10000,
      advancePercentSnapshot: 30,
      requiredAdvanceCents: 3000,
      completedAt: completedAt ?? null,
      updatedAt,
    },
  })
  createdBookingIds.push(booking.id)
  return booking
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
  await prisma.user.deleteMany({ where: { id: adminStubUserId } })
  await new Promise((resolve) => server.close(resolve))
})

describe('GET /hotels/public/popular', () => {
  test('a Hotel with one qualifying CONFIRMED booking appears', async () => {
    const { hotelId, hallId } = await eligibleHotel()
    const customer = await createCustomer()
    await createBookingDirect({
      hotelId,
      hallId,
      customerUserId: customer.id,
      status: 'CONFIRMED',
      updatedAt: new Date(),
    })

    const res = await get('/api/v1/hotels/public/popular' + POPULAR_LIST_QUERY)
    assert.equal(res.status, 200)
    const match = res.body.data.find((h) => h.id === hotelId)
    assert.ok(match, 'expected the Hotel to appear in Popular Hotels')
    assert.equal(match.bookingCount, 1)
  })

  test('a Hotel with one qualifying COMPLETED booking appears', async () => {
    const { hotelId, hallId } = await eligibleHotel()
    const customer = await createCustomer()
    await createBookingDirect({
      hotelId,
      hallId,
      customerUserId: customer.id,
      status: 'COMPLETED',
      updatedAt: new Date(),
      completedAt: new Date(),
    })

    const res = await get('/api/v1/hotels/public/popular' + POPULAR_LIST_QUERY)
    const match = res.body.data.find((h) => h.id === hotelId)
    assert.ok(match, 'expected the Hotel to appear in Popular Hotels')
    assert.equal(match.bookingCount, 1)
  })

  test('CONFIRMED and COMPLETED bookings aggregate into a single count', async () => {
    const { hotelId, hallId } = await eligibleHotel()
    const customer = await createCustomer()
    await createBookingDirect({ hotelId, hallId, customerUserId: customer.id, status: 'CONFIRMED', updatedAt: new Date() })
    await createBookingDirect({ hotelId, hallId, customerUserId: customer.id, status: 'CONFIRMED', updatedAt: new Date() })
    await createBookingDirect({
      hotelId,
      hallId,
      customerUserId: customer.id,
      status: 'COMPLETED',
      updatedAt: new Date(),
      completedAt: new Date(),
    })

    const res = await get('/api/v1/hotels/public/popular' + POPULAR_LIST_QUERY)
    const match = res.body.data.find((h) => h.id === hotelId)
    assert.equal(match.bookingCount, 3)
  })

  test('PENDING, REJECTED, CANCELLED, NO_SHOW, and EXPIRED bookings never count', async () => {
    const { hotelId, hallId } = await eligibleHotel()
    const customer = await createCustomer()
    for (const status of ['PENDING', 'REJECTED', 'CANCELLED', 'NO_SHOW', 'EXPIRED']) {
      await createBookingDirect({ hotelId, hallId, customerUserId: customer.id, status, updatedAt: new Date() })
    }

    const res = await get('/api/v1/hotels/public/popular' + POPULAR_LIST_QUERY)
    assert.equal(res.body.data.some((h) => h.id === hotelId), false)
  })

  test('a CONFIRMED booking older than 90 days does not count', async () => {
    const { hotelId, hallId } = await eligibleHotel()
    const customer = await createCustomer()
    await createBookingDirect({
      hotelId,
      hallId,
      customerUserId: customer.id,
      status: 'CONFIRMED',
      updatedAt: new Date(Date.now() - 91 * DAY_MS),
    })

    const res = await get('/api/v1/hotels/public/popular' + POPULAR_LIST_QUERY)
    assert.equal(res.body.data.some((h) => h.id === hotelId), false)
  })

  test('a booking exactly at the 90-day boundary is included (documented inclusive rule)', async () => {
    const { hotelId, hallId } = await eligibleHotel()
    const customer = await createCustomer()
    // Comfortably inside the inclusive >= cutoff, not right on the millisecond
    // (avoids flakiness from the small gap between "now" here and in the service).
    await createBookingDirect({
      hotelId,
      hallId,
      customerUserId: customer.id,
      status: 'CONFIRMED',
      updatedAt: new Date(Date.now() - 90 * DAY_MS + 60000),
    })

    const res = await get('/api/v1/hotels/public/popular' + POPULAR_LIST_QUERY)
    assert.equal(res.body.data.some((h) => h.id === hotelId), true)
  })

  test('multiple Halls belonging to one Hotel aggregate into a single Hotel count, never double-counted', async () => {
    const hotelId = await approveHotel()
    await addPhoto(hotelId)
    const hallA = await addHall(hotelId)
    const hallB = await addHall(hotelId)
    const customer = await createCustomer()
    for (let i = 0; i < 5; i++) {
      await createBookingDirect({ hotelId, hallId: hallA.id, customerUserId: customer.id, status: 'CONFIRMED', updatedAt: new Date() })
    }
    for (let i = 0; i < 7; i++) {
      await createBookingDirect({ hotelId, hallId: hallB.id, customerUserId: customer.id, status: 'CONFIRMED', updatedAt: new Date() })
    }

    const res = await get('/api/v1/hotels/public/popular' + POPULAR_LIST_QUERY)
    const match = res.body.data.find((h) => h.id === hotelId)
    assert.equal(match.bookingCount, 12)
  })

  test('a non-APPROVED_ACTIVE Hotel is excluded even with qualifying bookings', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))
    const hotelId = created.data.id
    createdHotelIds.push(hotelId)
    await patch(`/api/v1/hotels/${hotelId}`, completeHotelProfile(), authHeader(accessToken))
    await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
    // Deliberately not approved — stays UNDER_REVIEW.
    await addPhoto(hotelId)
    const hall = await addHall(hotelId)
    const customer = await createCustomer()
    await createBookingDirect({ hotelId, hallId: hall.id, customerUserId: customer.id, status: 'CONFIRMED', updatedAt: new Date() })

    const res = await get('/api/v1/hotels/public/popular' + POPULAR_LIST_QUERY)
    assert.equal(res.body.data.some((h) => h.id === hotelId), false)
  })

  test('a Hotel with no Halls is excluded even with qualifying bookings', async () => {
    const hotelId = await approveHotel()
    await addPhoto(hotelId)
    // No Hall created — but a Booking still needs a real hallId FK, so this
    // simulates the data state (qualifying Bookings exist, Hall since
    // removed) rather than requiring a hall-less Booking to exist.
    const hall = await addHall(hotelId)
    const customer = await createCustomer()
    await createBookingDirect({ hotelId, hallId: hall.id, customerUserId: customer.id, status: 'CONFIRMED', updatedAt: new Date() })
    await prisma.hall.update({ where: { id: hall.id }, data: { deletedAt: new Date() } })

    const res = await get('/api/v1/hotels/public/popular' + POPULAR_LIST_QUERY)
    assert.equal(res.body.data.some((h) => h.id === hotelId), false)
  })

  test('a Hotel with no photos is excluded even with qualifying bookings and a Hall', async () => {
    const hotelId = await approveHotel()
    const hall = await addHall(hotelId)
    // No HotelMedia PHOTO created.
    const customer = await createCustomer()
    await createBookingDirect({ hotelId, hallId: hall.id, customerUserId: customer.id, status: 'CONFIRMED', updatedAt: new Date() })

    const res = await get('/api/v1/hotels/public/popular' + POPULAR_LIST_QUERY)
    assert.equal(res.body.data.some((h) => h.id === hotelId), false)
  })

  test('Hotels are sorted by qualifying booking count, highest first', async () => {
    const low = await eligibleHotel()
    const high = await eligibleHotel()
    const mid = await eligibleHotel()
    const customer = await createCustomer()
    for (let i = 0; i < 2; i++) await createBookingDirect({ hotelId: low.hotelId, hallId: low.hallId, customerUserId: customer.id, status: 'CONFIRMED', updatedAt: new Date() })
    for (let i = 0; i < 9; i++) await createBookingDirect({ hotelId: high.hotelId, hallId: high.hallId, customerUserId: customer.id, status: 'CONFIRMED', updatedAt: new Date() })
    for (let i = 0; i < 5; i++) await createBookingDirect({ hotelId: mid.hotelId, hallId: mid.hallId, customerUserId: customer.id, status: 'CONFIRMED', updatedAt: new Date() })

    const res = await get('/api/v1/hotels/public/popular' + POPULAR_LIST_QUERY)
    const order = res.body.data.map((h) => h.id).filter((id) => [low.hotelId, high.hotelId, mid.hotelId].includes(id))
    assert.deepEqual(order, [high.hotelId, mid.hotelId, low.hotelId])
  })

  test('a tie in booking count breaks deterministically toward the most recent qualifying activity', async () => {
    const older = await eligibleHotel()
    const newer = await eligibleHotel()
    const customer = await createCustomer()
    const olderTime = new Date(Date.now() - 10 * DAY_MS)
    const newerTime = new Date(Date.now() - 1 * DAY_MS)
    for (let i = 0; i < 3; i++) {
      await createBookingDirect({ hotelId: older.hotelId, hallId: older.hallId, customerUserId: customer.id, status: 'CONFIRMED', updatedAt: olderTime })
    }
    for (let i = 0; i < 3; i++) {
      await createBookingDirect({ hotelId: newer.hotelId, hallId: newer.hallId, customerUserId: customer.id, status: 'CONFIRMED', updatedAt: newerTime })
    }

    const res = await get('/api/v1/hotels/public/popular' + POPULAR_LIST_QUERY)
    const olderIndex = res.body.data.findIndex((h) => h.id === older.hotelId)
    const newerIndex = res.body.data.findIndex((h) => h.id === newer.hotelId)
    assert.ok(newerIndex >= 0 && olderIndex >= 0);
    assert.ok(newerIndex < olderIndex, 'the Hotel with more recent qualifying activity should rank first on a tie')
  })

  test('requires no authentication', async () => {
    const res = await get('/api/v1/hotels/public/popular' + POPULAR_LIST_QUERY)
    assert.equal(res.status, 200)
  })

  test('rejects an invalid limit', async () => {
    const res = await get('/api/v1/hotels/public/popular?limit=0')
    assert.equal(res.status, 400)
  })

  test('existing GET /hotels/public behavior is unaffected by this feature', async () => {
    const { hotelId } = await eligibleHotel()
    const res = await get('/api/v1/hotels/public')
    assert.equal(res.status, 200)
    assert.equal(res.body.data.some((h) => h.id === hotelId), true)
    assert.equal(res.body.data[0].bookingCount, undefined)
  })
})
