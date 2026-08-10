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
  }
}

export function toPublicApplication(application) {
  return {
    id: application.id,
    hotelId: application.hotelId,
    status: application.status,
    decidedByUserId: application.decidedByUserId,
    decidedAt: application.decidedAt,
    submittedAt: application.submittedAt,
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
