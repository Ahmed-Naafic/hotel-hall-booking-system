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
    createdAt: hall.createdAt,
    updatedAt: hall.updatedAt,
  }
}
