import { Router } from 'express'
import * as controller from './review.controller.js'
import * as validation from './review.validation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'
import { requireAccountType } from '../../shared/middleware/authorize.js'

export const bookingReviewRouter = Router({ mergeParams: true })
bookingReviewRouter.use(authenticate, requireAccountType('CUSTOMER'))
bookingReviewRouter.post('/', validation.validateSubmitReview, controller.submitReview)

export const hotelReviewRouter = Router({ mergeParams: true })
hotelReviewRouter.get(
  '/',
  validation.validateHotelIdParam,
  validation.validateListReviews,
  controller.listHotelReviews,
)
