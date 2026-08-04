import { AppError } from './AppError.js'

/**
 * One class per api-standards.md §9 status code this module (and, over
 * time, every module) actually uses. Error codes are stable and
 * machine-readable (UPPER_SNAKE_CASE, api-standards.md §8) — a client
 * branches on `error`, never on parsing `message`.
 */

/** 400 — request fails request validation (shape, type, missing field). */
export class ValidationError extends AppError {
  constructor(message = 'The request could not be processed due to invalid input.', details) {
    super({ statusCode: 400, errorCode: 'VALIDATION_ERROR', message, details })
  }
}

/** 401 — missing, invalid, or expired credential (api-standards.md §12). */
export class AuthenticationError extends AppError {
  constructor(message = 'Authentication failed.') {
    super({ statusCode: 401, errorCode: 'AUTHENTICATION_ERROR', message })
  }
}

/** 403 — authenticated, but not authorized for this action (api-standards.md §13). */
export class AuthorizationError extends AppError {
  constructor(message = 'You are not authorized to perform this action.') {
    super({ statusCode: 403, errorCode: 'AUTHORIZATION_ERROR', message })
  }
}

/** 404 — resource does not exist (or belongs to a different tenant, api-standards.md §9). */
export class NotFoundError extends AppError {
  constructor(message = 'The requested resource was not found.') {
    super({ statusCode: 404, errorCode: 'NOT_FOUND', message })
  }
}

/** 409 — conflicts with current state. */
export class ConflictError extends AppError {
  constructor(message = 'The request conflicts with the current state of the resource.') {
    super({ statusCode: 409, errorCode: 'CONFLICT', message })
  }
}

/** 422 — well-formed request, business rule not satisfied (api-standards.md §9). */
export class BusinessRuleError extends AppError {
  constructor(message = 'The request violates a business rule.', details) {
    super({ statusCode: 422, errorCode: 'BUSINESS_RULE_VIOLATION', message, details })
  }
}

/** 429 — rate limited (api-standards.md §19). */
export class TooManyRequestsError extends AppError {
  constructor(message = 'Too many requests. Please try again later.') {
    super({ statusCode: 429, errorCode: 'TOO_MANY_REQUESTS', message })
  }
}
