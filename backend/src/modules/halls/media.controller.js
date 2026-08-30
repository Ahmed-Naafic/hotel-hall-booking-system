import * as hallService from './hall.service.js'
import * as mediaService from './media.service.js'
import { toPublicHallMedia } from './media.mapper.js'
import { sendSuccess, sendNoContent } from '../../shared/utils/responseEnvelope.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'

async function getOwnHall({ hotelId, hallId, userId }) {
  await hallService.assertOwnHotel(hotelId, userId)
  return hallService.getHallForHotel(hallId, hotelId)
}

export const uploadPhoto = asyncHandler(async (req, res) => {
  const hall = await getOwnHall({ hotelId: req.params.hotelId, hallId: req.params.hallId, userId: req.identity.userId })
  const media = await mediaService.uploadPhoto(hall, { buffer: req.file.buffer, mimeType: req.detectedMimeType })
  sendSuccess(res, {
    statusCode: 201,
    message: 'Hall photo uploaded successfully.',
    data: toPublicHallMedia(media),
  })
})

export const deleteMedia = asyncHandler(async (req, res) => {
  const hall = await getOwnHall({ hotelId: req.params.hotelId, hallId: req.params.hallId, userId: req.identity.userId })
  await mediaService.deleteMedia(hall, req.params.mediaId)
  sendNoContent(res)
})

export const getMedia = asyncHandler(async (req, res) => {
  const hall = await getOwnHall({ hotelId: req.params.hotelId, hallId: req.params.hallId, userId: req.identity.userId })
  const { photos } = await mediaService.getMedia(hall)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Hall media retrieved successfully.',
    data: { photos: photos.map(toPublicHallMedia) },
  })
})
