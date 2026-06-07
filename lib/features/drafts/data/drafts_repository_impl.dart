import '../domain/draft_generation.dart';
import '../domain/drafts_repository.dart';
import 'supabase_drafts_datasource.dart';

class DraftsRepositoryImpl implements DraftsRepository {
  DraftsRepositoryImpl(this._dataSource);

  final SupabaseDraftsDataSource _dataSource;

  @override
  Future<List<DraftGeneration>> fetchDrafts(String userId) async {
    final rows = await _dataSource.fetchRows(userId);
    return rows.map(DraftGeneration.fromMap).toList();
  }

  @override
  Future<DraftGeneration> saveDraft({
    required String userId,
    String? imageUrl,
    required String prompt,
    required String style,
    required int duration,
    String? templateId,
  }) async {
    final row = await _dataSource.insertDraft({
      'user_id': userId,
      'image_url': imageUrl,
      'prompt': prompt,
      'style': style,
      'duration': duration,
      'template_id': templateId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return DraftGeneration.fromMap(row);
  }

  @override
  Future<void> deleteDraft(String draftId) async {
    await _dataSource.deleteRow(draftId);
  }
}
