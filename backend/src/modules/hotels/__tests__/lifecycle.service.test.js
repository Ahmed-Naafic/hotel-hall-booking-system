import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import { isValidTransition } from '../lifecycle.service.js'

/**
 * Unit test (testing-standards.md §5) — pure logic, no database. Exhaustive
 * coverage of every row in Technical Design §6.2's transition table, plus
 * the SUSPENDED/DEACTIVATED → APPROVED_ACTIVE reactivation paths added on
 * top of it (BDR-012), positive and negative.
 */

const VALID_PAIRS = [
  ['REGISTERED', 'PROFILE_COMPLETE'],
  ['PROFILE_COMPLETE', 'UNDER_REVIEW'],
  ['UNDER_REVIEW', 'APPROVED_ACTIVE'],
  ['UNDER_REVIEW', 'REJECTED'],
  ['UNDER_REVIEW', 'WITHDRAWN'],
  ['REJECTED', 'UNDER_REVIEW'],
  ['APPROVED_ACTIVE', 'SUSPENDED'],
  ['APPROVED_ACTIVE', 'DEACTIVATED'],
  ['APPROVED_ACTIVE', 'RESTRICTED_UNDER_REVIEW'],
  ['RESTRICTED_UNDER_REVIEW', 'APPROVED_ACTIVE'],
  ['SUSPENDED', 'APPROVED_ACTIVE'],
  ['DEACTIVATED', 'APPROVED_ACTIVE'],
]

const ALL_STATUSES = [
  'REGISTERED',
  'PROFILE_COMPLETE',
  'UNDER_REVIEW',
  'APPROVED_ACTIVE',
  'REJECTED',
  'WITHDRAWN',
  'SUSPENDED',
  'DEACTIVATED',
  'RESTRICTED_UNDER_REVIEW',
]

describe('lifecycle.service — isValidTransition', () => {
  for (const [from, to] of VALID_PAIRS) {
    test(`allows ${from} -> ${to} (Technical Design §6.2)`, () => {
      assert.equal(isValidTransition(from, to), true)
    })
  }

  // Every pair NOT in VALID_PAIRS must be rejected — including the one
  // truly terminal state (WITHDRAWN) and every other deliberately-absent
  // transition (Technical Design §6). SUSPENDED/DEACTIVATED are no longer
  // terminal: each has a single reactivation path back to APPROVED_ACTIVE
  // (BDR-012).
  for (const from of ALL_STATUSES) {
    for (const to of ALL_STATUSES) {
      const isListedValid = VALID_PAIRS.some(([f, t]) => f === from && t === to)
      if (isListedValid || from === to) continue
      test(`rejects ${from} -> ${to} (not in Technical Design §6.2)`, () => {
        assert.equal(isValidTransition(from, to), false)
      })
    }
  }

  test('rejects a status transitioning to itself', () => {
    for (const status of ALL_STATUSES) {
      assert.equal(isValidTransition(status, status), false)
    }
  })
})
