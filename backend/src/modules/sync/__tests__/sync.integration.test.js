import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import * as hallService from '../../halls/hall.service.js'
import * as hotelService from '../../hotels/hotel.service.js'
import * as applicationService from '../../hotels/application.service.js'
import * as lifecycleService from '../../hotels/lifecycle.service.js'

/**
 * Synchronization Component — integration tests against a real database and a
 * real server (testing-standards.md §6), no mocked cross-module calls.
 *
 * The highest-value tests here are the cross-tenant ones. Everything else in
 * this module is recoverable; leaking one Hotel's Bookings to another Manager is
 * not, so every collection is asserted against a second tenant that must
 * receive nothing.
 */

let server
let baseUrl
let adminStubUserId

function uniqueMobileNumber() {
  return `+1${Math.floor(100000000 + Math.random() * 899999999)}`
}

async function request(method, path, { body, token } = {}) {
  const res = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  })
  const text = await res.text()
  return { status: res.status, body: text ? JSON.parse(text) : undefined }
}

async function registerAndLogin(accountType = 'HOTEL_MANAGER') {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  // BDR-018/BDR-019 — Full Name is required at registration for both types.
  const fullName = accountType === 'CUSTOMER' ? 'Sync Customer' : 'Sync Manager'
  await request('POST', '/api/v1/auth/register', {
    body: { mobileNumber, password, accountType, fullName },
  })
  // Login answers with a texted code; `scripts/testEnv.js` pins it.
  await request('POST', '/api/v1/auth/login', { body: { mobileNumber, password } })
  const verified = await request('POST', '/api/v1/auth/login/verify', {
    body: { mobileNumber, code: '123456' },
  })
  const user = await prisma.user.findUnique({ where: { mobileNumber } })
  return { user, accessToken: verified.body.data.accessToken }
}

async function createPlatformAdministrator() {
  return prisma.user.create({
    data: {
      mobileNumber: uniqueMobileNumber(),
      passwordHash: 'x',
      accountType: 'PLATFORM_ADMINISTRATOR',
      isVerified: true,
    },
  })
}

async function openApplicationId(hotelId) {
  const application = await prisma.hotelApplication.findFirst({ where: { hotelId, status: 'OPEN' } })
  return application.id
}

/**
 * A Manager with an APPROVED_ACTIVE Hotel holding one Hall.
 *
 * Goes through the real endpoints rather than inserting a Hotel at
 * `APPROVED_ACTIVE`: the lifecycle is a state machine
 * (`PROFILE_COMPLETE -> UNDER_REVIEW -> APPROVED_ACTIVE`) and
 * `lifecycle.service.js#transition` rightly refuses a jump. Submitting the
 * application is what moves it to `UNDER_REVIEW`.
 */
async function managerWithApprovedHotel() {
  const manager = await registerAndLogin('HOTEL_MANAGER')
  const token = manager.accessToken
  const created = await request('POST', '/api/v1/hotels', { token, body: {} })
  const hotelId = created.body.data.id
  await request('PATCH', `/api/v1/hotels/${hotelId}`, {
    token,
    body: {
      name: `Sync Hotel ${Date.now()}`,
      description: 'Seeded for synchronization tests.',
      location: { address: 'Somewhere', latitude: 2.0469, longitude: 45.3182 },
      contactPhone: '+15550001111',
    },
  })
  await request('POST', `/api/v1/hotels/${hotelId}/applications`, { token })
  const hotel = await hotelService.getHotelById(hotelId)
  await applicationService.recordDecision(hotel, await openApplicationId(hotelId), 'APPROVED', adminStubUserId)
  const hall = await hallService.createHall({
    hotelId,
    profileData: { name: 'Sync Hall', capacity: 100 },
  })
  return { ...manager, hotelId, hallId: hall.id }
}

function sync(collection, { token, since, limit } = {}) {
  const query = new URLSearchParams()
  if (since !== undefined) query.set('since', String(since))
  if (limit !== undefined) query.set('limit', String(limit))
  const suffix = query.toString() ? `?${query}` : ''
  return request('GET', `/api/v1/sync/${collection}${suffix}`, { token })
}

const ALL_COLLECTIONS = [
  'hotel',
  'hall',
  'hotelMedia',
  'hallMedia',
  'availabilityBlock',
  'booking',
  'notification',
  'hotelApplication',
]

