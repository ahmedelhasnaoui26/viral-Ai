import 'package:flutter/material.dart';

import '../../core/layout/viral_layout.dart';
import '../../core/theme/viral_design_tokens.dart';

class ViralOnboardingIconCard extends StatelessWidget {
  const ViralOnboardingIconCard({
    required this.icon,
    super.key,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final compact = ViralLayout.isCompact(context);
    final size = compact ? 120.0 : 160.0;
    final iconSize = compact ? 48.0 : 64.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: ViralTokens.onboardingIconGradient,
        borderRadius: BorderRadius.circular(ViralTokens.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, size: iconSize, color: ViralTokens.textPrimary),
    );
  }
}

class ViralPageIndicator extends StatelessWidget {
  const ViralPageIndicator({
    required this.count,
    required this.activeIndex,
    super.key,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        if (isActive) {
          return Container(
            width: 28,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: ViralTokens.primaryGradient,
            ),
          );
        }
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: ViralTokens.dividerGrey,
          ),
        );
      }),
    );
  }
}

class ViralSkipButton extends StatelessWidget {
  const ViralSkipButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: ViralTokens.skipText,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: const Text(
          'Skip',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
