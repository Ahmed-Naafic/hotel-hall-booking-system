import { ValidationError } from '../../shared/errors/errorTypes.js'

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export function validateHotelIdParam(req, res, next) {
  if (!UUID_PATTERN.test(req.params.hotelId)) {
    throw new ValidationError('The request could not be processed due to invalid input.', [
      { field: 'hotelId', message: 'hotelId must be a valid identifier.' },
    ])
  }
  next()
}
