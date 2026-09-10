import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import * as applicationService from '../../hotels/application.service.js'
import * as hotelService from '../../hotels/hotel.service.js'

/**
 * Integration tests for Ratings & Reviews V1 (approved business decisions)
 * — real Prisma queries against a real test database, same `createApp()` +
 * real `fetch` pattern as favorites.integration.test.js. Bookings are
 * inserted directly via Prisma in an exact status (the same legitimate
 * "simulate pre-existing data" technique popular.integration.test.js and
 * nearby.integration.test.js already use) rather than driven through the
 * full multi-step booking workflow, which is unrelated to what this file
 * verifies.
 */

let server
let baseUrl
let adminStubUserId

const DAY_MS = 24 * 60 * 60 * 1000

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

async function registerAndLogin(accountType) {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  // BDR-018/BDR-019: Full Name is required at registration for a CUSTOMER or
  // HOTEL_MANAGER account.
  const fullName = accountType === 'CUSTOMER' ? 'Test Customer' : accountType === 'HOTEL_MANAGER' ? 'Test Manager' : undefined
  await post('/api/v1/auth/register', { mobileNumber, password, accountType, fullName })
  const loginRes = await post('/api/v1/auth/login', { mobileNumber, password })
  return { mobileNumber, userId: loginRes.body.data.user.id, ...loginRes.body.data }
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

function completeHotelProfile() {
  return {
    name: 'Reviews Test Hotel',
    description: 'A Hotel used only for Ratings & Reviews integration tests.',
    location: { latitude: -1.286389, longitude: 36.817223, address: 'Test Address' },
    contactPhone: '+15550001111',
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

async function addHall(hotelId) {
  return prisma.hall.create({ data: { hotelId, profileData: { name: 'Test Hall', capacity: 100 } } })
}

let slotCounter = 0
function nextSlot({ inThePast = true } = {}) {
  slotCounter += 1
  const base = inThePast
    ? Date.UTC(2020, 0, 1, 0, 0, 0)
    : Date.now() + 365 * DAY_MS
  const startsAt = new Date(base + slotCounter * 4 * 60 * 60 * 1000)
  return { startsAt, endsAt: new Date(startsAt.getTime() + 3 * 60 * 60 * 1000) }
}

/** Inserts a Booking row directly with an explicit status — bypassing the booking workflow entirely. */
async function createBookingDirect({ hotelId, hallId, customerUserId, status, inThePast = true }) {
  const { startsAt, endsAt } = nextSlot({ inThePast })
  return prisma.booking.create({
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
      completedAt: status === 'COMPLETED' ? endsAt : null,
    },
  })
}

/** A COMPLETED Booking for a fresh Customer at a fresh, approved Hotel. Returns { customer, bookingId, hotelId }. */
async function completedBookingFixture() {
  const hotelId = await approveHotel()
  const hall = await addHall(hotelId)
  const customer = await registerAndLogin('CUSTOMER')
  const booking = await createBookingDirect({
    hotelId,
    hallId: hall.id,
    customerUserId: customer.userId,
    status: 'COMPLETED',
  })
  return { customer, bookingId: booking.id, hotelId }
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

describe('POST /bookings/:bookingId/review', () => {
  test('rejects an unauthenticated request', async () => {
    const { bookingId } = await completedBookingFixture()
    const res = await post(`/api/v1/bookings/${bookingId}/review`, { rating: 5 })
    assert.equal(res.status, 401)
  })

  test('rejects a HOTEL_MANAGER account', async () => {
    const { bookingId } = await completedBookingFixture()
    const { accessToken } = await registerAndLogin('HOTEL_MANAGER')
    const res = await post(`/api/v1/bookings/${bookingId}/review`, { rating: 5 }, authHeader(accessToken))
    assert.equal(res.status, 403)
  })

  test('a Customer with a COMPLETED Booking can submit a review', async () => {
    const { customer, bookingId } = await completedBookingFixture()
    const res = await post(`/api/v1/bookings/${bookingId}/review`, { rating: 4, text: 'Great stay.' }, authHeader(customer.accessToken))
    assert.equal(res.status, 201)
    assert.equal(res.body.data.review.rating, 4)
    assert.equal(res.body.data.review.text, 'Great stay.')
    assert.ok(res.body.data.review.id)
    assert.ok(res.body.data.review.createdAt)
  })

  test('review text is optional', async () => {
    const { customer, bookingId } = await completedBookingFixture()
    const res = await post(`/api/v1/bookings/${bookingId}/review`, { rating: 3 }, authHeader(customer.accessToken))
    assert.equal(res.status, 201)
    assert.equal(res.body.data.review.rating, 3);
    assert.equal(res.body.data.review.text, null)
  })

  test('rejects rating 0, 6, and a non-integer rating', async () => {
    const { customer, bookingId } = await completedBookingFixture()
    for (const rating of [0, 6, 3.5, 'five']) {
      const res = await post(`/api/v1/bookings/${bookingId}/review`, { rating }, authHeader(customer.accessToken))
      assert.equal(res.status, 400, `expected rating ${rating} to be rejected`)
    }
  })

  test('rejects a missing rating', async () => {
    const { customer, bookingId } = await completedBookingFixture()
    const res = await post(`/api/v1/bookings/${bookingId}/review`, { text: 'no rating' }, authHeader(customer.accessToken))
    assert.equal(res.status, 400)
  })

  test('rejects reviewing a PENDING Booking', async () => {
    const hotelId = await approveHotel()
    const hall = await addHall(hotelId)
    const customer = await registerAndLogin('CUSTOMER')
    const booking = await createBookingDirect({ hotelId, hallId: hall.id, customerUserId: customer.userId, status: 'PENDING' })

    const res = await post(`/api/v1/bookings/${booking.id}/review`, { rating: 5 }, authHeader(customer.accessToken))
    assert.equal(res.status, 409)
  })

  test('rejects reviewing a CONFIRMED (not yet completed) Booking', async () => {
    const hotelId = await approveHotel()
    const hall = await addHall(hotelId)
    const customer = await registerAndLogin('CUSTOMER')
    const booking = await createBookingDirect({ hotelId, hallId: hall.id, customerUserId: customer.userId, status: 'CONFIRMED' })

    const res = await post(`/api/v1/bookings/${booking.id}/review`, { rating: 5 }, authHeader(customer.accessToken))
    assert.equal(res.status, 409)
  })

  test('rejects reviewing a CANCELLED, REJECTED, NO_SHOW, or EXPIRED Booking', async () => {
    const hotelId = await approveHotel()
    const hall = await addHall(hotelId)
    const customer = await registerAndLogin('CUSTOMER')
    for (const status of ['CANCELLED', 'REJECTED', 'NO_SHOW', 'EXPIRED']) {
      const booking = await createBookingDirect({ hotelId, hallId: hall.id, customerUserId: customer.userId, status })
      const res = await post(`/api/v1/bookings/${booking.id}/review`, { rating: 5 }, authHeader(customer.accessToken))
      assert.equal(res.status, 409, `expected status ${status} to be rejected`)
    }
  })

  test("rejects reviewing another Customer's COMPLETED Booking as 404, never 403", async () => {
    const { bookingId } = await completedBookingFixture()
    const otherCustomer = await registerAndLogin('CUSTOMER')
    const res = await post(`/api/v1/bookings/${bookingId}/review`, { rating: 5 }, authHeader(otherCustomer.accessToken))
    assert.equal(res.status, 404)
  })

  test('rejects a duplicate review for the same Booking', async () => {
    const { customer, bookingId } = await completedBookingFixture()
    const first = await post(`/api/v1/bookings/${bookingId}/review`, { rating: 5 }, authHeader(customer.accessToken))
    assert.equal(first.status, 201)

    const second = await post(`/api/v1/bookings/${bookingId}/review`, { rating: 1 }, authHeader(customer.accessToken))
    assert.equal(second.status, 409)
  })

  test('a nonexistent Booking is a 404', async () => {
    const { customer } = await completedBookingFixture()
    const res = await post('/api/v1/bookings/00000000-0000-0000-0000-000000000000/review', { rating: 5 }, authHeader(customer.accessToken))
    assert.equal(res.status, 404)
  })
})

describe('GET /hotels/:hotelId/reviews and Hotel Detail review summary', () => {
  test('a Hotel with zero reviews shows a null average, zero count, and an empty list', async () => {
    const hotelId = await approveHotel()

    const detail = await get(`/api/v1/hotels/public/${hotelId}`)
    assert.equal(detail.status, 200)
    assert.equal(detail.body.data.reviewSummary.average, null)
    assert.equal(detail.body.data.reviewSummary.count, 0)

    const list = await get(`/api/v1/hotels/${hotelId}/reviews`)
    assert.equal(list.status, 200)
    assert.deepEqual(list.body.data, [])
  })

  test('the average and count reflect submitted reviews, and the list is newest-first', async () => {
    const hotelId = await approveHotel()
    const hall = await addHall(hotelId)

    const ratings = [5, 3, 4]
    for (const rating of ratings) {
      const customer = await registerAndLogin('CUSTOMER')
        const booking = await createBookingDirect({ hotelId, hallId: hall.id, customerUserId: customer.userId, status: 'COMPLETED' })
      const res = await post(`/api/v1/bookings/${booking.id}/review`, { rating, text: `Rated ${rating}` }, authHeader(customer.accessToken))
      assert.equal(res.status, 201)
    }

    const detail = await get(`/api/v1/hotels/public/${hotelId}`)
    assert.equal(detail.body.data.reviewSummary.count, 3)
    assert.equal(detail.body.data.reviewSummary.average, 4)

    const list = await get(`/api/v1/hotels/${hotelId}/reviews`)
    assert.equal(list.status, 200)
    assert.equal(list.body.data.length, 3)
    assert.deepEqual(list.body.data.map((r) => r.text), ['Rated 4', 'Rated 3', 'Rated 5'])
    assert.equal(list.body.data[0].rating, 4)
    // No Customer identity is ever exposed on a public review.
    for (const review of list.body.data) {
      assert.equal('customerUserId' in review, false)
      assert.equal('bookingId' in review, false)
    }
  })

  test('rejects an invalid limit', async () => {
    const hotelId = await approveHotel()
    const res = await get(`/api/v1/hotels/${hotelId}/reviews?limit=0`)
    assert.equal(res.status, 400)
  })
})
