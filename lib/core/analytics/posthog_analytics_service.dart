import 'package:posthog_flutter/posthog_flutter.dart';

import '../config/app_env.dart';
import 'analytics_event.dart';
import 'analytics_service.dart';

class PosthogAnalyticsService implements AnalyticsService {
  PosthogAnalyticsService._({required this.enabled});

  final bool enabled;

  static Future<PosthogAnalyticsService> create() async {
    if (AppEnv.posthogApiKey.isEmpty) {
      return PosthogAnalyticsService._(enabled: false);
    }
    final config = PostHogConfig(AppEnv.posthogApiKey);
    config.host = AppEnv.posthogHost;
    config.captureApplicationLifecycleEvents = false;
    await Posthog().setup(config);
    return PosthogAnalyticsService._(enabled: true);
  }

  @override
  Future<void> identify(String userId) async {
    if (!enabled) return;
    await Posthog().identify(userId: userId);
  }

  @override
  Future<void> track(AnalyticsEvent event) async {
    if (!enabled) return;
    await Posthog().capture(
      eventName: event.name,
      properties: Map<String, Object>.from(
        event.properties.map((key, value) => MapEntry(key, value ?? '')),
      ),
    );
  }
}
