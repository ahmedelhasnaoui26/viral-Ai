import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_env.dart';
import '../core/monetization/revenuecat_service.dart';
import '../core/notifications/push_notification_service.dart';
import 'viral_app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppEnv.isConfigured) {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  await Firebase.initializeApp();
  try {
    await PushNotificationService().initialize();
  } catch (error, stackTrace) {
    debugPrint('Push notification setup failed: $error');
    if (kDebugMode) {
      debugPrint('$stackTrace');
    }
  }
  await RevenueCatService.instance.initialize();

  if (AppEnv.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) => options.dsn = AppEnv.sentryDsn,
      appRunner: () => runZonedGuarded(
        () => runApp(const ProviderScope(child: ViralApp())),
        (error, stack) => Sentry.captureException(error, stackTrace: stack),
      ),
    );
    return;
  }

  runApp(const ProviderScope(child: ViralApp()));
}
