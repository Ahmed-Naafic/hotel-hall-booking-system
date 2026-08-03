import jwt from 'jsonwebtoken'
import { randomBytes, createHash } from 'node:crypto'
import { env } from '../../config/env.js'
import { AuthenticationError } from '../../shared/errors/errorTypes.js'

/**
 * Token Component (Technical Design §4, §7.3, §11) — the only component
 * that constructs or parses a JWT. Access tokens and refresh tokens are
 * treated as distinct security boundaries (architecture-principles.md §7):
 * the access token is a short-lived, stateless JWT; the refresh token is an
 * opaque, high-entropy secret whose hash (never the raw value) is what
 * persists (Session Component owns that persistence, not this component).
 */

const ACCESS_TOKEN_TTL_SECONDS = env.auth.accessTokenTtlMinutes * 60
const REFRESH_TOKEN_TTL_SECONDS = env.auth.refreshTokenTtlDays * 24 * 60 * 60

/**
 * Issues a short-lived access token carrying the identity and role claim
 * (BR-AUTH-14), plus the owning Session's id (`sid`) — this is what lets
 * logout (Technical Design §10: "Request — none beyond the current access
 * token") resolve which Session to end without a second parameter, even
 * though the access token itself is a stateless JWT with no other link to
 * a specific Session row.
 */
export function issueAccessToken({ userId, accountType, sessionId }) {
  return jwt.sign({ sub: userId, accountType, sid: sessionId }, env.auth.jwtSecret, {
    expiresIn: ACCESS_TOKEN_TTL_SECONDS,
  })
}

/** Verifies an access token; throws AuthenticationError on any failure (BR-AUTH-11). */
export function verifyAccessToken(token) {
  try {
    return jwt.verify(token, env.auth.jwtSecret)
  } catch {
    throw new AuthenticationError('Invalid or expired session.')
  }
}

/** Generates a new opaque refresh token (raw value — only ever returned to the client once). */
export function generateRefreshToken() {
  return randomBytes(64).toString('hex')
}

/** Hashes a refresh token for storage/lookup — never the raw value at rest (data-architecture.md §13). */
export function hashRefreshToken(rawToken) {
  return createHash('sha256').update(rawToken).digest('hex')
}

export function refreshTokenExpiryDate(from = new Date()) {
  return new Date(from.getTime() + REFRESH_TOKEN_TTL_SECONDS * 1000)
}
