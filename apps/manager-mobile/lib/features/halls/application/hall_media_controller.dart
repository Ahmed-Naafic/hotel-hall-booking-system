import 'package:flutter/foundation.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../data/hall_models.dart';
import '../data/hall_repository.dart';

class HallMediaController extends ChangeNotifier {
  HallMediaController({
    required this.repository,
    required this.hotelId,
    required this.hallId,
    this.photos = const [],
  });

  final HallRepository repository;
  final String hotelId;
  final String hallId;
  List<HallMedia> photos;
  bool isBusy = false;
  String? deletingId;
  String? errorMessage;

  Future<void> load() async {
    try {
      photos = await repository.getMedia(hotelId: hotelId, hallId: hallId);
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } on NetworkException catch (e) {
      errorMessage = e.message;
    }
    notifyListeners();
  }

  Future<void> delete(String id) async {
    deletingId = id;
    notifyListeners();
    try {
      await repository.deleteMedia(
        hotelId: hotelId,
        hallId: hallId,
        mediaId: id,
      );
      photos = photos.where((photo) => photo.id != id).toList();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } on NetworkException catch (e) {
      errorMessage = e.message;
    } finally {
      deletingId = null;
      notifyListeners();
    }
  }
}
