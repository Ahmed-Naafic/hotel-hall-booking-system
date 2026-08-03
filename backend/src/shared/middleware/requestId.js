import { randomUUID } from 'node:crypto'

/**
 * Attaches a correlation ID to every request — the same ID an error
 * response's `requestId` field carries (api-standards.md §8) and every log
 * line for this request uses (coding-standards.md §10).
 */
export function requestId(req, res, next) {
  req.requestId = randomUUID()
  res.setHeader('X-Request-Id', req.requestId)
  next()
}
