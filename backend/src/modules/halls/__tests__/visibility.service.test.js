import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import { computeVisibility } from '../visibility.service.js'

/**
 * Unit test (testing-standards.md §5) — pure logic, no database, no
 * mocking. Exhaustive coverage of Technical Design §6's flowchart: every
 * combination of `isOwner` and `eligible` an owning-Hotel-Manager check
 * upstream (Security Design §12) can produce.
 */

describe('visibility.service — computeVisibility', () => {
  test('owning Hotel Manager sees the Hall regardless of eligibility (BR-HALL-02)', () => {
    assert.equal(computeVisibility({ isOwner: true, eligible: true }), true)
    assert.equal(computeVisibility({ isOwner: true, eligible: false }), true)
  })

  test('non-owner sees the Hall only while the owning Hotel is eligible (BR-HALL-03, BR-HALL-04)', () => {
    assert.equal(computeVisibility({ isOwner: false, eligible: true }), true)
    assert.equal(computeVisibility({ isOwner: false, eligible: false }), false)
  })

  test('isActive is a second, independent gate for a non-owner — both eligible AND active are required', () => {
    assert.equal(computeVisibility({ isOwner: false, eligible: true, isActive: true }), true)
    assert.equal(computeVisibility({ isOwner: false, eligible: true, isActive: false }), false)
    assert.equal(computeVisibility({ isOwner: false, eligible: false, isActive: true }), false)
    assert.equal(computeVisibility({ isOwner: false, eligible: false, isActive: false }), false)
  })

  test('owning Hotel Manager sees an inactive Hall too (BR-HALL-02 extends to isActive)', () => {
    assert.equal(computeVisibility({ isOwner: true, eligible: true, isActive: false }), true)
  })

  test('isActive defaults to true when omitted — every existing caller not yet passing it is unaffected', () => {
    assert.equal(computeVisibility({ isOwner: false, eligible: true }), true)
  })
})
