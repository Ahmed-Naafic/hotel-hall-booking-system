import { Router } from 'express'
import * as controller from './favorite.controller.js'
import * as validation from './favorite.validation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'
import { requireAccountType } from '../../shared/middleware/authorize.js'

export const favoriteRouter = Router()
favoriteRouter.use(authenticate, requireAccountType('CUSTOMER'))
favoriteRouter.get('/hotels', controller.list)
favoriteRouter.put('/hotels/:hotelId', validation.validateHotelIdParam, controller.save)
favoriteRouter.delete('/hotels/:hotelId', validation.validateHotelIdParam, controller.unsave)
