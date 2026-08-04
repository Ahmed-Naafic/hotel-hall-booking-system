import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import * as credentialService from '../credential.service.js'

// Pure crypto — no database, no mocking needed (testing-standards.md §5).

describe('Credential Component', () => {
  test('hashes a password to a value distinct from the plain text', async () => {
    const hash = await credentialService.hashPassword('correct-horse-battery-staple')
    assert.notEqual(hash, 'correct-horse-battery-staple')
    assert.match(hash, /^\$argon2id\$/)
  })

  test('verifyPassword returns true for the correct password', async () => {
    const hash = await credentialService.hashPassword('correct-horse-battery-staple')
    assert.equal(await credentialService.verifyPassword('correct-horse-battery-staple', hash), true)
  })

  test('verifyPassword returns false for an incorrect password (caller decides the error, not this component)', async () => {
    const hash = await credentialService.hashPassword('correct-horse-battery-staple')
    assert.equal(await credentialService.verifyPassword('wrong-password', hash), false)
  })

  test('two hashes of the same password are not identical (salted)', async () => {
    const hashA = await credentialService.hashPassword('same-password')
    const hashB = await credentialService.hashPassword('same-password')
    assert.notEqual(hashA, hashB)
  })
})
