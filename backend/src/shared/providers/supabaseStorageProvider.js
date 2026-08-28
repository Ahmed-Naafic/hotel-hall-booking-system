import { createClient } from '@supabase/supabase-js'
import { logger } from '../../config/logger.js'

/**
 * Real StorageProvider (architecture-principles.md §10-11 abstraction
 * pattern), approved via ADR-0006. Constructed only when Supabase
 * credentials are present (shared/providers/storageProvider.js) — this
 * class itself never reads environment variables directly, so it stays
 * trivially testable with fake credentials. Uses the **service-role** key
 * (bypasses Row Level Security) — this class, and the credential it holds,
 * never leaves the backend process (Technical Design §12).
 */
export class SupabaseStorageProvider {
  constructor({ url, serviceRoleKey, bucket }) {
    this.bucket = bucket
    this.client = createClient(url, serviceRoleKey)
  }

  async upload({ path, buffer, contentType }) {
    const { error } = await this.client.storage.from(this.bucket).upload(path, buffer, {
      contentType,
      upsert: false,
    })
    if (error) {
      // No internal implementation leakage (coding-standards.md §9) — the
      // caller sees a generic failure; the real cause is logged, not
      // thrown to a client (Technical Design §16 — falls through to the
      // existing generic 500 handler, the same category a Twilio delivery
      // failure already uses).
      logger.error('[SupabaseStorageProvider] Upload failed', { path, error: error.message })
      throw new Error('Media storage upload failed.', { cause: error })
    }
    return { path }
  }

  async delete({ path }) {
    const { error } = await this.client.storage.from(this.bucket).remove([path])
    if (error) {
      logger.error('[SupabaseStorageProvider] Delete failed', { path, error: error.message })
      throw new Error('Media storage delete failed.', { cause: error })
    }
  }

  /**
   * `hotel-media` is a public-read bucket (Technical Design §8a — Hotel
   * Logo/Photos are already Public-classified data, §5); the public URL is
   * derived deterministically from the path, never stored as the database
   * reference itself (no signed-URL expiry to manage).
   */
  getPublicUrl({ path }) {
    const {
      data: { publicUrl },
    } = this.client.storage.from(this.bucket).getPublicUrl(path)
    return publicUrl
  }
}
