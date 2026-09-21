import { useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { ApiError } from '../../shared/api/apiClient.js'
import { Button } from '../../shared/components/Button.jsx'
import { Input } from '../../shared/components/Input.jsx'
import logoMark from '../../shared/design-system/assets/logo-mark.png'
import './login.css'

/**
 * A1 (Business Specification §7.3) — Platform Administrator login, in two
 * steps: the password, then the code texted to the account's mobile number.
 * A correct password alone issues no token, so a stolen one grants nothing.
 *
 * No registration link: Platform Administrator accounts are provisioned
 * internally, never self-registered (Business Specification §3.2).
 */
export function LoginPage({ notice }) {
  const { awaitingLoginCode } = useAuth()

  return (
    <Shell notice={awaitingLoginCode ? '' : notice}>
      {awaitingLoginCode ? <CodeStep /> : <PasswordStep />}
    </Shell>
  )
}

/**
 * The backend keeps sign-in failures generic on purpose (BR-AUTH-09/
 * BR-AUTH-06 for the password, and one uniform failure for an unknown
 * number, an expired code and a wrong code), so its message is shown as-is
 * rather than re-worded into something more specific. Anything else is an
 * unexpected fault and says so.
 */
function messageFor(error) {
  // 403 is the "wrong app" refusal raised by AuthContext when the account
  // that just authenticated is not a Platform Administrator; showing the
  // generic fault message instead would leave them guessing why correct
  // credentials bounced.
  if (error instanceof ApiError && [401, 403, 422].includes(error.status)) {
    return error.message
  }
  return 'Something went wrong. Please try again.'
}

function PasswordStep() {
  const { login } = useAuth()
  const [mobileNumber, setMobileNumber] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    setError('')
    setSubmitting(true)
    try {
      // Resolving true means a code was texted; the page swaps to the code
      // step on its own because `awaitingLoginCode` drives what renders.
      await login(mobileNumber, password)
    } catch (err) {
      setError(messageFor(err))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <div style={{ marginBottom: 'var(--space-4)' }}>
        <Input
          label="Mobile number"
          type="tel"
          autoComplete="username"
          required
          value={mobileNumber}
          onChange={(event) => setMobileNumber(event.target.value)}
        />
      </div>
      <div style={{ marginBottom: 'var(--space-6)' }}>
        <Input
          label="Password"
          type="password"
          autoComplete="current-password"
          required
          value={password}
          onChange={(event) => setPassword(event.target.value)}
        />
      </div>

      <ErrorLine message={error} />

      <Button type="submit" fullWidth loading={submitting} disabled={submitting}>
        Log in
      </Button>
    </form>
  )
}

function CodeStep() {
  const { completeLogin, resendLoginCode, cancelLogin, pendingMobileNumber } = useAuth()
  const [code, setCode] = useState('')
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [resending, setResending] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    setError('')
    setNotice('')
    setSubmitting(true)
    try {
      await completeLogin(code)
    } catch (err) {
      setError(messageFor(err))
    } finally {
      setSubmitting(false)
    }
  }

  async function handleResend() {
    setError('')
    setNotice('')
    setResending(true)
    try {
      await resendLoginCode()
      setNotice('A new code is on its way.')
    } catch (err) {
      setError(messageFor(err))
    } finally {
      setResending(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <p
        style={{
          fontSize: 'var(--text-sm)',
          color: 'var(--text-muted)',
          textAlign: 'center',
          margin: '0 0 var(--space-5)',
        }}
      >
        We sent a 6-digit code to {pendingMobileNumber}.
      </p>

      <div style={{ marginBottom: 'var(--space-6)' }}>
        <Input
          label="Verification code"
          type="text"
          inputMode="numeric"
          autoComplete="one-time-code"
          maxLength={6}
          required
          value={code}
          onChange={(event) => setCode(event.target.value.replace(/\D/g, ''))}
        />
      </div>

      {notice ? (
        <p
          role="status"
          style={{
            color: 'var(--success-700)',
            fontSize: 'var(--text-sm)',
            marginBottom: 'var(--space-4)',
          }}
        >
          {notice}
        </p>
      ) : null}

      <ErrorLine message={error} />

      <Button
        type="submit"
        fullWidth
        loading={submitting}
        disabled={submitting || code.length !== 6}
      >
        Verify and sign in
      </Button>

      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          gap: 'var(--space-3)',
          marginTop: 'var(--space-4)',
        }}
      >
        <Button type="button" variant="ghost" size="sm" onClick={handleResend} disabled={resending}>
          {resending ? 'Sending…' : 'Resend code'}
        </Button>
        <Button type="button" variant="ghost" size="sm" onClick={cancelLogin} disabled={submitting}>
          Use a different number
        </Button>
      </div>
    </form>
  )
}

function ErrorLine({ message }) {
  if (!message) return null
  return (
    <p
      role="alert"
      style={{
        color: 'var(--danger-700)',
        fontSize: 'var(--text-sm)',
        marginBottom: 'var(--space-4)',
      }}
    >
      {message}
    </p>
  )
}

function Shell({ notice, children }) {
  return (
    <div className="hh-login">
      <aside className="hh-login__brand">
        <div className="hh-login__arch" aria-hidden="true" />
        <div className="hh-login__arch hh-login__arch--inner" aria-hidden="true" />

        <div className="hh-login__brandInner hh-rise hh-rise--1">
          <img
            src={logoMark}
            alt=""
            width={44}
            height={44}
            style={{ display: 'block', borderRadius: 'var(--radius-md)' }}
          />
        </div>

        <div className="hh-login__brandInner">
          <p className="hh-eyebrow hh-rise hh-rise--2" style={{ margin: '0 0 var(--space-5)' }}>
            BOOK • STAY • CELEBRATE
          </p>
          <h1
            className="hh-rise hh-rise--3"
            style={{
              fontSize: 'var(--display-md)',
              color: 'var(--white)',
              margin: '0 0 var(--space-5)',
            }}
          >
            Platform
            <br />
            Administration
          </h1>
          <p
            className="hh-login__tagline hh-rise hh-rise--4"
            style={{
              fontFamily: 'var(--font-serif)',
              fontSize: 'var(--serif-md)',
              lineHeight: 'var(--serif-leading)',
              color: 'var(--text-on-navy)',
              opacity: 0.8,
              margin: 0,
            }}
          >
            Stay comfortable, celebrate memorable.
          </p>
        </div>

        <p
          className="hh-login__tagline"
          style={{ position: 'relative', zIndex: 1, margin: 0, fontSize: 'var(--text-xs)', color: 'var(--text-on-navy)', opacity: 0.55 }}
        >
          Every Hotel, application and decision on the Platform.
        </p>
      </aside>

      <main className="hh-login__form">
        <div className="hh-login__formInner">
          <div className="hh-rise hh-rise--2">
            <h2
              style={{
                fontSize: 'var(--display-sm)',
                color: 'var(--text-heading)',
                margin: '0 0 var(--space-3)',
              }}
            >
              Sign in
            </h2>
            <div
              aria-hidden="true"
              style={{ height: 1, width: 40, background: 'var(--border-rule-gold)', opacity: 0.6, marginBottom: 'var(--space-6)' }}
            />
          </div>

          {notice ? (
            <p
              role="status"
              className="hh-rise hh-rise--3"
              style={{
                color: 'var(--success-700)',
                fontSize: 'var(--text-sm)',
                marginBottom: 'var(--space-5)',
              }}
            >
              {notice}
            </p>
          ) : null}

          <div className="hh-rise hh-rise--3">{children}</div>
        </div>
      </main>
    </div>
  )
}
