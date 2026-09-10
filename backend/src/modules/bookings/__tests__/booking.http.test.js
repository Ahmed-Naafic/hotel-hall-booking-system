import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import { smsProvider } from '../../../shared/providers/smsProvider.js'
import * as hotelService from '../../hotels/hotel.service.js'
import * as applicationService from '../../hotels/application.service.js'
import * as lifecycleService from '../../hotels/lifecycle.service.js'
import * as hallService from '../../halls/hall.service.js'
import * as availabilityService from '../../availability/availability.service.js'

/**
 * HTTP-level integration tests (testing-standards.md §6) — real Prisma
 * queries, a real server, real requests through `authenticate`/
 * `requireAccountType`/`booking.validation.js`, never a mocked auth layer
 * or a direct `booking.service.js` call. Complements
 * `booking.integration.test.js` (service-layer pricing/lifecycle/overlap
 * behavior), which does not exercise route wiring, role/ownership
 * middleware, or request validation at all — this file exists to close
 * that gap (Booking Management V1 correction #5).
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

// No Twilio credentials are configured for the test run, so `smsProvider`
// is MockSmsProvider (same convention as authentication.integration.test.js).
function codeSentTo(mobileNumber) {
  const message = smsProvider.getLastMessageTo(mobileNumber)
  assert.ok(message, `expected a message to have been sent to ${mobileNumber}`)
  const match = message.body.match(/\d{6}/)
  assert.ok(match, `expected a 6-digit code in the message body: ${message.body}`)
  return match[0]
}

async function registerAndLogin(accountType) {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  // BDR-018/BDR-019: Full Name is required at registration for a CUSTOMER or
  // HOTEL_MANAGER account.
  const fullName = accountType === 'CUSTOMER' ? 'Test Customer' : accountType === 'HOTEL_MANAGER' ? 'Test Manager' : undefined
  await post('/api/v1/auth/register', { mobileNumber, password, accountType, fullName })
  const loginRes = await post('/api/v1/auth/login', { mobileNumber, password })
  return { mobileNumber, password, ...loginRes.body.data }
}

/** A Customer who has completed identity verification (BR-AUTH-02) — only these may book. */
async function registerVerifiedCustomer() {
  const customer = await registerAndLogin('CUSTOMER')
  await post('/api/v1/auth/verifications', undefined, authHeader(customer.accessToken))
  const code = codeSentTo(customer.mobileNumber)
  await post('/api/v1/auth/verifications/confirm', { code }, authHeader(customer.accessToken))
  return customer
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
    name: 'Grand Test Hotel',
    description: 'A comfortable city hotel with flexible halls.',
    location: { latitude: -1.286389, longitude: 36.817223, address: 'Downtown, Nairobi' },
    contactPhone: '+15550001111',
  }
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

/** Registers a Hotel that never reaches Approved/Active — remains REGISTERED (never Visible/eligible). */
async function createUnapprovedHotel(accessToken) {
  const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))
  return created.data.id
}

/** A fully-terms-complete Hall — booking creation requires this (BR-BOOKING-05). */
async function createHall(hotelId, { profileData, commercialData } = {}) {
  return hallService.createHall({
    hotelId,
    profileData: { name: 'Main Hall', capacity: 200, ...profileData },
    commercialData: {
      rentAmountCents: 50000,
      rentDurationHours: 24,
      advancePaymentPercent: 30,
      customerServiceNumber: '+252610000001',
      paymentReceivingNumber: '+252610000002',
      ...commercialData,
    },
  })
}

function futureRange(offsetDays = 10, hours = 24) {
  const startsAt = new Date(Date.now() + offsetDays * 86400000)
  const endsAt = new Date(startsAt.getTime() + hours * 3600000)
  return { startsAt: startsAt.toISOString(), endsAt: endsAt.toISOString() }
}

