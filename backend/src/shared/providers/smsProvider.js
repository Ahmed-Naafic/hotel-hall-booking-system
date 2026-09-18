import { env } from '../../config/env.js'
import { logger } from '../../config/logger.js'
import { TwilioSmsProvider } from './twilioSmsProvider.js'
import { XaliyeSmsProvider } from './xaliyeSmsProvider.js'
import { MockSmsProvider } from './mockSmsProvider.js'

/**
 * SmsProvider abstraction (architecture-principles.md §10-11) — every
 * caller depends on this module's `sendSms({ to, body })` contract, never
 * on a specific gateway. Selected once, at process start:
 *
 * - `SMS_API_URL` set        -> XaliyeSmsProvider. Preferred: it is the
 *   channel that actually reaches Somali numbers, which is what
 *   Verification (BR-AUTH-02) needs.
 * - All Twilio credentials   -> TwilioSmsProvider (ADR-0005).
 * - Neither                  -> MockSmsProvider. This is a normal, expected
 *   local-development and CI state, not a startup failure — the application
 *   must keep running (architecture-principles.md §11, graceful failure).
 *
 * Never hardcode a credential or placeholder value here or anywhere else;
 * absence simply selects the next option down.
 *
 * `selectProvider` takes its configuration as a parameter (rather than
 * reading `env` itself) specifically so the selection *decision* is
 * unit-testable with fake inputs, without needing to reload this ES
 * module under different environment variables (testing-standards.md §5).
 */
export function selectProvider({ xaliye = {}, twilio = {} } = {}) {
  const { baseUrl, apiKey } = xaliye
  if (baseUrl) {
    logger.info('[smsProvider] SMS_API_URL configured — using XaliyeSmsProvider.')
    return new XaliyeSmsProvider({ baseUrl, apiKey })
  }

  const { accountSid, authToken, fromNumber } = twilio
  if (accountSid && authToken && fromNumber) {
    logger.info('[smsProvider] Twilio credentials found — using TwilioSmsProvider.')
    return new TwilioSmsProvider({ accountSid, authToken, fromNumber })
  }

  logger.warn(
    '[smsProvider] No SMS gateway configured (SMS_API_URL, or TWILIO_ACCOUNT_SID / ' +
      'TWILIO_AUTH_TOKEN / TWILIO_FROM_NUMBER) — falling back to MockSmsProvider. ' +
      'Verification codes and password-reset codes will not be delivered to a real phone.',
  )
  return new MockSmsProvider()
}

export const smsProvider = selectProvider(env.sms)
