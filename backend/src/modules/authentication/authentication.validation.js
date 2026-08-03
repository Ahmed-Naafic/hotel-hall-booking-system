import { ValidationError } from '../../shared/errors/errorTypes.js'

/**
 * Request-shape validation (coding-standards.md §5, §11) — runs before any
 * controller logic. Business-rule validation (e.g. "already registered")
 * belongs in the service layer, not here (api-standards.md §14).
 *
 * Self-registration (this module's `register`) only ever creates a
 * Customer or Hotel account (BR-AUTH-03; Business Specification §3) — Staff
 * and Platform Administrator accounts are created by Staff Management
 * (Module 9) and Administration & Platform Management (Module 13)
 * respectively, never through this endpoint.
 */
const SELF_REGISTERABLE_ACCOUNT_TYPES = ['CUSTOMER', 'HOTEL_MANAGER']

// A deliberately permissive shape check — no approved document defines an
// exact mobile number format (Business Specification only requires that one
// exists, BR-AUTH-02). Digits, with an optional leading `+`.
const MOBILE_NUMBER_PATTERN = /^\+?[1-9]\d{6,14}$/

function assertString(value, field) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field, message: `${field} is required and must be a non-empty string.` },
    ])
  }
}

function assertMobileNumber(value, field = 'mobileNumber') {
  assertString(value, field)
  if (!MOBILE_NUMBER_PATTERN.test(value)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field, message: `${field} must be a valid mobile number.` },
    ])
  }
}

function assertPassword(value, field = 'password') {
  assertString(value, field)
  // Provisional floor only — the actual policy is Business Specification
  // Pending Business Decision #1 (Password Strength Policy), not decided
  // here (Technical Design §17, Item 5).
  if (value.length < 8) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field, message: `${field} must be at least 8 characters.` },
    ])
  }
}

export function validateRegister(req, res, next) {
  const { mobileNumber, password, accountType } = req.body ?? {}

  assertMobileNumber(mobileNumber)
  assertPassword(password)
  assertString(accountType, 'accountType')
  if (!SELF_REGISTERABLE_ACCOUNT_TYPES.includes(accountType)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      {
        field: 'accountType',
        message: `accountType must be one of: ${SELF_REGISTERABLE_ACCOUNT_TYPES.join(', ')}.`,
      },
    ])
  }

  next()
}

export function validateLogin(req, res, next) {
  const { mobileNumber, password } = req.body ?? {}
  assertMobileNumber(mobileNumber)
  assertString(password, 'password')
  next()
}

export function validateRefresh(req, res, next) {
  const { refreshToken } = req.body ?? {}
  assertString(refreshToken, 'refreshToken')
  next()
}
