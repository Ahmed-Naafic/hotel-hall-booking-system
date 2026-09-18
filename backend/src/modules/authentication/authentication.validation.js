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

const MAX_FULL_NAME_LENGTH = 200

// BDR-018 (Customer) / BDR-019 (Hotel Manager) — shape-checked here, the
// same layer mobileNumber/password already are, since this endpoint (not
// Customer/Hotel Management's own) is where the value is collected for
// either account type.
function assertFullName(value, field = 'fullName') {
  assertString(value, field)
  if (value.trim().length > MAX_FULL_NAME_LENGTH) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field, message: `${field} must be at most ${MAX_FULL_NAME_LENGTH} characters.` },
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

// Shape only — a 6-digit numeric code (verificationCode.js). Whether the
// code is actually correct/unexpired is business validation (service layer).
const VERIFICATION_CODE_PATTERN = /^\d{6}$/

function assertVerificationCode(value, field = 'code') {
  assertString(value, field)
  if (!VERIFICATION_CODE_PATTERN.test(value)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field, message: `${field} must be a 6-digit code.` },
    ])
  }
}

export function validateRegister(req, res, next) {
  const { mobileNumber, password, accountType, fullName } = req.body ?? {}

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
  // BDR-018/BDR-019 — required for both self-registerable account types;
  // each was approved separately, but both need the same shape check here.
  if (accountType === 'CUSTOMER' || accountType === 'HOTEL_MANAGER') {
    assertFullName(fullName)
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

export function validateConfirmVerification(req, res, next) {
  const { code } = req.body ?? {}
  assertVerificationCode(code)
  next()
}

/**
 * Second step of login. Carries the mobile number because there is no token
 * yet to say who is confirming — the first step deliberately issues none.
 */
export function validateCompleteLogin(req, res, next) {
  const { mobileNumber, code } = req.body ?? {}
  assertMobileNumber(mobileNumber)
  assertVerificationCode(code)
  next()
}

export function validateRequestPasswordReset(req, res, next) {
  const { mobileNumber } = req.body ?? {}
  assertMobileNumber(mobileNumber)
  next()
}

export function validateConfirmPasswordReset(req, res, next) {
  const { mobileNumber, code, newPassword } = req.body ?? {}
  assertMobileNumber(mobileNumber)
  assertVerificationCode(code)
  assertPassword(newPassword, 'newPassword')
  next()
}

export function validateChangePassword(req, res, next) {
  const { currentPassword, newPassword } = req.body ?? {}
  assertString(currentPassword, 'currentPassword')
  assertPassword(newPassword, 'newPassword')
  next()
}
