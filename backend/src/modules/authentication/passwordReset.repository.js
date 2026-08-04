import { prisma } from '../../shared/prismaClient.js'

/** The only place Prisma Client is called for the PasswordResetRequest entity (coding-standards.md §5). */

export function create({ userId, tokenHash, expiresAt }) {
  return prisma.passwordResetRequest.create({ data: { userId, tokenHash, expiresAt } })
}

/** The most recent, still-pending (unused) request for a user, if any. */
export function findActiveForUser(userId) {
  return prisma.passwordResetRequest.findFirst({
    where: { userId, usedAt: null },
    orderBy: { createdAt: 'desc' },
  })
}

/** Invalidates every pending request for a user — keeps "at most one active at a time" (Technical Design §5.1). */
export function invalidateActiveForUser(userId) {
  return prisma.passwordResetRequest.updateMany({
    where: { userId, usedAt: null },
    data: { usedAt: new Date() },
  })
}

export function markUsed(id) {
  return prisma.passwordResetRequest.update({ where: { id }, data: { usedAt: new Date() } })
}
