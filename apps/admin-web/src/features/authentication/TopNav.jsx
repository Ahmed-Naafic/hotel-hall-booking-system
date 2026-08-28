import { useState } from 'react'
import '../../shared/components/topnav.css'
import logoMark from '../../shared/design-system/assets/logo-mark.png'
import { IconMenu, IconClose } from '../../shared/components/Icon.jsx'
import { ProfileMenu } from './ProfileMenu.jsx'
import { NotificationsMenu } from './NotificationsMenu.jsx'

/**
 * The permanent top navigation (no sidebar, per the approved nav
 * direction). Center links are only the screens this app actually has —
 * Overview, Hotels, Applications. There is no "Administration" link:
 * Administration & Platform Management (Module 13) isn't built, and a nav
 * item with nowhere real to go would be exactly the "fake navigation
 * destination" this redesign was told not to create.
 */
const NAV_ITEMS = [
  { key: 'overview', label: 'Overview' },
  { key: 'hotels', label: 'Hotels' },
  { key: 'applications', label: 'Applications' },
]

export function TopNav({ activeView, onNavigate, user, onChangePassword, onLogout }) {
  const [mobileOpen, setMobileOpen] = useState(false)

  function navigate(view) {
    setMobileOpen(false)
    onNavigate(view)
  }

  return (
    <header style={{ background: 'var(--surface-navy)', borderBottom: '1px solid var(--navy-800)' }}>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: 'var(--space-4)',
          maxWidth: 1200,
          margin: '0 auto',
          padding: '0 var(--space-6)',
          height: 60,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0 }}>
          <img src={logoMark} alt="" width={30} height={30} style={{ display: 'block', borderRadius: 6 }} />
          <div style={{ minWidth: 0 }}>
            <p style={{ margin: 0, fontFamily: 'var(--font-display)', fontSize: 15, letterSpacing: 'var(--tracking-wide)', color: 'var(--white)', lineHeight: 1.1 }}>
              Hotel Hall
            </p>
            <p className="hh-eyebrow" style={{ margin: 0, fontSize: 10 }}>
              PLATFORM ADMINISTRATION
            </p>
          </div>
        </div>

        <nav className="hh-topnav-links" style={{ gap: 4 }} aria-label="Primary">
          {NAV_ITEMS.map((item) => (
            <button
              key={item.key}
              className={`hh-topnav-link${activeView === item.key ? ' is-active' : ''}`}
              aria-current={activeView === item.key ? 'page' : undefined}
              onClick={() => navigate(item.key)}
            >
              {item.label}
            </button>
          ))}
        </nav>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: '0 0 auto' }}>
          <NotificationsMenu />
          <ProfileMenu user={user} onChangePassword={onChangePassword} onLogout={onLogout} />
          <button
            className="hh-topnav-toggle"
            onClick={() => setMobileOpen((o) => !o)}
            aria-label={mobileOpen ? 'Close menu' : 'Open menu'}
            aria-expanded={mobileOpen}
            style={{
              alignItems: 'center',
              justifyContent: 'center',
              width: 36,
              height: 36,
              border: '1px solid rgba(255,255,255,0.18)',
              borderRadius: 'var(--radius-md)',
              background: 'rgba(255,255,255,0.06)',
              color: 'var(--white)',
              cursor: 'pointer',
            }}
          >
            {mobileOpen ? <IconClose size={18} /> : <IconMenu size={18} />}
          </button>
        </div>
      </div>

      <div
        className={`hh-topnav-mobile-panel${mobileOpen ? ' is-open' : ''}`}
        style={{ flexDirection: 'column', padding: 'var(--space-3) var(--space-6) var(--space-4)', gap: 4, borderTop: '1px solid rgba(255,255,255,0.12)' }}
      >
        {NAV_ITEMS.map((item) => (
          <button
            key={item.key}
            className={`hh-topnav-link${activeView === item.key ? ' is-active' : ''}`}
            aria-current={activeView === item.key ? 'page' : undefined}
            onClick={() => navigate(item.key)}
            style={{ justifyContent: 'flex-start' }}
          >
            {item.label}
          </button>
        ))}
      </div>
    </header>
  )
}
