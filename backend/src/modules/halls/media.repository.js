import { prisma } from '../../shared/prismaClient.js'

export function create({ id, hallId, type, storagePath }) {
  return prisma.hallMedia.create({ data: { id, hallId, type, storagePath } })
}

// `findFirst`, not `findUnique`: a unique lookup cannot carry the
// tombstone filter (Phase 0/S-05).
export function findById(id) {
  return prisma.hallMedia.findFirst({ where: { id, deletedAt: null } })
}

export function findByIdForHall(id, hallId) {
  return prisma.hallMedia.findFirst({ where: { id, hallId, deletedAt: null } })
}

export function findPhotosForHall(hallId) {
  return prisma.hallMedia.findMany({ where: { hallId, type: 'PHOTO', deletedAt: null }, orderBy: { createdAt: 'asc' } })
}

/**
 * Soft delete (Phase 0/S-05). This row used to be removed outright, which a
 * replicated client cannot detect — absence is not a change, so a deleted
 * photo would stay on the device forever. The Supabase object is still
 * deleted by the service layer; this row survives only as a tombstone, and
 * every read below filters it out.
 */
export function remove(id) {
  return prisma.hallMedia.update({ where: { id }, data: { deletedAt: new Date() } })
}
