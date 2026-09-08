import { prisma } from '../../shared/prismaClient.js'

const db = (client) => client ?? prisma

export function findUserById(userId) {
  return prisma.user.findFirst({ where: { id: userId, deletedAt: null } })
}

export function findProfileByUserId(userId, client) {
  return db(client).customerProfile.findFirst({ where: { userId, deletedAt: null } })
}

// `client` (a `prisma.$transaction` callback's client) lets a Customer
// registration create the User and this profile as one atomic unit
// (BDR-018) — see authentication.service.js#register.
export function createProfile({ userId, profileData }, client) {
  return db(client).customerProfile.create({ data: { userId, profileData } })
}

export function updateProfile({ userId, profileData }) {
  return prisma.customerProfile.update({ where: { userId }, data: { profileData } })
}
