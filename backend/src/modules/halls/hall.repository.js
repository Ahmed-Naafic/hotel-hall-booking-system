import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for the Hall entity
 * (coding-standards.md §5). No business logic — takes parameters, runs a
 * query, returns data.
 */

export function create({ hotelId, profileData, commercialData }) {
  return prisma.hall.create({
    data: { hotelId, profileData: profileData ?? null, ...commercialData },
  })
}

export function findById(id) {
  return prisma.hall.findUnique({ where: { id, deletedAt: null } })
}

/** Own-Hotel scoping (Technical Design §12) — a Hall belonging to a different Hotel is never returned. */
export function findByIdForHotel(id, hotelId) {
  return prisma.hall.findFirst({ where: { id, hotelId, deletedAt: null }, include: { media: true } })
}

export function updateProfileData(id, profileData) {
  return prisma.hall.update({ where: { id }, data: { profileData } })
}

export function update(id, data) {
  return prisma.hall.update({ where: { id }, data })
}

/**
 * `activeFilter` — `true`/`false` restricts to that `isActive` value,
 * `undefined` applies no filter at all (the owning Manager's own "All"
 * view). `search` matches `profileData.name` the same way Hotel Management
 * already matches Hotel name (`hotel.repository.js`) — one established
 * convention, not a second one invented here.
 */
function hallListWhere({ hotelId, activeFilter, search }) {
  return {
    hotelId,
    deletedAt: null,
    ...(activeFilter === undefined ? {} : { isActive: activeFilter }),
    ...(search ? { profileData: { path: ['name'], string_contains: search, mode: 'insensitive' } } : {}),
  }
}

/** Every Hall for one Hotel matching the given filters — the Hotel Manager's own management view (unfiltered by default, regardless of visibility). */
export function listByHotelId({ hotelId, skip, take, activeFilter, search }) {
  return prisma.hall.findMany({
    where: hallListWhere({ hotelId, activeFilter, search }),
    skip,
    take,
    orderBy: { createdAt: 'desc' },
    include: { media: true },
  })
}

export function countByHotelId(hotelId, { activeFilter, search } = {}) {
  return prisma.hall.count({ where: hallListWhere({ hotelId, activeFilter, search }) })
}

/**
 * Candidate Halls for the platform-wide browse endpoint (Technical Design
 * §11) — cursor-paginated, per `coding-standards.md` §6. Returns raw
 * candidates only; visibility filtering (which Hotel is currently
 * eligible) is the Visibility Component's job, never this repository's
 * (architecture-principles.md §5 — this repository never reaches into
 * Hotel Management's table to pre-filter).
 */
/**
 * Unlike `hallListWhere` above (a single Hotel Manager's own Hotel, so only
 * the Hall's own name is worth matching), this is a platform-wide browse —
 * a Customer typing a familiar Hotel name should find its Halls too, so
 * this matches either.
 */
function browseSearchWhere(search) {
  if (!search) return {}
  return {
    OR: [
      { profileData: { path: ['name'], string_contains: search, mode: 'insensitive' } },
      { hotel: { profileData: { path: ['name'], string_contains: search, mode: 'insensitive' } } },
    ],
  }
}

/**
 * `minPriceCents`/`maxPriceCents` (Advanced Filters, Customer Mobile) apply
 * at the database level — `rentAmountCents` is a real column, unlike
 * capacity (Hall's flexible `profileData`, filtered in-memory by
 * `visibility.service.js` instead, the same place it already reads
 * capacity for Large Halls).
 */
export function listCandidatesForBrowse({ hotelId, cursor, take, minPriceCents, maxPriceCents, search }) {
  return prisma.hall.findMany({
    where: {
      deletedAt: null,
      ...(hotelId ? { hotelId } : {}),
      ...(minPriceCents !== undefined || maxPriceCents !== undefined
        ? { rentAmountCents: { ...(minPriceCents !== undefined ? { gte: minPriceCents } : {}), ...(maxPriceCents !== undefined ? { lte: maxPriceCents } : {}) } }
        : {}),
      ...browseSearchWhere(search),
    },
    take,
    ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
    orderBy: { createdAt: 'desc' },
    include: { media: true, hotel: true },
  })
}

/**
 * Every Hall candidate for capacity ranking (Large Halls) — unfiltered by
 * Hotel eligibility, same as listCandidatesForBrowse above; the Visibility
 * Component (visibility.service.js) applies that filter, never this
 * repository (architecture-principles.md §5).
 *
 * Only the columns that ranking and visibility actually read, because this
 * query is unpaginated by design (the ranking spans the whole table): the
 * display joins would otherwise pull every media row on the platform into
 * memory just to discard all but the top `limit`. `hydrateByIds` below
 * fetches those joins for the winners alone.
 */
export function findAllCandidatesForRanking() {
  return prisma.hall.findMany({
    where: { deletedAt: null },
    select: { id: true, hotelId: true, isActive: true, profileData: true },
  })
}

/** Full display shape for an already-decided set of Halls, order not guaranteed. */
export function hydrateByIds(ids) {
  return prisma.hall.findMany({
    where: { id: { in: ids } },
    include: { media: true, hotel: true },
  })
}
