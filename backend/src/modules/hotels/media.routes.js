import { Router } from 'express'
import * as mediaController from './media.controller.js'
import * as mediaValidation from './media.validation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'

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
  mediaValidation.uploadMiddleware,
  mediaValidation.handleUploadError,
  mediaValidation.validateUploadedFile,
  mediaController.uploadLogo,
)

hotelMediaRouter.post(
  '/photos',
  authenticate,
  mediaValidation.uploadMiddleware,
  mediaValidation.handleUploadError,
  mediaValidation.validateUploadedFile,
  mediaController.uploadPhoto,
)

hotelMediaRouter.delete('/:mediaId', authenticate, mediaController.deleteMedia)

hotelMediaRouter.get('/', authenticate, mediaController.getMedia)
