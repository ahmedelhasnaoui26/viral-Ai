import 'package:flutter/material.dart';

/// Responsive layout helpers for small phones (e.g. iPhone SE) through large Pro models.
abstract final class ViralLayout {
  /// Logical height below which we tighten vertical spacing (iPhone SE ≈ 667).
  static const compactHeightBreakpoint = 700.0;

  /// Logical width below which we tighten horizontal spacing.
  static const compactWidthBreakpoint = 375.0;

  static bool isCompactHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height < compactHeightBreakpoint;
  }

  static bool isCompactWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width < compactWidthBreakpoint;
  }

  static bool isCompact(BuildContext context) {
    return isCompactHeight(context) || isCompactWidth(context);
  }

  /// Approximate total height of [ViralBottomNav] including system inset.
  static double bottomNavTotalHeight(BuildContext context) {
    final metrics = bottomNavMetrics(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return metrics.topPadding +
        metrics.iconBoxSize +
        metrics.iconLabelGap +
        metrics.labelLineHeight +
        bottomInset +
        metrics.safeAreaMinimumBottom;
  }

  /// Scroll/sliver padding so content clears the bottom navigation bar.
  static double scrollPaddingAboveBottomNav(BuildContext context) {
    return bottomNavTotalHeight(context) + 16;
  }

  static BottomNavMetrics bottomNavMetrics(BuildContext context) {
    final compact = isCompactHeight(context);
    return BottomNavMetrics(
      topPadding: compact ? 6 : 8,
      iconBoxSize: compact ? 36 : 40,
      iconSize: compact ? 22 : 24,
      iconLabelGap: compact ? 2 : 4,
      labelFontSize: compact ? 10 : 11,
      labelLineHeight: compact ? 12 : 13,
      safeAreaMinimumBottom: compact ? 2 : 4,
    );
  }
}

class BottomNavMetrics {
  const BottomNavMetrics({
    required this.topPadding,
    required this.iconBoxSize,
    required this.iconSize,
    required this.iconLabelGap,
    required this.labelFontSize,
    required this.labelLineHeight,
    required this.safeAreaMinimumBottom,
  });

  final double topPadding;
  final double iconBoxSize;
  final double iconSize;
  final double iconLabelGap;
  final double labelFontSize;
  final double labelLineHeight;
  final double safeAreaMinimumBottom;
}
