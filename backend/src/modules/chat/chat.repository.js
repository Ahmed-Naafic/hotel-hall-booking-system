import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for ChatMessage — no business logic
 * (coding-standards.md §5). `findBookingForParticipant` reaches into the
 * `booking`/`hotel` tables directly (never through `bookings`' own exported
 * functions) the same pragmatic way `notification.repository.js#
 * listPlatformAdministratorIds` already reaches into `user` — a minimal,
 * read-only projection, not a re-implementation of Booking Management's own
 * logic.
 */

export function findBookingForParticipant(bookingId) {
  return prisma.booking.findUnique({
    where: { id: bookingId },
    select: { id: true, customerUserId: true, hotelId: true, hotel: { select: { registeredByUserId: true } } },
  })
}

export function create({ bookingId, senderUserId, body }) {
  return prisma.chatMessage.create({ data: { bookingId, senderUserId, body } })
}

/** Oldest first (Business Rule 6) — the opposite order from Notification's own list. */
export function listForBooking({ bookingId, cursor, take }) {
  return prisma.chatMessage.findMany({
    where: { bookingId },
    orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    take,
    ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
  })
}

/** Marks every message in this Booking sent by someone other than `readerUserId` read. */
export function markOthersReadInBooking({ bookingId, readerUserId }) {
  return prisma.chatMessage.updateMany({
    where: { bookingId, senderUserId: { not: readerUserId }, readAt: null },
    data: { readAt: new Date() },
  })
}

/**
 * Total unread messages across every Booking `userId` participates in
 * (Business Rule 8) — a second, independent badge source from Notification's
 * own unread count.
 */
export function countUnreadForUser(userId) {
  return prisma.chatMessage.count({
    where: {
      readAt: null,
      senderUserId: { not: userId },
      booking: { OR: [{ customerUserId: userId }, { hotel: { registeredByUserId: userId } }] },
    },
  })
}
