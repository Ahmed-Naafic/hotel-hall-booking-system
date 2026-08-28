import { randomUUID } from 'node:crypto'
import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import { storageProvider } from '../../../shared/providers/storageProvider.js'
import * as mediaRepository from '../media.repository.js'
import * as mediaService from '../media.service.js'

/**
 * Integration tests (testing-standards.md §6) for the Hotel Media API
 * (BDR-015, ADR-0006, Technical Design §8a/§11) — real Prisma queries and
 * real JWT verification, same pattern as `hotels.integration.test.js`.
 * Supabase itself is never a real dependency here — `storageProvider` is
 * `MockStorageProvider` by default (no `SUPABASE_URL`/
 * `SUPABASE_SERVICE_ROLE_KEY` configured in this test environment),
 * exactly per `shared/providers/storageProvider.js`'s own credential-
 * presence selection rule.
 */

let server
let baseUrl

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

async function del(path, headers = {}) {
  const res = await fetch(`${baseUrl}${path}`, { method: 'DELETE', headers })
  return { status: res.status }
}

async function postFile(path, { filename, bytes, headers = {} }) {
  const form = new FormData()
  form.append('file', new Blob([bytes]), filename)
  const res = await fetch(`${baseUrl}${path}`, { method: 'POST', headers, body: form })
  const text = await res.text()
  return { status: res.status, body: text ? JSON.parse(text) : undefined }
}

function authHeader(token) {
  return { Authorization: `Bearer ${token}` }
}

async function registerAndLoginHotelManager() {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  await post('/api/v1/auth/register', { mobileNumber, password, accountType: 'HOTEL_MANAGER' })
  const loginRes = await post('/api/v1/auth/login', { mobileNumber, password })
  return loginRes.body.data
}

async function registerHotel(token) {
  const { body } = await post('/api/v1/hotels', {}, authHeader(token))
  return body.data.id
}

// Minimal, valid magic-byte headers — the detector only inspects these
// leading bytes (media.validation.js#detectImageMimeType), so the
// remainder is arbitrary padding.
const JPEG_BYTES = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46])
const PNG_BYTES = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00])
const WEBP_BYTES = Buffer.concat([
  Buffer.from('RIFF', 'ascii'),
  Buffer.from([0x00, 0x00, 0x00, 0x00]),
  Buffer.from('WEBP', 'ascii'),
])
const INVALID_BYTES = Buffer.from('this is not an image', 'utf-8')
const OVERSIZED_JPEG = Buffer.concat([JPEG_BYTES, Buffer.alloc(6 * 1024 * 1024)])

before(async () => {
  const app = createApp()
  server = app.listen(0)
  await new Promise((resolve) => server.once('listening', resolve))
  const { port } = server.address()
  baseUrl = `http://127.0.0.1:${port}`
})

after(async () => {
  await new Promise((resolve) => server.close(resolve))
  await prisma.$disconnect()
})

describe('Hotel Logo upload', () => {
  test('uploads a logo successfully', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)

    const res = await postFile(`/api/v1/hotels/${hotelId}/media/logo`, {
      filename: 'logo.jpg',
      bytes: JPEG_BYTES,
      headers: authHeader(accessToken),
    })

    assert.equal(res.status, 201)
    assert.equal(res.body.data.type, 'LOGO')
    assert.equal(res.body.data.hotelId, hotelId)
    assert.match(res.body.data.url, new RegExp(`hotels/${hotelId}/logo/`))
  })

  test('replacing the logo removes the previous one', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)

    const first = await postFile(`/api/v1/hotels/${hotelId}/media/logo`, {
      filename: 'logo1.png',
      bytes: PNG_BYTES,
      headers: authHeader(accessToken),
    })
    const second = await postFile(`/api/v1/hotels/${hotelId}/media/logo`, {
      filename: 'logo2.webp',
      bytes: WEBP_BYTES,
      headers: authHeader(accessToken),
    })

    assert.equal(second.status, 201)
    assert.notEqual(second.body.data.id, first.body.data.id)

    const oldRecord = await mediaRepository.findById(first.body.data.id)
    assert.equal(oldRecord, null)

    const { body: mediaBody } = await get(`/api/v1/hotels/${hotelId}/media`, authHeader(accessToken))
    assert.equal(mediaBody.data.logo.id, second.body.data.id)
  })
})

describe('Hotel Photo upload', () => {
  test('uploads a photo successfully, and multiple photos accumulate', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)

    const first = await postFile(`/api/v1/hotels/${hotelId}/media/photos`, {
      filename: 'a.jpg',
      bytes: JPEG_BYTES,
      headers: authHeader(accessToken),
    })
    const second = await postFile(`/api/v1/hotels/${hotelId}/media/photos`, {
      filename: 'b.png',
      bytes: PNG_BYTES,
      headers: authHeader(accessToken),
    })

    assert.equal(first.status, 201)
    assert.equal(first.body.data.type, 'PHOTO')
    assert.equal(second.status, 201)

    const { body: mediaBody } = await get(`/api/v1/hotels/${hotelId}/media`, authHeader(accessToken))
    assert.equal(mediaBody.data.photos.length, 2)
    assert.equal(mediaBody.data.logo, null)
  })
})

