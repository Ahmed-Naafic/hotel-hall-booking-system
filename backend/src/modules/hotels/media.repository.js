import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for the HotelMedia entity
 * (coding-standards.md §5). No business logic — takes parameters, runs a
 * query, returns data.
 */

export function create({ id, hotelId, type, storagePath }) {
  return prisma.hotelMedia.create({ data: { id, hotelId, type, storagePath } })
}

export function findById(id) {
  return prisma.hotelMedia.findUnique({ where: { id } })
}

/** Own-Hotel scoping (Technical Design §12) — mirrors hotel.repository.js#findByIdForOwner. */
export function findByIdForHotel(id, hotelId) {
  return prisma.hotelMedia.findFirst({ where: { id, hotelId } })
}

export function findLogoForHotel(hotelId) {
  return prisma.hotelMedia.findFirst({ where: { hotelId, type: 'LOGO' } })
}

export function findPhotosForHotel(hotelId) {
  return prisma.hotelMedia.findMany({ where: { hotelId, type: 'PHOTO' }, orderBy: { createdAt: 'asc' } })
}

export function remove(id) {
  return prisma.hotelMedia.delete({ where: { id } })
}
