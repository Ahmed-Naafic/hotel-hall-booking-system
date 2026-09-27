import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for the Hotel entity
 * (coding-standards.md §5). No business logic — takes parameters, runs a
 * query, returns data.
 */

// The registering Hotel Manager's own identity (BDR-019) — never
// `passwordHash` or any other credential field. Included on every query
// that feeds `hotel.mapper.js#toPublicHotel` (the Manager's own view and
// the Platform Administrator's review view; never the Customer-facing
// mappers, which use the separate `publicInclude` below and never join
// this relation at all).
const managerInclude = { registeredBy: { select: { id: true, fullName: true, mobileNumber: true } } }

export function create({ registeredByUserId, profileData }) {
  return prisma.hotel.create({
    data: { registeredByUserId, profileData },
    include: managerInclude,
  })
}

export function findById(id) {
  return prisma.hotel.findUnique({
    where: { id, deletedAt: null },
    include: { media: { where: { deletedAt: null }, orderBy: { createdAt: 'asc' } }, ...managerInclude },
  })
}

export function findByIdForOwner(id, registeredByUserId) {
  return prisma.hotel.findFirst({
    where: { id, registeredByUserId, deletedAt: null },
    include: { media: { where: { deletedAt: null }, orderBy: { createdAt: 'asc' } }, ...managerInclude },
  })
}

export function findLatestByOwner(registeredByUserId) {
  return prisma.hotel.findFirst({
    where: { registeredByUserId, deletedAt: null },
    orderBy: { createdAt: 'desc' },
    include: { media: { where: { deletedAt: null }, orderBy: { createdAt: 'asc' } }, ...managerInclude },
  })
}

// Status-only projections backing the Eligibility Query Interface
// (eligibility.service.js), which never reads anything but `status`. The
// `findById` above joins media and the registering Manager on every call —
// wasted work when the caller only asks "is this Hotel eligible?", and
// multiplied by every Hall on a browse page before `findStatusesByIds`
// collapsed that into one query.
/**
 * Every Hotel this Manager registered, ids only — the tenant boundary
 * synchronization scopes itself by (Local-First Technical Design §6).
 *
 * A list rather than a single id even though no approved journey gives a
 * Manager more than one Hotel: `Hotel`'s own schema comment records that the
 * Glossary says "at least one", and a scope that is already a list cannot be
 * silently widened later by a caller that assumed a scalar.
 */
export function listIdsByOwner(registeredByUserId) {
  return prisma.hotel.findMany({
    where: { registeredByUserId, deletedAt: null },
    select: { id: true },
  })
}

export function findStatusById(id) {
  return prisma.hotel.findUnique({
    where: { id, deletedAt: null },
    select: { id: true, status: true },
  })
}

export function findStatusesByIds(ids) {
  return prisma.hotel.findMany({
    where: { id: { in: ids }, deletedAt: null },
    select: { id: true, status: true },
  })
}

export function updateProfileData(id, profileData, client = prisma) {
  return client.hotel.update({ where: { id }, data: { profileData }, include: managerInclude })
}

// `application.service.js` calls this from inside `prisma.$transaction`
// blocks (its own default, tight timeout) and always discards the return
// value there — only the non-transactional (default `prisma`) callers
// (profile.service.js, suspension.service.js) actually consume the
// `registeredBy` field via `toPublicHotel`. Skip the extra join whenever a
// transactional `client` is passed, so it never adds latency to those
// already latency-sensitive transactions.
export function updateStatus(id, status, client = prisma) {
  return client.hotel.update({
    where: { id },
    data: { status },
    ...(client === prisma ? { include: managerInclude } : {}),
  })
}

/**
 * Re-publishes everything whose Customer-visibility depends on this Hotel's
 * status (Phase 0/S-06).
 *
 * A Hall carries no copy of its Hotel's status — `visibility.service.js#computeVisibility`
 * derives it live from the Eligibility Query Interface. So suspending a Hotel
 * writes exactly one row, `hotels.status`, while silently hiding every one of
 * its Halls and their photos from every Customer. No timestamp or sequence on
 * those rows moves, so a replicated client would keep showing a marketplace
 * that no longer exists until something unrelated happened to touch them.
 *
 * Bumping `sync_seq` here is what turns a derived change into an ordinary one
 * the existing cursor mechanism already carries. It is deliberately a write
 * fan-out rather than denormalising eligibility onto `Hall`: this project
 * commits to eligibility being computed in exactly one place
 * (`architecture-principles.md` §5), and a copied status column would be a
 * second source of truth for it.
 *
 * One statement, so it is atomic on its own even when no surrounding
 * transaction is supplied. Bounded by one Hotel's Hall count, on an action a
 * Platform Administrator performs rarely.
 */
