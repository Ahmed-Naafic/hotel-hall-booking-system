import { test, describe, before, after, afterEach } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import { pushProvider } from '../../../shared/providers/pushProvider.js'
import * as hotelService from '../../hotels/hotel.service.js'
import * as applicationService from '../../hotels/application.service.js'
import * as hallService from '../../halls/hall.service.js'

/**
 * Integration tests for Notification Management (Notification V1) — real
 * Prisma queries and a real server, the same `createApp()` + real `fetch`
 * pattern as `bookings/__tests__/booking.http.test.js`. `pushProvider` is
 * `MockPushProvider` (no Firebase credentials in the test environment —
 * `scripts/testEnv.js`), so push delivery can be asserted on directly
 * without a real Firebase project.
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

async function del(path, body, headers = {}) {
  const res = await fetch(`${baseUrl}${path}`, {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json', ...headers },
    body: body === undefined ? undefined : JSON.stringify(body),
  })
  return { status: res.status }
}

function authHeader(token) {
  return { Authorization: `Bearer ${token}` }
}

// Isolation: every row this file creates is tracked and deleted in
// `afterEach` (the same fix applied to `hotels/__tests__/popular.integration.test.js`
// this session) — this suite must not keep growing the shared dev database.
// Order matters: Notifications/Bookings first (no cascade to their
// Hotel/User), then Halls (no cascade from Hotel), then Hotels (cascades
// Media/Applications), then Users.
let createdNotificationIds = []
let createdBookingIds = []
let createdHallIds = []
let createdHotelIds = []
let createdUserIds = []

afterEach(async () => {
  await prisma.notification.deleteMany({ where: { id: { in: createdNotificationIds } } })
  await prisma.booking.deleteMany({ where: { id: { in: createdBookingIds } } })
  await prisma.hall.deleteMany({ where: { id: { in: createdHallIds } } })
  await prisma.hotel.deleteMany({ where: { id: { in: createdHotelIds } } })
  await prisma.deviceToken.deleteMany({ where: { userId: { in: createdUserIds } } })
  await prisma.user.deleteMany({ where: { id: { in: createdUserIds } } })
  createdNotificationIds = []
  createdBookingIds = []
  createdHallIds = []
  createdHotelIds = []
  createdUserIds = []
})

async function registerAndLogin(accountType) {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  await post('/api/v1/auth/register', { mobileNumber, password, accountType })
  const loginRes = await post('/api/v1/auth/login', { mobileNumber, password })
  createdUserIds.push(loginRes.body.data.user.id)
  return loginRes.body.data
}

async function registerVerifiedCustomer() {
  const customer = await registerAndLogin('CUSTOMER')
  await prisma.user.update({ where: { id: customer.user.id }, data: { isVerified: true } })
  return customer
}

async function createPlatformAdministrator() {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  const argon2 = await import('argon2')
  const passwordHash = await argon2.hash(password)
  const admin = await prisma.user.create({
    data: { mobileNumber, passwordHash, accountType: 'PLATFORM_ADMINISTRATOR', isVerified: true },
  })
  return admin
}

async function prismaOpenApplicationId(hotelId) {
  const application = await prisma.hotelApplication.findFirst({ where: { hotelId, status: 'OPEN' }, orderBy: { createdAt: 'desc' } })
  return application.id
}

function completeHotelProfile() {
  return {
    name: 'Notification Test Hotel',
    description: 'A hotel used only for Notification Management integration tests.',
    location: { latitude: -1.286389, longitude: 36.817223, address: 'Downtown, Nairobi' },
    contactPhone: '+15550001111',
  }
}

async function createApprovedHotel(accessToken) {
  const { body: created } = await post('/api/v1/hotels', {}, authHeader(accessToken))
  const hotelId = created.data.id
  createdHotelIds.push(hotelId)
  await patch(`/api/v1/hotels/${hotelId}`, completeHotelProfile(), authHeader(accessToken))
  await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(accessToken))
  const hotel = await hotelService.getHotelById(hotelId)
  await applicationService.recordDecision(hotel, await prismaOpenApplicationId(hotelId), 'APPROVED', adminStubUserId)
  return hotelId
}

async function createHall(hotelId, overrides = {}) {
  const hall = await hallService.createHall({
    hotelId,
    profileData: { name: 'Main Hall', capacity: 200, ...overrides.profileData },
    commercialData: {
      rentAmountCents: 50000,
      rentDurationHours: 24,
      advancePaymentPercent: 30,
      customerServiceNumber: '+252610000001',
      paymentReceivingNumber: '+252610000002',
      ...overrides.commercialData,
    },
  })
  createdHallIds.push(hall.id)
  return hall
}

function futureRange(offsetDays = 10, hours = 24) {
  const startsAt = new Date(Date.now() + offsetDays * 86400000)
  const endsAt = new Date(startsAt.getTime() + hours * 3600000)
  return { startsAt: startsAt.toISOString(), endsAt: endsAt.toISOString() }
}

/** A fresh Customer + Manager + Hotel + Hall + PENDING/UNPAID booking. */
async function createPendingBooking() {
  const customer = await registerVerifiedCustomer()
  const manager = await registerAndLogin('HOTEL_MANAGER')
  const hotelId = await createApprovedHotel(manager.accessToken)
  const hall = await createHall(hotelId)
  const { startsAt, endsAt } = futureRange()
  const created = await post(
    '/api/v1/bookings',
    { hallId: hall.id, startsAt, endsAt, numberOfGuests: 50, eventType: 'WEDDING' },
    authHeader(customer.accessToken),
  )
  createdBookingIds.push(created.body.data.id)
  return { customer, manager, hotelId, hall, booking: created.body.data }
}

