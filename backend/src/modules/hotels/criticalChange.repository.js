import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for the
 * CriticalInformationChangeRequest entity (coding-standards.md §5).
 */

export function findOpenByHotelId(hotelId) {
  return prisma.criticalInformationChangeRequest.findFirst({
    where: { hotelId, status: 'PENDING' },
    orderBy: { createdAt: 'desc' },
  })
}

export function findById(id) {
  return prisma.criticalInformationChangeRequest.findUnique({ where: { id } })
}

export function create(hotelId, proposedData) {
  return prisma.criticalInformationChangeRequest.create({
    data: { hotelId, proposedData },
  })
}

export function decide(id, { status, decidedByUserId }) {
  return prisma.criticalInformationChangeRequest.update({
    where: { id },
    data: { status, decidedByUserId, decidedAt: new Date() },
  })
}
