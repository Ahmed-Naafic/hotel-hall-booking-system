import { randomUUID } from 'node:crypto'
import * as mediaRepository from './media.repository.js'
import { deleteStoredMedia, uploadAndPersist as sharedUploadAndPersist } from '../../shared/media/mediaUpload.js'
import { extensionForMimeType } from '../../shared/media/imageValidation.js'
import { recordAuditEvent } from './audit.js'
import { NotFoundError } from '../../shared/errors/errorTypes.js'

function buildStoragePath({ hallId, mediaId, mimeType }) {
  const extension = extensionForMimeType(mimeType)
  return `halls/${hallId}/photos/${mediaId}.${extension}`
}

export async function uploadPhoto(hall, { buffer, mimeType }) {
  const mediaId = randomUUID()
  const storagePath = buildStoragePath({ hallId: hall.id, mediaId, mimeType })
  const created = await sharedUploadAndPersist({
    path: storagePath,
    buffer,
    mimeType,
    persist: ({ storagePath }) => mediaRepository.create({ id: mediaId, hallId: hall.id, type: 'PHOTO', storagePath }),
  })

  recordAuditEvent('HALL_MEDIA_UPLOADED', {
    hallId: hall.id,
    hotelId: hall.hotelId,
    details: { mediaId: created.id, type: 'PHOTO' },
  })

  return created
}

export async function deleteMedia(hall, mediaId) {
  const media = await mediaRepository.findByIdForHall(mediaId, hall.id)
  if (!media) {
    throw new NotFoundError('Hall media not found.')
  }

  await deleteStoredMedia(media.storagePath)
  await mediaRepository.remove(media.id)

  recordAuditEvent('HALL_MEDIA_DELETED', {
    hallId: hall.id,
    hotelId: hall.hotelId,
    details: { mediaId: media.id, type: media.type },
  })
}

export async function getMedia(hall) {
  const photos = await mediaRepository.findPhotosForHall(hall.id)
  return { photos }
}
