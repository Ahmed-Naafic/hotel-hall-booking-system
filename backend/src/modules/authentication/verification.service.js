import * as verificationRepository from './verification.repository.js'
import * as identityService from './identity.service.js'
import { generateVerificationCode } from './verificationCode.js'
import { sha256Hex } from '../../shared/utils/hash.js'
import { smsProvider } from '../../shared/providers/smsProvider.js'
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

  const code = generateVerificationCode()
  const codeHash = sha256Hex(code)
  const expiresAt = new Date(Date.now() + env.auth.verificationCodeTtlMinutes * 60 * 1000)

  await verificationRepository.create({ userId, codeHash, expiresAt })
  await smsProvider.sendSms({
    to: user.mobileNumber,
    body: `Your verification code is ${code}. It expires in ${env.auth.verificationCodeTtlMinutes} minutes.`,
  })
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
