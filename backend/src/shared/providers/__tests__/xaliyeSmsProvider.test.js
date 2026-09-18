import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import { XaliyeSmsProvider } from '../xaliyeSmsProvider.js'

// The gateway is injected as `fetchImpl`, so these exercise the real request
// shape and the real failure handling without contacting anyone
// (testing-standards.md §6).

function recordingFetch(response) {
  const calls = []
  const impl = async (url, init) => {
    calls.push({ url, init })
    return response
  }
  return { impl, calls }
}

const okResponse = (body = '{"messageId":"abc-123"}') => ({
  ok: true,
  status: 200,
  text: async () => body,
})

describe('XaliyeSmsProvider', () => {
  test('posts mobile/message JSON to the gateway sendSMS endpoint', async () => {
    const { impl, calls } = recordingFetch(okResponse())
    const provider = new XaliyeSmsProvider({ baseUrl: 'https://api.example.online', fetchImpl: impl })

    await provider.sendSms({ to: '+252618833500', body: 'Your code is 123456' })

    assert.equal(calls.length, 1)
    assert.equal(calls[0].url, 'https://api.example.online/sendSMS')
    assert.equal(calls[0].init.method, 'POST')
    assert.equal(calls[0].init.headers['Content-Type'], 'application/json')
    assert.deepEqual(JSON.parse(calls[0].init.body), {
      mobile: '+252618833500',
      message: 'Your code is 123456',
    })
  })

  test('a trailing slash on the configured URL does not double up', async () => {
    const { impl, calls } = recordingFetch(okResponse())
    const provider = new XaliyeSmsProvider({ baseUrl: 'https://api.example.online/', fetchImpl: impl })

    await provider.sendSms({ to: '+252611111111', body: 'hi' })
    assert.equal(calls[0].url, 'https://api.example.online/sendSMS')
  })

  test('sends no Authorization header when no key is configured', async () => {
    const { impl, calls } = recordingFetch(okResponse())
    const provider = new XaliyeSmsProvider({ baseUrl: 'https://api.example.online', fetchImpl: impl })

    await provider.sendSms({ to: '+252611111111', body: 'hi' })
    assert.equal('Authorization' in calls[0].init.headers, false)
  })

  test('sends the key as a bearer token when one is configured', async () => {
    const { impl, calls } = recordingFetch(okResponse())
    const provider = new XaliyeSmsProvider({
      baseUrl: 'https://api.example.online',
      apiKey: 'secret-for-test',
      fetchImpl: impl,
    })

    await provider.sendSms({ to: '+252611111111', body: 'hi' })
    assert.equal(calls[0].init.headers.Authorization, 'Bearer secret-for-test')
  })

  test('reports the gateway message id on success', async () => {
    const { impl } = recordingFetch(okResponse())
    const provider = new XaliyeSmsProvider({ baseUrl: 'https://api.example.online', fetchImpl: impl })

    const result = await provider.sendSms({ to: '+252611111111', body: 'hi' })
    assert.deepEqual(result, { success: true, providerMessageId: 'abc-123' })
  })

  test('succeeds even when the gateway answers with a non-JSON body', async () => {
    const { impl } = recordingFetch({ ok: true, status: 200, text: async () => 'OK' })
    const provider = new XaliyeSmsProvider({ baseUrl: 'https://api.example.online', fetchImpl: impl })

    const result = await provider.sendSms({ to: '+252611111111', body: 'hi' })
    assert.equal(result.success, true)
    assert.equal(result.providerMessageId, null)
  })

  test('a rejected send fails generically, never leaking the gateway response', async () => {
    const { impl } = recordingFetch({
      ok: false,
      status: 402,
      text: async () => '{"error":"insufficient balance on account 12345"}',
    })
    const provider = new XaliyeSmsProvider({ baseUrl: 'https://api.example.online', fetchImpl: impl })

    await assert.rejects(
      () => provider.sendSms({ to: '+252611111111', body: 'hi' }),
      (error) => {
        assert.equal(error.message, 'SMS delivery failed.')
        assert.equal(/balance|12345/.test(error.message), false)
        return true
      },
    )
  })

  test('an unreachable gateway fails generically rather than hanging the caller', async () => {
    const provider = new XaliyeSmsProvider({
      baseUrl: 'https://api.example.online',
      fetchImpl: async () => {
        throw new Error('getaddrinfo ENOTFOUND api.example.online')
      },
    })

    await assert.rejects(
      () => provider.sendSms({ to: '+252611111111', body: 'hi' }),
      (error) => {
        assert.equal(error.message, 'SMS delivery failed.')
        assert.ok(error.cause, 'the real cause is preserved for logging');
        return true
      },
    )
  })
})
