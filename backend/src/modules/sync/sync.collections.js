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
 * Each entry declares, and nothing else:
 *
 *   - `accountTypes` — who may ask for it.
 *   - `scopeArgs` — how the resolved scope maps onto the repository's window
 *     query for that collection (which owns the scope predicate itself), so a
 *     collection cannot accidentally be scoped by the wrong key.
 *   - optionally `prepare` — work that must happen before a batch is opened.
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
const NEVER_DELETED = new Set(['booking', 'notification', 'hotelApplication', 'chatMessage'])

export const collections = {
  hotel: { accountTypes: [HOTEL_MANAGER], scopeArgs: byOwnedHotels },
  hall: { accountTypes: [HOTEL_MANAGER], scopeArgs: byOwnedHotels },
  hotelMedia: { accountTypes: [HOTEL_MANAGER], scopeArgs: byOwnedHotels },
  hallMedia: { accountTypes: [HOTEL_MANAGER], scopeArgs: byOwnedHotels },
  availabilityBlock: {
    accountTypes: [HOTEL_MANAGER],
    scopeArgs: byOwnedHotels,
  },
  booking: {
    accountTypes: [HOTEL_MANAGER],
    scopeArgs: byOwnedHotels,
    /**
     * Brings the Hotel's Bookings up to date with the clock before scanning.
     *
     * `advanceLifecycle` expires overdue unpaid Bookings and completes ended
     * ones, and the server only does that when somebody reads. Without this a
     * replica holds Bookings stuck `PENDING` past `paymentDeadlineAt` until some
     * unrelated request happens to advance them. Once per *batch* — when a
     * batch opens, before its upper snapshot is taken, so the sweep's own
     * writes fall inside it — never per page. Outside any transaction: it fires
     * `BOOKING_EXPIRED` Notifications, which must not be rolled back.
     * Technical Design §12.
     */
    async prepare({ scope, advanceLifecycle }) {
      for (const hotelId of scope.hotelIds) {
        await advanceLifecycle({ hotelId })
      }
    },
  },
  notification: {
    accountTypes: [HOTEL_MANAGER],
    scopeArgs: byRecipient,
  },
  hotelApplication: {
    accountTypes: [HOTEL_MANAGER],
    scopeArgs: byOwnedHotels,
  },
  /**
   * The conversations on this Manager's own Hotels' Bookings. A Manager is a
   * participant in exactly those (`chat.service.js#assertParticipant`), so the
   * scope is the Booking's Hotel — never a `bookingId` the client supplies.
   */
  chatMessage: {
    accountTypes: [HOTEL_MANAGER],
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

/**
 * One page of one batch: the window query picks the rows, then they are
 * hydrated and split into live rows and tombstones. Paging (and the cursor) is
 * computed over the window rows, never the hydrated ones — a row written again
 * between the two queries hydrates with a newer `syncSeq`, and keying the
 * cursor off that would skip the rows in between.
 */
export async function fetchPage(name, { scope, window, limit }) {
  const definition = collections[name]
  const windowRows = await repository.windowRows(name, definition.scopeArgs(scope), window, limit + 1)
  const { data, hasNext, nextCursor } = page(windowRows, limit, window)
  const rows = await repository.hydrate(name, data.map((row) => row.id))
  return partition(name, { data: rows, hasNext, nextCursor })
}
