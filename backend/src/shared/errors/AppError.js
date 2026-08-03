/**
 * Base typed application error. Per coding-standards.md §9, a service throws
 * a typed error rather than an untyped one; the centralized error-handling
 * middleware (shared/middleware/errorHandler.js) is the only place that
 * turns it into an api-standards.md §8 error response.
 */
export class AppError extends Error {
  constructor({ statusCode, errorCode, message, details }) {
    super(message)
    this.name = this.constructor.name
    this.statusCode = statusCode
    this.errorCode = errorCode
    this.details = details
    this.isOperational = true
    Error.captureStackTrace(this, this.constructor)
  }
}
