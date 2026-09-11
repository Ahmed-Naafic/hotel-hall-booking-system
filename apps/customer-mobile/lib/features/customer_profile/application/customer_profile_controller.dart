import 'package:flutter/foundation.dart';

import '../data/customer_profile_repository.dart';

class CustomerProfileController extends ChangeNotifier {
  CustomerProfileController(this.repository);
  final CustomerProfileRepository repository;
  CustomerSnapshot? snapshot;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      snapshot = await repository.getMe();
    } catch (_) {
      errorMessage = 'Could not load your profile.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> createProfile(String fullName) async {
    isLoading = true;
    notifyListeners();
    try {
      await repository.createProfile(fullName: fullName);
      await load();
    } catch (_) {
      errorMessage = 'Could not create your profile.';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateFullName(String fullName) async {
    isLoading = true;
    notifyListeners();
    try {
      await repository.updateFullName(fullName);
      await load();
    } catch (_) {
      errorMessage = 'Could not update your name.';
      isLoading = false;
      notifyListeners();
    }
  }

  // A distinct flag from `isLoading` — uploading/removing the avatar
  // shouldn't block or be blocked by the name editor's own loading state.
  bool isUploadingAvatar = false;
  String? avatarErrorMessage;

  Future<void> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    isUploadingAvatar = true;
    avatarErrorMessage = null;
    notifyListeners();
    try {
      await repository.uploadAvatar(bytes: bytes, filename: filename);
      await load();
    } catch (_) {
      avatarErrorMessage = 'Could not upload your photo.';
    }
    isUploadingAvatar = false;
    notifyListeners();
  }

  Future<void> deleteAvatar() async {
    isUploadingAvatar = true;
    avatarErrorMessage = null;
    notifyListeners();
    try {
      await repository.deleteAvatar();
      await load();
    } catch (_) {
      avatarErrorMessage = 'Could not remove your photo.';
    }
    isUploadingAvatar = false;
    notifyListeners();
  }
}
