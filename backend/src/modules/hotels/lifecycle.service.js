import * as hotelRepository from './hotel.repository.js'
import { ConflictError } from '../../shared/errors/errorTypes.js'

/**
 * Lifecycle (State) Component (Technical Design §3, §6) — the single
 * arbiter of every Hotel status transition. No other component in this
 * module mutates Hotel.status directly (architecture-principles.md §4).
 *
 * The transition map below extends Technical Design §6.2's table with a
 * Platform-Administrator-triggered reactivation path out of SUSPENDED and
 * DEACTIVATED back to APPROVED_ACTIVE — both are reversible administrative
 * actions, not permanent ones (BDR-012). No exit from WITHDRAWN remains a
 * deliberate omission (Technical Design §6): a withdrawn application is
 * resubmitted from REGISTERED/PROFILE_COMPLETE via a brand-new application,
 * never reopened in place.
 */
const VALID_TRANSITIONS = {
  REGISTERED: ['PROFILE_COMPLETE'],
  PROFILE_COMPLETE: ['UNDER_REVIEW'],
  UNDER_REVIEW: ['APPROVED_ACTIVE', 'REJECTED', 'WITHDRAWN'],
  APPROVED_ACTIVE: ['SUSPENDED', 'DEACTIVATED', 'RESTRICTED_UNDER_REVIEW'],
  REJECTED: ['UNDER_REVIEW'],
  RESTRICTED_UNDER_REVIEW: ['APPROVED_ACTIVE'],
  WITHDRAWN: [],
  SUSPENDED: ['APPROVED_ACTIVE'],
  DEACTIVATED: ['APPROVED_ACTIVE'],
}

export function isValidTransition(fromStatus, toStatus) {
  return Boolean(VALID_TRANSITIONS[fromStatus]?.includes(toStatus))
}

/**
 * Applies a status transition to a Hotel, or throws 409 if the transition
 * isn't valid from the Hotel's current status (Technical Design §16).
 * Callers pass the Hotel record they already loaded, not just an id, so
 * this never has to re-fetch to know the current status.
 */
export async function transition(hotel, toStatus, { client } = {}) {
  if (!isValidTransition(hotel.status, toStatus)) {
    throw new ConflictError(
      `Cannot move a Hotel from ${hotel.status} to ${toStatus}.`,
    )
  }
  return hotelRepository.updateStatus(hotel.id, toStatus, client)
}
