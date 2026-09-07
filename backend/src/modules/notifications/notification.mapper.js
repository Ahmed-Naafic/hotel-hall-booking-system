/**
 * No `recipientUserId` in the public shape — the caller already knows who
 * they are; echoing their own id back teaches a client nothing and this
 * codebase's other mappers follow the same omit-the-obvious convention
 * (e.g. `booking.mapper.js` never echoes `customerUserId` back to the
 * Customer who owns it).
 */
export function toNotification(notification) {
  return {
    id: notification.id,
    type: notification.type,
    status: notification.status,
    title: notification.title,
    body: notification.body,
    bookingId: notification.bookingId,
    hotelId: notification.hotelId,
    hotelApplicationId: notification.hotelApplicationId,
    readAt: notification.readAt,
    createdAt: notification.createdAt,
  }
}
