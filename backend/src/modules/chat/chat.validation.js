import { ValidationError } from '../../shared/errors/errorTypes.js'

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const MAX_BODY_LENGTH = 2000

function fail(details) {
  throw new ValidationError('The request could not be processed due to invalid input.', details)
}

export function validateSendMessage(req, res, next) {
  const body = req.body ?? {}
  const details = []
  if (typeof body.body !== 'string' || !body.body.trim()) {
    details.push({ field: 'body', message: 'body is required.' })
  } else if (body.body.trim().length > MAX_BODY_LENGTH) {
    details.push({ field: 'body', message: `body must be at most ${MAX_BODY_LENGTH} characters.` })
  }
  if (details.length) fail(details)
  next()
}

export function validateList(req, res, next) {
  const details = []
  if (req.query.cursor !== undefined && !UUID.test(req.query.cursor)) details.push({ field: 'cursor', message: 'cursor must be a valid identifier.' })
  if (req.query.limit !== undefined && (!Number.isInteger(Number(req.query.limit)) || Number(req.query.limit) < 1)) details.push({ field: 'limit', message: 'limit must be a positive integer.' })
  if (details.length) fail(details)
  next()
}
