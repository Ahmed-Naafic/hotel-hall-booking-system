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
    createdAt: profile.createdAt,
    updatedAt: profile.updatedAt,
  }
}
