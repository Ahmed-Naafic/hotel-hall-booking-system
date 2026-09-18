import * as hotelService from '../hotels/hotel.service.js'
import * as applicationService from '../hotels/application.service.js'
import * as suspensionService from '../hotels/suspension.service.js'
import { toPublicApplication, toPublicHotel } from '../hotels/hotel.mapper.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'
import { sendSuccess } from '../../shared/utils/responseEnvelope.js'

export const listHotelApplications = asyncHandler(async (req, res) => {
  await hotelService.getHotelById(req.params.hotelId)
  const applications = await applicationService.listApplicationsForHotel(req.params.hotelId)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Hotel applications retrieved successfully.',
    data: applications.map(toPublicApplication),
  })
})

export const approveHotelApplication = asyncHandler(async (req, res) => {
  const hotel = await hotelService.getHotelById(req.params.hotelId)
  const application = await applicationService.recordDecision(
    hotel,
    req.params.applicationId,
    'APPROVED',
    req.identity.userId,
  )
  sendSuccess(res, {
    statusCode: 200,
    message: 'Hotel application approved successfully.',
    data: toPublicApplication(application),
  })
})

export const rejectHotelApplication = asyncHandler(async (req, res) => {
  const hotel = await hotelService.getHotelById(req.params.hotelId)
  const application = await applicationService.recordDecision(
    hotel,
    req.params.applicationId,
    'REJECTED',
    req.identity.userId,
    { decisionReason: req.body.reason },
  )
  sendSuccess(res, {
    statusCode: 200,
    message: 'Hotel application rejected successfully.',
    data: toPublicApplication(application),
  })
})

/** Suspension (HM11, BR-HOTEL-09) — only from APPROVED_ACTIVE; lifecycle.service.js enforces the transition. */
export const suspendHotel = asyncHandler(async (req, res) => {
  const hotel = await hotelService.getHotelById(req.params.hotelId)
  const updated = await suspensionService.suspendHotel(hotel, req.identity.userId)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Hotel suspended successfully.',
    data: toPublicHotel(updated),
  })
})

/** Deactivation (BR-HOTEL-09) — only from APPROVED_ACTIVE; lifecycle.service.js enforces the transition. */
export const deactivateHotel = asyncHandler(async (req, res) => {
  const hotel = await hotelService.getHotelById(req.params.hotelId)
  const updated = await suspensionService.deactivateHotel(hotel, req.identity.userId)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Hotel deactivated successfully.',
    data: toPublicHotel(updated),
  })
})

/** Reactivation (BDR-012) — only from SUSPENDED or DEACTIVATED; lifecycle.service.js enforces the transition. */
export const reactivateHotel = asyncHandler(async (req, res) => {
  const hotel = await hotelService.getHotelById(req.params.hotelId)
  const updated = await suspensionService.reactivateHotel(hotel, req.identity.userId)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Hotel reactivated successfully.',
    data: toPublicHotel(updated),
  })
})
