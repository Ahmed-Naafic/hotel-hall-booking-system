import { prisma } from '../../shared/prismaClient.js'

/** The only place Prisma Client is called for the VerificationRequest entity (coding-standards.md §5). */

export function create({ userId, codeHash, expiresAt }) {
  return prisma.verificationRequest.create({ data: { userId, codeHash, expiresAt } })
}

/** The most recent, still-pending (unconfirmed) request for a user, if any. */
export function findActiveForUser(userId) {
  return prisma.verificationRequest.findFirst({
    where: { userId, confirmedAt: null },
    orderBy: { createdAt: 'desc' },
  })
}

export function markConfirmed(id) {
  return prisma.verificationRequest.update({
    where: { id },
    data: { confirmedAt: new Date() },
  })
}
