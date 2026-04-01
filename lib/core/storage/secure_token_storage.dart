import 'package:shared_preferences/shared_preferences.dart';

/// Persists the access token.
///
/// Tries [SharedPreferences] first. If the platform channel is unavailable
/// (e.g. right after **hot restart** on macOS, where Pigeon can throw
/// `PlatformException(channel-error, ...)`), falls back to an in-memory
/// store for the current process only.
///
/// For durable storage across launches, do a **full restart** (`Stop` then
/// `flutter run`), not only hot restart.
abstract class TokenStorage {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> deleteToken();
}

final class FallbackTokenStorage implements TokenStorage {
  FallbackTokenStorage();

  static const _key = 'amethyst_access_token';

  SharedPreferences? _prefsCache;
  String? _memory;
  bool _prefsUnavailable = false;

  void _invalidatePrefs() {
    _prefsUnavailable = true;
    _prefsCache = null;
  }

  Future<SharedPreferences?> _loadPrefs() async {
    if (_prefsUnavailable) {
      return null;
    }
    if (_prefsCache != null) {
      return _prefsCache;
    }
    try {
      _prefsCache = await SharedPreferences.getInstance();
      return _prefsCache;
    } on Object {
      _invalidatePrefs();
      return null;
    }
  }

  @override
  Future<String?> readToken() async {
    if (!_prefsUnavailable) {
      final SharedPreferences? p = await _loadPrefs();
      if (p != null) {
        try {
          final String? v = p.getString(_key);
          if (v != null && v.isNotEmpty) {
            _memory = v;
            return v;
          }
        } on Object {
          _invalidatePrefs();
        }
      }
    }
    return _memory;
  }

  @override
  Future<void> writeToken(String token) async {
    _memory = token;
    if (_prefsUnavailable) {
      return;
    }
    try {
      final SharedPreferences? p = await _loadPrefs();
      if (p != null) {
        await p.setString(_key, token);
      }
    } on Object {
      _invalidatePrefs();
    }
  }

  @override
  Future<void> deleteToken() async {
    _memory = null;
    if (_prefsUnavailable) {
      return;
    }
    try {
      final SharedPreferences? p = await _loadPrefs();
      if (p != null) {
        await p.remove(_key);
      }
    } on Object {
      _invalidatePrefs();
    }
  }
}
