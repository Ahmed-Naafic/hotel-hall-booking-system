import { useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { ApiError } from '../../shared/api/apiClient.js'
import { Button } from '../../shared/components/Button.jsx'
import { Input } from '../../shared/components/Input.jsx'

/**
 * A3 (Business Specification §7.3, BR-AUTH-08) — change password while
 * authenticated. Ends the session on success (AuthContext.changePassword),
 * so this component's caller decides what happens after (Dashboard sends
 * the administrator back to the login screen with a confirmation).
 */
export function ChangePasswordCard({ onChanged }) {
  const { changePassword } = useAuth()
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    setError('')
    setSubmitting(true)
    try {
      await changePassword(currentPassword, newPassword)
      onChanged()
    } catch (err) {
      if (err instanceof ApiError && (err.status === 422 || err.status === 400)) {
        setError(err.message)
      } else {
        setError('Something went wrong. Please try again.')
      }
      setSubmitting(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate style={{ maxWidth: 360 }}>
      <div style={{ marginBottom: 'var(--space-4)' }}>
        <Input
          label="Current password"
          type="password"
          autoComplete="current-password"
          required
          value={currentPassword}
          onChange={(event) => setCurrentPassword(event.target.value)}
        />
      </div>
      <div style={{ marginBottom: 'var(--space-6)' }}>
        <Input
          label="New password"
          type="password"
          autoComplete="new-password"
          required
          minLength={8}
          hint="At least 8 characters."
          value={newPassword}
          onChange={(event) => setNewPassword(event.target.value)}
        />
      </div>

      {error ? (
        <p role="alert" style={{ color: 'var(--danger-700)', fontSize: 'var(--text-sm)', marginBottom: 'var(--space-4)' }}>
          {error}
        </p>
      ) : null}

      <Button type="submit" variant="secondary" loading={submitting} disabled={submitting}>
        Change password
      </Button>
    </form>
  )
}
