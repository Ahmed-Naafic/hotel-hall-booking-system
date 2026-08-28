import { logger } from '../../config/logger.js'

/**
 * Audit integration (Technical Design §13, WBS-11). No approved module owns
 * a persisted Audit Record entity (Technical Design §18 Item 4, inherited
 * from Module 1's own Technical Design §17 Item 4) — inventing one here
 * would mean this module unilaterally claiming ownership of a project-wide
 * gap it doesn't own. Audit events are therefore recorded as structured log
 * entries via the project's existing, already-approved logger (Winston,
 * ADR-0002), not a new database table — consistent with how this module's
 * Technical Design already treats audit as a cross-cutting participation,
 * not an owned entity.
 */
export function recordAuditEvent(action, { hotelId, actorUserId, details } = {}) {
  logger.info('hotel_management_audit_event', {
    module: 'hotels',
    action,
    hotelId,
    actorUserId,
    details,
    timestamp: new Date().toISOString(),
  })
}
