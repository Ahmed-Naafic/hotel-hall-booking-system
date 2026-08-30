import { prisma } from '../../shared/prismaClient.js'

export function findUserById(userId) {
  return prisma.user.findFirst({ where: { id: userId, deletedAt: null } })
}

export function findProfileByUserId(userId) {
  return prisma.customerProfile.findFirst({ where: { userId, deletedAt: null } })
}

export function createProfile({ userId, profileData }) {
  return prisma.customerProfile.create({ data: { userId, profileData } })
}

export function updateProfile({ userId, profileData }) {
  return prisma.customerProfile.update({ where: { userId }, data: { profileData } })
}
