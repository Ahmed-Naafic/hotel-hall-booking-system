import * as identityService from './identity.service.js'
import * as credentialService from './credential.service.js'
import * as tokenService from './token.service.js'
import * as sessionService from './session.service.js'
import * as authorizationService from './authorization.service.js'
import { AuthenticationError, BusinessRuleError } from '../../shared/errors/errorTypes.js'

/**
 * Authentication Component (Technical Design §4, §7) — orchestrates the
 * other components for each user-facing flow. Owns no storage of its own;
 * every read/write goes through the component that owns it.
 */

/** Registration (C2, H1, BR-AUTH-02) — creates the User Account. Mobile-number verification (C3) is a later increment. */
export async function register({ mobileNumber, password, accountType }) {
  const passwordHash = await credentialService.hashPassword(password)
  return identityService.registerIdentity({ mobileNumber, passwordHash, accountType })
}

/** Login (C4, H7, A1, Technical Design §7.1). */
export async function login({ mobileNumber, password }) {
  const user = await identityService.findIdentityByMobileNumber(mobileNumber)
  if (!user) {
    // Same message as a wrong password — never reveals whether the identifier exists (BR-AUTH-09).
    throw new AuthenticationError('Invalid credentials.')
  }

  const isCorrectPassword = await credentialService.verifyPassword(password, user.passwordHash)
  if (!isCorrectPassword) {
    // Same message as an unknown identifier — never reveals which failed (BR-AUTH-09).
    throw new AuthenticationError('Invalid credentials.')
  }

  if (!user.isActive) {
    // BR-AUTH-06: distinct message from "invalid credentials" once we know the account exists.
    throw new AuthenticationError('This account is inactive.')
  }

  const { session, rawRefreshToken } = await sessionService.startSession(user.id)
  const roleClaim = authorizationService.resolveRoleClaim(user)
  const accessToken = tokenService.issueAccessToken({
    userId: user.id,
    accountType: roleClaim,
    sessionId: session.id,
  })

  return { accessToken, refreshToken: rawRefreshToken, user }
}

/**
 * Logout (C5, A2, BR-AUTH-13) — ends the session identified by the
 * authenticated access token's `sid` claim (Technical Design §10: no
 * second parameter needed beyond the access token itself).
 */
export function logout(sessionId) {
  return sessionService.endSession(sessionId)
}

/** Token refresh (Technical Design §7.3) — rotates the refresh token and issues a new access token. */
export async function refresh(rawRefreshToken) {
  const session = await sessionService.validateRefreshToken(rawRefreshToken)
  const user = await identityService.findIdentityById(session.userId)

  if (!user || !user.isActive) {
    throw new AuthenticationError('Invalid or expired session.')
  }

  const { session: rotatedSession, rawRefreshToken: newRawRefreshToken } =
    await sessionService.rotateSession(session.id)
  const roleClaim = authorizationService.resolveRoleClaim(user)
  const accessToken = tokenService.issueAccessToken({
    userId: user.id,
    accountType: roleClaim,
    sessionId: rotatedSession.id,
  })

  return { accessToken, refreshToken: newRawRefreshToken }
}

/** Account summary (C8, Technical Design §10) — the authenticated identity's own record. */
export async function getCurrentUser(userId) {
  const user = await identityService.findIdentityById(userId)
  if (!user) {
    throw new AuthenticationError('Invalid or expired session.')
  }
  return user
}

/** Password change (C7, A3, BR-AUTH-08) — while authenticated, confirming the current password. */
export async function changePassword(userId, { currentPassword, newPassword }) {
  const user = await identityService.findIdentityById(userId)
  if (!user) {
    throw new AuthenticationError('Invalid or expired session.')
  }

  const isCorrectPassword = await credentialService.verifyPassword(currentPassword, user.passwordHash)
  if (!isCorrectPassword) {
    // 422, not 401: the caller is already authenticated — this is a
    // business-rule failure (Technical Design §10), not an auth failure.
    throw new BusinessRuleError('The current password is incorrect.')
  }

  const passwordHash = await credentialService.hashPassword(newPassword)
  await identityService.changePasswordHash(userId, passwordHash)

  // Same defensible security default as password reset — see
  // passwordReset.service.js's confirmPasswordReset() for the caveat this
  // does NOT cover (an already-issued access token remains valid until its
  // own expiry; only future refreshes are blocked).
  await sessionService.endAllSessionsForUser(userId)
}
