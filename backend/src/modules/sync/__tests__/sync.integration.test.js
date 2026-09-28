import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import * as hallService from '../../halls/hall.service.js'
import * as hotelService from '../../hotels/hotel.service.js'
import * as applicationService from '../../hotels/application.service.js'
import * as lifecycleService from '../../hotels/lifecycle.service.js'
import * as hallMediaService from '../../halls/media.service.js'
import jwt from 'jsonwebtoken'
import { env } from '../../../config/env.js'

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

/**
 * Follows `nextCursor` until the collection is caught up, the way a client
 * does, and returns everything received plus the cursor to resume from.
 */
async function drain(collection, { token, since, limit = 100 } = {}) {
  const changed = []
  const deleted = []
  let cursor = since
  for (let guard = 0; guard < 50; guard += 1) {
    const res = await sync(collection, { token, since: cursor, limit })
    assert.equal(res.status, 200, JSON.stringify(res.body))
    changed.push(...res.body.data.changed)
    deleted.push(...res.body.data.deleted)
    cursor = res.body.pagination.nextCursor
    if (!res.body.pagination.hasNext) return { changed, deleted, cursor }
  }
  throw new Error('drain did not converge')
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

  test('an expired access token on a private collection is refused (401), never degraded to anonymous', async () => {
    const manager = await managerWithApprovedHotel()
    const claims = jwt.decode(manager.accessToken)
    const expired = jwt.sign(
      { sub: claims.sub, accountType: claims.accountType, sid: claims.sid, exp: Math.floor(Date.now() / 1000) - 60 },
      env.auth.jwtSecret,
    )
    for (const collection of ALL_COLLECTIONS) {
      const res = await sync(collection, { token: expired })
      assert.equal(res.status, 401, `${collection} must refuse an expired token`)
    }
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

    // Give the other tenant a row in EVERY collection, and remember every id.
    // Several mapped shapes carry only `hallId`, not `hotelId`, so the id set —
    // not a hotelId comparison — is what makes this assertion non-vacuous.
    const customer = await registerAndLogin('CUSTOMER')
    const foreignHotelMedia = await prisma.hotelMedia.create({
      data: { hotelId: theirs.hotelId, type: 'PHOTO', storagePath: `hotels/${theirs.hotelId}/p.jpg` },
    })
    const foreignHallMedia = await prisma.hallMedia.create({
      data: { hallId: theirs.hallId, type: 'PHOTO', storagePath: `halls/${theirs.hallId}/p.jpg` },
    })
    const foreignBlock = await prisma.hallAvailabilityBlock.create({
      data: {
        hallId: theirs.hallId,
        startsAt: new Date(Date.now() + 86400000),
        endsAt: new Date(Date.now() + 90000000),
        createdByUserId: theirs.user.id,
      },
    })
    const foreignBooking = await prisma.booking.create({
      data: {
        customerUserId: customer.user.id,
        hotelId: theirs.hotelId,
        hallId: theirs.hallId,
        startsAt: new Date(Date.now() + 40 * 86400000),
        endsAt: new Date(Date.now() + 40 * 86400000 + 3600000),
        numberOfGuests: 10,
        eventType: 'CONFERENCE',
        paymentDeadlineAt: new Date(Date.now() + 86400000),
        totalRentCents: 1000,
        advancePercentSnapshot: 30,
        requiredAdvanceCents: 300,
      },
    })
    const foreignNotification = await prisma.notification.create({
      data: { recipientUserId: theirs.user.id, type: 'NEW_BOOKING_REQUEST', title: 'x', body: 'y' },
    })
    const foreignApplications = await prisma.hotelApplication.findMany({ where: { hotelId: theirs.hotelId } })
    assert.ok(foreignApplications.length > 0, 'the other tenant must have an application to leak')

    const foreignIds = new Set([
      theirs.hotelId,
      theirs.hallId,
      foreignHotelMedia.id,
      foreignHallMedia.id,
      foreignBlock.id,
      foreignBooking.id,
      foreignNotification.id,
      ...foreignApplications.map((a) => a.id),
    ])

    for (const collection of ALL_COLLECTIONS) {
      const { changed, deleted } = await drain(collection, { token: mine.accessToken })
      for (const id of deleted) {
        assert.ok(!foreignIds.has(id), `${collection} leaked a foreign tombstone: ${id}`)
      }
      for (const row of changed) {
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
    const { cursor: head } = await drain('hall', { token: manager.accessToken })

    const empty = await sync('hall', { token: manager.accessToken, since: head, limit: 100 })
    assert.equal(empty.status, 200)
    assert.deepEqual(empty.body.data.changed, [])
    assert.equal(empty.body.pagination.hasNext, false)
    assert.ok(empty.body.pagination.nextCursor, 'an empty page still returns a cursor to resume from')

    const again = await sync('hall', { token: manager.accessToken, since: head, limit: 100 })
    assert.deepEqual(again.body.data.changed, [], 'repeating a sync must change nothing')
  })

  test('a retried page request returns the same rows (a lost response is safe to repeat)', async () => {
    const manager = await managerWithApprovedHotel()
    for (const name of ['Retry A', 'Retry B', 'Retry C']) {
      await hallService.createHall({ hotelId: manager.hotelId, profileData: { name } })
    }
    const first = await sync('hall', { token: manager.accessToken, limit: 2 })
    const cursor = first.body.pagination.nextCursor
    assert.equal(first.body.pagination.hasNext, true)

    const attempt1 = await sync('hall', { token: manager.accessToken, since: cursor, limit: 2 })
    const attempt2 = await sync('hall', { token: manager.accessToken, since: cursor, limit: 2 })
    assert.deepEqual(
      attempt2.body.data.changed.map((r) => r.id),
      attempt1.body.data.changed.map((r) => r.id),
    )
    assert.equal(attempt2.body.pagination.nextCursor, attempt1.body.pagination.nextCursor)
  })

  test('nextCursor is opaque, and a forged or malformed one is rejected (400), never a 500', async () => {
    const manager = await managerWithApprovedHotel()
    const res = await sync('hall', { token: manager.accessToken, limit: 1 })
    assert.equal(typeof res.body.pagination.nextCursor, 'string')
    assert.ok(!/^\d+$/.test(res.body.pagination.nextCursor), 'the cursor is not a bare sequence number')

    const forge = (body) => Buffer.from(JSON.stringify(body)).toString('base64url')
    const bad = [
      '12345',
      'not base64 !!',
      forge({ v: 1, lo: "1:2:'; DROP TABLE halls; --", hi: null, after: null }),
      forge({ v: 1, lo: null, hi: null, after: '5' }), // `after` without a batch
      forge({ v: 1, lo: null, hi: '1:2:', after: '-1' }),
      // Shape-valid but rejected by pg_snapshot_in / int8 — each once a 500.
      forge({ v: 1, lo: '9:5:', hi: null, after: null }), // xmin > xmax
      forge({ v: 1, lo: '5:9:12', hi: null, after: null }), // xip outside [xmin, xmax)
      forge({ v: 1, lo: '5:9:7,6', hi: null, after: null }), // xip not ascending
      forge({ v: 1, lo: '1:99999999999999999999:', hi: null, after: null }), // beyond 64 bits
      forge({ v: 1, lo: null, hi: '1:2:', after: '9999999999999999999' }), // beyond int8
    ]
    for (const since of bad) {
      const rejected = await sync('hall', { token: manager.accessToken, since })
      assert.equal(rejected.status, 400, `cursor ${since} must be a 400`)
      assert.equal(rejected.body.error, 'VALIDATION_ERROR')
    }
  })

  test('a cursor from another cursor version is expired (409), so the client resyncs instead of wedging', async () => {
    const manager = await managerWithApprovedHotel()
    const old = Buffer.from(JSON.stringify({ v: 0, lo: null, hi: null, after: null })).toString('base64url')
    const res = await sync('hall', { token: manager.accessToken, since: old })
    assert.equal(res.status, 409)
    assert.equal(res.body.error, 'SYNC_CURSOR_EXPIRED')
  })

  test('a cursor ahead of the database (restored or branched) is expired, never silently empty', async () => {
    // After a point-in-time restore the transaction counter moves backwards;
    // such a cursor would count every new write as already seen.
    const manager = await managerWithApprovedHotel()
    const { cursor } = await drain('hall', { token: manager.accessToken })
    const body = JSON.parse(Buffer.from(cursor, 'base64url').toString('utf8'))
    const [xmin, xmax] = body.lo.split(':').map(BigInt)
    body.lo = `${xmin + 10000000000n}:${xmax + 10000000000n}:`
    const ahead = Buffer.from(JSON.stringify(body)).toString('base64url')

    const res = await sync('hall', { token: manager.accessToken, since: ahead })
    assert.equal(res.status, 409)
    assert.equal(res.body.error, 'SYNC_CURSOR_EXPIRED')
  })

  test('a row written before sync_txid existed arrives in the initial batch only, until written again', async () => {
    const manager = await managerWithApprovedHotel()
    // A pre-migration row: the column default applies only when the column is
    // omitted, so an explicit NULL on insert reproduces one without needing
    // superuser rights to bypass the update trigger.
    const legacy = await prisma.hall.create({
      data: { hotelId: manager.hotelId, profileData: { name: 'Legacy Hall' }, syncTxid: null },
    })
    assert.equal(legacy.syncTxid, null)
    manager.hallId = legacy.id

    const initial = await drain('hall', { token: manager.accessToken })
    assert.ok(initial.changed.some((r) => r.id === manager.hallId), 'initial sync includes it')

    const later = await drain('hall', { token: manager.accessToken, since: initial.cursor })
    assert.ok(!later.changed.some((r) => r.id === manager.hallId), 'never redelivered by a later batch')

    await prisma.hall.update({ where: { id: manager.hallId }, data: { isActive: false } })
    const afterWrite = await drain('hall', { token: manager.accessToken, since: later.cursor })
    assert.equal(afterWrite.changed.find((r) => r.id === manager.hallId)?.isActive, false)
  })

  test('a transaction that commits out of sequence order is still delivered', async () => {
    // The defect the snapshot-window cursor exists to prevent. A slow writer
    // draws its sync_seq first; a fast writer draws a higher one and commits
    // first; the client syncs in between. With a `sync_seq > :since` cursor the
    // slow row was skipped permanently — reproduced before the fix.
    const manager = await managerWithApprovedHotel()
    const { cursor: start } = await drain('hall', { token: manager.accessToken })

    let release
    const gate = new Promise((resolve) => { release = resolve })
    let slowId
    let slowDrawn
    const drawn = new Promise((resolve) => { slowDrawn = resolve })
    const slow = prisma.$transaction(async (tx) => {
      const hall = await tx.hall.create({ data: { hotelId: manager.hotelId, profileData: { name: 'Slow Hall' } } })
      slowId = hall.id
      slowDrawn(hall.syncSeq)
      await gate
    }, { timeout: 20000 })

    const slowSeq = await drawn
    const fast = await prisma.hall.create({ data: { hotelId: manager.hotelId, profileData: { name: 'Fast Hall' } } })
    assert.ok(BigInt(fast.syncSeq) > BigInt(slowSeq), 'precondition: the fast row drew the higher number')

    const between = await drain('hall', { token: manager.accessToken, since: start })
    assert.deepEqual(between.changed.map((r) => r.id), [fast.id], 'only the committed row is visible yet')

    release()
    await slow

    const after = await drain('hall', { token: manager.accessToken, since: between.cursor })
    assert.deepEqual(after.changed.map((r) => r.id), [slowId], 'the late-committing row must still arrive')
  })
})

describe('Incremental change detection', () => {
  test('an inserted row appears in the next incremental sync', async () => {
    const manager = await managerWithApprovedHotel()
    const { cursor: mark } = await drain('hall', { token: manager.accessToken })

    const added = await hallService.createHall({
      hotelId: manager.hotelId,
      profileData: { name: 'Inserted Hall' },
    })

    const next = await sync('hall', { token: manager.accessToken, since: mark, limit: 100 })
    assert.deepEqual(next.body.data.changed.map((row) => row.id), [added.id])
  })

  test('an updated row reappears with a higher syncSeq', async () => {
    const manager = await managerWithApprovedHotel()
    const first = await drain('hall', { token: manager.accessToken })
    const original = first.changed.find((row) => row.id === manager.hallId)
    const mark = first.cursor

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
    const first = await drain('hallMedia', { token: manager.accessToken })
    assert.ok(first.changed.some((row) => row.id === media.id))
    const mark = first.cursor

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
    const { cursor: mark } = await drain('availabilityBlock', { token: manager.accessToken })

    await prisma.hallAvailabilityBlock.update({
      where: { id: block.id },
      data: { deletedAt: new Date() },
    })

    const next = await sync('availabilityBlock', { token: manager.accessToken, since: mark, limit: 100 })
    assert.ok(next.body.data.deleted.includes(block.id))
  })
})

describe('Convergence', () => {
  test('notification read state converges across two devices of the same Manager', async () => {
    const manager = await managerWithApprovedHotel()
    const notification = await prisma.notification.create({
      data: { recipientUserId: manager.user.id, type: 'NEW_BOOKING_REQUEST', title: 'Two devices', body: 'b' },
    })
    const phone = await drain('notification', { token: manager.accessToken })
    const tablet = await drain('notification', { token: manager.accessToken })
    for (const device of [phone, tablet]) {
      assert.equal(device.changed.find((r) => r.id === notification.id)?.status, 'UNREAD')
    }

    // Read on the phone, through the existing command endpoint.
    const read = await request('POST', `/api/v1/notifications/${notification.id}/read`, { token: manager.accessToken })
    assert.equal(read.status, 200)

    for (const device of [phone, tablet]) {
      const next = await drain('notification', { token: manager.accessToken, since: device.cursor })
      assert.equal(next.changed.find((r) => r.id === notification.id)?.status, 'READ', 'both devices converge on READ')
    }
  })

  test('a soft-deleted Hall arrives as a tombstone', async () => {
    const manager = await managerWithApprovedHotel()
    const { cursor } = await drain('hall', { token: manager.accessToken })
    await prisma.hall.update({ where: { id: manager.hallId }, data: { deletedAt: new Date() } })

    const next = await drain('hall', { token: manager.accessToken, since: cursor })
    assert.ok(next.deleted.includes(manager.hallId))
    assert.ok(!next.changed.some((r) => r.id === manager.hallId))
  })
})

describe('Hotel lifecycle propagation', () => {
  test('suspending the Hotel republishes its Halls and media to the Manager', async () => {
    const manager = await managerWithApprovedHotel()
    await prisma.hallMedia.create({
      data: { hallId: manager.hallId, type: 'PHOTO', storagePath: `halls/${manager.hallId}/fan.jpg` },
    })

    const { cursor: hallMark } = await drain('hall', { token: manager.accessToken })
    const { cursor: mediaMark } = await drain('hallMedia', { token: manager.accessToken })

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

    const { cursor: mark } = await drain('hall', { token: manager.accessToken })

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

describe('Response shape — the same shape the REST endpoints return', () => {
  /**
   * Sync originally returned raw Prisma rows. That silently degraded two things
   * the client depends on, neither of which raises an error:
   *
   *   - `photos`, whose public URL `toPublicHall` derives from `storagePath` via
   *     the storage provider. A device cannot do that — it does not know the
   *     bucket host — so every replicated Hall would have shown no photos.
   *   - `bookingTerms`, which the mapper composes from flat columns. Parsing a
   *     raw row yields `{}`, not a failure.
   *
   * Reusing each module's existing mapper is what fixes it, and this asserts the
   * fix rather than the intention.
   */
  test('a synced Hall carries photos with derived URLs and composed bookingTerms', async () => {
    const manager = await managerWithApprovedHotel()
    await prisma.hall.update({
      where: { id: manager.hallId },
      data: { rentAmountCents: 250000, rentDurationHours: 24, advancePaymentPercent: 30 },
    })
    await prisma.hallMedia.create({
      data: { hallId: manager.hallId, type: 'PHOTO', storagePath: `halls/${manager.hallId}/shape.jpg` },
    })

    const res = await sync('hall', { token: manager.accessToken, limit: 100 })
    assert.equal(res.status, 200)
    const hall = res.body.data.changed.find((row) => row.id === manager.hallId)
    assert.ok(hall, 'the Manager must receive their own Hall')

    assert.ok(Array.isArray(hall.photos), 'photos must be present, not absent')
    assert.equal(hall.photos.length, 1)
    assert.ok(hall.photos[0].url, 'each photo must carry a URL the client cannot derive itself')

    assert.ok(hall.bookingTerms, 'bookingTerms must be composed, not left empty')
    assert.equal(hall.bookingTerms.rentAmountCents, 250000)
    assert.equal(hall.bookingTerms.advancePaymentPercent, 30)
    assert.equal(hall.bookingTerms.currency, 'USD')

    // And the sync ordering key rides alongside the business shape.
    assert.equal(typeof hall.syncSeq, 'string')
  })

  test('a synced Hall media row carries its hallId, which the client indexes by', async () => {
    const manager = await managerWithApprovedHotel()
    const media = await prisma.hallMedia.create({
      data: { hallId: manager.hallId, type: 'PHOTO', storagePath: `halls/${manager.hallId}/scope.jpg` },
    })

    const res = await sync('hallMedia', { token: manager.accessToken, limit: 100 })
    const row = res.body.data.changed.find((r) => r.id === media.id)
    assert.ok(row)
    assert.equal(row.hallId, manager.hallId, 'the client lifts hallId into an indexed column')
    assert.ok(row.url, 'media URL is derived server-side')
  })

  test('a synced Booking still carries no customer relation after mapping', async () => {
    const manager = await managerWithApprovedHotel()
    const customer = await registerAndLogin('CUSTOMER')
    const booking = await prisma.booking.create({
      data: {
        customerUserId: customer.user.id,
        hotelId: manager.hotelId,
        hallId: manager.hallId,
        startsAt: new Date(Date.now() + 30 * 86400000),
        endsAt: new Date(Date.now() + 30 * 86400000 + 7200000),
        numberOfGuests: 15,
        eventType: 'CONFERENCE',
        paymentDeadlineAt: new Date(Date.now() + 86400000),
        totalRentCents: 100000,
        advancePercentSnapshot: 30,
        requiredAdvanceCents: 30000,
      },
    })

    const res = await sync('booking', { token: manager.accessToken, limit: 100 })
    const row = res.body.data.changed.find((r) => r.id === booking.id)
    assert.ok(row)
    // `toBooking` emits `customer` only when the relation is loaded; the sync
    // query deliberately does not load it. This asserts the mapper cannot leak
    // through it.
    assert.equal(row.customer, undefined, 'no customer object may appear')
    assert.ok(!JSON.stringify(row).includes(customer.user.mobileNumber))
  })
})

describe('Media changes republish their parent', () => {
  /**
   * A synced Hall/Hotel embeds its photos (see "Response shape" above), so a
   * media write is a change to the parent. Without the
   * `sync_seq_bump_media_parent` trigger the parent's syncSeq never moved, and a
   * replica kept a deleted photo on screen forever.
   */
  async function hallAt(manager, since) {
    const { changed } = await drain('hall', { token: manager.accessToken, since })
    return changed.find((row) => row.id === manager.hallId)
  }
  const cursorOf = async (collection, manager) => (await drain(collection, { token: manager.accessToken })).cursor

  test('adding a Hall photo republishes the Hall carrying it', async () => {
    const manager = await managerWithApprovedHotel()
    const mark = await cursorOf('hall', manager)

    const media = await prisma.hallMedia.create({
      data: { hallId: manager.hallId, type: 'PHOTO', storagePath: `halls/${manager.hallId}/new.jpg` },
    })

    const hall = await hallAt(manager, mark)
    assert.ok(hall, 'a new photo must republish its Hall')
    assert.deepEqual(hall.photos.map((p) => p.id), [media.id])
  })

  test('deleting a Hall photo through the real service republishes the Hall without it', async () => {
    const manager = await managerWithApprovedHotel()
    const media = await prisma.hallMedia.create({
      data: { hallId: manager.hallId, type: 'PHOTO', storagePath: `halls/${manager.hallId}/gone.jpg` },
    })
    const mark = await cursorOf('hall', manager)

    const hallRecord = await prisma.hall.findUnique({ where: { id: manager.hallId } })
    await hallMediaService.deleteMedia(hallRecord, media.id)

    const hall = await hallAt(manager, mark)
    assert.ok(hall, 'a deleted photo must republish its Hall, or the replica shows it forever')
    assert.deepEqual(hall.photos, [])
  })

  test('adding and deleting a Hotel photo republishes the Hotel', async () => {
    const manager = await managerWithApprovedHotel()
    const hotelSync = (since) => drain('hotel', { token: manager.accessToken, since })
    const mark = await cursorOf('hotel', manager)

    const media = await prisma.hotelMedia.create({
      data: { hotelId: manager.hotelId, type: 'PHOTO', storagePath: `hotels/${manager.hotelId}/h.jpg` },
    })
    const addedBatch = await hotelSync(mark)
    const added = addedBatch.changed.find((r) => r.id === manager.hotelId)
    assert.ok(added, 'a new Hotel photo must republish the Hotel')
    assert.deepEqual(added.photos.map((p) => p.id), [media.id])

    await prisma.hotelMedia.update({ where: { id: media.id }, data: { deletedAt: new Date() } })
    const removed = (await hotelSync(addedBatch.cursor)).changed.find((r) => r.id === manager.hotelId)
    assert.ok(removed, 'a deleted Hotel photo must republish the Hotel')
    assert.deepEqual(removed.photos, [])
  })

  test('a bump that changes nothing but sync_seq does not cascade to the parent', async () => {
    // `touchSyncDependents` bumps every media row after bumping the parents
    // itself. Cascading from each of those would re-bump the parent once per
    // photo, for nothing.
    const manager = await managerWithApprovedHotel()
    const media = await prisma.hallMedia.create({
      data: { hallId: manager.hallId, type: 'PHOTO', storagePath: `halls/${manager.hallId}/still.jpg` },
    })
    const before = (await prisma.hall.findUnique({ where: { id: manager.hallId } })).syncSeq

    await prisma.$executeRaw`UPDATE hall_media SET sync_seq = nextval('sync_seq') WHERE id = ${media.id}::uuid`

    const after = (await prisma.hall.findUnique({ where: { id: manager.hallId } })).syncSeq
    assert.equal(after, before)
  })

  test('a cascading hard delete of the parent still succeeds', async () => {
    // The DELETE branch updates a parent that the same cascade is removing.
    // It must match no row rather than fail the delete.
    const manager = await managerWithApprovedHotel()
    const spare = await hallService.createHall({
      hotelId: manager.hotelId,
      profileData: { name: 'Cascade Hall', capacity: 10 },
    })
    await prisma.hallMedia.create({
      data: { hallId: spare.id, type: 'PHOTO', storagePath: `halls/${spare.id}/c.jpg` },
    })

    await prisma.hall.delete({ where: { id: spare.id } })
    assert.equal(await prisma.hallMedia.count({ where: { hallId: spare.id } }), 0)
  })

  test('a synced Hotel carries no registeredBy, so no mobileNumber reaches the device', async () => {
    const manager = await managerWithApprovedHotel()
    const res = await sync('hotel', { token: manager.accessToken, limit: 100 })
    const hotel = res.body.data.changed.find((r) => r.id === manager.hotelId)
    assert.ok(hotel)
    assert.equal(hotel.registeredBy, undefined)
    assert.ok(!JSON.stringify(hotel).includes(manager.user.mobileNumber))
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
