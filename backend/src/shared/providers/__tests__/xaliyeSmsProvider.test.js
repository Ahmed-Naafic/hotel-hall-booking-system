import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import { XaliyeSmsProvider, toE164 } from '../xaliyeSmsProvider.js'

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

// The shape the live gateway actually returns — the upstream carrier's
// envelope passed straight through.
const LIVE_SUCCESS_BODY = JSON.stringify({
  success: true,
  data: {
    ResponseCode: '200',
    ResponseMessage: 'SUCCESS!.',
    Data: { MessageID: '7deacdd1-c3db-4cb8-b473-cdacdb38a3e1', Description: 'The message is successfully sent!!' },
  },
})

const okResponse = (body = LIVE_SUCCESS_BODY) => ({
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

  test('dials a bare local number, the shape most accounts are registered in', async () => {
    const { impl, calls } = recordingFetch(okResponse())
    const provider = new XaliyeSmsProvider({ baseUrl: 'https://api.example.online', fetchImpl: impl })

    await provider.sendSms({ to: '615008800', body: 'hi' })
    assert.equal(JSON.parse(calls[0].init.body).mobile, '+252615008800')
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
    assert.deepEqual(result, {
      success: true,
      providerMessageId: '7deacdd1-c3db-4cb8-b473-cdacdb38a3e1',
    })
  })

  test('treats a 200 carrying success:false as a failure, not a delivery', async () => {
    const { impl } = recordingFetch({
      ok: true,
      status: 200,
      text: async () => '{"success":false,"data":{"ResponseMessage":"invalid number"}}',
    })
    const provider = new XaliyeSmsProvider({ baseUrl: 'https://api.example.online', fetchImpl: impl })

    await assert.rejects(
      () => provider.sendSms({ to: '+252600000000', body: 'hi' }),
      (error) => {
        assert.equal(error.message, 'SMS delivery failed.')
        return true
      },
    )
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

  describe('toE164', () => {
    test('widens the shapes this platform actually stores', () => {
      // Both are real, registered shapes — the pattern makes "+" optional.
      assert.equal(toE164('615008800'), '+252615008800');
      assert.equal(toE164('+252619490318'), '+252619490318');
    })

    test('accepts the other ways a Somali number gets written', () => {
      assert.equal(toE164('0615008800'), '+252615008800', 'national trunk prefix');
      assert.equal(toE164('252615008800'), '+252615008800', 'country code, no plus');
      assert.equal(toE164('00252615008800'), '+252615008800', 'international prefix as 00');
      assert.equal(toE164(' 61 500-88 00 '), '+252615008800', 'spaces and dashes');
    })

    test('never re-homes a number that already names its own country', () => {
      assert.equal(toE164('+15550001111'), '+15550001111');
      assert.equal(toE164('+441632960000'), '+441632960000');
    })

    test('leaves an empty value alone rather than dialling a country code', () => {
      assert.equal(toE164(''), '');
      assert.equal(toE164(null), '');
      assert.equal(toE164(undefined), '');
    })
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
