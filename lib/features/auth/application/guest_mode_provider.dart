import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router_refresh.dart';
import '../../../core/analytics/analytics_event.dart';
import '../../../core/di/providers.dart';
import '../data/guest_mode_repository.dart';

final guestModeRepositoryProvider = Provider<GuestModeRepository>((ref) {
  return GuestModeRepository();
});

class GuestModeState {
  const GuestModeState({
    this.isGuest = false,
    this.onboardingComplete = false,
    this.initialized = false,
  });

  final bool isGuest;
  final bool onboardingComplete;
  final bool initialized;

  bool get hasEnteredApp => onboardingComplete || isGuest;

  GuestModeState copyWith({
    bool? isGuest,
    bool? onboardingComplete,
    bool? initialized,
  }) {
    return GuestModeState(
      isGuest: isGuest ?? this.isGuest,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      initialized: initialized ?? this.initialized,
    );
  }
}

final guestModeProvider = NotifierProvider<GuestModeNotifier, GuestModeState>(
  GuestModeNotifier.new,
);

class GuestModeNotifier extends Notifier<GuestModeState> {
  late final GuestModeRepository _repository;

  @override
  GuestModeState build() {
    _repository = ref.read(guestModeRepositoryProvider);
    _load();
    return const GuestModeState();
  }

  Future<void> _load() async {
    final isGuest = await _repository.isGuestMode();
    final onboardingComplete = await _repository.isOnboardingComplete();
    state = GuestModeState(
      isGuest: isGuest,
      onboardingComplete: onboardingComplete,
      initialized: true,
    );
  }

  Future<void> enterGuestMode({bool trackAnalytics = true}) async {
    await _repository.setGuestMode(true);
    await _repository.setOnboardingComplete(true);
    state = state.copyWith(isGuest: true, onboardingComplete: true);

    if (trackAnalytics) {
      final analytics = ref.read(analyticsServiceProvider).asData?.value;
      await analytics?.track(const AnalyticsEvent(AnalyticsEvents.guestModeEntered));
    }
    ref.read(appRouterRefreshProvider).notify();
  }

  Future<void> markOnboardingComplete() async {
    await _repository.setOnboardingComplete(true);
    state = state.copyWith(onboardingComplete: true);
    ref.read(appRouterRefreshProvider).notify();
  }

  Future<void> clearGuestMode() async {
    await _repository.setGuestMode(false);
    state = state.copyWith(isGuest: false);
    ref.read(appRouterRefreshProvider).notify();
  }
}
