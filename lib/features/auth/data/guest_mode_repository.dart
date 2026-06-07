import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GuestModeRepository {
  GuestModeRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _guestModeKey = 'guest_mode_active';
  static const _onboardingCompleteKey = 'onboarding_complete';

  Future<bool> isGuestMode() async {
    final value = await _storage.read(key: _guestModeKey);
    return value == 'true';
  }

  Future<void> setGuestMode(bool active) async {
    if (active) {
      await _storage.write(key: _guestModeKey, value: 'true');
    } else {
      await _storage.delete(key: _guestModeKey);
    }
  }

  Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: _onboardingCompleteKey);
    return value == 'true';
  }

  Future<void> setOnboardingComplete(bool complete) async {
    if (complete) {
      await _storage.write(key: _onboardingCompleteKey, value: 'true');
    } else {
      await _storage.delete(key: _onboardingCompleteKey);
    }
  }
}
