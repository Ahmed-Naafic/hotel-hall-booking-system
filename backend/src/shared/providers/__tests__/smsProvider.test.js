import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import { selectProvider } from '../smsProvider.js'
import { MockSmsProvider } from '../mockSmsProvider.js'
import { TwilioSmsProvider } from '../twilioSmsProvider.js'

// Pure decision logic — no network, no real credentials needed
// (testing-standards.md §5). Confirms the requirement directly: absent
// credentials select the mock without throwing; present credentials
// select Twilio.

describe('SmsProvider selection', () => {
  test('selects MockSmsProvider when all three credentials are absent', () => {
    const provider = selectProvider({})
    assert.ok(provider instanceof MockSmsProvider)
  })

  test('selects MockSmsProvider when any one credential is missing', () => {
    assert.ok(selectProvider({ accountSid: 'AC123', authToken: 'token' }) instanceof MockSmsProvider)
    assert.ok(selectProvider({ accountSid: 'AC123', fromNumber: '+15550000000' }) instanceof MockSmsProvider)
    assert.ok(selectProvider({ authToken: 'token', fromNumber: '+15550000000' }) instanceof MockSmsProvider)
  })

  test('never throws when credentials are absent (graceful fallback)', () => {
    assert.doesNotThrow(() => selectProvider({}))
    assert.doesNotThrow(() =>
      selectProvider({ accountSid: undefined, authToken: undefined, fromNumber: undefined }),
    )
  })

  test('selects TwilioSmsProvider when all three credentials are present', () => {
    const provider = selectProvider({
      accountSid: 'AC-fake-for-test',
      authToken: 'fake-token-for-test',
      fromNumber: '+15550000000',
    })
    assert.ok(provider instanceof TwilioSmsProvider)
  })
})
