import { ValidationError } from '../../shared/errors/errorTypes.js'

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const STATUSES = new Set(['UNREAD', 'READ'])

function fail(details) {
  throw new ValidationError('The request could not be processed due to invalid input.', details)
}

export function validateList(req, res, next) {
  const details = []
  if (req.query.cursor !== undefined && !UUID.test(req.query.cursor)) details.push({ field: 'cursor', message: 'cursor must be a valid identifier.' })
  if (req.query.limit !== undefined && (!Number.isInteger(Number(req.query.limit)) || Number(req.query.limit) < 1)) details.push({ field: 'limit', message: 'limit must be a positive integer.' })
  if (req.query.status !== undefined && !STATUSES.has(req.query.status)) details.push({ field: 'status', message: 'status must be UNREAD or READ.' })
  if (details.length) fail(details)
  next()
}

export function validateDeviceToken(req, res, next) {
  const body = req.body ?? {}
  if (typeof body.token !== 'string' || !body.token.trim()) {
    fail([{ field: 'token', message: 'token is required.' }])
  }
  if (body.platform !== undefined && typeof body.platform !== 'string') {
    fail([{ field: 'platform', message: 'platform must be a string.' }])
  }
  next()
}

export function validateDeviceTokenQuery(req, res, next) {
  if (typeof req.query.token !== 'string' || !req.query.token.trim()) {
    fail([{ field: 'token', message: 'token is required.' }])
  }
  next()
}
