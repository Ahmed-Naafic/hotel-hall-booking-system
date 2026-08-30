import * as hotelRepository from './hotel.repository.js'
import { recordAuditEvent } from './audit.js'
import { NotFoundError } from '../../shared/errors/errorTypes.js'

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

export async function listPublicHotels({ cursor, limit = 20 }) {
  const results = await hotelRepository.listPublic({ cursor, take: limit + 1 })
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
