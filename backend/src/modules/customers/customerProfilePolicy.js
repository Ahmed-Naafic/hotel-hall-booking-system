import { ValidationError } from '../../shared/errors/errorTypes.js'

// No Customer profile fields are approved yet (BDR-CUST-01/02 remain pending).
export const allowedProfileFields = Object.freeze([])

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
  return {}
}

export function getReadiness(profile) {
  return {
    profileExists: profile !== null,
    isComplete: null,
    missingRequiredFields: null,
  }
}