before(async () => {
  server = createApp().listen(0)
  await new Promise((resolve) => server.once('listening', resolve))
  baseUrl = `http://127.0.0.1:${server.address().port}`
  adminStubUserId = (await createPlatformAdministrator()).id
})

after(async () => {
  await new Promise((resolve) => server.close(resolve))
  await prisma.$disconnect()
})

describe('Authorization', () => {
  test('rejects an unauthenticated request (401)', async () => {
    const res = await sync('hall')
    assert.equal(res.status, 401)
  })

  test('rejects an unknown collection before any query runs (400)', async () => {
    const manager = await managerWithApprovedHotel()
    const res = await sync('users', { token: manager.accessToken })
    assert.equal(res.status, 400)
    assert.equal(res.body.error, 'VALIDATION_ERROR')
  })

  test('a Customer cannot synchronize a Manager collection (403)', async () => {
    const customer = await registerAndLogin('CUSTOMER')
    for (const collection of ALL_COLLECTIONS) {
      const res = await sync(collection, { token: customer.accessToken })
      assert.equal(res.status, 403, `${collection} must be refused for a Customer`)
    }
  })

  test('rejects a malformed since cursor (400)', async () => {
    const manager = await managerWithApprovedHotel()
    const res = await sync('hall', { token: manager.accessToken, since: 'not-a-number' })
    assert.equal(res.status, 400)
  })

  test('rejects a limit outside its bounds (400)', async () => {
    const manager = await managerWithApprovedHotel()
    assert.equal((await sync('hall', { token: manager.accessToken, limit: 0 })).status, 400)
    assert.equal((await sync('hall', { token: manager.accessToken, limit: 5000 })).status, 400)
  })
})

describe('Tenant isolation', () => {
  test('no collection returns another Manager’s rows', async () => {
    const mine = await managerWithApprovedHotel()
    const theirs = await managerWithApprovedHotel()

    // Give the other tenant something to leak in every collection.
    await prisma.hotelMedia.create({
      data: { hotelId: theirs.hotelId, type: 'PHOTO', storagePath: `hotels/${theirs.hotelId}/p.jpg` },
    })
    await prisma.hallMedia.create({
      data: { hallId: theirs.hallId, type: 'PHOTO', storagePath: `halls/${theirs.hallId}/p.jpg` },
    })
    await prisma.hallAvailabilityBlock.create({
      data: {
        hallId: theirs.hallId,
        startsAt: new Date(Date.now() + 86400000),
        endsAt: new Date(Date.now() + 90000000),
        createdByUserId: theirs.user.id,
      },
    })

    const foreignIds = new Set([theirs.hotelId, theirs.hallId])

    for (const collection of ALL_COLLECTIONS) {
      const res = await sync(collection, { token: mine.accessToken, limit: 100 })
      assert.equal(res.status, 200, `${collection} must succeed for its owner`)
      for (const row of res.body.data.changed) {
        assert.ok(
          !foreignIds.has(row.id),
          `${collection} leaked a row belonging to another tenant: ${row.id}`,
        )
        if (row.hotelId !== undefined) {
          assert.equal(row.hotelId, mine.hotelId, `${collection} leaked a foreign hotelId`)
        }
      }
    }
  })

  test('a Manager with no Hotel receives nothing, never everything', async () => {
    // The empty-scope case: `hotelId: { in: [] }` must narrow to zero rows.
    await managerWithApprovedHotel() // somebody else's data exists
    const hotelless = await registerAndLogin('HOTEL_MANAGER')

    for (const collection of ['hotel', 'hall', 'hotelMedia', 'hallMedia', 'availabilityBlock', 'booking', 'hotelApplication']) {
      const res = await sync(collection, { token: hotelless.accessToken, limit: 100 })
      assert.equal(res.status, 200)
      assert.deepEqual(res.body.data.changed, [], `${collection} must be empty for a Manager with no Hotel`)
    }
  })

  test('a Notification addressed to somebody else is never returned', async () => {
    const mine = await managerWithApprovedHotel()
    const theirs = await managerWithApprovedHotel()
    const foreign = await prisma.notification.create({
      data: {
        recipientUserId: theirs.user.id,
        type: 'NEW_BOOKING_REQUEST',
        title: 'Not yours',
        body: 'Addressed to another Manager.',
      },
    })

    const res = await sync('notification', { token: mine.accessToken, limit: 100 })
    assert.equal(res.status, 200)
    assert.ok(!res.body.data.changed.some((row) => row.id === foreign.id))
  })

  test('scopeId changes when the caller’s scope changes', async () => {
    const manager = await registerAndLogin('HOTEL_MANAGER')
    const before = await sync('hall', { token: manager.accessToken })
    assert.equal(before.status, 200)

    await prisma.hotel.create({
      data: { registeredByUserId: manager.user.id, status: 'REGISTERED', profileData: { name: 'Later Hotel' } },
    })

    const after = await sync('hall', { token: manager.accessToken })
    assert.notEqual(
      after.body.data.scopeId,
      before.body.data.scopeId,
      'a client must be able to detect that its scope changed and wipe',
    )
  })
})

