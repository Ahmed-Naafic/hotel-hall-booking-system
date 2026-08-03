import { prisma } from '../../shared/prismaClient.js'

/** The only place Prisma Client is called for the Session entity (coding-standards.md §5). */

export function create({ userId, refreshTokenHash, expiresAt }) {
  return prisma.session.create({ data: { userId, refreshTokenHash, expiresAt } })
}

export function findByRefreshTokenHash(refreshTokenHash) {
  return prisma.session.findUnique({ where: { refreshTokenHash } })
}

export function rotate(sessionId, { refreshTokenHash, expiresAt }) {
  return prisma.session.update({
    where: { id: sessionId },
    data: { refreshTokenHash, expiresAt },
  })
}

export function revoke(sessionId) {
  return prisma.session.update({
    where: { id: sessionId },
    data: { revokedAt: new Date() },
  })
}

export function revokeAllForUser(userId) {
  return prisma.session.updateMany({
    where: { userId, revokedAt: null },
    data: { revokedAt: new Date() },
  })
}
