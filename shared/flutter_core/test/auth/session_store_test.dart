import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'in_memory_token_storage.dart';

void main() {
  group('SessionStore', () {
    test('save() with no remember argument persists, matching pre-existing behavior', () async {
      final storage = InMemoryTokenStorage();
      final sessionStore = SessionStore(storage: storage);

      await sessionStore.save(accessToken: 'a', refreshToken: 'b');

      expect(await storage.read('hh_access_token'), 'a');
      expect(await sessionStore.accessToken, 'a');
      expect(await sessionStore.refreshToken, 'b');
    });

    test('save(remember: false) keeps tokens readable this run without writing them to storage', () async {
      final storage = InMemoryTokenStorage();
      final sessionStore = SessionStore(storage: storage);

      await sessionStore.save(accessToken: 'a', refreshToken: 'b', remember: false);

      expect(await sessionStore.accessToken, 'a');
      expect(await sessionStore.refreshToken, 'b');
      expect(await storage.read('hh_access_token'), isNull);
      expect(await storage.read('hh_refresh_token'), isNull);
    });

    test('save(remember: false) wipes any session already persisted from an earlier login', () async {
      final storage = InMemoryTokenStorage();
      final sessionStore = SessionStore(storage: storage);
      await sessionStore.save(accessToken: 'old', refreshToken: 'old-r');

      await sessionStore.save(accessToken: 'new', refreshToken: 'new-r', remember: false);

      expect(await storage.read('hh_access_token'), isNull);
      expect(await sessionStore.accessToken, 'new');
    });

    test('a token-refresh save (remember omitted) reuses the last real choice', () async {
      final storage = InMemoryTokenStorage();
      final sessionStore = SessionStore(storage: storage);
      await sessionStore.save(accessToken: 'a', refreshToken: 'b', remember: false);

      // ApiClient's tokenPairSaver calls save() without a remember argument
      // on every token rotation — it has no way to know the original choice.
      await sessionStore.save(accessToken: 'a2', refreshToken: 'b2');

      expect(await sessionStore.accessToken, 'a2');
      expect(await storage.read('hh_access_token'), isNull, reason: 'still session-only');
    });

    test('clear() resets to the remembered default and drops both stores', () async {
      final storage = InMemoryTokenStorage();
      final sessionStore = SessionStore(storage: storage);
      await sessionStore.save(accessToken: 'a', refreshToken: 'b', remember: false);

      await sessionStore.clear();

      expect(await sessionStore.accessToken, isNull);
      // The next save() with no remember argument (e.g. a plain login)
      // persists again, not silently inheriting the session-only choice.
      await sessionStore.save(accessToken: 'c', refreshToken: 'd');
      expect(await storage.read('hh_access_token'), 'c');
    });
  });
}
