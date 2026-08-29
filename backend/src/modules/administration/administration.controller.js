import * as hotelService from '../hotels/hotel.service.js'
import * as applicationService from '../hotels/application.service.js'
import { toPublicApplication } from '../hotels/hotel.mapper.js'
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
