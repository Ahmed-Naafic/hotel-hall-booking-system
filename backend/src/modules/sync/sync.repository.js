import { Prisma } from '../../generated/prisma/client.ts'
import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for synchronization
 * (coding-standards.md §5). No business logic — takes an already-proven scope,
 * runs a query, returns rows.
 *
 * Every collection is read in two steps:
 *
 *   1. **Window** — raw SQL, because Prisma cannot express snapshot visibility.
 *      Selects `(id, sync_seq)` for the rows in scope whose writer is visible in
 *      the batch's upper snapshot and not in its lower one, ascending by
 *      `sync_seq`, after the batch's keyset position (sync.cursor.js).
 *   2. **Hydrate** — ordinary Prisma, loading exactly the relations each
 *      module's existing mapper needs, for those ids only.
 *
 * Two deliberate properties, both structural rather than conventional:
 *
 *   - **The scope arrives as ids.** No function takes a `hotelId` a client
 *     supplied; `hotelIds` has already been resolved from `req.identity` by
 *     `sync.scope.js`.
 *   - **An empty scope narrows to nothing.** `= ANY('{}')` matches no row, so a
 *     Manager with no Hotel gets an empty page rather than the whole table.
 *
 * Tombstoned rows are *not* filtered out — the caller separates them, because a
 * deletion is a change a replica has to be told about.
 */

/** The snapshot every new batch is bounded by. Taken before the window query. */
export async function currentSnapshot() {
  const [{ snapshot }] = await prisma.$queryRaw`SELECT pg_current_snapshot()::text AS snapshot`
  return snapshot
}

/**
 * Per-collection scope predicates, over table names fixed here — never a name
 * or a fragment from a request. `hallMedia`/`availabilityBlock` are scoped
 * through the Hall's owning Hotel, never a `hallId` from the client.
 */
const WINDOWS = {
  hotel: { table: 'hotels', scope: ({ hotelIds }) => Prisma.sql`id = ANY(${hotelIds}::uuid[])` },
  hall: { table: 'halls', scope: ({ hotelIds }) => Prisma.sql`hotel_id = ANY(${hotelIds}::uuid[])` },
  hotelMedia: {
    table: 'hotel_media',
    scope: ({ hotelIds }) => Prisma.sql`hotel_id = ANY(${hotelIds}::uuid[])`,
  },
  hallMedia: {
    table: 'hall_media',
    scope: ({ hotelIds }) =>
      Prisma.sql`hall_id IN (SELECT id FROM halls WHERE hotel_id = ANY(${hotelIds}::uuid[]))`,
  },
  availabilityBlock: {
    table: 'hall_availability_blocks',
    scope: ({ hotelIds }) =>
      Prisma.sql`hall_id IN (SELECT id FROM halls WHERE hotel_id = ANY(${hotelIds}::uuid[]))`,
  },
  booking: { table: 'bookings', scope: ({ hotelIds }) => Prisma.sql`hotel_id = ANY(${hotelIds}::uuid[])` },
  // Recipient, not Hotel: a Notification belongs to a person, and a Manager
  // must never receive one addressed to anybody else.
  notification: {
    table: 'notifications',
    scope: ({ recipientUserId }) => Prisma.sql`recipient_user_id = ${recipientUserId}::uuid`,
  },
  hotelApplication: {
    table: 'hotel_applications',
    scope: ({ hotelIds }) => Prisma.sql`hotel_id = ANY(${hotelIds}::uuid[])`,
  },
  chatMessage: {
    table: 'chat_messages',
    scope: ({ hotelIds }) =>
      Prisma.sql`booking_id IN (SELECT id FROM bookings WHERE hotel_id = ANY(${hotelIds}::uuid[]))`,
  },
}

/**
 * One page of a batch: `(id, syncSeq)` ascending.
 *
 * - Upper bound: the writer is visible in `hi`. A NULL `sync_txid` predates the
 *   column and is visible in every snapshot.
 * - Lower bound: the writer was *not* visible in `lo`. A NULL `sync_txid` was
 *   therefore already delivered by any batch that has a `lo`.
 * - `after`: keyset position within this batch.
 */
