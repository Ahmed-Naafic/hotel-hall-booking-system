/**
 * Data-shape translation (naming-conventions.md §6) — Prisma result → sync
 * response.
 *
 * Two jobs, both structural rather than cosmetic:
 *
 *   1. **`syncSeq` never leaves as a number.** It is a PostgreSQL `BIGINT`,
 *      which Prisma surfaces as a JS `BigInt`, and `JSON.stringify` throws on
 *      one. Every row is serialised through here so a new collection cannot
 *      leak an unserialisable value and 500 the endpoint.
 *   2. **`Decimal` fields become strings.** `advancePercentSnapshot` is a
 *      Prisma `Decimal`; sending it as a float would silently change a money
 *      figure's precision.
 */

/** Recursively converts the types JSON cannot carry, leaving everything else alone. */
function toJsonSafe(value) {
  if (typeof value === 'bigint') {
    return String(value)
  }
  if (value instanceof Date) {
    return value.toISOString()
  }
  if (Array.isArray(value)) {
    return value.map(toJsonSafe)
  }
  // Prisma's Decimal — duck-typed rather than imported, so this mapper has no
  // dependency on the generated client.
  if (value !== null && typeof value === 'object') {
    if (typeof value.toFixed === 'function' && typeof value.toNumber === 'function') {
      return value.toString()
    }
    return Object.fromEntries(Object.entries(value).map(([key, inner]) => [key, toJsonSafe(inner)]))
  }
  return value
}

export function toSyncData({ data, deleted, scopeId, serverTime }) {
  return {
    changed: data.map(toJsonSafe),
    // Ids only: a tombstone carries no payload, and the client already holds
    // whatever it is about to drop.
    deleted,
    scopeId,
    serverTime,
  }
}
