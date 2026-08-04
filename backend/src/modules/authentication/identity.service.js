import * as identityRepository from './identity.repository.js'
import { BusinessRuleError } from '../../shared/errors/errorTypes.js'

/**
 * Identity Component (Technical Design §4) — creates and retrieves the
 * login identity for an account. Never stores or reasons about a business
 * profile (owned by Customer/Hotel Management, §3.2) and never hashes or
 * verifies a credential itself (Credential Component's job).
 */

export async function registerIdentity({ mobileNumber, passwordHash, accountType }) {
  const existing = await identityRepository.findByMobileNumber(mobileNumber)
  if (existing) {
    // BR-AUTH-02: registration fails if the identifier is already registered.
    throw new BusinessRuleError('This mobile number is already registered.')
  }
  return identityRepository.create({ mobileNumber, passwordHash, accountType })
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