describe('Cursor and pagination', () => {
  test('initial sync returns everything in ascending syncSeq order', async () => {
    const manager = await managerWithApprovedHotel()
    for (const name of ['Paged A', 'Paged B', 'Paged C']) {
      await hallService.createHall({ hotelId: manager.hotelId, profileData: { name } })
    }

    const res = await sync('hall', { token: manager.accessToken, limit: 100 })
    assert.equal(res.status, 200)
    const seqs = res.body.data.changed.map((row) => BigInt(row.syncSeq))
    assert.ok(seqs.length >= 4)
    for (let i = 1; i < seqs.length; i += 1) {
      assert.ok(seqs[i] > seqs[i - 1], 'rows must ascend by syncSeq')
    }
  })

  test('paging with the returned cursor visits every row exactly once', async () => {
    const manager = await managerWithApprovedHotel()
    for (const name of ['Cur A', 'Cur B', 'Cur C', 'Cur D']) {
      await hallService.createHall({ hotelId: manager.hotelId, profileData: { name } })
    }

    const seen = []
    let cursor
    for (let guard = 0; guard < 20; guard += 1) {
      const res = await sync('hall', { token: manager.accessToken, since: cursor, limit: 2 })
      assert.equal(res.status, 200)
      seen.push(...res.body.data.changed.map((row) => row.id))
      if (!res.body.pagination.hasNext) break
      cursor = res.body.pagination.nextCursor
      assert.ok(cursor, 'hasNext implies a cursor')
    }

    assert.equal(new Set(seen).size, seen.length, 'no row may appear twice across pages')
    assert.ok(seen.length >= 5, `expected at least 5 Halls, saw ${seen.length}`)
  })

  test('a cursor at the head returns an empty page, and repeating it is idempotent', async () => {
    const manager = await managerWithApprovedHotel()
    const first = await sync('hall', { token: manager.accessToken, limit: 100 })
    const head = first.body.data.changed.map((row) => BigInt(row.syncSeq)).sort((a, b) => (a > b ? 1 : -1)).at(-1)

    const empty = await sync('hall', { token: manager.accessToken, since: head, limit: 100 })
    assert.equal(empty.status, 200)
    assert.deepEqual(empty.body.data.changed, [])
    assert.equal(empty.body.pagination.hasNext, false)

    const again = await sync('hall', { token: manager.accessToken, since: head, limit: 100 })
    assert.deepEqual(again.body.data.changed, [], 'repeating a sync must change nothing')
  })

  test('nextCursor is the highest syncSeq in the page, not the server clock', async () => {
    const manager = await managerWithApprovedHotel()
    for (const name of ['Head A', 'Head B']) {
      await hallService.createHall({ hotelId: manager.hotelId, profileData: { name } })
    }

    const res = await sync('hall', { token: manager.accessToken, limit: 1 })
    assert.equal(res.status, 200)
    assert.equal(res.body.pagination.nextCursor, res.body.data.changed.at(-1).syncSeq)
  })
})

