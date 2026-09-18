/**
 * No `bookingId` in the public shape — the caller already knows which
 * Booking's conversation they're reading (it's in the URL), the same
 * omit-the-obvious convention `notification.mapper.js` already follows.
 */
export function toChatMessage(message) {
  return {
    id: message.id,
    senderUserId: message.senderUserId,
    body: message.body,
    readAt: message.readAt,
    createdAt: message.createdAt,
  }
}
