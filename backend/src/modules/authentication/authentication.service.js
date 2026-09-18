import * as identityService from './identity.service.js'
import * as credentialService from './credential.service.js'
import * as tokenService from './token.service.js'
import * as sessionService from './session.service.js'
import * as authorizationService from './authorization.service.js'
import * as verificationService from './verification.service.js'
import * as customerService from '../customers/customer.service.js'
import { prisma } from '../../shared/prismaClient.js'
import { AuthenticationError, BusinessRuleError } from '../../shared/errors/errorTypes.js'

/**
 * Authentication Component (Technical Design §4, §7) — orchestrates the
 * other components for each user-facing flow. Owns no storage of its own;
 * every read/write goes through the component that owns it.
 */

/**
 * Registration (C2, H1, BR-AUTH-02/03) — creates the User Account.
 * Mobile-number verification (C3) is a later increment.
 *
 * A Customer registration also creates its CustomerProfile with the
 * required Full Name (BDR-018) in the same transaction — the identity
 * (this module's own concern) and the business profile (Customer
 * Management's concern, `identity.service.js`'s own doc comment) are two
 * writes, but one atomic registration: neither should exist without the
 * other having also succeeded. A Hotel Manager registration (BDR-019)
 * stores `fullName` directly on the same User row — a single write, no
 * transaction needed.
 */
export async function register({ mobileNumber, password, accountType, fullName }) {
  const passwordHash = await credentialService.hashPassword(password)
  if (accountType === 'CUSTOMER') {
    return prisma.$transaction(
      async (client) => {
        const user = await identityService.registerIdentity({ mobileNumber, passwordHash, accountType }, client)
        await customerService.createProfile(user.id, { fullName: fullName.trim() }, client)
        return user
      },
      // Registration is often the very first database call of a freshly
      // started process (a cold serverless Postgres connection can itself
      // take several seconds) — Prisma's 2s default `maxWait` to acquire a
      // connection is tighter than that, and would spuriously fail an
      // otherwise-healthy registration. A plain (non-transactional) query
      // has no such ceiling, which is why only this transactional path
      // needs it widened.
      { maxWait: 10000, timeout: 10000 },
    )
  }
  if (accountType === 'HOTEL_MANAGER') {
    return identityService.registerIdentity({ mobileNumber, passwordHash, accountType, fullName: fullName.trim() })
  }
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

  if (requiresLoginCode(user)) {
    // A password alone stops here: no session is started and no token is
    // issued until the code that was just texted comes back through
    // `completeLogin`, so a stolen password on its own grants nothing.
    await verificationService.sendLoginCode(user)
    return { verificationRequired: true }
  }

  return { verificationRequired: false, ...(await grantSession(user)) }
}

/**
 * Who has to enter a code to sign in — every account type that signs in at
 * all. Customers and Hotel Managers self-register against a mobile number
 * they own (BDR-018/BDR-019); a Platform Administrator is provisioned with
 * one (`scripts/create-platform-admin.js` takes `--mobile`), and an
 * administrator is the account most worth a second factor, since it decides
 * every Hotel's eligibility.
 *
 * The cost of including administrators is real and worth stating: platform
 * access now depends on the SMS gateway, so a carrier outage locks out the
 * people who would fix it. `scripts/create-platform-admin.js` remains the
 * way back in — it writes directly to the database and needs no SMS.
 */
const LOGIN_CODE_ACCOUNT_TYPES = ['CUSTOMER', 'HOTEL_MANAGER', 'PLATFORM_ADMINISTRATOR']

function requiresLoginCode(user) {
  return LOGIN_CODE_ACCOUNT_TYPES.includes(user.accountType)
}

async function grantSession(user) {
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
 * Second step of login — exchanges the texted code for a session.
 *
 * Unauthenticated by necessity (there is no token yet), so it is reachable
 * with a mobile number and a guess. Every failure is therefore the same
 * one: an unknown number, an expired code and a wrong code are
 * indistinguishable, exactly as `confirmVerification` already treats them,
 * so this cannot be used to enumerate who has an account.
 *
 * Confirming here also marks the account verified, so a Customer who
 * registered and never completed C3 finishes that the first time they sign
 * in rather than carrying an unverified account around.
 */
export async function completeLogin({ mobileNumber, code }) {
  const user = await identityService.findIdentityByMobileNumber(mobileNumber)
  if (!user || !requiresLoginCode(user)) {
    throw new BusinessRuleError('Invalid or expired verification request.')
  }
  if (!user.isActive) {
    throw new AuthenticationError('This account is inactive.')
  }

  const verified = await verificationService.confirmLoginCode(user.id, code)
  return grantSession(verified)
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
