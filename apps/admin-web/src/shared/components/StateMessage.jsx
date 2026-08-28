import { Button } from './Button.jsx'

/**
 * Shared empty/error state block — reused anywhere a list or detail view
 * has nothing to show (no data, no results, or a failed request). Keeps
 * empty/error presentation consistent across features instead of each
 * screen inventing its own.
 */
export function StateMessage({ tone = 'empty', title, message, retryLabel = 'Retry', onRetry, style }) {
  const isError = tone === 'error'
  return (
    <div
      role={isError ? 'alert' : 'status'}
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        textAlign: 'center',
        gap: 'var(--space-3)',
        padding: 'var(--space-9) var(--space-6)',
        border: `1px dashed ${isError ? 'var(--danger-500)' : 'var(--border-default)'}`,
        borderRadius: 'var(--radius-lg)',
        background: isError ? 'var(--danger-100)' : 'var(--surface-sunken)',
        ...style,
      }}
    >
      {title ? (
        <p
          style={{
            margin: 0,
            fontFamily: 'var(--font-sans)',
            fontSize: 'var(--text-sm)',
            fontWeight: 'var(--weight-semibold)',
            color: isError ? 'var(--danger-700)' : 'var(--text-heading)',
          }}
        >
          {title}
        </p>
      ) : null}
      {message ? (
        <p style={{ margin: 0, fontSize: 'var(--text-sm)', color: 'var(--text-muted)', maxWidth: 420 }}>
          {message}
        </p>
      ) : null}
      {onRetry ? (
        <Button variant={isError ? 'secondary' : 'ghost'} size="sm" onClick={onRetry} style={{ marginTop: 'var(--space-2)' }}>
          {retryLabel}
        </Button>
      ) : null}
    </div>
  )
}
