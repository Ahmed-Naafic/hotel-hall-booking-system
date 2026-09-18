import * as hotelRepository from './hotel.repository.js'
import * as bookingRepository from '../bookings/booking.repository.js'
import { recordAuditEvent } from './audit.js'
import { NotFoundError } from '../../shared/errors/errorTypes.js'
import { haversineDistanceKm } from '../../shared/utils/geo.js'

/** Nearby Hotels V1 — fixed for every Customer, not configurable (approved business rule). */
const NEARBY_RADIUS_KM = 5

/**
 * Popular Hotels (approved business rules) — a Booking counts toward
 * popularity only in the status it is in when this list is read (CONFIRMED
 * or COMPLETED), using whichever timestamp represents when it most
 * recently entered that status. A rolling 90-day *duration* (not a
 * calendar-day boundary), so it is computed as an absolute instant
 * (`Date.now() minus 90*24h`) and compared against the stored UTC instant —
 * timezone-independent by construction; Mogadishu-local wall-clock time
 * never enters the comparison.
 */
const POPULAR_WINDOW_DAYS = 90
const POPULAR_QUALIFYING_TRANSITIONS = [
  { status: 'CONFIRMED', dateField: 'updatedAt' },
  { status: 'COMPLETED', dateField: 'completedAt' },
]

/**
 * Hotel Component (Technical Design §3, §4) — creates and retrieves the
 * Hotel entity, the aggregate root every other component in this module
 * operates on. Never reasons about lifecycle transitions itself
 * (lifecycle.service.js's job).
 */

export async function registerHotel({ registeredByUserId, profileData }) {
  const hotel = await hotelRepository.create({
    registeredByUserId,
    profileData: profileData ?? null,
  })
  recordAuditEvent('HOTEL_REGISTERED', { hotelId: hotel.id, actorUserId: registeredByUserId })
  return hotel
}

export async function getHotelById(id) {
  const hotel = await hotelRepository.findById(id)
  if (!hotel) {
    throw new NotFoundError('Hotel not found.')
  }
  return hotel
}

/**
 * Own-Hotel scoping (Technical Design §12, api-standards.md §13) — a Hotel
 * Manager may only ever resolve their own Hotel. Cross-tenant access
 * returns 404, never 403, so tenant existence is never leaked.
 */
export async function getOwnHotelById(id, requestingUserId) {
  const hotel = await hotelRepository.findByIdForOwner(id, requestingUserId)
  if (!hotel) {
    throw new NotFoundError('Hotel not found.')
  }
  return hotel
}

export async function getLatestOwnHotel(requestingUserId) {
  return hotelRepository.findLatestByOwner(requestingUserId)
}

export function listHotels({ status, page = 1, limit = 20 }) {
  const skip = (page - 1) * limit
  return Promise.all([
    hotelRepository.list({ status, skip, take: limit }),
    hotelRepository.count({ status }),
  ])
}

export async function listPublicHotels({ cursor, limit = 20, search }) {
  const results = await hotelRepository.listPublic({ cursor, take: limit + 1, search })
  const hasNext = results.length > limit
  const hotels = hasNext ? results.slice(0, limit) : results
  return { hotels, hasNext, nextCursor: hasNext ? hotels[hotels.length - 1].id : null }
}

export async function getPublicHotelById(id) {
  const hotel = await hotelRepository.findPublicById(id)
  if (!hotel) {
    throw new NotFoundError('Hotel not found.')
  }
  return hotel
}

/**
 * Nearby Hotels (Customer Mobile, approved business rules) — geographic
 * lat/lng distance only, never address-text matching. The backend is
 * authoritative for both the distance calculation and the 5km filter, so
 * Customer Mobile never independently calculates or filters proximity.
 * A Hotel whose profileData.location is missing or has a non-numeric
 * latitude/longitude (legacy pre-BDR-017 plain-string shape, or an
 * incomplete profile) is excluded rather than treated as a match.
 */
export async function listNearbyPublicHotels({ latitude, longitude }) {
  const hotels = await hotelRepository.findAllApprovedActive()

  return hotels
    .map((hotel) => {
      const location = hotel.profileData?.location
      const hotelLatitude = location?.latitude
      const hotelLongitude = location?.longitude
      if (typeof hotelLatitude !== 'number' || typeof hotelLongitude !== 'number') {
        return null
      }
      const distanceKm = haversineDistanceKm({
        lat1: latitude,
        lon1: longitude,
        lat2: hotelLatitude,
        lon2: hotelLongitude,
      })
      return { hotel, distanceKm }
    })
    .filter((entry) => entry !== null && entry.distanceKm <= NEARBY_RADIUS_KM)
    .sort((a, b) => a.distanceKm - b.distanceKm)
}

/**
 * Popular Hotels (Customer Mobile, approved V1 business rules) — popularity
 * is Hotel-level: every qualifying Booking already carries hotelId directly
 * (Booking.hotelId, not derived through Hall), so a Hotel with several
 * qualifying Halls is summed exactly once per Booking, never per Hall — no
 * double counting is possible because each Booking row is aggregated once.
 */
export async function listPopularPublicHotels({ limit = 20 } = {}) {
  const since = new Date(Date.now() - POPULAR_WINDOW_DAYS * 24 * 60 * 60 * 1000)

  const aggregatesByTransition = await Promise.all(
    POPULAR_QUALIFYING_TRANSITIONS.map(({ status, dateField }) =>
      bookingRepository.aggregateQualifyingBookingCountsByHotel({ status, dateField, since }),
    ),
  )

  const summaryByHotelId = new Map()
  aggregatesByTransition.forEach((rows, index) => {
    const { dateField } = POPULAR_QUALIFYING_TRANSITIONS[index]
    for (const row of rows) {
      const summary = summaryByHotelId.get(row.hotelId) ?? { count: 0, lastActivityAt: null }
      summary.count += row._count._all
      const rowMax = row._max[dateField]
      if (rowMax && (!summary.lastActivityAt || rowMax > summary.lastActivityAt)) {
        summary.lastActivityAt = rowMax
      }
      summaryByHotelId.set(row.hotelId, summary)
    }
  })

  if (summaryByHotelId.size === 0) {
    return []
  }

  const hotels = await hotelRepository.findApprovedActiveByIds([...summaryByHotelId.keys()])

  return hotels
    .filter(
      (hotel) =>
        hotel.halls.length > 0 && (hotel.media ?? []).some((media) => media.type === 'PHOTO'),
    )
    .map((hotel) => ({ hotel, ...summaryByHotelId.get(hotel.id) }))
    .sort((a, b) => {
      if (b.count !== a.count) return b.count - a.count
      const aTime = a.lastActivityAt ? a.lastActivityAt.getTime() : 0
      const bTime = b.lastActivityAt ? b.lastActivityAt.getTime() : 0
      if (bTime !== aTime) return bTime - aTime
      return a.hotel.id.localeCompare(b.hotel.id)
    })
    .slice(0, limit)
}
