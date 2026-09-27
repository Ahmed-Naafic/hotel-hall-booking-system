import { createHash } from 'node:crypto'
import * as hotelOwnership from '../hotels/ownership.service.js'

/**
 * Resolves what the authenticated caller is allowed to synchronize
 * (Technical Design §6).
 *
 * Two rules this module exists to enforce structurally rather than by
 * convention:
 *
 *   1. **Scope comes from `req.identity`, never from a request parameter.** A
 *      client asking to sync "hotel X" is answered from the Hotels
 *      `registeredByUserId` says it owns. Nothing here reads `req.params` or
 *      `req.query`.
 *   2. **The predicate goes into the query**, not into a filter applied after
 *      fetching — so a resolver receives ids to constrain on, and a resolver
 *      with no ids returns nothing rather than everything.
 */

/**
 * The Hotels this caller owns. Empty for a Customer, an anonymous caller, or a
 * Manager who has not registered one — and an empty list must narrow a query to
 * nothing, never widen it.
 */
export async function ownedHotelIds(identity) {
  if (identity?.accountType !== 'HOTEL_MANAGER') {
    return []
  }
  // Through Hotel Management's Ownership Query Interface, never its repository
  // — this module must not query another module's data directly
  // (architecture-principles.md §5).
  return hotelOwnership.listOwnedHotelIds(identity.userId)
}

/**
 * A stable fingerprint of everything the caller's permissions depend on.
 *
 * `accountType` is a token claim, so a device holding data synced under a role
 * it no longer has would otherwise keep it indefinitely. The client compares
 * this against the value it synced under and discards its replica on a
 * mismatch. Hashed rather than sent raw so the response does not enumerate the
 * caller's Hotel ids as a side channel.
 */
export function scopeId({ identity, hotelIds }) {
  const material = [
    identity?.userId ?? 'anonymous',
    identity?.accountType ?? 'ANONYMOUS',
    ...[...hotelIds].sort(),
  ].join('|')
  return createHash('sha256').update(material).digest('hex').slice(0, 32)
}

/** Resolves the full scope once per request, so a resolver never re-queries it. */
export async function resolve(identity) {
  const hotelIds = await ownedHotelIds(identity)
  return { identity, hotelIds, scopeId: scopeId({ identity, hotelIds }) }
}
