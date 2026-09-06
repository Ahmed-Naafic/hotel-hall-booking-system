import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

void main() {
  group('ApiClient', () {
    test('GET returns the envelope\'s data field on success', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/auth/me');
        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'ok',
            'data': {'id': '1'},
          }),
          200,
        );
      });
      final client = ApiClient(httpClient: mock, baseUrl: 'http://test/api/v1');

      final data = await client.get('/auth/me');
      expect(data, {'id': '1'});
    });

    test('POST sends a JSON body and returns data', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {
          'mobileNumber': '+15551234567',
          'password': 'password123',
        });
        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'ok',
            'data': {'accessToken': 'a', 'refreshToken': 'b'},
          }),
          200,
        );
      });
      final client = ApiClient(httpClient: mock, baseUrl: 'http://test/api/v1');

      final data = await client.post(
        '/auth/login',
        body: {'mobileNumber': '+15551234567', 'password': 'password123'},
      );
      expect(data['accessToken'], 'a');
    });

    test(
      'attaches the Authorization header when a token is available',
      () async {
        final mock = MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer abc123');
          return http.Response(
            jsonEncode({'status': 'success', 'message': 'ok', 'data': {}}),
            200,
          );
        });
        final client = ApiClient(
          httpClient: mock,
          baseUrl: 'http://test/api/v1',
          accessTokenProvider: () async => 'abc123',
        );

        await client.get('/auth/me');
      },
    );

    test('sends no Authorization header when no token is available', () async {
      final mock = MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), false);
        return http.Response(
          jsonEncode({'status': 'success', 'message': 'ok', 'data': {}}),
          200,
        );
      });
      final client = ApiClient(
        httpClient: mock,
        baseUrl: 'http://test/api/v1',
        accessTokenProvider: () async => null,
      );

      await client.get('/auth/me');
    });

    test('a 204 response returns null', () async {
      final mock = MockClient((request) async => http.Response('', 204));
      final client = ApiClient(httpClient: mock, baseUrl: 'http://test/api/v1');

      final data = await client.post('/auth/logout');
      expect(data, isNull);
    });

    test(
      'a non-2xx response throws ApiException with the server\'s own message',
      () async {
        final mock = MockClient(
          (request) async => http.Response(
            jsonEncode({
              'status': 'error',
              'error': 'AUTHENTICATION_ERROR',
              'message': 'Invalid credentials.',
              'timestamp': '2026-08-25T00:00:00.000Z',
              'requestId': 'r1',
            }),
            401,
          ),
        );
        final client = ApiClient(
          httpClient: mock,
          baseUrl: 'http://test/api/v1',
        );

        await expectLater(
          client.post('/auth/login', body: {}),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 401)
                .having((e) => e.message, 'message', 'Invalid credentials.')
                .having((e) => e.isUnauthorized, 'isUnauthorized', true),
          ),
        );
      },
    );

    test(
      'refreshes once on 401, persists rotated tokens, and retries the original request',
      () async {
        final tokens = {'access': 'expired', 'refresh': 'refresh-a'};
        final calls = <String>[];
        final mock = MockClient((request) async {
          calls.add(
            '${request.method} ${request.url.path} ${request.headers['Authorization'] ?? ''}',
          );
          if (request.url.path.endsWith('/auth/me') &&
              request.headers['Authorization'] == 'Bearer expired') {
            return http.Response(
              jsonEncode({
                'status': 'error',
                'error': 'AUTHENTICATION_ERROR',
                'message': 'Invalid or expired session.',
              }),
              401,
            );
          }
          if (request.url.path.endsWith('/auth/refresh')) {
            expect(jsonDecode(request.body), {'refreshToken': 'refresh-a'});
            return http.Response(
              jsonEncode({
                'status': 'success',
                'message': 'ok',
                'data': {'accessToken': 'fresh', 'refreshToken': 'refresh-b'},
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/auth/me') &&
              request.headers['Authorization'] == 'Bearer fresh') {
            return http.Response(
              jsonEncode({
                'status': 'success',
                'message': 'ok',
                'data': {'id': 'u1'},
              }),
              200,
            );
          }
          throw StateError('unexpected call: ${request.url.path}');
        });
        final client = ApiClient(
          httpClient: mock,
          baseUrl: 'http://test/api/v1',
          accessTokenProvider: () async => tokens['access'],
          refreshTokenProvider: () async => tokens['refresh'],
          tokenPairSaver:
              ({required accessToken, required refreshToken}) async {
                tokens['access'] = accessToken;
                tokens['refresh'] = refreshToken;
              },
        );

        final data = await client.get('/auth/me');

        expect(data, {'id': 'u1'});
        expect(tokens['access'], 'fresh');
        expect(tokens['refresh'], 'refresh-b');
        expect(
          calls.where((call) => call.contains('/auth/refresh')),
          hasLength(1),
        );
      },
    );

    test(
      'does not retry forever when the retried request also returns 401',
      () async {
        final tokens = {'access': 'expired'};
        var attempts = 0;
        final mock = MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            return http.Response(
              jsonEncode({
                'status': 'success',
                'message': 'ok',
                'data': {'accessToken': 'fresh', 'refreshToken': 'refresh-b'},
              }),
              200,
            );
          }
          attempts += 1;
          return http.Response(
            jsonEncode({
              'status': 'error',
              'error': 'AUTHENTICATION_ERROR',
              'message': 'Still expired.',
            }),
            401,
          );
        });
        final client = ApiClient(
          httpClient: mock,
          baseUrl: 'http://test/api/v1',
          accessTokenProvider: () async => tokens['access'],
          refreshTokenProvider: () async => 'refresh-a',
          tokenPairSaver:
              ({required accessToken, required refreshToken}) async {
                tokens['access'] = accessToken;
              },
        );

        await expectLater(
          client.get('/auth/me'),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
        expect(attempts, 2);
      },
    );

    test('clears the session when refresh fails', () async {
      var cleared = false;
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return http.Response(
            jsonEncode({
              'status': 'error',
              'error': 'AUTHENTICATION_ERROR',
              'message': 'Invalid or expired session.',
            }),
            401,
          );
        }
        return http.Response(
          jsonEncode({
            'status': 'error',
            'error': 'AUTHENTICATION_ERROR',
            'message': 'Invalid or expired session.',
          }),
          401,
        );
      });
      final client = ApiClient(
        httpClient: mock,
        baseUrl: 'http://test/api/v1',
        accessTokenProvider: () async => 'expired',
        refreshTokenProvider: () async => 'refresh-a',
        sessionExpiredHandler: () async {
          cleared = true;
        },
      );

      await expectLater(client.get('/auth/me'), throwsA(isA<ApiException>()));
      expect(cleared, true);
    });

    test(
      'shares one in-flight refresh across concurrent 401 responses',
      () async {
        final tokens = {'access': 'expired'};
        var refreshCalls = 0;
        final releaseRefresh = Completer<void>();
        final mock = MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            refreshCalls += 1;
            await releaseRefresh.future;
            return http.Response(
              jsonEncode({
                'status': 'success',
                'message': 'ok',
                'data': {'accessToken': 'fresh', 'refreshToken': 'refresh-b'},
              }),
              200,
            );
          }
          if (request.headers['Authorization'] == 'Bearer expired') {
            return http.Response(
              jsonEncode({
                'status': 'error',
                'error': 'AUTHENTICATION_ERROR',
                'message': 'Invalid or expired session.',
              }),
              401,
            );
          }
          return http.Response(
            jsonEncode({
              'status': 'success',
              'message': 'ok',
              'data': {'id': request.url.path},
            }),
            200,
          );
        });
        final client = ApiClient(
          httpClient: mock,
          baseUrl: 'http://test/api/v1',
          accessTokenProvider: () async => tokens['access'],
          refreshTokenProvider: () async => 'refresh-a',
          tokenPairSaver:
              ({required accessToken, required refreshToken}) async {
                tokens['access'] = accessToken;
              },
        );

        final first = client.get('/auth/me');
        final second = client.get('/hotels/me');
        await Future<void>.delayed(Duration.zero);
        releaseRefresh.complete();

        await Future.wait([first, second]);
        expect(refreshCalls, 1);
      },
    );

    test('a validation error carries field-level details', () async {
      final mock = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'status': 'error',
            'error': 'VALIDATION_ERROR',
            'message':
                'The request could not be processed due to invalid input.',
            'details': [
              {
                'field': 'mobileNumber',
                'message': 'mobileNumber must be a valid mobile number.',
              },
            ],
          }),
          400,
        ),
      );
      final client = ApiClient(httpClient: mock, baseUrl: 'http://test/api/v1');

      try {
        await client.post('/auth/register', body: {});
        fail('expected ApiException');
      } on ApiException catch (e) {
        expect(e.isValidation, true);
        expect(e.details, hasLength(1));
        expect(e.details.first.field, 'mobileNumber');
      }
    });

    test(
      'getPaginated exposes the pagination field as a sibling of data, not nested inside it',
      () async {
        final mock = MockClient(
          (request) async => http.Response(
            jsonEncode({
              'status': 'success',
              'message': 'ok',
              'data': [
                {'id': 'h1'},
              ],
              'pagination': {
                'page': 1,
                'limit': 20,
                'total': 1,
                'hasNext': false,
                'hasPrevious': false,
              },
            }),
            200,
          ),
        );
        final client = ApiClient(
          httpClient: mock,
          baseUrl: 'http://test/api/v1',
        );

        final result = await client.getPaginated('/hotels/h1/halls');

        expect(result.data, [
          {'id': 'h1'},
        ]);
        expect(result.pagination, {
          'page': 1,
          'limit': 20,
          'total': 1,
          'hasNext': false,
          'hasPrevious': false,
        });
      },
    );

    test(
      'get() alone discards pagination and returns only data, for endpoints that never paginate',
      () async {
        final mock = MockClient(
          (request) async => http.Response(
            jsonEncode({
              'status': 'success',
              'message': 'ok',
              'data': {'id': 'u1'},
            }),
            200,
          ),
        );
        final client = ApiClient(
          httpClient: mock,
          baseUrl: 'http://test/api/v1',
        );

        final data = await client.get('/auth/me');
        expect(data, {'id': 'u1'});
      },
    );

    test('a connection failure throws NetworkException', () async {
      final mock = MockClient((request) async {
        throw const SocketException('Connection refused');
      });
      final client = ApiClient(httpClient: mock, baseUrl: 'http://test/api/v1');

      await expectLater(
        client.get('/auth/me'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('DELETE sends the request and a 204 response returns null', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/hotels/h1/media/m1');
        return http.Response('', 204);
      });
      final client = ApiClient(httpClient: mock, baseUrl: 'http://test/api/v1');

      final data = await client.delete('/hotels/h1/media/m1');
      expect(data, isNull);
    });

    test('PUT sends a JSON body and returns data', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/favorites/hotels/h1');
        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'ok',
            'data': {'hotelId': 'h1', 'saved': true},
          }),
          200,
        );
      });
      final client = ApiClient(httpClient: mock, baseUrl: 'http://test/api/v1');

      final data = await client.put('/favorites/hotels/h1');
      expect(data, {'hotelId': 'h1', 'saved': true});
    });

    test(
      'postMultipart sends the file as multipart/form-data with the Authorization header',
      () async {
        final mock = MockClient.streaming((request, bodyStream) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/hotels/h1/media/logo');
          expect(request.headers['Authorization'], 'Bearer abc123');
          expect(
            request.headers['content-type'],
            contains('multipart/form-data'),
          );

          final multipart = request as http.MultipartRequest;
          expect(multipart.files, hasLength(1));
          expect(multipart.files.first.field, 'file');
          expect(multipart.files.first.filename, 'logo.jpg');

          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'status': 'success',
                  'message': 'ok',
                  'data': {'id': 'm1', 'type': 'LOGO'},
                }),
              ),
            ),
            201,
          );
        });
        final client = ApiClient(
          httpClient: mock,
          baseUrl: 'http://test/api/v1',
          accessTokenProvider: () async => 'abc123',
        );

        final data = await client.postMultipart(
          '/hotels/h1/media/logo',
          bytes: [0xff, 0xd8, 0xff],
          filename: 'logo.jpg',
        );

        expect(data, {'id': 'm1', 'type': 'LOGO'});
      },
    );

    test(
      'postMultipart surfaces a non-2xx response as ApiException with the server\'s own message',
      () async {
        final mock = MockClient.streaming((request, bodyStream) async {
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'status': 'error',
                  'error': 'VALIDATION_ERROR',
                  'message':
                      'Unsupported file type. Allowed formats: JPEG, PNG, WebP.',
                }),
              ),
            ),
            400,
          );
        });
        final client = ApiClient(
          httpClient: mock,
          baseUrl: 'http://test/api/v1',
        );

        await expectLater(
          client.postMultipart(
            '/hotels/h1/media/logo',
            bytes: [1, 2, 3],
            filename: 'bad.txt',
          ),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Unsupported file type. Allowed formats: JPEG, PNG, WebP.',
            ),
          ),
        );
      },
    );
  });
}
