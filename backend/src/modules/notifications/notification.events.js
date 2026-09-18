import * as notificationService from './notification.service.js'
import * as notificationRepository from './notification.repository.js'

/**
 * One function per Notification Catalog row (Business Specification
 * "Notification Catalog"). Called from the exact call sites
 * `bookings`/`hotels` already use for `recordBookingAudit`/
 * `recordAuditEvent` — no new call sites invented (Project Rule 4/9). Every
 * function here composes plain data already available to its caller into a
 * `notificationService.notify(...)` call; none of them re-derive a business
 * rule or re-check authorization — the transition already happened and was
 * already authorized by the time these run.
 */

const money = (cents) => `$${(cents / 100).toFixed(2)}`
const hallName = (booking) => booking.hall?.profileData?.name || 'the Hall'
const hotelName = (booking) => booking.hotel?.profileData?.name || 'the Hotel'

export function onBookingCreated(booking) {
  return Promise.all([
    notificationService.notify({
      recipientUserId: booking.customerUserId,
      type: 'BOOKING_REQUEST_SUBMITTED',
      title: 'Booking requested',
      body: `Your request for ${hallName(booking)} at ${hotelName(booking)} has been sent.`,
      bookingId: booking.id,
      hotelId: booking.hotelId,
    }),
    notificationService.notify({
      recipientUserId: booking.hotel.registeredByUserId,
      type: 'NEW_BOOKING_REQUEST',
      title: 'New booking request',
      body: `A new booking request for ${hallName(booking)} was submitted.`,
      bookingId: booking.id,
      hotelId: booking.hotelId,
    }),
  ])
}

export function onBookingConfirmed(booking) {
  return notificationService.notify({
    recipientUserId: booking.customerUserId,
    type: 'BOOKING_CONFIRMED',
    title: 'Booking confirmed',
    body: `${hotelName(booking)} confirmed your booking for ${hallName(booking)}.`,
    bookingId: booking.id,
    hotelId: booking.hotelId,
  })
}

export function onBookingRejected(booking) {
  return notificationService.notify({
    recipientUserId: booking.customerUserId,
    type: 'BOOKING_REJECTED',
    title: 'Booking rejected',
    body: `${hotelName(booking)} rejected your booking request for ${hallName(booking)}.`,
    bookingId: booking.id,
    hotelId: booking.hotelId,
  })
}

function notifyCustomerBookingCancelled(booking) {
  return notificationService.notify({
    recipientUserId: booking.customerUserId,
    type: 'BOOKING_CANCELLED',
    title: 'Booking cancelled',
    body: `Your booking for ${hallName(booking)} at ${hotelName(booking)} was cancelled.`,
    bookingId: booking.id,
    hotelId: booking.hotelId,
  })
}

/** The Customer cancelled — notify both sides (M3: the Manager did not do this themselves). */
export function onBookingCancelledByCustomer(booking) {
  return Promise.all([
    notifyCustomerBookingCancelled(booking),
    notificationService.notify({
      recipientUserId: booking.hotel.registeredByUserId,
      type: 'CUSTOMER_BOOKING_CANCELLED',
      title: 'Booking cancelled by customer',
      body: `A customer cancelled their booking for ${hallName(booking)}.`,
      bookingId: booking.id,
      hotelId: booking.hotelId,
    }),
  ])
}

/** The Hotel Manager cancelled — only the Customer needs telling; the Manager knows their own action. */
export function onBookingCancelledByManager(booking) {
  return notifyCustomerBookingCancelled(booking)
}

export function onPaymentReported(booking) {
  return Promise.all([
    notificationService.notify({
      recipientUserId: booking.customerUserId,
      type: 'PAYMENT_REPORTED',
      title: 'Payment report received',
      body: `We received your payment report of ${money(booking.reportedAmountCents)} for ${hallName(booking)}. The Hotel will verify it soon.`,
      bookingId: booking.id,
      hotelId: booking.hotelId,
    }),
    notificationService.notify({
      recipientUserId: booking.hotel.registeredByUserId,
      type: 'CUSTOMER_PAYMENT_REPORTED',
      title: 'Payment reported',
      body: `A customer reported a payment of ${money(booking.reportedAmountCents)} for ${hallName(booking)}. Please verify it.`,
      bookingId: booking.id,
      hotelId: booking.hotelId,
    }),
  ])
}

export function onPaymentVerified(booking) {
  return notificationService.notify({
    recipientUserId: booking.customerUserId,
    type: 'PAYMENT_VERIFIED',
    title: 'Payment verified',
    body: `Your payment for ${hallName(booking)} at ${hotelName(booking)} has been verified.`,
    bookingId: booking.id,
    hotelId: booking.hotelId,
  })
}

export function onPaymentRejected(booking) {
  const reasonSuffix = booking.paymentRejectionReason ? ` Reason: ${booking.paymentRejectionReason}` : ''
  return notificationService.notify({
    recipientUserId: booking.customerUserId,
    type: 'PAYMENT_REJECTED',
    title: 'Payment rejected',
    body: `${hotelName(booking)} rejected your payment report for ${hallName(booking)}.${reasonSuffix}`,
    bookingId: booking.id,
    hotelId: booking.hotelId,
  })
}

