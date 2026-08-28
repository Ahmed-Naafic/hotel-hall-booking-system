import 'package:flutter/foundation.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../data/hotel_models.dart';
import '../data/hotel_repository.dart';
import 'image_picker_service.dart';

/// Drives Hotel Logo/Photo upload, replacement, deletion, and retrieval on
/// the Hotel Profile screen (`BDR-015`, `ADR-0006`, Technical Design §8a).
/// Independent of `HotelProfileFormController` — media upload is its own
/// immediate action per the approved upload flow ("Manager selects image →
/// ... → Flutter displays the uploaded media"), not bundled into the
/// standard-fields "Save & Continue" submission.
///
/// Never talks to Supabase directly (the mandated architecture: Manager
/// Mobile → Hotel Management Backend → Supabase Storage / Neon metadata) —
/// every action here is a call to this app's own `HotelRepository`, which
/// itself only ever calls this backend's own API.
class HotelMediaController extends ChangeNotifier {
  HotelMediaController({
    required this.repository,
    required this.hotelId,
    this.pickImage = pickImageFromGallery,
  });

  final HotelRepository repository;
  final String hotelId;
  final ImagePickerFn pickImage;

  HotelMedia? logo;
  List<HotelMedia> photos = [];

  bool isLoading = false;
  bool isUploadingLogo = false;
  bool isUploadingPhoto = false;
  String? deletingMediaId;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final media = await repository.getMedia(hotelId);
      logo = media.logo;
      photos = media.photos;
      isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      isLoading = false;
      errorMessage = e.message;
      notifyListeners();
    } on NetworkException catch (e) {
      isLoading = false;
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<bool> uploadLogo() async {
    final picked = await pickImage();
    if (picked == null) return false;

    isUploadingLogo = true;
    errorMessage = null;
    notifyListeners();
    try {
      logo = await repository.uploadLogo(hotelId, bytes: picked.bytes, filename: picked.filename);
      isUploadingLogo = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      isUploadingLogo = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      isUploadingLogo = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadPhoto() async {
    final picked = await pickImage();
    if (picked == null) return false;

    isUploadingPhoto = true;
    errorMessage = null;
    notifyListeners();
    try {
      final created = await repository.uploadPhoto(hotelId, bytes: picked.bytes, filename: picked.filename);
      photos = [...photos, created];
      isUploadingPhoto = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      isUploadingPhoto = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      isUploadingPhoto = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedia(String mediaId) async {
    deletingMediaId = mediaId;
    errorMessage = null;
    notifyListeners();
    try {
      await repository.deleteMedia(hotelId, mediaId);
      if (logo?.id == mediaId) {
        logo = null;
      }
      photos = photos.where((p) => p.id != mediaId).toList();
      deletingMediaId = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      deletingMediaId = null;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      deletingMediaId = null;
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
