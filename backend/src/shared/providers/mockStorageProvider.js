import { logger } from '../../config/logger.js'

/**
 * Fake StorageProvider (architecture-principles.md §10-11 abstraction
 * pattern) for local development and automated tests — never contacts a
 * real Supabase project, never requires credentials, and always
 * "succeeds" unless explicitly told to fail via `failNextUpload` (a test
 * helper for exercising the cleanup-on-metadata-failure path, Technical
 * Design §8a/§16).
 *
 * Uploaded objects are kept in memory so a test can assert what was
 * stored, and deleted, without any real storage backend
 * (testing-standards.md §6: external services are tested via mocks/test
 * doubles, never a dependency on a real external service).
 */
export class MockStorageProvider {
  constructor() {
    this.objects = new Map()
    this._failNextUpload = false
  }

  async upload({ path, buffer, contentType }) {
    if (this._failNextUpload) {
      this._failNextUpload = false
      logger.warn('[MockStorageProvider] Simulated upload failure', { path })
      throw new Error('Simulated storage upload failure.')
    }
    this.objects.set(path, { buffer, contentType })
    logger.info('[MockStorageProvider] Object stored (no real Supabase project configured)', { path })
    return { path }
  }

  async delete({ path }) {
    this.objects.delete(path)
    logger.info('[MockStorageProvider] Object deleted (no real Supabase project configured)', { path })
  }

  getPublicUrl({ path }) {
    return `https://mock-storage.local/hotel-media/${path}`
  }

  /** Test helper — makes the next `upload()` call reject. */
  failNextUpload() {
    this._failNextUpload = true
  }

  /** Test helper — clears state between test runs. */
  reset() {
    this.objects.clear()
    this._failNextUpload = false
  }
}
