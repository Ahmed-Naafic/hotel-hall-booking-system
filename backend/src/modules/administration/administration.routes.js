import { Router } from 'express'
import * as administrationController from './administration.controller.js'
import * as administrationValidation from './administration.validation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'
import { requireAccountType } from '../../shared/middleware/authorize.js'

export const administrationRouter = Router()

administrationRouter.get(
  '/hotels/:hotelId/applications',
  authenticate,
  requireAccountType('PLATFORM_ADMINISTRATOR'),
  administrationController.listHotelApplications,
)

administrationRouter.post(
  '/hotels/:hotelId/applications/:applicationId/approval',
  authenticate,
  requireAccountType('PLATFORM_ADMINISTRATOR'),
  administrationController.approveHotelApplication,
)

administrationRouter.post(
  '/hotels/:hotelId/applications/:applicationId/rejection',
  authenticate,
  requireAccountType('PLATFORM_ADMINISTRATOR'),
  administrationValidation.validateRejectHotelApplication,
  administrationController.rejectHotelApplication,
)
