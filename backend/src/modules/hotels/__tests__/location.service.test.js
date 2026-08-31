import test from 'node:test'
import assert from 'node:assert/strict'

import { reverseGeocode } from '../location.service.js'

test('returns a detected address from the configured provider', async () => {
  const provider = { reverseGeocode: async ({ latitude, longitude }) => `${latitude},${longitude} Nairobi` }
  assert.deepEqual(await reverseGeocode({ latitude: -1.28, longitude: 36.81 }, { provider }), {
    available: true,
    address: '-1.28,36.81 Nairobi',
  })
})

test('provider failure is represented as a non-blocking unavailable result', async () => {
  const provider = { reverseGeocode: async () => null }
  assert.deepEqual(await reverseGeocode({ latitude: -1.28, longitude: 36.81 }, { provider }), {
    available: false,
    address: null,
  })
})
