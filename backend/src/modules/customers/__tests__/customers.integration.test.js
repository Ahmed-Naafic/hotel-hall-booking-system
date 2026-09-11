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

async function postFile(path, { filename, bytes, token }) {
  const form = new FormData()
  form.append('file', new Blob([bytes]), filename)
  const res = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: form,
  })
  const text = await res.text()
  return { status: res.status, body: text ? JSON.parse(text) : undefined }
}

const PNG_BYTES = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00])

async function registerAndLogin(accountType = 'CUSTOMER') {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  // BDR-018/BDR-019: Full Name is required at registration for a CUSTOMER or
  // HOTEL_MANAGER account.
  const fullName = accountType === 'CUSTOMER' ? 'Test Customer' : accountType === 'HOTEL_MANAGER' ? 'Test Manager' : undefined
  await request('POST', '/api/v1/auth/register', { body: { mobileNumber, password, accountType, fullName } })
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
  test('authenticated CUSTOMER reads identity with their Full Name profile, auto-created at registration (BDR-018)', async () => {
    const { accessToken, user } = await registerAndLogin()
    const response = await request('GET', '/api/v1/customers/me', { token: accessToken })
    assert.equal(response.status, 200)
    assert.equal(response.body.data.user.id, user.id)
    assert.ok(response.body.data.profile, 'registration must create a CustomerProfile')
    assert.equal(response.body.data.profile.profileData.fullName, 'Test Customer')
    assert.deepEqual(response.body.data.readiness, {
      profileExists: true,
      isComplete: null,
      missingRequiredFields: null,
    })
    assert.equal(response.body.data.user.passwordHash, undefined)
  })

  test('CUSTOMER can update their Full Name after registration (BDR-018 — a profile already exists)', async () => {
    const { accessToken, user } = await registerAndLogin()
    const persisted = await prisma.customerProfile.findUnique({ where: { userId: user.id } })
    assert.ok(persisted)
    assert.equal(persisted.profileData.fullName, 'Test Customer')

    const updated = await request('PATCH', '/api/v1/customers/me/profile', {
      token: accessToken,
      body: { profileData: { fullName: 'Updated Name' } },
    })
    assert.equal(updated.status, 200)
    assert.equal(updated.body.data.profile.profileData.fullName, 'Updated Name')

    const read = await request('GET', '/api/v1/customers/me', { token: accessToken })
    assert.equal(read.body.data.profile.id, persisted.id)
    assert.equal(read.body.data.profile.profileData.fullName, 'Updated Name')
  })

  test('creating a profile via POST after registration is rejected as a duplicate (BDR-018 — one already exists)', async () => {
    const { accessToken } = await registerAndLogin()
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
    // customerB already has exactly one CustomerProfile from their own
    // registration (BDR-018) — the assertion is that the attempted
    // `userId` override didn't create a second one against their account,
    // not that they have none at all.
    assert.equal(await prisma.customerProfile.count({ where: { userId: customerB.user.id } }), 1)

    const arbitrary = await request('POST', '/api/v1/customers/me/profile', {
      token: customerA.accessToken,
      body: { profileData: { name: 'Not approved' } },
    })
    assert.equal(arbitrary.status, 400)
  })
})

