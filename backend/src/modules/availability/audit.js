import { logger } from '../../config/logger.js'

/**
 * Audit integration — structured log entries via the project's existing
 * logger (Winston), the identical mechanism `halls/audit.js` and
 * `hotels/audit.js` already use. No persisted Audit Record entity is
 * invented here.
 */
export function recordAuditEvent(action, { blockId, hallId, hotelId, actorUserId, details } = {}) {
  logger.info('availability_audit_event', {
    module: 'availability',
    action,
    blockId,
    hallId,
    hotelId,
    actorUserId,
    details,
    timestamp: new Date().toISOString(),
  })
}
