import 'package:customer_mobile/core/request_generation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The stale-response mechanism every discovery controller shares, tested once
/// here rather than five times through five controllers.

class _Subject with RequestGeneration {}

void main() {
  test('the first request is current', () {
    final subject = _Subject();

    final request = subject.beginRequest();

    expect(subject.isSuperseded(request), isFalse);
  });

  test('beginRequest supersedes every earlier request', () {
    final subject = _Subject();

    final first = subject.beginRequest();
    final second = subject.beginRequest();

    expect(subject.isSuperseded(first), isTrue, reason: 'the older request lost');
    expect(subject.isSuperseded(second), isFalse, reason: 'the newest request owns the state');
  });

  test('the newest request stays current however many were abandoned', () {
    final subject = _Subject();

    final abandoned = [for (var i = 0; i < 5; i += 1) subject.beginRequest()];
    final newest = subject.beginRequest();

    for (final request in abandoned) {
      expect(subject.isSuperseded(request), isTrue);
    }
    expect(subject.isSuperseded(newest), isFalse);
  });

  test('currentRequest joins the generation on screen without claiming a new one', () {
    final subject = _Subject();
    final onScreen = subject.beginRequest();

    // A page fetch for the result set already displayed.
    final page = subject.currentRequest();

    expect(page, onScreen, reason: 'a page belongs to the generation it was requested for');
    expect(subject.isSuperseded(page), isFalse);
  });

  test('a page is superseded as soon as the query changes', () {
    final subject = _Subject();
    subject.beginRequest();
    final page = subject.currentRequest();

    subject.beginRequest(); // the customer refined the query mid-page-fetch

    expect(
      subject.isSuperseded(page),
      isTrue,
      reason: 'the page must be dropped, not appended to a list it never belonged to',
    );
  });

  test('generations never repeat, so a token cannot be revived', () {
    final subject = _Subject();

    final seen = {for (var i = 0; i < 50; i += 1) subject.beginRequest()};

    expect(seen.length, 50);
  });
}
