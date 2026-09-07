import 'package:shared_preferences/shared_preferences.dart';

/// First-launch product walkthrough (not provider profile onboarding).
class WelcomeIntroStorage {
  WelcomeIntroStorage(this._prefs);

  static const prefKey = 'welcome_intro_seen_v1';

  final SharedPreferences _prefs;
  bool seen = false;

  void load() {
    seen = _prefs.getBool(prefKey) ?? false;
  }

  Future<void> markSeen() async {
    seen = true;
    await _prefs.setBool(prefKey, true);
  }

  /// Debug / QA — show intro again next cold start.
  Future<void> reset() async {
    seen = false;
    await _prefs.remove(prefKey);
  }
}
