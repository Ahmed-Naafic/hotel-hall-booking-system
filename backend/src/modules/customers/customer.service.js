import * as customerRepository from './customer.repository.js'
import { getReadiness } from './customerProfilePolicy.js'
import { ConflictError, NotFoundError } from '../../shared/errors/errorTypes.js'

export async function getCurrentCustomer(userId) {
  const [user, profile] = await Promise.all([
    customerRepository.findUserById(userId),
    customerRepository.findProfileByUserId(userId),
  ])
  if (!user) throw new NotFoundError('Customer account not found.')
  return { user, profile, readiness: getReadiness(profile) }
}

export async function createProfile(userId, profileData) {
  const existing = await customerRepository.findProfileByUserId(userId)
  if (existing) throw new ConflictError('Customer profile already exists.')
  return customerRepository.createProfile({ userId, profileData })
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
