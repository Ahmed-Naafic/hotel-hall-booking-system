const DEFAULT_ENDPOINT = 'https://nominatim.openstreetmap.org/reverse'
const DEFAULT_TIMEOUT_MS = 5000
const MIN_REQUEST_INTERVAL_MS = 1100

export class NominatimGeocodingProvider {
  constructor({ fetchImpl = fetch, endpoint = DEFAULT_ENDPOINT, timeoutMs = DEFAULT_TIMEOUT_MS } = {}) {
    this.fetchImpl = fetchImpl
    this.endpoint = endpoint
    this.timeoutMs = timeoutMs
    this.nextAllowedAt = 0
  }

  async reverseGeocode({ latitude, longitude }) {
    const waitMs = Math.max(0, this.nextAllowedAt - Date.now())
    if (waitMs > 0) await new Promise((resolve) => setTimeout(resolve, waitMs))
    this.nextAllowedAt = Date.now() + MIN_REQUEST_INTERVAL_MS
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs)
    try {
      const url = new URL(this.endpoint)
      url.searchParams.set('format', 'jsonv2')
      url.searchParams.set('lat', String(latitude))
      url.searchParams.set('lon', String(longitude))
      url.searchParams.set('addressdetails', '1')
      const response = await this.fetchImpl(url, {
        headers: {
          Accept: 'application/json',
          'User-Agent': process.env.GEOCODING_USER_AGENT || 'hotel-hall-booking-system/1.0',
        },
        signal: controller.signal,
      })
      if (!response.ok) return null
      const payload = await response.json()
      const address = typeof payload.display_name === 'string' ? payload.display_name.trim() : ''
      return address || null
    } catch {
      return null
    } finally {
      clearTimeout(timeout)
    }
  }
}
