import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for the User Account entity
 * (coding-standards.md §5). No business logic — takes parameters, runs a
 * query, returns data.
 */

const db = (client) => client ?? prisma

export function findByMobileNumber(mobileNumber) {
  return prisma.user.findUnique({ where: { mobileNumber } })
}

export function findById(id) {
  return prisma.user.findUnique({ where: { id } })
}

// `client` (a `prisma.$transaction` callback's client) lets a Customer
// registration create the User and its CustomerProfile (BDR-018) as one
// atomic unit — see authentication.service.js#register. `fullName` is
// stored directly on this row only for a Hotel Manager registration
// (BDR-019) — a Customer's `fullName` argument here is always `undefined`,
// since BDR-018 stores theirs on CustomerProfile instead (never revisited).
export function create({ mobileNumber, passwordHash, accountType, fullName }, client) {
  return db(client).user.create({
    data: { mobileNumber, passwordHash, accountType, fullName },
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
