import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for the User Account entity
 * (coding-standards.md §5). No business logic — takes parameters, runs a
 * query, returns data.
 */

export function findByMobileNumber(mobileNumber) {
  return prisma.user.findUnique({ where: { mobileNumber } })
}

export function findById(id) {
  return prisma.user.findUnique({ where: { id } })
}

export function create({ mobileNumber, passwordHash, accountType }) {
  return prisma.user.create({
    data: { mobileNumber, passwordHash, accountType },
  })
}

export function updatePasswordHash(id, passwordHash) {
  return prisma.user.update({ where: { id }, data: { passwordHash } })
}

export function markVerified(id) {
  return prisma.user.update({ where: { id }, data: { isVerified: true } })
}

export function setActive(id, isActive) {
  return prisma.user.update({ where: { id }, data: { isActive } })
}
