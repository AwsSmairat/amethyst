/// Base URL for the Amethyst API (includes `/api` prefix).
///
/// **Production default:** deployed backend on Render.
///
/// **Override** (local / staging / tests):
/// `--dart-define=API_BASE_URL=https://your-host.com/api`
abstract final class ApiConfig {
  /// Production API on Render. Override with `--dart-define=API_BASE_URL=...` when needed.
  static const String _productionDefault =
      'https://amethyst-shhh.onrender.com/api';

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
    return _isValidHttpBaseUrl(resolvedBaseUrl);
  }

  /// Non-null when startup should block and show the configuration screen.
  static String? get configurationBlockReason {
    if (!isConfigured) {
      return 'API_BASE_URL is empty. Set it in lib/core/config/api_config.dart '
          'or pass --dart-define=API_BASE_URL=...';
    }
    if (_containsUnsubstitutedPlaceholder(resolvedBaseUrl)) {
      return 'Replace YOUR-RENDER-URL in the production default '
          '(lib/core/config/api_config.dart) with your Render subdomain, '
          'or use --dart-define=API_BASE_URL=https://<your-service>.onrender.com/api';
    }
    if (!_isValidHttpBaseUrl(resolvedBaseUrl)) {
      return 'API_BASE_URL must be a valid http(s) URL with a host, e.g. '
          'https://example.onrender.com/api';
    }
    return null;
  }

  static bool _containsUnsubstitutedPlaceholder(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('your-render-url');
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
