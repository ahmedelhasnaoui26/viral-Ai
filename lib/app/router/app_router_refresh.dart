import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifies [GoRouter] when auth or guest session changes.
class AppRouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

final appRouterRefreshProvider = Provider<AppRouterRefresh>((ref) {
  final refresh = AppRouterRefresh();
  ref.onDispose(refresh.dispose);
  return refresh;
});
