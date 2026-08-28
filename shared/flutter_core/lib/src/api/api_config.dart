/// Backend base URL (api-standards.md §3, `/api/v1`). Overridable per build
/// via `--dart-define=API_BASE_URL=...` — never hardcoded per-environment
/// logic inside app code. Defaults to the Android-emulator loopback address
/// (`10.0.2.2`) reaching the local backend's default port (`backend/.env`'s
/// `PORT=3000`) — the common Flutter local-development default; a real
/// deployment overrides this at build time, not by editing source.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.108:3000/api/v1',
  );
}