describe('Incremental change detection', () => {
  test('an inserted row appears in the next incremental sync', async () => {
    const manager = await managerWithApprovedHotel()
    const first = await sync('hall', { token: manager.accessToken, limit: 100 })
    const mark = first.body.pagination.nextCursor ?? first.body.data.changed.at(-1).syncSeq

    const added = await hallService.createHall({
      hotelId: manager.hotelId,
      profileData: { name: 'Inserted Hall' },
    })

    const next = await sync('hall', { token: manager.accessToken, since: mark, limit: 100 })
    assert.deepEqual(next.body.data.changed.map((row) => row.id), [added.id])
  })

  test('an updated row reappears with a higher syncSeq', async () => {
    const manager = await managerWithApprovedHotel()
    const first = await sync('hall', { token: manager.accessToken, limit: 100 })
    const original = first.body.data.changed.find((row) => row.id === manager.hallId)
    const mark = first.body.data.changed.map((row) => BigInt(row.syncSeq)).sort((a, b) => (a > b ? 1 : -1)).at(-1)

    await prisma.hall.update({ where: { id: manager.hallId }, data: { isActive: false } })

    const next = await sync('hall', { token: manager.accessToken, since: mark, limit: 100 })
    const updated = next.body.data.changed.find((row) => row.id === manager.hallId)
    assert.ok(updated, 'the updated Hall must reappear')
    assert.ok(BigInt(updated.syncSeq) > BigInt(original.syncSeq))
    assert.equal(updated.isActive, false)
  })

  test('a soft-deleted row arrives as a tombstone, not as data', async () => {
    const manager = await managerWithApprovedHotel()
    const media = await prisma.hallMedia.create({
      data: { hallId: manager.hallId, type: 'PHOTO', storagePath: `halls/${manager.hallId}/tomb.jpg` },
    })
    const first = await sync('hallMedia', { token: manager.accessToken, limit: 100 })
    assert.ok(first.body.data.changed.some((row) => row.id === media.id))
    const mark = first.body.data.changed.map((row) => BigInt(row.syncSeq)).sort((a, b) => (a > b ? 1 : -1)).at(-1)

    await prisma.hallMedia.update({ where: { id: media.id }, data: { deletedAt: new Date() } })

    const next = await sync('hallMedia', { token: manager.accessToken, since: mark, limit: 100 })
    assert.ok(next.body.data.deleted.includes(media.id), 'the tombstone must be reported as deleted')
    assert.ok(
      !next.body.data.changed.some((row) => row.id === media.id),
      'a tombstone must not also arrive as live data',
    )
  })

  test('an availability block deletion arrives as a tombstone', async () => {
    const manager = await managerWithApprovedHotel()
    const block = await prisma.hallAvailabilityBlock.create({
      data: {
        hallId: manager.hallId,
        startsAt: new Date(Date.now() + 5 * 86400000),
        endsAt: new Date(Date.now() + 5 * 86400000 + 3600000),
        createdByUserId: manager.user.id,
      },
    })
    const first = await sync('availabilityBlock', { token: manager.accessToken, limit: 100 })
    const mark = first.body.data.changed.map((row) => BigInt(row.syncSeq)).sort((a, b) => (a > b ? 1 : -1)).at(-1)

    await prisma.hallAvailabilityBlock.update({
      where: { id: block.id },
      data: { deletedAt: new Date() },
    })

    const next = await sync('availabilityBlock', { token: manager.accessToken, since: mark, limit: 100 })
    assert.ok(next.body.data.deleted.includes(block.id))
  })
})

describe('Hotel lifecycle propagation', () => {
  test('suspending the Hotel republishes its Halls and media to the Manager', async () => {
    const manager = await managerWithApprovedHotel()
    await prisma.hallMedia.create({
      data: { hallId: manager.hallId, type: 'PHOTO', storagePath: `halls/${manager.hallId}/fan.jpg` },
    })

    const halls = await sync('hall', { token: manager.accessToken, limit: 100 })
    const media = await sync('hallMedia', { token: manager.accessToken, limit: 100 })
    const hallMark = halls.body.data.changed.map((r) => BigInt(r.syncSeq)).sort((a, b) => (a > b ? 1 : -1)).at(-1)
    const mediaMark = media.body.data.changed.map((r) => BigInt(r.syncSeq)).sort((a, b) => (a > b ? 1 : -1)).at(-1)

    const hotel = await hotelService.getHotelById(manager.hotelId)
    await lifecycleService.transition(hotel, 'SUSPENDED')

    // The Hall rows were not edited — visibility is derived from Hotel status —
    // so only the sync_seq fan-out can surface them.
    const hallsAfter = await sync('hall', { token: manager.accessToken, since: hallMark, limit: 100 })
    const mediaAfter = await sync('hallMedia', { token: manager.accessToken, since: mediaMark, limit: 100 })

    assert.ok(
      hallsAfter.body.data.changed.some((row) => row.id === manager.hallId),
      'a suspended Hotel must republish its Halls, or replicas keep showing them',
    )
    assert.ok(mediaAfter.body.data.changed.length > 0, 'its Hall media must be republished too')
  })

  test('reactivating the Hotel republishes them again', async () => {
    const manager = await managerWithApprovedHotel()
    const suspended = await hotelService.getHotelById(manager.hotelId)
    await lifecycleService.transition(suspended, 'SUSPENDED')

    const halls = await sync('hall', { token: manager.accessToken, limit: 100 })
    const mark = halls.body.data.changed.map((r) => BigInt(r.syncSeq)).sort((a, b) => (a > b ? 1 : -1)).at(-1)

    const reloaded = await hotelService.getHotelById(manager.hotelId)
    await lifecycleService.transition(reloaded, 'APPROVED_ACTIVE')

    const after = await sync('hall', { token: manager.accessToken, since: mark, limit: 100 })
    assert.ok(after.body.data.changed.some((row) => row.id === manager.hallId))
  })
})

