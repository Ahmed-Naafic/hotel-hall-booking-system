import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/hotel/application/hotel_media_controller.dart';
import 'package:manager_mobile/features/hotel/application/image_picker_service.dart';
import 'package:manager_mobile/features/hotel/data/hotel_models.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';

import '../../test_support.dart';

Map<String, dynamic> _mediaJson({String id = 'm1', String type = 'LOGO'}) => {
      'id': id,
      'hotelId': 'h1',
      'type': type,
      'url': 'https://mock-storage.local/hotel-media/hotels/h1/logo/$id.jpg',
      'createdAt': '2026-08-26T00:00:00.000Z',
      'updatedAt': '2026-08-26T00:00:00.000Z',
    };

Future<PickedImageData?> _fakePicker() async => const PickedImageData(bytes: [0xff, 0xd8, 0xff], filename: 'logo.jpg');

HotelMediaController _controller({
  required Future<http.Response> Function(http.Request) handler,
  ImagePickerFn pickImage = _fakePicker,
}) {
  final client = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  return HotelMediaController(repository: HotelRepository(client), hotelId: 'h1', pickImage: pickImage);
}

void main() {
  group('HotelMediaController.load', () {
    test('populates logo and photos from GET /hotels/:hotelId/media', () async {
      final controller = _controller(
        handler: (r) async {
          expect(r.method, 'GET');
          expect(r.url.path, '/api/v1/hotels/h1/media');
          return successResponse({
            'logo': _mediaJson(id: 'logo1'),
            'photos': [_mediaJson(id: 'p1', type: 'PHOTO'), _mediaJson(id: 'p2', type: 'PHOTO')],
          });
        },
      );

      await controller.load();

      expect(controller.logo?.id, 'logo1');
      expect(controller.photos, hasLength(2));
      expect(controller.isLoading, false);
    });

    test('an API error surfaces the server message', () async {
      final controller = _controller(
        handler: (r) async => errorResponse('NOT_FOUND', 'Hotel not found.', 404),
      );

      await controller.load();

      expect(controller.errorMessage, 'Hotel not found.');
    });
  });

  group('HotelMediaController.uploadLogo', () {
    test('uploads via multipart POST and sets the logo', () async {
      Map<String, String>? sentPath;
      final controller = _controller(
        handler: (r) async {
          sentPath = {'method': r.method, 'path': r.url.path};
          return successResponse(_mediaJson(id: 'logo-new'), status: 201);
        },
      );

      final ok = await controller.uploadLogo();

      expect(ok, true);
      expect(sentPath!['method'], 'POST');
      expect(sentPath!['path'], '/api/v1/hotels/h1/media/logo');
      expect(controller.logo?.id, 'logo-new');
      expect(controller.isUploadingLogo, false);
    });

    test('replacing an existing logo overwrites it, not appends', () async {
      final controller = _controller(
        handler: (r) async => successResponse(_mediaJson(id: 'logo-replacement'), status: 201),
      );
      controller.logo = HotelMedia.fromJson(_mediaJson(id: 'logo-old'));

      await controller.uploadLogo();

      expect(controller.logo?.id, 'logo-replacement');
    });

    test('cancelling the picker (returns null) is a no-op, no request made', () async {
      var called = false;
      final controller = _controller(
        handler: (r) async {
          called = true;
          throw StateError('should not be called');
        },
        pickImage: () async => null,
      );

      final ok = await controller.uploadLogo();

      expect(ok, false);
      expect(called, false);
    });

    test('an invalid-file rejection (400) surfaces the server message, logo unchanged', () async {
      final controller = _controller(
        handler: (r) async =>
            errorResponse('VALIDATION_ERROR', 'Unsupported file type. Allowed formats: JPEG, PNG, WebP.', 400),
      );

      final ok = await controller.uploadLogo();

      expect(ok, false);
      expect(controller.errorMessage, 'Unsupported file type. Allowed formats: JPEG, PNG, WebP.');
      expect(controller.logo, isNull);
    });

    test('an oversized-file rejection (400) surfaces the server message', () async {
      final controller = _controller(
        handler: (r) async => errorResponse('VALIDATION_ERROR', 'File exceeds the maximum size of 5 MB.', 400),
      );

      await controller.uploadLogo();

      expect(controller.errorMessage, 'File exceeds the maximum size of 5 MB.');
    });

    test('an upload failure (500) surfaces without crashing', () async {
      final controller = _controller(
        handler: (r) async => errorResponse('INTERNAL_SERVER_ERROR', 'An unexpected error occurred. Please try again later.', 500),
      );

      final ok = await controller.uploadLogo();

      expect(ok, false);
      expect(controller.errorMessage, 'An unexpected error occurred. Please try again later.');
    });
  });

  group('HotelMediaController.uploadPhoto', () {
    test('uploads via multipart POST and appends to the photos list', () async {
      final controller = _controller(
        handler: (r) async {
          expect(r.method, 'POST');
          expect(r.url.path, '/api/v1/hotels/h1/media/photos');
          return successResponse(_mediaJson(id: 'p1', type: 'PHOTO'), status: 201);
        },
      );

      final ok = await controller.uploadPhoto();

      expect(ok, true);
      expect(controller.photos, hasLength(1));
      expect(controller.photos.first.id, 'p1');
    });

    test('a second photo accumulates rather than replacing the first', () async {
      var callCount = 0;
      final controller = _controller(
        handler: (r) async {
          callCount += 1;
          return successResponse(_mediaJson(id: 'p$callCount', type: 'PHOTO'), status: 201);
        },
      );

      await controller.uploadPhoto();
      await controller.uploadPhoto();

      expect(controller.photos, hasLength(2));
      expect(controller.photos.map((p) => p.id), ['p1', 'p2']);
    });
  });

  group('HotelMediaController.deleteMedia', () {
    test('deletes the logo and clears it locally', () async {
      Map<String, String>? sent;
      final controller = _controller(
        handler: (r) async {
          sent = {'method': r.method, 'path': r.url.path};
          return http.Response('', 204);
        },
      );
      controller.logo = HotelMedia.fromJson(_mediaJson(id: 'logo1'));

      final ok = await controller.deleteMedia('logo1');

      expect(ok, true);
      expect(sent!['method'], 'DELETE');
      expect(sent!['path'], '/api/v1/hotels/h1/media/logo1');
      expect(controller.logo, isNull);
    });

    test('deletes one photo from the list, leaving the others', () async {
      final controller = _controller(handler: (r) async => http.Response('', 204));
      controller.photos = [
        HotelMedia.fromJson(_mediaJson(id: 'p1', type: 'PHOTO')),
        HotelMedia.fromJson(_mediaJson(id: 'p2', type: 'PHOTO')),
      ];

      await controller.deleteMedia('p1');

      expect(controller.photos.map((p) => p.id), ['p2']);
    });

    test('a 404 (already deleted / not owned) surfaces the server message, state unchanged', () async {
      final controller = _controller(
        handler: (r) async => errorResponse('NOT_FOUND', 'Hotel media not found.', 404),
      );
      controller.photos = [HotelMedia.fromJson(_mediaJson(id: 'p1', type: 'PHOTO'))];

      final ok = await controller.deleteMedia('p1');

      expect(ok, false);
      expect(controller.errorMessage, 'Hotel media not found.');
      expect(controller.photos, hasLength(1));
    });
  });
}
