import * as lifecycleService from './lifecycle.service.js'
import { recordAuditEvent } from './audit.js'
import * as notificationEvents from '../notifications/notification.events.js'

/**
 * Suspension / Restriction Component (Technical Design §3, §9) —
 * suspension and deactivation (BR-HOTEL-09), reactivation out of either,
 * and restriction triggered by invalid required information (BR-HOTEL-10).
 *
 * Suspension, deactivation, and reactivation are fully specified and
 * implemented below. Restriction's *detection mechanism* (what makes
 * information "invalid," and what triggers the check) is Pending Business
 * Decision #4 — genuinely undefined. This component provides the
 * transition capability only (restrictHotel/resolveRestriction, callable
 * through the same Module-13-authorized interface as suspension); it does
 * not invent an automatic detector or a resolution workflow.
 */

/** Only reachable through Module 13's own, separately-authorized interface (BR-HOTEL-09, BR-HOTEL-14). */
export async function suspendHotel(hotel, decidedByUserId) {
  const updated = await lifecycleService.transition(hotel, 'SUSPENDED')
  recordAuditEvent('HOTEL_SUSPENDED', { hotelId: hotel.id, actorUserId: decidedByUserId })
  await notificationEvents.onHotelSuspended(updated)
  return updated
}

export async function deactivateHotel(hotel, decidedByUserId) {
  const updated = await lifecycleService.transition(hotel, 'DEACTIVATED')
  recordAuditEvent('HOTEL_DEACTIVATED', { hotelId: hotel.id, actorUserId: decidedByUserId })
  await notificationEvents.onHotelDeactivated(updated)
  return updated
}

/** Reactivation out of SUSPENDED or DEACTIVATED (BDR-012) — both are reversible, not permanent. */
export async function reactivateHotel(hotel, decidedByUserId) {
  const updated = await lifecycleService.transition(hotel, 'APPROVED_ACTIVE')
  recordAuditEvent('HOTEL_REACTIVATED', { hotelId: hotel.id, actorUserId: decidedByUserId })
  await notificationEvents.onHotelReactivated(updated)
  return updated
}

/**
 * Restriction — the trigger condition and caller are undefined (Pending
 * Business Decision #4); this transition exists so a future decision can
 * be wired to it without redesigning this component.
 */
export async function restrictHotel(hotel, actorUserId) {
  const updated = await lifecycleService.transition(hotel, 'RESTRICTED_UNDER_REVIEW')
  recordAuditEvent('HOTEL_RESTRICTED', { hotelId: hotel.id, actorUserId })
  return updated
}

/** Resolution path — also Pending Business Decision #4; see above. */
export async function resolveRestriction(hotel, actorUserId) {
  const updated = await lifecycleService.transition(hotel, 'APPROVED_ACTIVE')
  recordAuditEvent('HOTEL_RESTRICTION_RESOLVED', { hotelId: hotel.id, actorUserId })
  return updated
}
