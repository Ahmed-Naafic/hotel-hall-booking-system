import 'package:flutter/foundation.dart';

import '../data/discovery_models.dart';
import '../data/discovery_repository.dart';

class DiscoveryController extends ChangeNotifier {
  DiscoveryController(this.repository);
  final DiscoveryRepository repository;
  List<HotelSummary> hotels = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadHotels() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      hotels = await repository.getHotels();
    } catch (_) {
      errorMessage = 'Could not load Hotels. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
