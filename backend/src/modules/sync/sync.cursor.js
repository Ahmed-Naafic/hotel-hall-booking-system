import { ValidationError } from '../../shared/errors/errorTypes.js'
import { AppError } from '../../shared/errors/AppError.js'

/**
 * Cursor arithmetic for every sync collection, in one place so no resolver
 * re-derives it (Local-First Synchronization Technical Design §4, §7).
 *
 * **A cursor is a snapshot window, not a sequence number.** `sync_seq` is drawn
 * when a row is written but the row becomes visible only at COMMIT, so a
 * transaction holding a lower number can commit after a client has already
 * advanced past it — and `sync_seq > :since` would then never return that row.
 * Reproduced on PostgreSQL 17 before this design was adopted.
 *
 * Instead, every row records the transaction that last wrote it (`sync_txid`),
 * and a batch is exactly the rows whose writer is visible in snapshot `hi` but
 * was not visible in snapshot `lo`. Consecutive batches share a boundary
 * (`next.lo = this.hi`), so every committed write lands in exactly one batch,
 * whatever order transactions commit in.
 *
 * Within one batch the set of rows is fixed, so it is paged by `sync_seq`
 * keyset (`after`) — safe there, because the only way a row leaves the set is a
 * newer write, which puts it in the next batch.
 *
 * The token is opaque to clients (`api-standards.md` permits opaque cursors):
 * base64url JSON `{ v, lo, hi, after }`, where `lo`/`hi` are PostgreSQL
 * `pg_snapshot` text (`xmin:xmax:xip,...`) and `after` a decimal `sync_seq`.
 */

/** `coding-standards.md` §6 — the same bounded default every list here uses. */
export const DEFAULT_LIMIT = 20
export const MAX_LIMIT = 100

const VERSION = 1
const SNAPSHOT = /^\d{1,20}:\d{1,20}:(\d{1,20}(,\d{1,20})*)?$/
const DECIMAL = /^\d{1,19}$/
const XID8_MAX = 2n ** 64n - 1n
const INT8_MAX = 2n ** 63n - 1n

/**
 * "Discard this collection and resync it from nothing" (Technical Design §8).
 * A 409 — the cursor conflicts with the database's current state — carrying a
 * machine-readable code the client branches on. Never an empty success, which
 * would be indistinguishable from "nothing changed".
 */
export class SyncCursorExpiredError extends AppError {
  constructor(message = 'This sync cursor can no longer be continued; resynchronize this collection.') {
    super({ statusCode: 409, errorCode: 'SYNC_CURSOR_EXPIRED', message })
  }
}

/**
 * Everything `pg_snapshot_in` would reject, rejected here first so a forged
 * value is a 400, never a 500: `xmin <= xmax`, every in-progress id in
 * `[xmin, xmax)`, strictly ascending, and all within 64 bits.
 */
function isValidSnapshot(value) {
  if (value === null) return true
  if (typeof value !== 'string' || !SNAPSHOT.test(value)) return false
  const [xminText, xmaxText, xipText] = value.split(':')
  const xmin = BigInt(xminText)
  const xmax = BigInt(xmaxText)
  if (xmin < 1n || xmax > XID8_MAX || xmin > xmax) return false
  let previous = -1n
  for (const text of xipText === '' ? [] : xipText.split(',')) {
    const xid = BigInt(text)
    if (xid < xmin || xid >= xmax || xid <= previous) return false
    previous = xid
  }
  return true
}

/** The `xmax` of a snapshot's text form, for comparing against the database's. */
export function snapshotXmax(value) {
  return BigInt(value.split(':')[1])
}
// A pg_snapshot lists every in-progress transaction id, so its length tracks
// concurrency. Bounded so a forged cursor cannot become an expensive parse.
const MAX_TOKEN_LENGTH = 16384

/** @typedef {{ lo: string|null, hi: string|null, after: bigint|null }} SyncWindow */

export function encodeCursor({ lo, hi, after }) {
  const body = { v: VERSION, lo, hi, after: after === null ? null : String(after) }
  return Buffer.from(JSON.stringify(body), 'utf8').toString('base64url')
}

/**
 * Parses and validates a client-supplied cursor. Every field is shape-checked
 * here — the snapshots are later cast to `pg_snapshot` in SQL, where a
 * malformed value would surface as a 500 rather than the 400 it is.
 *
 * @returns {SyncWindow}
 */
export function decodeCursor(token) {
  const invalid = () =>
    new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'since', message: 'since must be a cursor previously returned by this endpoint.' },
    ])

  if (typeof token !== 'string' || token.length === 0 || token.length > MAX_TOKEN_LENGTH) {
    throw invalid()
  }
  let body
  try {
    body = JSON.parse(Buffer.from(token, 'base64url').toString('utf8'))
  } catch {
    throw invalid()
  }
  if (body === null || typeof body !== 'object' || typeof body.v !== 'number') throw invalid()
  // A well-formed token from another cursor version was genuinely issued by
  // this endpoint — the client did nothing wrong, it just cannot be continued.
  // Reporting it as expired lets the client recover by resyncing; a 400 would
  // repeat on every run and wedge that collection for good.
  if (body.v !== VERSION) throw new SyncCursorExpiredError()

  const { lo, hi, after } = body
  if (!isValidSnapshot(lo) || !isValidSnapshot(hi)) throw invalid()
  if (!(after === null || (typeof after === 'string' && DECIMAL.test(after) && BigInt(after) <= INT8_MAX))) {
    throw invalid()
  }
  // `after` only means something inside a batch, which needs its upper bound.
  if (after !== null && hi === null) throw invalid()

  return { lo, hi, after: after === null ? null : BigInt(after) }
}

/** The window for a first sync: nothing seen yet, no batch started. */
export const INITIAL_WINDOW = Object.freeze({ lo: null, hi: null, after: null })

/**
 * Splits an over-fetched batch page into the page plus `hasNext`, and builds
 * the cursor to resume from.
 *
 * `rows` are `{ id, syncSeq }` from the window query, ascending by `syncSeq`,
 * `take` = `limit + 1`. When the batch has more rows, the next cursor stays in
 * the same batch after the last row returned. When it is exhausted, the next
 * cursor opens the following batch from this batch's upper snapshot — so a
 * client that has "nothing new" still advances, and never re-reads.
 */
export function page(rows, limit, window) {
  const hasNext = rows.length > limit
  const data = hasNext ? rows.slice(0, limit) : rows
  const nextCursor = hasNext
    ? encodeCursor({ lo: window.lo, hi: window.hi, after: data.at(-1).syncSeq })
    : encodeCursor({ lo: window.hi, hi: null, after: null })
  return { data, hasNext, nextCursor }
}
