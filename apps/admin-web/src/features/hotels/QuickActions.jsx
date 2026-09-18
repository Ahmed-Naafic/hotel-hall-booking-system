import { useState } from 'react'
import { IconBuilding, IconClipboard } from '../../shared/components/Icon.jsx'

/**
 * Only two actions are real: the Hotels registry and the Applications
 * queue, both already screens in this app. "Administration" and "System
 * Settings" are not included — Administration & Platform Management
 * (Module 13) isn't built, and there is no settings surface to link to;
 * adding buttons for either would be UI for functionality the backend
 * doesn't support yet.
 */
export function QuickActions({ onViewHotels, onReviewApplications }) {
  const actions = [
    { key: 'hotels', label: 'View All Hotels', description: 'Browse the full Hotel registry', Icon: IconBuilding, onClick: onViewHotels },
    { key: 'applications', label: 'Review Applications', description: 'Open the application queue', Icon: IconClipboard, onClick: onReviewApplications },
  ]

  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 'var(--space-3)' }}>
      {actions.map(({ key, ...action }) => (
        <QuickActionButton key={key} {...action} />
      ))}
    </div>
  )
}

function QuickActionButton({ label, description, Icon, onClick }) {
  const [hover, setHover] = useState(false)

  return (
    <button
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 'var(--space-3)',
        textAlign: 'left',
        padding: 'var(--space-4)',
        borderWidth: '1px',
        borderStyle: 'solid',
        borderColor: hover ? 'var(--teal-600)' : 'var(--border-subtle)',
        borderRadius: 'var(--radius-lg)',
        background: hover ? 'var(--surface-teal-tint)' : 'var(--surface-card)',
        cursor: 'pointer',
        transition: 'var(--transition-control)',
        fontFamily: 'var(--font-sans)',
      }}
    >
      <span
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          width: 36,
          height: 36,
          flex: '0 0 auto',
          borderRadius: 'var(--radius-md)',
          background: 'var(--surface-navy-tint)',
          color: 'var(--text-heading)',
        }}
      >
        <Icon size={18} />
      </span>
      <span>
        <span style={{ display: 'block', fontSize: 'var(--text-sm)', fontWeight: 'var(--weight-medium)', color: 'var(--text-heading)' }}>
          {label}
        </span>
        <span style={{ display: 'block', fontSize: 'var(--text-xs)', color: 'var(--text-muted)' }}>{description}</span>
      </span>
    </button>
  )
}
