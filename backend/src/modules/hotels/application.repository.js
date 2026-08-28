import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for the HotelApplication entity
 * (coding-standards.md §5).
 */

export function findOpenByHotelId(hotelId) {
  return prisma.hotelApplication.findFirst({
    where: { hotelId, status: 'OPEN' },
    orderBy: { createdAt: 'desc' },
  })
}

export function findById(id) {
  return prisma.hotelApplication.findUnique({ where: { id } })
}

export function create(hotelId) {
  return prisma.hotelApplication.create({ data: { hotelId } })
}

export function decide(id, { status, decidedByUserId }) {
  return prisma.hotelApplication.update({
    where: { id },
    data: { status, decidedByUserId, decidedAt: new Date() },
  })
}

export function withdraw(id) {
  return prisma.hotelApplication.update({
    where: { id },
    data: { status: 'WITHDRAWN', decidedAt: new Date() },
  })
}
