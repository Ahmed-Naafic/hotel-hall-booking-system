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
    this._nextFailureCode = undefined
  }

  async sendPush({ deviceToken, title, body, data }) {
    if (this._failNextSend) {
      this._failNextSend = false
      const code = this._nextFailureCode
      this._nextFailureCode = undefined
      logger.warn('[MockPushProvider] Simulated push delivery failure', { deviceToken, code })
      // Mirrors FcmPushProvider's own failure shape exactly (a generic
      // message wrapping the real cause — coding-standards.md §9, no
      // internal-implementation leakage) so callers that branch on
      // `err.cause?.code` (e.g. dead-token pruning) behave identically
      // against Mock and real FCM.
      const cause = new Error('Simulated push delivery failure.')
      if (code) cause.code = code
      throw new Error('Push delivery failed.', { cause })
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

  /** Test helper — makes the next `sendPush()` call reject, optionally
   *  with a specific FCM-style error `code` (e.g.
   *  'messaging/registration-token-not-registered') carried on the
   *  wrapped error's `.cause`. */
  failNextSend(code) {
    this._failNextSend = true
    this._nextFailureCode = code
  }

  /** Test helper — clears state between test runs. */
  reset() {
    this.sentPushes = []
    this._failNextSend = false
    this._nextFailureCode = undefined
  }
}
