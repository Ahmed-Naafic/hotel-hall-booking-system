import { prisma } from '../../shared/prismaClient.js'
import { since } from './sync.cursor.js'

/**
 * The only place Prisma Client is called for synchronization
 * (coding-standards.md §5). No business logic — takes an already-proven scope,
 * runs a query, returns rows.
 *
 * Every function here shares one shape: the caller's scope predicate, `AND
 * sync_seq > :cursor`, ordered ascending by `sync_seq`, `take` = `limit + 1`.
 * `syncSeq` is unique database-wide so the ordering is total and needs no
 * tiebreaker.
 *
 * Two deliberate properties, both structural rather than conventional:
 *
 *   - **The scope arrives as ids.** No function takes a `hotelId` a client
 *     supplied; `hotelIds` has already been resolved from `req.identity` by
 *     `sync.scope.js`.
 *   - **An empty scope narrows to nothing.** `{ in: [] }` matches no row, so a
 *     Manager with no Hotel gets an empty page rather than the whole table.
 *
 * Tombstoned rows are *not* filtered out — the caller separates them, because a
 * deletion is a change a replica has to be told about.
 */

/** The shared ordering/limit clause, so no query here can drift from the others. */
function scan(take) {
  return { orderBy: { syncSeq: 'asc' }, take }
}

export function hotels({ hotelIds, cursor, take }) {
  return prisma.hotel.findMany({
    where: { id: { in: hotelIds }, ...since(cursor) },
    ...scan(take),
  })
}

export function halls({ hotelIds, cursor, take }) {
  return prisma.hall.findMany({
    where: { hotelId: { in: hotelIds }, ...since(cursor) },
    ...scan(take),
  })
}

export function hotelMedia({ hotelIds, cursor, take }) {
  return prisma.hotelMedia.findMany({
    where: { hotelId: { in: hotelIds }, ...since(cursor) },
    ...scan(take),
  })
}

export function hallMedia({ hotelIds, cursor, take }) {
  return prisma.hallMedia.findMany({
    // Scoped through the Hall's owning Hotel, never a `hallId` from the client.
    where: { hall: { hotelId: { in: hotelIds } }, ...since(cursor) },
    ...scan(take),
  })
}

export function availabilityBlocks({ hotelIds, cursor, take }) {
  return prisma.hallAvailabilityBlock.findMany({
    where: { hall: { hotelId: { in: hotelIds } }, ...since(cursor) },
    ...scan(take),
  })
}

/**
 * Booking columns replicated to a Manager's device — an explicit allowlist, not
 * the whole row and no relations.
 *
 * `fullName`/`mobileNumber` are deliberately absent: `mobileNumber` is
 * Restricted (`data-architecture.md` §13, `BR-AUTH-02`) and no approved rule
 * covers holding it on a device. `customerUserId` is kept so Manager Mobile can
 * fetch contact details from the existing Booking endpoint when a Manager opens
 * one. Local-First Technical Design §5, business decision #3.
 */
const BOOKING_FIELDS = {
  id: true,
  syncSeq: true,
  customerUserId: true,
  hotelId: true,
  hallId: true,
  startsAt: true,
  endsAt: true,
  numberOfGuests: true,
  eventType: true,
  specialRequest: true,
  status: true,
  paymentStatus: true,
  paymentDeadlineAt: true,
  totalRentCents: true,
  advancePercentSnapshot: true,
  requiredAdvanceCents: true,
  reportedAmountCents: true,
  paymentReportedAt: true,
  paymentVerifiedAt: true,
  paymentRejectionReason: true,
  cancelledAt: true,
  cancellationReason: true,
  completedAt: true,
  createdAt: true,
  updatedAt: true,
}

export function bookings({ hotelIds, cursor, take }) {
  return prisma.booking.findMany({
    where: { hotelId: { in: hotelIds }, ...since(cursor) },
    ...scan(take),
    select: BOOKING_FIELDS,
  })
}

export function notifications({ recipientUserId, cursor, take }) {
  return prisma.notification.findMany({
    // Recipient, not Hotel: a Notification belongs to a person, and a Manager
    // must never receive one addressed to anybody else.
    where: { recipientUserId, ...since(cursor) },
    ...scan(take),
  })
}

export function hotelApplications({ hotelIds, cursor, take }) {
  return prisma.hotelApplication.findMany({
    where: { hotelId: { in: hotelIds }, ...since(cursor) },
    ...scan(take),
  })
}
