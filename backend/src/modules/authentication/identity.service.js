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

export async function registerIdentity({ mobileNumber, passwordHash, accountType, fullName }, client) {
  const existing = await identityRepository.findByMobileNumber(mobileNumber)
  if (existing) {
    // BR-AUTH-02: registration fails if the identifier is already registered.
    throw new BusinessRuleError('This mobile number is already registered.')
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
