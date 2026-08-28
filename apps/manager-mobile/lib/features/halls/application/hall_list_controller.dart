import 'package:flutter/foundation.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../data/hall_models.dart';
import '../data/hall_repository.dart';

enum HallListStatus { loading, empty, ready, error }

/// Loads one Hotel's Halls (own-Hotel management view — every Hall
/// regardless of visibility, WBS-05). No visibility filtering happens
/// here or anywhere in this app — the backend already returns every Hall
/// the owning Manager is entitled to see (Hall Management Technical Design
/// §11).
class HallListController extends ChangeNotifier {
  HallListController({required this.repository, required this.hotelId});

  final HallRepository repository;
  final String hotelId;

  HallListStatus status = HallListStatus.loading;
  List<Hall> halls = [];
  String? errorMessage;
  bool hasNext = false;
  bool isLoadingMore = false;
  int _page = 1;
  static const _limit = 20;

  Future<void> load() async {
    status = HallListStatus.loading;
    errorMessage = null;
    _page = 1;
    notifyListeners();

    try {
      final result = await repository.listHalls(hotelId: hotelId, page: _page, limit: _limit);
      halls = result.halls;
      hasNext = result.hasNext;
      status = halls.isEmpty ? HallListStatus.empty : HallListStatus.ready;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = HallListStatus.error;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      status = HallListStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasNext || isLoadingMore) return;
    isLoadingMore = true;
    notifyListeners();

    try {
      final result = await repository.listHalls(hotelId: hotelId, page: _page + 1, limit: _limit);
      halls = [...halls, ...result.halls];
      hasNext = result.hasNext;
      _page += 1;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } on NetworkException catch (e) {
      errorMessage = e.message;
    }
    isLoadingMore = false;
    notifyListeners();
  }

  /// Called after a successful create/edit so the list reflects it without
  /// a full reload.
  void upsert(Hall hall) {
    final index = halls.indexWhere((h) => h.id == hall.id);
    if (index == -1) {
      halls = [hall, ...halls];
    } else {
      halls = [...halls]..[index] = hall;
    }
    status = HallListStatus.ready;
    notifyListeners();
  }
}
