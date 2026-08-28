import { Router } from 'express'
import * as hotelController from './hotel.controller.js'
import * as hotelValidation from './hotel.validation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'

/**
 * Route definitions only (coding-standards.md §5) — maps method + path to a
 * controller function. Mounted at /api/v1/hotels by the app entry point.
 * Endpoints per Technical Design §11. No approve/reject/suspend/deactivate
 * endpoint exists here — those belong to Administration & Platform
 * Management's own future API surface (BR-HOTEL-14); this module exposes
 * only the internal service interface those endpoints will call
 * (application.service.js, profile.service.js, suspension.service.js).
 */
export const hotelRouter = Router()

// GET /hotels (Platform-Administrator-only query interface) must be
// registered before GET /hotels/:id so it isn't shadowed by the param route.
hotelRouter.get('/', authenticate, hotelValidation.validateListHotels, hotelController.listHotels)

hotelRouter.post(
  '/',
  authenticate,
  hotelValidation.validateRegisterHotel,
  hotelController.registerHotel,
)

hotelRouter.get('/:id', authenticate, hotelController.getHotel)

hotelRouter.patch(
  '/:id',
  authenticate,
  hotelValidation.validateUpdateHotel,
  hotelController.updateHotel,
)

hotelRouter.post('/:id/applications', authenticate, hotelController.submitApplication)

hotelRouter.post(
  '/:id/applications/:applicationId/withdrawal',
  authenticate,
  hotelController.withdrawApplication,
)
