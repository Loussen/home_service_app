import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_service_app/app/config/app_colors.dart';

/// Soft surface card used across My Sancho screens.
class MsCard extends StatelessWidget {
  const MsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: padding,
      child: child,
    );
    return Material(
      color: color,
      elevation: 0,
      shadowColor: AppColors.ink.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? body
          : InkWell(
              onTap: onTap,
              child: body,
            ),
    );
  }
}

class MsSectionTitle extends StatelessWidget {
  const MsSectionTitle(this.text, {super.key, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class MsBrandTitle extends StatelessWidget {
  const MsBrandTitle({
    super.key,
    this.fontSize = 28,
    this.showMark = true,
  });

  final double fontSize;
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      'My Sancho',
      style: GoogleFonts.fraunces(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.1,
      ),
    );
    if (!showMark) return title;
    final markSize = fontSize * 0.95;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(markSize * 0.22),
          child: Image.asset(
            'assets/brand/logo-color.jpg',
            width: markSize,
            height: markSize,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: fontSize * 0.28),
        Flexible(child: title),
      ],
    );
  }
}

class MsPrimaryButton extends StatelessWidget {
  const MsPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
