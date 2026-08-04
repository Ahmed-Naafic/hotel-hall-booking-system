import { env } from '../../config/env.js'
import { logger } from '../../config/logger.js'
import { TwilioSmsProvider } from './twilioSmsProvider.js'
import { MockSmsProvider } from './mockSmsProvider.js'

/**
 * SmsProvider abstraction (architecture-principles.md §10-11) — every
 * caller depends on this module's `sendSms({ to, body })` contract, never
 * on Twilio directly. Selected once, at process start, based on whether
 * all three Twilio credentials are present:
 *
 * - All present  -> TwilioSmsProvider (ADR-0005's approved provider).
 * - Any missing  -> MockSmsProvider. This is a normal, expected local-
 *   development and CI state, not a startup failure — the application
 *   must keep running (architecture-principles.md §11, graceful failure).
 *
 * Never hardcode a credential or placeholder value here or anywhere else;
 * absence simply selects the mock.
 *
 * `selectProvider` takes its credentials as a parameter (rather than
 * reading `env` itself) specifically so the selection *decision* is
 * unit-testable with fake inputs, without needing to reload this ES
 * module under different environment variables (testing-standards.md §5).
 */
export function selectProvider({ accountSid, authToken, fromNumber }) {
  if (accountSid && authToken && fromNumber) {
    logger.info('[smsProvider] Twilio credentials found — using TwilioSmsProvider.')
    return new TwilioSmsProvider({ accountSid, authToken, fromNumber })
  }

  logger.warn(
    '[smsProvider] No Twilio credentials configured (TWILIO_ACCOUNT_SID / ' +
      'TWILIO_AUTH_TOKEN / TWILIO_FROM_NUMBER) — falling back to MockSmsProvider. ' +
      'Verification codes and password-reset codes will not be delivered to a real phone.',
  )
  return new MockSmsProvider()
}

export const smsProvider = selectProvider(env.sms.twilio)
