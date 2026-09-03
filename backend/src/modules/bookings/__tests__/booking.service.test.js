import test from 'node:test'
import assert from 'node:assert/strict'
import { calculatePricing } from '../booking.service.js'

test('24-hour ceiling pricing charges one unit for exactly 24 hours', () => {
  const startsAt = new Date('2030-01-01T00:00:00.000Z')
  const endsAt = new Date('2030-01-02T00:00:00.000Z')
  assert.deepEqual(calculatePricing({ startsAt, endsAt, rentAmountCents: 50000, advancePercent: 20 }), {
    totalRentCents: 50000,
    requiredAdvanceCents: 10000,
  })
})

test('25 hours at $500 per 24 hours costs $1,000', () => {
  const startsAt = new Date('2030-01-01T00:00:00.000Z')
  const endsAt = new Date('2030-01-02T01:00:00.000Z')
  assert.deepEqual(calculatePricing({ startsAt, endsAt, rentAmountCents: 50000, advancePercent: 25 }), {
    totalRentCents: 100000,
    requiredAdvanceCents: 25000,
  })
})

test('required advance rounds to the nearest cent', () => {
  const startsAt = new Date('2030-01-01T00:00:00.000Z')
  const endsAt = new Date('2030-01-01T01:00:00.000Z')
  assert.equal(calculatePricing({ startsAt, endsAt, rentAmountCents: 999, advancePercent: 12.5 }).requiredAdvanceCents, 125)
})
