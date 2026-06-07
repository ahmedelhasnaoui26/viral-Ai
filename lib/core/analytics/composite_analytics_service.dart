import 'analytics_event.dart';
import 'analytics_service.dart';

class CompositeAnalyticsService implements AnalyticsService {
  const CompositeAnalyticsService(this.services);

  final List<AnalyticsService> services;

  @override
  Future<void> identify(String userId) async {
    for (final service in services) {
      await service.identify(userId);
    }
  }

  @override
  Future<void> track(AnalyticsEvent event) async {
    for (final service in services) {
      await service.track(event);
    }
  }
}
