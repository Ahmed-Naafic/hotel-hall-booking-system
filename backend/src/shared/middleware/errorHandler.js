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
  // express.json() (body-parser) throws a plain SyntaxError — not an
  // AppError — for malformed JSON in the request body. That's a client
  // mistake (400), never a server fault (500); without this check it fell
  // through to the generic 500 branch below, misreporting every malformed
  // request as an internal server error.
  const isBodyParseError = !isAppError && (err.type === 'entity.parse.failed' || (err instanceof SyntaxError && err.status === 400))

  const statusCode = isAppError ? err.statusCode : isBodyParseError ? 400 : 500
  const errorCode = isAppError ? err.errorCode : isBodyParseError ? 'VALIDATION_ERROR' : 'INTERNAL_SERVER_ERROR'
  const message = isAppError
    ? err.message
    : isBodyParseError
      ? 'The request could not be processed due to invalid input.'
      : 'An unexpected error occurred. Please try again later.'

  if (statusCode >= 500) {
    // A 5xx we threw on purpose (a dependency being down, say) is not an
    // unhandled fault and has nothing useful in its stack — the throw site
    // is already named by its own log line. Calling it "unhandled" and
    // dumping a trace buries the genuine crashes this line exists for.
    logger.error(isAppError ? 'Dependency unavailable' : 'Unhandled error', {
      requestId: req.requestId,
      path: req.originalUrl,
      method: req.method,
      error: isAppError ? err.message : err.stack || err.message,
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
