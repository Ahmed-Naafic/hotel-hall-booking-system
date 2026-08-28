import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for the Hall entity
 * (coding-standards.md §5). No business logic — takes parameters, runs a
 * query, returns data.
 */

export function create({ hotelId, profileData }) {
  return prisma.hall.create({
    data: { hotelId, profileData: profileData ?? null },
  })
}

export function findById(id) {
  return prisma.hall.findUnique({ where: { id, deletedAt: null } })
}

/** Own-Hotel scoping (Technical Design §12) — a Hall belonging to a different Hotel is never returned. */
export function findByIdForHotel(id, hotelId) {
  return prisma.hall.findFirst({ where: { id, hotelId, deletedAt: null } })
}

export function updateProfileData(id, profileData) {
  return prisma.hall.update({ where: { id }, data: { profileData } })
}

/** Every Hall for one Hotel, regardless of visibility — the Hotel Manager's own management view. */
export function listByHotelId({ hotelId, skip, take }) {
  return prisma.hall.findMany({
    where: { hotelId, deletedAt: null },
    skip,
    take,
    orderBy: { createdAt: 'desc' },
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
  })
}
