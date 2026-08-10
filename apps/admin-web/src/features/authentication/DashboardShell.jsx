import { useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { Button } from '../../shared/components/Button.jsx'
import { ChangePasswordCard } from './ChangePasswordCard.jsx'
import { HotelsListCard } from '../hotels/HotelsListCard.jsx'

/**
 * Minimal authenticated shell — hosts A2/A3 (logout, change password) and
 * the Hotel Management Hotel list (Technical Design §11, `GET /hotels`).
 * The real Administration & Platform Management dashboard (Hotel approval
 * *actions*, platform analytics — system-architecture-overview.md §4) is
 * Module 13's own scope, not built here; this is the read-only query
 * interface piece that's already unblocked.
 */
export function DashboardShell({ onPasswordChanged, onLogout }) {
  const { user, logout } = useAuth()
  const [view, setView] = useState('overview')
  const showChangePassword = view === 'password'
  const isPlatformAdministrator = user?.accountType === 'PLATFORM_ADMINISTRATOR'

  return (
    <div style={{ minHeight: '100vh', background: 'var(--surface-page)' }}>
      <header
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: 'var(--space-4) var(--space-6)',
          background: 'var(--surface-navy)',
          color: 'var(--text-on-navy)',
        }}
      >
        <span className="hh-eyebrow">HOTEL HALL &bull; PLATFORM ADMINISTRATION</span>
        <Button
          variant="ghost"
          size="sm"
          onClick={() => {
            logout()
            onLogout?.()
          }}
        >
          Log out
        </Button>
      </header>

      <main
        style={{
          padding: 'var(--space-8) var(--space-6)',
          maxWidth: view === 'hotels' ? 960 : 640,
          margin: '0 auto',
        }}
      >
        <h1
          style={{
            fontFamily: 'var(--font-display)',
            textTransform: 'uppercase',
            fontSize: 'var(--text-2xl)',
            color: 'var(--text-heading)',
            margin: '0 0 var(--space-2)',
          }}
        >
          Welcome
        </h1>
        <p style={{ color: 'var(--text-subtle)', marginBottom: 'var(--space-6)' }}>
          Signed in as {user?.mobileNumber} &middot; {user?.accountType}
        </p>

        {isPlatformAdministrator ? (
          <nav style={{ display: 'flex', gap: 'var(--space-2)', marginBottom: 'var(--space-6)' }}>
            <Button
              variant={view === 'overview' ? 'secondary' : 'ghost'}
              size="sm"
              onClick={() => setView('overview')}
            >
              Overview
            </Button>
            <Button variant={view === 'hotels' ? 'secondary' : 'ghost'} size="sm" onClick={() => setView('hotels')}>
              Hotels
            </Button>
          </nav>
        ) : null}

        <section
          style={{
            background: 'var(--surface-card)',
            border: '1px solid var(--border-subtle)',
            borderRadius: 'var(--radius-lg)',
            boxShadow: 'var(--shadow-sm)',
            padding: 'var(--space-6)',
          }}
        >
          {view === 'hotels' ? (
            <>
              <h2 style={{ fontSize: 'var(--text-lg)', color: 'var(--text-heading)', marginTop: 0 }}>Hotels</h2>
              <HotelsListCard />
            </>
          ) : showChangePassword ? (
            <>
              <h2 style={{ fontSize: 'var(--text-lg)', color: 'var(--text-heading)', marginTop: 0 }}>
                Change password
              </h2>
              <ChangePasswordCard onChanged={onPasswordChanged} />
              <Button
                variant="ghost"
                size="sm"
                style={{ marginTop: 'var(--space-4)' }}
                onClick={() => setView('overview')}
              >
                Cancel
              </Button>
            </>
          ) : (
            <Button variant="secondary" onClick={() => setView('password')}>
              Change password
            </Button>
          )}
        </section>
      </main>
    </div>
  )
}
