import { logger } from '../../config/logger.js'

export function recordBookingAudit(action, { bookingId, actorUserId, details } = {}) {
  logger.info('booking_management_audit_event', {
    module: 'bookings', action, bookingId, actorUserId, details, timestamp: new Date().toISOString(),
  })
}
