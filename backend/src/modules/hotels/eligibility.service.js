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
export async function getEligibility(hotelId) {
  const hotel = await hotelRepository.findById(hotelId)
  if (!hotel) {
    return { found: false, eligible: false, status: null }
  }
  return { found: true, eligible: hotel.status === 'APPROVED_ACTIVE', status: hotel.status }
}
