import { logger } from '../../config/logger.js'

/**
 * Fake SmsProvider (architecture-principles.md §10-11 abstraction pattern)
 * for local development and automated tests — never contacts a real
 * carrier, never requires credentials, and always "succeeds".
 *
 * Sent messages are kept in memory so a test can retrieve the verification
 * code or reset code it "delivered" without any real SMS channel
 * (testing-standards.md §6: external services are tested via mocks/test
 * doubles, never a dependency on a real external service).
 */
export class MockSmsProvider {
  constructor() {
    this.sentMessages = []
    this._failNextSend = false
  }

  /**
   * Test helper — makes the next send throw, the way a real gateway does
   * when it is unreachable or refuses the message. Mirrors
   * `MockStorageProvider.failNextUpload`, and exists for the same reason:
   * the failure path is a real one (a Customer cannot sign in without a
   * code) and deserves to be exercised rather than assumed.
   */
  failNextSend() {
    this._failNextSend = true
  }

  async sendSms({ to, body }) {
    if (this._failNextSend) {
      this._failNextSend = false
      logger.warn('[MockSmsProvider] Simulated SMS delivery failure', { to })
      throw new Error('Simulated SMS delivery failure.')
    }
    const message = { to, body, sentAt: new Date() }
    this.sentMessages.push(message)
    logger.info('[MockSmsProvider] SMS not actually sent (no SMS provider configured)', {
      to,
    })
    return { success: true, providerMessageId: `mock-${this.sentMessages.length}` }
  }

  /** Test helper — the most recent message sent to a given number. */
  getLastMessageTo(to) {
    return [...this.sentMessages].reverse().find((message) => message.to === to)
  }

  /** Test helper — clears history between test runs. */
  reset() {
    this.sentMessages = []
    this._failNextSend = false
  }
}
