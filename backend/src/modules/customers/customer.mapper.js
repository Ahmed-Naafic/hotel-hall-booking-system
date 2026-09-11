import { storageProvider } from '../../shared/providers/storageProvider.js'

export function toCustomerIdentity(user) {
  return {
    id: user.id,
    mobileNumber: user.mobileNumber,
    accountType: user.accountType,
    isVerified: user.isVerified,
    isActive: user.isActive,
  }
}

export function toCustomerProfile(profile) {
  if (!profile) return null
  return {
    id: profile.id,
    profileData: profile.profileData,
    avatarUrl: profile.avatarStoragePath
      ? storageProvider.getPublicUrl({ path: profile.avatarStoragePath })
      : null,
    createdAt: profile.createdAt,
    updatedAt: profile.updatedAt,
  }
}
