import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/core/welcome/welcome_intro_storage.dart';

/// First-launch explainer (voice → match → CONNECT). Skip once → login.
class WelcomeIntroPage extends StatefulWidget {
  const WelcomeIntroPage({super.key});

  @override
  State<WelcomeIntroPage> createState() => _WelcomeIntroPageState();
}

class _WelcomeIntroPageState extends State<WelcomeIntroPage> {
  final _page = PageController();
  int _index = 0;

  static const _stepCount = 4;

  List<_WelcomeStep> get _steps => [
        _WelcomeStep(
          title: t('welcome.step1.title'),
          body: t('welcome.step1.body'),
          visual: _WelcomeVisual.logo,
        ),
        _WelcomeStep(
          title: t('welcome.step2.title'),
          body: t('welcome.step2.body'),
          visual: _WelcomeVisual.icon,
          icon: Icons.mic_rounded,
          accent: AppColors.secondary,
        ),
        _WelcomeStep(
          title: t('welcome.step3.title'),
          body: t('welcome.step3.body'),
          visual: _WelcomeVisual.icon,
          icon: Icons.travel_explore_rounded,
          accent: AppColors.primary,
        ),
        _WelcomeStep(
          title: t('welcome.step4.title'),
          body: t('welcome.step4.body'),
          visual: _WelcomeVisual.icon,
          icon: Icons.forum_rounded,
          accent: AppColors.secondary,
        ),
      ];

  Future<void> _finish() async {
    await getIt<WelcomeIntroStorage>().markSeen();
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    if (_index >= _stepCount - 1) {
      _finish();
      return;
    }
    _page.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final last = _index == _stepCount - 1;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F7FB),
              AppColors.mist,
              Color(0xFFFFE8CC),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      '${_index + 1}/$_stepCount',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        t('welcome.skip'),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  itemCount: _stepCount,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _WelcomeStepView(step: steps[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_stepCount, (i) {
                        final on = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: on ? 22 : 8,
                          decoration: BoxDecoration(
                            color: on ? AppColors.primary : AppColors.divider,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          last ? t('welcome.start') : t('welcome.next'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _WelcomeVisual { logo, icon }

class _WelcomeStep {
  const _WelcomeStep({
    required this.title,
    required this.body,
    required this.visual,
    this.icon,
    this.accent,
  });

  final String title;
  final String body;
  final _WelcomeVisual visual;
  final IconData? icon;
  final Color? accent;
}

class _WelcomeStepView extends StatelessWidget {
  const _WelcomeStepView({required this.step});

  final _WelcomeStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Center(child: _HeroVisual(step: step)),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: GoogleFonts.fraunces(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  step.body,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({required this.step});

  final _WelcomeStep step;

  @override
  Widget build(BuildContext context) {
    if (step.visual == _WelcomeVisual.logo) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/brand/logo-color.jpg',
                width: 148,
                height: 148,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'My Sancho',
            style: GoogleFonts.fraunces(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      );
    }

    final accent = step.accent ?? AppColors.primary;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.08),
          ),
        ),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(step.icon, size: 72, color: accent),
        ),
        Positioned(
          right: 36,
          top: 28,
          child: _MiniBadge(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.secondary,
          ),
        ),
        Positioned(
          left: 40,
          bottom: 36,
          child: _MiniBadge(
            icon: Icons.check_circle_rounded,
            color: AppColors.published,
          ),
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
