import * as identityRepository from './identity.repository.js'
import { BusinessRuleError } from '../../shared/errors/errorTypes.js'

/**
 * Identity Component (Technical Design §4) — creates and retrieves the
 * login identity for an account. Never stores or reasons about a business
 * profile (Hotel's own profile is owned by Hotel Management, a Customer's
 * extended profile by Customer Management, §3.2). `fullName` (BDR-018,
 * BDR-019) is an exception only in the sense that it lives on this same
 * User row for a Hotel Manager (no separate profile table exists for one)
 * — it is still the account holder's own core identity, not a business
 * profile field, and this component never reasons about *why* it was
 * collected, only stores what it's given.
 */

/**
 * How an occupied number is described back to whoever tried to reuse it.
 *
 * Only the two self-registerable types are named. A Platform Administrator
 * is deliberately absent: those accounts are provisioned internally, never
 * through this endpoint, so naming one would tell an anonymous caller that
 * a given number belongs to an administrator — and the generic message
 * below is already true and already enough to stop the registration.
 */
const ACCOUNT_TYPE_LABELS = {
  CUSTOMER: 'a Customer',
  HOTEL_MANAGER: 'a Hotel Manager',
}

export async function registerIdentity({ mobileNumber, passwordHash, accountType, fullName }, client) {
  const existing = await identityRepository.findByMobileNumber(mobileNumber)
  if (existing) {
    // BR-AUTH-02: registration fails if the identifier is already registered.
    // Naming the account type is what tells someone whether to sign in
    // instead, or that the number is on the other app — the common real
    // cases, and both unactionable from "already registered" alone.
    const label = ACCOUNT_TYPE_LABELS[existing.accountType]
    throw new BusinessRuleError(
      label
        ? `This mobile number is already registered as ${label}. Log in instead, or use a different number.`
        : 'This mobile number is already registered.',
    )
  }
  return identityRepository.create({ mobileNumber, passwordHash, accountType, fullName }, client)
}

export function findIdentityByMobileNumber(mobileNumber) {
  return identityRepository.findByMobileNumber(mobileNumber)
}

export function findIdentityById(id) {
  return identityRepository.findById(id)
}

export function markIdentityVerified(id) {
  return identityRepository.markVerified(id)
}

export function deactivateIdentity(id) {
  return identityRepository.setActive(id, false)
}

export function reactivateIdentity(id) {
  return identityRepository.setActive(id, true)
}

export function changePasswordHash(id, passwordHash) {
  return identityRepository.updatePasswordHash(id, passwordHash)
}
