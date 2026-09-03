import { ValidationError } from '../../shared/errors/errorTypes.js'

/**
 * Request-shape validation only (coding-standards.md §5, §11) — format and
 * presence, never business rules. The past-date rule (Approved Technical
 * Design decision 5) and the overlap check are business-integrity concerns
 * and live in `availability.service.js` instead, matching `hall.validation.js`'s
 * own precedent.
 *
 * There is deliberately no "end must be after start" check here.
 * `availability.service.js#combineBlockPeriod` classifies every well-formed
 * `(date, startTime, endTime)` triple into exactly one of three cases —
 * a normal same-day period (`startTime < endTime`), an overnight period
 * that rolls into the next calendar day (`endTime <= startTime`, e.g.
 * `22:00`→`02:00`), or identical start/end time-of-day (also rolls
 * forward, becoming a full 24-hour period, never a zero-length one) — so
 * every combination of two well-formed `HH:mm` values is already a valid,
 * forward-moving period by the time it reaches the service layer. There is
 * no fourth, invalid case for this layer to reject.
 */

const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/
const TIME_PATTERN = /^([01]\d|2[0-3]):[0-5]\d$/

function isValidDateString(value) {
  if (typeof value !== 'string' || !DATE_PATTERN.test(value)) return false
  const [year, month, day] = value.split('-').map(Number)
  const parsed = new Date(Date.UTC(year, month - 1, day))
  return parsed.getUTCFullYear() === year && parsed.getUTCMonth() === month - 1 && parsed.getUTCDate() === day
}

function isValidTimeString(value) {
  return typeof value === 'string' && TIME_PATTERN.test(value)
}

export function validateDateQuery(req, res, next) {
  const { date } = req.query ?? {}
  if (!isValidDateString(date)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'date', message: 'date must be a valid calendar date in YYYY-MM-DD format.' },
    ])
  }
  next()
}

function collectPeriodErrors({ date, startTime, endTime, reason }) {
  const details = []
  if (!isValidDateString(date)) {
    details.push({ field: 'date', message: 'date must be a valid calendar date in YYYY-MM-DD format.' })
  }
  if (!isValidTimeString(startTime)) {
    details.push({ field: 'startTime', message: 'startTime must be a valid time in HH:mm format.' })
  }
  if (!isValidTimeString(endTime)) {
    details.push({ field: 'endTime', message: 'endTime must be a valid time in HH:mm format.' })
  }
  if (reason !== undefined && reason !== null && typeof reason !== 'string') {
    details.push({ field: 'reason', message: 'reason must be a string.' })
  }
  return details
}

export function validateCreateBlock(req, res, next) {
  const { date, startTime, endTime, reason } = req.body ?? {}
  const details = collectPeriodErrors({ date, startTime, endTime, reason })
  if (details.length > 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', details)
  }
  next()
}

export function validateUpdateBlock(req, res, next) {
  const body = req.body ?? {}
  if (Object.keys(body).length === 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'body', message: 'At least one field must be provided.' },
    ])
  }

  const details = []
  if (body.date !== undefined && !isValidDateString(body.date)) {
    details.push({ field: 'date', message: 'date must be a valid calendar date in YYYY-MM-DD format.' })
  }
  if (body.startTime !== undefined && !isValidTimeString(body.startTime)) {
    details.push({ field: 'startTime', message: 'startTime must be a valid time in HH:mm format.' })
  }
  if (body.endTime !== undefined && !isValidTimeString(body.endTime)) {
    details.push({ field: 'endTime', message: 'endTime must be a valid time in HH:mm format.' })
  }
  if (body.reason !== undefined && body.reason !== null && typeof body.reason !== 'string') {
    details.push({ field: 'reason', message: 'reason must be a string.' })
  }
  if (details.length > 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', details)
  }
  next()
}

export function validateCheckAvailability(req, res, next) {
  const { date, startTime, endTime } = req.body ?? {}
  const details = collectPeriodErrors({ date, startTime, endTime, reason: undefined })
  if (details.length > 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', details)
  }
  next()
}
