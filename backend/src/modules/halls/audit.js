import { logger } from '../../config/logger.js'

/**
 * Audit integration (Technical Design §13, Implementation Plan WBS-07). No
 * approved module owns a persisted Audit Record entity (Technical Design
 * §18 Item 3, inherited from Hotel Management's and Module 1's own
 * Technical Designs) — inventing one here would mean this module
 * unilaterally claiming ownership of a project-wide gap it doesn't own.
 * Audit events are recorded as structured log entries via the project's
 * existing, already-approved logger (Winston, ADR-0002), the identical
 * mechanism `backend/src/modules/hotels/audit.js` already uses.
 */
export function recordAuditEvent(action, { hallId, hotelId, actorUserId, details } = {}) {
  logger.info('hall_management_audit_event', {
    module: 'halls',
    action,
    hallId,
    hotelId,
    actorUserId,
    details,
    timestamp: new Date().toISOString(),
  })
}
