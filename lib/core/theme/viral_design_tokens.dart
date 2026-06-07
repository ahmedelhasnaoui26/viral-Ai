import 'package:flutter/material.dart';

/// Design tokens for CineMorph AI UI.
abstract final class ViralTokens {
  static const appName = 'CineMorph AI';
  static const black = Color(0xFF000000);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceElevated = Color(0xFF1C1C1E);
  static const cardDark = Color(0xFF121212);
  static const cardInner = Color(0xFF0A0A0A);
  static const borderSubtle = Color(0xFF2C2C2E);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);
  static const textDim = Color(0xFF4B5563);
  static const checkGreen = Color(0xFF22C55E);
  static const skipText = Color(0xFFE0E0E0);
  static const inputHint = Color(0xFF6B7280);
  static const dividerGrey = Color(0xFF374151);
  static const inactiveNav = Color(0xFF9CA3AF);
  static const trendingChipBg = Color(0xFF1E1033);
  static const trendingChipBorder = Color(0xFFA855F7);
  static const trendingChipText = Color(0xFFC4B5FD);
  static const proBadgeOrange = Color(0xFFF97316);
  static const specialOfferIconBg = Color(0xFF2D1B4E);

  static const radiusXs = 12.0;
  static const radiusSm = 16.0;
  static const radiusMd = 20.0;
  static const radiusLg = 24.0;
  static const radiusXl = 28.0;
  static const radiusPill = 32.0;

  static const paddingH = 20.0;
  static const paddingScreen = 24.0;

  static const primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
  );

  static const primaryGradientDiagonal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
  );

  static const crownGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
  );

  static const proCardBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
  );

  static const profileHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9333EA), Color(0xFF06B6D4)],
  );

  static const styleCinematic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
  );

  static const styleDreamy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
  );

  static const styleDramatic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFEA580C)],
  );

  static const styleEthereal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDB2777), Color(0xFF7C3AED)],
  );

  static const templateCinematic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
  );

  static const templateParallax = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF22D3EE)],
  );

  static const templateGlitch = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF4ADE80)],
  );

  static const templateDreamy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEC4899), Color(0xFF7C3AED)],
  );

  static const trendingCardMesh = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF9A8D4),
      Color(0xFFFDBA74),
      Color(0xFFFDE047),
      Color(0xFF6EE7B7),
      Color(0xFF93C5FD),
    ],
  );

  static const categoryTrending = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
  );

  static const categoryPopular = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
  );

  static const categoryNew = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF059669)],
  );

  static const categoryFavorites = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEC4899), Color(0xFFDC2626)],
  );

  static const generateButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7C3AED), Color(0xFFBE185D)],
  );

  static const durationSelected = Color(0xFF9333EA);

  static const heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D28D9), Color(0xFF4C1D95), Color(0xFF1E1033)],
  );

  static const proBannerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF5B21B6), Color(0xFF831843)],
  );

  static const feedBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4C1D95), Color(0xFFBE185D), Color(0xFF0A0A0A)],
    stops: [0.0, 0.45, 1.0],
  );

  static const styleAnime = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7F1D1D), Color(0xFFEC4899)],
  );

  static const styleViralTikTok = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
  );

  static const onboardingIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEC4899), Color(0xFF7C3AED)],
  );

  static List<BoxShadow> primaryButtonGlow = [
    BoxShadow(
      color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFFD946EF).withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> proButtonGlow = [
    BoxShadow(
      color: const Color(0xFFA855F7).withValues(alpha: 0.4),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}
