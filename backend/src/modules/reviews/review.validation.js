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

export function validateListReviews(req, res, next) {
  const details = []
  if (req.query.cursor !== undefined && !UUID_PATTERN.test(req.query.cursor)) {
    details.push({ field: 'cursor', message: 'cursor must be a valid identifier.' })
  }
  if (req.query.limit !== undefined && (!Number.isInteger(Number(req.query.limit)) || Number(req.query.limit) < 1)) {
    details.push({ field: 'limit', message: 'limit must be a positive integer.' })
  }
  if (details.length) {
    throw new ValidationError('The request could not be processed due to invalid input.', details)
  }
  next()
}

export function validateSubmitReview(req, res, next) {
  const body = req.body ?? {}
  const details = []
  if (!Number.isInteger(body.rating) || body.rating < 1 || body.rating > 5) {
    details.push({ field: 'rating', message: 'rating must be an integer from 1 to 5.' })
  }
  if (body.text !== undefined && typeof body.text !== 'string') {
    details.push({ field: 'text', message: 'text must be a string.' })
  }
  if (details.length) {
    throw new ValidationError('The request could not be processed due to invalid input.', details)
  }
  next()
}
