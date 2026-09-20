import { useEffect, useRef, useState } from 'react'
import { IconBell } from '../../shared/components/Icon.jsx'
import { useNotifications } from '../notifications/useNotifications.js'

/**
 * A Notifications entry point in the header, per the approved nav
 * composition. Wired to the real Communication & Notification Management
 * API (Technical Design "Admin Web": deferred unless the existing shell
 * supports a bell/list cheaply without inventing new frontend
 * infrastructure — this bell/dropdown shell already existed as a
 * placeholder, so wiring it to the same `/notifications` routes every other
 * client already uses satisfies that condition). No push delivery to the
 * browser — that would be new infrastructure the Business Specification's
 * "Out of Scope for V1" excludes; this is the in-app list only, the same
 * scope Customer/Manager Mobile's own in-app treatment provides alongside
 * their push.
 */
export function NotificationsMenu({ onSelectHotel }) {
  const [open, setOpen] = useState(false)
  const rootRef = useRef(null)
  const { notifications, unreadCount, loadState, error, load, markRead, markAllRead } = useNotifications()

  useEffect(() => {
    if (!open) return
    load()
    function handleClick(event) {
      if (rootRef.current && !rootRef.current.contains(event.target)) setOpen(false)
    }
    document.addEventListener('mousedown', handleClick)
    return () => document.removeEventListener('mousedown', handleClick)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open])

  async function handleSelect(notification) {
    await markRead(notification.id)
    setOpen(false)
    if (notification.hotelId) {
      onSelectHotel?.(notification.hotelId)
    }
  }

  return (
    <div ref={rootRef} style={{ position: 'relative' }}>
      <button
        onClick={() => setOpen((o) => !o)}
        aria-haspopup="true"
        aria-expanded={open}
        aria-label={unreadCount > 0 ? `Notifications, ${unreadCount} unread` : 'Notifications'}
        style={{
          position: 'relative',
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
        {unreadCount > 0 ? (
          <span
            style={{
              position: 'absolute',
              top: 2,
              right: 2,
              minWidth: 15,
              height: 15,
              padding: '0 3px',
              borderRadius: 999,
              background: 'var(--danger-500)',
              color: 'white',
              fontSize: 9,
              fontWeight: 700,
              lineHeight: '15px',
              textAlign: 'center',
            }}
          >
            {unreadCount > 99 ? '99+' : unreadCount}
          </span>
        ) : null}
      </button>

      {open ? (
        <div
          role="dialog"
          aria-label="Notifications"
          style={{
            position: 'absolute',
            top: 'calc(100% + 8px)',
            right: 0,
            // Never wider than the screen it is pinned to.
            width: 'min(320px, calc(100vw - var(--space-6)))',
            maxHeight: 420,
            overflowY: 'auto',
            background: 'var(--surface-card)',
            border: '1px solid var(--border-subtle)',
            borderRadius: 'var(--radius-lg)',
            boxShadow: 'var(--shadow-lg)',
            padding: 'var(--space-4)',
            zIndex: 30,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
            <p style={{ margin: 0, fontSize: 'var(--text-sm)', fontWeight: 'var(--weight-medium)', color: 'var(--text-heading)' }}>
              Notifications
            </p>
            {unreadCount > 0 ? (
              <button
                onClick={markAllRead}
                style={{ border: 'none', background: 'none', color: 'var(--text-link)', fontSize: 'var(--text-xs)', cursor: 'pointer', padding: 0 }}
              >
                Mark all read
              </button>
            ) : null}
          </div>

          {loadState === 'loading' ? (
            <p style={{ margin: 0, fontSize: 'var(--text-sm)', color: 'var(--text-muted)' }}>Loading…</p>
          ) : loadState === 'error' ? (
            <div>
              <p style={{ margin: '0 0 6px', fontSize: 'var(--text-sm)', color: 'var(--danger-700)' }}>{error}</p>
              <button
                onClick={load}
                style={{ border: 'none', background: 'none', color: 'var(--text-link)', fontSize: 'var(--text-xs)', cursor: 'pointer', padding: 0 }}
              >
                Try again
              </button>
            </div>
          ) : notifications.length === 0 ? (
            <p style={{ margin: 0, fontSize: 'var(--text-sm)', color: 'var(--text-muted)' }}>You have no notifications yet.</p>
          ) : (
            <ul style={{ listStyle: 'none', margin: 0, padding: 0, display: 'flex', flexDirection: 'column', gap: 2 }}>
              {notifications.map((notification) => (
                <li key={notification.id}>
                  <button
                    onClick={() => handleSelect(notification)}
                    style={{
                      width: '100%',
                      textAlign: 'left',
                      border: 'none',
                      background: notification.status === 'UNREAD' ? 'var(--surface-sunken)' : 'transparent',
                      borderRadius: 'var(--radius-md)',
                      padding: 'var(--space-2) var(--space-3)',
                      cursor: 'pointer',
                      display: 'flex',
                      gap: 8,
                      alignItems: 'flex-start',
                    }}
                  >
                    {notification.status === 'UNREAD' ? (
                      <span style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--text-link)', marginTop: 6, flexShrink: 0 }} />
                    ) : (
                      <span style={{ width: 6, flexShrink: 0 }} />
                    )}
                    <span style={{ minWidth: 0 }}>
                      <span style={{ display: 'block', fontSize: 'var(--text-sm)', fontWeight: 'var(--weight-medium)', color: 'var(--text-heading)' }}>
                        {notification.title}
                      </span>
                      <span style={{ display: 'block', fontSize: 'var(--text-xs)', color: 'var(--text-muted)', marginTop: 2 }}>
                        {notification.body}
                      </span>
                      <span style={{ display: 'block', fontSize: 'var(--text-xs)', color: 'var(--text-subtle)', marginTop: 2 }}>
                        {new Date(notification.createdAt).toLocaleString()}
                      </span>
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      ) : null}
    </div>
  )
}
