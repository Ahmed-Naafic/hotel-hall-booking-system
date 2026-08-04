import { randomInt } from 'node:crypto'

/**
 * A 6-digit numeric code, suitable for both the Verification Component
 * (BR-AUTH-02) and the Password Reset flow (BR-AUTH-09) — SMS-appropriate,
 * short enough to type back into the app. Exact format is Business
 * Specification Pending Business Decision #2 (business-specification.md
 * §10); this is a development default, not settled policy.
 */
export function generateVerificationCode() {
  return String(randomInt(0, 1_000_000)).padStart(6, '0')
}
