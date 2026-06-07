import '../domain/leaderboard_entry.dart';
import '../domain/leaderboards_repository.dart';
import 'supabase_leaderboards_datasource.dart';

class LeaderboardsRepositoryImpl implements LeaderboardsRepository {
  LeaderboardsRepositoryImpl(this._dataSource);

  final SupabaseLeaderboardsDataSource _dataSource;

  @override
  Future<List<LeaderboardEntry>> fetchTopVideos() async {
    final rows = await _dataSource.topVideos();
    return rows.map((r) {
      final views = (r['views_count'] as num?)?.toInt() ?? 0;
      final likes = (r['likes_count'] as num?)?.toInt() ?? 0;
      final shares = (r['shares_count'] as num?)?.toInt() ?? 0;
      return LeaderboardEntry(
        id: r['id'] as String,
        title: (r['caption'] as String?)?.trim().isNotEmpty == true
            ? (r['caption'] as String)
            : 'Video',
        subtitle: r['creator_handle'] as String? ?? '',
        score: views + likes + shares,
        thumbnailUrl: r['thumbnail_url'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<LeaderboardEntry>> fetchTopTemplates() async {
    final rows = await _dataSource.topTemplates();
    return rows.map((r) {
      return LeaderboardEntry(
        id: r['id'] as String,
        title: r['title'] as String? ?? 'Template',
        subtitle: '${r['uses_count'] ?? 0} uses',
        score: (r['uses_count'] as num?)?.toInt() ?? 0,
        thumbnailUrl: r['thumbnail_url'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<LeaderboardEntry>> fetchTopCreators() async {
    final rows = await _dataSource.feedForCreators();
    final scores = <String, int>{};
    final handles = <String, String>{};
    for (final r in rows) {
      final id = r['creator_id'] as String?;
      if (id == null) continue;
      final views = (r['views_count'] as num?)?.toInt() ?? 0;
      final likes = (r['likes_count'] as num?)?.toInt() ?? 0;
      final shares = (r['shares_count'] as num?)?.toInt() ?? 0;
      scores[id] = (scores[id] ?? 0) + views + likes + shares;
      handles[id] = r['creator_handle'] as String? ?? '';
    }

    final sorted = scores.keys.toList()..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    final top = sorted.take(20).toList();
    final profiles = await _dataSource.profilesByIds(top);
    final profileById = {for (final p in profiles) p['id'] as String: p};

    return top.map((id) {
      final profile = profileById[id];
      final display = profile?['display_name'] as String?;
      final handle = profile?['handle'] as String? ?? handles[id] ?? '';
      return LeaderboardEntry(
        id: id,
        title: (display?.trim().isNotEmpty == true) ? display! : handle,
        subtitle: handle,
        score: scores[id] ?? 0,
        thumbnailUrl: profile?['avatar_url'] as String?,
      );
    }).toList();
  }
}
