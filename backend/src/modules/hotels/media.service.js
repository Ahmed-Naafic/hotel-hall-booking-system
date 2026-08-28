import { randomUUID } from 'node:crypto'
import * as mediaRepository from './media.repository.js'
import { storageProvider } from '../../shared/providers/storageProvider.js'
import { extensionForMimeType } from './media.validation.js'
import { recordAuditEvent } from './audit.js'
import { NotFoundError } from '../../shared/errors/errorTypes.js'

/**
 * Media Component (Technical Design §3, §8a) — Hotel Logo/Photo upload,
 * replacement, deletion, and retrieval (`BDR-015`, `ADR-0006`). The only
 * component that talks to the Storage Provider abstraction; every other
 * component in this module remains storage-agnostic.
 */

function buildStoragePath({ hotelId, kind, mimeType }) {
  const extension = extensionForMimeType(mimeType)
  return `hotels/${hotelId}/${kind}/${randomUUID()}.${extension}`
}

/**
 * Creates a Hotel Media record in Supabase + Neon, cleaning up the
 * just-uploaded Supabase object if the Neon write fails (Technical Design
 * §8a, §16) — no orphaned file is left behind.
 */
async function uploadAndPersist({ hotelId, kind, type, buffer, mimeType }) {
  const storagePath = buildStoragePath({ hotelId, kind, mimeType })
  await storageProvider.upload({ path: storagePath, buffer, contentType: mimeType })

  try {
    return await mediaRepository.create({ hotelId, type, storagePath })
  } catch (err) {
    await storageProvider.delete({ path: storagePath }).catch(() => {})
    throw err
  }
}

/**
 * Uploads (or replaces) the Hotel's Logo. At most one `LOGO` record per
 * Hotel — a business-level constraint (Technical Design §5), not a
 * database constraint. The previous logo (if any) is looked up *before*
 * the new upload, and deleted only *after* the new one is fully persisted
 * — an interrupted upload never leaves the Hotel without the logo it
 * previously had.
 */
export async function uploadLogo(hotel, { buffer, mimeType }) {
  const previousLogo = await mediaRepository.findLogoForHotel(hotel.id)

  const created = await uploadAndPersist({
    hotelId: hotel.id,
    kind: 'logo',
    type: 'LOGO',
    buffer,
    mimeType,
  })

  if (previousLogo) {
    await storageProvider.delete({ path: previousLogo.storagePath }).catch(() => {})
    await mediaRepository.remove(previousLogo.id).catch(() => {})
  }

  recordAuditEvent(previousLogo ? 'HOTEL_MEDIA_LOGO_REPLACED' : 'HOTEL_MEDIA_UPLOADED', {
    hotelId: hotel.id,
    actorUserId: hotel.registeredByUserId,
    details: { mediaId: created.id, type: 'LOGO' },
  })

  return created
}

/** Adds a Hotel Photo. No replacement semantics — Photos are plural (`BDR-015`). */
export async function uploadPhoto(hotel, { buffer, mimeType }) {
  const created = await uploadAndPersist({
    hotelId: hotel.id,
    kind: 'photos',
    type: 'PHOTO',
    buffer,
    mimeType,
  })

  recordAuditEvent('HOTEL_MEDIA_UPLOADED', {
    hotelId: hotel.id,
    actorUserId: hotel.registeredByUserId,
    details: { mediaId: created.id, type: 'PHOTO' },
  })

  return created
}

/** Deletes one Hotel Media record (Logo or Photo) and its Supabase object. */
export async function deleteMedia(hotel, mediaId) {
  const media = await mediaRepository.findByIdForHotel(mediaId, hotel.id)
  if (!media) {
    throw new NotFoundError('Hotel media not found.')
  }

  await storageProvider.delete({ path: media.storagePath })
  await mediaRepository.remove(media.id)

  recordAuditEvent('HOTEL_MEDIA_DELETED', {
    hotelId: hotel.id,
    actorUserId: hotel.registeredByUserId,
    details: { mediaId: media.id, type: media.type },
  })
}

/** Retrieves the Hotel's current Logo (or `null`) and full Photos list. */
export async function getMedia(hotel) {
  const [logo, photos] = await Promise.all([
    mediaRepository.findLogoForHotel(hotel.id),
    mediaRepository.findPhotosForHotel(hotel.id),
  ])
  return { logo, photos }
}
