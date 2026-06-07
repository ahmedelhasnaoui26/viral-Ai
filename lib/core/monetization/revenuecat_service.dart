import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/app_env.dart';

/// Wraps RevenueCat. Safe to call when API keys are missing (dev / simulator).
class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  bool _configured = false;

  bool get isConfigured => _configured;

  Future<void> initialize() async {
    if (_configured) return;

    final key = Platform.isIOS
        ? AppEnv.revenueCatAppleApiKey
        : AppEnv.revenueCatGoogleApiKey;
    if (key.isEmpty) {
      debugPrint(
        'RevenueCat: skipped configure (set REVENUECAT_APPLE_API_KEY / '
        'REVENUECAT_GOOGLE_API_KEY via --dart-define)',
      );
      return;
    }

    await Purchases.setLogLevel(LogLevel.info);
    await Purchases.configure(PurchasesConfiguration(key));
    _configured = true;
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_configured) return null;
    return Purchases.getCustomerInfo();
  }

  Future<Offerings?> getOfferings() async {
    if (!_configured) return null;
    return Purchases.getOfferings();
  }

  Future<CustomerInfo?> purchase(Package package) async {
    if (!_configured) {
      throw StateError('RevenueCat is not configured');
    }
    final result = await Purchases.purchasePackage(package);
    return result.customerInfo;
  }

  Future<CustomerInfo?> restore() async {
    if (!_configured) return null;
    return Purchases.restorePurchases();
  }

  Future<bool> isPremium() async {
    final info = await getCustomerInfo();
    if (info == null) return false;
    return info.entitlements.active.containsKey('premium');
  }
}
