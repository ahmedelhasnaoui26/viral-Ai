import 'leaderboard_entry.dart';

abstract class LeaderboardsRepository {
  Future<List<LeaderboardEntry>> fetchTopCreators();
  Future<List<LeaderboardEntry>> fetchTopVideos();
  Future<List<LeaderboardEntry>> fetchTopTemplates();
}
