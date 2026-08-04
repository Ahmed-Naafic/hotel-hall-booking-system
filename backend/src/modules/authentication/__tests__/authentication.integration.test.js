import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import { createApp } from '../../../app.js'
import { prisma } from '../../../shared/prismaClient.js'
import { smsProvider } from '../../../shared/providers/smsProvider.js'

/**
 * Integration tests (testing-standards.md §6) — real Prisma queries against
 * a real test database, real JWT verification through the Access Gate, not
 * a mocked auth layer. Covers the full C4/C5/H7/A1/A2 journeys plus the
 * exception scenarios from business-specification.md §8.
 */

let server
let baseUrl

function uniqueMobileNumber() {
  // 9 random digits after the country code — avoids cross-test collisions
  // without depending on leftover state from a previous run.
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

async function patch(path, body, headers = {}) {
  const res = await fetch(`${baseUrl}${path}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', ...headers },
    body: body === undefined ? undefined : JSON.stringify(body),
  })
  const text = await res.text()
  return { status: res.status, body: text ? JSON.parse(text) : undefined }
}

// This test suite runs with no Twilio credentials configured, so
// `smsProvider` (shared/providers/smsProvider.js) is MockSmsProvider —
// itself the thing this increment's abstraction requirement verifies
// (tests never depend on a real SMS channel, testing-standards.md §6).
function codeSentTo(mobileNumber) {
  const message = smsProvider.getLastMessageTo(mobileNumber)
  assert.ok(message, `expected a message to have been sent to ${mobileNumber}`)
  const match = message.body.match(/\d{6}/)
  assert.ok(match, `expected a 6-digit code in the message body: ${message.body}`)
  return match[0]
}

async function registerAndLogin(overrides = {}) {
  const mobileNumber = uniqueMobileNumber()
  const password = 'correct-horse-battery-staple'
  await post('/api/v1/auth/register', {
    mobileNumber,
    password,
    accountType: 'CUSTOMER',
    ...overrides,
  })
  const loginRes = await post('/api/v1/auth/login', { mobileNumber, password })
  return { mobileNumber, password, ...loginRes.body.data }
}

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

describe('Authentication — registration (C2, H1, BR-AUTH-02)', () => {
  test('registers a new Customer account', async () => {
    const mobileNumber = uniqueMobileNumber()
    const { status, body } = await post('/api/v1/auth/register', {
      mobileNumber,
      password: 'correct-horse-battery-staple',
      accountType: 'CUSTOMER',
    })

    assert.equal(status, 201)
    assert.equal(body.status, 'success')
    assert.equal(body.data.mobileNumber, mobileNumber)
    assert.equal(body.data.accountType, 'CUSTOMER')
    assert.equal(body.data.isVerified, false)
    assert.equal(body.data.passwordHash, undefined, 'password hash must never appear in a response')
  })

  test('rejects a duplicate mobile number with 422 (business rule, not request shape)', async () => {
    const mobileNumber = uniqueMobileNumber()
    const payload = { mobileNumber, password: 'correct-horse-battery-staple', accountType: 'CUSTOMER' }
    await post('/api/v1/auth/register', payload)

    const { status, body } = await post('/api/v1/auth/register', payload)
    assert.equal(status, 422)
    assert.equal(body.error, 'BUSINESS_RULE_VIOLATION')
  })

  test('rejects Staff and Platform Administrator self-registration with 400 (Business Specification §3)', async () => {
    const { status, body } = await post('/api/v1/auth/register', {
      mobileNumber: uniqueMobileNumber(),
      password: 'correct-horse-battery-staple',
      accountType: 'STAFF',
    })
    assert.equal(status, 400)
    assert.equal(body.error, 'VALIDATION_ERROR')
  })

  test('rejects a malformed request with 400', async () => {
    const { status, body } = await post('/api/v1/auth/register', { mobileNumber: '' })
    assert.equal(status, 400)
    assert.equal(body.error, 'VALIDATION_ERROR')
  })
})

describe('Authentication — login (C4, H7, A1)', () => {
  test('logs in with correct credentials and receives access + refresh tokens', async () => {
    const mobileNumber = uniqueMobileNumber()
    const password = 'correct-horse-battery-staple'
    await post('/api/v1/auth/register', { mobileNumber, password, accountType: 'CUSTOMER' })

    const { status, body } = await post('/api/v1/auth/login', { mobileNumber, password })

    assert.equal(status, 200)
    assert.ok(body.data.accessToken)
    assert.ok(body.data.refreshToken)
    assert.equal(body.data.user.mobileNumber, mobileNumber)
  })

  test('rejects an unregistered mobile number the same way as a wrong password (BR-AUTH-09, no enumeration)', async () => {
    const unknown = await post('/api/v1/auth/login', {
      mobileNumber: uniqueMobileNumber(),
      password: 'whatever-password',
    })

    const mobileNumber = uniqueMobileNumber()
    await post('/api/v1/auth/register', {
      mobileNumber,
      password: 'correct-horse-battery-staple',
      accountType: 'CUSTOMER',
    })
    const wrongPassword = await post('/api/v1/auth/login', { mobileNumber, password: 'wrong-password' })

    assert.equal(unknown.status, 401)
    assert.equal(wrongPassword.status, 401)
    assert.equal(unknown.body.message, wrongPassword.body.message)
  })

  test('blocks login on a deactivated account with a distinct message (BR-AUTH-06)', async () => {
    const mobileNumber = uniqueMobileNumber()
    const password = 'correct-horse-battery-staple'
    const registerRes = await post('/api/v1/auth/register', {
      mobileNumber,
      password,
      accountType: 'CUSTOMER',
    })
    await prisma.user.update({
      where: { id: registerRes.body.data.id },
      data: { isActive: false },
    })

    const { status, body } = await post('/api/v1/auth/login', { mobileNumber, password })
    assert.equal(status, 401)
    assert.match(body.message, /inactive/i)
  })
})

describe('Authentication — Access Gate (BR-AUTH-14, architecture-principles.md §7)', () => {
  test('blocks a protected endpoint with no token', async () => {
    const { status } = await post('/api/v1/auth/logout', undefined)
    assert.equal(status, 401)
  })

  test('blocks a protected endpoint with a garbage token', async () => {
    const { status } = await post('/api/v1/auth/logout', undefined, {
      Authorization: 'Bearer not-a-real-token',
    })
    assert.equal(status, 401)
  })

  test('allows a protected endpoint with a valid access token', async () => {
    const { accessToken } = await registerAndLogin()
    const { status } = await post('/api/v1/auth/logout', undefined, {
      Authorization: `Bearer ${accessToken}`,
    })
    assert.equal(status, 204)
  })
})

describe('Authentication — logout (C5, A2, BR-AUTH-13)', () => {
  test('ends the session so its refresh token no longer works', async () => {
    const { accessToken, refreshToken } = await registerAndLogin()

    const logoutRes = await post('/api/v1/auth/logout', undefined, {
      Authorization: `Bearer ${accessToken}`,
    })
    assert.equal(logoutRes.status, 204)

    const refreshRes = await post('/api/v1/auth/refresh', { refreshToken })
    assert.equal(refreshRes.status, 401)
  })
})

describe('Authentication — token refresh (Technical Design §7.3)', () => {
  test('issues a new access + refresh token pair', async () => {
    const { refreshToken } = await registerAndLogin()

    const { status, body } = await post('/api/v1/auth/refresh', { refreshToken })
    assert.equal(status, 200)
    assert.ok(body.data.accessToken)
    assert.ok(body.data.refreshToken)
    assert.notEqual(body.data.refreshToken, refreshToken)
  })

  test('rotation invalidates the previous refresh token (single use)', async () => {
    const { refreshToken } = await registerAndLogin()

    const first = await post('/api/v1/auth/refresh', { refreshToken })
    assert.equal(first.status, 200)

    const reuse = await post('/api/v1/auth/refresh', { refreshToken })
    assert.equal(reuse.status, 401)
  })

  test('rejects an unknown refresh token with 401, not a distinct error type (BR-AUTH-11)', async () => {
    const { status } = await post('/api/v1/auth/refresh', { refreshToken: 'a'.repeat(128) })
    assert.equal(status, 401)
  })
})

describe('Authentication — account summary (C8)', () => {
  test('returns the caller\'s own account when authenticated', async () => {
    const { accessToken, mobileNumber } = await registerAndLogin()

    const { status, body } = await get('/api/v1/auth/me', {
      Authorization: `Bearer ${accessToken}`,
    })

    assert.equal(status, 200)
    assert.equal(body.data.mobileNumber, mobileNumber)
    assert.equal(body.data.passwordHash, undefined, 'password hash must never appear in a response')
  })

  test('blocks the endpoint with no access token', async () => {
    const { status } = await get('/api/v1/auth/me')
    assert.equal(status, 401)
  })
})

describe('Authentication — identity verification (C3, BR-AUTH-02)', () => {
  test('full flow: request, receive via MockSmsProvider, confirm', async () => {
    const { accessToken, mobileNumber } = await registerAndLogin()

    const requestRes = await post('/api/v1/auth/verifications', undefined, {
      Authorization: `Bearer ${accessToken}`,
    })
    assert.equal(requestRes.status, 200)

    const code = codeSentTo(mobileNumber)

    const confirmRes = await post(
      '/api/v1/auth/verifications/confirm',
      { code },
      { Authorization: `Bearer ${accessToken}` },
    )
    assert.equal(confirmRes.status, 200)
    assert.equal(confirmRes.body.data.isVerified, true)
  })

  test('rejects an incorrect code with 422', async () => {
    const { accessToken } = await registerAndLogin()
    await post('/api/v1/auth/verifications', undefined, { Authorization: `Bearer ${accessToken}` })

    const { status, body } = await post(
      '/api/v1/auth/verifications/confirm',
      { code: '000000' },
      { Authorization: `Bearer ${accessToken}` },
    )
    assert.equal(status, 422)
    assert.equal(body.error, 'BUSINESS_RULE_VIOLATION')
  })

  test('a used code cannot be confirmed a second time', async () => {
    const { accessToken, mobileNumber } = await registerAndLogin()
    await post('/api/v1/auth/verifications', undefined, { Authorization: `Bearer ${accessToken}` })
    const code = codeSentTo(mobileNumber)
    await post('/api/v1/auth/verifications/confirm', { code }, { Authorization: `Bearer ${accessToken}` })

    const { status } = await post(
      '/api/v1/auth/verifications/confirm',
      { code },
      { Authorization: `Bearer ${accessToken}` },
    )
    assert.equal(status, 422)
  })

  test('rejects a second request while one is still active with 409', async () => {
    const { accessToken } = await registerAndLogin()
    await post('/api/v1/auth/verifications', undefined, { Authorization: `Bearer ${accessToken}` })

    const { status, body } = await post('/api/v1/auth/verifications', undefined, {
      Authorization: `Bearer ${accessToken}`,
    })
    assert.equal(status, 409)
    assert.equal(body.error, 'CONFLICT')
  })

  test('rejects a request for an already-verified account with 422', async () => {
    const { accessToken, mobileNumber } = await registerAndLogin()
    await post('/api/v1/auth/verifications', undefined, { Authorization: `Bearer ${accessToken}` })
    const code = codeSentTo(mobileNumber)
    await post('/api/v1/auth/verifications/confirm', { code }, { Authorization: `Bearer ${accessToken}` })

    const { status, body } = await post('/api/v1/auth/verifications', undefined, {
      Authorization: `Bearer ${accessToken}`,
    })
    assert.equal(status, 422)
    assert.equal(body.error, 'BUSINESS_RULE_VIOLATION')
  })

  test('blocks both endpoints with no access token', async () => {
    const requestRes = await post('/api/v1/auth/verifications', undefined)
    const confirmRes = await post('/api/v1/auth/verifications/confirm', { code: '123456' })
    assert.equal(requestRes.status, 401)
    assert.equal(confirmRes.status, 401)
  })
})

describe('Authentication — password reset (C6, BR-AUTH-09)', () => {
  test('full flow: request, receive via MockSmsProvider, confirm, log in with the new password', async () => {
    const { mobileNumber, password: oldPassword } = await registerAndLogin()

    const requestRes = await post('/api/v1/auth/password-resets', { mobileNumber })
    assert.equal(requestRes.status, 200)

    const code = codeSentTo(mobileNumber)
    const newPassword = 'new-correct-horse-battery'

    const confirmRes = await patch('/api/v1/auth/password-resets', { mobileNumber, code, newPassword })
    assert.equal(confirmRes.status, 200)

    const oldLogin = await post('/api/v1/auth/login', { mobileNumber, password: oldPassword })
    assert.equal(oldLogin.status, 401)

    const newLogin = await post('/api/v1/auth/login', { mobileNumber, password: newPassword })
    assert.equal(newLogin.status, 200)
  })

  test('never reveals whether the mobile number is registered', async () => {
    const unknownNumber = uniqueMobileNumber()
    const { status, body } = await post('/api/v1/auth/password-resets', { mobileNumber: unknownNumber })

    assert.equal(status, 200)
    assert.equal(smsProvider.getLastMessageTo(unknownNumber), undefined, 'no SMS for an unknown number')

    const { mobileNumber } = await registerAndLogin()
    const known = await post('/api/v1/auth/password-resets', { mobileNumber })
    assert.equal(known.status, 200)
    assert.equal(known.body.message, body.message, 'identical response either way')
  })

  test('rejects an incorrect code with 422', async () => {
    const { mobileNumber } = await registerAndLogin()
    await post('/api/v1/auth/password-resets', { mobileNumber })

    const { status } = await patch('/api/v1/auth/password-resets', {
      mobileNumber,
      code: '000000',
      newPassword: 'new-correct-horse-battery',
    })
    assert.equal(status, 422)
  })

  test('a new request supersedes the previous one (at most one active at a time, Technical Design §5.1)', async () => {
    const { mobileNumber } = await registerAndLogin()
    await post('/api/v1/auth/password-resets', { mobileNumber })
    const firstCode = codeSentTo(mobileNumber)

    await post('/api/v1/auth/password-resets', { mobileNumber })
    const secondCode = codeSentTo(mobileNumber)

    const confirmWithFirst = await patch('/api/v1/auth/password-resets', {
      mobileNumber,
      code: firstCode,
      newPassword: 'new-correct-horse-battery',
    })
    assert.equal(confirmWithFirst.status, 422, 'the superseded code must no longer work')

    if (firstCode !== secondCode) {
      const confirmWithSecond = await patch('/api/v1/auth/password-resets', {
        mobileNumber,
        code: secondCode,
        newPassword: 'new-correct-horse-battery',
      })
      assert.equal(confirmWithSecond.status, 200)
    }
  })

  test('ends existing sessions — the old refresh token no longer works after a reset', async () => {
    const { mobileNumber, refreshToken } = await registerAndLogin()
    await post('/api/v1/auth/password-resets', { mobileNumber })
    const code = codeSentTo(mobileNumber)
    await patch('/api/v1/auth/password-resets', {
      mobileNumber,
      code,
      newPassword: 'new-correct-horse-battery',
    })

    const refreshRes = await post('/api/v1/auth/refresh', { refreshToken })
    assert.equal(refreshRes.status, 401)
  })
})

describe('Authentication — password change (C7, A3, BR-AUTH-08)', () => {
  test('changes the password when the current password is correct', async () => {
    const { accessToken, mobileNumber } = await registerAndLogin()
    const newPassword = 'new-correct-horse-battery'

    const { status } = await patch(
      '/api/v1/auth/password',
      { currentPassword: 'correct-horse-battery-staple', newPassword },
      { Authorization: `Bearer ${accessToken}` },
    )
    assert.equal(status, 200)

    const loginRes = await post('/api/v1/auth/login', { mobileNumber, password: newPassword })
    assert.equal(loginRes.status, 200)
  })

  test('rejects an incorrect current password with 422', async () => {
    const { accessToken } = await registerAndLogin()

    const { status, body } = await patch(
      '/api/v1/auth/password',
      { currentPassword: 'wrong-password', newPassword: 'new-correct-horse-battery' },
      { Authorization: `Bearer ${accessToken}` },
    )
    assert.equal(status, 422)
    assert.equal(body.error, 'BUSINESS_RULE_VIOLATION')
  })

  test('ends existing sessions — the old refresh token no longer works after a change', async () => {
    const { accessToken, refreshToken } = await registerAndLogin()
    await patch(
      '/api/v1/auth/password',
      { currentPassword: 'correct-horse-battery-staple', newPassword: 'new-correct-horse-battery' },
      { Authorization: `Bearer ${accessToken}` },
    )

    const refreshRes = await post('/api/v1/auth/refresh', { refreshToken })
    assert.equal(refreshRes.status, 401)
  })

  test('blocks the endpoint with no access token', async () => {
    const { status } = await patch('/api/v1/auth/password', {
      currentPassword: 'a',
      newPassword: 'new-correct-horse-battery',
    })
    assert.equal(status, 401)
  })
})
