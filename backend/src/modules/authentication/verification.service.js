import * as verificationRepository from './verification.repository.js'
import * as identityService from './identity.service.js'
import { generateVerificationCode } from './verificationCode.js'
import { sha256Hex } from '../../shared/utils/hash.js'
import { smsProvider } from '../../shared/providers/smsProvider.js'
import { MockSmsProvider } from '../../shared/providers/mockSmsProvider.js'
import { env } from '../../config/env.js'
import { BusinessRuleError, ConflictError } from '../../shared/errors/errorTypes.js'

/**
 * Verification Component (Technical Design §4, §7.5) — manages the
 * Identity Verification lifecycle (BR-AUTH-02, C3) through the SmsProvider
 * abstraction (architecture-principles.md §10-11), never Twilio directly.
 */

function isExpired(request) {
  return request.expiresAt.getTime() < Date.now()
}

/**
 * Issues a code, stores its hash, and texts it — the single place that
 * decides what a verification code is and how it reaches someone, shared by
 * first-time verification (C3) and the login second factor.
 *
 * Deliberately does not check for an already-active request: the newest
 * request is the one `findActiveForUser` returns, so re-issuing simply
 * supersedes an earlier code. The "one at a time" rule belongs to
 * `requestVerification` below, which is the flow a caller can spam.
 */
async function issueCode(user) {
  // Dev/test convenience: DEV_FIXED_VERIFICATION_CODE, if set, replaces the
  // random code — but only while the selected provider is the mock, so this
  // can never silently weaken a real SMS-backed environment. The condition
  // asks the provider itself rather than naming one gateway's credentials:
  // when this checked `env.sms.twilio` specifically, configuring any other
  // gateway left a real deployment handing out a fixed code. Safe here
  // specifically because VerificationRequest.codeHash carries no uniqueness
  // constraint (unlike PasswordResetRequest.tokenHash — see
  // verificationCode.js's own docstring for why that flow never applies
  // this override).
  const deliversForReal = !(smsProvider instanceof MockSmsProvider)
  const code = !deliversForReal && env.auth.devFixedVerificationCode
    ? env.auth.devFixedVerificationCode
    : generateVerificationCode()

  const expiresAt = new Date(Date.now() + env.auth.verificationCodeTtlMinutes * 60 * 1000)
  await verificationRepository.create({ userId: user.id, codeHash: sha256Hex(code), expiresAt })
  await smsProvider.sendSms({
    to: user.mobileNumber,
    body: `Your verification code is ${code}. It expires in ${env.auth.verificationCodeTtlMinutes} minutes.`,
  })
}

/**
 * The login second factor (BR-AUTH-02) — a fresh code for someone who has
 * just proved their password. Separate entry point from
 * `requestVerification` because that one refuses while a code is still
 * live, which would lock someone out of signing in again within the TTL.
 */
export async function sendLoginCode(user) {
  await issueCode(user)
}

/** C3 — request a verification code for the caller's own, unverified account. */
export async function requestVerification(userId) {
  const user = await identityService.findIdentityById(userId)

  if (user.isVerified) {
    throw new BusinessRuleError('This account is already verified.')
  }

  const active = await verificationRepository.findActiveForUser(userId)
  if (active && !isExpired(active)) {
    throw new ConflictError('A verification code has already been sent. Please wait for it to expire, or use it.')
  }

  await issueCode(user)
}

/**
 * The login second factor's confirm step — same code, same expiry, same
 * uniform failure as C3 below, and it marks the account verified for the
 * same reason: possession of the number has just been proved.
 *
 * Returns the updated identity so the caller can mint a session from it
 * without re-reading the row.
 */
export async function confirmLoginCode(userId, code) {
  return confirmVerification(userId, code)
}

/** C3 — confirm a verification code, activating the User Account (BR-AUTH-02). */
export async function confirmVerification(userId, code) {
  const active = await verificationRepository.findActiveForUser(userId)

  // One uniform failure for "no request", "expired", and "wrong code" —
  // Technical Design §7.5/§10 treats all three as the same 422, never a
  // distinct error type the caller could use to enumerate which failed.
  if (!active || isExpired(active) || sha256Hex(code) !== active.codeHash) {
    throw new BusinessRuleError('Invalid or expired verification request.')
  }

  await verificationRepository.markConfirmed(active.id)
  return identityService.markIdentityVerified(userId)
}
