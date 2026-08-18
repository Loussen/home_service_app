import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:home_service_app/features/auth/presentation/widgets/auth_chrome.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController(text: '+994');
  final _focus = FocusNode();

  @override
  void dispose() {
    _phone.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _normalizedPhone() {
    var phone = _phone.text.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (phone.startsWith('00')) {
      phone = '+${phone.substring(2)}';
    }
    if (RegExp(r'^994\d{9}$').hasMatch(phone)) {
      phone = '+$phone';
    }
    if (RegExp(r'^0\d{9}$').hasMatch(phone)) {
      phone = '+994${phone.substring(1)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return AuthChrome(
      subtitle: t('login.subtitle'),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            Text(
              t('login.title'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t('login.hint'),
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phone,
              focusNode: _focus,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _focus.unfocus(),
              decoration: InputDecoration(
                labelText: t('login.phone_label'),
                prefixIcon: const Icon(Icons.phone_outlined),
                helperText: t('login.phone_helper'),
              ),
            ),
            const SizedBox(height: 20),
            BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state.message != null && state.message!.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message!)),
                  );
                }
              },
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: state.loading
                      ? null
                      : () async {
                          final phone = _normalizedPhone();
                          if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(phone)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t('login.phone_invalid')),
                              ),
                            );
                            return;
                          }
                          final ok =
                              await context.read<AuthCubit>().sendOtp(phone);
                          if (ok && context.mounted) context.push('/otp');
                        },
                  child: Text(
                    state.loading ? t('login.submitting') : t('login.submit'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              AppConfig.apiHostHint,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.muted.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
