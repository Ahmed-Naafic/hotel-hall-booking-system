/**
 * Cursor arithmetic for every sync collection, in one place so no resolver
 * re-derives it (Local-First Synchronization Technical Design §7).
 *
 * The shape is always `sync_seq > :since ORDER BY sync_seq ASC LIMIT :n`.
 * `sync_seq` is unique across the whole database, so the ordering is total and
 * needs no tiebreaker — deliberately unlike the `createdAt`-ordered cursors
 * elsewhere, which required an `id` tiebreaker added after measurement showed
 * eight rows sharing a `created_at` returned seven at `limit=1`.
 */

/** `coding-standards.md` §6 — the same bounded default every list here uses. */
export const DEFAULT_LIMIT = 20
export const MAX_LIMIT = 100

/**
 * Splits an over-fetched page into the page itself plus `hasNext`, and reports
 * the cursor to resume from.
 *
 * `nextCursor` is the highest `syncSeq` **in the returned page**, never the
 * server clock and never a value derived from the request: a client that
 * advanced its mark past rows it had not received would skip them permanently.
 *
 * Rows are expected in ascending `syncSeq` order, `take` = `limit + 1`.
 */
export function page(rows, limit) {
  const hasNext = rows.length > limit
  const data = hasNext ? rows.slice(0, limit) : rows
  const last = data.at(-1)
  return {
    data,
    hasNext,
    // A `BigInt` cannot be serialised to JSON, and the cursor is opaque to the
    // client anyway, so it travels as a decimal string.
    nextCursor: last ? String(last.syncSeq) : null,
  }
}

/**
 * The `where` fragment a resolver spreads into its own scope predicate.
 * Absent `since` means initial sync, which is the same scan from zero rather
 * than a separate bootstrap path.
 */
export function since(cursor) {
  return cursor === undefined ? {} : { syncSeq: { gt: cursor } }
}
