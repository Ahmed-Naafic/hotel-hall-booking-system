import { NotFoundError } from '../errors/errorTypes.js'

/** Catches any request that matched no route, per api-standards.md §9 (404). */
export function notFoundHandler(req, res, next) {
  next(new NotFoundError(`No route matches ${req.method} ${req.originalUrl}.`))
}
