import { prisma } from '../../shared/prismaClient.js'

export function create({ id, hallId, type, storagePath }) {
  return prisma.hallMedia.create({ data: { id, hallId, type, storagePath } })
}

export function findById(id) {
  return prisma.hallMedia.findUnique({ where: { id } })
}

export function findByIdForHall(id, hallId) {
  return prisma.hallMedia.findFirst({ where: { id, hallId } })
}

export function findPhotosForHall(hallId) {
  return prisma.hallMedia.findMany({ where: { hallId, type: 'PHOTO' }, orderBy: { createdAt: 'asc' } })
}

export function remove(id) {
  return prisma.hallMedia.delete({ where: { id } })
}
