import { after, before, describe, test } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import * as hallService from '../../halls/hall.service.js'
import * as hotelService from '../../hotels/hotel.service.js'
import * as applicationService from '../../hotels/application.service.js'

/**
 * Integration tests (testing-standards.md §6) — real Prisma queries against
 * the real dev database, real HTTP server, matching `halls.integration.test.js`'s
 * established style. Covers the Manager block-management endpoints and the
 * public Customer availability endpoints (Approved Implementation Plan,
 * Availability & Calendar V1).
 */

let server
let baseUrl
let adminStubUserId

function uniqueMobileNumber() {
  return `+1${Math.floor(100000000 + Math.random() * 899999999)}`
}

async function request(method, path, { body, token } = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  })
  const text = await response.text()
  return { status: response.status, body: text ? JSON.parse(text) : undefined }
}

async function registerAndLogin(accountType = 'HOTEL_MANAGER') {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  await request('POST', '/api/v1/auth/register', { body: { mobileNumber, password, accountType } })
  const response = await request('POST', '/api/v1/auth/login', { body: { mobileNumber, password } })
  return response.body.data
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
  const application = await prisma.hotelApplication.findFirst({ where: { hotelId, status: 'OPEN' } })
  return application.id
}

function completeHotelProfile() {
  return {
    name: 'Grand Test Hotel',
    description: 'A comfortable city hotel with flexible halls.',
    location: { latitude: 2.0469, longitude: 45.3182, address: 'Downtown, Mogadishu' },
    contactPhone: '+15550001111',
  }
}

/** Registers, completes, submits, and approves a Hotel — reaching APPROVED_ACTIVE. */
async function createApprovedHotel(accessToken) {
  const { body: created } = await request('POST', '/api/v1/hotels', { token: accessToken })
  const hotelId = created.data.id
  await request('PATCH', `/api/v1/hotels/${hotelId}`, { body: completeHotelProfile(), token: accessToken })
  await request('POST', `/api/v1/hotels/${hotelId}/applications`, { token: accessToken })
  const hotel = await hotelService.getHotelById(hotelId)
  await applicationService.recordDecision(hotel, await prismaOpenApplicationId(hotelId), 'APPROVED', adminStubUserId)
  return hotelId
}

async function createUnapprovedHotel(accessToken) {
  const { body: created } = await request('POST', '/api/v1/hotels', { token: accessToken })
  return created.data.id
}

/** date string ("YYYY-MM-DD") for N days from now, in Mogadishu-adjacent UTC terms. */
function dateInDays(n) {
  const d = new Date(Date.now() + n * 24 * 60 * 60 * 1000)
  return d.toISOString().slice(0, 10)
}

before(async () => {
  server = createApp().listen(0)
  await new Promise((resolve) => server.once('listening', resolve))
  baseUrl = `http://127.0.0.1:${server.address().port}`
  const admin = await createPlatformAdministrator()
  adminStubUserId = admin.id
})

after(async () => {
  await new Promise((resolve) => server.close(resolve))
  await prisma.$disconnect()
})

