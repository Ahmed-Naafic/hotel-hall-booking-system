import * as eligibilityService from '../hotels/eligibility.service.js'
import * as hallRepository from './hall.repository.js'

/**
 * Visibility Component (Technical Design §3, §6) — computes whether a
 * given Hall is Hidden or Visible. Never a persisted status; always
 * derived live from Hotel Management's existing Eligibility Query
 * Interface (`eligibility.service.js`), which this module consumes as an
 * in-process call and never re-implements (BR-HALL-05, architecture-
 * principles.md §5).
 *
 * `isOwner` is always an *already-resolved* input here — per Technical
 * Design §6's own flowchart, determining "is the caller the authenticated
 * owning Hotel Manager" is a Security Design (§12) / API-layer concern,
 * not this component's. This split keeps `computeVisibility` a pure
 * function (no I/O), the same shape as `lifecycle.service.js#isValidTransition`
 * in Hotel Management, fully unit-testable without mocking anything.
 */

/**
 * Pure decision function — no I/O. The owning Hotel Manager always sees
 * their own Hall regardless of Hotel eligibility or its own Active/Inactive
 * toggle (`BR-HALL-02`); anyone else sees it only while the owning Hotel is
 * eligible (`BR-HALL-03`, `BR-HALL-04`) AND the Hall itself is Active — the
 * Manager's own on/off switch (`Hall.isActive`), a second, independent gate
 * layered on top of eligibility, never a replacement for it.
 */
export function computeVisibility({ isOwner, eligible, isActive = true }) {
  if (isOwner) {
    return true
  }
  return eligible === true && isActive === true
}

/**
 * Async orchestration — calls the real Eligibility Query Interface. Never
 * mocked in this module's own tests (Implementation Plan §8); exercised
 * against a real Hotel record in integration tests.
 */
export async function isHallVisible(hall, { isOwner }) {
  if (isOwner) {
    return true
  }
  const { eligible } = await eligibilityService.getEligibility(hall.hotelId)
  return computeVisibility({ isOwner, eligible, isActive: hall.isActive })
}

/**
 * Raw pass-through to the Eligibility Query Interface, exposed for
 * `hall.service.js#listHallsForHotelScoped` — a single-Hotel list needs
 * `found` (does the Hotel exist at all, Technical Design §11) as well as
 * `eligible`, neither of which `isHallVisible`/`computeVisibility` above
 * exposes on their own (they only ever return a plain boolean). Kept here,
 * not called directly from `hall.service.js`, so this remains the one
 * place in the module that talks to Hotel Management's Eligibility Query
 * Interface (`architecture-principles.md` §5).
 */
export function getHotelEligibility(hotelId) {
  return eligibilityService.getEligibility(hotelId)
}

/**
 * Filters a list of Halls down to the ones visible to the current caller —
 * used by the platform-wide browse endpoint and any list view a non-owner
 * calls. `isOwner` is per-Hall (a caller may own some, not others, across
 * different Hotels in a hypothetical future multi-Hotel-per-manager
 * scenario, though no approved journey exercises that today).
 */
export async function filterVisible(halls, resolveIsOwner) {
  const isOwnerOf = (hall) => (resolveIsOwner ? resolveIsOwner(hall) : false)
  const eligibilityByHotelId = await eligibilityService.getEligibilityForMany(
    halls.filter((hall) => !isOwnerOf(hall)).map((hall) => hall.hotelId),
  )
  return halls.filter((hall) => {
    const isOwner = isOwnerOf(hall)
    const eligible = isOwner ? true : (eligibilityByHotelId.get(hall.hotelId)?.eligible ?? false)
    return computeVisibility({ isOwner, eligible, isActive: hall.isActive })
  })
}

