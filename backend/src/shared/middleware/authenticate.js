import * as tokenService from '../../modules/authentication/token.service.js'
import { AuthenticationError } from '../errors/errorTypes.js'

/**
 * Access Gate (Technical Design §4, §8) — the shared middleware every
 * protected endpoint, in every module, sits behind. Validates the access
 * token via the Authentication module's Token Component before a request
 * reaches any module's business logic (architecture-principles.md §7,
 * "Authentication before authorization, structurally"). On success,
 * attaches `req.identity = { userId, accountType }` — the authenticated
 * identity and role claim this module produces (BR-AUTH-14); it does not
 * itself decide what that identity is permitted to do.
 */
export function authenticate(req, res, next) {
  const header = req.headers.authorization

  if (!header || !header.startsWith('Bearer ')) {
    throw new AuthenticationError('Authentication required.')
  }

  const token = header.slice('Bearer '.length)
  const payload = tokenService.verifyAccessToken(token)

  req.identity = { userId: payload.sub, accountType: payload.accountType, sessionId: payload.sid }
  next()
}

/**
 * Optional variant of the Access Gate, for endpoints that are public but
 * behave differently when a valid identity is presented (Hall Management
 * Technical Design §11/§12, `BDR-009`) — the first such endpoints in the
 * project; every other module's endpoints are either fully public or fully
 * required-auth. Never rejects a request: an absent, malformed, or
 * expired token is treated identically to an anonymous caller, since these
 * endpoints never require a token in the first place. `req.identity` is
 * set only when a token is present and valid.
 */
export function optionalAuthenticate(req, res, next) {
  const header = req.headers.authorization

  if (!header || !header.startsWith('Bearer ')) {
    return next()
  }

  try {
    const payload = tokenService.verifyAccessToken(header.slice('Bearer '.length))
    req.identity = { userId: payload.sub, accountType: payload.accountType, sessionId: payload.sid }
  } catch {
    // Invalid/expired token on a public endpoint — fall back to the
    // anonymous view rather than rejecting the request.
  }

  next()
}
