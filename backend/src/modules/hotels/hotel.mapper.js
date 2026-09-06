import { storageProvider } from '../../shared/providers/storageProvider.js'

/**
 * Data-shape translation (naming-conventions.md §6) — Prisma result → API
 * response.
 */
export function toPublicHotel(hotel) {
  return {
    id: hotel.id,
    registeredByUserId: hotel.registeredByUserId,
    status: hotel.status,
    profileData: hotel.profileData,
    createdAt: hotel.createdAt,
    updatedAt: hotel.updatedAt,
    logo: toMedia(hotel.media?.find((item) => item.type === 'LOGO') ?? null),
    photos: (hotel.media ?? []).filter((item) => item.type === 'PHOTO').map(toMedia),
  }
}

export function toPublicApplication(application) {
  return {
    id: application.id,
    hotelId: application.hotelId,
    status: application.status,
    decidedByUserId: application.decidedByUserId,
    decidedAt: application.decidedAt,
    decisionReason: application.decisionReason,
    submittedAt: application.submittedAt,
  }
}

/** Hotel Detail (GET /hotels/public/:id) only — never the listing endpoints, which stay out of Ratings & Reviews V1 scope. */
export function toHotelDetail(hotel, reviewSummary) {
  return {
    ...toCustomerVisibleHotel(hotel),
    reviewSummary,
  }
}

export function toCustomerVisibleHotel(hotel) {
  const media = hotel.media ?? []
  return {
    id: hotel.id,
    profileData: hotel.profileData,
    logo: toMedia(media.find((item) => item.type === 'LOGO') ?? null),
    photos: media.filter((item) => item.type === 'PHOTO').map(toMedia),
  }
}

/** Nearby Hotels — the same Customer-visible shape plus the backend-computed distance. */
export function toNearbyHotel(hotel, distanceKm) {
  return {
    ...toCustomerVisibleHotel(hotel),
    distanceKm: Math.round(distanceKm * 10) / 10,
  }
}

/** Popular Hotels — the same Customer-visible shape plus the real qualifying booking count. */
export function toPopularHotel(hotel, bookingCount) {
  return {
    ...toCustomerVisibleHotel(hotel),
    bookingCount,
  }
}

function toMedia(media) {
  if (!media) return null
  return {
    id: media.id,
    type: media.type,
    url: storageProvider.getPublicUrl({ path: media.storagePath }),
  }
}

export function toPublicCriticalChangeRequest(request) {
  return {
    id: request.id,
    hotelId: request.hotelId,
    status: request.status,
    proposedData: request.proposedData,
    decidedByUserId: request.decidedByUserId,
    decidedAt: request.decidedAt,
    submittedAt: request.submittedAt,
  }
}
