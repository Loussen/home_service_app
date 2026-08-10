import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController(text: '+994501111111');
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
    return Scaffold(
      // Avoid noisy layout fights with system keyboard when possible
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.12),
                      Text(
                        'Ev və Ailə\nXidmətləri',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'AI səs sorğusu ilə yaxınlıqdakı peşəkarlara çatın.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _phone,
                        focusNode: _focus,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _focus.unfocus(),
                        decoration: const InputDecoration(
                          labelText: 'Telefon nömrəsi',
                          helperText: 'Demo: +994501111111 · OTP 123456',
                        ),
                      ),
                      const SizedBox(height: 16),
                      BlocConsumer<AuthCubit, AuthState>(
                        listener: (context, state) {
                          if (state.message != null &&
                              state.message!.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.message!),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        builder: (context, state) {
                          return ElevatedButton(
                            onPressed: state.loading
                                ? null
                                : () async {
                                    final phone = _normalizedPhone();
                                    if (!RegExp(r'^\+?[0-9]{9,15}$')
                                        .hasMatch(phone)) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Tam nömrə daxil edin (məs. +994501111111)',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    final ok = await context
                                        .read<AuthCubit>()
                                        .sendOtp(phone);
                                    if (ok && context.mounted) {
                                      context.push('/otp');
                                    }
                                  },
                            child: Text(
                              state.loading ? 'Göndərilir...' : 'OTP göndər',
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'API: ${AppConfig.apiHostHint}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55),
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
