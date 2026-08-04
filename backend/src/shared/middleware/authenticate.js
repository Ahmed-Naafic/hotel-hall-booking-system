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
