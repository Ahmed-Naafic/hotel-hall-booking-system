import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for the Hotel entity
 * (coding-standards.md §5). No business logic — takes parameters, runs a
 * query, returns data.
 */

// The registering Hotel Manager's own identity (BDR-019) — never
// `passwordHash` or any other credential field. Included on every query
// that feeds `hotel.mapper.js#toPublicHotel` (the Manager's own view and
// the Platform Administrator's review view; never the Customer-facing
// mappers, which use the separate `publicInclude` below and never join
// this relation at all).
const managerInclude = { registeredBy: { select: { id: true, fullName: true, mobileNumber: true } } }

export function create({ registeredByUserId, profileData }) {
  return prisma.hotel.create({
    data: { registeredByUserId, profileData },
    include: managerInclude,
  })
}

export function findById(id) {
  return prisma.hotel.findUnique({
    where: { id, deletedAt: null },
    include: { media: { orderBy: { createdAt: 'asc' } }, ...managerInclude },
  })
}

export function findByIdForOwner(id, registeredByUserId) {
  return prisma.hotel.findFirst({
    where: { id, registeredByUserId, deletedAt: null },
    include: { media: { orderBy: { createdAt: 'asc' } }, ...managerInclude },
  })
}

export function findLatestByOwner(registeredByUserId) {
  return prisma.hotel.findFirst({
    where: { registeredByUserId, deletedAt: null },
    orderBy: { createdAt: 'desc' },
    include: { media: { orderBy: { createdAt: 'asc' } }, ...managerInclude },
  })
}

export function updateProfileData(id, profileData, client = prisma) {
  return client.hotel.update({ where: { id }, data: { profileData }, include: managerInclude })
}

// `application.service.js` calls this from inside `prisma.$transaction`
// blocks (its own default, tight timeout) and always discards the return
// value there — only the non-transactional (default `prisma`) callers
// (profile.service.js, suspension.service.js) actually consume the
// `registeredBy` field via `toPublicHotel`. Skip the extra join whenever a
// transactional `client` is passed, so it never adds latency to those
// already latency-sensitive transactions.
export function updateStatus(id, status, client = prisma) {
  return client.hotel.update({
    where: { id },
    data: { status },
    ...(client === prisma ? { include: managerInclude } : {}),
  })
}

export function list({ status, skip, take }) {
  return prisma.hotel.findMany({
    where: { deletedAt: null, ...(status ? { status } : {}) },
    skip,
    take,
    orderBy: { createdAt: 'desc' },
    include: { media: { orderBy: { createdAt: 'asc' } }, ...managerInclude },
  })
}

export function count({ status }) {
  return prisma.hotel.count({ where: { deletedAt: null, ...(status ? { status } : {}) } })
}

const publicInclude = {
  media: { orderBy: { createdAt: 'asc' } },
}

export function listPublic({ cursor, take }) {
  return prisma.hotel.findMany({
    where: { deletedAt: null, status: 'APPROVED_ACTIVE' },
    include: publicInclude,
    take,
    ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
    orderBy: { createdAt: 'desc' },
  })
}

export function findPublicById(id) {
  return prisma.hotel.findFirst({
    where: { id, deletedAt: null, status: 'APPROVED_ACTIVE' },
    include: publicInclude,
  })
}

/**
 * Every Customer-visible Hotel, unpaginated — the candidate set Nearby
 * Hotels (hotel.service.js#listNearbyPublicHotels) filters down by
 * coordinate validity and the fixed 5km radius. Same eligibility filter as
 * listPublic/findPublicById (BR: only APPROVED_ACTIVE is Customer-visible).
 */
export function findAllApprovedActive() {
  return prisma.hotel.findMany({
    where: { deletedAt: null, status: 'APPROVED_ACTIVE' },
    include: publicInclude,
  })
}

/**
 * Popular Hotels — the same Customer-visible eligibility filter as
 * listPublic/findPublicById/findAllApprovedActive, scoped to a specific
 * candidate id set (the Hotels with at least one qualifying Booking).
 * Halls are included (non-deleted only) so the service layer can apply the
 * "at least one Hall" requirement without a second query.
 */
export function findApprovedActiveByIds(ids) {
  return prisma.hotel.findMany({
    where: { id: { in: ids }, deletedAt: null, status: 'APPROVED_ACTIVE' },
    include: {
      ...publicInclude,
      halls: { where: { deletedAt: null }, select: { id: true } },
    },
  })
}
