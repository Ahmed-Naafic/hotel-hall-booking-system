import { prisma } from '../../shared/prismaClient.js'
import * as repository from './booking.repository.js'
import * as availabilityService from '../availability/availability.service.js'
import * as hotelEligibility from '../hotels/eligibility.service.js'
import { lockHallSchedule } from '../availability/hallScheduleLock.js'
import { recordBookingAudit } from './audit.js'
import * as notificationEvents from '../notifications/notification.events.js'
import { BusinessRuleError, ConflictError, NotFoundError } from '../../shared/errors/errorTypes.js'

const DAY_MS = 24 * 60 * 60 * 1000
/** Approved V1 business rule — a fixed 30% advance, platform-wide (not Hall-configurable). */
const ADVANCE_PERCENT = 30

export function calculatePricing({ startsAt, endsAt, rentAmountCents, advancePercent }) {
  const units = Math.ceil((endsAt.getTime() - startsAt.getTime()) / DAY_MS)
  const totalRentCents = units * rentAmountCents
  return { totalRentCents, requiredAdvanceCents: Math.round(totalRentCents * Number(advancePercent) / 100) }
}

function assertTransition(booking, statuses, message) {
  if (!statuses.includes(booking.status)) throw new ConflictError(message)
}

/** Notification V1, C8 — one Notification per Booking actually flipped to EXPIRED by this call (never a re-notification of one already expired). */
function notifyExpired(expiredBookings) {
  return Promise.all(expiredBookings.map((booking) => notificationEvents.onBookingExpired(booking)))
}

async function expireAndFindCustomer(id, userId) {
  await notifyExpired(await repository.expireOverdue({ customerUserId: userId }))
  const booking = await repository.findForCustomer(id, userId)
  if (!booking) throw new NotFoundError('Booking not found.')
  return booking
}

async function expireAndFindHotel(id, hotelId) {
  await notifyExpired(await repository.expireOverdue({ hotelId }))
  const booking = await repository.findForHotel(id, hotelId)
  if (!booking) throw new NotFoundError('Booking not found.')
  return booking
}

export async function createBooking({ customerUserId, hallId, startsAt, endsAt, numberOfGuests, eventType, specialRequest }) {
  const start = new Date(startsAt)
  const end = new Date(endsAt)
  if (start <= new Date()) throw new BusinessRuleError('A booking must start in the future.')
  if (end <= start) throw new BusinessRuleError('endsAt must be later than startsAt.')

  const [customer, hall] = await Promise.all([repository.findCustomer(customerUserId), repository.findHallWithHotel(hallId)])
  if (!customer?.isVerified) throw new BusinessRuleError('Only a verified Customer can create a booking.')
  if (!hall) throw new NotFoundError('Hall not found.')
  const eligibility = await hotelEligibility.getEligibility(hall.hotelId)
  if (!eligibility.eligible) throw new NotFoundError('Hall not found.')
  if (numberOfGuests > Number(hall.profileData?.capacity ?? 0)) throw new BusinessRuleError('The number of guests exceeds the Hall capacity.')
  if (!hall.rentAmountCents || hall.advancePaymentPercent === null) {
    throw new BusinessRuleError('This Hall does not have complete booking terms.')
  }

  const pricing = calculatePricing({ startsAt: start, endsAt: end, rentAmountCents: hall.rentAmountCents, advancePercent: ADVANCE_PERCENT })
  let booking
  try {
    booking = await prisma.$transaction(async (client) => {
      await lockHallSchedule(hallId, client)
      await availabilityService.assertPeriodIsFree({ hallId, startsAt: start, endsAt: end, client })
      return repository.create({
        customerUserId, hotelId: hall.hotelId, hallId, startsAt: start, endsAt: end,
        numberOfGuests, eventType, specialRequest: specialRequest?.trim() || null,
        paymentDeadlineAt: new Date(Date.now() + DAY_MS),
        totalRentCents: pricing.totalRentCents,
        advancePercentSnapshot: ADVANCE_PERCENT,
        requiredAdvanceCents: pricing.requiredAdvanceCents,
      }, client)
    })
  } catch (error) {
    const pgCode = error?.meta?.driverAdapterError?.cause?.code
    if (error?.code === 'P2039' || pgCode === '23P01') throw new ConflictError('This period conflicts with an existing booking.')
    throw error
  }
  recordBookingAudit('BOOKING_CREATED', { bookingId: booking.id, actorUserId: customerUserId })
  await notificationEvents.onBookingCreated(booking)
  return booking
}

