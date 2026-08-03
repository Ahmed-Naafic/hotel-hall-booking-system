/**
 * Data-shape translation (naming-conventions.md §6) — Prisma result → API
 * response. `passwordHash` is Restricted (data-architecture.md §13) and
 * never leaves this module in a response body (api-standards.md §19).
 */
export function toPublicUser(user) {
  return {
    id: user.id,
    mobileNumber: user.mobileNumber,
    accountType: user.accountType,
    isVerified: user.isVerified,
    isActive: user.isActive,
  }
}
