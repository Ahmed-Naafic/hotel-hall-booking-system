import { prisma } from '../../shared/prismaClient.js'

const db = (client) => client ?? prisma
const includeDetails = { hall: true, hotel: true, review: true }

/**
 * Popular Hotels (Customer Mobile, Hotel Management's own read model) —
 * a single database-side GROUP BY per qualifying status, never a per-Hotel
 * query and never every Booking loaded into memory. `dateField` is whichever
 * timestamp represents "when this Booking most recently entered `status`"
 * (no dedicated confirmedAt column exists — CONFIRMED's own updatedAt is
 * the closest authoritative signal Prisma's @updatedAt already maintains;
 * COMPLETED has its own explicit completedAt).
 */
export function aggregateQualifyingBookingCountsByHotel({ status, dateField, since }) {
  return prisma.booking.groupBy({
    by: ['hotelId'],
    where: { status, [dateField]: { gte: since } },
    _count: { _all: true },
    _max: { [dateField]: true },
    orderBy: { hotelId: 'asc' },
  })
}

export function findCustomer(userId, client) {
  return db(client).user.findFirst({ where: { id: userId, accountType: 'CUSTOMER', deletedAt: null } })
}

export function findHallWithHotel(hallId, client) {
  return db(client).hall.findFirst({ where: { id: hallId, deletedAt: null }, include: { hotel: true } })
}

export function create(data, client) {
  return db(client).booking.create({ data, include: includeDetails })
}

export function findForCustomer(id, customerUserId, client) {
  return db(client).booking.findFirst({ where: { id, customerUserId }, include: includeDetails })
}

export function findForHotel(id, hotelId, client) {
  return db(client).booking.findFirst({ where: { id, hotelId }, include: includeDetails })
}

export function update(id, data, client) {
  return db(client).booking.update({ where: { id }, data, include: includeDetails })
}

export function expireOverdue(where, now = new Date(), client) {
  return db(client).booking.updateMany({
    where: { ...where, status: 'PENDING', paymentDeadlineAt: { lte: now }, paymentStatus: { not: 'PAID' } },
    data: { status: 'EXPIRED' },
  })
}

export function listForCustomer({ customerUserId, cursor, take }) {
  return prisma.booking.findMany({
    where: { customerUserId }, include: includeDetails, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take,
    ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
  })
}

export function listForHotel({ hotelId, status, cursor, take }) {
  return prisma.booking.findMany({
    where: { hotelId, ...(status ? { status } : {}) }, include: includeDetails,
    orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take,
    ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
  })
}
