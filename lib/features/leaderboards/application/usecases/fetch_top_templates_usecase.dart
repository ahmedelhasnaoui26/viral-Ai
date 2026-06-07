import '../../domain/leaderboard_entry.dart';
import '../../domain/leaderboards_repository.dart';

class FetchTopTemplatesUseCase {
  FetchTopTemplatesUseCase(this._repository);

  final LeaderboardsRepository _repository;

  Future<List<LeaderboardEntry>> call() => _repository.fetchTopTemplates();
}
