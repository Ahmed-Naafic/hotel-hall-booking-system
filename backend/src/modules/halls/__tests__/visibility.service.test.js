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
})
