const EARTH_RADIUS_KM = 6371

function toRadians(degrees) {
  return (degrees * Math.PI) / 180
}

/**
 * Great-circle distance between two lat/lng points (Haversine formula), in
 * kilometers. Pure math — no PostGIS or database extension required. Used
 * by Nearby Hotels (Customer Mobile) to compute distance server-side so the
 * client never independently calculates or filters proximity.
 */
export function haversineDistanceKm({ lat1, lon1, lat2, lon2 }) {
  const dLat = toRadians(lat2 - lat1)
  const dLon = toRadians(lon2 - lon1)
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLon / 2) ** 2
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  return EARTH_RADIUS_KM * c
}
