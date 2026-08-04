/**
 * The one success envelope every endpoint uses (api-standards.md §7).
 * Callers are responsible for `data` never being `null` on success — an
 * empty collection is `[]`, never an omission.
 */
export function sendSuccess(res, { statusCode = 200, message, data, pagination } = {}) {
  const body = {
    status: 'success',
    message,
    data,
    timestamp: new Date().toISOString(),
  }
  if (pagination) {
    body.pagination = pagination
  }
  res.status(statusCode).json(body)
}

/** 204 No Content — no body, per api-standards.md §9. */
export function sendNoContent(res) {
  res.status(204).end()
}
