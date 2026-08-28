import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { errorHandler } from '../errorHandler.js'
import { NotFoundError, ValidationError } from '../../errors/errorTypes.js'

/**
 * Covers a genuine defect found while diagnosing a reported intermittent
 * 500 on `POST /auth/login`: malformed JSON in the request body (a client
 * mistake) was being reported as a 500 Internal Server Error instead of a
 * 400, because express.json()'s SyntaxError isn't an AppError instance and
 * fell through the generic "unhandled" branch.
 */

function fakeReqRes() {
  const req = { requestId: 'r1', originalUrl: '/api/v1/test', method: 'POST' }
  const res = {
    statusCode: null,
    body: null,
    status(code) {
      this.statusCode = code
      return this
    },
    json(payload) {
      this.body = payload
      return this
    },
  }
  return { req, res }
}

describe('errorHandler — pure classification logic (unit)', () => {
  test('a body-parser JSON SyntaxError (entity.parse.failed) becomes 400 VALIDATION_ERROR, not 500', () => {
    const { req, res } = fakeReqRes()
    const err = new SyntaxError('Unexpected end of JSON input')
    err.status = 400
    err.type = 'entity.parse.failed'

    errorHandler(err, req, res, () => {})

    assert.equal(res.statusCode, 400)
    assert.equal(res.body.error, 'VALIDATION_ERROR')
  })

  test('an AppError (e.g. NotFoundError) keeps its own status/errorCode, unaffected by the parse-error fix', () => {
    const { req, res } = fakeReqRes()
    errorHandler(new NotFoundError('Hall not found.'), req, res, () => {})

    assert.equal(res.statusCode, 404)
    assert.equal(res.body.error, 'NOT_FOUND')
  })

  test('a ValidationError (AppError) is unaffected by the parse-error fix', () => {
    const { req, res } = fakeReqRes()
    errorHandler(new ValidationError('Bad input.', [{ field: 'x', message: 'x is required.' }]), req, res, () => {})

    assert.equal(res.statusCode, 400)
    assert.equal(res.body.error, 'VALIDATION_ERROR')
    assert.deepEqual(res.body.details, [{ field: 'x', message: 'x is required.' }])
  })

  test('a genuinely unexpected error (not AppError, not a parse failure) still returns 500 — this fix does not mask real server faults', () => {
    const { req, res } = fakeReqRes()
    errorHandler(new TypeError('Cannot read properties of undefined'), req, res, () => {})

    assert.equal(res.statusCode, 500)
    assert.equal(res.body.error, 'INTERNAL_SERVER_ERROR')
  })
})

describe('errorHandler — malformed request body over real HTTP (api-standards.md §8/§9)', () => {
  let server
  let baseUrl

  before(async () => {
    const app = createApp()
    server = app.listen(0)
    await new Promise((resolve) => server.once('listening', resolve))
    const { port } = server.address()
    baseUrl = `http://127.0.0.1:${port}`
  })

  after(async () => {
    await new Promise((resolve) => server.close(resolve))
  })

  test('malformed JSON in the request body returns 400 VALIDATION_ERROR, never 500', async () => {
    const res = await fetch(`${baseUrl}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      // Deliberately truncated/invalid JSON — the exact class of failure
      // a mangled request body (e.g. from a fragile client-side quoting
      // bug) produces.
      body: '{"mobileNumber":"+15551234567","password":"password123"',
    })
    const body = await res.json()

    assert.equal(res.status, 400)
    assert.equal(body.error, 'VALIDATION_ERROR')
    assert.equal(body.status, 'error')
    assert.ok(body.requestId)
  })
})
