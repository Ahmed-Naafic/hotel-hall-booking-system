import { storageProvider } from '../../shared/providers/storageProvider.js'

export function toPublicHallMedia(media) {
  if (!media) return null
  return {
    id: media.id,
    hallId: media.hallId,
    type: media.type,
    url: storageProvider.getPublicUrl({ path: media.storagePath }),
    createdAt: media.createdAt,
    updatedAt: media.updatedAt,
  }
}
