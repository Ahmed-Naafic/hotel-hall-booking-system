import multer from 'multer'
import { ValidationError } from '../errors/errorTypes.js'

/**
 * Shared image upload validation for backend-mediated media APIs.
 * These are the existing Hotel Media technical defaults, promoted unchanged
 * for the second consumer (Hall Media).
 */
export const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024

const ALLOWED_EXTENSIONS_BY_MIME_TYPE = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
}

export const uploadMiddleware = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_SIZE_BYTES },
}).single('file')

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