/** A fresh Customer + Hall + PENDING/UNPAID booking, ready for payment/cancellation tests. */
async function createPendingBooking({ guests = 50, capacity = 200 } = {}) {
  const customer = await registerVerifiedCustomer()
  const manager = await registerAndLogin('HOTEL_MANAGER')
  const hotelId = await createApprovedHotel(manager.accessToken)
  const hall = await createHall(hotelId, { profileData: { capacity } })
  const { startsAt, endsAt } = futureRange()
  const created = await post(
    '/api/v1/bookings',
    { hallId: hall.id, startsAt, endsAt, numberOfGuests: guests, eventType: 'WEDDING' },
    authHeader(customer.accessToken),
  )
  return { customer, manager, hotelId, hall, booking: created.body.data }
}

/** A PENDING booking whose required advance has already been reported and verified as PAID. */
async function createPaidBooking(overrides) {
  const context = await createPendingBooking(overrides)
  await post(`/api/v1/bookings/${context.booking.id}/payment-report`, { amountCents: context.booking.pricing.requiredAdvanceCents }, authHeader(context.customer.accessToken))
  await post(`/api/v1/hotels/${context.hotelId}/bookings/${context.booking.id}/payment-verification`, { decision: 'VERIFY' }, authHeader(context.manager.accessToken))
  return context
}

before(async () => {
  const app = createApp()
  server = app.listen(0)
  await new Promise((resolve) => server.once('listening', resolve))
  baseUrl = `http://127.0.0.1:${server.address().port}`
  const admin = await createPlatformAdministrator()
  adminStubUserId = admin.id
})

after(async () => {
  await new Promise((resolve) => server.close(resolve))
  await prisma.$disconnect()
})

describe('POST /api/v1/bookings — creation', () => {
  test('a verified Customer creates a booking (201) with system-calculated pricing ($500/24h, 30% advance = $150)', async () => {
    const customer = await registerVerifiedCustomer()
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const hotelId = await createApprovedHotel(manager.accessToken)
    const hall = await createHall(hotelId)
    const { startsAt, endsAt } = futureRange()

    const res = await post(
      '/api/v1/bookings',
      { hallId: hall.id, startsAt, endsAt, numberOfGuests: 50, eventType: 'WEDDING' },
      authHeader(customer.accessToken),
    )

    assert.equal(res.status, 201)
    assert.equal(res.body.data.status, 'PENDING')
    assert.equal(res.body.data.paymentStatus, 'UNPAID')
    assert.equal(res.body.data.pricing.totalRentCents, 50000)
    assert.equal(res.body.data.pricing.requiredAdvanceCents, 15000)
  })

  test('an unauthenticated request is rejected (401)', async () => {
    const res = await post('/api/v1/bookings', {})
    assert.equal(res.status, 401)
  })

  test('a wrong account type (Hotel Manager) is rejected (403)', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const hotelId = await createApprovedHotel(manager.accessToken)
    const hall = await createHall(hotelId)
    const { startsAt, endsAt } = futureRange()

    const res = await post(
      '/api/v1/bookings',
      { hallId: hall.id, startsAt, endsAt, numberOfGuests: 10, eventType: 'MEETING' },
      authHeader(manager.accessToken),
    )
    assert.equal(res.status, 403)
  })

  test('an unverified Customer is rejected (422)', async () => {
    const customer = await registerAndLogin('CUSTOMER') // never completes verification
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const hotelId = await createApprovedHotel(manager.accessToken)
    const hall = await createHall(hotelId)
    const { startsAt, endsAt } = futureRange()

    const res = await post(
      '/api/v1/bookings',
      { hallId: hall.id, startsAt, endsAt, numberOfGuests: 10, eventType: 'MEETING' },
      authHeader(customer.accessToken),
    )
    assert.equal(res.status, 422)
  })

  test('an invalid eventType is rejected (400) — the fixed enum is never widened', async () => {
    const customer = await registerVerifiedCustomer()
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const hotelId = await createApprovedHotel(manager.accessToken)
    const hall = await createHall(hotelId)
    const { startsAt, endsAt } = futureRange()

    const res = await post(
      '/api/v1/bookings',
      { hallId: hall.id, startsAt, endsAt, numberOfGuests: 10, eventType: 'PARTY' },
      authHeader(customer.accessToken),
    )
    assert.equal(res.status, 400)
  })

  test('a guest count exceeding Hall capacity is rejected (422)', async () => {
    const customer = await registerVerifiedCustomer()
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const hotelId = await createApprovedHotel(manager.accessToken)
    const hall = await createHall(hotelId, { profileData: { capacity: 20 } })
    const { startsAt, endsAt } = futureRange()

    const res = await post(
      '/api/v1/bookings',
      { hallId: hall.id, startsAt, endsAt, numberOfGuests: 21, eventType: 'MEETING' },
      authHeader(customer.accessToken),
    )
    assert.equal(res.status, 422)
  })

  test('a Hall belonging to a not-yet-eligible Hotel is rejected as not found (404) — never leaks existence', async () => {
    const customer = await registerVerifiedCustomer()
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const hotelId = await createUnapprovedHotel(manager.accessToken)
    const hall = await createHall(hotelId)
    const { startsAt, endsAt } = futureRange()

    const res = await post(
      '/api/v1/bookings',
      { hallId: hall.id, startsAt, endsAt, numberOfGuests: 10, eventType: 'MEETING' },
      authHeader(customer.accessToken),
    )
    assert.equal(res.status, 404)
  })
})