export async function windowRows(collection, scopeArgs, { lo, hi, after }, take) {
  const { table, scope } = WINDOWS[collection]
  const lower = lo === null
    ? Prisma.empty
    : Prisma.sql`AND sync_txid IS NOT NULL AND NOT pg_visible_in_snapshot(sync_txid::text::xid8, ${lo}::pg_snapshot)`
  const keyset = after === null ? Prisma.empty : Prisma.sql`AND sync_seq > ${after}`

  const rows = await prisma.$queryRaw`
    SELECT id::text AS id, sync_seq AS "syncSeq"
      FROM ${Prisma.raw(`"${table}"`)}
     WHERE ${scope(scopeArgs)}
       AND (sync_txid IS NULL OR pg_visible_in_snapshot(sync_txid::text::xid8, ${hi}::pg_snapshot))
       ${lower}
       ${keyset}
     ORDER BY sync_seq ASC
     LIMIT ${take}
  `
  return rows.map((row) => ({ id: row.id, syncSeq: BigInt(row.syncSeq) }))
}

/**
 * Booking columns replicated to a Manager's device — an explicit allowlist, not
 * the whole row and no relations.
 *
 * `fullName`/`mobileNumber` are deliberately absent: customer contact details
 * are Confidential (`data-architecture.md` §13) and no approved rule covers
 * holding them on a device. `customerUserId` is kept so Manager Mobile can
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

// Each hydration loads exactly what its module's existing mapper needs, and
// nothing more. Sync returns the same shape the REST endpoints already return
// (see `sync.mapper.js`), so the relations the mappers read must be loaded here.
const HYDRATORS = {
  // `registeredBy` is deliberately not loaded, so `toPublicHotel` omits it. It
  // would put the Manager's mobile number on the device for no reader —
  // Manager Mobile takes its own identity from the session — and it could not
  // stay fresh: renaming a user bumps no Hotel row.
  hotel: (ids) =>
    prisma.hotel.findMany({
      where: { id: { in: ids } },
      include: { media: { where: { deletedAt: null }, orderBy: { createdAt: 'asc' } } },
    }),
  // `toPublicHall` derives each photo's public URL from its storagePath — the
  // client cannot do that itself, it does not know the bucket host.
  hall: (ids) =>
    prisma.hall.findMany({ where: { id: { in: ids } }, include: { media: { where: { deletedAt: null } } } }),
  hotelMedia: (ids) => prisma.hotelMedia.findMany({ where: { id: { in: ids } } }),
  hallMedia: (ids) => prisma.hallMedia.findMany({ where: { id: { in: ids } } }),
  availabilityBlock: (ids) => prisma.hallAvailabilityBlock.findMany({ where: { id: { in: ids } } }),
  // `select`, not `include`: omitting the `customer` relation is what keeps
  // contact details out. `toBooking` emits `customer` only when the relation is
  // loaded, so the mapper needs no special case and cannot be made to leak by
  // a later change here that does not also add the relation.
  booking: (ids) => prisma.booking.findMany({ where: { id: { in: ids } }, select: BOOKING_FIELDS }),
  notification: (ids) => prisma.notification.findMany({ where: { id: { in: ids } } }),
  hotelApplication: (ids) => prisma.hotelApplication.findMany({ where: { id: { in: ids } } }),
  chatMessage: (ids) => prisma.chatMessage.findMany({ where: { id: { in: ids } } }),
}

/**
 * Loads full rows for a window page, in the window's order.
 *
 * A row written again between the two queries hydrates as its newer version —
 * harmless, because that newer write also lands in the next batch and applying
 * a row twice is idempotent. A row hard-deleted in between (only by cascade) is
 * simply absent.
 */
export async function hydrate(collection, ids) {
  if (ids.length === 0) return []
  const rows = await HYDRATORS[collection](ids)
  const byId = new Map(rows.map((row) => [row.id, row]))
  return ids.map((id) => byId.get(id)).filter(Boolean)
}

export const WINDOW_COLLECTIONS = Object.keys(WINDOWS)
