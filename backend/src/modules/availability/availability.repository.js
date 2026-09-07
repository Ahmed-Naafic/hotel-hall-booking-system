import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for the HallAvailabilityBlock
 * entity (coding-standards.md §5). No business logic — takes parameters,
 * runs a query, returns data. Every mutating function accepts an optional
 * `client` (a `prisma.$transaction` callback's client) so the service layer
 * can run the overlap pre-check and the write atomically, the same
 * convention `hotels/application.repository.js` already uses.
 */

function db(client) {
  return client ?? prisma
}

export function create({ hallId, startsAt, endsAt, reason, createdByUserId }, client) {
  return db(client).hallAvailabilityBlock.create({
    data: { hallId, startsAt, endsAt, reason: reason ?? null, createdByUserId },
  })
}

export function findByIdForHall(id, hallId, client) {
  return db(client).hallAvailabilityBlock.findFirst({ where: { id, hallId } })
}

export function update(id, { startsAt, endsAt, reason }, client) {
  return db(client).hallAvailabilityBlock.update({
    where: { id },
    data: { startsAt, endsAt, reason },
  })
}

export function deleteById(id, client) {
  return db(client).hallAvailabilityBlock.delete({ where: { id } })
}

/** Every block for one Hall whose period intersects [rangeStart, rangeEnd) — the day-view query. */
export function listForHallInRange({ hallId, rangeStart, rangeEnd }, client) {
  return db(client).hallAvailabilityBlock.findMany({
    where: { hallId, startsAt: { lt: rangeEnd }, endsAt: { gt: rangeStart } },
    orderBy: { startsAt: 'asc' },
  })
}

/**
 * Whether any existing block for this Hall overlaps [startsAt, endsAt) —
 * the same `starts_at < :end AND ends_at > :start` predicate as
 * `listForHallInRange`, narrowed to a single period and (on edit) excluding
 * the block being edited from the comparison against itself.
 */
export async function hasOverlap({ hallId, startsAt, endsAt, excludeId }, client) {
  const match = await db(client).hallAvailabilityBlock.findFirst({
    where: {
      hallId,
      startsAt: { lt: endsAt },
      endsAt: { gt: startsAt },
      ...(excludeId ? { id: { not: excludeId } } : {}),
    },
    select: { id: true },
  })
  return match !== null
}

export function listBlockingBookingsForHallInRange({ hallId, rangeStart, rangeEnd }, client) {
  return db(client).booking.findMany({
    where: {
      hallId,
      status: { in: ['PENDING', 'CONFIRMED'] },
      startsAt: { lt: rangeEnd },
      endsAt: { gt: rangeStart },
    },
    select: { startsAt: true, endsAt: true },
    orderBy: { startsAt: 'asc' },
  })
}

export async function hasBlockingBookingOverlap({ hallId, startsAt, endsAt, excludeBookingId }, client) {
  const match = await db(client).booking.findFirst({
    where: {
      hallId,
      status: { in: ['PENDING', 'CONFIRMED'] },
      startsAt: { lt: endsAt },
      endsAt: { gt: startsAt },
      ...(excludeBookingId ? { id: { not: excludeBookingId } } : {}),
    },
    select: { id: true },
  })
  return match !== null
}

/**
 * `updateManyAndReturn`, not `updateMany` — the caller (availability.service.js)
 * fires the Booking-expired Notification (Notification V1, C8) for each row
 * actually returned here. This is a genuinely separate lazy-expiration
 * sweep from `booking.repository.js#expireOverdue` (pre-existing
 * duplication, not introduced by Notification V1 — see that module's own
 * Technical Design "Idempotency"), so both must be able to trigger the
 * Notification; the shared `status: 'PENDING'` guard means only whichever
 * sweep reaches a given row first can ever match and return it, preventing
 * a duplicate regardless of which path catches it.
 */
export function expireOverdueBookings({ hallId, now }, client) {
  return db(client).booking.updateManyAndReturn({
    where: {
      hallId,
      status: 'PENDING',
      paymentDeadlineAt: { lte: now },
      paymentStatus: { not: 'PAID' },
    },
    data: { status: 'EXPIRED' },
    include: { hall: true, hotel: true },
  })
}
