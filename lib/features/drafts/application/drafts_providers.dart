import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/drafts_repository_impl.dart';
import '../data/supabase_drafts_datasource.dart';
import '../domain/draft_generation.dart';
import '../domain/drafts_repository.dart';
import 'usecases/delete_draft_usecase.dart';
import 'usecases/fetch_drafts_usecase.dart';
import 'usecases/save_draft_usecase.dart';

final draftsDataSourceProvider = Provider<SupabaseDraftsDataSource>((ref) {
  return SupabaseDraftsDataSource(ref.watch(supabaseClientProvider));
});

final draftsRepositoryProvider = Provider<DraftsRepository>((ref) {
  return DraftsRepositoryImpl(ref.watch(draftsDataSourceProvider));
});

final fetchDraftsUseCaseProvider = Provider<FetchDraftsUseCase>((ref) {
  return FetchDraftsUseCase(ref.watch(draftsRepositoryProvider));
});

final saveDraftUseCaseProvider = Provider<SaveDraftUseCase>((ref) {
  return SaveDraftUseCase(ref.watch(draftsRepositoryProvider));
});

final deleteDraftUseCaseProvider = Provider<DeleteDraftUseCase>((ref) {
  return DeleteDraftUseCase(ref.watch(draftsRepositoryProvider));
});

final currentUserDraftsProvider = FutureProvider<List<DraftGeneration>>((ref) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return [];
  return ref.watch(fetchDraftsUseCaseProvider).call(userId);
});