export async function listCustomer({ customerUserId, cursor, limit }) {
  await notifyExpired(await repository.expireOverdue({ customerUserId }))
  return paged(await repository.listForCustomer({ customerUserId, cursor, take: limit + 1 }), limit)
}

export async function listHotel({ hotelId, status, cursor, limit }) {
  await notifyExpired(await repository.expireOverdue({ hotelId }))
  return paged(await repository.listForHotel({ hotelId, status, cursor, take: limit + 1 }), limit)
}

function paged(rows, limit) {
  const hasNext = rows.length > limit
  const data = hasNext ? rows.slice(0, limit) : rows
  return { bookings: data, hasNext, nextCursor: hasNext ? data.at(-1).id : null }
}

export const getCustomer = ({ bookingId, customerUserId }) => expireAndFindCustomer(bookingId, customerUserId)
export const getHotel = ({ bookingId, hotelId }) => expireAndFindHotel(bookingId, hotelId)

export async function reportPayment({ bookingId, customerUserId, amountCents }) {
  const booking = await expireAndFindCustomer(bookingId, customerUserId)
  assertTransition(booking, ['PENDING'], 'Payment cannot be reported for this booking.')
  if (!['UNPAID', 'REJECTED'].includes(booking.paymentStatus)) throw new ConflictError('A payment report is already active.')
  const updated = await repository.update(booking.id, { paymentStatus: 'CUSTOMER_REPORTED', reportedAmountCents: amountCents, paymentReportedAt: new Date(), paymentRejectionReason: null })
  recordBookingAudit('PAYMENT_REPORTED', { bookingId, actorUserId: customerUserId, details: { amountCents } })
  await notificationEvents.onPaymentReported(updated)
  return updated
}

export async function verifyPayment({ bookingId, hotelId, actorUserId, decision, reason }) {
  const booking = await expireAndFindHotel(bookingId, hotelId)
  assertTransition(booking, ['PENDING'], 'Payment cannot be reviewed for this booking.')
  if (booking.paymentStatus !== 'CUSTOMER_REPORTED') throw new ConflictError('There is no active payment report to review.')
  // A reported amount below the required advance is surfaced to the Hotel
  // Manager as a warning (Manager Mobile, before this call is ever made) —
  // never a hard backend block. The Manager's own judgment is the final
  // check; the backend enforces ownership and status, not the amount.
  const verified = decision === 'VERIFY'
  const updated = await repository.update(booking.id, verified
    ? { paymentStatus: 'PAID', paymentVerifiedAt: new Date(), paymentVerifiedById: actorUserId, paymentRejectionReason: null }
    : { paymentStatus: 'REJECTED', paymentRejectionReason: reason.trim(), paymentVerifiedAt: null, paymentVerifiedById: null })
  recordBookingAudit(verified ? 'PAYMENT_VERIFIED' : 'PAYMENT_REJECTED', { bookingId, actorUserId })
  await (verified ? notificationEvents.onPaymentVerified(updated) : notificationEvents.onPaymentRejected(updated))
  return updated
}

/**
 * Re-validates everything that could have gone stale between the booking's
 * creation and this confirmation attempt — Hotel eligibility (which is also
 * the Hall's own eligibility, Hall Management never keeps a separate
 * status), current Hall capacity, and a fresh Availability check through
 * the existing Availability Query Interface (never reimplemented here).
 * Period exclusivity is already continuously guaranteed by the DB EXCLUDE
 * constraint from creation onward, so this call's real job is catching
 * eligibility/capacity drift and any out-of-band block, not a booking-vs-
 * booking race.
 */
