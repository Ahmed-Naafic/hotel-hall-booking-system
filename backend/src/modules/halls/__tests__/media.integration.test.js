import { randomUUID } from 'node:crypto'
import { test, describe, before, after, beforeEach } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import { storageProvider } from '../../../shared/providers/storageProvider.js'
import * as mediaRepository from '../media.repository.js'
import * as mediaService from '../media.service.js'

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
  const text = await res.text()
  return { status: res.status, body: text ? JSON.parse(text) : undefined }
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
  // BDR-019: Full Name is required at registration for a HOTEL_MANAGER account.
  await post('/api/v1/auth/register', { mobileNumber, password, accountType: 'HOTEL_MANAGER', fullName: 'Test Manager' })
  // Login answers with a texted code instead of a session now; the suite
  // pins that code in scripts/testEnv.js.
  await post('/api/v1/auth/login', { mobileNumber, password })
  const loginRes = await post('/api/v1/auth/login/verify', { mobileNumber, code: '123456' })
  return loginRes.body.data
}

async function registerHotel(token) {
  const { body } = await post('/api/v1/hotels', {}, authHeader(token))
  return body.data.id
}

async function createHall(token, hotelId) {
  const { body } = await post(
    `/api/v1/hotels/${hotelId}/halls`,
    { profileData: { name: 'The Gallery', capacity: 80 } },
    authHeader(token),
  )
  return body.data.id
}

const JPEG_BYTES = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46])
const PNG_BYTES = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00])
const INVALID_BYTES = Buffer.from('this is not an image', 'utf-8')
const OVERSIZED_JPEG = Buffer.concat([JPEG_BYTES, Buffer.alloc(6 * 1024 * 1024)])

before(async () => {
  const app = createApp()
  server = app.listen(0)
  await new Promise((resolve) => server.once('listening', resolve))
  const { port } = server.address()
  baseUrl = `http://127.0.0.1:${port}`
})

beforeEach(() => {
  storageProvider.reset?.()
})

after(async () => {
  await new Promise((resolve) => server.close(resolve))
  await prisma.$disconnect()
})

describe('Hall Photo upload and retrieval', () => {
  test('uploads a Hall photo successfully', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)
    const hallId = await createHall(accessToken, hotelId)

    const res = await postFile(`/api/v1/hotels/${hotelId}/halls/${hallId}/media/photos`, {
      filename: 'hall.jpg',
      bytes: JPEG_BYTES,
      headers: authHeader(accessToken),
    })

    assert.equal(res.status, 201)
    assert.equal(res.body.message, 'Hall photo uploaded successfully.')
    assert.equal(res.body.data.hallId, hallId)
    assert.equal(res.body.data.type, 'PHOTO')
    assert.match(res.body.data.url, new RegExp(`halls/${hallId}/photos/${res.body.data.id}\\.jpg`))
  })

  test('retrieves Hall photos in the expected response shape', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)
    const hallId = await createHall(accessToken, hotelId)

    await postFile(`/api/v1/hotels/${hotelId}/halls/${hallId}/media/photos`, {
      filename: 'a.jpg',
      bytes: JPEG_BYTES,
      headers: authHeader(accessToken),
    })
    await postFile(`/api/v1/hotels/${hotelId}/halls/${hallId}/media/photos`, {
      filename: 'b.png',
      bytes: PNG_BYTES,
      headers: authHeader(accessToken),
    })

    const res = await get(`/api/v1/hotels/${hotelId}/halls/${hallId}/media`, authHeader(accessToken))

    assert.equal(res.status, 200)
    assert.deepEqual(Object.keys(res.body.data), ['photos'])
    assert.equal(res.body.data.photos.length, 2)
    assert.ok(!('logo' in res.body.data))
  })
})

describe('Hall Media ownership and tenant isolation', () => {
  test('uses existing Hall ownership checks: a Hall from another Hotel returns 404', async () => {
    const ownerA = await registerAndLoginHotelManager()
    const hotelIdA = await registerHotel(ownerA.accessToken)
    const ownerB = await registerAndLoginHotelManager()
    const hotelIdB = await registerHotel(ownerB.accessToken)
    const hallIdB = await createHall(ownerB.accessToken, hotelIdB)

    const res = await postFile(`/api/v1/hotels/${hotelIdA}/halls/${hallIdB}/media/photos`, {
      filename: 'wrong-hotel.jpg',
      bytes: JPEG_BYTES,
      headers: authHeader(ownerA.accessToken),
    })

    assert.equal(res.status, 404)
  })

  test('a different Hotel Manager cannot upload, retrieve, or delete Hall media', async () => {
    const owner = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(owner.accessToken)
    const hallId = await createHall(owner.accessToken, hotelId)
    const uploaded = await postFile(`/api/v1/hotels/${hotelId}/halls/${hallId}/media/photos`, {
      filename: 'hall.jpg',
      bytes: JPEG_BYTES,
      headers: authHeader(owner.accessToken),
    })
    const other = await registerAndLoginHotelManager()

    const uploadRes = await postFile(`/api/v1/hotels/${hotelId}/halls/${hallId}/media/photos`, {
      filename: 'cross-tenant.jpg',
      bytes: JPEG_BYTES,
      headers: authHeader(other.accessToken),
    })
    const getRes = await get(`/api/v1/hotels/${hotelId}/halls/${hallId}/media`, authHeader(other.accessToken))
    const deleteRes = await del(
      `/api/v1/hotels/${hotelId}/halls/${hallId}/media/${uploaded.body.data.id}`,
      authHeader(other.accessToken),
    )

    assert.equal(uploadRes.status, 404)
    assert.equal(getRes.status, 404)
    assert.equal(deleteRes.status, 404)
    assert.notEqual(await mediaRepository.findById(uploaded.body.data.id), null)
  })
})

