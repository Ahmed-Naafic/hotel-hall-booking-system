import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for SavedHotel — no business logic
 * (coding-standards.md §5).
 */

export function findHotelForSave(hotelId) {
  return prisma.hotel.findFirst({ where: { id: hotelId, deletedAt: null }, select: { id: true } })
}

export function findSaved(customerUserId, hotelId) {
  return prisma.savedHotel.findUnique({
    where: { customerUserId_hotelId: { customerUserId, hotelId } },
  })
}

export function save(customerUserId, hotelId) {
  return prisma.savedHotel.upsert({
    where: { customerUserId_hotelId: { customerUserId, hotelId } },
    create: { customerUserId, hotelId },
    update: {},
  })
}

export function unsave(customerUserId, hotelId) {
  return prisma.savedHotel.deleteMany({ where: { customerUserId, hotelId } })
}

export function listHotelIds(customerUserId) {
  return prisma.savedHotel.findMany({
    where: { customerUserId },
    select: { hotelId: true },
    orderBy: { createdAt: 'desc' },
  })
}
