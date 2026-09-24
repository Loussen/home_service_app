import 'dart:io';

import 'package:flutter/material.dart';
import 'package:home_service_app/app/config/app_colors.dart';
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

  static const none = AppUpdateDecision(
    kind: AppUpdateKind.none,
    storeUrl: '',
    softMinVersion: '',
  );
}

/// Soft / force update from bootstrap `config.app_update`.
///
/// Force is a persistent [Stack] overlay (survives GoRouter navigation).
/// Soft is the same overlay but dismissible once per soft-min version.
class AppUpdateGate {
  AppUpdateGate._();

  static final ValueNotifier<AppUpdateDecision> decision =
      ValueNotifier(AppUpdateDecision.none);

  static bool _resolving = false;

  /// True while force-update overlay blocks the app — mute UX audio.
  static bool get isForceBlocked =>
      decision.value.kind == AppUpdateKind.force;

  /// Evaluate once after bootstrap; updates [decision].
  static Future<void> resolve() async {
    if (_resolving) return;
    _resolving = true;
    try {
      final result = await evaluate(AppRemoteConfig.instance.config.appUpdate);
      if (result.kind == AppUpdateKind.soft) {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool(_softDismissKey(result.softMinVersion)) == true) {
          decision.value = AppUpdateDecision.none;
          return;
        }
      }
      decision.value = result;
    } finally {
      _resolving = false;
    }
  }

  static Future<void> dismissSoft() async {
    final current = decision.value;
    if (current.kind != AppUpdateKind.soft) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_softDismissKey(current.softMinVersion), true);
    decision.value = AppUpdateDecision.none;
  }

  static Future<AppUpdateDecision> evaluate(BootstrapAppUpdate update) async {
    String current;
    try {
      final info = await PackageInfo.fromPlatform();
      current = info.version.trim();
    } catch (e) {
      // Hot restart after adding package_info_plus → MissingPluginException.
      debugPrint('[update] PackageInfo unavailable: $e');
      return AppUpdateDecision.none;
    }

    final platform = Platform.isIOS
        ? update.ios
        : (Platform.isAndroid ? update.android : null);
    if (platform == null) return AppUpdateDecision.none;

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

/// Full-screen gate — use above the router so auth redirects cannot dismiss it.
class AppUpdateOverlay extends StatelessWidget {
  const AppUpdateOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUpdateDecision>(
      valueListenable: AppUpdateGate.decision,
      builder: (context, decision, _) {
        if (decision.kind == AppUpdateKind.none) {
          return const SizedBox.shrink();
        }
        final force = decision.kind == AppUpdateKind.force;
        return Positioned.fill(
          child: Material(
            // Force: fully cover the app so navigation behind is invisible.
            // Soft: dim only — user can still dismiss.
            color: force
                ? AppColors.canvas
                : AppColors.ink.withValues(alpha: 0.55),
            child: SafeArea(
              child: Center(
                child: PopScope(
                  canPop: !force,
                  onPopInvokedWithResult: (didPop, _) async {
                    if (didPop && !force) {
                      await AppUpdateGate.dismissSoft();
                    }
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: force
                            ? const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 8),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: force ? AppColors.peach : AppColors.mist,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              force
                                  ? Icons.system_update_alt_rounded
                                  : Icons.system_update_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t(force
                                ? 'update.force_title'
                                : 'update.soft_title'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t(
                              force
                                  ? (Platform.isIOS
                                      ? 'update.force_body_ios'
                                      : 'update.force_body_android')
                                  : 'update.soft_body',
                            ),
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
                              onPressed: decision.storeUrl.isEmpty
                                  ? null
                                  : () async {
                                      final uri =
                                          Uri.tryParse(decision.storeUrl);
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(t('update.action')),
                            ),
                          ),
                          if (!force) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => AppUpdateGate.dismissSoft(),
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
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
