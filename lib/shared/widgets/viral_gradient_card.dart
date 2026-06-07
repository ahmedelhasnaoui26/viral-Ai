import 'package:flutter/material.dart';

import '../../core/theme/viral_design_tokens.dart';
import 'viral_ui_widgets.dart';

class ViralGradientCard extends StatelessWidget {
  const ViralGradientCard({
    required this.gradient,
    required this.child,
    this.height,
    this.borderRadius = ViralTokens.radiusLg,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.selectedBorder = false,
    super.key,
  });

  final Gradient gradient;
  final Widget child;
  final double? height;
  final double borderRadius;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool selectedBorder;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: selectedBorder
            ? Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5)
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}

class ViralSectionTitle extends StatelessWidget {
  const ViralSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: ViralTokens.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );
  }
}

class ViralBrandHeader extends StatelessWidget {
  const ViralBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const ViralGradientText(
      ViralTokens.appName,
      fontSize: 24,
    );
  }
}

class ViralTrendingChip extends StatelessWidget {
  const ViralTrendingChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: ViralTokens.trendingChipBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ViralTokens.trendingChipBorder.withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 16, color: ViralTokens.trendingChipText),
          SizedBox(width: 6),
          Text(
            'Trending',
            style: TextStyle(
              color: ViralTokens.trendingChipText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
