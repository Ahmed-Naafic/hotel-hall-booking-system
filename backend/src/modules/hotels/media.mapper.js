import { storageProvider } from '../../shared/providers/storageProvider.js'

/**
 * Data-shape translation (naming-conventions.md §6) — Prisma result → API
 * response. The public URL is derived from `storagePath` at read time
 * (Technical Design §8a) — never stored as the database reference itself.
 */
export function toPublicHotelMedia(media) {
  if (!media) return null
  return {
    id: media.id,
    hotelId: media.hotelId,
    type: media.type,
    url: storageProvider.getPublicUrl({ path: media.storagePath }),
    createdAt: media.createdAt,
    updatedAt: media.updatedAt,
  }
}
