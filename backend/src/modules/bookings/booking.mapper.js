export function toBooking(booking) {
  return {
    id: booking.id,
    customerUserId: booking.customerUserId,
    hotelId: booking.hotelId,
    hallId: booking.hallId,
    startsAt: booking.startsAt,
    endsAt: booking.endsAt,
    numberOfGuests: booking.numberOfGuests,
    eventType: booking.eventType,
    specialRequest: booking.specialRequest,
    status: booking.status,
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
  }
}
