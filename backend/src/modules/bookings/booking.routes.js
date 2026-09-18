import { Router } from 'express'
import * as controller from './booking.controller.js'
import * as validation from './booking.validation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'
import { requireAccountType } from '../../shared/middleware/authorize.js'

export const bookingRouter = Router()
bookingRouter.use(authenticate, requireAccountType('CUSTOMER'))
bookingRouter.post('/', validation.validateCreate, controller.create)
bookingRouter.get('/', validation.validateList, controller.listCustomer)
bookingRouter.get('/:bookingId', controller.getCustomer)
bookingRouter.post('/:bookingId/payment-report', validation.validatePaymentReport, controller.reportPayment)
bookingRouter.post('/:bookingId/cancellation', validation.validateCancelCustomer, controller.cancelCustomer)

export const hotelBookingRouter = Router({ mergeParams: true })
hotelBookingRouter.use(authenticate, requireAccountType('HOTEL_MANAGER'))
hotelBookingRouter.get('/', validation.validateList, controller.listHotel)
hotelBookingRouter.get('/summary', controller.summary)
hotelBookingRouter.get('/:bookingId', controller.getHotel)
hotelBookingRouter.post('/:bookingId/payment-verification', validation.validatePaymentDecision, controller.verifyPayment)
hotelBookingRouter.post('/:bookingId/confirmation', controller.confirm)
hotelBookingRouter.post('/:bookingId/rejection', controller.reject)
hotelBookingRouter.post('/:bookingId/cancellation', controller.cancelHotel)
hotelBookingRouter.post('/:bookingId/completion', controller.complete)
hotelBookingRouter.post('/:bookingId/no-show', controller.noShow)
