import { prisma } from '../../shared/prismaClient.js'

const db = (client) => client ?? prisma
// `customer.customerProfile` surfaces the Customer's Full Name (BDR-018) to
// a Hotel Manager viewing a Booking — booking.mapper.js#toBooking reads it.
const includeDetails = { hall: true, hotel: true, review: true, customer: { include: { customerProfile: true } } }

/**
 * Popular Hotels (Customer Mobile, Hotel Management's own read model) —
 * a single database-side GROUP BY per qualifying status, never a per-Hotel
 * query and never every Booking loaded into memory. `dateField` is whichever
 * timestamp represents "when this Booking most recently entered `status`"
 * (no dedicated confirmedAt column exists — CONFIRMED's own updatedAt is
 * the closest authoritative signal Prisma's @updatedAt already maintains;
 * COMPLETED has its own explicit completedAt).
 */
export function aggregateQualifyingBookingCountsByHotel({ status, dateField, since }) {
  return prisma.booking.groupBy({
    by: ['hotelId'],
    where: { status, [dateField]: { gte: since } },
    _count: { _all: true },
    _max: { [dateField]: true },
    orderBy: { hotelId: 'asc' },
  })
}

export function findCustomer(userId, client) {
  return db(client).user.findFirst({ where: { id: userId, accountType: 'CUSTOMER', deletedAt: null } })
}

export function findHallWithHotel(hallId, client) {
  return db(client).hall.findFirst({ where: { id: hallId, deletedAt: null }, include: { hotel: true } })
}

export function create(data, client) {
  return db(client).booking.create({ data, include: includeDetails })
}

export function findForCustomer(id, customerUserId, client) {
  return db(client).booking.findFirst({ where: { id, customerUserId }, include: includeDetails })
}

export function findForHotel(id, hotelId, client) {
  return db(client).booking.findFirst({ where: { id, hotelId }, include: includeDetails })
}

export function update(id, data, client) {
  return db(client).booking.update({ where: { id }, data, include: includeDetails })
}

/**
 * `updateManyAndReturn`, not `updateMany` — the caller (booking.service.js)
 * needs the actually-expired rows, with their Hall/Hotel relations, to fire
 * the Booking-expired Notification (Notification V1, C8) exactly once per
 * newly-expired Booking. No separate "was this already notified" flag is
 * needed: the `status: 'PENDING'` guard below means a row can only ever be
 * matched and returned by whichever caller's sweep reaches it first, the
 * same guard every other lifecycle transition in this module already
 * relies on for idempotency.
 *
 * Deliberately `{ hall: true, hotel: true }`, not the full `includeDetails`
 * — Prisma's `updateManyAndReturn` output type only supports a row's own
 * forward relations, never a one-to-one back-relation like `review`.
 */
export function expireOverdue(where, now = new Date(), client) {
  return db(client).booking.updateManyAndReturn({
    where: { ...where, status: 'PENDING', paymentDeadlineAt: { lte: now }, paymentStatus: { not: 'PAID' } },
    data: { status: 'EXPIRED' },
    include: { hall: true, hotel: true },
  })
}

/**
 * Completes Bookings whose event ended longer ago than the No-show grace
 * window — the counterpart to `expireOverdue` above, for the other end of the
 * lifecycle. Without it a CONFIRMED Booking never finishes on its own: it
 * waits indefinitely on a Manager remembering to tap Complete, and the
 * Customer's review (which requires COMPLETED) stays out of reach.
 *
 * `updateMany`, not `updateManyAndReturn` — unlike expiry, COMPLETED has no
 * Notification Catalog entry (booking.service.js#transitionHotel), so nothing
 * needs the affected rows back. The `status: 'CONFIRMED'` guard makes this
 * idempotent: a row can only be matched by whichever sweep reaches it first.
 */
export function completeEnded(where, now, graceMs, client) {
  return db(client).booking.updateMany({
    where: { ...where, status: 'CONFIRMED', endsAt: { lte: new Date(now.getTime() - graceMs) } },
    data: { status: 'COMPLETED', completedAt: now },
  })
}

export function listForCustomer({ customerUserId, cursor, take }) {
  return prisma.booking.findMany({
    where: { customerUserId }, include: includeDetails, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take,
    ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
  })
}

export function listForHotel({ hotelId, status, cursor, take }) {
  return prisma.booking.findMany({
    where: { hotelId, ...(status ? { status } : {}) }, include: includeDetails,
    orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take,
    ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
  })
}

/**
 * Manager Dashboard Overview — three database-side aggregates, never every
 * Booking loaded into memory just to count/sum it. Revenue counts only
 * `CONFIRMED`/`COMPLETED` Bookings (an actual, materialized rent charge) —
 * never `PENDING` (not yet earned) or a terminal non-charge status
 * (`REJECTED`/`CANCELLED`/`NO_SHOW`/`EXPIRED`).
 */
export async function getSummary({ hotelId }) {
  const [totalBookings, revenue, pendingCount] = await Promise.all([
    prisma.booking.count({ where: { hotelId } }),
    prisma.booking.aggregate({ where: { hotelId, status: { in: ['CONFIRMED', 'COMPLETED'] } }, _sum: { totalRentCents: true } }),
    prisma.booking.count({ where: { hotelId, status: 'PENDING' } }),
  ])
  return { totalBookings, totalRevenueCents: revenue._sum.totalRentCents ?? 0, pendingCount }
}
