import * as reviewRepository from './review.repository.js'
import * as bookingRepository from '../bookings/booking.repository.js'
import { NotFoundError, ConflictError } from '../../shared/errors/errorTypes.js'

/**
 * Ratings & Reviews (Customer Mobile, approved V1 business decisions) — a
 * review is always tied to one COMPLETED Booking the reviewing Customer
 * actually owns; eligibility is read from the existing Booking relationship
 * (approved decision #10), never a duplicate/parallel check. The backend is
 * the sole authority for eligibility (approved decision #7) — Flutter never
 * decides whether a Booking may be reviewed.
 */

export async function submitReview({ bookingId, customerUserId, rating, text }) {
  const booking = await bookingRepository.findForCustomer(bookingId, customerUserId)
  if (!booking) {
    throw new NotFoundError('Booking not found.')
  }
  if (booking.status !== 'COMPLETED') {
    throw new ConflictError('Only a completed Booking can be reviewed.')
  }
  const existing = await reviewRepository.findByBookingId(bookingId)
  if (existing) {
    throw new ConflictError('This Booking has already been reviewed.')
  }

  try {
    await reviewRepository.create({ bookingId, customerUserId, hotelId: booking.hotelId, rating, text })
  } catch (error) {
    // The @@unique(bookingId) constraint is the authoritative guard against a
    // race between the check above and this write; the precheck exists only
    // to give the common case a clean, specific message.
    if (error?.code === 'P2002') throw new ConflictError('This Booking has already been reviewed.')
    throw error
  }

  return bookingRepository.findForCustomer(bookingId, customerUserId)
}

/** Public Hotel Detail review list (approved decision #5) — cursor pagination, same convention as GET /halls. */
export async function listHotelReviews({ hotelId, cursor, limit = 20 }) {
  const results = await reviewRepository.listForHotel({ hotelId, cursor, take: limit + 1 })
  const hasNext = results.length > limit
  const reviews = hasNext ? results.slice(0, limit) : results
  return { reviews, hasNext, nextCursor: hasNext ? reviews[reviews.length - 1].id : null }
}

/** Hotel Detail's average rating + review count — null average (not 0) when a Hotel has zero reviews. */
export async function getHotelReviewSummary(hotelId) {
  const result = await reviewRepository.aggregateForHotel(hotelId)
  const count = result._count._all
  return {
    average: count === 0 ? null : Math.round((result._avg.rating ?? 0) * 10) / 10,
    count,
  }
}
