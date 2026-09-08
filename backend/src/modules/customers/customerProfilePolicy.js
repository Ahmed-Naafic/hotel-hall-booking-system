import { ValidationError } from '../../shared/errors/errorTypes.js'

// BDR-018 approved `fullName` as the first named Customer profile field
// (partially resolving BDR-CUST-01 — every other candidate field there
// remains pending, per BDR-CUST-02). It is collected at registration
// (authentication.validation.js#validateRegister) and stored here, in the
// module that owns the Customer's business profile.
export const allowedProfileFields = Object.freeze(['fullName'])

const MAX_FULL_NAME_LENGTH = 200

function validateFullName(value, field) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field, message: `${field} must be a non-empty string.` },
    ])
  }
  if (value.trim().length > MAX_FULL_NAME_LENGTH) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field, message: `${field} must be at most ${MAX_FULL_NAME_LENGTH} characters.` },
    ])
  }
}

const FIELD_VALIDATORS = { fullName: validateFullName }

export function validateAndMapProfileData(value) {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'profileData', message: 'profileData must be an object.' },
    ])
  }

  const unsupported = Object.keys(value).filter((key) => !allowedProfileFields.includes(key))
  if (unsupported.length > 0) {
    throw new ValidationError('Customer profile fields have not yet been approved.',
      unsupported.map((field) => ({ field: `profileData.${field}`, message: 'This Customer profile field is not approved.' })))
  }

  const mapped = {}
  for (const field of allowedProfileFields) {
    if (value[field] === undefined) continue
    FIELD_VALIDATORS[field](value[field], `profileData.${field}`)
    mapped[field] = typeof value[field] === 'string' ? value[field].trim() : value[field]
  }
  return mapped
}

export function getReadiness(profile) {
  return {
    profileExists: profile !== null,
    isComplete: null,
    missingRequiredFields: null,
  }
}
