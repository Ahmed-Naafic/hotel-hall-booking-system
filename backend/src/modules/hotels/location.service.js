import { geocodingProvider } from '../../shared/location/geocodingProvider.js'

export async function reverseGeocode({ latitude, longitude }, { provider = geocodingProvider } = {}) {
  const address = await provider.reverseGeocode({ latitude, longitude })
  return { available: address !== null, address }
}
