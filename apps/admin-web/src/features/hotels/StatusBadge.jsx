import { STATUS_TONE, formatStatusLabel } from './hotelStatus.js'

export function StatusBadge({ status }) {
  const tone = STATUS_TONE[status] ?? { fg: 'var(--text-subtle)', bg: 'var(--surface-navy-tint)' }
  return (
    <span
      style={{
        display: 'inline-block',
        padding: '2px 10px',
        borderRadius: 'var(--radius-full, 999px)',
        fontSize: 'var(--text-2xs)',
        fontWeight: 'var(--weight-medium)',
        letterSpacing: 'var(--tracking-wider)',
        textTransform: 'uppercase',
        color: tone.fg,
        background: tone.bg,
        whiteSpace: 'nowrap',
      }}
    >
      {formatStatusLabel(status)}
    </span>
  )
}
