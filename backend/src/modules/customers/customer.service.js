import { randomUUID } from 'node:crypto'
import * as customerRepository from './customer.repository.js'
import { getReadiness } from './customerProfilePolicy.js'
import { uploadAndPersist, deleteStoredMedia } from '../../shared/media/mediaUpload.js'
import { extensionForMimeType } from '../../shared/media/imageValidation.js'
import { ConflictError, NotFoundError } from '../../shared/errors/errorTypes.js'

export async function getCurrentCustomer(userId) {
  const [user, profile] = await Promise.all([
    customerRepository.findUserById(userId),
    customerRepository.findProfileByUserId(userId),
  ])
  if (!user) throw new NotFoundError('Customer account not found.')
  return { user, profile, readiness: getReadiness(profile) }
}

export async function createProfile(userId, profileData, client) {
  const existing = await customerRepository.findProfileByUserId(userId, client)
  if (existing) throw new ConflictError('Customer profile already exists.')
  return customerRepository.createProfile({ userId, profileData }, client)
}

export async function updateProfile(userId, profileData) {
  const existing = await customerRepository.findProfileByUserId(userId)
  if (!existing) throw new NotFoundError('Customer profile not found.')
  return customerRepository.updateProfile({ userId, profileData: { ...existing.profileData, ...profileData } })
}

export async function getCustomerReadiness(userId) {
  const profile = await customerRepository.findProfileByUserId(userId)
  return getReadiness(profile)
}

/**
 * Uploads (or replaces) the Customer's own avatar — at most one at a time,
 * the same "replace, don't append" shape Hotel Media's Logo already
 * establishes (`hotels/media.service.js#uploadLogo`): the previous file is
 * deleted only *after* the new one is fully persisted, so an interrupted
 * upload never leaves the Customer without the avatar they previously had.
 */
export async function uploadAvatar(userId, { buffer, mimeType }) {
  const existing = await customerRepository.findProfileByUserId(userId)
  if (!existing) throw new NotFoundError('Customer profile not found.')

  const extension = extensionForMimeType(mimeType)
  const storagePath = `customers/${userId}/avatar/${randomUUID()}.${extension}`
  const previousPath = existing.avatarStoragePath

  const updated = await uploadAndPersist({
    path: storagePath,
    buffer,
    mimeType,
    persist: ({ storagePath }) => customerRepository.updateAvatar({ userId, avatarStoragePath: storagePath }),
  })

  if (previousPath) {
    await deleteStoredMedia(previousPath).catch(() => {})
  }

  return updated
}

export async function deleteAvatar(userId) {
  const existing = await customerRepository.findProfileByUserId(userId)
  if (!existing) throw new NotFoundError('Customer profile not found.')
  if (!existing.avatarStoragePath) throw new NotFoundError('No avatar to delete.')

  await deleteStoredMedia(existing.avatarStoragePath).catch(() => {})
  return customerRepository.updateAvatar({ userId, avatarStoragePath: null })
}