/**
 * The platform-wide browse query (`GET /api/v1/halls`, Technical Design
 * §11) — public, unconditionally; never returns a Hidden Hall to anyone,
 * including an authenticated Hotel Manager, since it isn't scoped to any
 * one Hotel (§11's own explicit rule) — every candidate is checked with
 * `isOwner: false`.
 *
 * `hasNext`/`nextCursor` are computed against the *raw* candidate page
 * (before visibility filtering), so pagination correctly continues scanning
 * forward even when some candidates on a page are Hidden and filtered out.
 */
/**
 * `minCapacity`/`minPriceCents`/`maxPriceCents` (Advanced Filters, Customer
 * Mobile "All Halls") narrow the same candidate page visibility already
 * filters — never a separate query. Price is pushed to the database
 * (`hallRepository.listCandidatesForBrowse`, a real column); capacity is
 * applied here, in-memory, the same way `listLargeHalls` below already
 * reads it from Hall's flexible `profileData` (no real column exists yet —
 * Pending Business Decision #2). Like the existing visibility filter, this
 * can return fewer than `limit` results on a page without `hasNext` being
 * false — the candidate page itself, not the filtered result, decides
 * pagination, so a Customer scrolling for a rare combination keeps making
 * forward progress via `loadMore` rather than getting stuck on a
 * technically-non-empty but filtered-to-nothing page.
 */
export async function browseVisibleHalls({ hotelId, cursor, limit, minCapacity, minPriceCents, maxPriceCents, search }) {
  const candidates = await hallRepository.listCandidatesForBrowse({ hotelId, cursor, take: limit + 1, minPriceCents, maxPriceCents, search })
  const hasNext = candidates.length > limit
  const page = hasNext ? candidates.slice(0, limit) : candidates
  const visible = await filterVisible(page, () => false)
  const halls = minCapacity === undefined ? visible : visible.filter((hall) => hallCapacity(hall) >= minCapacity)
  const nextCursor = hasNext ? page[page.length - 1].id : null
  return { halls, hasNext, nextCursor }
}

function hallCapacity(hall) {
  const value = Number(hall.profileData?.capacity)
  return Number.isFinite(value) ? value : 0
}

/**
 * Hall-name-only (not Hotel name) — unlike `browseVisibleHalls` below,
 * `findAllCandidatesForRanking`'s own doc comment explains why it
 * deliberately selects only the columns ranking/visibility need, no Hotel
 * join, to avoid pulling every media row on the platform into memory for a
 * query that already scans the whole table. Adding a Hotel-name match here
 * would mean joining that back in for every candidate, not just the
 * `limit` winners this function already hydrates separately.
 */
function hallMatchesSearch(hall, search) {
  if (!search) return true
  const name = hall.profileData?.name
  return typeof name === 'string' && name.toLowerCase().includes(search.toLowerCase())
}

/**
 * Large Halls (Customer Mobile, approved V1 business rules) — every
 * Visible Hall (the same Visibility Component this file already applies to
 * the platform-wide browse above), ranked by capacity descending, tied
 * Halls broken deterministically by id. No new "large" field or
 * classification is stored — "large" is purely this ranking. No pagination
 * (not required for V1); a single bounded, ranked list, sorted in the
 * backend so Customer Mobile never computes the ranking itself.
 */
export async function listLargeHalls({ limit, search }) {
  const candidates = await hallRepository.findAllCandidatesForRanking()
  const visible = await filterVisible(candidates, () => false)
  const ranked = visible
    .filter((hall) => hallMatchesSearch(hall, search))
    .sort((a, b) => {
      const diff = hallCapacity(b) - hallCapacity(a)
      if (diff !== 0) return diff
      return a.id.localeCompare(b.id)
    })
    .slice(0, limit)

  if (ranked.length === 0) {
    return []
  }

  // The ranking above runs on lean rows; only the Halls that survived it are
  // worth the media/hotel display joins.
  const hydratedById = new Map(
    (await hallRepository.hydrateByIds(ranked.map((hall) => hall.id))).map((hall) => [hall.id, hall]),
  )
  return ranked.map((hall) => hydratedById.get(hall.id)).filter(Boolean)
}
