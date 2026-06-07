import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../core/di/providers.dart';
import '../../../core/media/video_playback_loader.dart';
import '../../../core/theme/viral_design_tokens.dart';
import '../../../core/utils/creator_display.dart';
import '../../../core/utils/video_url_resolver.dart';
import '../../../shared/widgets/viral_gradient_button.dart';
import '../../auth/application/auth_gate.dart';
import '../../auth/domain/auth_gated_action.dart';
import '../../comments/presentation/comments_sheet.dart';
import '../../reports/presentation/report_sheet.dart';
import '../application/feed_providers.dart';
import '../domain/feed_item.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _pageController = PageController();
  final Map<String, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<VideoPlayerController> _controllerFor(FeedItem item) async {
    final existing = _controllers[item.id];
    if (existing != null) return existing;

    final file = await loadVideoFile(ref, item.videoUrl);
    final controller = VideoPlayerController.file(File(file.path));
    await controller.initialize();
    controller.setLooping(true);
    _controllers[item.id] = controller;
    return controller;
  }

  void _setActive(int index, List<FeedItem> items) {
    _currentIndex = index;
    for (final entry in _controllers.entries) {
      final itemIndex = items.indexWhere((it) => it.id == entry.key);
      if (itemIndex == index) {
        entry.value.play();
      } else {
        entry.value.pause();
      }
    }
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static Future<void> _shareFeedItem(
    BuildContext context,
    WidgetRef ref,
    FeedItem item,
  ) async {
    HapticFeedback.lightImpact();
    try {
      final shareUrl = await resolveVideoPlayUrl(ref, item.videoUrl);
      final caption = item.caption.trim();
      final message = caption.isNotEmpty
          ? 'Check out this video on CineMorph AI!\n\n$caption\n\n$shareUrl'
          : 'Check out this video on CineMorph AI!\n\n$shareUrl';

      await Share.share(message, subject: 'CineMorph AI Video');

      final analytics = ref.read(analyticsServiceProvider).asData?.value;
      await analytics?.track(const AnalyticsEvent(AnalyticsEvents.shareTapped));

      await ref.read(feedControllerProvider.notifier).recordShare(item.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedControllerProvider);
    return feed.when(
      loading: () => DecoratedBox(
        decoration: const BoxDecoration(gradient: ViralTokens.feedBackgroundGradient),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Center(child: Text('Failed to load feed: $error')),
      data: (items) {
        if (items.isEmpty) {
          return DecoratedBox(
            decoration: const BoxDecoration(gradient: ViralTokens.feedBackgroundGradient),
            child: const Center(
              child: Text(
                'No public videos yet.\nCreate and publish the first one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ViralTokens.textPrimary, fontSize: 16),
              ),
            ),
          );
        }
        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: (index) async {
            HapticFeedback.selectionClick();
            _setActive(index, items);
            ref.read(feedControllerProvider.notifier).recordView(items[index].id);
            await ref.read(feedControllerProvider.notifier).prefetch(index + 1);
            if (!mounted) return;
            setState(() {});
          },
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return FutureBuilder<VideoPlayerController>(
              future: _controllerFor(item),
              builder: (context, snapshot) {
                final controller = snapshot.data;
                if (controller != null && controller.value.isInitialized) {
                  if (index == _currentIndex && !controller.value.isPlaying) {
                    controller.play();
                  }
                }
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (controller != null && controller.value.isInitialized)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      )
                    else
                      const DecoratedBox(
                        decoration: BoxDecoration(gradient: ViralTokens.feedBackgroundGradient),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.5, 0.75, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 100,
                      child: Column(
                        children: [
                          _FeedActionButton(
                            icon: Icons.flag_outlined,
                            onTap: () => showReportSheet(
                              context: context,
                              ref: ref,
                              targetType: 'video',
                              targetId: item.id,
                            ),
                          ),
                          _FeedActionButton(
                            icon: item.liked ? Icons.favorite : Icons.favorite_border,
                            label: _formatCount(item.likesCount),
                            onTap: () async {
                              final allowed = await requireAuthentication(
                                context,
                                ref,
                                action: AuthGatedAction.profileFeatures,
                              );
                              if (!context.mounted || !allowed) return;
                              HapticFeedback.mediumImpact();
                              ref.read(feedControllerProvider.notifier).toggleLike(item.id);
                            },
                          ),
                          _FeedActionButton(
                            icon: Icons.chat_bubble_outline,
                            label: _formatCount(item.commentsCount),
                            onTap: () => showCommentsSheet(
                              context: context,
                              ref: ref,
                              feedItemId: item.id,
                              videoOwnerId: item.userId,
                              initialCount: item.commentsCount,
                            ),
                          ),
                          _FeedActionButton(
                            icon: Icons.share_outlined,
                            label: _formatCount(item.sharesCount),
                            onTap: () => _shareFeedItem(context, ref, item),
                          ),
                          _FeedActionButton(
                            icon: item.saved ? Icons.bookmark : Icons.bookmark_border,
                            onTap: () async {
                              final allowed = await requireAuthentication(
                                context,
                                ref,
                                action: AuthGatedAction.saveToLibrary,
                              );
                              if (!context.mounted || !allowed) return;
                              ref.read(feedControllerProvider.notifier).toggleSave(item.id);
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 80,
                      bottom: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: ViralTokens.surface,
                                child: Text(
                                  item.creatorDisplayName.isNotEmpty
                                      ? item.creatorDisplayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: ViralTokens.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.creatorDisplayName,
                                      style: const TextStyle(
                                        color: ViralTokens.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (CreatorDisplay.subtitleHandle(
                                          displayName: item.creatorDisplayName,
                                          handle: item.creatorHandle,
                                        ) !=
                                        null)
                                      Text(
                                        CreatorDisplay.subtitleHandle(
                                          displayName: item.creatorDisplayName,
                                          handle: item.creatorHandle,
                                        )!,
                                        style: const TextStyle(
                                          color: ViralTokens.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (item.userId.isNotEmpty)
                                SizedBox(
                                  width: 88,
                                  height: 32,
                                  child: ViralGradientButton(
                                    label: item.followingCreator ? 'Following' : 'Follow',
                                    height: 32,
                                    showGlow: false,
                                    onPressed: () async {
                                      final allowed = await requireAuthentication(
                                        context,
                                        ref,
                                        action: AuthGatedAction.profileFeatures,
                                      );
                                      if (!context.mounted || !allowed) return;
                                      await ref
                                          .read(feedControllerProvider.notifier)
                                          .toggleFollow(item.userId);
                                    },
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.caption,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ViralTokens.textPrimary,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                          if (item.templateId != null) ...[
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () => context.push('/template/${item.templateId}'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shuffle, color: ViralTokens.textPrimary, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Use Template',
                                      style: TextStyle(
                                        color: ViralTokens.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FeedActionButton extends StatelessWidget {
  const _FeedActionButton({
    required this.icon,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: ViralTokens.textPrimary, size: 26),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label!,
              style: const TextStyle(
                color: ViralTokens.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