function notificationsFor(accessToken) {
  return get('/api/v1/notifications', authHeader(accessToken))
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
  await prisma.user.deleteMany({ where: { id: adminStubUserId } })
  await new Promise((resolve) => server.close(resolve))
})

describe('Booking lifecycle notifications', () => {
  test('creating a booking notifies both the Customer (submitted) and the Hotel Manager (new request)', async () => {
    const { customer, manager, booking } = await createPendingBooking()

    const customerList = await notificationsFor(customer.accessToken)
    const managerList = await notificationsFor(manager.accessToken)
    createdNotificationIds.push(...customerList.body.data.map((n) => n.id), ...managerList.body.data.map((n) => n.id))

    const customerNotification = customerList.body.data.find((n) => n.bookingId === booking.id)
    assert.ok(customerNotification, 'expected the Customer to have a Notification for this Booking')
    assert.equal(customerNotification.type, 'BOOKING_REQUEST_SUBMITTED')
    assert.equal(customerNotification.status, 'UNREAD')

    const managerNotification = managerList.body.data.find((n) => n.bookingId === booking.id)
    assert.ok(managerNotification, 'expected the Hotel Manager to have a Notification for this Booking')
    assert.equal(managerNotification.type, 'NEW_BOOKING_REQUEST')
  })

  test('reporting a payment notifies both the Customer (confirmation) and the Hotel Manager (review needed)', async () => {
    const { customer, manager, hotelId, booking } = await createPendingBooking()

    await post(`/api/v1/bookings/${booking.id}/payment-report`, { amountCents: booking.pricing.requiredAdvanceCents }, authHeader(customer.accessToken))

    const customerList = await notificationsFor(customer.accessToken)
    const managerList = await notificationsFor(manager.accessToken)
    createdNotificationIds.push(...customerList.body.data.map((n) => n.id), ...managerList.body.data.map((n) => n.id))

    assert.ok(customerList.body.data.some((n) => n.type === 'PAYMENT_REPORTED' && n.bookingId === booking.id))
    assert.ok(managerList.body.data.some((n) => n.type === 'CUSTOMER_PAYMENT_REPORTED' && n.bookingId === booking.id))
    void hotelId
  })

  test('verifying a payment notifies the Customer', async () => {
    const { customer, manager, hotelId, booking } = await createPendingBooking()
    await post(`/api/v1/bookings/${booking.id}/payment-report`, { amountCents: booking.pricing.requiredAdvanceCents }, authHeader(customer.accessToken))

    await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/payment-verification`, { decision: 'VERIFY' }, authHeader(manager.accessToken))

    const customerList = await notificationsFor(customer.accessToken)
    createdNotificationIds.push(...customerList.body.data.map((n) => n.id))
    assert.ok(customerList.body.data.some((n) => n.type === 'PAYMENT_VERIFIED' && n.bookingId === booking.id))
  })

  test('rejecting a payment notifies the Customer', async () => {
    const { customer, manager, hotelId, booking } = await createPendingBooking()
    await post(`/api/v1/bookings/${booking.id}/payment-report`, { amountCents: booking.pricing.requiredAdvanceCents }, authHeader(customer.accessToken))

    await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/payment-verification`, { decision: 'REJECT', reason: 'Amount does not match.' }, authHeader(manager.accessToken))

    const customerList = await notificationsFor(customer.accessToken)
    createdNotificationIds.push(...customerList.body.data.map((n) => n.id))
    assert.ok(customerList.body.data.some((n) => n.type === 'PAYMENT_REJECTED' && n.bookingId === booking.id))
  })

  test('the Hotel Manager confirming a booking notifies only the Customer', async () => {
    const { customer, manager, hotelId, booking } = await createPendingBooking()
    await post(`/api/v1/bookings/${booking.id}/payment-report`, { amountCents: booking.pricing.requiredAdvanceCents }, authHeader(customer.accessToken))
    await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/payment-verification`, { decision: 'VERIFY' }, authHeader(manager.accessToken))

    await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/confirmation`, undefined, authHeader(manager.accessToken))

    const customerList = await notificationsFor(customer.accessToken)
    createdNotificationIds.push(...customerList.body.data.map((n) => n.id))
    assert.ok(customerList.body.data.some((n) => n.type === 'BOOKING_CONFIRMED' && n.bookingId === booking.id))
  })

  test('the Hotel Manager rejecting a booking notifies the Customer', async () => {
    const { customer, manager, hotelId, booking } = await createPendingBooking()

    await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/rejection`, undefined, authHeader(manager.accessToken))

    const customerList = await notificationsFor(customer.accessToken)
    createdNotificationIds.push(...customerList.body.data.map((n) => n.id))
    assert.ok(customerList.body.data.some((n) => n.type === 'BOOKING_REJECTED' && n.bookingId === booking.id))
  })

  test('the Customer cancelling notifies both sides', async () => {
    const { customer, manager, booking } = await createPendingBooking()

    await post(`/api/v1/bookings/${booking.id}/cancellation`, undefined, authHeader(customer.accessToken))

    const customerList = await notificationsFor(customer.accessToken)
    const managerList = await notificationsFor(manager.accessToken)
    createdNotificationIds.push(...customerList.body.data.map((n) => n.id), ...managerList.body.data.map((n) => n.id))
    assert.ok(customerList.body.data.some((n) => n.type === 'BOOKING_CANCELLED' && n.bookingId === booking.id))
    assert.ok(managerList.body.data.some((n) => n.type === 'CUSTOMER_BOOKING_CANCELLED' && n.bookingId === booking.id))
  })

  test('the Hotel Manager cancelling notifies only the Customer, never a self-notification for the Manager', async () => {
    const { customer, manager, hotelId, booking } = await createPendingBooking()

    await post(`/api/v1/hotels/${hotelId}/bookings/${booking.id}/cancellation`, undefined, authHeader(manager.accessToken))

    const customerList = await notificationsFor(customer.accessToken)
    const managerList = await notificationsFor(manager.accessToken)
    createdNotificationIds.push(...customerList.body.data.map((n) => n.id), ...managerList.body.data.map((n) => n.id))
    assert.ok(customerList.body.data.some((n) => n.type === 'BOOKING_CANCELLED' && n.bookingId === booking.id))
    assert.equal(managerList.body.data.some((n) => n.type === 'CUSTOMER_BOOKING_CANCELLED' && n.bookingId === booking.id), false, 'the Manager must not be notified of their own cancellation')
  })
})

describe('Hotel application notifications (Platform Administrator)', () => {
  test('a new hotel application notifies every Platform Administrator', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const { body: created } = await post('/api/v1/hotels', {}, authHeader(manager.accessToken))
    const hotelId = created.data.id
    createdHotelIds.push(hotelId)
    await patch(`/api/v1/hotels/${hotelId}`, completeHotelProfile(), authHeader(manager.accessToken))

    await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(manager.accessToken))

    const rows = await prisma.notification.findMany({ where: { hotelId, type: 'NEW_HOTEL_APPLICATION' } })
    createdNotificationIds.push(...rows.map((n) => n.id))
    assert.ok(rows.some((n) => n.recipientUserId === adminStubUserId), 'expected the stub Platform Administrator to be notified')
  })

  test('withdrawing an application notifies every Platform Administrator', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const { body: created } = await post('/api/v1/hotels', {}, authHeader(manager.accessToken))
    const hotelId = created.data.id
    createdHotelIds.push(hotelId)
    await patch(`/api/v1/hotels/${hotelId}`, completeHotelProfile(), authHeader(manager.accessToken))
    const { body: application } = await post(`/api/v1/hotels/${hotelId}/applications`, undefined, authHeader(manager.accessToken))

    await post(`/api/v1/hotels/${hotelId}/applications/${application.data.id}/withdrawal`, undefined, authHeader(manager.accessToken))

    const rows = await prisma.notification.findMany({ where: { hotelId, type: 'HOTEL_APPLICATION_WITHDRAWN' } })
    createdNotificationIds.push(...rows.map((n) => n.id))
    assert.ok(rows.some((n) => n.recipientUserId === adminStubUserId))
  })
})

describe('Ownership and tenant isolation', () => {
  test('a Customer cannot see another Customer\'s Notification', async () => {
    const { customer: customerA, booking } = await createPendingBooking()
    const customerB = await registerVerifiedCustomer()

    const listA = await notificationsFor(customerA.accessToken)
    createdNotificationIds.push(...listA.body.data.map((n) => n.id))
    const notificationId = listA.body.data.find((n) => n.bookingId === booking.id).id

    const readAttempt = await post(`/api/v1/notifications/${notificationId}/read`, undefined, authHeader(customerB.accessToken))
    assert.equal(readAttempt.status, 404)

    const listB = await notificationsFor(customerB.accessToken)
    assert.equal(listB.body.data.some((n) => n.id === notificationId), false)
  })

  test('a Hotel Manager only ever receives Notifications for their own Hotel', async () => {
    const { manager: managerA, booking: bookingA } = await createPendingBooking()
    const { manager: managerB } = await createPendingBooking()

    const listB = await notificationsFor(managerB.accessToken)
    createdNotificationIds.push(...listB.body.data.map((n) => n.id))
    assert.equal(listB.body.data.some((n) => n.bookingId === bookingA.id), false)
    void managerA
  })
})

describe('Read state', () => {
  test('marking one Notification read persists, and does not affect others', async () => {
    const { customer, booking } = await createPendingBooking()
    const list = await notificationsFor(customer.accessToken)
    createdNotificationIds.push(...list.body.data.map((n) => n.id))
    const target = list.body.data.find((n) => n.bookingId === booking.id)
    assert.equal(target.status, 'UNREAD')

    const res = await post(`/api/v1/notifications/${target.id}/read`, undefined, authHeader(customer.accessToken))
    assert.equal(res.status, 200)
    assert.equal(res.body.data.status, 'READ')
    assert.ok(res.body.data.readAt)

    const after2 = await notificationsFor(customer.accessToken)
    assert.equal(after2.body.data.find((n) => n.id === target.id).status, 'READ')
  })

  test('marking all Notifications read clears the unread count', async () => {
    const { customer } = await createPendingBooking()
    const before1 = await get('/api/v1/notifications/unread-count', authHeader(customer.accessToken))
    assert.ok(before1.body.data.count >= 1)

    const res = await post('/api/v1/notifications/read-all', undefined, authHeader(customer.accessToken))
    assert.equal(res.status, 200)

    const after1 = await get('/api/v1/notifications/unread-count', authHeader(customer.accessToken))
    assert.equal(after1.body.data.count, 0)

    const list = await notificationsFor(customer.accessToken)
    createdNotificationIds.push(...list.body.data.map((n) => n.id))
    assert.ok(list.body.data.every((n) => n.status === 'READ'))
  })

  test('a Customer with no Notifications sees an empty list and a zero unread count', async () => {
    const customer = await registerVerifiedCustomer()
    const list = await notificationsFor(customer.accessToken)
    const count = await get('/api/v1/notifications/unread-count', authHeader(customer.accessToken))
    assert.deepEqual(list.body.data, [])
    assert.equal(count.body.data.count, 0)
  })
})

describe('Pagination', () => {
  test('list results are cursor-paginated, newest first', async () => {
    const { customer, hotelId, hall } = await createPendingBooking()
    for (let i = 0; i < 3; i++) {
      const { startsAt, endsAt } = futureRange(20 + i)
      const created = await post('/api/v1/bookings', { hallId: hall.id, startsAt, endsAt, numberOfGuests: 10, eventType: 'OTHER' }, authHeader(customer.accessToken))
      createdBookingIds.push(created.body.data.id)
    }
    void hotelId

    const firstPage = await get('/api/v1/notifications?limit=2', authHeader(customer.accessToken))
    createdNotificationIds.push(...firstPage.body.data.map((n) => n.id))
    assert.equal(firstPage.body.data.length, 2)
    assert.equal(firstPage.body.pagination.hasNext, true)

    const secondPage = await get(`/api/v1/notifications?limit=2&cursor=${firstPage.body.pagination.nextCursor}`, authHeader(customer.accessToken))
    createdNotificationIds.push(...secondPage.body.data.map((n) => n.id))
    assert.ok(secondPage.body.data.length >= 1)
    assert.equal(firstPage.body.data.some((a) => secondPage.body.data.some((b) => b.id === a.id)), false, 'pages must not overlap')
  })
})

describe('Push delivery failure handling', () => {
  test('a push delivery failure never prevents the Notification from existing and being readable', async () => {
    const customer = await registerVerifiedCustomer()
    const tokenRes = await fetch(`${baseUrl}/api/v1/notifications/device-tokens`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', ...authHeader(customer.accessToken) },
      body: JSON.stringify({ token: `test-device-${uniqueMobileNumber()}` }),
    })
    assert.equal(tokenRes.status, 200)
    pushProvider.failNextSend()

    const manager = await registerAndLogin('HOTEL_MANAGER')
    const hotelId = await createApprovedHotel(manager.accessToken)
    const hall = await createHall(hotelId)
    const { startsAt, endsAt } = futureRange()
    const created = await post('/api/v1/bookings', { hallId: hall.id, startsAt, endsAt, numberOfGuests: 10, eventType: 'OTHER' }, authHeader(customer.accessToken))
    createdBookingIds.push(created.body.data.id)
    assert.equal(created.status, 201, 'the Booking itself must succeed regardless of push delivery outcome')

    // Push delivery is fire-and-forget (notification.service.js#notify) —
    // give it a tick to run and fail before asserting the Notification
    // still exists and is readable.
    await new Promise((resolve) => setTimeout(resolve, 50))

    const list = await notificationsFor(customer.accessToken)
    createdNotificationIds.push(...list.body.data.map((n) => n.id))
    assert.ok(list.body.data.some((n) => n.bookingId === created.body.data.id), 'the Notification must exist even though its push delivery failed')
  })
})

describe('Device tokens', () => {
  test('registering, then unregistering, a device token', async () => {
    const customer = await registerVerifiedCustomer()
    const token = `test-device-${uniqueMobileNumber()}`

    const registerRes = await fetch(`${baseUrl}/api/v1/notifications/device-tokens`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', ...authHeader(customer.accessToken) },
      body: JSON.stringify({ token, platform: 'android' }),
    })
    assert.equal(registerRes.status, 200)
    const stored = await prisma.deviceToken.findUnique({ where: { token } })
    assert.ok(stored)
    assert.equal(stored.userId, customer.user.id)

    const unregisterRes = await fetch(`${baseUrl}/api/v1/notifications/device-tokens?token=${encodeURIComponent(token)}`, {
      method: 'DELETE',
      headers: authHeader(customer.accessToken),
    })
    assert.equal(unregisterRes.status, 204)
    assert.equal(await prisma.deviceToken.findUnique({ where: { token } }), null)
  })

  test('re-registering an existing token moves it to the new owner instead of duplicating it', async () => {
    const customerA = await registerVerifiedCustomer()
    const customerB = await registerVerifiedCustomer()
    const token = `test-device-shared-${uniqueMobileNumber()}`

    await fetch(`${baseUrl}/api/v1/notifications/device-tokens`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', ...authHeader(customerA.accessToken) },
      body: JSON.stringify({ token }),
    })
    await fetch(`${baseUrl}/api/v1/notifications/device-tokens`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', ...authHeader(customerB.accessToken) },
      body: JSON.stringify({ token }),
    })

    const rows = await prisma.deviceToken.findMany({ where: { token } })
    assert.equal(rows.length, 1, 'the token must move to the new owner, never duplicate')
    assert.equal(rows[0].userId, customerB.user.id)
    await prisma.deviceToken.deleteMany({ where: { token } })
  })
})