async function assertConfirmable(booking) {
  const eligibility = await hotelEligibility.getEligibility(booking.hotelId)
  if (!eligibility.eligible) throw new BusinessRuleError('The Hotel is no longer operationally eligible.')
  const hall = await repository.findHallWithHotel(booking.hallId)
  if (!hall) throw new NotFoundError('Hall not found.')
  if (booking.numberOfGuests > Number(hall.profileData?.capacity ?? 0)) throw new BusinessRuleError('The number of guests exceeds the Hall capacity.')
  await availabilityService.assertPeriodIsFree({ hallId: booking.hallId, startsAt: booking.startsAt, endsAt: booking.endsAt, excludeBookingId: booking.id })
}

export async function transitionHotel({ bookingId, hotelId, actorUserId, action }) {
  const booking = await expireAndFindHotel(bookingId, hotelId)
  const now = new Date()
  if (action === 'CONFIRMED') {
    assertTransition(booking, ['PENDING'], 'Booking cannot be confirmed.')
    if (booking.paymentStatus !== 'PAID') throw new BusinessRuleError('Payment must be verified before confirmation.')
    await assertConfirmable(booking)
  } else {
    const rules = {
      REJECTED: () => { assertTransition(booking, ['PENDING'], 'Booking cannot be rejected.'); if (booking.paymentStatus === 'PAID') throw new BusinessRuleError('A paid booking cannot be rejected.') },
      // Cancellation applies to any still-active Booking (PENDING or CONFIRMED),
      // regardless of payment state — the approved rule ties cancellability to
      // the Booking still being "applicable" (not yet REJECTED/CANCELLED/
      // COMPLETED/NO_SHOW/EXPIRED), never to whether it has been paid. No
      // refund/fee logic runs here; paymentStatus is left exactly as it was.
      CANCELLED: () => { assertTransition(booking, ['PENDING', 'CONFIRMED'], 'Booking cannot be cancelled.') },
      COMPLETED: () => { assertTransition(booking, ['CONFIRMED'], 'Booking cannot be completed.'); if (now < booking.endsAt) throw new BusinessRuleError('A booking can only be completed after it ends.') },
      NO_SHOW: () => { assertTransition(booking, ['CONFIRMED'], 'Booking cannot be marked no-show.'); if (now < booking.startsAt) throw new BusinessRuleError('A booking can only be marked no-show after it starts.') },
    }
    rules[action]()
  }
  const data = { status: action }
  if (action === 'CANCELLED') Object.assign(data, { cancelledAt: now, cancelledByUserId: actorUserId })
  if (action === 'COMPLETED') data.completedAt = now
  const updated = await repository.update(booking.id, data)
  recordBookingAudit(`BOOKING_${action}`, { bookingId, actorUserId })
  // Notification V1 Catalog: COMPLETED/NO_SHOW have no approved Notification
  // Catalog entry (Business Specification) — deliberately not notified.
  const onTransition = {
    CONFIRMED: notificationEvents.onBookingConfirmed,
    REJECTED: notificationEvents.onBookingRejected,
    CANCELLED: notificationEvents.onBookingCancelledByManager,
  }[action]
  if (onTransition) await onTransition(updated)
  return updated
}

export async function cancelCustomer({ bookingId, customerUserId }) {
  const booking = await expireAndFindCustomer(bookingId, customerUserId)
  assertTransition(booking, ['PENDING', 'CONFIRMED'], 'Booking cannot be cancelled.')
  const updated = await repository.update(booking.id, { status: 'CANCELLED', cancelledAt: new Date(), cancelledByUserId: customerUserId })
  recordBookingAudit('BOOKING_CANCELLED', { bookingId, actorUserId: customerUserId })
  await notificationEvents.onBookingCancelledByCustomer(updated)
  return updated
}
