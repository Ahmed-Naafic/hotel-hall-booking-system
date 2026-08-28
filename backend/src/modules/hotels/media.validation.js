import multer from 'multer'
import { ValidationError } from '../../shared/errors/errorTypes.js'

/**
 * Request-shape validation for Hotel Media uploads (coding-standards.md
 * §5, §11; api-standards.md §15) — runs before any controller logic.
 * Business-rule validation (ownership, at-most-one-Logo) belongs in the
 * service layer (api-standards.md §14).
 */

/**
 * Technical default, not a settled business decision — flagged for review
 * (Technical Design §8a). Nothing in the Business Specification or any
 * approved BDR sets this number.
 */
export const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024

const ALLOWED_EXTENSIONS_BY_MIME_TYPE = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
}

/** Parses a single `multipart/form-data` file field into memory (never disk). */
export const uploadMiddleware = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_SIZE_BYTES },
}).single('file')

/**
 * Detects the real content type from the file's own magic bytes
 * (`api-standards.md` §15) — never trusts the client-supplied filename
 * extension or `Content-Type` header. Returns the detected MIME type, or
 * `null` if it doesn't match one of the allowed image formats.
 */
export function detectImageMimeType(buffer) {
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return 'image/jpeg'
  }
  if (
    buffer.length >= 8 &&
    buffer[0] === 0x89 &&
    buffer[1] === 0x50 &&
    buffer[2] === 0x4e &&
    buffer[3] === 0x47 &&
    buffer[4] === 0x0d &&
    buffer[5] === 0x0a &&
    buffer[6] === 0x1a &&
    buffer[7] === 0x0a
  ) {
    return 'image/png'
  }
  if (buffer.length >= 12 && buffer.toString('ascii', 0, 4) === 'RIFF' && buffer.toString('ascii', 8, 12) === 'WEBP') {
    return 'image/webp'
  }
  return null
}

export function extensionForMimeType(mimeType) {
  return ALLOWED_EXTENSIONS_BY_MIME_TYPE[mimeType]
}

/** Runs after `uploadMiddleware` has parsed the multipart body. */
export function validateUploadedFile(req, res, next) {
  if (!req.file) {
    throw new ValidationError('A file is required.', [{ field: 'file', message: 'A file is required.' }])
  }

  const mimeType = detectImageMimeType(req.file.buffer)
  if (!mimeType) {
    throw new ValidationError('Unsupported file type. Allowed formats: JPEG, PNG, WebP.', [
      { field: 'file', message: 'Unsupported file type. Allowed formats: JPEG, PNG, WebP.' },
    ])
  }

  req.detectedMimeType = mimeType
  next()
}

/**
 * Translates multer's own oversized-file rejection (thrown by
 * `uploadMiddleware` itself, before `validateUploadedFile` ever runs) into
 * this project's standard `400` error envelope (`api-standards.md` §8)
 * instead of multer's default error shape. Express routes a `next(err)`
 * call to the nearest 4-parameter middleware, so this must be registered
 * immediately after `uploadMiddleware` in each route (`media.routes.js`).
 */
export function handleUploadError(err, req, res, next) {
  if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
    return next(
      new ValidationError(`File exceeds the maximum size of ${MAX_FILE_SIZE_BYTES / (1024 * 1024)} MB.`, [
        { field: 'file', message: 'File exceeds the maximum allowed size.' },
      ]),
    )
  }
  next(err)
}
