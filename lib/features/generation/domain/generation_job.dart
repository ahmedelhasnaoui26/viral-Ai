/// Lifecycle of a generation job on the server.
enum GenerationStatus {
  queued,
  processing,
  archiving,
  completed,
  failed,
}

class GenerationJob {
  const GenerationJob({
    required this.id,
    required this.status,
    required this.inputObjectKey,
    this.outputObjectKey,
    this.r2VideoUrl,
    this.replicatePredictionId,
    this.errorMessage,
    this.isExtended = false,
    this.clipCount = 1,
    this.completedClips = 0,
    this.progressPercent = 0,
    this.extendPhase,
    this.targetDurationSeconds = 5,
  });

  final String id;
  final GenerationStatus status;
  final String inputObjectKey;
  final String? outputObjectKey;
  final String? r2VideoUrl;
  final String? replicatePredictionId;
  final String? errorMessage;
  final bool isExtended;
  final int clipCount;
  final int completedClips;
  final int progressPercent;
  final String? extendPhase;
  final int targetDurationSeconds;

  /// Backward-compatible alias — prefer [outputObjectKey] or [r2VideoUrl].
  String? get outputUrl => outputObjectKey ?? r2VideoUrl;

  bool get isDone =>
      status == GenerationStatus.completed || status == GenerationStatus.failed;

  bool get hasPermanentStorage =>
      outputObjectKey != null &&
      outputObjectKey!.isNotEmpty &&
      !outputObjectKey!.startsWith('http');
}
