import { useEffect, useState } from 'react'
import { IconClose, IconArrowLeft } from '../../shared/components/Icon.jsx'

/**
 * Full-screen click-to-zoom viewer for a Hotel's Logo/Photos
 * (`HotelDetailPage`'s "Hotel Media" section) — the thumbnails there are
 * otherwise a dead end for a Platform Administrator reviewing an
 * application, with no way to inspect a photo past its small grid tile.
 * Click the backdrop or press Escape to close; click the image itself to
 * toggle between fit-to-screen and full native resolution (scrollable);
 * arrow keys/buttons step through every image in `images` when there is
 * more than one.
 */
export function ImageLightbox({ images, initialIndex = 0, onClose }) {
  const [index, setIndex] = useState(initialIndex)
  const [zoomed, setZoomed] = useState(false)

  useEffect(() => {
    function onKeyDown(event) {
      if (event.key === 'Escape') onClose()
      if (event.key === 'ArrowLeft') setIndex((i) => Math.max(0, i - 1))
      if (event.key === 'ArrowRight') setIndex((i) => Math.min(images.length - 1, i + 1))
    }
    window.addEventListener('keydown', onKeyDown)
    // Lock background scroll while the lightbox is open.
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      window.removeEventListener('keydown', onKeyDown)
      document.body.style.overflow = previousOverflow
    }
  }, [images.length, onClose])

  useEffect(() => setZoomed(false), [index])

  const current = images[index]
  if (!current) return null

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={current.alt}
      onClick={onClose}
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(6, 24, 47, 0.9)',
        zIndex: 1000,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 'var(--space-7)',
      }}
    >
      <button
        onClick={onClose}
        aria-label="Close"
        style={iconButtonStyle('var(--space-5)', 'var(--space-5)')}
      >
        <IconClose size={20} style={{ color: '#fff' }} />
      </button>

      {images.length > 1 && index > 0 ? (
        <button
          onClick={(event) => {
            event.stopPropagation()
            setIndex((i) => i - 1)
          }}
          aria-label="Previous photo"
          style={{ ...iconButtonStyle('50%', undefined, 'var(--space-5)'), transform: 'translateY(-50%)' }}
        >
          <IconArrowLeft size={20} style={{ color: '#fff' }} />
        </button>
      ) : null}
      {images.length > 1 && index < images.length - 1 ? (
        <button
          onClick={(event) => {
            event.stopPropagation()
            setIndex((i) => i + 1)
          }}
          aria-label="Next photo"
          style={{
            ...iconButtonStyle('50%', 'var(--space-5)', undefined),
            transform: 'translateY(-50%) scaleX(-1)',
          }}
        >
          <IconArrowLeft size={20} style={{ color: '#fff' }} />
        </button>
      ) : null}

      <div
        onClick={(event) => event.stopPropagation()}
        style={{
          maxWidth: '100%',
          maxHeight: '100%',
          overflow: zoomed ? 'auto' : 'hidden',
          display: 'flex',
          alignItems: zoomed ? 'flex-start' : 'center',
          justifyContent: zoomed ? 'flex-start' : 'center',
        }}
      >
        <img
          src={current.url}
          alt={current.alt}
          onClick={() => setZoomed((z) => !z)}
          style={{
            maxWidth: zoomed ? 'none' : '90vw',
            maxHeight: zoomed ? 'none' : '90vh',
            display: 'block',
            objectFit: 'contain',
            borderRadius: 'var(--radius-md)',
            cursor: zoomed ? 'zoom-out' : 'zoom-in',
          }}
        />
      </div>

      {images.length > 1 ? (
        <div
          style={{
            position: 'absolute',
            bottom: 'var(--space-5)',
            left: '50%',
            transform: 'translateX(-50%)',
            color: '#fff',
            fontSize: 'var(--text-sm)',
            background: 'rgba(255, 255, 255, 0.12)',
            padding: 'var(--space-1) var(--space-4)',
            borderRadius: 'var(--radius-full, 999px)',
          }}
        >
          {index + 1} / {images.length}
        </div>
      ) : null}
    </div>
  )
}

function iconButtonStyle(top, right, left) {
  return {
    position: 'absolute',
    top,
    right,
    left,
    background: 'rgba(255, 255, 255, 0.12)',
    border: 'none',
    borderRadius: '50%',
    width: 40,
    height: 40,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    cursor: 'pointer',
  }
}
