import { ValidationError } from '../../shared/errors/errorTypes.js'

/**
 * Request-shape validation (coding-standards.md §5, §11) — runs before any
 * controller logic. Business-rule validation belongs in the service layer
 * (api-standards.md §14).
 */
// BDR-020 — search is free text, not an identifier; only bounded so an
// unreasonably long query can't be sent, never restricted in character set.
// Shared by every public browse/search endpoint this module has (Public,
// Nearby, Popular) so "search means the same thing everywhere" holds at the
// validation layer too, not just in each service's own matching logic.
const MAX_SEARCH_LENGTH = 200

function validateSearchLength(search, details) {
  if (search !== undefined && (typeof search !== 'string' || search.length > MAX_SEARCH_LENGTH)) {
    details.push({ field: 'search', message: `search must be a string of ${MAX_SEARCH_LENGTH} characters or fewer.` })
  }
}

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

function validCoordinate(value, min, max) {
  return typeof value === 'number' && Number.isFinite(value) && value >= min && value <= max
}

export function validateReverseGeocode(req, res, next) {
  const { latitude, longitude } = req.body ?? {}
  const details = []
  if (!validCoordinate(latitude, -90, 90)) {
    details.push({ field: 'latitude', message: 'latitude must be a number between -90 and 90.' })
  }
  if (!validCoordinate(longitude, -180, 180)) {
    details.push({ field: 'longitude', message: 'longitude must be a number between -180 and 180.' })
  }
  if (details.length > 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', details)
  }
  next()
}

function queryCoordinate(value) {
  if (typeof value !== 'string' || value.trim().length === 0) return NaN
  return Number(value)
}

export function validateNearbyHotels(req, res, next) {
  const { latitude, longitude, search } = req.query ?? {}
  const details = []
  if (!validCoordinate(queryCoordinate(latitude), -90, 90)) {
    details.push({ field: 'latitude', message: 'latitude must be a number between -90 and 90.' })
  }
  if (!validCoordinate(queryCoordinate(longitude), -180, 180)) {
    details.push({ field: 'longitude', message: 'longitude must be a number between -180 and 180.' })
  }
  validateSearchLength(search, details)
  if (details.length > 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', details)
  }
  next()
}

export function validatePopularHotels(req, res, next) {
  const { limit, search } = req.query ?? {}
  const details = []
  if (limit !== undefined && (!Number.isInteger(Number(limit)) || Number(limit) < 1)) {
    details.push({ field: 'limit', message: 'limit must be a positive integer.' })
  }
  validateSearchLength(search, details)
  if (details.length > 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', details)
  }
  next()
}

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export function validateHotelId(req, res, next) {
  if (!UUID_PATTERN.test(req.params.id)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'id', message: 'id must be a valid identifier.' },
    ])
  }
  next()
}

export function validatePublicHotels(req, res, next) {
  const { limit, cursor, search } = req.query ?? {}
  const details = []
  if (limit !== undefined && (!Number.isInteger(Number(limit)) || Number(limit) < 1)) {
    details.push({ field: 'limit', message: 'limit must be a positive integer.' })
  }
  if (cursor !== undefined && !UUID_PATTERN.test(cursor)) {
    details.push({ field: 'cursor', message: 'cursor must be a valid identifier.' })
  }
  validateSearchLength(search, details)
  if (details.length > 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', details)
  }
  next()
}
