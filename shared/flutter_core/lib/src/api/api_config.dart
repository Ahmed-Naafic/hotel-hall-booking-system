/// Backend base URL (api-standards.md §3, `/api/v1`). Set per build via
/// `--dart-define=API_BASE_URL=...` — never hardcoded per-environment logic
/// inside app code.
///
/// The default is the Android-emulator loopback (`10.0.2.2`) reaching the
/// local backend's default port (`backend/.env`'s `PORT=3000`), which is the
/// only host that is right by construction rather than by circumstance: it
/// resolves to whichever machine is running the emulator. Anything else — a
/// LAN address, a deployed server — belongs on the build command, because a
/// baked-in address goes stale silently and the app just stops reaching the
/// backend with no clue why.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );
}
