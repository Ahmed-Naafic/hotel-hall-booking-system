import * as passwordResetRepository from './passwordReset.repository.js'
import * as identityService from './identity.service.js'
import * as credentialService from './credential.service.js'
import * as sessionService from './session.service.js'
import { generateVerificationCode } from './verificationCode.js'
import { sha256Hex } from '../../shared/utils/hash.js'
import { smsProvider } from '../../shared/providers/smsProvider.js'
import { env } from '../../config/env.js'
import { BusinessRuleError } from '../../shared/errors/errorTypes.js'

/**
 * Password Reset lifecycle (Technical Design §4 Credential Component, §7.4,
 * BR-AUTH-09) — through the SmsProvider abstraction, never Twilio directly.
 */

function isExpired(request) {
  return request.expiresAt.getTime() < Date.now()
}

/**
 * C6 — request a password reset. Never reveals whether `mobileNumber` is
 * registered (BR-AUTH-09): the caller (controller) responds identically
 * whether or not a User Account was found.
 */
export async function requestPasswordReset(mobileNumber) {
  const user = await identityService.findIdentityByMobileNumber(mobileNumber)
  if (!user) {
    return
  }

  // Technical Design §5.1: "at most one active Password Reset Request at a
  // time" — a new request supersedes any still-pending one.
  await passwordResetRepository.invalidateActiveForUser(user.id)

  const code = generateVerificationCode()
  const tokenHash = sha256Hex(code)
  const expiresAt = new Date(Date.now() + env.auth.passwordResetCodeTtlMinutes * 60 * 1000)

  await passwordResetRepository.create({ userId: user.id, tokenHash, expiresAt })
  await smsProvider.sendSms({
    to: user.mobileNumber,
    body: `Your password reset code is ${code}. It expires in ${env.auth.passwordResetCodeTtlMinutes} minutes.`,
  })
}

/**
 * C6 — confirm a password reset. Takes `mobileNumber` rather than a reset
 * request id: Technical Design §10 originally shaped this as
 * `PATCH /password-resets/:id`, but the POST above cannot return that id
 * to the client without contradicting its own anti-enumeration requirement
 * (returning an id would reveal the account exists) — corrected in
 * Technical Design v1.5 to take the identifier directly, the same pattern
 * confirmVerification() already uses.
 */
export async function confirmPasswordReset(mobileNumber, code, newPassword) {
  const user = await identityService.findIdentityByMobileNumber(mobileNumber)
  const active = user ? await passwordResetRepository.findActiveForUser(user.id) : null

  if (!user || !active || isExpired(active) || sha256Hex(code) !== active.tokenHash) {
    throw new BusinessRuleError('Invalid or expired password reset request.')
  }

  const passwordHash = await credentialService.hashPassword(newPassword)
  await identityService.changePasswordHash(user.id, passwordHash)
  await passwordResetRepository.markUsed(active.id)

  // Not an explicit business rule — a defensible security default
  // (architecture-principles.md §7), the same one deactivation uses
  // (BR-AUTH-06): every refresh token is revoked, so no session can be
  // renewed past its current access token. This does NOT immediately
  // invalidate an already-issued access token still inside its own
  // expiry (Technical Design §9 — access tokens are short-lived,
  // stateless JWTs by design; there is no blocklist). The exposure window
  // this leaves is bounded by ACCESS_TOKEN_TTL_MINUTES, not eliminated.
  await sessionService.endAllSessionsForUser(user.id)
}
