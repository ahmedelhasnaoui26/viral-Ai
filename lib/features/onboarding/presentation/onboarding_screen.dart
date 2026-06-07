import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../core/di/providers.dart';
import '../../../core/layout/viral_layout.dart';
import '../../../core/theme/viral_design_tokens.dart';
import '../../auth/application/guest_mode_provider.dart';
import '../../../shared/widgets/viral_gradient_button.dart';
import '../../../shared/widgets/viral_onboarding_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.showChevron,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool showChevron;
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _OnboardingPageData(
      icon: Icons.auto_fix_high,
      title: 'Transform Images to Videos',
      subtitle:
          'Upload any image and watch AI bring it to life with stunning animations and effects',
      buttonLabel: 'Continue',
      showChevron: true,
    ),
    _OnboardingPageData(
      icon: Icons.bolt_outlined,
      title: 'Use Viral Templates',
      subtitle:
          'Choose from thousands of trending templates used by top creators',
      buttonLabel: 'Continue',
      showChevron: true,
    ),
    _OnboardingPageData(
      icon: Icons.trending_up,
      title: 'Share & Grow',
      subtitle:
          'Join a community of creators and grow your audience with viral content',
      buttonLabel: 'Start Creating',
      showChevron: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final analytics = ref.read(analyticsServiceProvider).asData?.value;
    analytics?.track(const AnalyticsEvent(AnalyticsEvents.onboardingStarted));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _enterAsGuest() async {
    await ref.read(guestModeProvider.notifier).enterGuestMode();
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _close() async {
    HapticFeedback.lightImpact();
    await _enterAsGuest();
  }

  Future<void> _onPrimaryPressed() async {
    if (_index < _pages.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final analytics = ref.read(analyticsServiceProvider).asData?.value;
    await analytics?.track(
      const AnalyticsEvent(AnalyticsEvents.onboardingCompleted),
    );
    await ref.read(guestModeProvider.notifier).markOnboardingComplete();
    if (!mounted) return;
    context.push('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final compact = ViralLayout.isCompact(context);
    final titleSize = compact ? 26.0 : 32.0;
    final sectionGap = compact ? 20.0 : 32.0;
    final contentGap = compact ? 24.0 : 48.0;
    final buttonHeight = compact ? 52.0 : 60.0;

    return Scaffold(
      backgroundColor: ViralTokens.black,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [
              const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              ViralTokens.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ViralTokens.paddingScreen),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    ViralSkipButton(onPressed: _close),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _pages.length,
                        onPageChanged: (value) {
                          HapticFeedback.selectionClick();
                          setState(() => _index = value);
                        },
                        itemBuilder: (context, index) {
                          final data = _pages[index];
                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ViralOnboardingIconCard(icon: data.icon),
                                  SizedBox(height: contentGap),
                                  Text(
                                    data.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ViralTokens.textPrimary,
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                      height: 1.15,
                                    ),
                                  ),
                                  SizedBox(height: compact ? 12 : 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      data.subtitle,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: ViralTokens.textSecondary,
                                        fontSize: compact ? 14 : 16,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    ViralPageIndicator(count: _pages.length, activeIndex: _index),
                    SizedBox(height: sectionGap),
                    ViralGradientButton(
                      label: page.buttonLabel,
                      trailingIcon: page.showChevron ? Icons.arrow_forward : null,
                      height: buttonHeight,
                      onPressed: _onPrimaryPressed,
                    ),
                    SizedBox(height: compact ? 8 : 16),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
