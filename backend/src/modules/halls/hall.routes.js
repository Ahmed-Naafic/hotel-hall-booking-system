import { Router } from 'express'
import * as hallController from './hall.controller.js'
import * as hallValidation from './hall.validation.js'
import { authenticate, optionalAuthenticate } from '../../shared/middleware/authenticate.js'
import { requireAccountType } from '../../shared/middleware/authorize.js'

/**
 * Route definitions only (coding-standards.md §5) — maps method + path to
 * a controller function. Two routers, two distinct mount points (Technical
 * Design §11's own deliberate distinction):
 *
 * - `hallRouter` — mounted at the flat `/api/v1/halls` (the platform-wide,
 *   public, unconditional browse endpoint, `BR-HALL-08`).
 * - `hotelHallsRouter` — mounted at the nested `/api/v1/hotels/:hotelId/halls`
 *   (WBS-05's own-Hotel-scoped endpoints), `mergeParams: true` so `:hotelId`
 *   from the mount path reaches every handler here.
 */
export const hallRouter = Router()

hallRouter.get('/', hallValidation.validateBrowseHalls, hallController.browseHalls)
hallRouter.get('/large-capacity', hallValidation.validateLargeHalls, hallController.listLargeHalls)

export const hotelHallsRouter = Router({ mergeParams: true })

hotelHallsRouter.post(
  '/',
  authenticate,
  requireAccountType('HOTEL_MANAGER'),
  hallValidation.validateCreateHall,
  hallController.createHall,
)
hotelHallsRouter.get('/', optionalAuthenticate, hallValidation.validateListHallsForHotel, hallController.listHallsForHotel)
hotelHallsRouter.get('/:id', optionalAuthenticate, hallController.getHall)
hotelHallsRouter.patch(
  '/:id',
  authenticate,
  requireAccountType('HOTEL_MANAGER'),
  hallValidation.validateUpdateHall,
  hallController.updateHall,
)
