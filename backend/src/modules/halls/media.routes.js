import { Router } from 'express'
import * as mediaController from './media.controller.js'
import * as mediaValidation from '../../shared/media/imageValidation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'
import { requireAccountType } from '../../shared/middleware/authorize.js'

export const hallMediaRouter = Router({ mergeParams: true })

hallMediaRouter.post(
  '/photos',
  authenticate,
  requireAccountType('HOTEL_MANAGER'),
  mediaValidation.uploadMiddleware,
  mediaValidation.handleUploadError,
  mediaValidation.validateUploadedFile,
  mediaController.uploadPhoto,
)

hallMediaRouter.delete('/:mediaId', authenticate, requireAccountType('HOTEL_MANAGER'), mediaController.deleteMedia)

hallMediaRouter.get('/', authenticate, requireAccountType('HOTEL_MANAGER'), mediaController.getMedia)
