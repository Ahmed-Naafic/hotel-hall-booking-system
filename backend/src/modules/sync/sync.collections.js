import * as repository from './sync.repository.js'
import { page } from './sync.cursor.js'

/**
 * The synchronizable collections (Local-First Synchronization Technical Design
 * §5, §6, §17).
 *
 * There is deliberately **no** generic `GET /sync/:table`. A collection exists
 * in this registry or it cannot be synchronized at all. `users`, `sessions`,
 * `verification_requests`, `password_reset_requests` and `device_tokens` are
 * absent because they are never replicated to a device.
 *
 * Each entry declares three things and nothing else:
 *
 *   - `accountTypes` — who may ask for it.
 *   - `fetch` — the repository query, which already carries the scope predicate.
 *   - `scopeArgs` — how the resolved scope maps onto that query's parameters, so
 *     a collection cannot accidentally be scoped by the wrong key.
 *
 * Phase 1 covers Manager Mobile's working set: one Hotel and everything under
 * it. Customer and public collections are Phase 2/3 and are intentionally not
 * registered, so no half-scoped resolver is reachable.
 */

const HOTEL_MANAGER = 'HOTEL_MANAGER'

/** Scoped by the Hotels the caller owns. */
const byOwnedHotels = (scope) => ({ hotelIds: scope.hotelIds })
/** Scoped by the caller themselves, for rows that belong to a person. */
const byRecipient = (scope) => ({ recipientUserId: scope.identity.userId })

/**
 * Tables that never delete a row, soft or otherwise. Listing them explicitly
 * rather than inferring from the absence of `deletedAt` means adding a
 * tombstone column to one of them cannot silently start hiding its rows.
 */
const NEVER_DELETED = new Set(['booking', 'notification', 'hotelApplication'])

export const collections = {
  hotel: { accountTypes: [HOTEL_MANAGER], fetch: repository.hotels, scopeArgs: byOwnedHotels },
  hall: { accountTypes: [HOTEL_MANAGER], fetch: repository.halls, scopeArgs: byOwnedHotels },
  hotelMedia: { accountTypes: [HOTEL_MANAGER], fetch: repository.hotelMedia, scopeArgs: byOwnedHotels },
  hallMedia: { accountTypes: [HOTEL_MANAGER], fetch: repository.hallMedia, scopeArgs: byOwnedHotels },
  availabilityBlock: {
    accountTypes: [HOTEL_MANAGER],
    fetch: repository.availabilityBlocks,
    scopeArgs: byOwnedHotels,
  },
  booking: {
    accountTypes: [HOTEL_MANAGER],
    fetch: repository.bookings,
    scopeArgs: byOwnedHotels,
    /**
     * Brings the Hotel's Bookings up to date with the clock before scanning.
     *
     * `advanceLifecycle` expires overdue unpaid Bookings and completes ended
     * ones, and the server only does that when somebody reads. Without this a
     * replica holds Bookings stuck `PENDING` past `paymentDeadlineAt` until some
     * unrelated request happens to advance them. Once per request, never per
     * page, and outside any transaction — it fires `BOOKING_EXPIRED`
     * Notifications, which must not be rolled back. Technical Design §12.
     */
    async prepare({ scope, advanceLifecycle }) {
      for (const hotelId of scope.hotelIds) {
        await advanceLifecycle({ hotelId })
      }
    },
  },
  notification: {
    accountTypes: [HOTEL_MANAGER],
    fetch: repository.notifications,
    scopeArgs: byRecipient,
  },
  hotelApplication: {
    accountTypes: [HOTEL_MANAGER],
    fetch: repository.hotelApplications,
    scopeArgs: byOwnedHotels,
  },
}

export const COLLECTION_NAMES = Object.keys(collections)

/**
 * Splits one page into live rows and tombstone ids. A soft-deleted row is
 * reported as `deleted` rather than filtered away, because absence is not
 * something a replica can detect.
 */
export function partition(name, { data, hasNext, nextCursor }) {
  if (NEVER_DELETED.has(name)) {
    return { data, deleted: [], hasNext, nextCursor }
  }
  const live = []
  const deleted = []
  for (const row of data) {
    if (row.deletedAt !== null && row.deletedAt !== undefined) {
      deleted.push(row.id)
    } else {
      live.push(row)
    }
  }
  return { data: live, deleted, hasNext, nextCursor }
}

/** Runs one collection's query and splits the result. */
export async function fetchPage(name, { scope, cursor, limit }) {
  const definition = collections[name]
  const rows = await definition.fetch({
    ...definition.scopeArgs(scope),
    cursor,
    take: limit + 1,
  })
  return partition(name, page(rows, limit))
}
