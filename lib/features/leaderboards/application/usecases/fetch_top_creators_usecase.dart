import '../../domain/leaderboard_entry.dart';
import '../../domain/leaderboards_repository.dart';

class FetchTopCreatorsUseCase {
  FetchTopCreatorsUseCase(this._repository);

  final LeaderboardsRepository _repository;

  Future<List<LeaderboardEntry>> call() => _repository.fetchTopCreators();
}
