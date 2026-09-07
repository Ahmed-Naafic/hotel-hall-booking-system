import { env } from '../../config/env.js'
import { logger } from '../../config/logger.js'
import { FcmPushProvider } from './fcmPushProvider.js'
import { MockPushProvider } from './mockPushProvider.js'

/**
 * PushProvider abstraction (architecture-principles.md §10-11) — every
 * caller depends on this module's `sendPush({ deviceToken, title, body,
 * data })` contract, never on Firebase directly. Selected once, at process
 * start, based on whether all three Firebase service-account credentials
 * are present:
 *
 * - All present  -> FcmPushProvider (ADR-0001's already-approved provider).
 * - Any missing  -> MockPushProvider. This is a normal, expected local-
 *   development and CI state, not a startup failure — the application must
 *   keep running (architecture-principles.md §11, graceful failure), and
 *   Notification Management's persistence/API/read-state all work fully
 *   without a configured push provider (Business Specification, push is a
 *   best-effort delivery mechanism, never the source of truth).
 *
 * Never hardcode a credential or placeholder value here or anywhere else;
 * absence simply selects the mock.
 *
 * `selectProvider` takes its credentials as a parameter (rather than
 * reading `env` itself) specifically so the selection *decision* is
 * unit-testable with fake inputs, without needing to reload this ES module
 * under different environment variables (testing-standards.md §5) — the
 * same pattern `smsProvider.js`/`storageProvider.js` already establish.
 */
export function selectProvider({ projectId, clientEmail, privateKey }) {
  if (projectId && clientEmail && privateKey) {
    logger.info('[pushProvider] Firebase credentials found — using FcmPushProvider.')
    return new FcmPushProvider({ projectId, clientEmail, privateKey })
  }

  logger.warn(
    '[pushProvider] No Firebase credentials configured (FIREBASE_PROJECT_ID / ' +
      'FIREBASE_CLIENT_EMAIL / FIREBASE_PRIVATE_KEY) — falling back to MockPushProvider. ' +
      'Notifications will still be created and readable in-app; push delivery is simulated.',
  )
  return new MockPushProvider()
}

export const pushProvider = selectProvider(env.push.firebase)
