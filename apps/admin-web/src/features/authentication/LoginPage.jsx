import { useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { ApiError } from '../../shared/api/apiClient.js'
import { Button } from '../../shared/components/Button.jsx'
import { Input } from '../../shared/components/Input.jsx'
import logoFull from '../../shared/design-system/assets/logo-full.png'

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
  if (error instanceof ApiError && (error.status === 401 || error.status === 422)) {
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
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'var(--surface-page)',
        padding: 'var(--space-6)',
      }}
    >
      <div
        style={{
          width: '100%',
          maxWidth: 400,
          background: 'var(--surface-card)',
          border: '1px solid var(--border-subtle)',
          borderRadius: 'var(--radius-lg)',
          boxShadow: 'var(--shadow-sm)',
          padding: 'var(--space-8)',
        }}
      >
        <img
          src={logoFull}
          alt="Hotel Hall"
          style={{ display: 'block', width: 96, height: 96, margin: '0 auto var(--space-6)' }}
        />
        <p className="hh-eyebrow" style={{ textAlign: 'center', marginBottom: 'var(--space-2)' }}>
          PLATFORM ADMINISTRATION
        </p>
        <h1
          style={{
            fontFamily: 'var(--font-display)',
            textTransform: 'uppercase',
            textAlign: 'center',
            fontSize: 'var(--text-xl)',
            letterSpacing: 'var(--tracking-wide)',
            color: 'var(--text-heading)',
            margin: '0 0 var(--space-6)',
          }}
        >
          Sign in
        </h1>

        {notice ? (
          <p
            role="status"
            style={{
              color: 'var(--success-700)',
              fontSize: 'var(--text-sm)',
              textAlign: 'center',
              marginBottom: 'var(--space-4)',
            }}
          >
            {notice}
          </p>
        ) : null}

        {children}
      </div>
    </div>
  )
}
