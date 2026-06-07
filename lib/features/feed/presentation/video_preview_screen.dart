import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/errors/function_error_message.dart';
import '../../../core/media/video_playback_loader.dart';
import '../../../core/theme/viral_design_tokens.dart';
import '../../../core/utils/video_url_resolver.dart';
import '../../../shared/widgets/viral_ui_widgets.dart';

/// Full-screen playback for feed / saved / profile videos.
class VideoPreviewScreen extends ConsumerStatefulWidget {
  const VideoPreviewScreen({
    required this.videoUrl,
    this.jobId,
    super.key,
  });

  final String videoUrl;
  final String? jobId;

  @override
  ConsumerState<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends ConsumerState<VideoPreviewScreen> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    await _controller?.dispose();
    _controller = null;

    try {
      final file = await loadVideoFile(
        ref,
        widget.videoUrl,
        jobId: widget.jobId,
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyFunctionError(e);
        _loading = false;
      });
    }
  }

  Future<void> _shareVideo() async {
    HapticFeedback.lightImpact();
    try {
      final shareUrl = await resolveVideoPlayUrl(ref, widget.videoUrl);
      await Share.share(
        'Check out this video on CineMorph AI!\n\n$shareUrl',
        subject: 'CineMorph AI Video',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share: ${friendlyFunctionError(e)}')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralTokens.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, ViralTokens.paddingH, 0),
              child: Row(
                children: [
                  ViralBackCircleButton(onPressed: () => Navigator.pop(context)),
                  const Expanded(
                    child: Text(
                      'Video',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ViralTokens.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _shareVideo,
                    icon: const Icon(Icons.share_outlined, color: ViralTokens.textPrimary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.videocam_off_outlined,
                                  color: ViralTokens.textMuted,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Could not load video',
                                  style: const TextStyle(
                                    color: ViralTokens.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: const TextStyle(color: ViralTokens.textMuted, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: _loadVideo,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try again'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _controller != null && _controller!.value.isInitialized
                          ? Center(
                              child: AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: VideoPlayer(_controller!),
                              ),
                            )
                          : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
