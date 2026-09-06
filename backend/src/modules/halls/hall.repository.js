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

/** Every Hall for one Hotel, regardless of visibility — the Hotel Manager's own management view. */
export function listByHotelId({ hotelId, skip, take }) {
  return prisma.hall.findMany({
    where: { hotelId, deletedAt: null },
    skip,
    take,
    orderBy: { createdAt: 'desc' },
    include: { media: true },
  })
}

export function countByHotelId(hotelId) {
  return prisma.hall.count({ where: { hotelId, deletedAt: null } })
}

/**
 * Candidate Halls for the platform-wide browse endpoint (Technical Design
 * §11) — cursor-paginated, per `coding-standards.md` §6. Returns raw
 * candidates only; visibility filtering (which Hotel is currently
 * eligible) is the Visibility Component's job, never this repository's
 * (architecture-principles.md §5 — this repository never reaches into
 * Hotel Management's table to pre-filter).
 */
export function listCandidatesForBrowse({ hotelId, cursor, take }) {
  return prisma.hall.findMany({
    where: { deletedAt: null, ...(hotelId ? { hotelId } : {}) },
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
 * repository (architecture-principles.md §5). `hotel: true` is a display
 * join (the owning Hotel's name), not a filter criterion.
 */
export function findAllCandidatesForRanking() {
  return prisma.hall.findMany({
    where: { deletedAt: null },
    include: { media: true, hotel: true },
  })
}