export function onBookingExpired(booking) {
  return notificationService.notify({
    recipientUserId: booking.customerUserId,
    type: 'BOOKING_EXPIRED',
    title: 'Booking expired',
    body: `Your booking request for ${hallName(booking)} at ${hotelName(booking)} expired because payment was not completed in time.`,
    bookingId: booking.id,
    hotelId: booking.hotelId,
  })
}

async function notifyEveryAdmin({ type, title, body, hotel, application }) {
  const admins = await notificationRepository.listPlatformAdministratorIds()
  await Promise.all(
    admins.map((admin) =>
      notificationService.notify({
        recipientUserId: admin.id,
        type,
        title,
        body,
        hotelId: hotel.id,
        hotelApplicationId: application.id,
      }),
    ),
  )
}

const applicationHotelName = (hotel) => hotel.profileData?.name || 'A hotel'

export function onHotelApplicationSubmitted(application, hotel) {
  return notifyEveryAdmin({
    type: 'NEW_HOTEL_APPLICATION',
    title: 'New hotel application',
    body: `${applicationHotelName(hotel)} submitted a new application for review.`,
    hotel,
    application,
  })
}

export function onHotelApplicationResubmitted(application, hotel) {
  return notifyEveryAdmin({
    type: 'HOTEL_APPLICATION_RESUBMITTED',
    title: 'Hotel application resubmitted',
    body: `${applicationHotelName(hotel)} resubmitted their application for review.`,
    hotel,
    application,
  })
}

export function onHotelApplicationWithdrawn(application, hotel) {
  return notifyEveryAdmin({
    type: 'HOTEL_APPLICATION_WITHDRAWN',
    title: 'Hotel application withdrawn',
    body: `${applicationHotelName(hotel)} withdrew their application.`,
    hotel,
    application,
  })
}

/** M4/M5 (`BDR-021`) — the Hotel Manager who registered the Hotel, never the whole admin role. */
export function onHotelApplicationApproved(application, hotel) {
  return notificationService.notify({
    recipientUserId: hotel.registeredByUserId,
    type: 'HOTEL_APPLICATION_APPROVED',
    title: 'Hotel application approved',
    body: `${applicationHotelName(hotel)}'s application has been approved. You can now list Halls and receive bookings.`,
    hotelId: hotel.id,
    hotelApplicationId: application.id,
  })
}

export function onHotelApplicationRejected(application, hotel) {
  const reasonSuffix = application.decisionReason ? ` Reason: ${application.decisionReason}` : ''
  return notificationService.notify({
    recipientUserId: hotel.registeredByUserId,
    type: 'HOTEL_APPLICATION_REJECTED',
    title: 'Hotel application rejected',
    body: `${applicationHotelName(hotel)}'s application has been rejected.${reasonSuffix}`,
    hotelId: hotel.id,
    hotelApplicationId: application.id,
  })
}

/** HM11, BR-HOTEL-09 — the Hotel Manager who registered the Hotel, never the whole admin role. */
export function onHotelSuspended(hotel) {
  return notificationService.notify({
    recipientUserId: hotel.registeredByUserId,
    type: 'HOTEL_SUSPENDED',
    title: 'Hotel suspended',
    body: `${applicationHotelName(hotel)} has been suspended by a Platform Administrator and is no longer operationally eligible.`,
    hotelId: hotel.id,
  })
}

export function onHotelDeactivated(hotel) {
  return notificationService.notify({
    recipientUserId: hotel.registeredByUserId,
    type: 'HOTEL_DEACTIVATED',
    title: 'Hotel deactivated',
    body: `${applicationHotelName(hotel)} has been deactivated by a Platform Administrator and is no longer operationally eligible.`,
    hotelId: hotel.id,
  })
}

/** Reactivation out of SUSPENDED or DEACTIVATED (BDR-012). */
export function onHotelReactivated(hotel) {
  return notificationService.notify({
    recipientUserId: hotel.registeredByUserId,
    type: 'HOTEL_REACTIVATED',
    title: 'Hotel reactivated',
    body: `${applicationHotelName(hotel)} has been reactivated by a Platform Administrator. You can list Halls and receive bookings again.`,
    hotelId: hotel.id,
  })
}

/**
 * Communication V1 (C9/M9) — `booking` here is the minimal
 * `chat.repository.js#findBookingForParticipant` projection
 * (`customerUserId`, `hotelId`, `hotel.registeredByUserId`), not the full
 * Booking Management shape every other event function above receives; the
 * recipient is whichever participant did not send the message.
 */
export function onChatMessageSent(message, booking) {
  const recipientUserId = message.senderUserId === booking.customerUserId
    ? booking.hotel.registeredByUserId
    : booking.customerUserId
  return notificationService.notify({
    recipientUserId,
    type: 'NEW_CHAT_MESSAGE',
    title: 'New message',
    body: message.body,
    bookingId: booking.id,
  })
}
