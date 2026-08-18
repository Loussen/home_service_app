import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:home_service_app/features/auth/presentation/widgets/auth_chrome.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _goNext(AuthState state) {
    if (state.isNewUser) {
      context.go('/role');
      return;
    }
    final user = state.user;
    if (user != null && user.needsProviderOnboarding) {
      context.go('/onboarding');
      return;
    }
    context.go('/search');
  }

  @override
  Widget build(BuildContext context) {
    final phone = context.read<AuthCubit>().state.pendingPhone ?? '';

    return AuthChrome(
      showBack: true,
      subtitle: t('otp.subtitle'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('otp.title'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              phone.isEmpty
                  ? t('otp.sent_generic')
                  : t('otp.sent_to', params: {'phone': phone}),
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                helperText: t('otp.helper'),
              ),
            ),
            const SizedBox(height: 20),
            BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state.status == AuthStatus.authenticated) {
                  _goNext(state);
                }
                if (state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message!)),
                  );
                }
              },
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: state.loading
                      ? null
                      : () => context
                          .read<AuthCubit>()
                          .verifyOtp(_code.text.trim()),
                  child: Text(
                    state.loading ? t('otp.submitting') : t('otp.submit'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
