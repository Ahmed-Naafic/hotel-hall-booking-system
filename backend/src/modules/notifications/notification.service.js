import * as repository from './notification.repository.js'
import { pushProvider } from '../../shared/providers/pushProvider.js'
import { logger } from '../../config/logger.js'
import { NotFoundError } from '../../shared/errors/errorTypes.js'

/**
 * Notification Management (Notification V1, approved Business Specification
 * §"Business Rules"). `notify()` is the single entry point every other
 * module's business event calls into (`notification.events.js`) — it never
 * throws back to its caller (Rule 19: a push failure must never roll back
 * the business operation that already happened), because the only part it
 * awaits is the DB persist (Rule 2/13: the Notification is the source of
 * truth and must exist before anything else happens to it); push delivery
 * (Rule 14/15: best-effort, never source of truth) is fired afterward
 * without being awaited, so a slow or failing push provider can never delay
 * or fail the HTTP response of the business operation that triggered it.
 */
export async function notify({ recipientUserId, type, title, body, bookingId, hotelId, hotelApplicationId }) {
  const notification = await repository.create({ recipientUserId, type, title, body, bookingId, hotelId, hotelApplicationId })
  deliverPush(notification).catch((err) => {
    logger.error('[notifications] push delivery failed', { notificationId: notification.id, error: err.message })
  })
  return notification
}

/** FCM error codes meaning the token itself is permanently dead (uninstalled,
 *  cleared app data, or never valid) — see admin.messaging()'s documented
 *  error codes. Any other failure (network, quota, malformed payload) leaves
 *  the token in place: it may well still be good next time. */
const DEAD_TOKEN_ERROR_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
])

async function deliverPush(notification) {
  const tokens = await repository.listDeviceTokensForUser(notification.recipientUserId)
  await Promise.all(
    tokens.map(async (deviceToken) => {
      try {
        await pushProvider.sendPush({
          deviceToken: deviceToken.token,
          title: notification.title,
          body: notification.body,
          data: {
            notificationId: notification.id,
            type: notification.type,
            ...(notification.bookingId ? { bookingId: notification.bookingId } : {}),
            ...(notification.hotelId ? { hotelId: notification.hotelId } : {}),
            ...(notification.hotelApplicationId ? { hotelApplicationId: notification.hotelApplicationId } : {}),
          },
        })
      } catch (err) {
        // A dead token will fail forever otherwise, growing the fan-out on
        // every future Notification for this recipient — prune it, but only
        // for the specific error that actually means "this token is gone."
        if (DEAD_TOKEN_ERROR_CODES.has(err.cause?.code)) {
          await repository.deleteDeviceToken(deviceToken.token)
        }
        throw err
      }
    }),
  )
}

export async function listForUser({ recipientUserId, status, cursor, limit }) {
  const rows = await repository.listForUser({ recipientUserId, status, cursor, take: limit + 1 })
  const hasNext = rows.length > limit
  const notifications = hasNext ? rows.slice(0, limit) : rows
  return { notifications, hasNext, nextCursor: hasNext ? notifications.at(-1).id : null }
}

export function unreadCountForUser(recipientUserId) {
  return repository.countUnreadForUser(recipientUserId)
}

export async function markRead({ id, recipientUserId }) {
  const existing = await repository.findByIdForUser(id, recipientUserId)
  if (!existing) throw new NotFoundError('Notification not found.')
  if (existing.status === 'READ') return existing
  return repository.markRead(id)
}

export function markAllRead(recipientUserId) {
  return repository.markAllReadForUser(recipientUserId)
}

export function registerDeviceToken({ userId, token, platform }) {
  return repository.upsertDeviceToken({ userId, token, platform })
}

export function unregisterDeviceToken(token) {
  return repository.deleteDeviceToken(token)
}
