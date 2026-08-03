import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import * as credentialService from '../credential.service.js'
import { AuthenticationError } from '../../../shared/errors/errorTypes.js'

// Pure crypto — no database, no mocking needed (testing-standards.md §5).

describe('Credential Component', () => {
  test('hashes a password to a value distinct from the plain text', async () => {
    const hash = await credentialService.hashPassword('correct-horse-battery-staple')
    assert.notEqual(hash, 'correct-horse-battery-staple')
    assert.match(hash, /^\$argon2id\$/)
  })

  test('verifies the correct password against its own hash', async () => {
    const hash = await credentialService.hashPassword('correct-horse-battery-staple')
    await assert.doesNotReject(() => credentialService.verifyPassword('correct-horse-battery-staple', hash))
  })

  test('rejects an incorrect password with AuthenticationError', async () => {
    const hash = await credentialService.hashPassword('correct-horse-battery-staple')
    await assert.rejects(
      () => credentialService.verifyPassword('wrong-password', hash),
      AuthenticationError,
    )
  })

  test('two hashes of the same password are not identical (salted)', async () => {
    const hashA = await credentialService.hashPassword('same-password')
    const hashB = await credentialService.hashPassword('same-password')
    assert.notEqual(hashA, hashB)
  })
})
