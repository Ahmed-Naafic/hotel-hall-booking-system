import { toPublicHotel, toPublicApplication } from '../hotels/hotel.mapper.js'
import { toPublicHall } from '../halls/hall.mapper.js'
import { toPublicHotelMedia } from '../hotels/media.mapper.js'
import { toPublicHallMedia } from '../halls/media.mapper.js'
import { toManagerAvailabilityBlock } from '../availability/availability.mapper.js'
import { toBooking } from '../bookings/booking.mapper.js'
import { toNotification } from '../notifications/notification.mapper.js'

/**
 * Data-shape translation (naming-conventions.md §6) — Prisma result → sync
 * response.
 *
 * **Sync returns the same shape the REST endpoints already return.** Each
 * collection reuses its own module's existing mapper rather than shipping the
 * raw row, for three reasons found while wiring the first client:
 *
 *   1. **The client cannot derive a media URL.** `toPublicHall`/`toPublicHotel`
 *      build each photo's public URL from `storagePath` via the storage
 *      provider; a device does not know the bucket host. A raw row would have
 *      left every replicated Hall with no photos.
 *   2. **A raw row silently degrades.** `Hall.fromJson` reads a nested
 *      `bookingTerms`, which the mapper composes from flat columns. Parsing a
 *      raw row yields an empty object rather than an error — the worst failure
 *      mode, because nothing reports it.
 *   3. **Otherwise every mapper would be reimplemented per platform**, three
 *      times, and drift from the server's.
 *
 * `syncSeq` is added alongside the mapped body: the client needs it to order
 * rows locally, and it is the one field no business mapper knows about.
 */

const mappers = {
  hotel: toPublicHotel,
  hall: toPublicHall,
  hotelMedia: toPublicHotelMedia,
  hallMedia: toPublicHallMedia,
  availabilityBlock: toManagerAvailabilityBlock,
  booking: toBooking,
  notification: toNotification,
  hotelApplication: toPublicApplication,
}

/** Converts the types JSON cannot carry. `syncSeq` is a BIGINT; dates are Dates. */
function toJsonSafe(value) {
  if (typeof value === 'bigint') return String(value)
  if (value instanceof Date) return value.toISOString()
  if (Array.isArray(value)) return value.map(toJsonSafe)
  if (value !== null && typeof value === 'object') {
    // Prisma's Decimal — duck-typed, so this mapper needs no dependency on the
    // generated client.
    if (typeof value.toFixed === 'function' && typeof value.toNumber === 'function') {
      return value.toString()
    }
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, toJsonSafe(v)]))
  }
  return value
}

/** One row, in its module's own response shape, plus its sync ordering key. */
export function toSyncRow(collection, row) {
  const map = mappers[collection]
  if (!map) {
    throw new Error(`No mapper registered for sync collection "${collection}".`)
  }
  return toJsonSafe({ ...map(row), syncSeq: row.syncSeq })
}

export function toSyncData({ collection, data, deleted, scopeId, serverTime }) {
  return {
    changed: data.map((row) => toSyncRow(collection, row)),
    // Ids only: a tombstone carries no payload, and the client already holds
    // whatever it is about to drop.
    deleted,
    scopeId,
    serverTime,
  }
}
