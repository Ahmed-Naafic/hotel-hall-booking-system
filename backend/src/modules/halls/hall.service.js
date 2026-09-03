import * as hallRepository from './hall.repository.js'
import * as ownershipService from '../hotels/ownership.service.js'
import * as visibilityService from './visibility.service.js'
import { recordAuditEvent } from './audit.js'
import { NotFoundError } from '../../shared/errors/errorTypes.js'

/**
 * Hall Component (Technical Design §3, §4) — creates and retrieves the
 * Hall entity, the aggregate root every other component in this module
 * operates on. Never reasons about visibility itself (visibility.service.js's
 * job, Technical Design §6).
 */

export async function createHall({ hotelId, profileData, commercialData }) {
  const hall = await hallRepository.create({ hotelId, profileData, commercialData })
  recordAuditEvent('HALL_CREATED', { hallId: hall.id, hotelId })
  return hall
}

export async function getHallById(id) {
  const hall = await hallRepository.findById(id)
  if (!hall) {
    throw new NotFoundError('Hall not found.')
  }
  return hall
}

/**
 * Scoped to a specific Hotel — a Hall belonging to a different Hotel is
 * never returned (Technical Design §12, `BR-HALL-10`). Callers (the
 * controller layer) are responsible for having already established that
 * `hotelId` is the one the caller is authorized against.
 */
export async function getHallForHotel(id, hotelId) {
  const hall = await hallRepository.findByIdForHotel(id, hotelId)
  if (!hall) {
    throw new NotFoundError('Hall not found.')
  }
  return hall
}

/** Every Hall for one Hotel, regardless of visibility — the Hotel Manager's own management view. */
export function listHallsForHotel({ hotelId, page = 1, limit = 20 }) {
  const skip = (page - 1) * limit
  return Promise.all([
    hallRepository.listByHotelId({ hotelId, skip, take: limit }),
    hallRepository.countByHotelId(hotelId),
  ])
}

/**
 * Own-Hotel authorization (Technical Design §12, `BR-HALL-10`) — resolves
 * whether the caller owns `hotelId`, through Hotel Management's Hotel
 * Ownership Query Interface (`hotels/ownership.service.js`, Approved
 * Technical Design v1.5). Never reaches into Hotel Management's table
 * directly (`architecture-principles.md` §5) — only this module's own
 * service layer talks to another module's interface, the same discipline
 * `visibility.service.js` already applies to the Eligibility Query
 * Interface.
 */
export function isOwnHotel(hotelId, userId) {
  return ownershipService.isOwnedByUser(hotelId, userId)
}

/**
 * Guards the write endpoints (`POST`/`PATCH`, WBS-05) — cross-tenant and
 * nonexistent `hotelId` both resolve to `404`, never `403`
 * (`api-standards.md` §13, Technical Design §12/§16).
 */
export async function assertOwnHotel(hotelId, userId) {
  const owned = await isOwnHotel(hotelId, userId)
  if (!owned) {
    throw new NotFoundError('Hotel not found.')
  }
}

/**
 * Single-Hall read, scoped to `:hotelId` and gated by visibility for a
 * non-owner (`GET /hotels/:hotelId/halls/:id`, Technical Design §11,
 * §14.3) — the owning Hotel Manager always sees the Hall regardless of
 * visibility (`BR-HALL-02`); anyone else only if it's Visible. A Hidden
 * Hall and a nonexistent one are both `404`, never distinguished
 * (`api-standards.md` §9's "never leak existence", generalized to
 * visibility per Technical Design §6/§12).
 */
export async function getHallScoped({ id, hotelId, userId }) {
  const isOwner = userId ? await isOwnHotel(hotelId, userId) : false
  const hall = await getHallForHotel(id, hotelId)
  const visible = await visibilityService.isHallVisible(hall, { isOwner })
  if (!visible) {
    throw new NotFoundError('Hall not found.')
  }
  return hall
}

/**
 * Hall list, scoped to `:hotelId` (`GET /hotels/:hotelId/halls`, Technical
 * Design §11) — the owning Hotel Manager sees every Hall; anyone else sees
 * the full page only while the Hotel is eligible, or an empty page
 * otherwise (every Hall under one Hotel shares the identical eligibility
 * outcome, Technical Design §6, so a single Hotel-level check replaces
 * what would otherwise be a per-Hall N+1 — the accepted N+1 characteristic,
 * Technical Design §18 Item 5, applies only to the platform-wide,
 * multi-Hotel browse endpoint, not this single-Hotel list). `404` if
 * `:hotelId` doesn't exist at all, offset pagination (`coding-standards.md`
 * §6 — a bounded, per-Hotel list).
 */
export async function listHallsForHotelScoped({ hotelId, userId, page = 1, limit = 20 }) {
  const isOwner = userId ? await isOwnHotel(hotelId, userId) : false

  if (!isOwner) {
    const { found, eligible } = await visibilityService.getHotelEligibility(hotelId)
    if (!found) {
      throw new NotFoundError('Hotel not found.')
    }
    if (!eligible) {
      return { halls: [], total: 0 }
    }
  }

  const [halls, total] = await listHallsForHotel({ hotelId, page, limit })
  return { halls, total }
}
