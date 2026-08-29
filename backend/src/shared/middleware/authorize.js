import { AuthorizationError } from '../errors/errorTypes.js'

export function requireAccountType(...allowedTypes) {
  return (req, res, next) => {
    if (!allowedTypes.includes(req.identity?.accountType)) {
      throw new AuthorizationError('You are not authorized to perform this action.')
    }
    next()
  }
}
