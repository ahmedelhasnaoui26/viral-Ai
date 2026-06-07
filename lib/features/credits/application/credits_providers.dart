import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/supabase_credits_datasource.dart';
import '../domain/user_credits.dart';

final creditsDataSourceProvider = Provider<SupabaseCreditsDataSource>((ref) {
  return SupabaseCreditsDataSource(ref.watch(supabaseClientProvider));
});

final userCreditsProvider = FutureProvider<UserCredits>((ref) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return UserCredits.empty;

  final row = await ref.watch(creditsDataSourceProvider).fetchRow(userId);
  if (row == null) return UserCredits.empty;
  return UserCredits.fromMap(row);
});

final revenueCatPremiumProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(revenueCatServiceProvider);
  await service.initialize();
  if (!service.isConfigured) return false;
  return service.isPremium();
});

/// True when the signed-in user has an active Pro subscription or plan.
final isProMemberProvider = Provider<bool>((ref) {
  final credits = ref.watch(userCreditsProvider).asData?.value;
  if (credits != null && !credits.isFree) {
    return true;
  }
  return ref.watch(revenueCatPremiumProvider).asData?.value ?? false;
});
