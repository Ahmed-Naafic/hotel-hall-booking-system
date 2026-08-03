import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import * as authorizationService from '../authorization.service.js'

describe('Authorization (Claim) Component', () => {
  test('resolves the role claim from the User Account accountType (production only, BR-AUTH-14)', () => {
    const user = { id: 'user-1', accountType: 'HOTEL_MANAGER' }
    assert.equal(authorizationService.resolveRoleClaim(user), 'HOTEL_MANAGER')
  })
})
