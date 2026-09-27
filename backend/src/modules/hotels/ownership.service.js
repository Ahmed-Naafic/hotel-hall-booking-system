import * as hotelRepository from './hotel.repository.js'

/**
 * Hotel Ownership Query Interface (Technical Design §3, §10, §18 Item 6) —
 * a narrow, read-only interface Hall Management (Module 4) queries to
 * determine whether a given Hotel Manager owns a given Hotel (BR-HALL-10).
 * Distinct from the Eligibility Query Interface (eligibility.service.js):
 * this answers "who owns this Hotel," never "is this Hotel operationally
 * eligible" — the two questions are deliberately not conflated.
 *
 * Returns a boolean only, never a Hotel record, so no Hotel data crosses
 * the module boundary (architecture-principles.md §5). Wraps the same
 * internal lookup this module's own controller already uses for own-Hotel
 * scoping (hotel.service.js#getOwnHotelById) — no new query is introduced.
 */
export async function isOwnedByUser(hotelId, userId) {
  const hotel = await hotelRepository.findByIdForOwner(hotelId, userId)
  return hotel !== null
}

/**
 * The inverse question: which Hotels does this Manager own?
 *
 * Added for the Synchronization Component (Local-First Technical Design §6),
 * which needs the tenant boundary as a list to constrain a query by, not a
 * yes/no about one Hotel it already has in hand. An additive extension to this
 * interface, the same shape Hall Management Technical Design §18 Item 5
 * anticipates for the Eligibility Query Interface.
 *
 * Ids only — consistent with this interface's rule that no Hotel record crosses
 * the module boundary.
 */
export async function listOwnedHotelIds(userId) {
  const hotels = await hotelRepository.listIdsByOwner(userId)
  return hotels.map((hotel) => hotel.id)
}
