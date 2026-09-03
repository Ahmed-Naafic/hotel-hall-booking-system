import { prisma } from '../../shared/prismaClient.js'

const db = (client) => client ?? prisma
const includeDetails = { hall: true, hotel: true }

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
