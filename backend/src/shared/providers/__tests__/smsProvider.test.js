import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import { selectProvider } from '../smsProvider.js'
import { MockSmsProvider } from '../mockSmsProvider.js'
import { TwilioSmsProvider } from '../twilioSmsProvider.js'
import { XaliyeSmsProvider } from '../xaliyeSmsProvider.js'

// Pure decision logic — no network, no real credentials needed
// (testing-standards.md §5). Confirms the requirement directly: absent
// configuration selects the mock without throwing; present configuration
// selects the gateway it belongs to, in the documented order of preference.

describe('SmsProvider selection', () => {
  test('selects MockSmsProvider when nothing is configured', () => {
    assert.ok(selectProvider({}) instanceof MockSmsProvider)
    assert.ok(selectProvider() instanceof MockSmsProvider)
  })

  test('selects MockSmsProvider when any one Twilio credential is missing', () => {
    assert.ok(selectProvider({ twilio: { accountSid: 'AC123', authToken: 'token' } }) instanceof MockSmsProvider)
    assert.ok(selectProvider({ twilio: { accountSid: 'AC123', fromNumber: '+15550000000' } }) instanceof MockSmsProvider)
    assert.ok(selectProvider({ twilio: { authToken: 'token', fromNumber: '+15550000000' } }) instanceof MockSmsProvider)
  })

  test('never throws when configuration is absent (graceful fallback)', () => {
    assert.doesNotThrow(() => selectProvider({}))
    assert.doesNotThrow(() =>
      selectProvider({ twilio: { accountSid: undefined, authToken: undefined, fromNumber: undefined } }),
    )
    assert.doesNotThrow(() => selectProvider({ xaliye: { baseUrl: undefined } }))
  })

  test('selects TwilioSmsProvider when all three credentials are present', () => {
    const provider = selectProvider({
      twilio: {
        accountSid: 'AC-fake-for-test',
        authToken: 'fake-token-for-test',
        fromNumber: '+15550000000',
      },
    })
    assert.ok(provider instanceof TwilioSmsProvider)
  })

  test('selects XaliyeSmsProvider from the endpoint alone — the key is optional', () => {
    const provider = selectProvider({ xaliye: { baseUrl: 'https://sms.example/' } })
    assert.ok(provider instanceof XaliyeSmsProvider)
  })

  test('prefers Xaliye over Twilio — it is the channel that reaches Somali numbers', () => {
    const provider = selectProvider({
      xaliye: { baseUrl: 'https://sms.example' },
      twilio: {
        accountSid: 'AC-fake-for-test',
        authToken: 'fake-token-for-test',
        fromNumber: '+15550000000',
      },
    })
    assert.ok(provider instanceof XaliyeSmsProvider)
  })
})
