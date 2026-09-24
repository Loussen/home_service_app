import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/config/router.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/core/remote/bootstrap_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum AppUpdateKind { none, soft, force }

class AppUpdateDecision {
  const AppUpdateDecision({
    required this.kind,
    required this.storeUrl,
    required this.softMinVersion,
  });

  final AppUpdateKind kind;
  final String storeUrl;
  final String softMinVersion;
}

/// Soft / force update from bootstrap `config.app_update`.
class AppUpdateGate {
  AppUpdateGate._();

  static bool _prompting = false;

  static Future<void> maybePrompt() async {
    if (_prompting) return;
    final nav = rootNavigatorKey.currentContext;
    if (nav == null) return;

    final decision = await evaluate(AppRemoteConfig.instance.config.appUpdate);
    if (decision.kind == AppUpdateKind.none) return;

    if (decision.kind == AppUpdateKind.soft) {
      final prefs = await SharedPreferences.getInstance();
      final key = _softDismissKey(decision.softMinVersion);
      if (prefs.getBool(key) == true) return;
    }

    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    _prompting = true;
    try {
      await showDialog<void>(
        context: ctx,
        barrierDismissible: decision.kind == AppUpdateKind.soft,
        barrierColor: AppColors.ink.withValues(alpha: 0.45),
        builder: (dialogCtx) => PopScope(
          canPop: decision.kind == AppUpdateKind.soft,
          child: _UpdateDialog(
            kind: decision.kind,
            storeUrl: decision.storeUrl,
            onLater: () async {
              if (decision.kind == AppUpdateKind.soft) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(
                  _softDismissKey(decision.softMinVersion),
                  true,
                );
              }
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            },
          ),
        ),
      );
    } finally {
      _prompting = false;
    }
  }

  static Future<AppUpdateDecision> evaluate(BootstrapAppUpdate update) async {
    String current;
    try {
      final info = await PackageInfo.fromPlatform();
      current = info.version.trim();
    } catch (e) {
      // Hot restart after adding package_info_plus → MissingPluginException.
      // Full rebuild fixes it; skip the gate rather than crash.
      debugPrint('[update] PackageInfo unavailable: $e');
      return const AppUpdateDecision(
        kind: AppUpdateKind.none,
        storeUrl: '',
        softMinVersion: '',
      );
    }

    final platform = Platform.isIOS
        ? update.ios
        : (Platform.isAndroid ? update.android : null);
    if (platform == null) {
      return const AppUpdateDecision(
        kind: AppUpdateKind.none,
        storeUrl: '',
        softMinVersion: '',
      );
    }

    final forceMin = platform.forceMinVersion;
    if (forceMin.isNotEmpty && _isOlder(current, forceMin)) {
      return AppUpdateDecision(
        kind: AppUpdateKind.force,
        storeUrl: platform.storeUrl,
        softMinVersion: platform.softMinVersion,
      );
    }

    final softMin = platform.softMinVersion;
    if (softMin.isNotEmpty && _isOlder(current, softMin)) {
      return AppUpdateDecision(
        kind: AppUpdateKind.soft,
        storeUrl: platform.storeUrl,
        softMinVersion: softMin,
      );
    }

    return AppUpdateDecision(
      kind: AppUpdateKind.none,
      storeUrl: platform.storeUrl,
      softMinVersion: softMin,
    );
  }

  /// True when [current] is strictly older than [minimum].
  static bool _isOlder(String current, String minimum) {
    final a = _parts(current);
    final b = _parts(minimum);
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av < bv) return true;
      if (av > bv) return false;
    }
    return false;
  }

  static List<int> _parts(String version) {
    final cleaned = version.split(RegExp(r'[^0-9.]')).first;
    return cleaned
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList(growable: false);
  }

  static String _softDismissKey(String softMin) =>
      'soft_update_dismissed_${Platform.isIOS ? 'ios' : 'android'}_$softMin';
}

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog({
    required this.kind,
    required this.storeUrl,
    required this.onLater,
  });

  final AppUpdateKind kind;
  final String storeUrl;
  final Future<void> Function() onLater;

  bool get _force => kind == AppUpdateKind.force;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _force ? AppColors.peach : AppColors.mist,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _force
                    ? Icons.system_update_alt_rounded
                    : Icons.system_update_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t(_force ? 'update.force_title' : 'update.soft_title'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              t(_force ? 'update.force_body' : 'update.soft_body'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: storeUrl.isEmpty
                    ? null
                    : () async {
                        final uri = Uri.tryParse(storeUrl);
                        if (uri == null) return;
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.mist,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(t('update.action')),
              ),
            ),
            if (!_force) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => onLater(),
                child: Text(
                  t('update.later'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