export function touchSyncDependents(hotelId, client = prisma) {
  return client.$executeRaw`
    WITH bumped_halls AS (
      UPDATE halls SET sync_seq = nextval('sync_seq')
       WHERE hotel_id = ${hotelId}::uuid
       RETURNING id
    ), bumped_hotel_media AS (
      UPDATE hotel_media SET sync_seq = nextval('sync_seq')
       WHERE hotel_id = ${hotelId}::uuid
       RETURNING id
    )
    UPDATE hall_media SET sync_seq = nextval('sync_seq')
     WHERE hall_id IN (SELECT id FROM bumped_halls)
  `
}

export function list({ status, skip, take }) {
  return prisma.hotel.findMany({
    where: { deletedAt: null, ...(status ? { status } : {}) },
    skip,
    take,
    orderBy: { createdAt: 'desc' },
    include: { media: { where: { deletedAt: null }, orderBy: { createdAt: 'asc' } }, ...managerInclude },
  })
}

export function count({ status }) {
  return prisma.hotel.count({ where: { deletedAt: null, ...(status ? { status } : {}) } })
}

const publicInclude = {
  media: { where: { deletedAt: null }, orderBy: { createdAt: 'asc' } },
}

// `BDR-020` — case-insensitive, partial match against Hotel Name and the
// customer-facing address (`BDR-017`'s `location.address`), evaluated in
// PostgreSQL via Prisma's JSON path filtering — never by loading candidate
// Hotels into the application to filter there (rejected at any Hotel-count
// scale, per BDR-020's own Options Considered).
function searchWhere(search) {
  if (!search) return {}
  return {
    OR: [
      { profileData: { path: ['name'], string_contains: search, mode: 'insensitive' } },
      { profileData: { path: ['location', 'address'], string_contains: search, mode: 'insensitive' } },
    ],
  }
}

export function listPublic({ cursor, take, search }) {
  return prisma.hotel.findMany({
    where: { deletedAt: null, status: 'APPROVED_ACTIVE', ...searchWhere(search) },
    include: publicInclude,
    take,
    ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
    // `id` breaks ties on `createdAt` — without it two Hotels sharing a
    // timestamp have no defined order between pages, so a cursor can skip
    // one or return it twice. Same two-key ordering every other
    // cursor-paginated list in the project already uses
    // (`notification.repository.js`, `booking.repository.js`,
    // `review.repository.js`, `chat.repository.js`).
    orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
  })
}

export function findPublicById(id) {
  return prisma.hotel.findFirst({
    where: { id, deletedAt: null, status: 'APPROVED_ACTIVE' },
    include: publicInclude,
  })
}

/**
 * Every Customer-visible Hotel, unpaginated — the candidate set Nearby
 * Hotels (hotel.service.js#listNearbyPublicHotels) filters down by
 * coordinate validity and the fixed 5km radius. Same eligibility filter as
 * listPublic/findPublicById (BR: only APPROVED_ACTIVE is Customer-visible).
 */
/**
 * The candidate set Nearby Hotels filters by distance — `id` and
 * `profileData` only, no joins.
 *
 * Measured at 2,000 approved Hotels: joining media here (which the previous
 * `findAllApprovedActive` did) cost 169ms median for an endpoint that keeps
 * roughly 38 rows, because every Hotel's photos were fetched to answer a
 * question only its coordinates can answer. `profileData` is still needed in
 * full — it carries the coordinates, and the name/address the optional
 * `search` matches against.
 *
 * Same lean-candidates-then-hydrate-the-winners shape
 * `visibility.service.js#listLargeHalls` already uses with
 * `hallRepository.findAllCandidatesForRanking` / `hydrateByIds`.
 */
export function findProximityCandidates() {
  return prisma.hotel.findMany({
    where: { deletedAt: null, status: 'APPROVED_ACTIVE' },
    select: { id: true, profileData: true },
  })
}

/**
 * Popular Hotels — the same Customer-visible eligibility filter as
 * listPublic/findPublicById/findProximityCandidates, scoped to a specific
 * candidate id set (the Hotels with at least one qualifying Booking).
 * Halls are included (non-deleted only) so the service layer can apply the
 * "at least one Hall" requirement without a second query.
 */
export function findApprovedActiveByIds(ids) {
  return prisma.hotel.findMany({
    where: { id: { in: ids }, deletedAt: null, status: 'APPROVED_ACTIVE' },
    include: {
      ...publicInclude,
      halls: { where: { deletedAt: null }, select: { id: true } },
    },
  })
}
