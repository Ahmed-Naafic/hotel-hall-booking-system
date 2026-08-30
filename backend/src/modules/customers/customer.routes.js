import { Router } from 'express'
import * as customerController from './customer.controller.js'
import * as customerValidation from './customer.validation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'
import { requireAccountType } from '../../shared/middleware/authorize.js'

export const customerRouter = Router()

customerRouter.use(authenticate, requireAccountType('CUSTOMER'))
customerRouter.get('/me', customerController.getMe)
customerRouter.post('/me/profile', customerValidation.validateProfile, customerController.createProfile)
customerRouter.patch('/me/profile', customerValidation.validateProfile, customerController.updateProfile)
