import { createHash } from 'node:crypto'

/**
 * Fast, deterministic hash for high-entropy secrets and short-lived codes
 * that must never be stored raw (data-architecture.md §13, Restricted) but
 * don't need a slow, salted algorithm — that's Credential Component's
 * Argon2id, reserved for long-lived user passwords (Technical Design §11).
 */
export function sha256Hex(value) {
  return createHash('sha256').update(value).digest('hex')
}
