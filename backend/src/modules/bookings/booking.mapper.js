export function toBooking(booking) {
  return {
    id: booking.id,
    customerUserId: booking.customerUserId,
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
