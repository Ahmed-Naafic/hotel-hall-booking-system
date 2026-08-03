import argon2 from 'argon2'
import { env } from '../../config/env.js'
import { AuthenticationError } from '../../shared/errors/errorTypes.js'

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
 * Verifies a plain password against a stored hash. Never distinguishes
 * "wrong password" from "unknown identifier" to the caller (BR-AUTH-09,
 * anti-enumeration) — that distinction is the Authentication Component's
 * responsibility to word consistently, not this component's to leak.
 */
export async function verifyPassword(plainPassword, passwordHash) {
  const isValid = await argon2.verify(passwordHash, plainPassword)
  if (!isValid) {
    throw new AuthenticationError('Invalid credentials.')
  }
}
