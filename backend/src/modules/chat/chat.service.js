import * as repository from './chat.repository.js'
import * as notificationEvents from '../notifications/notification.events.js'
import { NotFoundError } from '../../shared/errors/errorTypes.js'

/**
 * Communication V1 (approved Business Specification §"Communication V1").
 * `assertParticipant` is the single choke point every route in this module
 * calls before touching a message row (Technical Design "Authorization &
 * Tenant Isolation") — true iff the caller is the Booking's own Customer or
 * the Booking's Hotel's own Manager; a 404 (never 403 — matching this
 * codebase's existing cross-tenant convention of not confirming a resource
 * exists to someone who can't see it) otherwise.
 */
async function assertParticipant(bookingId, userId) {
  const booking = await repository.findBookingForParticipant(bookingId)
  if (!booking) throw new NotFoundError('Booking not found.')
  const isCustomer = booking.customerUserId === userId
  const isManager = booking.hotel.registeredByUserId === userId
  if (!isCustomer && !isManager) throw new NotFoundError('Booking not found.')
  return booking
}

export async function sendMessage({ bookingId, senderUserId, body }) {
  const booking = await assertParticipant(bookingId, senderUserId)
  const message = await repository.create({ bookingId, senderUserId, body })
  // Fire-and-forget-after-persist, same shape every other Notification
  // Catalog trigger already uses (Business Rule 9/19) — a push failure can
  // never block or roll back the message that already exists.
  await notificationEvents.onChatMessageSent(message, booking)
  return message
}

export async function listForBooking({ bookingId, userId, cursor, limit }) {
  await assertParticipant(bookingId, userId)
  const rows = await repository.listForBooking({ bookingId, cursor, take: limit + 1 })
  const hasNext = rows.length > limit
  const messages = hasNext ? rows.slice(0, limit) : rows
  return { messages, hasNext, nextCursor: hasNext ? messages.at(-1).id : null }
}

export async function markConversationRead({ bookingId, userId }) {
  await assertParticipant(bookingId, userId)
  return repository.markOthersReadInBooking({ bookingId, readerUserId: userId })
}

export function unreadCountForUser(userId) {
  return repository.countUnreadForUser(userId)
}
