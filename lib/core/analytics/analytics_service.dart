import 'analytics_event.dart';

abstract class AnalyticsService {
  Future<void> identify(String userId);
  Future<void> track(AnalyticsEvent event);
}
