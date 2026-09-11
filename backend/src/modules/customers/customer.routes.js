import { Router } from 'express'
import * as customerController from './customer.controller.js'
import * as customerValidation from './customer.validation.js'
import * as mediaValidation from '../../shared/media/imageValidation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'
import { requireAccountType } from '../../shared/middleware/authorize.js'

export const customerRouter = Router()

customerRouter.use(authenticate, requireAccountType('CUSTOMER'))
customerRouter.get('/me', customerController.getMe)
customerRouter.post('/me/profile', customerValidation.validateProfile, customerController.createProfile)
customerRouter.patch('/me/profile', customerValidation.validateProfile, customerController.updateProfile)
customerRouter.post(
  '/me/avatar',
  mediaValidation.uploadMiddleware,
  mediaValidation.handleUploadError,
  mediaValidation.validateUploadedFile,
  customerController.uploadAvatar,
)
customerRouter.delete('/me/avatar', customerController.deleteAvatar)
