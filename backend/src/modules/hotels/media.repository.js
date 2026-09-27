import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for the HotelMedia entity
 * (coding-standards.md §5). No business logic — takes parameters, runs a
 * query, returns data.
 */

export function create({ id, hotelId, type, storagePath }) {
  return prisma.hotelMedia.create({ data: { id, hotelId, type, storagePath } })
}

// `findFirst`, not `findUnique`: a unique lookup cannot carry the
// tombstone filter (Phase 0/S-05).
export function findById(id) {
  return prisma.hotelMedia.findFirst({ where: { id, deletedAt: null } })
}

/** Own-Hotel scoping (Technical Design §12) — mirrors hotel.repository.js#findByIdForOwner. */
export function findByIdForHotel(id, hotelId) {
  return prisma.hotelMedia.findFirst({ where: { id, hotelId, deletedAt: null } })
}

export function findLogoForHotel(hotelId) {
  return prisma.hotelMedia.findFirst({ where: { hotelId, type: 'LOGO', deletedAt: null } })
}

export function findPhotosForHotel(hotelId) {
  return prisma.hotelMedia.findMany({ where: { hotelId, type: 'PHOTO', deletedAt: null }, orderBy: { createdAt: 'asc' } })
}

/**
 * Soft delete (Phase 0/S-05). This row used to be removed outright, which a
 * replicated client cannot detect — absence is not a change, so a deleted
 * photo would stay on the device forever. The Supabase object is still
 * deleted by the service layer; this row survives only as a tombstone, and
 * every read below filters it out.
 */
export function remove(id) {
  return prisma.hotelMedia.update({ where: { id }, data: { deletedAt: new Date() } })
}
