import { ValidationError } from '../../shared/errors/errorTypes.js'

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const EVENT_TYPES = new Set(['WEDDING', 'CONFERENCE', 'BIRTHDAY', 'MEETING', 'GRADUATION', 'OTHER'])
const STATUSES = new Set(['PENDING', 'CONFIRMED', 'REJECTED', 'CANCELLED', 'COMPLETED', 'NO_SHOW', 'EXPIRED'])

function fail(details) {
  throw new ValidationError('The request could not be processed due to invalid input.', details)
}

export function validateCreate(req, res, next) {
  const body = req.body ?? {}
  const details = []
  if (!UUID.test(body.hallId ?? '')) details.push({ field: 'hallId', message: 'hallId must be a valid identifier.' })
  if (!body.startsAt || Number.isNaN(Date.parse(body.startsAt))) details.push({ field: 'startsAt', message: 'startsAt must be a valid ISO date-time.' })
  if (!body.endsAt || Number.isNaN(Date.parse(body.endsAt))) details.push({ field: 'endsAt', message: 'endsAt must be a valid ISO date-time.' })
  if (!Number.isInteger(body.numberOfGuests) || body.numberOfGuests < 1) details.push({ field: 'numberOfGuests', message: 'numberOfGuests must be a positive integer.' })
  if (!EVENT_TYPES.has(body.eventType)) details.push({ field: 'eventType', message: 'eventType is invalid.' })
  if (body.specialRequest !== undefined && typeof body.specialRequest !== 'string') details.push({ field: 'specialRequest', message: 'specialRequest must be a string.' })
  if (details.length) fail(details)
  next()
}

export function validatePaymentReport(req, res, next) {
  if (!Number.isInteger(req.body?.amountCents) || req.body.amountCents < 1) {
    fail([{ field: 'amountCents', message: 'amountCents must be a positive integer.' }])
  }
  next()
}

export function validatePaymentDecision(req, res, next) {
  if (!['VERIFY', 'REJECT'].includes(req.body?.decision)) {
    fail([{ field: 'decision', message: 'decision must be VERIFY or REJECT.' }])
  }
  if (req.body.decision === 'REJECT' && (typeof req.body.reason !== 'string' || !req.body.reason.trim())) {
    fail([{ field: 'reason', message: 'reason is required when rejecting a payment report.' }])
  }
  next()
}

export function validateList(req, res, next) {
  const details = []
  if (req.query.cursor !== undefined && !UUID.test(req.query.cursor)) details.push({ field: 'cursor', message: 'cursor must be a valid identifier.' })
  if (req.query.limit !== undefined && (!Number.isInteger(Number(req.query.limit)) || Number(req.query.limit) < 1)) details.push({ field: 'limit', message: 'limit must be a positive integer.' })
  if (req.query.status !== undefined && !STATUSES.has(req.query.status)) details.push({ field: 'status', message: 'status is invalid.' })
  if (details.length) fail(details)
  next()
}