describe('File validation', () => {
  test('rejects an unsupported file type (400), never reaches storage', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)

    const res = await postFile(`/api/v1/hotels/${hotelId}/media/logo`, {
      filename: 'not-an-image.txt',
      bytes: INVALID_BYTES,
      headers: authHeader(accessToken),
    })

    assert.equal(res.status, 400);
    assert.equal(res.body.error, 'VALIDATION_ERROR')
  })

  test('rejects a missing file (400)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)

    const res = await fetch(`${baseUrl}/api/v1/hotels/${hotelId}/media/logo`, {
      method: 'POST',
      headers: authHeader(accessToken),
      body: new FormData(),
    })

    assert.equal(res.status, 400)
  })

  test('rejects an oversized file (400)', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)

    const res = await postFile(`/api/v1/hotels/${hotelId}/media/logo`, {
      filename: 'huge.jpg',
      bytes: OVERSIZED_JPEG,
      headers: authHeader(accessToken),
    })

    assert.equal(res.status, 400)
    assert.equal(res.body.error, 'VALIDATION_ERROR')
  })
})

describe('Ownership and cross-tenant access', () => {
  test('a Hotel Manager cannot upload media to another Hotel Manager\'s Hotel (404)', async () => {
    const ownerA = await registerAndLoginHotelManager()
    const hotelIdA = await registerHotel(ownerA.accessToken)
    const ownerB = await registerAndLoginHotelManager()

    const res = await postFile(`/api/v1/hotels/${hotelIdA}/media/logo`, {
      filename: 'logo.jpg',
      bytes: JPEG_BYTES,
      headers: authHeader(ownerB.accessToken),
    })

    assert.equal(res.status, 404)
  })

  test('a Hotel Manager cannot delete another Hotel Manager\'s media (404), and the media survives', async () => {
    const ownerA = await registerAndLoginHotelManager()
    const hotelIdA = await registerHotel(ownerA.accessToken)
    const uploaded = await postFile(`/api/v1/hotels/${hotelIdA}/media/logo`, {
      filename: 'logo.jpg',
      bytes: JPEG_BYTES,
      headers: authHeader(ownerA.accessToken),
    })
    const ownerB = await registerAndLoginHotelManager()

    const res = await del(`/api/v1/hotels/${hotelIdA}/media/${uploaded.body.data.id}`, authHeader(ownerB.accessToken))

    assert.equal(res.status, 404)
    const stillThere = await mediaRepository.findById(uploaded.body.data.id)
    assert.notEqual(stillThere, null)
  })

  test('a Hotel Manager cannot retrieve another Hotel Manager\'s media (404)', async () => {
    const ownerA = await registerAndLoginHotelManager()
    const hotelIdA = await registerHotel(ownerA.accessToken)
    const ownerB = await registerAndLoginHotelManager()

    const res = await get(`/api/v1/hotels/${hotelIdA}/media`, authHeader(ownerB.accessToken))

    assert.equal(res.status, 404)
  })
})

describe('Deletion', () => {
  test('deletes a photo (204), and it no longer appears in the media list', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)
    const uploaded = await postFile(`/api/v1/hotels/${hotelId}/media/photos`, {
      filename: 'a.jpg',
      bytes: JPEG_BYTES,
      headers: authHeader(accessToken),
    })

    const res = await del(`/api/v1/hotels/${hotelId}/media/${uploaded.body.data.id}`, authHeader(accessToken))

    assert.equal(res.status, 204)
    const { body: mediaBody } = await get(`/api/v1/hotels/${hotelId}/media`, authHeader(accessToken))
    assert.equal(mediaBody.data.photos.length, 0)
  })

  test('deleting a nonexistent media id returns 404', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)

    const res = await del(`/api/v1/hotels/${hotelId}/media/00000000-0000-0000-0000-000000000000`, authHeader(accessToken))

    assert.equal(res.status, 404)
  })
})

describe('Storage/persistence failure handling', () => {
  test('a storage upload failure never creates a Neon metadata record', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)
    storageProvider.failNextUpload()

    const res = await postFile(`/api/v1/hotels/${hotelId}/media/logo`, {
      filename: 'logo.jpg',
      bytes: JPEG_BYTES,
      headers: authHeader(accessToken),
    })

    assert.equal(res.status, 500)
    const { body: mediaBody } = await get(`/api/v1/hotels/${hotelId}/media`, authHeader(accessToken))
    assert.equal(mediaBody.data.logo, null)
  })

  test('a metadata (Neon) persistence failure cleans up the just-uploaded Supabase object', async () => {
    // Exercises media.service.js directly (bypassing HTTP/ownership),
    // the same "stub caller" pattern this file's own header comment
    // documents for paths that are hard to reach through the real API —
    // here, forcing a *genuine* Neon write failure via a foreign-key
    // violation (a Hotel id that was never actually persisted) is more
    // faithful than mocking Prisma, and sidesteps ES modules' immutable
    // named-export bindings, which make `mediaRepository.create` and
    // Prisma's own proxied model delegates both unmockable via
    // `node:test`'s `mock.method` without the (experimental,
    // flag-gated) `mock.module` API.
    const fakeHotel = { id: randomUUID(), registeredByUserId: randomUUID() }
    const objectCountBefore = storageProvider.objects.size

    await assert.rejects(() => mediaService.uploadLogo(fakeHotel, { buffer: JPEG_BYTES, mimeType: 'image/jpeg' }))

    const created = await mediaRepository.findLogoForHotel(fakeHotel.id)
    assert.equal(created, null, 'no Hotel Media record should exist for the never-persisted Hotel')
    assert.equal(storageProvider.objects.size, objectCountBefore, 'the uploaded Supabase object should have been cleaned up, leaving no net change')
  })
})
