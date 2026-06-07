import 'dart:async';

import '../errors/app_failure.dart';

class RetryExecutor {
  const RetryExecutor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 300),
  });

  final int maxRetries;
  final Duration baseDelay;

  Future<T> run<T>(Future<T> Function() task) async {
    Object? lastError;
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await task();
      } catch (error) {
        lastError = error;
        if (attempt < maxRetries - 1) {
          final delay = baseDelay * (attempt + 1);
          await Future<void>.delayed(delay);
        }
      }
    }
    throw AppFailure('Request failed after retries: $lastError');
  }
}
