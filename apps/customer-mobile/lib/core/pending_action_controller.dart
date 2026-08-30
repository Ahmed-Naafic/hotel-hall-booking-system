import 'package:flutter/foundation.dart';

import '../features/discovery/data/discovery_models.dart';

class PendingActionController extends ChangeNotifier {
  HallSummary? hall;

  void preserveBookingHall(HallSummary value) {
    hall = value;
    notifyListeners();
  }

  HallSummary? takeHall() {
    final value = hall;
    hall = null;
    notifyListeners();
    return value;
  }
}
