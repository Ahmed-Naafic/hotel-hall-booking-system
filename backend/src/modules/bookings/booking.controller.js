import * as service from './booking.service.js'
import * as hallService from '../halls/hall.service.js'
import { toBooking } from './booking.mapper.js'
import { sendSuccess } from '../../shared/utils/responseEnvelope.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'

const limitOf = (req) => Math.min(Number(req.query.limit ?? 20), 100)
const respond = (res, message, booking, statusCode = 200) => sendSuccess(res, { statusCode, message, data: toBooking(booking) })

export const create = asyncHandler(async (req, res) => respond(res, 'Booking created successfully.', await service.createBooking({ customerUserId: req.identity.userId, ...req.body }), 201))
export const getCustomer = asyncHandler(async (req, res) => respond(res, 'Booking retrieved successfully.', await service.getCustomer({ bookingId: req.params.bookingId, customerUserId: req.identity.userId })))
export const listCustomer = asyncHandler(async (req, res) => {
  const limit = limitOf(req)
  const result = await service.listCustomer({ customerUserId: req.identity.userId, cursor: req.query.cursor, limit })
  sendSuccess(res, { message: 'Bookings retrieved successfully.', data: result.bookings.map(toBooking), pagination: { limit, hasNext: result.hasNext, nextCursor: result.nextCursor } })
})
export const reportPayment = asyncHandler(async (req, res) => respond(res, 'Payment reported successfully.', await service.reportPayment({ bookingId: req.params.bookingId, customerUserId: req.identity.userId, amountCents: req.body.amountCents })))
export const cancelCustomer = asyncHandler(async (req, res) => respond(res, 'Booking cancelled successfully.', await service.cancelCustomer({ bookingId: req.params.bookingId, customerUserId: req.identity.userId })))

async function ownHotel(req) { await hallService.assertOwnHotel(req.params.hotelId, req.identity.userId) }
export const getHotel = asyncHandler(async (req, res) => { await ownHotel(req); respond(res, 'Booking retrieved successfully.', await service.getHotel({ bookingId: req.params.bookingId, hotelId: req.params.hotelId })) })
export const listHotel = asyncHandler(async (req, res) => {
  await ownHotel(req)
  const limit = limitOf(req)
  const result = await service.listHotel({ hotelId: req.params.hotelId, status: req.query.status, cursor: req.query.cursor, limit })
  sendSuccess(res, { message: 'Bookings retrieved successfully.', data: result.bookings.map(toBooking), pagination: { limit, hasNext: result.hasNext, nextCursor: result.nextCursor } })
})
export const verifyPayment = asyncHandler(async (req, res) => { await ownHotel(req); respond(res, 'Payment report reviewed successfully.', await service.verifyPayment({ bookingId: req.params.bookingId, hotelId: req.params.hotelId, actorUserId: req.identity.userId, ...req.body })) })

const transition = (action, message) => asyncHandler(async (req, res) => {
  await ownHotel(req)
  respond(res, message, await service.transitionHotel({ bookingId: req.params.bookingId, hotelId: req.params.hotelId, actorUserId: req.identity.userId, action }))
})
export const confirm = transition('CONFIRMED', 'Booking confirmed successfully.')
export const reject = transition('REJECTED', 'Booking rejected successfully.')
export const cancelHotel = transition('CANCELLED', 'Booking cancelled successfully.')
export const complete = transition('COMPLETED', 'Booking completed successfully.')
export const noShow = transition('NO_SHOW', 'Booking marked as no-show successfully.')
