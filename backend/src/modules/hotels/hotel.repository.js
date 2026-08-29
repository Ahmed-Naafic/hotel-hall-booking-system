import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for the Hotel entity
 * (coding-standards.md §5). No business logic — takes parameters, runs a
 * query, returns data.
 */

export function create({ registeredByUserId, profileData }) {
  return prisma.hotel.create({
    data: { registeredByUserId, profileData },
  })
}

export function findById(id) {
  return prisma.hotel.findUnique({ where: { id, deletedAt: null } })
}

export function findByIdForOwner(id, registeredByUserId) {
  return prisma.hotel.findFirst({ where: { id, registeredByUserId, deletedAt: null } })
}

export function findLatestByOwner(registeredByUserId) {
  return prisma.hotel.findFirst({
    where: { registeredByUserId, deletedAt: null },
    orderBy: { createdAt: 'desc' },
  })
}

export function updateProfileData(id, profileData, client = prisma) {
  return client.hotel.update({ where: { id }, data: { profileData } })
}

export function updateStatus(id, status, client = prisma) {
  return client.hotel.update({ where: { id }, data: { status } })
}

export function list({ status, skip, take }) {
  return prisma.hotel.findMany({
    where: { deletedAt: null, ...(status ? { status } : {}) },
    skip,
    take,
    orderBy: { createdAt: 'desc' },
  })
}

export function count({ status }) {
  return prisma.hotel.count({ where: { deletedAt: null, ...(status ? { status } : {}) } })
}
