import '../../domain/drafts_repository.dart';

class DeleteDraftUseCase {
  DeleteDraftUseCase(this._repository);

  final DraftsRepository _repository;

  Future<void> call(String draftId) => _repository.deleteDraft(draftId);
}
