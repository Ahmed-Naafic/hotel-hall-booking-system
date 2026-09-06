import { after, before, test } from 'node:test'
import assert from 'node:assert/strict'
import { prisma } from '../../../shared/prismaClient.js'
import * as bookingService from '../booking.service.js'
import * as availabilityService from '../../availability/availability.service.js'

let customer
let manager
let hotel
let hall

before(async () => {
  const suffix = `${Date.now()}${Math.floor(Math.random() * 1000)}`
  customer = await prisma.user.create({ data: { mobileNumber: `+25261${suffix.slice(-7)}`, passwordHash: 'test', accountType: 'CUSTOMER', isVerified: true } })
  manager = await prisma.user.create({ data: { mobileNumber: `+25262${suffix.slice(-7)}`, passwordHash: 'test', accountType: 'HOTEL_MANAGER', isVerified: true } })
  hotel = await prisma.hotel.create({ data: { registeredByUserId: manager.id, status: 'APPROVED_ACTIVE', profileData: { name: 'Booking Test Hotel' } } })
  hall = await prisma.hall.create({ data: {
    hotelId: hotel.id,
    profileData: { name: 'Main Hall', capacity: 200 },
    rentAmountCents: 50000,
    rentDurationHours: 24,
    advancePaymentPercent: 30,
    customerServiceNumber: '+252610000001',
    paymentReceivingNumber: '+252610000002',
  } })
})

after(async () => {
  await prisma.booking.deleteMany({ where: { hotelId: hotel?.id } })
  await prisma.hallAvailabilityBlock.deleteMany({ where: { hallId: hall?.id } })
  if (hall) await prisma.hall.delete({ where: { id: hall.id } })
  if (hotel) await prisma.hotel.delete({ where: { id: hotel.id } })
  await prisma.user.deleteMany({ where: { id: { in: [customer?.id, manager?.id].filter(Boolean) } } })
  await prisma.$disconnect()
})

async function createBooking(offsetDays = 10, hours = 25) {
  const startsAt = new Date(Date.now() + offsetDays * 86400000)
  const endsAt = new Date(startsAt.getTime() + hours * 3600000)
  return bookingService.createBooking({ customerUserId: customer.id, hallId: hall.id, startsAt, endsAt, numberOfGuests: 100, eventType: 'WEDDING' })
}

test('creates a booking with immutable pricing snapshots and completes payment/confirmation flow', async () => {
  const booking = await createBooking()
  assert.equal(booking.totalRentCents, 100000)
  assert.equal(booking.requiredAdvanceCents, 30000)
  assert.equal(booking.status, 'PENDING')

  const reported = await bookingService.reportPayment({ bookingId: booking.id, customerUserId: customer.id, amountCents: 30000 })
  assert.equal(reported.paymentStatus, 'CUSTOMER_REPORTED')
  const paid = await bookingService.verifyPayment({ bookingId: booking.id, hotelId: hotel.id, actorUserId: manager.id, decision: 'VERIFY' })
  assert.equal(paid.paymentStatus, 'PAID')
  const confirmed = await bookingService.transitionHotel({ bookingId: booking.id, hotelId: hotel.id, actorUserId: manager.id, action: 'CONFIRMED' })
  assert.equal(confirmed.status, 'CONFIRMED')
})

test('rejects overlapping bookings and manual blocks against bookings', async () => {
  const first = await createBooking(20, 8)
  await assert.rejects(() => bookingService.createBooking({
    customerUserId: customer.id, hallId: hall.id,
    startsAt: new Date(first.startsAt.getTime() + 3600000), endsAt: new Date(first.endsAt.getTime() + 3600000),
    numberOfGuests: 10, eventType: 'MEETING',
  }), (error) => error.statusCode === 409)

  await assert.rejects(() => availabilityService.createBlock({
    hallId: hall.id,
    date: first.startsAt.toISOString().slice(0, 10),
    startTime: first.startsAt.toISOString().slice(11, 16),
    endTime: first.endsAt.toISOString().slice(11, 16),
    reason: 'Conflict test', createdByUserId: manager.id,
  }), (error) => error.statusCode === 409)
})

test('rejected payment report can be resubmitted, and an insufficient report can still be rejected (Manager\'s own choice)', async () => {
  const booking = await createBooking(30, 2)
  await bookingService.reportPayment({ bookingId: booking.id, customerUserId: customer.id, amountCents: 100 })
  await bookingService.verifyPayment({ bookingId: booking.id, hotelId: hotel.id, actorUserId: manager.id, decision: 'REJECT', reason: 'Amount not received in full.' })
  const resubmitted = await bookingService.reportPayment({ bookingId: booking.id, customerUserId: customer.id, amountCents: booking.requiredAdvanceCents })
  assert.equal(resubmitted.paymentStatus, 'CUSTOMER_REPORTED')
})

test('an insufficient reported amount can still be verified anyway — the amount is a warning, never a backend block', async () => {
  const booking = await createBooking(31, 2)
  await bookingService.reportPayment({ bookingId: booking.id, customerUserId: customer.id, amountCents: 100 })
  const verified = await bookingService.verifyPayment({ bookingId: booking.id, hotelId: hotel.id, actorUserId: manager.id, decision: 'VERIFY' })
  assert.equal(verified.paymentStatus, 'PAID')
})

test('lazy expiration releases an overdue pending period', async () => {
  const booking = await createBooking(40, 2)
  await prisma.booking.update({ where: { id: booking.id }, data: { paymentDeadlineAt: new Date(Date.now() - 1000) } })
  assert.equal(await availabilityService.isPeriodFree({ hallId: hall.id, startsAt: booking.startsAt, endsAt: booking.endsAt }), true)
  assert.equal((await prisma.booking.findUnique({ where: { id: booking.id } })).status, 'EXPIRED')
})
