import { ValidationError } from '../../shared/errors/errorTypes.js'

export function validateRejectHotelApplication(req, res, next) {
  const { reason } = req.body ?? {}
  if (typeof reason !== 'string' || reason.trim().length === 0) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'reason', message: 'A rejection reason is required.' },
    ])
  }
  if (reason.trim().length > 1000) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'reason', message: 'reason must be 1000 characters or fewer.' },
    ])
  }
  req.body.reason = reason.trim()
  next()
}
