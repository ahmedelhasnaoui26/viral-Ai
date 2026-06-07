import '../../domain/draft_generation.dart';
import '../../domain/drafts_repository.dart';

class FetchDraftsUseCase {
  FetchDraftsUseCase(this._repository);

  final DraftsRepository _repository;

  Future<List<DraftGeneration>> call(String userId) => _repository.fetchDrafts(userId);
}
