import { ValidationError } from '../../shared/errors/errorTypes.js'
import { COLLECTION_NAMES } from './sync.collections.js'
import { DEFAULT_LIMIT, MAX_LIMIT } from './sync.cursor.js'

/**
 * Rejects a malformed sync request before any query runs
 * (Technical Design §17). `collection` is checked against the registry's own
 * allowlist rather than a copy of it, so the two cannot drift.
 */
export function validateChanges(req, res, next) {
  const details = []
  const { collection } = req.params
  const { since, limit } = req.query ?? {}

  if (!COLLECTION_NAMES.includes(collection)) {
    details.push({
      field: 'collection',
      message: `collection must be one of: ${COLLECTION_NAMES.join(', ')}.`,
    })
  }

  // `since` is a decimal string, not a number: `sync_seq` is a BIGINT and can
  // exceed what a JS number represents exactly.
  if (since !== undefined) {
    if (!/^\d+$/.test(since)) {
      details.push({ field: 'since', message: 'since must be a non-negative integer.' })
    } else {
      req.syncCursor = BigInt(since)
    }
  }

  if (limit !== undefined) {
    const parsed = Number(limit)
    if (!Number.isInteger(parsed) || parsed < 1 || parsed > MAX_LIMIT) {
      details.push({ field: 'limit', message: `limit must be an integer between 1 and ${MAX_LIMIT}.` })
    } else {
      req.syncLimit = parsed
    }
  }

  if (details.length > 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', details)
  }

  req.syncLimit ??= DEFAULT_LIMIT
  next()
}
