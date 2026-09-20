/**
 * The masthead every screen opens with — the brand's own heading device,
 * not a generic admin title bar.
 *
 * Three parts, in the order the design system defines them: a gold eyebrow
 * (12px / .22em / uppercase), a Cinzel display title, and a gold hairline
 * beneath it. The readme is explicit that the gold rule is a brand device
 * rather than a divider — "flanking an eyebrow, or under a section title" —
 * which is exactly this use, and the only place gold earns its ~10% share
 * on an otherwise navy-and-ivory page.
 *
 * Titles are short on purpose: Cinzel is always uppercase here, and
 * uppercase titling type stops reading as a title much past two or three
 * words.
 */
export function PageHeader({ eyebrow, title, subtitle, actions }) {
  return (
    <header style={{ marginBottom: 'var(--space-9)' }}>
      {eyebrow ? (
        <p className="hh-eyebrow" style={{ margin: '0 0 var(--space-3)' }}>
          {eyebrow}
        </p>
      ) : null}

      <div
        style={{
          display: 'flex',
          alignItems: 'flex-end',
          justifyContent: 'space-between',
          gap: 'var(--space-5)',
          flexWrap: 'wrap',
        }}
      >
        <h1 style={{ fontSize: 'var(--display-sm)', margin: 0 }}>{title}</h1>
        {actions ? <div style={{ flex: '0 0 auto' }}>{actions}</div> : null}
      </div>

      <div
        aria-hidden="true"
        style={{
          height: 1,
          marginTop: 'var(--space-4)',
          background: 'var(--border-rule-gold)',
          opacity: 0.55,
        }}
      />

      {subtitle ? (
        <p
          style={{
            margin: 'var(--space-4) 0 0',
            color: 'var(--text-muted)',
            fontSize: 'var(--text-sm)',
            // Body copy measures 60–72 characters in this system.
            maxWidth: 'var(--container-narrow)',
          }}
        >
          {subtitle}
        </p>
      ) : null}
    </header>
  )
}
