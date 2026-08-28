import './skeleton.css'

/** A single placeholder bar. Width/height are plain CSS values (e.g. '60%', 14). */
export function Skeleton({ width = '100%', height = 14, style }) {
  return (
    <span
      className="hh-skeleton"
      aria-hidden="true"
      style={{ width, height, ...style }}
    />
  )
}

/** A row of skeleton cells matching a table's column count. */
export function SkeletonTableRow({ columns }) {
  return (
    <tr style={{ borderBottom: '1px solid var(--border-subtle)' }}>
      {Array.from({ length: columns }).map((_, index) => (
        <td key={index} style={{ padding: 'var(--space-2) var(--space-3)' }}>
          <Skeleton height={12} width={index === columns - 1 ? '40%' : '75%'} />
        </td>
      ))}
    </tr>
  )
}
