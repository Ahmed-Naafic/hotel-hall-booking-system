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

// BDR-020's own bound, mirrored here (`hotel.validation.js` carries the
// canonical comment) — Hall search is free text too, only length-bounded.
const MAX_SEARCH_LENGTH = 200

function validateSearchLength(search, details) {
  if (search !== undefined && (typeof search !== 'string' || search.length > MAX_SEARCH_LENGTH)) {
    details.push({ field: 'search', message: `search must be a string of ${MAX_SEARCH_LENGTH} characters or fewer.` })
  }
}

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

function collectDirectFieldErrors(body) {
  const details = []
  if (body.isActive !== undefined && typeof body.isActive !== 'boolean') {
    details.push({ field: 'isActive', message: 'isActive must be a boolean.' })
  }
  return details
}

function collectCommercialErrors(body, required) {
  const details = []
  const positiveInteger = (value) => Number.isInteger(value) && value > 0
  if ((required || body.rentAmountCents !== undefined) && !positiveInteger(body.rentAmountCents)) details.push({ field: 'rentAmountCents', message: 'rentAmountCents must be a positive integer.' })
  if ((required || body.rentDurationHours !== undefined) && body.rentDurationHours !== 24) details.push({ field: 'rentDurationHours', message: 'rentDurationHours must be 24.' })
  // Approved V1 business rule: a fixed 30% advance, platform-wide — not a
  // Hall-level Manager choice (mirrors rentDurationHours's fixed-24 treatment).
  if ((required || body.advancePaymentPercent !== undefined) && body.advancePaymentPercent !== 30) details.push({ field: 'advancePaymentPercent', message: 'advancePaymentPercent must be 30.' })
  for (const field of ['customerServiceNumber', 'paymentReceivingNumber']) {
    if ((required || body[field] !== undefined) && !isNonEmptyString(body[field])) details.push({ field, message: `${field} is required and must be a non-empty string.` })
  }
  return details
}

export function validateCreateHall(req, res, next) {
  const { profileData } = req.body ?? {}
  if (profileData !== undefined) {
    assertPlainObject(profileData, 'profileData')
  }

  const details = collectStandardFieldErrors(profileData ?? {}, { requireName: true, requireCapacity: true })
  details.push(...collectCommercialErrors(req.body ?? {}, false))
  details.push(...collectDirectFieldErrors(req.body ?? {}))
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
  details.push(...collectCommercialErrors(body, false))
  details.push(...collectDirectFieldErrors(body))
  if (details.length > 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', details)
  }

  next()
}

export function validateListHallsForHotel(req, res, next) {
  const { page, limit, status } = req.query ?? {}
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
  if (status !== undefined && !['active', 'inactive'].includes(status)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'status', message: 'status must be "active" or "inactive".' },
    ])
  }
  next()
}

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

/** A non-negative integer query parameter, or `undefined` if not supplied — `fail` on anything else (a negative number, a non-numeric string). */
function nonNegativeIntOrFail(value, field) {
  if (value === undefined) return undefined
  const parsed = Number(value)
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field, message: `${field} must be a non-negative integer.` },
    ])
  }
  return parsed
}

export function validateBrowseHalls(req, res, next) {
  const { hotelId, limit, cursor, search } = req.query ?? {}
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
  const searchDetails = []
  validateSearchLength(search, searchDetails)
  if (searchDetails.length > 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', searchDetails)
  }
  // Advanced Filters (Customer Mobile, All Halls) — capacity lives in the
  // Hall's own flexible `profileData` (Pending Business Decision #2 on
  // required Hall content, same reason `visibility.service.js#hallCapacity`
  // already reads it defensively rather than as a real column); price is
  // the real `rentAmountCents` column.
  nonNegativeIntOrFail(req.query?.minCapacity, 'minCapacity')
  const minPriceCents = nonNegativeIntOrFail(req.query?.minPriceCents, 'minPriceCents')
  const maxPriceCents = nonNegativeIntOrFail(req.query?.maxPriceCents, 'maxPriceCents')
  if (minPriceCents !== undefined && maxPriceCents !== undefined && minPriceCents > maxPriceCents) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'maxPriceCents', message: 'maxPriceCents must be greater than or equal to minPriceCents.' },
    ])
  }
  next()
}

export function validateLargeHalls(req, res, next) {
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
