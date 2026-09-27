/// Stale-response protection for a controller that can have more than one
/// request in flight for the same piece of state.
///
/// The problem it solves, concretely: Discover's search box fans one query out
/// at every category controller. Each keystroke pause can start a request
/// while an earlier one is still travelling, and the network returns them in
/// whatever order it likes. Assigning the response directly — `halls = await
/// repository.get(...)` — means the **last response** wins rather than the
/// **last query**, so a slow reply for an abandoned query lands on top of a
/// newer one. When the abandoned query was the empty one, that paints the
/// whole unfiltered marketplace over a live search.
///
/// One mechanism, used by every discovery controller, rather than five
/// hand-rolled guards that can each drift:
///
/// ```dart
/// Future<void> load() async {
///   final request = beginRequest();
///   state = loading;
///   notifyListeners();
///   try {
///     final result = await repository.fetch(search: _search);
///     if (isSuperseded(request)) return; // a newer query has taken over
///     items = result;
///   } catch (_) {
///     if (isSuperseded(request)) return;
///   }
///   notifyListeners();
/// }
/// ```
///
/// Appending a page is the one case that must *not* claim a new generation —
/// see [currentRequest].
mixin RequestGeneration {
  int _generation = 0;

  /// Claims the next generation for a request that **replaces** the current
  /// result set, and returns the token to check on completion. Every earlier
  /// in-flight request becomes stale the moment this is called.
  int beginRequest() => ++_generation;

  /// Joins the generation already on screen, for a request that **appends** to
  /// it rather than replacing it — loading the next page.
  ///
  /// Deliberately does not advance the counter: a page belongs to the result
  /// set it was requested for, so if the query changes before it arrives it
  /// must be dropped, not appended to a list it was never part of.
  int currentRequest() => _generation;

  /// Whether `request` has been superseded by a newer one. A superseded
  /// request must not write its result, its error, or its loading flags — the
  /// generation that replaced it owns all of them.
  ///
  /// Named `isSuperseded` rather than `isStale` deliberately:
  /// `PopularHotelsController` already has an `isStale` flag meaning "the
  /// popularity ranking needs refetching", which is a different idea entirely.
  bool isSuperseded(int request) => request != _generation;
}
