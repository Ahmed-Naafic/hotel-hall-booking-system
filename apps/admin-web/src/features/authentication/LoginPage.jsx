import { useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { ApiError } from '../../shared/api/apiClient.js'
import { Button } from '../../shared/components/Button.jsx'
import { Input } from '../../shared/components/Input.jsx'
import logoFull from '../../shared/design-system/assets/logo-full.png'

/**
 * A1 (Business Specification §7.3) — Platform Administrator login.
 * No registration link: Platform Administrator accounts are provisioned
 * internally, never self-registered (Business Specification §3.2).
 */
export function LoginPage({ notice }) {
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
      await login(mobileNumber, password)
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) {
        // BR-AUTH-09/BR-AUTH-06: the backend already keeps this message
        // generic — displayed as-is, never re-worded into something more
        // specific that would leak which part was wrong.
        setError(err.message)
      } else {
        setError('Something went wrong. Please try again.')
      }
    } finally {
      setSubmitting(false)
    }
  }

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
        <p
          className="hh-eyebrow"
          style={{ textAlign: 'center', marginBottom: 'var(--space-2)' }}
        >
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

          {error ? (
            <p
              role="alert"
              style={{
                color: 'var(--danger-700)',
                fontSize: 'var(--text-sm)',
                marginBottom: 'var(--space-4)',
              }}
            >
              {error}
            </p>
          ) : null}

          <Button type="submit" fullWidth loading={submitting} disabled={submitting}>
            Log in
          </Button>
        </form>
      </div>
    </div>
  )
}
