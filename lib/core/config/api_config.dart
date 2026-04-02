/// Base URL for the Amethyst API (includes `/api` prefix).
///
/// Always override at build/run time via `--dart-define`, e.g.:
/// `--dart-define=API_BASE_URL=https://your-public-url.com/api`
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // No localhost / no LAN defaults: required for real-device + remote testing.
    defaultValue: '',
  );

  static bool get isConfigured => baseUrl.trim().isNotEmpty;

  /// A short mode hint for debugging/logging.
  static String get mode {
    final raw = baseUrl.trim();
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
