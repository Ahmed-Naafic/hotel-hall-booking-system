import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../data/hall_models.dart';
import '../data/hall_repository.dart';

enum HallListStatus { loading, empty, ready, error }

/// Loads one Hotel's Halls (own-Hotel management view — every Hall
/// regardless of visibility, WBS-05), optionally narrowed by [search] text
/// or an Active/Inactive [statusFilter] — both applied server-side (the
/// backend's own `GET /hotels/:hotelId/halls?search=&status=`), never a
/// client-side filter over an already-loaded, possibly-incomplete page.
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
  static const _searchDebounce = Duration(milliseconds: 400);

  String search = '';
  // null = "All", matching the mockup's default selected chip.
  String? statusFilter;
  Timer? _searchDebounceTimer;

  // Overview chip counts — "All (n)" / "Active (n)" / "Inactive (n)".
  // Non-essential (the list itself works without them), so a failure here
  // never surfaces as a screen-level error.
  int? allCount;
  int? activeCount;
  int? inactiveCount;

  bool get isFiltering => search.isNotEmpty || statusFilter != null;

  Future<void> load() async {
    status = HallListStatus.loading;
    errorMessage = null;
    _page = 1;
    notifyListeners();

    try {
      final result = await repository.listHalls(
        hotelId: hotelId,
        page: _page,
        limit: _limit,
        search: search,
        status: statusFilter,
      );
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
    unawaited(loadCounts());
  }

  Future<void> loadMore() async {
    if (!hasNext || isLoadingMore) return;
    isLoadingMore = true;
    notifyListeners();

    try {
      final result = await repository.listHalls(
        hotelId: hotelId,
        page: _page + 1,
        limit: _limit,
        search: search,
        status: statusFilter,
      );
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

  /// The "All (n)" / "Active (n)" / "Inactive (n)" chip counts — two cheap
  /// `limit: 1` calls (mirroring the same `page.total`-only trick the
  /// Dashboard's own Hall count already uses), never every Hall fetched
  /// just to count it. Inactive is derived (`all - active`) rather than a
  /// third call.
  Future<void> loadCounts() async {
    try {
      final results = await Future.wait([
        repository.listHalls(hotelId: hotelId, limit: 1),
        repository.listHalls(hotelId: hotelId, limit: 1, status: 'active'),
      ]);
      allCount = results[0].total;
      activeCount = results[1].total;
      inactiveCount = results[0].total - results[1].total;
      notifyListeners();
    } on ApiException {
      // Chip counts are a non-essential nicety.
    } on NetworkException {
      // Same.
    }
  }

  /// Debounced (BDR-020-style — matches the established Hotel-search
  /// pattern), so every keystroke doesn't fire a request.
  void setSearch(String value) {
    search = value;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, load);
  }

  /// Chip taps are immediate — never debounced, unlike free-text search.
  void setStatusFilter(String? value) {
    if (statusFilter == value) return;
    statusFilter = value;
    load();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
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
    unawaited(loadCounts());
  }

  /// The Manager's own Active/Inactive toggle — reloads (rather than a
  /// local `upsert`) so a Hall that no longer matches the current
  /// status filter disappears immediately, exactly like a fresh fetch
  /// would show.
  Future<void> setHallActive(Hall hall, bool isActive) async {
    await repository.setActive(hotelId: hotelId, id: hall.id, isActive: isActive);
    await load();
  }
}
