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
}
