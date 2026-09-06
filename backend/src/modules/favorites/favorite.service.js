import * as repository from './favorite.repository.js'
import { NotFoundError } from '../../shared/errors/errorTypes.js'

/**
 * Favorites (Customer Mobile) — a personal bookmark, not a business rule or
 * eligibility check. Saving requires the Hotel to currently exist; once
 * saved, a bookmark is never silently removed if the Hotel later becomes
 * ineligible for ordinary browsing (the same way Booking History still
 * shows past Bookings regardless of the Hotel's current status).
 */

export async function saveHotel({ customerUserId, hotelId }) {
  const hotel = await repository.findHotelForSave(hotelId)
  if (!hotel) {
    throw new NotFoundError('Hotel not found.')
  }
  await repository.save(customerUserId, hotelId)
}

export async function unsaveHotel({ customerUserId, hotelId }) {
  await repository.unsave(customerUserId, hotelId)
}

export async function listSavedHotelIds({ customerUserId }) {
  const rows = await repository.listHotelIds(customerUserId)
  return rows.map((row) => row.hotelId)
}
