/**
 * Data-shape translation (naming-conventions.md §6) — Prisma result → API
 * response. Never includes the reviewing Customer's identity (approved
 * business decision, no existing convention exposes it publicly).
 */
export function toReview(review) {
  return {
    id: review.id,
    rating: review.rating,
    text: review.text,
    createdAt: review.createdAt,
  }
}
