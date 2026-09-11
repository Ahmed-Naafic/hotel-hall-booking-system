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

// Best-effort read of a location-ish field. `location` itself is a
// structured value (ADR-0008 — `{ latitude, longitude, address }`,
// `Hotel.profileData.location`) written by the Hotel Manager's location
// picker; a couple of older/plainer keys are checked as string fallbacks
// for profiles that predate that structure. Returns null (never a
// placeholder string) when nothing usable is present.
const LOCATION_FALLBACK_KEYS = ['city', 'address']

export function getHotelLocation(hotel) {
  const profileData = hotel?.profileData
  if (!profileData || typeof profileData !== 'object') return null
  const location = profileData.location
  if (
    location &&
    typeof location === 'object' &&
    typeof location.address === 'string' &&
    location.address.trim().length > 0
  ) {
    return location.address.trim()
  }
  if (typeof location === 'string' && location.trim().length > 0) return location.trim()
  for (const key of LOCATION_FALLBACK_KEYS) {
    const value = profileData[key]
    if (typeof value === 'string' && value.trim().length > 0) return value.trim()
  }
  return null
}

// The Hotel's exact coordinates (ADR-0008), when the profile has completed
// the structured location step — null for a profile that hasn't (or that
// predates the structure and only has a plain-string address/city).
export function getHotelCoordinates(hotel) {
  const location = hotel?.profileData?.location
  if (!location || typeof location !== 'object') return null
  const { latitude, longitude } = location
  if (typeof latitude !== 'number' || typeof longitude !== 'number') return null
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null
  return { latitude, longitude }
}

export function shortHotelId(id) {
  return typeof id === 'string' ? id.slice(0, 8) : id
}
