/**
 * Data-shape translation (naming-conventions.md §6) — Prisma result → API
 * response. `passwordHash` is Restricted (data-architecture.md §13) and
 * never leaves this module in a response body (api-standards.md §19).
 */
export function toPublicUser(user) {
  return {
    id: user.id,
    mobileNumber: user.mobileNumber,
    // Populated for a Hotel Manager only (BDR-019). A Customer's own
    // display name lives on CustomerProfile instead (BDR-018, never
    // revisited) and must never appear on this response — the field key
    // itself is omitted, not just set to `null`, preserving the existing
    // module-boundary contract this endpoint already had.
    ...(user.accountType === 'HOTEL_MANAGER' ? { fullName: user.fullName ?? null } : {}),
    accountType: user.accountType,
    isVerified: user.isVerified,
    isActive: user.isActive,
  }
}
