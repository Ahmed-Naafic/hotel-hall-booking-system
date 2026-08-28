import { ValidationError } from '../../shared/errors/errorTypes.js'

/**
 * Request-shape validation (coding-standards.md §5, §11) — runs before any
 * controller logic. Business-rule validation belongs in the service layer
 * (api-standards.md §14).
 */
const HOTEL_STATUS_VALUES = [
  'REGISTERED',
  'PROFILE_COMPLETE',
  'UNDER_REVIEW',
  'APPROVED_ACTIVE',
  'REJECTED',
  'WITHDRAWN',
  'SUSPENDED',
  'DEACTIVATED',
  'RESTRICTED_UNDER_REVIEW',
]

function assertPlainObject(value, field) {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field, message: `${field} must be an object.` },
    ])
  }
}

export function validateRegisterHotel(req, res, next) {
  const { profileData } = req.body ?? {}
  if (profileData !== undefined) {
    assertPlainObject(profileData, 'profileData')
  }
  next()
}

export function validateUpdateHotel(req, res, next) {
  const body = req.body ?? {}
  if (Object.keys(body).length === 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'body', message: 'At least one field must be provided.' },
    ])
  }
  assertPlainObject(body, 'body')
  next()
}

export function validateListHotels(req, res, next) {
  const { status, page, limit } = req.query ?? {}
  if (status !== undefined && !HOTEL_STATUS_VALUES.includes(status)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'status', message: `status must be one of: ${HOTEL_STATUS_VALUES.join(', ')}.` },
    ])
  }
  if (page !== undefined && (!Number.isInteger(Number(page)) || Number(page) < 1)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'page', message: 'page must be a positive integer.' },
    ])
  }
  if (limit !== undefined && (!Number.isInteger(Number(limit)) || Number(limit) < 1)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'limit', message: 'limit must be a positive integer.' },
    ])
  }
  next()
}
