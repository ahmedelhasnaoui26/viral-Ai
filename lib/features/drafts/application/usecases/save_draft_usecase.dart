import '../../domain/draft_generation.dart';
import '../../domain/drafts_repository.dart';

class SaveDraftUseCase {
  SaveDraftUseCase(this._repository);

  final DraftsRepository _repository;

  Future<DraftGeneration> call({
    required String userId,
    String? imageUrl,
    required String prompt,
    required String style,
    required int duration,
    String? templateId,
  }) =>
      _repository.saveDraft(
        userId: userId,
        imageUrl: imageUrl,
        prompt: prompt,
        style: style,
        duration: duration,
        templateId: templateId,
      );
}
