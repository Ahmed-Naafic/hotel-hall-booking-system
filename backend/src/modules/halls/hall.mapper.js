import { storageProvider } from '../../shared/providers/storageProvider.js'

/**
 * Data-shape translation (naming-conventions.md §6) — Prisma result → API
 * response. Mirrors Hotel Management's `toPublicHotel` exactly:
 * `profileData` is passed through as-is, unwrapped — its now-defined
 * standard keys (`BDR-016`: name, capacity, description, location) are
 * ordinary content within it, not separate response fields.
 */
export function toPublicHall(hall) {
  return {
    id: hall.id,
    hotelId: hall.hotelId,
    profileData: hall.profileData,
    isActive: hall.isActive,
    bookingTerms: {
      currency: 'USD',
      rentAmountCents: hall.rentAmountCents,
      rentDurationHours: hall.rentDurationHours,
      advancePaymentPercent: hall.advancePaymentPercent === null || hall.advancePaymentPercent === undefined ? null : Number(hall.advancePaymentPercent),
      customerServiceNumber: hall.customerServiceNumber,
      paymentReceivingNumber: hall.paymentReceivingNumber,
    },
    createdAt: hall.createdAt,
    updatedAt: hall.updatedAt,
    photos: (hall.media ?? []).filter((item) => item.type === 'PHOTO').map((item) => ({
      id: item.id,
      type: item.type,
      url: storageProvider.getPublicUrl({ path: item.storagePath }),
    })),
  }
}

/**
 * The same Hall shape as toPublicHall, plus the owning Hotel's name — a
 * purely additive field (never removes/renames anything toPublicHall
 * already returns) used only by discovery-style browse contexts (the
 * platform-wide GET /halls, Large Halls) where the Hall is shown outside
 * the context of any one already-known Hotel screen. Requires the caller's
 * Prisma query to `include: { hotel: true }`.
 */
export function toBrowsableHall(hall) {
  return {
    ...toPublicHall(hall),
    hotel: hall.hotel ? { id: hall.hotel.id, name: hall.hotel.profileData?.name ?? null } : null,
  }
}
