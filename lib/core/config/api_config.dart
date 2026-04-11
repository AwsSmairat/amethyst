import 'package:flutter/foundation.dart';

/// Base URL for the Amethyst API (includes `/api` prefix).
///
/// ## Backend route layout (Express)
///
/// - **REST API:** `app.use('/api', apiRouter)` — auth, users, vehicles, etc. all live under
///   the `/api` prefix (e.g. `/api/auth/login`).
/// - **Also at server root (not under `/api`):** `GET /`, `GET /health` — do **not** use the
///   root domain alone as [baseUrl]; the app expects [resolvedBaseUrl] to end with `/api`.
///
/// ## Production URLs (default Railway API)
///
/// Use **`https://amethyst-production-7418.up.railway.app/api`** as [baseUrl] / [resolvedBaseUrl]
/// (never `https://amethyst-production-7418.up.railway.app` without `/api`).
///
/// | Purpose | Method + URL |
/// |--------|----------------|
/// | Health (matches app base) | `GET https://amethyst-production-7418.up.railway.app/api/health` |
/// | Login | `POST https://amethyst-production-7418.up.railway.app/api/auth/login` |
///
/// Root health (optional, not used by Dio): `GET https://amethyst-production-7418.up.railway.app/health`
///
/// **Production default:** Railway — override with `--dart-define=API_BASE_URL=...` for staging/CI.
///
/// **Override** (local / staging / tests):
/// `--dart-define=API_BASE_URL=http://127.0.0.1:4000/api`
///
/// **Web release:** `localhost` / `127.0.0.1` are rejected (browsers cannot reach
/// your laptop from Firebase Hosting). Use debug/profile or `--dart-define` with
/// a LAN/tunnel URL for local web testing.
abstract final class ApiConfig {
  /// Compile-time default when `API_BASE_URL` is not passed at build.
  static const String _productionDefault =
      'https://amethyst-production-7418.up.railway.app/api';

  /// Set `--dart-define=API_DEBUG_NETWORK=true` to log resolved URLs and Dio errors (login, etc.).
  static const bool debugNetwork =
      bool.fromEnvironment('API_DEBUG_NETWORK', defaultValue: false);

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _productionDefault,
  );

  /// Trimmed base URL with no trailing slash (single source for HTTP clients).
  static String get resolvedBaseUrl {
    final t = baseUrl.trim();
    if (t.isEmpty) return '';
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }

  static bool get isConfigured => resolvedBaseUrl.isNotEmpty;

  /// `true` when the URL is usable (valid `http`/`https`, host set, no template left).
  static bool get isValidConfiguration {
    if (!isConfigured) return false;
    if (_containsUnsubstitutedPlaceholder(resolvedBaseUrl)) return false;
    if (!_isValidHttpBaseUrl(resolvedBaseUrl)) return false;
    if (_isRetiredBundledApiHost(resolvedBaseUrl)) return false;
    return true;
  }

  /// Same path the app uses for `POST` login (`baseUrl` + `/auth/login` → `/api/auth/login` on server).
  static String get debugResolvedLoginUrl {
    final String b = resolvedBaseUrl;
    if (b.isEmpty) return '(API_BASE_URL unset)';
    return '$b/auth/login';
  }

  /// Non-null when startup should block and show the configuration screen.
  static String? get configurationBlockReason {
    if (!isConfigured) {
      return 'API_BASE_URL is empty. Set it in lib/core/config/api_config.dart '
          'or pass --dart-define=API_BASE_URL=...';
    }
    if (_containsUnsubstitutedPlaceholder(resolvedBaseUrl)) {
      return 'Replace the API host placeholder in lib/core/config/api_config.dart, '
          'or use --dart-define=API_BASE_URL=https://YOUR_SERVICE.up.railway.app/api';
    }
    if (!_isValidHttpBaseUrl(resolvedBaseUrl)) {
      return 'API_BASE_URL must be a valid http(s) URL with a host, e.g. '
          'https://amethyst-production-7418.up.railway.app/api';
    }
    if (_isRetiredBundledApiHost(resolvedBaseUrl)) {
      return 'This API host (legacy Render demo) is no longer available. '
          'Use the Railway production URL or your own deployment, e.g. '
          '--dart-define=API_BASE_URL=https://amethyst-production-7418.up.railway.app/api\n'
          'Verify: GET {API_BASE_URL}/health (e.g. '
          'https://amethyst-production-7418.up.railway.app/api/health).';
    }
    if (kIsWeb && kReleaseMode && _hostIsLoopback(resolvedBaseUrl)) {
      return 'Production web build cannot use localhost or 127.0.0.1 for '
          'API_BASE_URL (the API must be reachable from the internet). '
          'Use the default in lib/core/config/api_config.dart or pass '
          '--dart-define=API_BASE_URL=https://amethyst-production-7418.up.railway.app/api. '
          'For local Chrome testing use flutter run (debug) or a LAN/tunnel URL.';
    }
    return null;
  }

  static bool _hostIsLoopback(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host == 'localhost' || host == '127.0.0.1';
  }

  static bool _containsUnsubstitutedPlaceholder(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('your-render-url') ||
        host.contains('your-railway-url') ||
        host.contains('your-api-host');
  }

  /// Rejects the old bundled demo host (no longer deployed).
  static bool _isRetiredBundledApiHost(String url) {
    final String? host = Uri.tryParse(url)?.host.toLowerCase();
    return host == 'amethyst-shhh.onrender.com';
  }

  static bool _isValidHttpBaseUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    if (uri.host.isEmpty) return false;
    return true;
  }

  /// A short mode hint for debugging/logging.
  static String get mode {
    final raw = resolvedBaseUrl;
    if (raw.isEmpty) return 'missing';
    final uri = Uri.tryParse(raw);
    final host = uri?.host ?? '';
    if (host == '10.0.2.2') return 'emulator';
    if (host == 'localhost' || host == '127.0.0.1') return 'localhost';
    if (_isPrivateLan(host)) return 'local-lan';
    return 'public';
  }

  static bool _isPrivateLan(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    final nums = parts.map(int.tryParse).toList(growable: false);
    if (nums.any((e) => e == null)) return false;
    final a = nums[0]!, b = nums[1]!;
    if (a == 10) return true;
    if (a == 192 && b == 168) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    return false;
  }
}