describe('Customer avatar (own profile photo)', () => {
  test('a fresh Customer has no avatar until they upload one', async () => {
    const { accessToken } = await registerAndLogin()
    const response = await request('GET', '/api/v1/customers/me', { token: accessToken })
    assert.equal(response.body.data.profile.avatarUrl, null)
  })

  test('uploading an avatar sets a real, stable avatarUrl (never a signed/temporary one)', async () => {
    const { accessToken } = await registerAndLogin()
    const uploaded = await postFile('/api/v1/customers/me/avatar', {
      filename: 'me.png',
      bytes: PNG_BYTES,
      token: accessToken,
    })
    assert.equal(uploaded.status, 201)
    assert.ok(uploaded.body.data.profile.avatarUrl)

    const read = await request('GET', '/api/v1/customers/me', { token: accessToken })
    assert.equal(read.body.data.profile.avatarUrl, uploaded.body.data.profile.avatarUrl)
  })

  test('re-uploading replaces the previous avatar, never leaving two', async () => {
    const { accessToken } = await registerAndLogin()
    const first = await postFile('/api/v1/customers/me/avatar', {
      filename: 'first.png',
      bytes: PNG_BYTES,
      token: accessToken,
    })
    const second = await postFile('/api/v1/customers/me/avatar', {
      filename: 'second.png',
      bytes: PNG_BYTES,
      token: accessToken,
    })
    assert.equal(second.status, 201)
    assert.notEqual(second.body.data.profile.avatarUrl, first.body.data.profile.avatarUrl)

    const read = await request('GET', '/api/v1/customers/me', { token: accessToken })
    assert.equal(read.body.data.profile.avatarUrl, second.body.data.profile.avatarUrl)
  })

  test('deleting the avatar clears it back to null', async () => {
    const { accessToken } = await registerAndLogin()
    await postFile('/api/v1/customers/me/avatar', { filename: 'me.png', bytes: PNG_BYTES, token: accessToken })

    const deleted = await request('DELETE', '/api/v1/customers/me/avatar', { token: accessToken })
    assert.equal(deleted.status, 200)
    assert.equal(deleted.body.data.profile.avatarUrl, null)

    const read = await request('GET', '/api/v1/customers/me', { token: accessToken })
    assert.equal(read.body.data.profile.avatarUrl, null)
  })

  test('deleting with no avatar on file is a 404, not a silent no-op', async () => {
    const { accessToken } = await registerAndLogin()
    const response = await request('DELETE', '/api/v1/customers/me/avatar', { token: accessToken })
    assert.equal(response.status, 404)
  })

  test('rejects an unsupported file type (400)', async () => {
    const { accessToken } = await registerAndLogin()
    const response = await postFile('/api/v1/customers/me/avatar', {
      filename: 'me.txt',
      bytes: Buffer.from('not an image'),
      token: accessToken,
    })
    assert.equal(response.status, 400)
  })

  test('rejects an unauthenticated upload (401)', async () => {
    const response = await postFile('/api/v1/customers/me/avatar', { filename: 'me.png', bytes: PNG_BYTES })
    assert.equal(response.status, 401)
  })

  test('a HOTEL_MANAGER cannot use the Customer avatar endpoint (403)', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const response = await postFile('/api/v1/customers/me/avatar', {
      filename: 'me.png',
      bytes: PNG_BYTES,
      token: manager.accessToken,
    })
    assert.equal(response.status, 403)
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

  test('search matches the full Hotel Name (BDR-020)', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const suffix = uniqueMobileNumber().slice(-8)
    const hotel = await prisma.hotel.create({
      data: { registeredByUserId: manager.user.id, status: 'APPROVED_ACTIVE', profileData: { name: `Hotel Guuleed ${suffix}` } },
    })

    const res = await request('GET', `/api/v1/hotels/public?search=${encodeURIComponent(`Hotel Guuleed ${suffix}`)}`)
    assert.equal(res.status, 200)
    assert.ok(res.body.data.some((h) => h.id === hotel.id))
  })

  test('search matches a partial Hotel Name (BDR-020)', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const suffix = uniqueMobileNumber().slice(-8)
    const hotel = await prisma.hotel.create({
      data: { registeredByUserId: manager.user.id, status: 'APPROVED_ACTIVE', profileData: { name: `Hotel Guuleed ${suffix}` } },
    })

    const res = await request('GET', `/api/v1/hotels/public?search=${encodeURIComponent(`Guuleed ${suffix}`)}`)
    assert.equal(res.status, 200)
    assert.ok(res.body.data.some((h) => h.id === hotel.id))
  })

  test('search is case-insensitive (BDR-020)', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const suffix = uniqueMobileNumber().slice(-8)
    const hotel = await prisma.hotel.create({
      data: { registeredByUserId: manager.user.id, status: 'APPROVED_ACTIVE', profileData: { name: `Hotel Guuleed ${suffix}` } },
    })

    const res = await request('GET', `/api/v1/hotels/public?search=${encodeURIComponent(`HOTEL GUULEED ${suffix}`)}`)
    assert.equal(res.status, 200)
    assert.ok(res.body.data.some((h) => h.id === hotel.id))
  })

  test('search matches the customer-facing address (BDR-020)', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const suffix = uniqueMobileNumber().slice(-8)
    const hotel = await prisma.hotel.create({
      data: {
        registeredByUserId: manager.user.id,
        status: 'APPROVED_ACTIVE',
        profileData: { name: 'Unrelated Hotel Name', location: { latitude: 2.05, longitude: 45.32, address: `Lido Beach ${suffix}, Mogadishu` } },
      },
    })

    const res = await request('GET', `/api/v1/hotels/public?search=${encodeURIComponent(`lido beach ${suffix}`)}`)
    assert.equal(res.status, 200)
    assert.ok(res.body.data.some((h) => h.id === hotel.id))
  })

  test('a Hotel outside the default first page is still found by search (the reported bug)', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const suffix = uniqueMobileNumber().slice(-8)
    const hotel = await prisma.hotel.create({
      data: {
        registeredByUserId: manager.user.id,
        status: 'APPROVED_ACTIVE',
        profileData: { name: `Hotel Guuleed ${suffix}` },
        createdAt: new Date('2020-01-01T00:00:00.000Z'),
      },
    })

    const unsearched = await request('GET', '/api/v1/hotels/public?limit=1')
    assert.ok(!unsearched.body.data.some((h) => h.id === hotel.id), 'expected the old Hotel to be off the default first page')

    const searched = await request('GET', `/api/v1/hotels/public?search=${encodeURIComponent(`Guuleed ${suffix}`)}&limit=1`)
    assert.equal(searched.status, 200)
    assert.ok(searched.body.data.some((h) => h.id === hotel.id), 'expected search to find it regardless of page/creation order')
  })

  test('a search with no matches returns an empty list, not an error (BDR-020)', async () => {
    const res = await request('GET', `/api/v1/hotels/public?search=${encodeURIComponent(`NoSuchHotel-${uniqueMobileNumber()}`)}`)
    assert.equal(res.status, 200)
    assert.deepEqual(res.body.data, [])
  })

  test('search still respects the existing cursor pagination contract (BDR-020)', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const suffix = uniqueMobileNumber().slice(-8)
    const first = await prisma.hotel.create({
      data: { registeredByUserId: manager.user.id, status: 'APPROVED_ACTIVE', profileData: { name: `SearchPage ${suffix} A` } },
    })
    const second = await prisma.hotel.create({
      data: { registeredByUserId: manager.user.id, status: 'APPROVED_ACTIVE', profileData: { name: `SearchPage ${suffix} B` } },
    })

    const page1 = await request('GET', `/api/v1/hotels/public?search=${encodeURIComponent(`SearchPage ${suffix}`)}&limit=1`)
    assert.equal(page1.status, 200)
    assert.equal(page1.body.data.length, 1)
    assert.equal(page1.body.pagination.hasNext, true)
    assert.ok(page1.body.pagination.nextCursor)

    const page2 = await request(
      'GET',
      `/api/v1/hotels/public?search=${encodeURIComponent(`SearchPage ${suffix}`)}&limit=1&cursor=${page1.body.pagination.nextCursor}`,
    )
    assert.equal(page2.status, 200)
    assert.equal(page2.body.data.length, 1)
    assert.notEqual(page1.body.data[0].id, page2.body.data[0].id)
    assert.deepEqual(
      [page1.body.data[0].id, page2.body.data[0].id].sort(),
      [first.id, second.id].sort(),
    )
  })

  test('search never returns a non-Approved/Active Hotel, even on a name match (BDR-020)', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const suffix = uniqueMobileNumber().slice(-8)
    const hidden = await prisma.hotel.create({
      data: { registeredByUserId: manager.user.id, status: 'REJECTED', profileData: { name: `Hidden Guuleed ${suffix}` } },
    })

    const res = await request('GET', `/api/v1/hotels/public?search=${encodeURIComponent(`Guuleed ${suffix}`)}`)
    assert.equal(res.status, 200)
    assert.ok(!res.body.data.some((h) => h.id === hidden.id))
  })

  test('an overlong search value is rejected with 400 (BDR-020)', async () => {
    const res = await request('GET', `/api/v1/hotels/public?search=${'a'.repeat(201)}`)
    assert.equal(res.status, 400)
  })

  test('omitting search leaves GET /hotels/public unchanged (BDR-020)', async () => {
    const res = await request('GET', '/api/v1/hotels/public')
    assert.equal(res.status, 200)
    assert.ok(Array.isArray(res.body.data))
    assert.ok(res.body.pagination)
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
