import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/analytics/analytics_event.dart';
import '../core/di/providers.dart';
import '../core/network/connectivity_provider.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/application/guest_mode_provider.dart';
import 'router/app_router.dart';

class ViralApp extends ConsumerWidget {
  const ViralApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authSessionProvider, (previous, next) {
      final user = next.asData?.value;
      final wasSignedIn = previous?.asData?.value != null;
      if (user != null && !wasSignedIn) {
        ref.read(guestModeProvider.notifier).clearGuestMode();
        final analytics = ref.read(analyticsServiceProvider).asData?.value;
        analytics?.track(const AnalyticsEvent(AnalyticsEvents.signInSuccess));
        analytics?.identify(user.id);
      }
    });

    ref.listen(authChangeEventProvider, (previous, next) {
      final event = next.asData?.value;
      if (event == AuthChangeEvent.passwordRecovery) {
        ref.read(appRouterProvider).go('/reset-password');
      }
    });

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Viral AI Video',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        final online = ref.watch(connectivityProvider).asData?.value ?? true;
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (!online)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ColoredBox(
                  color: Colors.orange,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Text(
                        'Offline mode: actions will retry automatically',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
