import * as service from './favorite.service.js'
import { sendSuccess, sendNoContent } from '../../shared/utils/responseEnvelope.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'

export const save = asyncHandler(async (req, res) => {
  await service.saveHotel({ customerUserId: req.identity.userId, hotelId: req.params.hotelId })
  sendSuccess(res, { statusCode: 200, message: 'Hotel saved successfully.', data: { hotelId: req.params.hotelId, saved: true } })
})

export const unsave = asyncHandler(async (req, res) => {
  await service.unsaveHotel({ customerUserId: req.identity.userId, hotelId: req.params.hotelId })
  sendNoContent(res)
})

export const list = asyncHandler(async (req, res) => {
  const hotelIds = await service.listSavedHotelIds({ customerUserId: req.identity.userId })
  sendSuccess(res, { message: 'Saved hotels retrieved successfully.', data: hotelIds })
})
