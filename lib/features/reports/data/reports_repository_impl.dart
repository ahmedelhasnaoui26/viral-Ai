import '../domain/reports_repository.dart';
import 'supabase_reports_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._dataSource);

  final SupabaseReportsDataSource _dataSource;

  @override
  Future<void> submitReport({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    final reporterId = _dataSource.currentUserId;
    if (reporterId == null) {
      throw StateError('Sign in to report content');
    }

    final reportRow = await _dataSource.insertReport({
      'reporter_id': reporterId,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
    });

    await _dataSource.insertModerationQueue({
      'target_type': targetType,
      'target_id': targetId,
      'report_id': reportRow['id'],
      'status': 'pending',
    });
  }
}
