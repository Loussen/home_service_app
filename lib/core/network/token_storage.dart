import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists Sanctum token across cold start / hot restart.
///
/// Secure storage is primary; SharedPreferences is a same-device fallback
/// because iOS Keychain reads can occasionally fail right after restart.
class TokenStorage {
  TokenStorage(this._prefs);

  static const _key = 'auth_token';
  static const _prefsKey = 'auth_token_prefs';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<void> saveToken(String token) async {
    await _storage.write(key: _key, value: token);
    await _prefs.setString(_prefsKey, token);
  }

  Future<String?> readToken() async {
    try {
      final secure = await _storage.read(key: _key);
      if (secure != null && secure.isNotEmpty) {
        // Keep prefs mirror in sync.
        if (_prefs.getString(_prefsKey) != secure) {
          await _prefs.setString(_prefsKey, secure);
        }
        return secure;
      }
    } catch (_) {
      // Fall through to prefs.
    }
    final fallback = _prefs.getString(_prefsKey);
    if (fallback != null && fallback.isNotEmpty) {
      // Re-hydrate secure storage when possible.
      try {
        await _storage.write(key: _key, value: fallback);
      } catch (_) {}
      return fallback;
    }
    return null;
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
    await _prefs.remove(_prefsKey);
  }
}
