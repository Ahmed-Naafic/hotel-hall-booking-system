import { Router } from 'express'
import * as availabilityController from './availability.controller.js'
import * as availabilityValidation from './availability.validation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'
import { requireAccountType } from '../../shared/middleware/authorize.js'

/**
 * Route definitions only (coding-standards.md §5). Two routers from one
 * file, mirroring `halls/hall.routes.js`'s own `hallRouter`/
 * `hotelHallsRouter` split:
 *
 * - `hallAvailabilityRouter` — own-Hotel-scoped Manager block management,
 *   mounted at `/api/v1/hotels/:hotelId/halls/:hallId/availability`.
 * - `publicHallAvailabilityRouter` — the flat, public Customer surface,
 *   mounted at `/api/v1/halls/:hallId/availability` (Approved Technical
 *   Design decision 3 — lives entirely in this module, never duplicated
 *   into `halls/hall.routes.js`).
 */
export const hallAvailabilityRouter = Router({ mergeParams: true })

hallAvailabilityRouter.get(
  '/blocks',
  authenticate,
  requireAccountType('HOTEL_MANAGER'),
  availabilityValidation.validateDateQuery,
  availabilityController.listBlocksForManager,
)
hallAvailabilityRouter.post(
  '/blocks',
  authenticate,
  requireAccountType('HOTEL_MANAGER'),
  availabilityValidation.validateCreateBlock,
  availabilityController.createBlock,
)
hallAvailabilityRouter.patch(
  '/blocks/:blockId',
  authenticate,
  requireAccountType('HOTEL_MANAGER'),
  availabilityValidation.validateUpdateBlock,
  availabilityController.updateBlock,
)
hallAvailabilityRouter.delete(
  '/blocks/:blockId',
  authenticate,
  requireAccountType('HOTEL_MANAGER'),
  availabilityController.deleteBlock,
)

export const publicHallAvailabilityRouter = Router({ mergeParams: true })

publicHallAvailabilityRouter.get(
  '/',
  availabilityValidation.validateDateQuery,
  availabilityController.getPublicAvailability,
)
publicHallAvailabilityRouter.post(
  '/check',
  authenticate,
  requireAccountType('CUSTOMER'),
  availabilityValidation.validateCheckAvailability,
  availabilityController.checkAvailability,
)