describe('Ownership and cross-tenant access', () => {
  test('a Customer cannot retrieve another Customer\'s booking (404)', async () => {
    const { booking } = await createPendingBooking()
    const other = await registerVerifiedCustomer()

    const res = await get(`/api/v1/bookings/${booking.id}`, authHeader(other.accessToken))
    assert.equal(res.status, 404)
  })

  test('a Hotel Manager cannot retrieve a booking belonging to another Hotel (404)', async () => {
    const { booking } = await createPendingBooking()
    const otherManager = await registerAndLogin('HOTEL_MANAGER')
    const otherHotelId = await createApprovedHotel(otherManager.accessToken)

    const res = await get(`/api/v1/hotels/${otherHotelId}/bookings/${booking.id}`, authHeader(otherManager.accessToken))
    assert.equal(res.status, 404)
  })

  test('a Customer cannot call own-Hotel Manager booking routes (403)', async () => {
    const customer = await registerVerifiedCustomer()
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const hotelId = await createApprovedHotel(manager.accessToken)

    const res = await get(`/api/v1/hotels/${hotelId}/bookings`, authHeader(customer.accessToken))
    assert.equal(res.status, 403)
  })
})

describe('Manager visibility of Customer identity (BDR-018)', () => {
  test('a Hotel Manager viewing a Booking sees the real Customer Full Name and Mobile Number', async () => {
    const { customer, manager, hotelId, booking } = await createPendingBooking()

    const detail = await get(`/api/v1/hotels/${hotelId}/bookings/${booking.id}`, authHeader(manager.accessToken))
    assert.equal(detail.status, 200)
    assert.equal(detail.body.data.customer.fullName, 'Test Customer')
    assert.equal(detail.body.data.customer.mobileNumber, customer.mobileNumber)

    const list = await get(`/api/v1/hotels/${hotelId}/bookings`, authHeader(manager.accessToken))
    assert.equal(list.status, 200)
    const listed = list.body.data.find((b) => b.id === booking.id)
    assert.equal(listed.customer.fullName, 'Test Customer')
    assert.equal(listed.customer.mobileNumber, customer.mobileNumber)
  })

  test('a Manager cannot see Customer information for a Booking outside their own Hotel (404 — same as any other cross-tenant access)', async () => {
    const { booking } = await createPendingBooking()
    const otherManager = await registerAndLogin('HOTEL_MANAGER')
    const otherHotelId = await createApprovedHotel(otherManager.accessToken)

    const res = await get(`/api/v1/hotels/${otherHotelId}/bookings/${booking.id}`, authHeader(otherManager.accessToken))
    assert.equal(res.status, 404)
  })

  test("the Customer's own view of their Booking also includes their own name and number (not a privacy leak — it is their own data)", async () => {
    const { customer, booking } = await createPendingBooking()

    const res = await get(`/api/v1/bookings/${booking.id}`, authHeader(customer.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.customer.fullName, 'Test Customer')
    assert.equal(res.body.data.customer.mobileNumber, customer.mobileNumber)
  })
})

describe('Payment reporting and verification', () => {
  test('a Customer reports a payment (200, CUSTOMER_REPORTED) — never sets PAID directly', async () => {
    const { customer, booking } = await createPendingBooking()

    const res = await post(`/api/v1/bookings/${booking.id}/payment-report`, { amountCents: 100 }, authHeader(customer.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.paymentStatus, 'CUSTOMER_REPORTED')
  })

  test('a Customer reports the exact required advance amount (200) — stored as reported, not yet PAID', async () => {
    const { customer, booking } = await createPendingBooking()

    const res = await post(`/api/v1/bookings/${booking.id}/payment-report`, { amountCents: booking.pricing.requiredAdvanceCents }, authHeader(customer.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.paymentStatus, 'CUSTOMER_REPORTED')
    assert.equal(res.body.data.payment.reportedAmountCents, booking.pricing.requiredAdvanceCents)
  })

  test('the Manager can verify an insufficient reported amount anyway (200, PAID) — the amount is a warning, never a backend block', async () => {
    const { customer, manager, hotelId, booking } = await createPendingBooking()
    await post(`/api/v1/bookings/${booking.id}/payment-report`, { amountCents: 100 }, authHeader(customer.accessToken))

    const res = await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/payment-verification`, { decision: 'VERIFY' }, authHeader(manager.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.paymentStatus, 'PAID')
  })

  test('the Manager verifies a sufficient payment report (200, PAID)', async () => {
    const { customer, manager, hotelId, booking } = await createPendingBooking()
    await post(`/api/v1/bookings/${booking.id}/payment-report`, { amountCents: booking.pricing.requiredAdvanceCents }, authHeader(customer.accessToken))

    const res = await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/payment-verification`, { decision: 'VERIFY' }, authHeader(manager.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.paymentStatus, 'PAID')
  })

  test('the Manager rejects a payment report with a reason (200, REJECTED)', async () => {
    const { customer, manager, hotelId, booking } = await createPendingBooking()
    await post(`/api/v1/bookings/${booking.id}/payment-report`, { amountCents: 100 }, authHeader(customer.accessToken))

    const res = await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/payment-verification`, { decision: 'REJECT', reason: 'Not received.' }, authHeader(manager.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.paymentStatus, 'REJECTED')
  })
})

describe('Manager confirmation', () => {
  test('confirms a PENDING, fully paid booking (200, CONFIRMED)', async () => {
    const { manager, hotelId, booking } = await createPaidBooking()

    const res = await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/confirmation`, undefined, authHeader(manager.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'CONFIRMED')
  })

  test('confirmation fails while payment is not PAID (422)', async () => {
    const { manager, hotelId, booking } = await createPendingBooking()

    const res = await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/confirmation`, undefined, authHeader(manager.accessToken))
    assert.equal(res.status, 422)
  })

  test('confirmation re-checks Hotel/Hall eligibility — rejects once the Hotel is no longer Approved/Active (422), booking stays PENDING', async () => {
    const { manager, hotelId, booking } = await createPaidBooking()
    const hotel = await hotelService.getHotelById(hotelId)
    await lifecycleService.transition(hotel, 'SUSPENDED')

    const res = await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/confirmation`, undefined, authHeader(manager.accessToken))
    assert.equal(res.status, 422)

    const stillPending = await get(`/api/v1/hotels/${hotelId}/bookings/${booking.id}`, authHeader(manager.accessToken))
    assert.equal(stillPending.body.data.status, 'PENDING')
  })

  test('confirmation re-checks current Hall capacity — rejects once the Manager has lowered capacity below the booking\'s guest count (422)', async () => {
    const { manager, hotelId, hall, booking } = await createPaidBooking({ guests: 150, capacity: 200 })
    await patch(`/api/v1/hotels/${hotelId}/halls/${hall.id}`, { capacity: 100 }, authHeader(manager.accessToken))

    const res = await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/confirmation`, undefined, authHeader(manager.accessToken))
    assert.equal(res.status, 422)
  })

  test('confirmation re-checks availability through the Availability interface — rejects if the period is no longer free (409)', async () => {
    const { hotelId, hall, manager, booking } = await createPaidBooking()
    // No app-level path can create this conflict — createBooking/createBlock
    // both take the shared per-Hall advisory lock and pre-check the other
    // table before writing, so a block can never legitimately overlap a
    // PENDING booking. This direct write simulates the out-of-band/stale
    // state confirmation's own re-check exists to catch — see
    // booking.service.js#assertConfirmable.
    const hotel = await hotelService.getHotelById(hotelId)
    await prisma.hallAvailabilityBlock.create({
      data: {
        hallId: hall.id,
        startsAt: new Date(booking.startsAt),
        endsAt: new Date(booking.endsAt),
        reason: 'Simulated out-of-band conflict',
        createdByUserId: hotel.registeredByUserId,
      },
    })

    const res = await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/confirmation`, undefined, authHeader(manager.accessToken))
    assert.equal(res.status, 409)
  })
})

describe('Invalid state transitions', () => {
  test('cannot confirm a booking that is already REJECTED (409)', async () => {
    const { manager, hotelId, booking } = await createPendingBooking()
    await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/rejection`, undefined, authHeader(manager.accessToken))

    const res = await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/confirmation`, undefined, authHeader(manager.accessToken))
    assert.equal(res.status, 409)
  })

  test('cannot report payment on a booking that is no longer PENDING (409)', async () => {
    const { customer, manager, hotelId, booking } = await createPendingBooking()
    await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/rejection`, undefined, authHeader(manager.accessToken))

    const res = await post(`/api/v1/bookings/${booking.id}/payment-report`, { amountCents: 100 }, authHeader(customer.accessToken))
    assert.equal(res.status, 409)
  })

  test('cannot complete a booking that is still PENDING (409)', async () => {
    const { manager, hotelId, booking } = await createPendingBooking()

    const res = await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/completion`, undefined, authHeader(manager.accessToken))
    assert.equal(res.status, 409)
  })

  test('cannot mark a still-PENDING booking no-show (409)', async () => {
    const { manager, hotelId, booking } = await createPendingBooking()

    const res = await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/no-show`, undefined, authHeader(manager.accessToken))
    assert.equal(res.status, 409)
  })
})

describe('Cancellation authorization', () => {
  test('a Customer cancels their own PENDING booking (200, CANCELLED) — never deleted', async () => {
    const { customer, booking } = await createPendingBooking()

    const res = await post(`/api/v1/bookings/${booking.id}/cancellation`, undefined, authHeader(customer.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'CANCELLED')

    const stillExists = await prisma.booking.findUnique({ where: { id: booking.id } })
    assert.ok(stillExists, 'the booking record must be preserved, never deleted')
  })

  test('a Customer cannot cancel another Customer\'s booking (404)', async () => {
    const { booking } = await createPendingBooking()
    const other = await registerVerifiedCustomer()

    const res = await post(`/api/v1/bookings/${booking.id}/cancellation`, undefined, authHeader(other.accessToken))
    assert.equal(res.status, 404)
  })

  test('an own-Hotel Manager cancels a PENDING booking (200, CANCELLED)', async () => {
    const { manager, hotelId, booking } = await createPendingBooking()

    const res = await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/cancellation`, undefined, authHeader(manager.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'CANCELLED')
  })

  test('a Manager cannot cancel a booking belonging to another Hotel (404)', async () => {
    const { booking } = await createPendingBooking()
    const otherManager = await registerAndLogin('HOTEL_MANAGER')
    const otherHotelId = await createApprovedHotel(otherManager.accessToken)

    const res = await post(`/api/v1/hotels/${otherHotelId}/bookings/${booking.id}/cancellation`, undefined, authHeader(otherManager.accessToken))
    assert.equal(res.status, 404)
  })

  test('a PENDING, PAID booking can still be cancelled by its Customer (200, CANCELLED) — cancellability is not gated on payment state, and paymentStatus is left untouched (no refund logic)', async () => {
    const { customer, booking } = await createPaidBooking()

    const res = await post(`/api/v1/bookings/${booking.id}/cancellation`, undefined, authHeader(customer.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'CANCELLED')
    assert.equal(res.body.data.paymentStatus, 'PAID')
  })

  test('a CONFIRMED booking can be cancelled by its own Customer (200, CANCELLED)', async () => {
    const { customer, manager, hotelId, booking } = await createPaidBooking()
    await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/confirmation`, undefined, authHeader(manager.accessToken))

    const res = await post(`/api/v1/bookings/${booking.id}/cancellation`, undefined, authHeader(customer.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'CANCELLED')
  })

  test('a CONFIRMED booking can be cancelled by its own-Hotel Manager (200, CANCELLED)', async () => {
    const { manager, hotelId, booking } = await createPaidBooking()
    await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/confirmation`, undefined, authHeader(manager.accessToken))

    const res = await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/cancellation`, undefined, authHeader(manager.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'CANCELLED')
  })

  test('a no-longer-applicable (already REJECTED) booking cannot be cancelled (409)', async () => {
    const { customer, manager, hotelId, booking } = await createPendingBooking()
    await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/rejection`, undefined, authHeader(manager.accessToken))

    const res = await post(`/api/v1/bookings/${booking.id}/cancellation`, undefined, authHeader(customer.accessToken))
    assert.equal(res.status, 409)
  })
})

