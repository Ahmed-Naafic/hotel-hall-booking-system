import { after, before, describe, test } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import * as hallService from '../../halls/hall.service.js'

let server
let baseUrl

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

async function registerAndLogin(accountType = 'CUSTOMER') {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  await request('POST', '/api/v1/auth/register', { body: { mobileNumber, password, accountType } })
  const response = await request('POST', '/api/v1/auth/login', { body: { mobileNumber, password } })
  return response.body.data
}

before(async () => {
  server = createApp().listen(0)
  await new Promise((resolve) => server.once('listening', resolve))
  baseUrl = `http://127.0.0.1:${server.address().port}`
})

after(async () => {
  await new Promise((resolve) => server.close(resolve))
  await prisma.$disconnect()
})

describe('Customer self-service profile', () => {
  test('authenticated CUSTOMER reads identity with no profile and unresolved readiness', async () => {
    const { accessToken, user } = await registerAndLogin()
    const response = await request('GET', '/api/v1/customers/me', { token: accessToken })
    assert.equal(response.status, 200)
    assert.equal(response.body.data.user.id, user.id)
    assert.equal(response.body.data.profile, null)
    assert.deepEqual(response.body.data.readiness, {
      profileExists: false,
      isComplete: null,
      missingRequiredFields: null,
    })
    assert.equal(response.body.data.user.passwordHash, undefined)
  })

  test('CUSTOMER creates, persists, reads, and updates only their own empty profile', async () => {
    const { accessToken, user } = await registerAndLogin()
    const created = await request('POST', '/api/v1/customers/me/profile', {
      token: accessToken,
      body: { profileData: {} },
    })
    assert.equal(created.status, 201)
    assert.equal(created.body.data.readiness.profileExists, true)

    const persisted = await prisma.customerProfile.findUnique({ where: { userId: user.id } })
    assert.ok(persisted)

    const updated = await request('PATCH', '/api/v1/customers/me/profile', {
      token: accessToken,
      body: { profileData: {} },
    })
    assert.equal(updated.status, 200)

    const read = await request('GET', '/api/v1/customers/me', { token: accessToken })
    assert.equal(read.body.data.profile.id, persisted.id)
  })

  test('duplicate creation is rejected', async () => {
    const { accessToken } = await registerAndLogin()
    await request('POST', '/api/v1/customers/me/profile', { token: accessToken, body: { profileData: {} } })
    const duplicate = await request('POST', '/api/v1/customers/me/profile', {
      token: accessToken,
      body: { profileData: {} },
    })
    assert.equal(duplicate.status, 409)
  })

  test('anonymous and HOTEL_MANAGER callers are rejected', async () => {
    const anonymous = await request('GET', '/api/v1/customers/me')
    assert.equal(anonymous.status, 401)

    const manager = await registerAndLogin('HOTEL_MANAGER')
    const forbidden = await request('GET', '/api/v1/customers/me', { token: manager.accessToken })
    assert.equal(forbidden.status, 403)
  })

  test('ownership identifiers and unapproved profile fields are rejected', async () => {
    const customerA = await registerAndLogin()
    const customerB = await registerAndLogin()
    const manipulated = await request('POST', '/api/v1/customers/me/profile', {
      token: customerA.accessToken,
      body: { userId: customerB.user.id, profileData: {} },
    })
    assert.equal(manipulated.status, 400)
    assert.equal(await prisma.customerProfile.count({ where: { userId: customerB.user.id } }), 0)

    const arbitrary = await request('POST', '/api/v1/customers/me/profile', {
      token: customerA.accessToken,
      body: { profileData: { name: 'Not approved' } },
    })
    assert.equal(arbitrary.status, 400)
  })
})

describe('Anonymous Hotel and Hall discovery', () => {
  test('only approved active Hotels are listed and private fields are excluded', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const visible = await prisma.hotel.create({
      data: { registeredByUserId: manager.user.id, status: 'APPROVED_ACTIVE', profileData: { name: 'Visible Hotel' } },
    })
    const hidden = await prisma.hotel.create({
      data: { registeredByUserId: manager.user.id, status: 'REJECTED', profileData: { name: 'Hidden Hotel' } },
    })

    const list = await request('GET', '/api/v1/hotels/public')
    assert.equal(list.status, 200)
    assert.ok(list.body.data.some((hotel) => hotel.id === visible.id))
    assert.ok(!list.body.data.some((hotel) => hotel.id === hidden.id))
    const publicHotel = list.body.data.find((hotel) => hotel.id === visible.id)
    assert.equal(publicHotel.registeredByUserId, undefined)
    assert.equal(publicHotel.status, undefined)

    assert.equal((await request('GET', `/api/v1/hotels/public/${visible.id}`)).status, 200)
    assert.equal((await request('GET', `/api/v1/hotels/public/${hidden.id}`)).status, 404)
  })

  test('public Hall discovery returns authoritative photos and hides Halls of ineligible Hotels', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const visibleHotel = await prisma.hotel.create({
      data: { registeredByUserId: manager.user.id, status: 'APPROVED_ACTIVE' },
    })
    const hiddenHotel = await prisma.hotel.create({
      data: { registeredByUserId: manager.user.id, status: 'SUSPENDED' },
    })
    const visibleHall = await hallService.createHall({ hotelId: visibleHotel.id, profileData: { name: 'Visible', capacity: 50 } })
    const hiddenHall = await hallService.createHall({ hotelId: hiddenHotel.id, profileData: { name: 'Hidden', capacity: 50 } })
    await prisma.hallMedia.create({
      data: { hallId: visibleHall.id, type: 'PHOTO', storagePath: `halls/${visibleHall.id}/photos/test.jpg` },
    })

    const response = await request('GET', '/api/v1/halls')
    assert.equal(response.status, 200)
    const result = response.body.data.find((hall) => hall.id === visibleHall.id)
    assert.ok(result)
    assert.equal(result.photos.length, 1)
    assert.ok(!response.body.data.some((hall) => hall.id === hiddenHall.id))
  })
})
