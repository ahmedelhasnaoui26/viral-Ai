import 'package:mixpanel_flutter/mixpanel_flutter.dart';

import '../config/app_env.dart';
import 'analytics_event.dart';
import 'analytics_service.dart';

class MixpanelAnalyticsService implements AnalyticsService {
  MixpanelAnalyticsService._(this._mixpanel, {required this.enabled});

  final Mixpanel _mixpanel;
  final bool enabled;

  static Future<MixpanelAnalyticsService> create() async {
    final token = AppEnv.mixpanelToken;
    if (token.isEmpty) {
      return MixpanelAnalyticsService._(_NoopMixpanel(), enabled: false);
    }
    final mixpanel = await Mixpanel.init(token, trackAutomaticEvents: false);
    return MixpanelAnalyticsService._(mixpanel, enabled: true);
  }

  @override
  Future<void> identify(String userId) async {
    if (!enabled) return;
    _mixpanel.identify(userId);
  }

  @override
  Future<void> track(AnalyticsEvent event) async {
    if (!enabled) return;
    _mixpanel.track(event.name, properties: event.properties);
  }
}

class _NoopMixpanel implements Mixpanel {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
