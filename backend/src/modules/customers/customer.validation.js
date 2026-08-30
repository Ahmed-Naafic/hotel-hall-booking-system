import { validateAndMapProfileData } from './customerProfilePolicy.js'
import { ValidationError } from '../../shared/errors/errorTypes.js'

export function validateProfile(req, res, next) {
  const body = req.body ?? {}
  const allowedBodyKeys = ['profileData']
  const extraKeys = Object.keys(body).filter((key) => !allowedBodyKeys.includes(key))
  if (extraKeys.length > 0) {
    throw new ValidationError('The request could not be processed due to invalid input.',
      extraKeys.map((field) => ({ field, message: 'This field is not allowed.' })))
  }
  if (!Object.hasOwn(body, 'profileData')) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'profileData', message: 'profileData is required.' },
    ])
  }
  req.customerProfileData = validateAndMapProfileData(body.profileData)
  next()
}