describe('Booking collection', () => {
  test('never exposes the Customer’s contact details (Technical Design §5)', async () => {
    const manager = await managerWithApprovedHotel()
    const customer = await registerAndLogin('CUSTOMER')
    await prisma.hall.update({
      where: { id: manager.hallId },
      data: { rentAmountCents: 100000, advancePaymentPercent: 30 },
    })
    const booking = await prisma.booking.create({
      data: {
        customerUserId: customer.user.id,
        hotelId: manager.hotelId,
        hallId: manager.hallId,
        startsAt: new Date(Date.now() + 10 * 86400000),
        endsAt: new Date(Date.now() + 10 * 86400000 + 7200000),
        numberOfGuests: 20,
        eventType: 'WEDDING',
        paymentDeadlineAt: new Date(Date.now() + 86400000),
        totalRentCents: 100000,
        advancePercentSnapshot: 30,
        requiredAdvanceCents: 30000,
      },
    })

    const res = await sync('booking', { token: manager.accessToken, limit: 100 })
    assert.equal(res.status, 200)
    const row = res.body.data.changed.find((r) => r.id === booking.id)
    assert.ok(row, 'the Manager must receive their own Hotel’s Booking')

    const serialised = JSON.stringify(row)
    assert.ok(!serialised.includes(customer.user.mobileNumber), 'mobileNumber must never be replicated')
    assert.equal(row.customer, undefined, 'no customer relation may be included')
    assert.equal(row.fullName, undefined)
    // The reference is kept so the app can fetch details online when opened.
    assert.equal(row.customerUserId, customer.user.id)
  })

  test('advances overdue Bookings before scanning, so a replica never holds a stale PENDING', async () => {
    const manager = await managerWithApprovedHotel()
    const customer = await registerAndLogin('CUSTOMER')
    const booking = await prisma.booking.create({
      data: {
        customerUserId: customer.user.id,
        hotelId: manager.hotelId,
        hallId: manager.hallId,
        startsAt: new Date(Date.now() + 20 * 86400000),
        endsAt: new Date(Date.now() + 20 * 86400000 + 7200000),
        numberOfGuests: 10,
        eventType: 'MEETING',
        // Already past its deadline and unpaid — the sweep must expire it.
        paymentDeadlineAt: new Date(Date.now() - 3600000),
        totalRentCents: 100000,
        advancePercentSnapshot: 30,
        requiredAdvanceCents: 30000,
      },
    })

    const res = await sync('booking', { token: manager.accessToken, limit: 100 })
    const row = res.body.data.changed.find((r) => r.id === booking.id)
    assert.ok(row)
    assert.equal(row.status, 'EXPIRED', 'sync must run the clock sweep, not serve a stale status')
  })

  test('serialises Decimal and BigInt safely', async () => {
    const manager = await managerWithApprovedHotel()
    const res = await sync('hall', { token: manager.accessToken, limit: 100 })
    assert.equal(res.status, 200)
    const row = res.body.data.changed[0]
    assert.equal(typeof row.syncSeq, 'string', 'syncSeq must travel as a string, not a JSON number')
  })
})

describe('Response envelope', () => {
  test('uses the project’s existing envelope and reports its own scope', async () => {
    const manager = await managerWithApprovedHotel()
    const res = await sync('hall', { token: manager.accessToken })

    assert.equal(res.status, 200)
    assert.equal(res.body.status, 'success')
    assert.ok(res.body.timestamp)
    assert.ok(Array.isArray(res.body.data.changed))
    assert.ok(Array.isArray(res.body.data.deleted))
    assert.ok(res.body.data.scopeId)
    assert.ok(res.body.data.serverTime)
    assert.equal(res.body.pagination.limit, 20)
    assert.ok('hasNext' in res.body.pagination)
    assert.ok('nextCursor' in res.body.pagination)
  })
})
