import '../../domain/reports_repository.dart';

class SubmitReportUseCase {
  SubmitReportUseCase(this._repository);

  final ReportsRepository _repository;

  Future<void> call({
    required String targetType,
    required String targetId,
    required String reason,
  }) =>
      _repository.submitReport(
        targetType: targetType,
        targetId: targetId,
        reason: reason,
      );
}