describe('Manager block management (own-Hotel scoped)', () => {
  test('creates a block for a future period (201)', async () => {
    const { accessToken } = await registerAndLogin()
    const hotelId = await createApprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId })
    const date = dateInDays(2)

    const res = await request('POST', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`, {
      token: accessToken,
      body: { date, startTime: '10:00', endTime: '14:00', reason: 'Maintenance' },
    })

    assert.equal(res.status, 201)
    assert.equal(res.body.data.reason, 'Maintenance')
    assert.equal(new Date(res.body.data.startsAt).toISOString().slice(11, 16), '07:00') // 10:00 EAT = 07:00 UTC
    assert.equal(new Date(res.body.data.endsAt).toISOString().slice(11, 16), '11:00')
  })

  test('an overlapping block is rejected (409)', async () => {
    const { accessToken } = await registerAndLogin()
    const hotelId = await createApprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId })
    const date = dateInDays(2)

    await request('POST', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`, {
      token: accessToken,
      body: { date, startTime: '10:00', endTime: '14:00' },
    })
    const conflict = await request('POST', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`, {
      token: accessToken,
      body: { date, startTime: '12:00', endTime: '16:00' },
    })

    assert.equal(conflict.status, 409)
  })

  test('adjacent blocks (10:00-14:00, 14:00-18:00) both succeed — [start, end) never treats touching as overlap', async () => {
    const { accessToken } = await registerAndLogin()
    const hotelId = await createApprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId })
    const date = dateInDays(2)

    const first = await request('POST', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`, {
      token: accessToken,
      body: { date, startTime: '10:00', endTime: '14:00' },
    })
    const second = await request('POST', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`, {
      token: accessToken,
      body: { date, startTime: '14:00', endTime: '18:00' },
    })

    assert.equal(first.status, 201)
    assert.equal(second.status, 201)
  })

  test('an overnight period (endTime before startTime) rolls to the next calendar day and succeeds', async () => {
    const { accessToken } = await registerAndLogin()
    const hotelId = await createApprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId })
    const date = dateInDays(2)

    const res = await request('POST', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`, {
      token: accessToken,
      body: { date, startTime: '22:00', endTime: '02:00' },
    })

    assert.equal(res.status, 201)
    const startsAt = new Date(res.body.data.startsAt)
    const endsAt = new Date(res.body.data.endsAt)
    assert.ok(endsAt > startsAt)
    assert.equal(endsAt.getTime() - startsAt.getTime(), 4 * 60 * 60 * 1000)
  })

  test('a past-dated block is rejected (422) — decision 5 applies to create', async () => {
    const { accessToken } = await registerAndLogin()
    const hotelId = await createApprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId })
    const pastDate = dateInDays(-2)

    const res = await request('POST', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`, {
      token: accessToken,
      body: { date: pastDate, startTime: '10:00', endTime: '14:00' },
    })

    assert.equal(res.status, 422)
    assert.equal(res.body.error, 'BUSINESS_RULE_VIOLATION')
  })

  test('editing a block to move its start into the past is rejected (422) — decision 5 applies to update', async () => {
    const { accessToken } = await registerAndLogin()
    const hotelId = await createApprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId })
    const created = await request('POST', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`, {
      token: accessToken,
      body: { date: dateInDays(2), startTime: '10:00', endTime: '14:00' },
    })

    const edited = await request(
      'PATCH',
      `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks/${created.body.data.id}`,
      { token: accessToken, body: { date: dateInDays(-1) } },
    )

    assert.equal(edited.status, 422)
  })

  test('malformed date/time is rejected (400)', async () => {
    const { accessToken } = await registerAndLogin()
    const hotelId = await createApprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId })

    const res = await request('POST', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`, {
      token: accessToken,
      body: { date: '2026-13-40', startTime: '25:99', endTime: '14:00' },
    })

    assert.equal(res.status, 400)
    assert.ok(res.body.details.some((d) => d.field === 'date'))
    assert.ok(res.body.details.some((d) => d.field === 'startTime'))
  })

  test('a non-Manager (CUSTOMER) is rejected (403)', async () => {
    const { accessToken: customerToken } = await registerAndLogin('CUSTOMER')
    const { accessToken: managerToken } = await registerAndLogin()
    const hotelId = await createApprovedHotel(managerToken)
    const hall = await hallService.createHall({ hotelId })

    const res = await request('POST', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`, {
      token: customerToken,
      body: { date: dateInDays(2), startTime: '10:00', endTime: '14:00' },
    })

    assert.equal(res.status, 403)
  })

  test('a Manager cannot manage another Manager\'s Hall — cross-tenant is 404, never 403', async () => {
    const { accessToken: ownerToken } = await registerAndLogin()
    const ownerHotelId = await createApprovedHotel(ownerToken)
    const hall = await hallService.createHall({ hotelId: ownerHotelId })
    const { accessToken: otherToken } = await registerAndLogin()
    const otherHotelId = await createUnapprovedHotel(otherToken)

    const res = await request(
      'POST',
      `/api/v1/hotels/${otherHotelId}/halls/${hall.id}/availability/blocks`,
      { token: otherToken, body: { date: dateInDays(2), startTime: '10:00', endTime: '14:00' } },
    )

    assert.equal(res.status, 404)
  })

  test('delete removes a block (204); a second delete of the same id is 404', async () => {
    const { accessToken } = await registerAndLogin()
    const hotelId = await createApprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId })
    const created = await request('POST', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`, {
      token: accessToken,
      body: { date: dateInDays(2), startTime: '10:00', endTime: '14:00' },
    })
    const blockId = created.body.data.id

    const first = await request('DELETE', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks/${blockId}`, {
      token: accessToken,
    })
    const second = await request('DELETE', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks/${blockId}`, {
      token: accessToken,
    })

    assert.equal(first.status, 204)
    assert.equal(second.status, 404)
  })
})

describe('Public Customer availability (GET .../availability, POST .../availability/check)', () => {
  test('a Hall belonging to an unapproved Hotel exposes no public availability (404)', async () => {
    const { accessToken } = await registerAndLogin()
    const hotelId = await createUnapprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId })

    const res = await request('GET', `/api/v1/halls/${hall.id}/availability?date=${dateInDays(2)}`)
    assert.equal(res.status, 404)
  })

  test('busy periods are returned with no reason/id/createdByUserId leaked', async () => {
    const { accessToken } = await registerAndLogin()
    const hotelId = await createApprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId })
    const date = dateInDays(2)
    await request('POST', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`, {
      token: accessToken,
      body: { date, startTime: '10:00', endTime: '14:00', reason: 'Private wedding, family Doe' },
    })

    const res = await request('GET', `/api/v1/halls/${hall.id}/availability?date=${date}`)

    assert.equal(res.status, 200)
    assert.equal(res.body.data.busyPeriods.length, 1)
    const period = res.body.data.busyPeriods[0]
    assert.deepEqual(Object.keys(period).sort(), ['end', 'start'])
  })

  test('POST .../check returns available:true for a free period', async () => {
    const { accessToken } = await registerAndLogin()
    const hotelId = await createApprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId })
    const { accessToken: customerToken } = await registerAndLogin('CUSTOMER')

    const res = await request('POST', `/api/v1/halls/${hall.id}/availability/check`, {
      token: customerToken,
      body: { date: dateInDays(2), startTime: '10:00', endTime: '14:00' },
    })

    assert.equal(res.status, 200)
    assert.equal(res.body.data.available, true)
  })

  test('POST .../check returns available:false for a period overlapping an existing block', async () => {
    const { accessToken } = await registerAndLogin()
    const hotelId = await createApprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId })
    const date = dateInDays(2)
    await request('POST', `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`, {
      token: accessToken,
      body: { date, startTime: '10:00', endTime: '14:00' },
    })
    const { accessToken: customerToken } = await registerAndLogin('CUSTOMER')

    const res = await request('POST', `/api/v1/halls/${hall.id}/availability/check`, {
      token: customerToken,
      body: { date, startTime: '12:00', endTime: '13:00' },
    })

    assert.equal(res.status, 200)
    assert.equal(res.body.data.available, false)
  })

  test('an unauthenticated caller cannot POST .../check (401)', async () => {
    const { accessToken } = await registerAndLogin()
    const hotelId = await createApprovedHotel(accessToken)
    const hall = await hallService.createHall({ hotelId })

    const res = await request('POST', `/api/v1/halls/${hall.id}/availability/check`, {
      body: { date: dateInDays(2), startTime: '10:00', endTime: '14:00' },
    })

    assert.equal(res.status, 401)
  })
})
