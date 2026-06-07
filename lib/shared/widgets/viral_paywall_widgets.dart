import 'package:flutter/material.dart';

import '../../core/theme/viral_design_tokens.dart';
import 'viral_gradient_button.dart';

class PlanFeatureRow extends StatelessWidget {
  const PlanFeatureRow({
    required this.label,
    required this.included,
    super.key,
  });

  final String label;
  final bool included;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: included ? ViralTokens.checkGreen : ViralTokens.textDim,
            ),
            child: Icon(
              included ? Icons.check : Icons.close,
              size: 14,
              color: included ? ViralTokens.textPrimary : ViralTokens.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: included ? ViralTokens.textPrimary : ViralTokens.textDim,
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

class ViralPlanCard extends StatelessWidget {
  const ViralPlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.buttonLabel,
    required this.onPressed,
    this.isCurrentPlan = false,
    this.showMostPopular = false,
    this.gradientBorder = false,
    this.headerIcon,
    super.key,
  });

  final String title;
  final String price;
  final String period;
  final List<({String label, bool included})> features;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool isCurrentPlan;
  final bool showMostPopular;
  final bool gradientBorder;
  final Widget? headerIcon;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: gradientBorder ? ViralTokens.cardInner : ViralTokens.surface,
        borderRadius: BorderRadius.circular(ViralTokens.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ViralTokens.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            color: ViralTokens.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          period,
                          style: const TextStyle(
                            color: ViralTokens.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ?headerIcon,
            ],
          ),
          const SizedBox(height: 24),
          ...features.map((f) => PlanFeatureRow(label: f.label, included: f.included)),
          const SizedBox(height: 8),
          if (isCurrentPlan)
            _CurrentPlanButton(label: buttonLabel)
          else
            ViralGradientButton(
              label: buttonLabel,
              onPressed: onPressed,
              showGlow: true,
              gradient: ViralTokens.primaryGradient,
            ),
        ],
      ),
    );

    if (gradientBorder) {
      card = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ViralTokens.radiusXl + 2),
          gradient: ViralTokens.proCardBorderGradient,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA855F7).withValues(alpha: 0.2),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: card,
      );
    }

    if (showMostPopular) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: card,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: ViralTokens.crownGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Most Popular',
              style: TextStyle(
                color: ViralTokens.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    return card;
  }
}

class _CurrentPlanButton extends StatelessWidget {
  const _CurrentPlanButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(ViralTokens.radiusXs),
        border: Border.all(color: ViralTokens.textDim),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: ViralTokens.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ViralSpecialOfferCard extends StatelessWidget {
  const ViralSpecialOfferCard({required this.onViewAnnual, super.key});

  final VoidCallback onViewAnnual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ViralTokens.surface,
        borderRadius: BorderRadius.circular(ViralTokens.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ViralTokens.specialOfferIconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => ViralTokens.crownGradient.createShader(bounds),
                  child: const Icon(Icons.auto_awesome, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Special Offer',
                      style: TextStyle(
                        color: ViralTokens.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Get 2 months free when you subscribe to the annual plan. Limited time only!',
                      style: TextStyle(
                        color: ViralTokens.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewAnnual,
              style: ElevatedButton.styleFrom(
                backgroundColor: ViralTokens.textPrimary,
                foregroundColor: ViralTokens.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ViralTokens.radiusSm),
                ),
              ),
              child: const Text(
                'View Annual Plans',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
