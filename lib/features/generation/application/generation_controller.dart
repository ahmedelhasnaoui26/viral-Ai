import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/errors/function_error_message.dart';
import '../data/services/video_storage_service.dart';
import '../domain/generation_job.dart';
import 'generation_providers.dart';

class GenerationState {
  const GenerationState({
    this.loading = false,
    this.job,
    this.errorMessage,
    this.statusMessage,
    this.uploadProgress = 0,
    this.progressPercent = 0,
    this.selectedStyle = 'cinematic',
    this.selectedDurationSeconds = 5,
    this.selectedImagePath,
    this.lastTemplateId,
  });

  final bool loading;
  final GenerationJob? job;
  final String? errorMessage;
  final String? statusMessage;
  final double uploadProgress;
  final int progressPercent;
  final String selectedStyle;
  final int selectedDurationSeconds;
  final String? selectedImagePath;
  final String? lastTemplateId;

  GenerationState copyWith({
    bool? loading,
    GenerationJob? job,
    String? errorMessage,
    String? statusMessage,
    bool clearStatusMessage = false,
    double? uploadProgress,
    int? progressPercent,
    String? selectedStyle,
    int? selectedDurationSeconds,
    String? selectedImagePath,
    String? lastTemplateId,
  }) {
    return GenerationState(
      loading: loading ?? this.loading,
      job: job ?? this.job,
      errorMessage: errorMessage,
      statusMessage:
          clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
      uploadProgress: uploadProgress ?? this.uploadProgress,
      progressPercent: progressPercent ?? this.progressPercent,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      selectedDurationSeconds: selectedDurationSeconds ?? this.selectedDurationSeconds,
      selectedImagePath: selectedImagePath ?? this.selectedImagePath,
      lastTemplateId: lastTemplateId ?? this.lastTemplateId,
    );
  }
}

class GenerationController extends Notifier<GenerationState> {
  late final VideoStorageService _videoStorage;
  late final AnalyticsService _analytics;
  final _picker = ImagePicker();

  @override
  GenerationState build() {
    _videoStorage = ref.read(videoStorageServiceProvider);
    _analytics = ref.read(analyticsResolvedProvider);
    return const GenerationState();
  }

  Future<void> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (file == null) return;
    state = state.copyWith(selectedImagePath: file.path, errorMessage: null);
  }

  void selectStyle(String style) {
    state = state.copyWith(selectedStyle: style);
  }

  void selectDuration(int seconds) {
    state = state.copyWith(selectedDurationSeconds: seconds);
  }

  void setImagePath(String path) {
    state = state.copyWith(selectedImagePath: path, errorMessage: null);
  }

  Future<void> generate({
    required String prompt,
    String? templateId,
  }) async {
    if (state.selectedImagePath == null) {
      state = state.copyWith(errorMessage: 'Please select an image first.');
      return;
    }
    state = state.copyWith(
      loading: true,
      errorMessage: null,
      statusMessage: 'Preparing upload…',
      uploadProgress: 0,
    );
    try {
      await _analytics.track(
        const AnalyticsEvent(AnalyticsEvents.generationStarted),
      );

      final completed = await _videoStorage.generateVideo(
        imageFile: File(state.selectedImagePath!),
        prompt: prompt,
        style: state.selectedStyle,
        durationSeconds: state.selectedDurationSeconds,
        templateId: templateId,
        onUploadProgress: (progress) {
          state = state.copyWith(
            uploadProgress: progress,
            statusMessage: 'Uploading image… ${(progress * 100).round()}%',
          );
        },
        onStatusMessage: (message) {
          state = state.copyWith(statusMessage: message);
        },
        onProgress: (percent) {
          state = state.copyWith(progressPercent: percent);
        },
      );

      state = state.copyWith(
        loading: false,
        job: completed,
        uploadProgress: 1,
        progressPercent: completed.progressPercent,
        clearStatusMessage: true,
        lastTemplateId: templateId,
      );

      if (completed.status == GenerationStatus.completed) {
        await _analytics.track(
          AnalyticsEvent(
            AnalyticsEvents.generationCompleted,
            properties: {
              'jobId': completed.id,
              'r2VideoUrl': completed.r2VideoUrl ?? '',
            },
          ),
        );
      } else {
        await _analytics.track(
          AnalyticsEvent(
            AnalyticsEvents.generationFailed,
            properties: {'jobId': completed.id, 'reason': completed.errorMessage ?? 'unknown'},
          ),
        );
      }
    } catch (error) {
      final message = error is StateError && error.message.isNotEmpty
          ? error.message
          : friendlyFunctionError(error);
      state = state.copyWith(
        loading: false,
        errorMessage: message,
        clearStatusMessage: true,
      );
      await _analytics.track(
        AnalyticsEvent(
          AnalyticsEvents.generationFailed,
          properties: {'reason': message},
        ),
      );
    }
  }
}
