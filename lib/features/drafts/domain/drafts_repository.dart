import 'draft_generation.dart';

abstract class DraftsRepository {
  Future<List<DraftGeneration>> fetchDrafts(String userId);
  Future<DraftGeneration> saveDraft({
    required String userId,
    String? imageUrl,
    required String prompt,
    required String style,
    required int duration,
    String? templateId,
  });
  Future<void> deleteDraft(String draftId);
}
