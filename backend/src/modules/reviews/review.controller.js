import * as service from './review.service.js'
import { toReview } from './review.mapper.js'
import { toBooking } from '../bookings/booking.mapper.js'
import { sendSuccess } from '../../shared/utils/responseEnvelope.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'

export const submitReview = asyncHandler(async (req, res) => {
  const booking = await service.submitReview({
    bookingId: req.params.bookingId,
    customerUserId: req.identity.userId,
    rating: req.body.rating,
    text: req.body.text,
  })
  sendSuccess(res, { statusCode: 201, message: 'Review submitted successfully.', data: toBooking(booking) })
})

const limitOf = (req) => Math.min(Number(req.query.limit ?? 20), 100)

export const listHotelReviews = asyncHandler(async (req, res) => {
  const limit = limitOf(req)
  const result = await service.listHotelReviews({ hotelId: req.params.hotelId, cursor: req.query.cursor, limit })
  sendSuccess(res, {
    message: 'Reviews retrieved successfully.',
    data: result.reviews.map(toReview),
    pagination: { limit, hasNext: result.hasNext, nextCursor: result.nextCursor },
  })
})
