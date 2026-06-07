import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/viral_design_tokens.dart';
import '../../auth/application/auth_gate.dart';
import '../../auth/domain/auth_gated_action.dart';
import '../../credits/application/credits_providers.dart';
import '../../../shared/widgets/viral_gradient_button.dart';
import '../../../shared/widgets/viral_ui_widgets.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedPlan = 1;

  static const _features = [
    (Icons.videocam_outlined, 'More AI video generations (free plan: 1/day)'),
    (Icons.block, 'No watermark on exported videos'),
    (Icons.auto_awesome, 'Unlock premium viral templates'),
    (Icons.bookmark_added_outlined, 'Save videos to your library'),
    (Icons.ios_share, 'Share and download in full quality'),
  ];

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(revenueCatOfferingsProvider);

    return Scaffold(
      backgroundColor: ViralTokens.black,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1),
            radius: 1.2,
            colors: [
              const Color(0xFF6D28D9).withValues(alpha: 0.25),
              ViralTokens.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, ViralTokens.paddingH, 0),
                child: Row(
                  children: [
                    ViralBackCircleButton(onPressed: () => context.pop()),
                    const Expanded(
                      child: Text(
                        'Upgrade to Pro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ViralTokens.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: ViralTokens.paddingH),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(ViralTokens.radiusXl),
                          gradient: ViralTokens.heroCardGradient,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: ViralTokens.crownGradient,
                              ),
                              child: const Icon(
                                Icons.workspace_premium,
                                color: ViralTokens.textPrimary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Unlock Pro',
                              style: TextStyle(
                                color: ViralTokens.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Get everything below with your subscription',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: ViralTokens.textSecondary, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ViralSubscriptionPlanTile(
                        title: 'Weekly',
                        price: '\$4.99',
                        period: '/week',
                        selected: _selectedPlan == 0,
                        onTap: () => setState(() => _selectedPlan = 0),
                      ),
                      ViralSubscriptionPlanTile(
                        title: 'Monthly',
                        price: '\$14.99',
                        period: '/month',
                        saveLabel: 'Save 25%',
                        badge: 'Most Popular',
                        selected: _selectedPlan == 1,
                        onTap: () => setState(() => _selectedPlan = 1),
                      ),
                      ViralSubscriptionPlanTile(
                        title: 'Annual',
                        price: '\$99.99',
                        period: '/year',
                        saveLabel: 'Save 44%',
                        selected: _selectedPlan == 2,
                        onTap: () => setState(() => _selectedPlan = 2),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'What you get with Pro:',
                          style: TextStyle(
                            color: ViralTokens.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._features.map(
                        (f) => ViralFeatureIconRow(icon: f.$1, label: f.$2),
                      ),
                      const SizedBox(height: 24),
                      ViralGradientButton(
                        label: 'Start Free Trial',
                        onPressed: () => _purchase(offeringsAsync),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Free trial where available, then billed per plan. Cancel anytime.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ViralTokens.textMuted, fontSize: 12),
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text(
                          'Maybe later',
                          style: TextStyle(color: ViralTokens.textSecondary, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchase(AsyncValue<Offerings?> offeringsAsync) async {
    final allowed = await requireAuthentication(
      context,
      ref,
      action: AuthGatedAction.subscribePremium,
    );
    if (!allowed || !mounted) return;

    final offerings = offeringsAsync.asData?.value;
    final packages = offerings?.current?.availablePackages ?? [];
    final package = packages.isEmpty ? null : packages.first;
    if (package == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subscription packages found.')),
      );
      return;
    }
    final service = ref.read(revenueCatServiceProvider);
    await service.initialize();
    if (!service.isConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscriptions are not configured. Add REVENUECAT_APPLE_API_KEY.'),
        ),
      );
      return;
    }
    final analytics = ref.read(analyticsServiceProvider).asData?.value;
    try {
      await service.purchase(package);
      ref.invalidate(revenueCatPremiumProvider);
      ref.invalidate(userCreditsProvider);
      await analytics?.track(
        const AnalyticsEvent(AnalyticsEvents.subscriptionStarted),
      );
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $error')),
      );
    }
  }
}
