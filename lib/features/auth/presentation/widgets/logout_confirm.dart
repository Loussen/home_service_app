import 'package:flutter/material.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';

Future<bool> confirmLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.45),
    builder: (ctx) => Dialog(
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
              decoration: const BoxDecoration(
                color: AppColors.peach,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t('account.logout.confirm_title'),
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              t('account.logout.confirm_body'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.45,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(t('common.cancel')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(t('account.menu.logout')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return ok == true;
}
