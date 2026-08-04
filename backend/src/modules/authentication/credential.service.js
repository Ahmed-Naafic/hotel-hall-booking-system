import argon2 from 'argon2'
import { env } from '../../config/env.js'

/**
 * Credential Component (Technical Design §4, §11) — stores and verifies
 * password credentials using Argon2id (decided 2026-08-03, Technical
 * Design §11). Never exposes a stored credential in any form (BR-AUTH-08,
 * BR-AUTH-09; data-architecture.md §13, Restricted classification).
 */

const argon2Options = {
  type: argon2.argon2id,
  memoryCost: env.auth.argon2.memoryCost,
  timeCost: env.auth.argon2.timeCost,
  parallelism: env.auth.argon2.parallelism,
}

export function hashPassword(plainPassword) {
  return argon2.hash(plainPassword, argon2Options)
}

/**
 * Returns whether a plain password matches a stored hash — a boolean, not
 * a thrown error. What a mismatch *means* differs by caller: login treats
 * it as a 401 (BR-AUTH-09, never distinguished from an unknown identifier);
 * changing a password treats it as a 422 (a business-rule failure on an
 * already-authenticated request). Deciding between those is the caller's
 * job, not this pure-crypto component's.
 */
export function verifyPassword(plainPassword, passwordHash) {
  return argon2.verify(passwordHash, plainPassword)
}
