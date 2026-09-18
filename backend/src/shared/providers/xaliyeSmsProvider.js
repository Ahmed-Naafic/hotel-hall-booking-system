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
        body: JSON.stringify({ mobile: toE164(to), message: body }),
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

    // The gateway answers 200 with `success: false` for a message it did not
    // accept (an unreachable number, an exhausted balance), so HTTP status
    // alone would report those as delivered.
    const accepted = response.ok && payload?.success !== false
    if (!accepted) {
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

/**
 * Somalia. Registration accepts a mobile number with or without a country
 * code (`/^\+?[1-9]\d{6,14}$/`), so accounts exist in both shapes —
 * `+252619490318` and a bare local `615008800` — and the gateway needs a
 * dialable number either way.
 */
const DEFAULT_COUNTRY_CODE = '252'

/**
 * Widens whatever shape an account was registered in into the international
 * form the gateway dials. Normalising here, at the boundary, rather than
 * rewriting stored numbers: the stored value is what the Customer types to
 * log in, and changing it would break sign-in for every existing account.
 *
 * A number that already carries a country code is left alone, so this never
 * assumes Somalia for someone who registered from abroad.
 */
export function toE164(mobileNumber, countryCode = DEFAULT_COUNTRY_CODE) {
  const cleaned = String(mobileNumber ?? '').replace(/[\s\-()./]/g, '')
  if (cleaned === '') return cleaned

  if (cleaned.startsWith('+')) return cleaned
  // 00 is the other way of writing the international prefix.
  if (cleaned.startsWith('00')) return `+${cleaned.slice(2)}`
  if (cleaned.startsWith(countryCode)) return `+${cleaned}`
  // A single leading 0 is the national trunk prefix, dropped in E.164.
  if (cleaned.startsWith('0')) return `+${countryCode}${cleaned.slice(1)}`
  return `+${countryCode}${cleaned}`
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
 * The observed success payload nests the id as
 * `{ success, data: { Data: { MessageID } } }` — the upstream carrier's
 * envelope passed through. Flatter spellings are accepted too so a change
 * in that envelope degrades to "no id" rather than throwing. Nothing in
 * this system reads the id back; it exists for tracing a delivery in the
 * provider's own dashboard.
 */
function messageIdFrom(payload) {
  if (!payload || typeof payload !== 'object') return null
  return (
    payload.data?.Data?.MessageID ??
    payload.messageId ??
    payload.id ??
    payload.message_id ??
    null
  )
}
