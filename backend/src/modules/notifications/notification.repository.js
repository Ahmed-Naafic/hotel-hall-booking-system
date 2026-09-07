import { prisma } from '../../shared/prismaClient.js'

/**
 * The only place Prisma Client is called for Notification/DeviceToken — no
 * business logic (coding-standards.md §5).
 */

export function create({ recipientUserId, type, title, body, bookingId, hotelId, hotelApplicationId }) {
  return prisma.notification.create({
    data: {
      recipientUserId,
      type,
      title,
      body,
      bookingId: bookingId ?? null,
      hotelId: hotelId ?? null,
      hotelApplicationId: hotelApplicationId ?? null,
    },
  })
}

export function findByIdForUser(id, recipientUserId) {
  return prisma.notification.findFirst({ where: { id, recipientUserId } })
}

export function listForUser({ recipientUserId, status, cursor, take }) {
  return prisma.notification.findMany({
    where: { recipientUserId, ...(status ? { status } : {}) },
    orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    take,
    ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
  })
}

export function countUnreadForUser(recipientUserId) {
  return prisma.notification.count({ where: { recipientUserId, status: 'UNREAD' } })
}

export function markRead(id) {
  return prisma.notification.update({ where: { id }, data: { status: 'READ', readAt: new Date() } })
}

export function markAllReadForUser(recipientUserId) {
  return prisma.notification.updateMany({
    where: { recipientUserId, status: 'UNREAD' },
    data: { status: 'READ', readAt: new Date() },
  })
}

/** Every currently-active Platform Administrator — Admin notifications broadcast to the role (Business Specification "Recipients"). */
export function listPlatformAdministratorIds() {
  return prisma.user.findMany({
    where: { accountType: 'PLATFORM_ADMINISTRATOR', deletedAt: null, isActive: true },
    select: { id: true },
  })
}

export function upsertDeviceToken({ userId, token, platform }) {
  return prisma.deviceToken.upsert({
    where: { token },
    create: { userId, token, platform: platform ?? null },
    // Re-registering an already-known token moves it to the current owner
    // (a shared device, or logout/login as someone else) rather than
    // leaving it duplicated under a stale user.
    update: { userId, platform: platform ?? null },
  })
}

export function deleteDeviceToken(token) {
  return prisma.deviceToken.deleteMany({ where: { token } })
}

export function listDeviceTokensForUser(userId) {
  return prisma.deviceToken.findMany({ where: { userId }, select: { token: true } })
}
