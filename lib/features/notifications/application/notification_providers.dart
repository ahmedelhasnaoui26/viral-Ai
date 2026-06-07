import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/notification_repository.dart';
import '../domain/notification_item.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(supabaseClientProvider));
});

final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) {
  return ref.watch(notificationRepositoryProvider).fetchNotifications();
});
