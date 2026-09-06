import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for Review — no business logic
 * (coding-standards.md §5).
 */

export function findByBookingId(bookingId) {
  return prisma.review.findUnique({ where: { bookingId } })
}

export function create({ bookingId, customerUserId, hotelId, rating, text }) {
  return prisma.review.create({
    data: { bookingId, customerUserId, hotelId, rating, text: text ?? null },
  })
}

export function listForHotel({ hotelId, cursor, take }) {
  return prisma.review.findMany({
    where: { hotelId },
    orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    take,
    ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
  })
}

/** A single database-side aggregate — never every Review loaded into memory. */
export function aggregateForHotel(hotelId) {
  return prisma.review.aggregate({
    where: { hotelId },
    _avg: { rating: true },
    _count: { _all: true },
  })
}
