/**
 * Wraps an async controller so a rejected Promise reaches the centralized
 * error-handling middleware via next(error), per coding-standards.md §9 —
 * no controller needs its own try/catch to forward an error.
 */
export function asyncHandler(fn) {
  return function wrapped(req, res, next) {
    Promise.resolve(fn(req, res, next)).catch(next)
  }
}
