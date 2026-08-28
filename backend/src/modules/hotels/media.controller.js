import * as hotelService from './hotel.service.js'
import * as mediaService from './media.service.js'
import { toPublicHotelMedia } from './media.mapper.js'
import { sendSuccess, sendNoContent } from '../../shared/utils/responseEnvelope.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'

/**
 * Controller layer (coding-standards.md §5) — reads the request, calls the
 * service, shapes the response. No business logic and no direct Prisma or
 * Supabase access here. Own-Hotel authorization (api-standards.md §13) is
 * applied inline via `hotelService.getOwnHotelById` — 404, never 403,
 * cross-tenant — the exact same pattern `hotel.controller.js` already
 * uses; introduces no second authorization mechanism (Technical Design
 * §12).
 */

export const uploadLogo = asyncHandler(async (req, res) => {
  const hotel = await hotelService.getOwnHotelById(req.params.hotelId, req.identity.userId)
  const media = await mediaService.uploadLogo(hotel, { buffer: req.file.buffer, mimeType: req.detectedMimeType })
  sendSuccess(res, {
    statusCode: 201,
    message: 'Hotel logo uploaded successfully.',
    data: toPublicHotelMedia(media),
  })
})

export const uploadPhoto = asyncHandler(async (req, res) => {
  const hotel = await hotelService.getOwnHotelById(req.params.hotelId, req.identity.userId)
  const media = await mediaService.uploadPhoto(hotel, { buffer: req.file.buffer, mimeType: req.detectedMimeType })
  sendSuccess(res, {
    statusCode: 201,
    message: 'Hotel photo uploaded successfully.',
    data: toPublicHotelMedia(media),
  })
})

export const deleteMedia = asyncHandler(async (req, res) => {
  const hotel = await hotelService.getOwnHotelById(req.params.hotelId, req.identity.userId)
  await mediaService.deleteMedia(hotel, req.params.mediaId)
  sendNoContent(res)
})

export const getMedia = asyncHandler(async (req, res) => {
  const hotel =
    req.identity.accountType === 'PLATFORM_ADMINISTRATOR'
      ? await hotelService.getHotelById(req.params.hotelId)
      : await hotelService.getOwnHotelById(req.params.hotelId, req.identity.userId)
  const { logo, photos } = await mediaService.getMedia(hotel)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Hotel media retrieved successfully.',
    data: { logo: toPublicHotelMedia(logo), photos: photos.map(toPublicHotelMedia) },
  })
})
