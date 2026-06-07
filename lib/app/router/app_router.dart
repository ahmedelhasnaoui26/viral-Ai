import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/auth_redirect_config.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/application/guest_mode_provider.dart';
import '../../features/auth/presentation/screens/delete_account_screen.dart';
import '../../features/auth/presentation/screens/privacy_policy_screen.dart';
import '../../features/auth/presentation/screens/create_account_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/terms_screen.dart';
import '../../features/feed/presentation/video_preview_screen.dart';
import '../../features/generation/presentation/generation_screen.dart';
import '../../features/generation/presentation/video_result_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/paywall/presentation/paywall_screen.dart';
import '../../features/shell/presentation/main_shell_screen.dart';
import '../../features/profile/presentation/account_settings_screen.dart';
import '../../features/profile/presentation/creator_dashboard_screen.dart';
import '../../features/leaderboards/presentation/leaderboards_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/templates/presentation/template_details_screen.dart';
import 'app_router_refresh.dart';
import 'router_refresh_notifier.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorExploreKey = GlobalKey<NavigatorState>(debugLabel: 'explore');
final _shellNavigatorCreateKey = GlobalKey<NavigatorState>(debugLabel: 'create');
final _shellNavigatorFeedKey = GlobalKey<NavigatorState>(debugLabel: 'feed');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateStream = ref.watch(authServiceProvider).authStateChanges;
  final authRefresh = RouterRefreshNotifier(authStateStream);
  final guestRefresh = ref.watch(appRouterRefreshProvider);

  void onSessionChange() {
    authRefresh.refresh();
    guestRefresh.notify();
  }

  ref.listen(authSessionProvider, (_, _) => onSessionChange());
  ref.listen(guestModeProvider, (_, _) => onSessionChange());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/onboarding',
    refreshListenable: Listenable.merge([authRefresh, guestRefresh]),
    redirect: (context, state) {
      if (AuthRedirectConfig.isPasswordRecoveryCallback(state.uri)) {
        return '/reset-password';
      }

      // OAuth deep link — Supabase handles the ?code= via app_links; do not route it.
      if (AuthRedirectConfig.isOAuthCallback(state.uri) ||
          AuthRedirectConfig.isOAuthCallbackLocation(state.uri.toString()) ||
          AuthRedirectConfig.isOAuthCallbackLocation(state.matchedLocation)) {
        // Supabase exchanges ?code= via app_links; never route the deep link URL.
        return '/home';
      }

      if (AuthRedirectConfig.isEmailAuthCallback(state.uri)) {
        return '/auth';
      }

      final guestState = ref.read(guestModeProvider);
      if (!guestState.initialized) return null;

      final isSignedIn = ref.read(authServiceProvider).currentUser != null;
      final location = state.matchedLocation;
      final hasEnteredApp = isSignedIn || guestState.hasEnteredApp;

      const publicRoutes = {
        '/onboarding',
        '/auth',
        '/auth/sign-up',
        '/auth/forgot-password',
        '/reset-password',
        '/privacy',
        '/terms',
        '/delete-account',
      };

      if (isSignedIn) {
        if (location == '/onboarding') return '/home';
        if (location == '/auth' ||
            location == '/auth/sign-up' ||
            location == '/auth/forgot-password') {
          return '/home';
        }
        return null;
      }

      if (!hasEnteredApp) {
        if (!publicRoutes.contains(location)) {
          return '/onboarding';
        }
        return null;
      }

      // Guest or onboarding-complete user: never force /auth
      if (location == '/onboarding') {
        return '/home';
      }
      return null;
    },
    onException: (context, state, router) {
      if (AuthRedirectConfig.isPasswordRecoveryCallback(state.uri)) {
        router.go('/reset-password');
        return;
      }
      if (AuthRedirectConfig.isOAuthCallback(state.uri) ||
          AuthRedirectConfig.isOAuthCallbackLocation(state.uri.toString())) {
        router.go('/home');
        return;
      }
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, _) => const SignInScreen(),
        routes: [
          GoRoute(
            path: 'sign-up',
            builder: (_, _) => const CreateAccountScreen(),
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (_, _) => const ForgotPasswordScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, _) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (_, _) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, _) => const TermsScreen(),
      ),
      GoRoute(
        path: '/delete-account',
        builder: (_, _) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: '/paywall',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/creator-dashboard',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const CreatorDashboardScreen(),
      ),
      GoRoute(
        path: '/account-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: '/leaderboards',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const LeaderboardsScreen(),
      ),
      GoRoute(
        path: '/generate',
        redirect: (_, __) => '/create',
      ),
      GoRoute(
        path: '/result',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final videoUrl = state.uri.queryParameters['videoUrl'] ?? '';
          return VideoResultScreen(
            videoUrl: videoUrl,
            generationJobId: state.uri.queryParameters['jobId'] ?? '',
            templateId: state.uri.queryParameters['templateId'],
            prompt: state.uri.queryParameters['prompt'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/watch',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final encoded = state.uri.queryParameters['videoUrl'] ?? '';
          final jobId = state.uri.queryParameters['jobId'];
          return VideoPreviewScreen(
            videoUrl: Uri.decodeComponent(encoded),
            jobId: jobId,
          );
        },
      ),
      GoRoute(
        path: '/template/:templateId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => TemplateDetailsScreen(
          templateId: state.pathParameters['templateId'] ?? '',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const HomeBranchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorExploreKey,
            routes: [
              GoRoute(
                path: '/explore',
                builder: (_, _) => const ExploreBranchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCreateKey,
            routes: [
              GoRoute(
                path: '/create',
                builder: (_, state) => GenerationScreen(
                      templateId: state.uri.queryParameters['templateId'],
                      draftId: state.uri.queryParameters['draftId'],
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorFeedKey,
            routes: [
              GoRoute(
                path: '/feed',
                builder: (_, _) => const FeedBranchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileBranchScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
