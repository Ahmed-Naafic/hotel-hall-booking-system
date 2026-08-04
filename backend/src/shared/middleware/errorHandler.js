import { AppError } from '../errors/AppError.js'
import { logger } from '../../config/logger.js'

/**
 * The single centralized error-handling middleware every route's errors
 * flow into (coding-standards.md §9). Produces the api-standards.md §8
 * error envelope; never leaks a stack trace, Prisma internals, or a file
 * path to the client (architecture-principles.md §13).
 */
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  const isAppError = err instanceof AppError
  const statusCode = isAppError ? err.statusCode : 500
  const errorCode = isAppError ? err.errorCode : 'INTERNAL_SERVER_ERROR'
  const message = isAppError
    ? err.message
    : 'An unexpected error occurred. Please try again later.'

  if (!isAppError || statusCode >= 500) {
    logger.error('Unhandled error', {
      requestId: req.requestId,
      path: req.originalUrl,
      method: req.method,
      error: err.stack || err.message,
    })
  }

  const body = {
    status: 'error',
    error: errorCode,
    message,
    timestamp: new Date().toISOString(),
    requestId: req.requestId,
  }
  if (isAppError && err.details) {
    body.details = err.details
  }

  res.status(statusCode).json(body)
}
