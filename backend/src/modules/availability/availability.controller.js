import * as hallService from '../halls/hall.service.js'
import * as availabilityService from './availability.service.js'
import { toManagerAvailabilityBlock, toPublicBusyPeriod } from './availability.mapper.js'
import { sendSuccess, sendNoContent } from '../../shared/utils/responseEnvelope.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'

/**
 * Controller layer (coding-standards.md §5) — reads the request, calls the
 * service, shapes the response. No business logic and no direct Prisma
 * access here. Own-Hotel authorization on the Manager endpoints is applied
 * inline via `hallService.assertOwnHotel`/`getHallForHotel` — the exact
 * two-call guard `hall.controller.js` already uses, never a new mechanism.
 */

export const listBlocksForManager = asyncHandler(async (req, res) => {
  const { hotelId, hallId } = req.params
  await hallService.assertOwnHotel(hotelId, req.identity.userId)
  await hallService.getHallForHotel(hallId, hotelId)
  const blocks = await availabilityService.getBlocksForHall({ hallId, date: req.query.date })
  sendSuccess(res, {
    statusCode: 200,
    message: 'Availability blocks retrieved successfully.',
    data: blocks.map(toManagerAvailabilityBlock),
  })
})

export const createBlock = asyncHandler(async (req, res) => {
  const { hotelId, hallId } = req.params
  await hallService.assertOwnHotel(hotelId, req.identity.userId)
  await hallService.getHallForHotel(hallId, hotelId)
  const { date, startTime, endTime, reason } = req.body
  const block = await availabilityService.createBlock({
    hallId,
    date,
    startTime,
    endTime,
    reason,
    createdByUserId: req.identity.userId,
  })
  sendSuccess(res, {
    statusCode: 201,
    message: 'Availability block created successfully.',
    data: toManagerAvailabilityBlock(block),
  })
})

export const updateBlock = asyncHandler(async (req, res) => {
  const { hotelId, hallId, blockId } = req.params
  await hallService.assertOwnHotel(hotelId, req.identity.userId)
  await hallService.getHallForHotel(hallId, hotelId)
  const { date, startTime, endTime, reason } = req.body
  const block = await availabilityService.updateBlock({ hallId, blockId, date, startTime, endTime, reason })
  sendSuccess(res, {
    statusCode: 200,
    message: 'Availability block updated successfully.',
    data: toManagerAvailabilityBlock(block),
  })
})

export const deleteBlock = asyncHandler(async (req, res) => {
  const { hotelId, hallId, blockId } = req.params
  await hallService.assertOwnHotel(hotelId, req.identity.userId)
  await hallService.getHallForHotel(hallId, hotelId)
  await availabilityService.deleteBlock({ hallId, blockId })
  sendNoContent(res)
})

/**
 * Public — flat route, no `:hotelId`. A Hidden Hall (Hotel not eligible)
 * is `404`, identical to every other public Hall read (Technical Design
 * §10/§11).
 */
export const getPublicAvailability = asyncHandler(async (req, res) => {
  const { hallId } = req.params
  const blocks = await availabilityService.getPublicAvailability({ hallId, date: req.query.date })
  sendSuccess(res, {
    statusCode: 200,
    message: 'Availability retrieved successfully.',
    data: { busyPeriods: blocks.map(toPublicBusyPeriod) },
  })
})

export const checkAvailability = asyncHandler(async (req, res) => {
  const { hallId } = req.params
  const { date, startTime, endTime } = req.body
  const result = await availabilityService.checkAvailability({ hallId, date, startTime, endTime })
  sendSuccess(res, {
    statusCode: 200,
    message: 'Availability checked successfully.',
    data: result,
  })
})
