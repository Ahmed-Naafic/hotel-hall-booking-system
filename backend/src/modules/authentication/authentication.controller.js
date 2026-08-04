import * as authenticationService from './authentication.service.js'
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
  const { accessToken, refreshToken, user } = await authenticationService.login(req.body)
  sendSuccess(res, {
    statusCode: 200,
    message: 'Login successful.',
    data: { accessToken, refreshToken, user: toPublicUser(user) },
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
