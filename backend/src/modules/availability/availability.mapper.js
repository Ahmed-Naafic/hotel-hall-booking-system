/**
 * Data-shape translation (naming-conventions.md §6) — Prisma result → API
 * response. Two shapes, deliberately: the Manager owns the Hall and may see
 * everything about a block; a Customer may only ever learn that a period is
 * busy, never why or who created it (Availability Response design).
 */

export function toManagerAvailabilityBlock(block) {
  return {
    id: block.id,
    hallId: block.hallId,
    startsAt: block.startsAt,
    endsAt: block.endsAt,
    reason: block.reason,
    createdByUserId: block.createdByUserId,
    createdAt: block.createdAt,
    updatedAt: block.updatedAt,
  }
}

export function toPublicBusyPeriod(block) {
  return {
    start: block.startsAt,
    end: block.endsAt,
  }
}
