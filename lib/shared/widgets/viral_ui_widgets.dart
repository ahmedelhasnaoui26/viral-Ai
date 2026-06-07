import 'package:flutter/material.dart';

import '../../core/theme/viral_design_tokens.dart';
import 'viral_gradient_button.dart';

/// Gradient text (titles like "Create", "Explore", "CineMorph AI").
class ViralGradientText extends StatelessWidget {
  const ViralGradientText(
    this.text, {
    this.fontSize = 28,
    this.fontWeight = FontWeight.w700,
    this.gradient = ViralTokens.primaryGradient,
    super.key,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class ViralSectionHeader extends StatelessWidget {
  const ViralSectionHeader({
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
    this.leadingIcon,
    super.key,
  });

  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leadingIcon != null) ...[leadingIcon!, const SizedBox(width: 8)],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: ViralTokens.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (trailingLabel != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailingLabel!,
              style: const TextStyle(
                color: Color(0xFFA78BFA),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class ViralNotificationBell extends StatelessWidget {
  const ViralNotificationBell({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ViralTokens.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none, color: ViralTokens.textPrimary, size: 22),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEC4899),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ViralHomeHeroCard extends StatelessWidget {
  const ViralHomeHeroCard({required this.onCreateTap, super.key});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ViralTokens.radiusXl),
        gradient: ViralTokens.heroCardGradient,
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: ViralTokens.textPrimary, size: 36),
          const SizedBox(height: 16),
          const Text(
            'Turn Photos Into Magic',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ViralTokens.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create viral cinematic videos in seconds',
            textAlign: TextAlign.center,
            style: TextStyle(color: ViralTokens.textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: ViralGradientButton(
              label: 'Create Video',
              height: 48,
              onPressed: onCreateTap,
            ),
          ),
        ],
      ),
    );
  }
}

class ViralProUpgradeBanner extends StatelessWidget {
  const ViralProUpgradeBanner({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ViralTokens.radiusLg),
          gradient: ViralTokens.proBannerGradient,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium, color: ViralTokens.textPrimary, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      color: ViralTokens.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Unlimited videos, no watermark',
                    style: TextStyle(color: ViralTokens.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.8), size: 24),
          ],
        ),
      ),
    );
  }
}

class ViralCreatorRow extends StatelessWidget {
  const ViralCreatorRow({
    required this.name,
    required this.followers,
    this.subtitle,
    this.isFollowing = false,
    this.followEnabled = true,
    this.onFollow,
    super.key,
  });

  final String name;
  final String followers;
  final String? subtitle;
  final bool isFollowing;
  final bool followEnabled;
  final VoidCallback? onFollow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ViralTokens.surface,
        borderRadius: BorderRadius.circular(ViralTokens.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: ViralTokens.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: ViralTokens.textMuted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  followers,
                  style: const TextStyle(color: ViralTokens.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          if (followEnabled)
            SizedBox(
              width: 96,
              height: 36,
              child: ViralGradientButton(
                label: isFollowing ? 'Following' : 'Follow',
                height: 36,
                showGlow: false,
                onPressed: onFollow,
              ),
            ),
        ],
      ),
    );
  }
}

class ViralBackCircleButton extends StatelessWidget {
  const ViralBackCircleButton({this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      style: IconButton.styleFrom(
        backgroundColor: ViralTokens.surface,
        shape: const CircleBorder(),
      ),
      icon: const Icon(Icons.arrow_back, color: ViralTokens.textPrimary, size: 22),
    );
  }
}

class ViralFeatureIconRow extends StatelessWidget {
  const ViralFeatureIconRow({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: ViralTokens.crownGradient,
            ),
            child: Icon(icon, color: ViralTokens.textPrimary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ViralTokens.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ViralSubscriptionPlanTile extends StatelessWidget {
  const ViralSubscriptionPlanTile({
    required this.title,
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
    this.saveLabel,
    this.badge,
    super.key,
  });

  final String title;
  final String price;
  final String period;
  final String? saveLabel;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: ViralTokens.surface,
              borderRadius: BorderRadius.circular(ViralTokens.radiusLg),
              border: selected
                  ? Border.all(color: const Color(0xFFA855F7), width: 1.5)
                  : Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: ViralTokens.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (saveLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          saveLabel!,
                          style: const TextStyle(
                            color: Color(0xFFA78BFA),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: ViralTokens.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      period,
                      style: const TextStyle(color: ViralTokens.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: ViralTokens.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: ViralTokens.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
