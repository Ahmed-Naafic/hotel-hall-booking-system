import { ValidationError } from '../../shared/errors/errorTypes.js'

/**
 * Request-shape validation (coding-standards.md §5, §11) — runs before any
 * controller logic. Business-rule validation belongs in the service layer
 * (api-standards.md §14). Field-level content validation for Hall Name and
 * Capacity, added per `BDR-016` (Required Hall Information, Approved
 * 2026-08-26, Technical Design §8): `api-standards.md` §9 classifies a
 * missing required field as request validation (`400`), not a business
 * rule (`422`) — the same classification this file already used for
 * `profileData`'s shape.
 */

function assertPlainObject(value, field) {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field, message: `${field} must be an object.` },
    ])
  }
}

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0
}

/** Accepts a JSON number or a numeric string (never trusts a client to pick one), per `BDR-016`. */
function isValidCapacity(value) {
  if (typeof value === 'number') {
    return Number.isInteger(value) && value > 0
  }
  if (typeof value === 'string') {
    const trimmed = value.trim()
    return /^\d+$/.test(trimmed) && Number(trimmed) > 0
  }
  return false
}

/**
 * Standard-field content checks shared by create (all-required) and update
 * (only-if-present) — collects every failure into one `details` array
 * (`api-standards.md` §8) rather than stopping at the first, so a client
 * sees every problem in one round trip.
 */
function collectStandardFieldErrors(fields, { requireName, requireCapacity }) {
  const details = []
  const hasName = fields?.name !== undefined
  const hasCapacity = fields?.capacity !== undefined && fields?.capacity !== null && fields?.capacity !== ''

  if (requireName && !hasName) {
    details.push({ field: 'name', message: 'Hall Name is required.' })
  } else if (hasName && !isNonEmptyString(fields.name)) {
    details.push({ field: 'name', message: 'Hall Name must be a non-empty string.' })
  }

  if (requireCapacity && !hasCapacity) {
    details.push({ field: 'capacity', message: 'Capacity is required.' })
  } else if (hasCapacity && !isValidCapacity(fields.capacity)) {
    details.push({ field: 'capacity', message: 'Capacity must be a valid positive number.' })
  }

  return details
}

export function validateCreateHall(req, res, next) {
  const { profileData } = req.body ?? {}
  if (profileData !== undefined) {
    assertPlainObject(profileData, 'profileData')
  }

  const details = collectStandardFieldErrors(profileData ?? {}, { requireName: true, requireCapacity: true })
  if (details.length > 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', details)
  }

  next()
}

export function validateUpdateHall(req, res, next) {
  const body = req.body ?? {}
  if (Object.keys(body).length === 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'body', message: 'At least one field must be provided.' },
    ])
  }
  assertPlainObject(body, 'body')

  // Only the fields actually present are validated — an edit that never
  // touches name/capacity must not be forced to re-supply them (merge
  // semantics, Technical Design §7/§8).
  const details = collectStandardFieldErrors(body, { requireName: false, requireCapacity: false })
  if (details.length > 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', details)
  }

  next()
}

export function validateListHallsForHotel(req, res, next) {
  const { page, limit } = req.query ?? {}
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

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export function validateBrowseHalls(req, res, next) {
  const { hotelId, limit, cursor } = req.query ?? {}
  if (hotelId !== undefined && !UUID_PATTERN.test(hotelId)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'hotelId', message: 'hotelId must be a valid identifier.' },
    ])
  }
  if (limit !== undefined && (!Number.isInteger(Number(limit)) || Number(limit) < 1)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'limit', message: 'limit must be a positive integer.' },
    ])
  }
  if (cursor !== undefined && !UUID_PATTERN.test(cursor)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'cursor', message: 'cursor must be a valid identifier.' },
    ])
  }
  next()
}
