import * as hallService from './hall.service.js'
import * as profileService from './profile.service.js'
import * as visibilityService from './visibility.service.js'
import { toPublicHall } from './hall.mapper.js'
import { sendSuccess } from '../../shared/utils/responseEnvelope.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'

/**
 * Controller layer (coding-standards.md §5) — reads the request, calls the
 * service, shapes the response. No business logic and no direct Prisma
 * access here. Own-Hotel authorization (WBS-05) is applied inline via
 * hallService.assertOwnHotel/getHallScoped/listHallsForHotelScoped — 404,
 * never 403, cross-tenant (api-standards.md §13), through Hotel
 * Management's Hotel Ownership Query Interface (Approved Technical Design
 * v1.5) — never a direct Hotel table read.
 */

/**
 * Create a Hall belonging to `:hotelId` (`POST /hotels/:hotelId/halls`,
 * `HL1`/`HL2`, `BR-HALL-02`) — own-Hotel only; no precondition on the
 * owning Hotel's own status.
 */
export const createHall = asyncHandler(async (req, res) => {
  const { hotelId } = req.params
  await hallService.assertOwnHotel(hotelId, req.identity.userId)
  const { profileData, ...commercialData } = req.body ?? {}
  const hall = await hallService.createHall({ hotelId, profileData, commercialData })
  sendSuccess(res, {
    statusCode: 201,
    message: 'Hall created successfully.',
    data: toPublicHall(hall),
  })
})

/**
 * Retrieve a single Hall (`GET /hotels/:hotelId/halls/:id`, `HL2`, `HL5`,
 * `HL6`, Technical Design §11, §14.3) — public, with conditional behavior:
 * the owning Hotel Manager sees the Hall regardless of visibility; anyone
 * else only if it's Visible.
 */
export const getHall = asyncHandler(async (req, res) => {
  const { hotelId, id } = req.params
  const hall = await hallService.getHallScoped({ id, hotelId, userId: req.identity?.userId })
  sendSuccess(res, {
    statusCode: 200,
    message: 'Hall retrieved successfully.',
    data: toPublicHall(hall),
  })
})

/**
 * Update a Hall's profile information (`PATCH /hotels/:hotelId/halls/:id`,
 * `HL3`, `BR-HALL-07`) — own-Hotel only; every well-formed change applies
 * immediately, no review step.
 */
export const updateHall = asyncHandler(async (req, res) => {
  const { hotelId, id } = req.params
  await hallService.assertOwnHotel(hotelId, req.identity.userId)
  const hall = await hallService.getHallForHotel(id, hotelId)
  const updated = await profileService.updateHallProfile(hall, req.body)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Hall updated successfully.',
    data: toPublicHall(updated),
  })
})

/**
 * List one Hotel's Halls (`GET /hotels/:hotelId/halls`, Technical Design
 * §11) — public, same conditional behavior as the single-Hall `GET`
 * above; offset pagination (`coding-standards.md` §6 — a bounded,
 * per-Hotel list, unlike the platform-wide `GET /halls` cursor-paginated
 * browse).
 */
export const listHallsForHotel = asyncHandler(async (req, res) => {
  const { hotelId } = req.params
  const page = req.query.page ? Number(req.query.page) : 1
  const limit = req.query.limit ? Math.min(Number(req.query.limit), 100) : 20
  const { halls, total } = await hallService.listHallsForHotelScoped({
    hotelId,
    userId: req.identity?.userId,
    page,
    limit,
  })
  sendSuccess(res, {
    statusCode: 200,
    message: 'Halls retrieved successfully.',
    data: halls.map(toPublicHall),
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

/**
 * Platform-wide browse (`GET /api/v1/halls`, Technical Design §11,
 * `BR-HALL-08`) — public, unconditionally; realizes Customer browsing
 * without an account (`BDR-009`). Cursor pagination (`coding-standards.md`
 * §6, Technical Design v1.2).
 */
export const browseHalls = asyncHandler(async (req, res) => {
  const limit = req.query.limit ? Math.min(Number(req.query.limit), 100) : 20
  const { halls, hasNext, nextCursor } = await visibilityService.browseVisibleHalls({
    hotelId: req.query.hotelId,
    cursor: req.query.cursor,
    limit,
  })
  sendSuccess(res, {
    statusCode: 200,
    message: 'Halls retrieved successfully.',
    data: halls.map(toPublicHall),
    pagination: { limit, nextCursor, hasNext },
  })
})