describe('Hall Media validation and failures', () => {
  test('rejects an unsupported file before storage is called', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)
    const hallId = await createHall(accessToken, hotelId)
    const objectCountBefore = storageProvider.objects?.size ?? 0

    const res = await postFile(`/api/v1/hotels/${hotelId}/halls/${hallId}/media/photos`, {
      filename: 'not-an-image.txt',
      bytes: INVALID_BYTES,
      headers: authHeader(accessToken),
    })

    assert.equal(res.status, 400)
    assert.equal(res.body.error, 'VALIDATION_ERROR')
    assert.equal(storageProvider.objects?.size ?? 0, objectCountBefore)
  })

  test('rejects an oversized file before storage is called', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)
    const hallId = await createHall(accessToken, hotelId)
    const objectCountBefore = storageProvider.objects?.size ?? 0

    const res = await postFile(`/api/v1/hotels/${hotelId}/halls/${hallId}/media/photos`, {
      filename: 'huge.jpg',
      bytes: OVERSIZED_JPEG,
      headers: authHeader(accessToken),
    })

    assert.equal(res.status, 400)
    assert.equal(res.body.error, 'VALIDATION_ERROR')
    assert.equal(storageProvider.objects?.size ?? 0, objectCountBefore)
  })

  test('a storage upload failure never creates a Hall Media metadata record', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)
    const hallId = await createHall(accessToken, hotelId)
    storageProvider.failNextUpload()

    const res = await postFile(`/api/v1/hotels/${hotelId}/halls/${hallId}/media/photos`, {
      filename: 'hall.jpg',
      bytes: JPEG_BYTES,
      headers: authHeader(accessToken),
    })

    assert.equal(res.status, 500)
    const { body: mediaBody } = await get(`/api/v1/hotels/${hotelId}/halls/${hallId}/media`, authHeader(accessToken))
    assert.equal(mediaBody.data.photos.length, 0)
  })

  test('a metadata persistence failure cleans up the just-uploaded storage object', async () => {
    const fakeHall = { id: randomUUID(), hotelId: randomUUID() }
    const objectCountBefore = storageProvider.objects.size

    await assert.rejects(() => mediaService.uploadPhoto(fakeHall, { buffer: JPEG_BYTES, mimeType: 'image/jpeg' }))

    const created = await mediaRepository.findPhotosForHall(fakeHall.id)
    assert.equal(created.length, 0)
    assert.equal(storageProvider.objects.size, objectCountBefore)
  })
})

describe('Hall Media deletion', () => {
  test('deletes a Hall photo and removes it from retrieval', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)
    const hallId = await createHall(accessToken, hotelId)
    const uploaded = await postFile(`/api/v1/hotels/${hotelId}/halls/${hallId}/media/photos`, {
      filename: 'hall.jpg',
      bytes: JPEG_BYTES,
      headers: authHeader(accessToken),
    })
    const storedPath = [...storageProvider.objects.keys()].find((path) => path.includes(uploaded.body.data.id))

    const res = await del(`/api/v1/hotels/${hotelId}/halls/${hallId}/media/${uploaded.body.data.id}`, authHeader(accessToken))

    assert.equal(res.status, 204)
    assert.equal(storageProvider.objects.has(storedPath), false)
    const { body: mediaBody } = await get(`/api/v1/hotels/${hotelId}/halls/${hallId}/media`, authHeader(accessToken))
    assert.equal(mediaBody.data.photos.length, 0)
  })

  test('deleting a nonexistent Hall media id returns 404', async () => {
    const { accessToken } = await registerAndLoginHotelManager()
    const hotelId = await registerHotel(accessToken)
    const hallId = await createHall(accessToken, hotelId)

    const res = await del(`/api/v1/hotels/${hotelId}/halls/${hallId}/media/00000000-0000-0000-0000-000000000000`, authHeader(accessToken))

    assert.equal(res.status, 404)
  })
})
