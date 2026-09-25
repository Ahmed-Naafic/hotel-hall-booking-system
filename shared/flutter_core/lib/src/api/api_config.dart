/// Backend base URL (api-standards.md §3, `/api/v1`). Set per build via
/// `--dart-define=API_BASE_URL=...` — never hardcoded per-environment logic
/// inside app code.
///
/// The default is the deployed backend, reached over nginx on port 80 — not
/// `:3000`, which is the Node process's own port (`backend/.env`'s
/// `PORT=3000`) and is not exposed publicly on that host.
///
/// Any other target belongs on the build command, not here:
///
/// ```
/// flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
/// ```
///
/// (`10.0.2.2` is the Android-emulator loopback to the machine running the
/// emulator; a LAN address works the same way for a physical device.)
///
/// A baked-in address is a standing liability: when the deployment moves,
/// this line goes stale silently and the app just stops reaching the
/// backend with no clue why. If that happens, check here first.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://185.169.252.69/api/v1',
  );
}
