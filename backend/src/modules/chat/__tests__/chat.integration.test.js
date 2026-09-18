import { test, describe, before, after, afterEach } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import { pushProvider } from '../../../shared/providers/pushProvider.js'
import * as hotelService from '../../hotels/hotel.service.js'
import * as applicationService from '../../hotels/application.service.js'
import * as hallService from '../../halls/hall.service.js'

/**
 * Integration tests for Communication V1 (approved Business Specification
 * §"Communication V1") — real Prisma queries and a real server, the same
 * `createApp()` + real `fetch` pattern every other integration test file in
 * this codebase already uses. `pushProvider` is `MockPushProvider` (no
 * Firebase credentials in the test environment — `scripts/testEnv.js`).
 */

let server
let baseUrl
let adminStubUserId

function uniqueMobileNumber() {
  const suffix = Math.floor(100000000 + Math.random() * 899999999)
  return `+1${suffix}`
}

async function pollUntil(read, isDone, { timeoutMs = 5000, intervalMs = 100 } = {}) {
  const deadline = Date.now() + timeoutMs
  let value = await read()
  while (!isDone(value) && Date.now() < deadline) {
    await new Promise((resolve) => setTimeout(resolve, intervalMs))
    value = await read()
  }
  return value
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

// Isolation: every row this file creates is tracked and deleted in
// `afterEach` (same convention as `notifications/__tests__/notification.integration.test.js`).
// Order: ChatMessages/Notifications first, then Bookings, Halls, Hotels, Users.
let createdChatMessageIds = []
let createdNotificationIds = []
let createdBookingIds = []
let createdHallIds = []
let createdHotelIds = []
let createdUserIds = []

afterEach(async () => {
  await prisma.chatMessage.deleteMany({ where: { id: { in: createdChatMessageIds } } })
  await prisma.notification.deleteMany({ where: { id: { in: createdNotificationIds } } })
  await prisma.booking.deleteMany({ where: { id: { in: createdBookingIds } } })
  await prisma.hall.deleteMany({ where: { id: { in: createdHallIds } } })
  await prisma.hotel.deleteMany({ where: { id: { in: createdHotelIds } } })
  await prisma.deviceToken.deleteMany({ where: { userId: { in: createdUserIds } } })
  await prisma.user.deleteMany({ where: { id: { in: createdUserIds } } })
  createdChatMessageIds = []
  createdNotificationIds = []
  createdBookingIds = []
  createdHallIds = []
  createdHotelIds = []
  createdUserIds = []
})

async function registerAndLogin(accountType) {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  const fullName = accountType === 'CUSTOMER' ? 'Test Customer' : accountType === 'HOTEL_MANAGER' ? 'Test Manager' : undefined
  await post('/api/v1/auth/register', { mobileNumber, password, accountType, fullName })
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
  return prisma.user.create({ data: { mobileNumber, passwordHash, accountType: 'PLATFORM_ADMINISTRATOR', isVerified: true } })
}

async function prismaOpenApplicationId(hotelId) {
  const application = await prisma.hotelApplication.findFirst({ where: { hotelId, status: 'OPEN' }, orderBy: { createdAt: 'desc' } })
  return application.id
}

function completeHotelProfile() {
  return {
    name: 'Chat Test Hotel',
    description: 'A hotel used only for Communication V1 integration tests.',
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

function messagesFor(bookingId, accessToken) {
  return get(`/api/v1/bookings/${bookingId}/messages`, authHeader(accessToken))
}

function sendMessage(bookingId, accessToken, body) {
  return post(`/api/v1/bookings/${bookingId}/messages`, { body }, authHeader(accessToken))
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

describe('Sending and reading a Booking conversation', () => {
  test('the Customer and the Hotel Manager can each send a message and see the other\'s (AC-6)', async () => {
    const { customer, manager, booking } = await createPendingBooking()

    const sent = await sendMessage(booking.id, customer.accessToken, 'Hi, can we add extra chairs?')
    assert.equal(sent.status, 201)
    createdChatMessageIds.push(sent.body.data.id)
    assert.equal(sent.body.data.body, 'Hi, can we add extra chairs?')
    assert.equal(sent.body.data.senderUserId, customer.user.id)
    assert.equal(sent.body.data.readAt, null)

    const reply = await sendMessage(booking.id, manager.accessToken, 'Sure, no problem.')
    createdChatMessageIds.push(reply.body.data.id)

    const asCustomer = await messagesFor(booking.id, customer.accessToken)
    assert.equal(asCustomer.status, 200)
    assert.deepEqual(asCustomer.body.data.map((m) => m.body), ['Hi, can we add extra chairs?', 'Sure, no problem.'])

    const asManager = await messagesFor(booking.id, manager.accessToken)
    assert.deepEqual(asManager.body.data.map((m) => m.body), ['Hi, can we add extra chairs?', 'Sure, no problem.'])
  })

  test('messages are returned oldest first (Business Rule 6 — opposite of Notification\'s own order)', async () => {
    const { customer, booking } = await createPendingBooking()
    const first = await sendMessage(booking.id, customer.accessToken, 'first')
    const second = await sendMessage(booking.id, customer.accessToken, 'second')
    createdChatMessageIds.push(first.body.data.id, second.body.data.id)

    const list = await messagesFor(booking.id, customer.accessToken)
    assert.deepEqual(list.body.data.map((m) => m.body), ['first', 'second'])
  })

  test('an empty or whitespace-only body is rejected (400), never persisted', async () => {
    const { customer, booking } = await createPendingBooking()
    const res = await sendMessage(booking.id, customer.accessToken, '   ')
    assert.equal(res.status, 400)

    const list = await messagesFor(booking.id, customer.accessToken)
    assert.deepEqual(list.body.data, [])
  })
})

describe('Ownership and tenant isolation (AC-7)', () => {
  test('a user who is neither the Booking\'s Customer nor its Hotel\'s Manager gets 404, not the conversation', async () => {
    const { booking } = await createPendingBooking()
    const outsider = await registerVerifiedCustomer()

    const readRes = await messagesFor(booking.id, outsider.accessToken)
    assert.equal(readRes.status, 404)

    const sendRes = await sendMessage(booking.id, outsider.accessToken, 'trying to butt in')
    assert.equal(sendRes.status, 404)
  })

  test('a Hotel Manager of a different Hotel cannot see this Booking\'s conversation', async () => {
    const { booking } = await createPendingBooking()
    const otherManager = await registerAndLogin('HOTEL_MANAGER')
    await createApprovedHotel(otherManager.accessToken)

    const res = await messagesFor(booking.id, otherManager.accessToken)
    assert.equal(res.status, 404)
  })
})

describe('Read state (AC-8)', () => {
  test('opening the conversation marks only the other participant\'s messages read, never the reader\'s own', async () => {
    const { customer, manager, booking } = await createPendingBooking()
    const fromCustomer = await sendMessage(booking.id, customer.accessToken, 'from customer')
    const fromManager = await sendMessage(booking.id, manager.accessToken, 'from manager')
    createdChatMessageIds.push(fromCustomer.body.data.id, fromManager.body.data.id)

    const markRes = await post(`/api/v1/bookings/${booking.id}/messages/read-all`, undefined, authHeader(manager.accessToken))
    assert.equal(markRes.status, 200)

    const list = await messagesFor(booking.id, manager.accessToken)
    const byId = Object.fromEntries(list.body.data.map((m) => [m.id, m]))
    assert.ok(byId[fromCustomer.body.data.id].readAt, 'the Customer\'s message should now be read')
    assert.equal(byId[fromManager.body.data.id].readAt, null, 'the Manager\'s own message is never marked read by their own read-all')
  })

  test('the unread-message count reflects only messages sent by the other participant, across all of the caller\'s Bookings', async () => {
    const { customer, manager, booking } = await createPendingBooking()
    const msg = await sendMessage(booking.id, customer.accessToken, 'are you there?')
    createdChatMessageIds.push(msg.body.data.id)

    const managerUnread = await get('/api/v1/messages/unread-count', authHeader(manager.accessToken))
    assert.equal(managerUnread.body.data.count, 1)

    const customerUnread = await get('/api/v1/messages/unread-count', authHeader(customer.accessToken))
    assert.equal(customerUnread.body.data.count, 0, 'the sender never counts their own message as unread')

    await post(`/api/v1/bookings/${booking.id}/messages/read-all`, undefined, authHeader(manager.accessToken))
    const afterRead = await get('/api/v1/messages/unread-count', authHeader(manager.accessToken))
    assert.equal(afterRead.body.data.count, 0)
  })
})

describe('Notification delivery (AC-9, AC-10)', () => {
  test('sending a message produces exactly one NEW_CHAT_MESSAGE Notification for the other participant, never for the sender', async () => {
    const { customer, manager, booking } = await createPendingBooking()
    const sent = await sendMessage(booking.id, customer.accessToken, 'ping')
    createdChatMessageIds.push(sent.body.data.id)

    const managerNotifications = await get('/api/v1/notifications', authHeader(manager.accessToken))
    const chatNotifications = managerNotifications.body.data.filter((n) => n.type === 'NEW_CHAT_MESSAGE' && n.bookingId === booking.id)
    assert.equal(chatNotifications.length, 1)
    createdNotificationIds.push(chatNotifications[0].id)

    const customerNotifications = await get('/api/v1/notifications', authHeader(customer.accessToken))
    assert.equal(customerNotifications.body.data.filter((n) => n.type === 'NEW_CHAT_MESSAGE').length, 0, 'the sender is never notified of their own message')
  })

  test('a simulated push delivery failure never prevents the message from existing and being readable', async () => {
    const { customer, manager, booking } = await createPendingBooking()
    await fetch(`${baseUrl}/api/v1/notifications/device-tokens`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', ...authHeader(manager.accessToken) },
      body: JSON.stringify({ token: `chat-test-token-${manager.user.id}` }),
    })
    pushProvider.failNextSend?.()

    const sent = await sendMessage(booking.id, customer.accessToken, 'this push will fail')
    assert.equal(sent.status, 201)
    createdChatMessageIds.push(sent.body.data.id)

    const readBack = await pollUntil(
      () => messagesFor(booking.id, manager.accessToken),
      (res) => res.body.data.some((m) => m.id === sent.body.data.id),
    )
    assert.ok(readBack.body.data.some((m) => m.id === sent.body.data.id))
  })
})
