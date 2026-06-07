import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static const _topics = [
    'generation_completed',
    'free_credits',
    'trending_styles',
    'reengagement',
  ];

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (Platform.isIOS) {
      final apnsToken = await _waitForApnsToken(messaging);
      if (apnsToken == null) {
        debugPrint(
          'APNS token not available yet; skipping topic subscription. '
          'Use a physical device for push, or retry after the token is set.',
        );
        return;
      }
    }

    for (final topic in _topics) {
      try {
        await messaging.subscribeToTopic(topic);
      } catch (error, stackTrace) {
        debugPrint('Failed to subscribe to topic "$topic": $error');
        if (kDebugMode) {
          debugPrint('$stackTrace');
        }
      }
    }
  }

  Future<String?> _waitForApnsToken(
    FirebaseMessaging messaging, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final token = await messaging.getAPNSToken();
      if (token != null) {
        return token;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }
}
