import 'package:image_picker/image_picker.dart';

/// The raw bytes and filename this app needs from a picked image — never
/// exposes the underlying `image_picker` package type beyond this file, so
/// a widget/controller depending on it stays trivially fakeable in tests
/// (no platform channel involved). Mirrors apps/manager-mobile's own
/// `image_picker_service.dart` (Hotel/Hall photo picking) exactly.
class PickedImageData {
  const PickedImageData({required this.bytes, required this.filename});

  final List<int> bytes;
  final String filename;
}

/// A pickable-function type, injected into `CustomerProfileController` —
/// tests supply a fake that returns fixed bytes instead of driving the
/// real platform picker (which needs a platform channel `flutter test`
/// doesn't provide).
typedef ImagePickerFn = Future<PickedImageData?> Function();

/// The real picker (gallery source — a Customer selecting an existing
/// photo, not taking a new one).
Future<PickedImageData?> pickImageFromGallery() async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.gallery);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return PickedImageData(bytes: bytes, filename: file.name);
}
