import * as hotelRepository from './hotel.repository.js'
import { ConflictError } from '../../shared/errors/errorTypes.js'

/**
 * Lifecycle (State) Component (Technical Design §3, §6) — the single
 * arbiter of every Hotel status transition. No other component in this
 * module mutates Hotel.status directly (architecture-principles.md §4).
 *
 * The transition map below is exactly Technical Design §6.2's table — no
 * transition exists here that isn't listed there. In particular, no
 * reactivation path out of SUSPENDED/DEACTIVATED, and no exit from
 * WITHDRAWN, are deliberate omissions (Technical Design §6), not bugs.
 */
const VALID_TRANSITIONS = {
  REGISTERED: ['PROFILE_COMPLETE'],
  PROFILE_COMPLETE: ['UNDER_REVIEW'],
  UNDER_REVIEW: ['APPROVED_ACTIVE', 'REJECTED', 'WITHDRAWN'],
  APPROVED_ACTIVE: ['SUSPENDED', 'DEACTIVATED', 'RESTRICTED_UNDER_REVIEW'],
  REJECTED: ['UNDER_REVIEW'],
  RESTRICTED_UNDER_REVIEW: ['APPROVED_ACTIVE'],
  WITHDRAWN: [],
  SUSPENDED: [],
  DEACTIVATED: [],
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
export async function transition(hotel, toStatus) {
  if (!isValidTransition(hotel.status, toStatus)) {
    throw new ConflictError(
      `Cannot move a Hotel from ${hotel.status} to ${toStatus}.`,
    )
  }
  return hotelRepository.updateStatus(hotel.id, toStatus)
}
