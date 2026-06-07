import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../core/di/providers.dart';
import '../../auth/application/auth_gate.dart';
import '../../auth/domain/auth_gated_action.dart';
import '../../../core/media/video_playback_loader.dart';
import '../../../core/theme/viral_design_tokens.dart';
import '../../../shared/widgets/viral_gradient_button.dart';
import '../../../shared/widgets/viral_ui_widgets.dart';
import '../../feed/application/feed_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../application/generation_providers.dart';

class VideoResultScreen extends ConsumerStatefulWidget {
  const VideoResultScreen({
    required this.videoUrl,
    required this.generationJobId,
    required this.prompt,
    this.templateId,
    super.key,
  });

  final String videoUrl;
  final String generationJobId;
  final String prompt;
  final String? templateId;

  @override
  ConsumerState<VideoResultScreen> createState() => _VideoResultScreenState();
}

class _VideoResultScreenState extends ConsumerState<VideoResultScreen> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _exporting = false;
  bool _posting = false;
  bool _postToCommunity = true;
  bool _publishTemplate = false;
  late final TextEditingController _captionController;
  late final TextEditingController _templateTitleController;
  late final TextEditingController _templateDescriptionController;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.prompt);
    _templateTitleController = TextEditingController();
    _templateDescriptionController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPlayer());
  }

  Future<void> _initPlayer() async {
    if (widget.videoUrl.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final file = await loadVideoFile(
        ref,
        widget.videoUrl,
        jobId: widget.generationJobId,
      );
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _captionController.dispose();
    _templateTitleController.dispose();
    _templateDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralTokens.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ViralTokens.paddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ViralGradientText('Create', fontSize: 28),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/create'),
                    child: const Text(
                      'Start Over',
                      style: TextStyle(color: ViralTokens.textSecondary, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ViralTokens.radiusXl),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _controller == null || !_controller!.value.isInitialized
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(ViralTokens.radiusXl),
                                gradient: ViralTokens.heroCardGradient,
                              ),
                              child: const Center(
                                child: Text(
                                  'No video available yet',
                                  style: TextStyle(color: ViralTokens.textSecondary),
                                ),
                              ),
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _controller!.value.size.width,
                                    height: _controller!.value.size.height,
                                    child: VideoPlayer(_controller!),
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ResultAction(
                    icon: Icons.download_outlined,
                    label: 'Download',
                    onTap: _exporting ? null : _saveToGalleryGated,
                  ),
                  _ResultAction(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: widget.videoUrl.isEmpty
                        ? null
                        : () async {
                            final allowed = await requireAuthentication(
                              context,
                              ref,
                              action: AuthGatedAction.shareVideo,
                            );
                            if (!context.mounted || !allowed) return;
                            final analytics = ref.read(analyticsServiceProvider).asData?.value;
                            await analytics?.track(
                              const AnalyticsEvent(AnalyticsEvents.shareTapped),
                            );
                            await Share.share('Check my AI video: ${widget.videoUrl}');
                          },
                  ),
                  _ResultAction(
                    icon: Icons.send_outlined,
                    label: 'Publish',
                    onTap: _posting ? null : _publishToCommunity,
                  ),
                  _ResultAction(
                    icon: Icons.shuffle,
                    label: 'Remix',
                    onTap: () => context.go('/create'),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _postToCommunity,
              onChanged: _posting ? null : (value) => setState(() => _postToCommunity = value),
              activeThumbColor: const Color(0xFFA855F7),
              title: const Text(
                'Post to Community',
                style: TextStyle(color: ViralTokens.textPrimary),
              ),
              subtitle: const Text(
                'Make your generation discoverable in Feed',
                style: TextStyle(color: ViralTokens.textMuted),
              ),
            ),
            if (_postToCommunity) ...[
              TextField(
                controller: _captionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Caption',
                  hintText: 'Tell people what this video is about',
                ),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                value: _publishTemplate,
                onChanged: _posting
                    ? null
                    : (value) => setState(() => _publishTemplate = value),
                title: const Text('Publish Template'),
                subtitle: const Text('Let other users remix your settings'),
              ),
              if (_publishTemplate) ...[
                TextField(
                  controller: _templateTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Template title',
                    hintText: 'e.g. Anime Hero Entrance',
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _templateDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Template description',
                    hintText: 'Describe this template style',
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            ViralGradientButton(
              label: 'Create Another',
              onPressed: () => context.go('/create'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _saveToGalleryGated() async {
    final allowed = await requireAuthentication(
      context,
      ref,
      action: AuthGatedAction.saveToLibrary,
    );
    if (!mounted || !allowed) return;
    await _saveToGallery();
  }

  Future<void> _saveToGallery() async {
    if (widget.videoUrl.isEmpty) return;
    setState(() => _exporting = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/viral_export_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await Dio().download(widget.videoUrl, outputPath);
      await PhotoManager.requestPermissionExtend();
      await PhotoManager.editor.saveVideo(File(outputPath));
      final analytics = ref.read(analyticsServiceProvider).asData?.value;
      await analytics?.track(const AnalyticsEvent(AnalyticsEvents.exportCompleted));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved to gallery')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _publishToCommunity() async {
    if (widget.generationJobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing generation job id.')),
      );
      return;
    }
    setState(() => _posting = true);
    try {
      final repo = ref.read(generationRepositoryProvider);
      await repo.publishGeneration(
        generationJobId: widget.generationJobId,
        postToCommunity: _postToCommunity,
        caption: _captionController.text.trim(),
        thumbnailUrl: widget.videoUrl,
        publishTemplate: _publishTemplate,
        templateTitle:
            _publishTemplate ? _templateTitleController.text.trim() : null,
        templateDescription: _publishTemplate
            ? _templateDescriptionController.text.trim()
            : null,
        templateCategory: 'Trending',
        templateIsPremium: false,
      );
      ref.invalidate(feedControllerProvider);
      ref.invalidate(currentUserVideosProvider);
      ref.invalidate(currentUserStatsProvider);
      ref.invalidate(creatorDashboardProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Published to community.')),
      );
      context.go('/feed');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publish failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _posting = false);
      }
    }
  }
}

class _ResultAction extends StatelessWidget {
  const _ResultAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: ViralTokens.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ViralTokens.textPrimary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: ViralTokens.textPrimary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
