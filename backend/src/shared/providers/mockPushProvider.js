import { logger } from '../../config/logger.js'

/**
 * Fake PushProvider (architecture-principles.md §10-11 abstraction pattern)
 * for local development and automated tests — never contacts a real
 * Firebase project, never requires credentials, and always "succeeds".
 *
 * Sent pushes are kept in memory so a test can assert what was "delivered"
 * without any real push channel (testing-standards.md §6: external services
 * are tested via mocks/test doubles, never a dependency on a real external
 * service).
 */
export class MockPushProvider {
  constructor() {
    this.sentPushes = []
    this._failNextSend = false
  }

  async sendPush({ deviceToken, title, body, data }) {
    if (this._failNextSend) {
      this._failNextSend = false
      logger.warn('[MockPushProvider] Simulated push delivery failure', { deviceToken })
      throw new Error('Simulated push delivery failure.')
    }
    const push = { deviceToken, title, body, data, sentAt: new Date() }
    this.sentPushes.push(push)
    logger.info('[MockPushProvider] Push not actually sent (no push provider configured)', {
      deviceToken,
    })
    return { success: true, providerMessageId: `mock-${this.sentPushes.length}` }
  }

  /** Test helper — the most recent push sent to a given device token. */
  getLastPushTo(deviceToken) {
    return [...this.sentPushes].reverse().find((push) => push.deviceToken === deviceToken)
  }

  /** Test helper — makes the next `sendPush()` call reject. */
  failNextSend() {
    this._failNextSend = true
  }

  /** Test helper — clears state between test runs. */
  reset() {
    this.sentPushes = []
    this._failNextSend = false
  }
}
