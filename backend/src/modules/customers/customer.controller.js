import * as customerService from './customer.service.js'
import { toCustomerIdentity, toCustomerProfile } from './customer.mapper.js'
import { getReadiness } from './customerProfilePolicy.js'
import { sendSuccess } from '../../shared/utils/responseEnvelope.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'

export const getMe = asyncHandler(async (req, res) => {
  const result = await customerService.getCurrentCustomer(req.identity.userId)
  sendSuccess(res, {
    message: 'Customer retrieved successfully.',
    data: { user: toCustomerIdentity(result.user), profile: toCustomerProfile(result.profile), readiness: result.readiness },
  })
})

export const createProfile = asyncHandler(async (req, res) => {
  const profile = await customerService.createProfile(req.identity.userId, req.customerProfileData)
  sendSuccess(res, {
    statusCode: 201,
    message: 'Customer profile created successfully.',
    data: { profile: toCustomerProfile(profile), readiness: getReadiness(profile) },
  })
})

export const updateProfile = asyncHandler(async (req, res) => {
  const profile = await customerService.updateProfile(req.identity.userId, req.customerProfileData)
  sendSuccess(res, {
    message: 'Customer profile updated successfully.',
    data: { profile: toCustomerProfile(profile), readiness: getReadiness(profile) },
  })
})
