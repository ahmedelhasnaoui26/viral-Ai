import 'package:flutter/material.dart';

import '../../core/theme/viral_design_tokens.dart';

class ViralGradientButton extends StatelessWidget {
  const ViralGradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.height = 60,
    this.gradient = ViralTokens.primaryGradient,
    this.showGlow = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final double height;
  final Gradient gradient;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ViralTokens.radiusMd),
        gradient: onPressed == null ? null : gradient,
        color: onPressed == null ? ViralTokens.surface : null,
        boxShadow: showGlow && onPressed != null ? ViralTokens.primaryButtonGlow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(ViralTokens.radiusMd),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: ViralTokens.textPrimary, size: 22),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: ViralTokens.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 6),
                  Icon(trailingIcon, color: ViralTokens.textPrimary, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ViralWhiteButton extends StatelessWidget {
  const ViralWhiteButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ViralTokens.textPrimary,
          foregroundColor: ViralTokens.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ViralTokens.radiusSm),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 10)],
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ViralTokens.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViralOutlinedDarkButton extends StatelessWidget {
  const ViralOutlinedDarkButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: ViralTokens.textPrimary,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ViralTokens.radiusSm),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 10)],
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
