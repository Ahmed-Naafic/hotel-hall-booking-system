import { Router } from 'express'
import * as authenticationController from './authentication.controller.js'
import * as authenticationValidation from './authentication.validation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'

/**
 * Route definitions only (coding-standards.md §5) — maps method + path to a
 * controller function. Mounted at /api/v1/auth by the app entry point.
 * Endpoints per Technical Design §10; WBS-10 (verifications) and WBS-11a/b
 * (password change/reset) remain a later increment (Milestone M3).
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
