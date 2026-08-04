import { Router } from 'express'
import * as authenticationController from './authentication.controller.js'
import * as authenticationValidation from './authentication.validation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'

/**
 * Route definitions only (coding-standards.md §5) — maps method + path to a
 * controller function. Mounted at /api/v1/auth by the app entry point.
 * Endpoints per Technical Design §10 (password-resets confirm corrected in
 * v1.5 — see passwordReset.service.js's confirmPasswordReset() docstring).
 */
export const authenticationRouter = Router()

authenticationRouter.post(
  '/register',
  authenticationValidation.validateRegister,
  authenticationController.register,
)

authenticationRouter.post(
  '/login',
  authenticationValidation.validateLogin,
  authenticationController.login,
)

authenticationRouter.post('/logout', authenticate, authenticationController.logout)

authenticationRouter.post(
  '/refresh',
  authenticationValidation.validateRefresh,
  authenticationController.refresh,
)

authenticationRouter.get('/me', authenticate, authenticationController.getCurrentUser)

authenticationRouter.post(
  '/verifications',
  authenticate,
  authenticationController.requestVerification,
)

authenticationRouter.post(
  '/verifications/confirm',
  authenticate,
  authenticationValidation.validateConfirmVerification,
  authenticationController.confirmVerification,
)

authenticationRouter.post(
  '/password-resets',
  authenticationValidation.validateRequestPasswordReset,
  authenticationController.requestPasswordReset,
)

// No :id — see passwordReset.service.js's confirmPasswordReset() docstring
// for why (an id in the POST response above would violate BR-AUTH-09).
authenticationRouter.patch(
  '/password-resets',
  authenticationValidation.validateConfirmPasswordReset,
  authenticationController.confirmPasswordReset,
)

authenticationRouter.patch(
  '/password',
  authenticate,
  authenticationValidation.validateChangePassword,
  authenticationController.changePassword,
)
