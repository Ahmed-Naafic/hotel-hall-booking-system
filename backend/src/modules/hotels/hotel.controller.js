import * as hotelService from './hotel.service.js'
import * as profileService from './profile.service.js'
import * as applicationService from './application.service.js'
import { toPublicHotel, toPublicApplication } from './hotel.mapper.js'
import { sendSuccess } from '../../shared/utils/responseEnvelope.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'
import { AuthorizationError, BusinessRuleError } from '../../shared/errors/errorTypes.js'

/**
 * Controller layer (coding-standards.md §5) — reads the request, calls the
 * service, shapes the response. No business logic and no direct Prisma
 * access here. Own-Hotel authorization (api-standards.md §13) is applied
 * inline via hotelService.getOwnHotelById — 404, never 403, cross-tenant.
 */

function requirePlatformAdministrator(req) {
  if (req.identity.accountType !== 'PLATFORM_ADMINISTRATOR') {
    throw new AuthorizationError('You are not authorized to perform this action.')
  }
}

export const registerHotel = asyncHandler(async (req, res) => {
  const hotel = await hotelService.registerHotel({
    registeredByUserId: req.identity.userId,
    profileData: req.body?.profileData,
  })
  sendSuccess(res, {
    statusCode: 201,
    message: 'Hotel registered successfully.',
    data: toPublicHotel(hotel),
  })
})

export const getHotel = asyncHandler(async (req, res) => {
  const hotel =
    req.identity.accountType === 'PLATFORM_ADMINISTRATOR'
      ? await hotelService.getHotelById(req.params.id)
      : await hotelService.getOwnHotelById(req.params.id, req.identity.userId)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Hotel retrieved successfully.',
    data: toPublicHotel(hotel),
  })
})

/**
 * Routes to the Profile Component function matching the Hotel's current
 * status (Technical Design §8) — completion (REGISTERED), editing a
 * rejected draft (REJECTED), or ordinary/critical change (APPROVED_ACTIVE).
 * Any other status is a business-rule failure (422).
 */
export const updateHotel = asyncHandler(async (req, res) => {
  const hotel = await hotelService.getOwnHotelById(req.params.id, req.identity.userId)

  if (hotel.status === 'REGISTERED') {
    const updated = await profileService.completeProfile(hotel, req.body)
    return sendSuccess(res, {
      statusCode: 200,
      message: 'Hotel profile completed successfully.',
      data: toPublicHotel(updated),
    })
  }

  if (hotel.status === 'REJECTED') {
    const updated = await profileService.editRejectedApplication(hotel, req.body)
    return sendSuccess(res, {
      statusCode: 200,
      message: 'Application updated successfully.',
      data: toPublicHotel(updated),
    })
  }

  if (hotel.status === 'APPROVED_ACTIVE') {
    const { applied, hotel: updatedHotel, criticalChangeRequest } = await profileService.changeProfile(
      hotel,
      req.body,
    )
    return sendSuccess(res, {
      statusCode: 200,
      message: applied
        ? 'Profile change applied successfully.'
        : 'Profile change submitted for Platform Administrator review.',
      data: { applied, hotel: toPublicHotel(updatedHotel), criticalChangeRequestId: criticalChangeRequest?.id ?? null },
    })
  }

  throw new BusinessRuleError("This Hotel's current status does not permit profile changes.")
})

export const submitApplication = asyncHandler(async (req, res) => {
  const hotel = await hotelService.getOwnHotelById(req.params.id, req.identity.userId)
  const application = await applicationService.submitOrResubmitApplication(hotel)
  sendSuccess(res, {
    statusCode: 201,
    message: 'Application submitted successfully.',
    data: toPublicApplication(application),
  })
})

export const withdrawApplication = asyncHandler(async (req, res) => {
  const hotel = await hotelService.getOwnHotelById(req.params.id, req.identity.userId)
  const application = await applicationService.withdrawApplication(hotel)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Application withdrawn successfully.',
    data: toPublicApplication(application),
  })
})

/** Platform-Administrator-only — the query interface behind the Hotel approval queue (Technical Design §11). */
export const listHotels = asyncHandler(async (req, res) => {
  requirePlatformAdministrator(req)
  const page = req.query.page ? Number(req.query.page) : 1
  const limit = req.query.limit ? Math.min(Number(req.query.limit), 100) : 20
  const [hotels, total] = await hotelService.listHotels({ status: req.query.status, page, limit })
  sendSuccess(res, {
    statusCode: 200,
    message: 'Hotels retrieved successfully.',
    data: hotels.map(toPublicHotel),
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
      hasNext: page * limit < total,
      hasPrevious: page > 1,
    },
  })
})
