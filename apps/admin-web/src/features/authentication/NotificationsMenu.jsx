import { useEffect, useRef, useState } from 'react'
import { IconBell } from '../../shared/components/Icon.jsx'

/**
 * A Notifications entry point in the header, per the approved nav
 * composition — but there is no Notifications module built yet (only
 * `authentication` and `hotels` exist under `backend/src/modules`), so
 * there is nothing real to list. Rather than invent sample notifications
 * or omit the affordance the design calls for, this opens to an honest
 * "no notifications yet" state — a true statement (there are zero,
 * because there is no source to produce any), not fabricated content.
 */
export function NotificationsMenu() {
  const [open, setOpen] = useState(false)
  const rootRef = useRef(null)

  useEffect(() => {
    if (!open) return
    function handleClick(event) {
      if (rootRef.current && !rootRef.current.contains(event.target)) setOpen(false)
    }
    document.addEventListener('mousedown', handleClick)
    return () => document.removeEventListener('mousedown', handleClick)
  }, [open])

  return (
    <div ref={rootRef} style={{ position: 'relative' }}>
      <button
        onClick={() => setOpen((o) => !o)}
        aria-haspopup="true"
        aria-expanded={open}
        aria-label="Notifications"
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          width: 36,
          height: 36,
          border: '1px solid rgba(255,255,255,0.18)',
          borderRadius: '50%',
          background: 'rgba(255,255,255,0.06)',
          color: 'var(--text-on-navy)',
          cursor: 'pointer',
        }}
      >
        <IconBell size={17} />
      </button>

      {open ? (
        <div
          role="dialog"
          aria-label="Notifications"
          style={{
            position: 'absolute',
            top: 'calc(100% + 8px)',
            right: 0,
            width: 260,
            background: 'var(--surface-card)',
            border: '1px solid var(--border-subtle)',
            borderRadius: 'var(--radius-lg)',
            boxShadow: 'var(--shadow-lg)',
            padding: 'var(--space-4)',
            zIndex: 30,
          }}
        >
          <p style={{ margin: '0 0 4px', fontSize: 'var(--text-sm)', fontWeight: 'var(--weight-medium)', color: 'var(--text-heading)' }}>
            Notifications
          </p>
          <p style={{ margin: 0, fontSize: 'var(--text-sm)', color: 'var(--text-muted)' }}>You have no notifications yet.</p>
        </div>
      ) : null}
    </div>
  )
}
