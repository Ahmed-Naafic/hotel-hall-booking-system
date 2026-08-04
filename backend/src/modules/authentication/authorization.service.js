/**
 * Authorization (Claim) Component (Technical Design §4, §8) — resolves an
 * Identity's role into the claim the Token Component embeds. Production
 * only: this component never evaluates a permission or makes an access
 * decision (BR-AUTH-14) — that is Security & Access Control's (Module 14)
 * policy, applied downstream of this module's output.
 *
 * Today a User Account's `accountType` (identity.repository.js) already is
 * its one role, per data-architecture.md §5 ("a Role grants one or more
 * Permissions; an Identity holds one or more Roles") realized minimally —
 * this is the seam a future multi-role model would extend without changing
 * any caller of resolveRoleClaim().
 */
export function resolveRoleClaim(user) {
  return user.accountType
}