describe('Payment deadline and expiration', () => {
  test('a PENDING booking past its 24-hour payment deadline is lazily flipped to EXPIRED and stops blocking availability', async () => {
    const { customer, hall, booking } = await createPendingBooking()
    await prisma.booking.update({ where: { id: booking.id }, data: { paymentDeadlineAt: new Date(Date.now() - 1000) } })

    const raw = await prisma.booking.findUnique({ where: { id: booking.id } })
    assert.equal(raw.status, 'PENDING', 'expiration is lazy — the raw row does not flip until something reads/checks it')

    const res = await get(`/api/v1/bookings/${booking.id}`, authHeader(customer.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'EXPIRED')

    const free = await availabilityService.isPeriodFree({ hallId: hall.id, startsAt: booking.startsAt, endsAt: booking.endsAt })
    assert.equal(free, true, 'an expired booking must no longer block availability')
  })

  test('an expired booking can no longer receive a payment report (409)', async () => {
    const { customer, booking } = await createPendingBooking()
    await prisma.booking.update({ where: { id: booking.id }, data: { paymentDeadlineAt: new Date(Date.now() - 1000) } })

    const res = await post(`/api/v1/bookings/${booking.id}/payment-report`, { amountCents: 100 }, authHeader(customer.accessToken))
    assert.equal(res.status, 409)
  })

  test('a Pending Paid booking does not expire even past its original deadline (BR-BOOKING, business-specification.md)', async () => {
    const { hotelId, manager, booking } = await createPaidBooking()
    await prisma.booking.update({ where: { id: booking.id }, data: { paymentDeadlineAt: new Date(Date.now() - 1000) } })

    const res = await get(`/api/v1/hotels/${hotelId}/bookings/${booking.id}`, authHeader(manager.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'PENDING')
    assert.equal(res.body.data.paymentStatus, 'PAID')
  })
})
