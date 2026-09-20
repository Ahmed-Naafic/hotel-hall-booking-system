import { useEffect, useRef, useState } from 'react'
import { IconUser, IconChevronDown, IconLock, IconLogout } from '../../shared/components/Icon.jsx'

/**
 * The signed-in Platform Administrator's account menu — replaces the bare
 * "Log out" button the header used to have. Both menu items are existing,
 * real features (A2 logout, A3 change password, Authentication &
 * Account Management Module 1) — nothing new is added here.
 */
export function ProfileMenu({ user, onChangePassword, onLogout }) {
  const [open, setOpen] = useState(false)
  const rootRef = useRef(null)

  useEffect(() => {
    if (!open) return
    function handleClick(event) {
      if (rootRef.current && !rootRef.current.contains(event.target)) setOpen(false)
    }
    function handleKey(event) {
      if (event.key === 'Escape') setOpen(false)
    }
    document.addEventListener('mousedown', handleClick)
    document.addEventListener('keydown', handleKey)
    return () => {
      document.removeEventListener('mousedown', handleClick)
      document.removeEventListener('keydown', handleKey)
    }
  }, [open])

  return (
    <div ref={rootRef} style={{ position: 'relative' }}>
      <button
        onClick={() => setOpen((o) => !o)}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-label="Account menu"
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 8,
          height: 36,
          padding: '0 10px 0 6px',
          border: '1px solid rgba(255,255,255,0.18)',
          borderRadius: 'var(--radius-pill)',
          background: 'rgba(255,255,255,0.06)',
          color: 'var(--text-on-navy)',
          cursor: 'pointer',
        }}
      >
        <span
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: 26,
            height: 26,
            borderRadius: '50%',
            background: 'var(--gold-600)',
            color: 'var(--navy-900)',
          }}
        >
          <IconUser size={14} />
        </span>
        <span className="hh-topnav-user-label" style={{ fontSize: 'var(--text-sm)', maxWidth: 140, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {user?.mobileNumber}
        </span>
        <IconChevronDown size={14} />
      </button>

      {open ? (
        <div
          role="menu"
          style={{
            position: 'absolute',
            top: 'calc(100% + 8px)',
            right: 0,
            minWidth: 'min(220px, calc(100vw - var(--space-6)))',
            background: 'var(--surface-card)',
            border: '1px solid var(--border-subtle)',
            borderRadius: 'var(--radius-lg)',
            boxShadow: 'var(--shadow-lg)',
            padding: 'var(--space-2)',
            zIndex: 30,
          }}
        >
          <div style={{ padding: 'var(--space-2) var(--space-3)', marginBottom: 4, borderBottom: '1px solid var(--border-subtle)' }}>
            <p style={{ margin: 0, fontSize: 'var(--text-sm)', color: 'var(--text-heading)', fontWeight: 'var(--weight-medium)' }}>
              {user?.mobileNumber}
            </p>
            <p style={{ margin: 0, fontSize: 'var(--text-xs)', color: 'var(--text-muted)' }}>Platform Administrator</p>
          </div>
          <MenuItem icon={<IconLock size={16} />} onClick={() => { setOpen(false); onChangePassword() }}>
            Change password
          </MenuItem>
          <MenuItem icon={<IconLogout size={16} />} onClick={() => { setOpen(false); onLogout() }}>
            Log out
          </MenuItem>
        </div>
      ) : null}
    </div>
  )
}

function MenuItem({ icon, onClick, children }) {
  return (
    <button
      role="menuitem"
      onClick={onClick}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        width: '100%',
        padding: '8px 10px',
        border: 0,
        borderRadius: 'var(--radius-md)',
        background: 'transparent',
        color: 'var(--text-body)',
        fontFamily: 'var(--font-sans)',
        fontSize: 'var(--text-sm)',
        textAlign: 'left',
        cursor: 'pointer',
      }}
      onMouseEnter={(e) => (e.currentTarget.style.background = 'var(--surface-navy-tint)')}
      onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
    >
      <span style={{ color: 'var(--text-muted)' }}>{icon}</span>
      {children}
    </button>
  )
}
