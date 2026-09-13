import 'package:flutter/material.dart';
import 'package:home_service_app/app/widgets/app_confirm_dialog.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';

Future<bool> confirmLogout(BuildContext context) {
  return showAppConfirm(
    context,
    title: t('account.logout.confirm_title'),
    message: t('account.logout.confirm_body'),
    confirmLabel: t('account.menu.logout'),
    cancelLabel: t('common.cancel'),
    destructive: true,
  );
}
