/**
 * Reads display fields out of a Hotel's `profileData`. Profile content has
 * no fixed schema yet — Business Specification Pending Decision #7
 * (`Hotel.profileData` in schema.prisma) — so these only ever read a field
 * if the Hotel happens to have set one; they never assume it exists, and
 * never invent a value that isn't there.
 *
 * Two distinct "no name" cases are surfaced honestly rather than collapsed
 * into one generic label:
 *  - `incomplete`: `profileData` is null/empty — the Hotel hasn't
 *    completed its profile yet (still REGISTERED, per lifecycle.service.js
 *    — HM2 requires PROFILE_COMPLETE before an application can be
 *    submitted).
 *  - `unnamed`: `profileData` has content but no recognizable name field —
 *    a genuinely different situation from "nothing submitted yet."
 */
export function getHotelDisplayName(hotel) {
  const profileData = hotel?.profileData
  if (!profileData || typeof profileData !== 'object' || Object.keys(profileData).length === 0) {
    return { text: 'Profile Incomplete', variant: 'incomplete' }
  }
  const name = profileData.name
  if (typeof name === 'string' && name.trim().length > 0) {
    return { text: name.trim(), variant: 'named' }
  }
  return { text: 'Unnamed Hotel', variant: 'unnamed' }
}

// Best-effort read of a location-ish field. No field name is standardized
// yet (same Pending Decision #7 as above) — this checks the handful of
// plausible keys a Hotel Manager's client might use, and returns null
// (never a placeholder string) when none are present.
const LOCATION_KEYS = ['location', 'city', 'address']

export function getHotelLocation(hotel) {
  const profileData = hotel?.profileData
  if (!profileData || typeof profileData !== 'object') return null
  for (const key of LOCATION_KEYS) {
    const value = profileData[key]
    if (typeof value === 'string' && value.trim().length > 0) return value.trim()
  }
  return null
}

export function shortHotelId(id) {
  return typeof id === 'string' ? id.slice(0, 8) : id
}
