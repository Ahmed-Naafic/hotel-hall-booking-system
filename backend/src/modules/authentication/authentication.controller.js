import * as authenticationService from './authentication.service.js'
import * as verificationService from './verification.service.js'
import * as passwordResetService from './passwordReset.service.js'
import { toPublicUser } from './authentication.mapper.js'
import { sendSuccess, sendNoContent } from '../../shared/utils/responseEnvelope.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'

/**
 * Controller layer (coding-standards.md §5) — reads the request, calls the
 * service, shapes the response. No business logic and no direct Prisma
 * access here.
 */

export const register = asyncHandler(async (req, res) => {
  const user = await authenticationService.register(req.body)
  sendSuccess(res, {
    statusCode: 201,
    message: 'Registration accepted. Verification is required before booking.',
    data: toPublicUser(user),
  })
})

export const login = asyncHandler(async (req, res) => {
  const result = await authenticationService.login(req.body)

  // Two shapes, told apart by `verificationRequired` rather than by which
  // fields happen to be present: an account that owes a code gets no token
  // here at all, and must come back through `POST /auth/login/verify`.
  if (result.verificationRequired) {
    sendSuccess(res, {
      statusCode: 200,
      message: 'Verification code sent. Enter it to finish signing in.',
      data: { verificationRequired: true },
    })
    return
  }

  sendSuccess(res, {
    statusCode: 200,
    message: 'Login successful.',
    data: {
      verificationRequired: false,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      user: toPublicUser(result.user),
    },
  })
})

export const completeLogin = asyncHandler(async (req, res) => {
  const { accessToken, refreshToken, user } = await authenticationService.completeLogin(req.body)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Login successful.',
    data: { verificationRequired: false, accessToken, refreshToken, user: toPublicUser(user) },
  })
})

export const logout = asyncHandler(async (req, res) => {
  await authenticationService.logout(req.identity.sessionId)
  sendNoContent(res)
})

export const refresh = asyncHandler(async (req, res) => {
  const { accessToken, refreshToken } = await authenticationService.refresh(req.body.refreshToken)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Token refreshed successfully.',
    data: { accessToken, refreshToken },
  })
})

export const getCurrentUser = asyncHandler(async (req, res) => {
  const user = await authenticationService.getCurrentUser(req.identity.userId)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Current account retrieved successfully.',
    data: toPublicUser(user),
  })
})

export const requestVerification = asyncHandler(async (req, res) => {
  await verificationService.requestVerification(req.identity.userId)
  sendSuccess(res, { statusCode: 200, message: 'Verification code sent.', data: {} })
})

export const confirmVerification = asyncHandler(async (req, res) => {
  const user = await verificationService.confirmVerification(req.identity.userId, req.body.code)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Account verified successfully.',
    data: toPublicUser(user),
  })
})

export const requestPasswordReset = asyncHandler(async (req, res) => {
  await passwordResetService.requestPasswordReset(req.body.mobileNumber)
  // BR-AUTH-09: identical response whether or not the account exists.
  sendSuccess(res, {
    statusCode: 200,
    message: 'If this account exists, password reset instructions were sent.',
    data: {},
  })
})

export const confirmPasswordReset = asyncHandler(async (req, res) => {
  const { mobileNumber, code, newPassword } = req.body
  await passwordResetService.confirmPasswordReset(mobileNumber, code, newPassword)
  sendSuccess(res, { statusCode: 200, message: 'Password reset successfully.', data: {} })
})

export const changePassword = asyncHandler(async (req, res) => {
  await authenticationService.changePassword(req.identity.userId, req.body)
  sendSuccess(res, { statusCode: 200, message: 'Password changed successfully.', data: {} })
})
