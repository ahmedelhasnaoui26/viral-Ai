import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/reports_repository_impl.dart';
import '../data/supabase_reports_datasource.dart';
import '../domain/reports_repository.dart';
import 'usecases/submit_report_usecase.dart';

final reportsDataSourceProvider = Provider<SupabaseReportsDataSource>((ref) {
  return SupabaseReportsDataSource(ref.watch(supabaseClientProvider));
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(ref.watch(reportsDataSourceProvider));
});

final submitReportUseCaseProvider = Provider<SubmitReportUseCase>((ref) {
  return SubmitReportUseCase(ref.watch(reportsRepositoryProvider));
});
