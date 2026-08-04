import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import * as tokenService from '../token.service.js'
import { AuthenticationError } from '../../../shared/errors/errorTypes.js'

// Pure JWT/crypto — no database, no mocking needed (testing-standards.md §5).

describe('Token Component', () => {
  test('issues an access token carrying the identity, role claim, and session id', () => {
    const token = tokenService.issueAccessToken({
      userId: 'user-1',
      accountType: 'CUSTOMER',
      sessionId: 'session-1',
    })
    const payload = tokenService.verifyAccessToken(token)

    assert.equal(payload.sub, 'user-1')
    assert.equal(payload.accountType, 'CUSTOMER')
    assert.equal(payload.sid, 'session-1')
  })

  test('rejects a malformed access token with AuthenticationError (BR-AUTH-11)', () => {
    assert.throws(() => tokenService.verifyAccessToken('not-a-real-token'), AuthenticationError)
  })

  test('rejects an access token signed with a different secret', () => {
    // Simulates a token that was never issued by this server.
    const jwt = tokenService.issueAccessToken({ userId: 'x', accountType: 'CUSTOMER', sessionId: 's' })
    const tampered = jwt.slice(0, -4) + 'abcd'
    assert.throws(() => tokenService.verifyAccessToken(tampered), AuthenticationError)
  })

  test('generates unique, high-entropy refresh tokens', () => {
    const a = tokenService.generateRefreshToken()
    const b = tokenService.generateRefreshToken()
    assert.notEqual(a, b)
    assert.equal(a.length, 128) // 64 bytes, hex-encoded
  })

  test('hashes a refresh token deterministically (same input, same hash)', () => {
    const raw = tokenService.generateRefreshToken()
    assert.equal(tokenService.hashRefreshToken(raw), tokenService.hashRefreshToken(raw))
  })

  test('hashRefreshToken never returns the raw value', () => {
    const raw = tokenService.generateRefreshToken()
    assert.notEqual(tokenService.hashRefreshToken(raw), raw)
  })

  test('refresh token expiry is in the future', () => {
    const expiry = tokenService.refreshTokenExpiryDate()
    assert.ok(expiry.getTime() > Date.now())
  })
})
