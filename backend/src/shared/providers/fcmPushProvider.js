import admin from 'firebase-admin'
import { logger } from '../../config/logger.js'

/**
 * Real PushProvider (architecture-principles.md §10-11 abstraction
 * pattern), approved via ADR-0001 (Firebase Cloud Messaging is the
 * platform's push provider from the original technology-stack decision —
 * Notification Management, Module 10, is its first real consumer).
 * Constructed only when all three Firebase service-account credentials are
 * present (shared/providers/pushProvider.js) — this class itself never
 * reads environment variables directly, so it stays trivially testable with
 * fake credentials.
 *
 * Uses a service-account credential (HTTP v1 API), not the legacy FCM
 * server key naming-conventions.md §10 illustrates — Google deprecated the
 * legacy key/API; a service account is the current, correct integration.
 */
export class FcmPushProvider {
  constructor({ projectId, clientEmail, privateKey }) {
    this.app = admin.initializeApp(
      { credential: admin.credential.cert({ projectId, clientEmail, privateKey }) },
      'notifications',
    )
  }

  async sendPush({ deviceToken, title, body, data }) {
    try {
      const stringData = data
        ? Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)]))
        : undefined
      const messageId = await admin.messaging(this.app).send({
        token: deviceToken,
        notification: { title, body },
        data: stringData,
      })
      return { success: true, providerMessageId: messageId }
    } catch (err) {
      // No internal implementation leakage (coding-standards.md §9) — the
      // caller sees a generic failure; the real cause is logged, not thrown
      // to a client.
      logger.error('[FcmPushProvider] Push delivery failed', { error: err.message })
      throw new Error('Push delivery failed.', { cause: err })
    }
  }
}
