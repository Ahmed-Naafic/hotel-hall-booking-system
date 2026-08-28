import { env } from '../../config/env.js'
import { logger } from '../../config/logger.js'
import { SupabaseStorageProvider } from './supabaseStorageProvider.js'
import { MockStorageProvider } from './mockStorageProvider.js'

/**
 * StorageProvider abstraction (architecture-principles.md §10-11) — every
 * caller depends on this module's `upload`/`delete`/`getPublicUrl`
 * contract, never on Supabase directly. Selected once, at process start,
 * based on whether Supabase credentials are present — the exact same
 * pattern `shared/providers/smsProvider.js` already establishes for
 * Twilio:
 *
 * - Both present  -> SupabaseStorageProvider (ADR-0006's approved provider).
 * - Either missing -> MockStorageProvider. This is a normal, expected
 *   local-development and CI state, not a startup failure — the
 *   application must keep running (architecture-principles.md §11,
 *   graceful failure).
 *
 * Never hardcode a credential or placeholder value here or anywhere else;
 * absence simply selects the mock.
 *
 * `selectProvider` takes its credentials as a parameter (rather than
 * reading `env` itself) specifically so the selection *decision* is
 * unit-testable with fake inputs (testing-standards.md §5).
 */
export function selectProvider({ url, serviceRoleKey, bucket }) {
  if (url && serviceRoleKey) {
    logger.info('[storageProvider] Supabase credentials found — using SupabaseStorageProvider.')
    return new SupabaseStorageProvider({ url, serviceRoleKey, bucket })
  }

  logger.warn(
    '[storageProvider] No Supabase credentials configured (SUPABASE_URL / ' +
      'SUPABASE_SERVICE_ROLE_KEY) — falling back to MockStorageProvider. ' +
      'Hotel media will not be uploaded to a real Supabase project.',
  )
  return new MockStorageProvider()
}

export const storageProvider = selectProvider(env.storage.supabase)
