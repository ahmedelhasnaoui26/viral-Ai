abstract class ReportsRepository {
  Future<void> submitReport({
    required String targetType,
    required String targetId,
    required String reason,
  });
}
