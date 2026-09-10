import { after, before, test } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import * as hallService from '../../halls/hall.service.js'
import * as hotelService from '../../hotels/hotel.service.js'
import * as applicationService from '../../hotels/application.service.js'

/**
 * The EXCLUDE-constraint race test (Approved Implementation Plan §Testing).
 * Proves the PostgreSQL `EXCLUDE USING gist` constraint — not merely the
 * application-level pre-check — is what prevents two overlapping blocks
 * from ever both existing, by racing two real concurrent HTTP requests
 * against the real dev database.
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

async function registerAndLogin() {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  // BDR-019: Full Name is required at registration for a HOTEL_MANAGER account.
  await request('POST', '/api/v1/auth/register', { body: { mobileNumber, password, accountType: 'HOTEL_MANAGER', fullName: 'Test Manager' } })
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

async function createApprovedHotel(accessToken) {
  const { body: created } = await request('POST', '/api/v1/hotels', { token: accessToken })
  const hotelId = created.data.id
  await request('PATCH', `/api/v1/hotels/${hotelId}`, {
    token: accessToken,
    body: {
      name: 'Grand Test Hotel',
      description: 'A comfortable city hotel with flexible halls.',
      location: { latitude: 2.0469, longitude: 45.3182, address: 'Downtown, Mogadishu' },
      contactPhone: '+15550001111',
    },
  })
  await request('POST', `/api/v1/hotels/${hotelId}/applications`, { token: accessToken })
  const hotel = await hotelService.getHotelById(hotelId)
  await applicationService.recordDecision(hotel, await prismaOpenApplicationId(hotelId), 'APPROVED', adminStubUserId)
  return hotelId
}

function dateInDays(n) {
  return new Date(Date.now() + n * 24 * 60 * 60 * 1000).toISOString().slice(0, 10)
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

test('two concurrent overlapping block creations: exactly one succeeds, one is rejected, and exactly one row exists', async () => {
  const { accessToken } = await registerAndLogin()
  const hotelId = await createApprovedHotel(accessToken)
  const hall = await hallService.createHall({ hotelId })
  const date = dateInDays(2)
  const period = { date, startTime: '10:00', endTime: '14:00' }
  const overlappingPeriod = { date, startTime: '11:00', endTime: '15:00' }
  const path = `/api/v1/hotels/${hotelId}/halls/${hall.id}/availability/blocks`

  const [first, second] = await Promise.all([
    request('POST', path, { token: accessToken, body: period }),
    request('POST', path, { token: accessToken, body: overlappingPeriod }),
  ])

  const statuses = [first.status, second.status].sort()
  assert.deepEqual(statuses, [201, 409])

  const rows = await prisma.hallAvailabilityBlock.findMany({ where: { hallId: hall.id } })
  assert.equal(rows.length, 1)
})
