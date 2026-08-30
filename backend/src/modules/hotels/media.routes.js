import { Router } from 'express'
import * as mediaController from './media.controller.js'
import * as mediaValidation from '../../shared/media/imageValidation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'
import { requireAccountType } from '../../shared/middleware/authorize.js'

/**
 * Route definitions only (coding-standards.md §5) — maps method + path to
 * a controller function. Mounted at `/api/v1/hotels/:hotelId/media`
 * (`mergeParams: true` so `:hotelId` reaches every handler here), the same
 * nested-router pattern `hall.routes.js`'s `hotelHallsRouter` already
 * establishes for `/api/v1/hotels/:hotelId/halls`. Endpoints per Hotel
 * Management Technical Design §8a/§11.
 */
export const hotelMediaRouter = Router({ mergeParams: true })

hotelMediaRouter.post(
  '/logo',
  authenticate,
  requireAccountType('HOTEL_MANAGER'),
  mediaValidation.uploadMiddleware,
  mediaValidation.handleUploadError,
  mediaValidation.validateUploadedFile,
  mediaController.uploadLogo,
)

hotelMediaRouter.post(
  '/photos',
  authenticate,
  requireAccountType('HOTEL_MANAGER'),
  mediaValidation.uploadMiddleware,
  mediaValidation.handleUploadError,
  mediaValidation.validateUploadedFile,
  mediaController.uploadPhoto,
)

hotelMediaRouter.delete('/:mediaId', authenticate, requireAccountType('HOTEL_MANAGER'), mediaController.deleteMedia)

hotelMediaRouter.get('/', authenticate, mediaController.getMedia)
