import { logger } from '../../config/logger.js'

/**
 * Real SmsProvider (architecture-principles.md §10-11 abstraction pattern)
 * for the Xaliye gateway — the delivery channel that actually reaches
 * Somali numbers, which is what Verification (BR-AUTH-02) needs.
 *
 * Same contract as `TwilioSmsProvider`: `sendSms({ to, body })`, a generic
 * failure to the caller, the real cause logged. The endpoint is passed in
 * (shared/providers/smsProvider.js reads it from env), so this class never
 * reads environment variables itself and stays testable with a fake `fetch`.
 */
export class XaliyeSmsProvider {
  constructor({ baseUrl, apiKey, timeoutMs = 15000, fetchImpl = fetch }) {
    this.baseUrl = baseUrl.replace(/\/+$/, '')
    this.apiKey = apiKey
    this.timeoutMs = timeoutMs
    this.fetchImpl = fetchImpl
  }

  async sendSms({ to, body }) {
    // A verification code is worthless once it expires, so a gateway that
    // never answers has to fail rather than hold the request open.
    const abort = AbortSignal.timeout(this.timeoutMs)

    let response
    let payload
    try {
      response = await this.fetchImpl(`${this.baseUrl}/sendSMS`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(this.apiKey ? { Authorization: `Bearer ${this.apiKey}` } : {}),
        },
        body: JSON.stringify({ mobile: to, message: body }),
        signal: abort,
      })
      const text = await response.text()
      payload = text ? safeJson(text) : null
    } catch (error) {
      // No internal implementation leakage (coding-standards.md §9) — the
      // caller sees a generic failure; the real cause is logged, never
      // thrown to a client. The message body is deliberately not logged:
      // it carries the verification code.
      logger.error('[XaliyeSmsProvider] SMS delivery failed', { to, error: error.message })
      throw new Error('SMS delivery failed.', { cause: error })
    }

    if (!response.ok) {
      logger.error('[XaliyeSmsProvider] SMS gateway rejected the message', {
        to,
        status: response.status,
        response: typeof payload === 'string' ? payload.slice(0, 200) : payload,
      })
      throw new Error('SMS delivery failed.')
    }

    return {
      success: true,
      providerMessageId: messageIdFrom(payload),
    }
  }
}

function safeJson(text) {
  try {
    return JSON.parse(text)
  } catch {
    // The gateway is not documented as always returning JSON; the raw body
    // is still useful in a log line.
    return text
  }
}

/**
 * The gateway's success payload is not a documented shape, so this takes
 * whichever id-like field is present and otherwise reports none, rather
 * than inventing one. Nothing in this system reads the id back — it exists
 * for tracing a delivery in the provider's own dashboard.
 */
function messageIdFrom(payload) {
  if (payload && typeof payload === 'object') {
    return payload.messageId ?? payload.id ?? payload.message_id ?? null
  }
  return null
}
