import twilio from 'twilio'
import { logger } from '../../config/logger.js'

/**
 * Real SmsProvider (architecture-principles.md §10-11 abstraction pattern),
 * approved via ADR-0005. Constructed only when all three Twilio credentials
 * are present (shared/providers/smsProvider.js) — this class itself never
 * reads environment variables directly, so it stays trivially testable
 * with fake credentials.
 */
export class TwilioSmsProvider {
  constructor({ accountSid, authToken, fromNumber }) {
    this.fromNumber = fromNumber
    this.client = twilio(accountSid, authToken)
  }

  async sendSms({ to, body }) {
    try {
      const message = await this.client.messages.create({ to, from: this.fromNumber, body })
      return { success: true, providerMessageId: message.sid }
    } catch (err) {
      // No internal implementation leakage (coding-standards.md §9) — the
      // caller sees a generic failure; the real cause is logged, not thrown
      // to a client.
      logger.error('[TwilioSmsProvider] SMS delivery failed', { to, error: err.message })
      throw new Error('SMS delivery failed.', { cause: err })
    }
  }
}
