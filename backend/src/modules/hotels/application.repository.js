import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for the HotelApplication entity
 * (coding-standards.md §5).
 */

export function findOpenByHotelId(hotelId, client = prisma) {
  return client.hotelApplication.findFirst({
    where: { hotelId, status: 'OPEN' },
    orderBy: { createdAt: 'desc' },
  })
}

export function findLatestByHotelId(hotelId, client = prisma) {
  return client.hotelApplication.findFirst({
    where: { hotelId },
    orderBy: { submittedAt: 'desc' },
  })
}

export function listByHotelId(hotelId, client = prisma) {
  return client.hotelApplication.findMany({
    where: { hotelId },
    orderBy: { submittedAt: 'desc' },
  })
}

export function findById(id, client = prisma) {
  return client.hotelApplication.findUnique({ where: { id } })
}

export function create(hotelId, client = prisma) {
  return client.hotelApplication.create({ data: { hotelId } })
}

export function decide(id, { status, decidedByUserId, decisionReason }, client = prisma) {
  return client.hotelApplication.update({
    where: { id },
    data: { status, decidedByUserId, decisionReason: decisionReason ?? null, decidedAt: new Date() },
  })
}

export function withdraw(id, client = prisma) {
  return client.hotelApplication.update({
    where: { id },
    data: { status: 'WITHDRAWN', decidedAt: new Date() },
  })
}
