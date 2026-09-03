import { describe, test } from 'node:test'
import assert from 'node:assert/strict'
import {
  intervalsOverlap,
  mogadishuDayToUtcRange,
  combineBlockPeriod,
} from '../availability.service.js'

/**
 * Pure-function unit tests (testing-standards.md) — no database, no
 * server, matching `visibility.service.test.js`'s style for this module's
 * own pure decision logic.
 */

describe('intervalsOverlap — the [start, end) rule', () => {
  test('overlapping intervals', () => {
    assert.equal(
      intervalsOverlap({ startA: 10, endA: 14, startB: 12, endB: 16 }),
      true,
    )
  })

  test('adjacent intervals never overlap (10-14 and 14-18)', () => {
    assert.equal(
      intervalsOverlap({ startA: 10, endA: 14, startB: 14, endB: 18 }),
      false,
    )
  })

  test('fully-contained interval overlaps', () => {
    assert.equal(
      intervalsOverlap({ startA: 10, endA: 18, startB: 12, endB: 14 }),
      true,
    )
  })

  test('identical intervals overlap', () => {
    assert.equal(
      intervalsOverlap({ startA: 10, endA: 14, startB: 10, endB: 14 }),
      true,
    )
  })

  test('disjoint, non-adjacent intervals never overlap', () => {
    assert.equal(
      intervalsOverlap({ startA: 10, endA: 14, startB: 20, endB: 22 }),
      false,
    )
  })
})

describe('mogadishuDayToUtcRange — fixed +03:00, no DST', () => {
  test('a known date maps to the correct UTC window', () => {
    const { rangeStart, rangeEnd } = mogadishuDayToUtcRange('2026-09-10')
    assert.equal(rangeStart.toISOString(), '2026-09-09T21:00:00.000Z')
    assert.equal(rangeEnd.toISOString(), '2026-09-10T21:00:00.000Z')
  })

  test('correctly crosses a month boundary', () => {
    const { rangeStart, rangeEnd } = mogadishuDayToUtcRange('2026-10-01')
    assert.equal(rangeStart.toISOString(), '2026-09-30T21:00:00.000Z')
    assert.equal(rangeEnd.toISOString(), '2026-10-01T21:00:00.000Z')
  })
})

describe('combineBlockPeriod — date + startTime + endTime -> two absolute instants', () => {
  test('a same-day period combines directly, no rollover', () => {
    const { startsAt, endsAt } = combineBlockPeriod({ date: '2026-09-10', startTime: '10:00', endTime: '14:00' })
    assert.equal(startsAt.toISOString(), '2026-09-10T07:00:00.000Z')
    assert.equal(endsAt.toISOString(), '2026-09-10T11:00:00.000Z')
  })

  test('an overnight period (end time-of-day <= start time-of-day) rolls to the next calendar day', () => {
    const { startsAt, endsAt } = combineBlockPeriod({ date: '2026-09-10', startTime: '22:00', endTime: '02:00' })
    assert.equal(startsAt.toISOString(), '2026-09-10T19:00:00.000Z')
    assert.equal(endsAt.toISOString(), '2026-09-10T23:00:00.000Z')
    assert.ok(endsAt > startsAt)
  })

  test('identical start and end time-of-day produces a full 24-hour period, never a zero-length one', () => {
    const { startsAt, endsAt } = combineBlockPeriod({ date: '2026-09-10', startTime: '10:00', endTime: '10:00' })
    assert.equal(endsAt.getTime() - startsAt.getTime(), 24 * 60 * 60 * 1000)
  })
})
