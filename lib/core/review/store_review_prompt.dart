import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Soft App Store / Play In-App Review — never spam.
///
/// Caps: max [maxLifetime] lifetime, min [minDaysBetween] days between prompts,
/// at most once per app version.
class StoreReviewPrompt {
  StoreReviewPrompt._();

  static const _countKey = 'store_review_shown_count';
  static const _lastAtKey = 'store_review_last_at_ms';
  static const _versionKey = 'store_review_last_version';

  static const maxLifetime = 3;
  static const minDaysBetween = 21;

  /// Call after a strong success (e.g. offer completed).
  static Future<void> maybeAsk() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_countKey) ?? 0;
      if (count >= maxLifetime) return;

      final info = await PackageInfo.fromPlatform();
      final version = '${info.version}+${info.buildNumber}';
      if (prefs.getString(_versionKey) == version) return;

      final lastMs = prefs.getInt(_lastAtKey);
      if (lastMs != null) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - lastMs;
        if (elapsed < minDaysBetween * 24 * 60 * 60 * 1000) return;
      }

      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;

      await review.requestReview();
      await prefs.setInt(_countKey, count + 1);
      await prefs.setInt(
        _lastAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setString(_versionKey, version);
    } catch (e) {
      debugPrint('[store_review] skip: $e');
    }
  }
}
