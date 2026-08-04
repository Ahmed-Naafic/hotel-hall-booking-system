import * as sessionRepository from './session.repository.js'
import * as tokenService from './token.service.js'
import { AuthenticationError } from '../../shared/errors/errorTypes.js'

/**
 * Session Component (Technical Design §4, §9) — the logical session a
 * Token Component's tokens belong to; tracks validity and termination
 * independent of token format. Concurrent session behaviour is not yet
 * defined by an approved decision (Technical Design §9) — this component
 * does not limit concurrent sessions per User Account.
 */

export async function startSession(userId) {
  const rawRefreshToken = tokenService.generateRefreshToken()
  const refreshTokenHash = tokenService.hashRefreshToken(rawRefreshToken)
  const expiresAt = tokenService.refreshTokenExpiryDate()

  const session = await sessionRepository.create({ userId, refreshTokenHash, expiresAt })
  return { session, rawRefreshToken }
}

/**
 * Validates a presented raw refresh token and returns its Session.
 * BR-AUTH-11: any invalid, expired, or revoked refresh token is treated as
 * unauthenticated — never a distinct error type the caller special-cases.
 */
export async function validateRefreshToken(rawRefreshToken) {
  const refreshTokenHash = tokenService.hashRefreshToken(rawRefreshToken)
  const session = await sessionRepository.findByRefreshTokenHash(refreshTokenHash)

  if (!session || session.revokedAt || session.expiresAt < new Date()) {
    throw new AuthenticationError('Invalid or expired session.')
  }
  return session
}

/** Rotates the refresh token on every use (Technical Design §7.3, §11). */
export async function rotateSession(sessionId) {
  const rawRefreshToken = tokenService.generateRefreshToken()
  const refreshTokenHash = tokenService.hashRefreshToken(rawRefreshToken)
  const expiresAt = tokenService.refreshTokenExpiryDate()

  const session = await sessionRepository.rotate(sessionId, { refreshTokenHash, expiresAt })
  return { session, rawRefreshToken }
}

/** Explicit termination via logout (BR-AUTH-13). */
export function endSession(sessionId) {
  return sessionRepository.revoke(sessionId)
}

/** Terminates every Session belonging to a User Account (BR-AUTH-06, on deactivation). */
export function endAllSessionsForUser(userId) {
  return sessionRepository.revokeAllForUser(userId)
}
