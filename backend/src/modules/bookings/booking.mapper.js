import { toReview } from '../reviews/review.mapper.js'
import { storageProvider } from '../../shared/providers/storageProvider.js'

export function toBooking(booking) {
  return {
    id: booking.id,
    customerUserId: booking.customerUserId,
    // Lets a Hotel Manager identify who a Booking belongs to (BDR-018) —
    // the Customer's own view of their own Booking already knows this
    // about themselves, so the same shape is safe for both roles.
    customer: booking.customer ? {
      id: booking.customer.id,
      fullName: booking.customer.customerProfile?.profileData?.fullName ?? null,
      mobileNumber: booking.customer.mobileNumber,
      avatarUrl: booking.customer.customerProfile?.avatarStoragePath
        ? storageProvider.getPublicUrl({ path: booking.customer.customerProfile.avatarStoragePath })
        : null,
    } : undefined,
    hotelId: booking.hotelId,
    hallId: booking.hallId,
    hotel: booking.hotel ? { id: booking.hotel.id, name: booking.hotel.profileData?.name ?? null } : undefined,
    hall: booking.hall ? {
      id: booking.hall.id,
      name: booking.hall.profileData?.name ?? null,
      bookingTerms: {
        currency: 'USD',
        rentAmountCents: booking.hall.rentAmountCents,
        rentDurationHours: booking.hall.rentDurationHours,
        advancePaymentPercent: booking.hall.advancePaymentPercent === null || booking.hall.advancePaymentPercent === undefined ? null : Number(booking.hall.advancePaymentPercent),
        customerServiceNumber: booking.hall.customerServiceNumber,
        paymentReceivingNumber: booking.hall.paymentReceivingNumber,
      },
    } : undefined,
    startsAt: booking.startsAt,
    endsAt: booking.endsAt,
    numberOfGuests: booking.numberOfGuests,
    eventType: booking.eventType,
    specialRequest: booking.specialRequest,
    status: booking.status,
    // BDR-024 — set only when a Customer cancelled a Confirmed booking;
    // null for a still-Pending cancellation (never required there) and for
    // a Hotel-Manager-initiated cancellation (this rule doesn't apply to
    // it).
    cancellationReason: booking.cancellationReason,
    paymentStatus: booking.paymentStatus,
    paymentDeadlineAt: booking.paymentDeadlineAt,
    pricing: {
      currency: 'USD',
      totalRentCents: booking.totalRentCents,
      advancePercent: Number(booking.advancePercentSnapshot),
      requiredAdvanceCents: booking.requiredAdvanceCents,
    },
    payment: {
      reportedAmountCents: booking.reportedAmountCents,
      reportedAt: booking.paymentReportedAt,
      verifiedAt: booking.paymentVerifiedAt,
      rejectionReason: booking.paymentRejectionReason,
    },
    createdAt: booking.createdAt,
    updatedAt: booking.updatedAt,
    review: booking.review ? toReview(booking.review) : null,
  }
}
