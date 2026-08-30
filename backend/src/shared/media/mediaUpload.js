import { storageProvider } from '../providers/storageProvider.js'

/**
 * Shared upload primitive: write object storage first, persist module-owned
 * metadata second, and clean up the just-uploaded object if metadata fails.
 */
export async function uploadAndPersist({ path, buffer, mimeType, persist }) {
  await storageProvider.upload({ path, buffer, contentType: mimeType })

  try {
    return await persist({ storagePath: path })
  } catch (err) {
    await storageProvider.delete({ path }).catch(() => {})
    throw err
  }
}

export function deleteStoredMedia(path) {
  return storageProvider.delete({ path })
}
