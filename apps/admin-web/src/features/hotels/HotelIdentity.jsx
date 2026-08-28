import { getHotelDisplayName, getHotelLocation } from './hotelProfile.js'
import { IconMapPin } from '../../shared/components/Icon.jsx'

/**
 * The "Hotel" identity cell reused by the Hotels table, the Applications
 * table, and Recent Applications — name (or an honest incomplete/unnamed
 * state) plus location when the profile happens to include one. Never the
 * raw UUID as the primary identity (that stays on the Details page).
 */
export function HotelIdentity({ hotel }) {
  const { text, variant } = getHotelDisplayName(hotel)
  const location = getHotelLocation(hotel)
  return (
    <div style={{ minWidth: 0 }}>
      <span
        style={{
          display: 'block',
          color: variant === 'named' ? 'var(--text-body)' : 'var(--text-subtle)',
          fontStyle: variant === 'incomplete' ? 'italic' : 'normal',
          fontWeight: variant === 'named' ? 'var(--weight-medium)' : 'var(--weight-regular)',
        }}
      >
        {text}
      </span>
      {location ? (
        <span
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: 4,
            marginTop: 2,
            fontSize: 'var(--text-xs)',
            color: 'var(--text-muted)',
          }}
        >
          <IconMapPin size={12} />
          {location}
        </span>
      ) : null}
    </div>
  )
}
