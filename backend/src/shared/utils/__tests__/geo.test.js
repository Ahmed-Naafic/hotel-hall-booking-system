import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import { haversineDistanceKm } from '../geo.js'

describe('haversineDistanceKm', () => {
  test('returns 0 for the same point', () => {
    const distance = haversineDistanceKm({ lat1: -1.286389, lon1: 36.817223, lat2: -1.286389, lon2: 36.817223 })
    assert.equal(distance, 0)
  })

  test('is symmetric', () => {
    const a = { lat1: -1.286389, lon1: 36.817223, lat2: -1.2, lon2: 36.9 }
    const b = { lat1: -1.2, lon1: 36.9, lat2: -1.286389, lon2: 36.817223 }
    assert.ok(Math.abs(haversineDistanceKm(a) - haversineDistanceKm(b)) < 1e-9)
  })

  test('one degree of latitude is approximately 111 km', () => {
    const distance = haversineDistanceKm({ lat1: 0, lon1: 0, lat2: 1, lon2: 0 })
    assert.ok(distance > 110 && distance < 112, `expected ~111km, got ${distance}`)
  })

  test('a known short distance (~1.2km apart) resolves within tolerance', () => {
    // Two points roughly 1.2km apart near the equator/Nairobi area.
    const distance = haversineDistanceKm({ lat1: -1.286389, lon1: 36.817223, lat2: -1.2765, lon2: 36.8175 })
    assert.ok(distance > 1 && distance < 1.5, `expected ~1.1-1.2km, got ${distance}`)
  })

  test('antipodal-ish far points are far outside a 5km radius', () => {
    const distance = haversineDistanceKm({ lat1: -1.286389, lon1: 36.817223, lat2: 51.5072, lon2: -0.1276 })
    assert.ok(distance > 1000)
  })
})
