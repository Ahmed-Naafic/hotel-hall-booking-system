import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import { MockSmsProvider } from '../mockSmsProvider.js'

describe('MockSmsProvider', () => {
  test('always succeeds without any real credentials', async () => {
    const provider = new MockSmsProvider()
    const result = await provider.sendSms({ to: '+15551234567', body: 'test' })
    assert.equal(result.success, true)
    assert.ok(result.providerMessageId)
  })

  test('records sent messages, retrievable by recipient', async () => {
    const provider = new MockSmsProvider()
    await provider.sendSms({ to: '+15551111111', body: 'first' })
    await provider.sendSms({ to: '+15552222222', body: 'second' })
    await provider.sendSms({ to: '+15551111111', body: 'third (most recent to this number)' })

    const last = provider.getLastMessageTo('+15551111111')
    assert.equal(last.body, 'third (most recent to this number)')
  })

  test('getLastMessageTo returns undefined for a number never messaged', () => {
    const provider = new MockSmsProvider()
    assert.equal(provider.getLastMessageTo('+15559999999'), undefined)
  })

  test('reset() clears history', async () => {
    const provider = new MockSmsProvider()
    await provider.sendSms({ to: '+15551234567', body: 'test' })
    provider.reset()
    assert.equal(provider.getLastMessageTo('+15551234567'), undefined)
  })
})
