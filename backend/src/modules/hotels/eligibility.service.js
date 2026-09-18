import * as hotelRepository from './hotel.repository.js'

/**
 * Eligibility Query Interface (Technical Design §3, §10) — a narrow,
 * read-only interface Authentication & Account Management (Module 1) and
 * Hall Management (Module 4) query to determine a Hotel's current
 * operational eligibility (BR-HOTEL-04, BR-HOTEL-05). This is the only
 * seam those modules use into this module's data — never a direct query
 * against the Hotel table (architecture-principles.md §5).
 *
 * A Hotel is operationally eligible — able to list Halls and receive
 * Bookings — only while APPROVED_ACTIVE (BR-HOTEL-05).
 */
const NOT_FOUND = { found: false, eligible: false, status: null }

function toEligibility(hotel) {
  if (!hotel) {
    return NOT_FOUND
  }
  return { found: true, eligible: hotel.status === 'APPROVED_ACTIVE', status: hotel.status }
}

export async function getEligibility(hotelId) {
  return toEligibility(await hotelRepository.findStatusById(hotelId))
}

/**
 * Batch form of the same query, for callers holding a whole page of records
 * that each reference a Hotel (Hall Management's Visibility Component being
 * the first). Resolves the entire page in one round trip instead of one per
 * record — the same interface and the same answer per Hotel, never a second
 * eligibility rule. Ids absent from the result are reported `found: false`,
 * identically to `getEligibility` above.
 */
export async function getEligibilityForMany(hotelIds) {
  const uniqueIds = [...new Set(hotelIds)]
  if (uniqueIds.length === 0) {
    return new Map()
  }
  const hotels = await hotelRepository.findStatusesByIds(uniqueIds)
  const byId = new Map(hotels.map((hotel) => [hotel.id, toEligibility(hotel)]))
  return new Map(uniqueIds.map((id) => [id, byId.get(id) ?? NOT_FOUND]))
}
