import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/viral_layout.dart';
import '../../../core/theme/viral_design_tokens.dart';
import '../../../core/utils/format_count.dart';
import '../../auth/application/app_access_provider.dart';
import '../../credits/application/credits_providers.dart';
import '../../../shared/widgets/viral_gradient_button.dart';
import '../../../shared/widgets/viral_ui_widgets.dart';
import '../../drafts/application/drafts_providers.dart';
import '../../drafts/domain/draft_generation.dart';
import '../../social/presentation/follow_list_screen.dart';
import '../application/profile_providers.dart';
import '../domain/profile_models.dart';

enum _ProfileTab { videos, saved, drafts, templates }

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  _ProfileTab _tab = _ProfileTab.videos;

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(isGuestProvider);
    final isPro = ref.watch(isProMemberProvider);
    final bottomInset = ViralLayout.scrollPaddingAboveBottomNav(context);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final statsAsync = ref.watch(currentUserStatsProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 12, ViralTokens.paddingH, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const ViralGradientText('Profile', fontSize: 28),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: ViralTokens.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings_outlined, color: ViralTokens.textPrimary, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 24, ViralTokens.paddingH, 0),
          sliver: SliverToBoxAdapter(
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load profile'),
              data: (profile) {
                final stats = statsAsync.value ?? ProfileStats.empty;
                final handle = isGuest
                    ? '@guest'
                    : (profile?.handle.isNotEmpty == true
                        ? profile!.handle
                        : '@yourcreations');
                return Column(
                  children: [
                    _Avatar(avatarUrl: profile?.avatarUrl, showProBadge: !isGuest && isPro),
                    const SizedBox(height: 14),
                    Text(
                      isGuest ? 'Guest' : (profile?.displayLabel ?? 'You'),
                      style: const TextStyle(
                        color: ViralTokens.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(handle, style: const TextStyle(color: ViralTokens.textSecondary, fontSize: 15)),
                    if (!isGuest && (profile?.bio.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 8),
                      Text(
                        profile!.bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: ViralTokens.textMuted, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _StatColumn(
                          value: isGuest ? '—' : formatCompactCount(stats.videoCount),
                          label: 'Videos',
                        ),
                        _StatColumn(
                          value: isGuest ? '—' : formatCompactCount(stats.totalViews),
                          label: 'Views',
                        ),
                        _StatColumn(
                          value: isGuest ? '—' : formatCompactCount(stats.totalLikes),
                          label: 'Likes',
                        ),
                      ],
                    ),
                    if (!isGuest) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                final uid = profile?.id;
                                if (uid == null) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => FollowListScreen(
                                      userId: uid,
                                      type: FollowListType.followers,
                                    ),
                                  ),
                                );
                              },
                              child: _StatColumn(
                                value: formatCompactCount(stats.followersCount),
                                label: 'Followers',
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                final uid = profile?.id;
                                if (uid == null) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => FollowListScreen(
                                      userId: uid,
                                      type: FollowListType.following,
                                    ),
                                  ),
                                );
                              },
                              child: _StatColumn(
                                value: formatCompactCount(stats.followingCount),
                                label: 'Following',
                              ),
                            ),
                          ),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (!isGuest && !isPro)
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 44,
                              child: ViralGradientButton(
                                label: 'Upgrade to Pro',
                                icon: Icons.workspace_premium,
                                height: 44,
                                showGlow: false,
                                onPressed: () => context.push('/paywall'),
                              ),
                            ),
                          ),
                        if (!isGuest && !isPro) const SizedBox(width: 10),
                        Expanded(
                          flex: !isGuest && !isPro ? 2 : 1,
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: isGuest
                                  ? null
                                  : () => context.push('/account-settings'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: ViralTokens.surface,
                                foregroundColor: ViralTokens.textPrimary,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: const Text(
                                'Edit Profile',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 24, ViralTokens.paddingH, 0),
          sliver: SliverToBoxAdapter(
            child: _ProfileTabBar(tab: _tab, onChanged: (t) => setState(() => _tab = t)),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(ViralTokens.paddingH, 16, ViralTokens.paddingH, bottomInset),
          sliver: SliverToBoxAdapter(child: _buildTabBody(context, isGuest)),
        ),
      ],
    );
  }

  void _openVideo(BuildContext context, ProfileVideoItem video) {
    if (video.videoUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This video is no longer available.')),
      );
      return;
    }
    final params = {
      'videoUrl': video.videoUrl,
      if (video.generationJobId != null) 'jobId': video.generationJobId!,
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    context.push('/watch?$query');
  }

  Widget _buildTabBody(BuildContext context, bool isGuest) {
    if (isGuest) {
      return _ProfileEmptyState(
        icon: Icons.person_outline,
        title: 'Sign in to view your profile',
        subtitle: 'Publish videos, save favorites, and track your stats',
        buttonLabel: 'Sign In',
        onPressed: () => context.push('/auth'),
      );
    }

    switch (_tab) {
      case _ProfileTab.videos:
        final videosAsync = ref.watch(currentUserVideosProvider);
        return videosAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (e, _) => Text('Failed to load videos: $e'),
          data: (videos) {
            if (videos.isEmpty) {
              return _ProfileEmptyState(
                icon: Icons.grid_view_rounded,
                title: 'No videos yet',
                subtitle: 'Publish your first video to the community',
                buttonLabel: 'Create Video',
                onPressed: () => context.go('/create'),
              );
            }
            return _VideoGrid(
              videos: videos,
              onVideoTap: (video) => _openVideo(context, video),
            );
          },
        );
      case _ProfileTab.saved:
        final savedAsync = ref.watch(currentUserSavedVideosProvider);
        return savedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Failed to load saved: $e'),
          data: (videos) {
            if (videos.isEmpty) {
              return _ProfileEmptyState(
                icon: Icons.bookmark_border,
                title: 'No saved videos',
                subtitle: 'Save videos from the feed to watch later',
                buttonLabel: 'Explore Feed',
                onPressed: () => context.go('/feed'),
              );
            }
            return _VideoGrid(
              videos: videos,
              onVideoTap: (video) => _openVideo(context, video),
            );
          },
        );
      case _ProfileTab.drafts:
        final draftsAsync = ref.watch(currentUserDraftsProvider);
        return draftsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Failed to load drafts: $e'),
          data: (drafts) {
            if (drafts.isEmpty) {
              return _ProfileEmptyState(
                icon: Icons.description_outlined,
                title: 'No drafts',
                subtitle: 'Save a draft from Create to resume later',
                buttonLabel: 'Create Video',
                onPressed: () => context.go('/create'),
              );
            }
            return Column(
              children: drafts.map((draft) => _DraftRow(draft: draft)).toList(),
            );
          },
        );
      case _ProfileTab.templates:
        final templatesAsync = ref.watch(currentUserTemplatesProvider);
        return Column(
          children: [
            GestureDetector(
              onTap: () => context.push('/creator-dashboard'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ViralTokens.surface,
                  borderRadius: BorderRadius.circular(ViralTokens.radiusLg),
                ),
                child: templatesAsync.when(
                  loading: () => const Text('Loading dashboard...'),
                  error: (_, __) => const Text('Creator Dashboard'),
                  data: (templates) => Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.show_chart, color: Color(0xFFA78BFA), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Creator Dashboard',
                              style: TextStyle(
                                color: ViralTokens.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'View analytics & insights',
                              style: TextStyle(color: ViralTokens.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${templates.length}',
                            style: const TextStyle(
                              color: ViralTokens.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Templates',
                            style: TextStyle(color: ViralTokens.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      const Icon(Icons.chevron_right, color: ViralTokens.textMuted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            templatesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Failed to load templates: $e'),
              data: (templates) {
                if (templates.isEmpty) {
                  return _ProfileEmptyState(
                    icon: Icons.play_circle_outline,
                    title: 'No published templates',
                    subtitle: 'Publish a template after creating a video',
                    buttonLabel: 'Create Video',
                    onPressed: () => context.go('/create'),
                  );
                }
                return Column(
                  children: templates.map((t) {
                    return ListTile(
                      title: Text(t.title, style: const TextStyle(color: ViralTokens.textPrimary)),
                      subtitle: Text(
                        '${formatCompactCount(t.usesCount)} uses',
                        style: const TextStyle(color: ViralTokens.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: ViralTokens.textMuted),
                      onTap: () => context.push('/template/${t.id}'),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.avatarUrl, this.showProBadge = false});

  final String? avatarUrl;
  final bool showProBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: ViralTokens.surface,
          backgroundImage: avatarUrl != null && avatarUrl!.startsWith('http')
              ? NetworkImage(avatarUrl!)
              : null,
          child: avatarUrl == null || !avatarUrl!.startsWith('http')
              ? const Icon(Icons.person, size: 48, color: ViralTokens.textPrimary)
              : null,
        ),
        if (showProBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFEC4899),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium, color: ViralTokens.textPrimary, size: 14),
            ),
          ),
      ],
    );
  }
}

class _VideoGrid extends StatelessWidget {
  const _VideoGrid({
    required this.videos,
    this.onVideoTap,
  });

  final List<ProfileVideoItem> videos;
  final ValueChanged<ProfileVideoItem>? onVideoTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.62,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return GestureDetector(
          onTap: onVideoTap != null ? () => onVideoTap!(video) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ViralTokens.radiusSm),
            child: Stack(
              fit: StackFit.expand,
              children: [
              if (video.thumbnailUrl != null && video.thumbnailUrl!.startsWith('http'))
                Image.network(video.thumbnailUrl!, fit: BoxFit.cover)
              else
                Container(color: ViralTokens.surface),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: ViralTokens.textPrimary, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      formatCompactCount(video.viewsCount),
                      style: const TextStyle(
                        color: ViralTokens.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({required this.tab, required this.onChanged});

  final _ProfileTab tab;
  final ValueChanged<_ProfileTab> onChanged;

  static const _tabs = [
    (_ProfileTab.videos, Icons.grid_view_rounded, 'Videos'),
    (_ProfileTab.saved, Icons.bookmark_border, 'Saved'),
    (_ProfileTab.drafts, Icons.description_outlined, 'Drafts'),
    (_ProfileTab.templates, Icons.play_circle_outline, 'Templates'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _tabs.map((entry) {
        final selected = tab == entry.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(entry.$1),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Icon(
                  entry.$2,
                  color: selected ? ViralTokens.textPrimary : ViralTokens.inactiveNav,
                  size: 22,
                ),
                const SizedBox(height: 6),
                Text(
                  entry.$3,
                  style: TextStyle(
                    color: selected ? ViralTokens.textPrimary : ViralTokens.inactiveNav,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: selected ? 32 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA855F7),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: ViralTokens.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: ViralTokens.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DraftRow extends ConsumerWidget {
  const _DraftRow({required this.draft});

  final DraftGeneration draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ViralTokens.surface,
        borderRadius: BorderRadius.circular(ViralTokens.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.prompt.isNotEmpty ? draft.prompt : 'Untitled draft',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ViralTokens.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${draft.style} · ${draft.duration}s',
                  style: const TextStyle(color: ViralTokens.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go('/create?draftId=${draft.id}'),
            child: const Text('Resume'),
          ),
          IconButton(
            onPressed: () async {
              await ref.read(deleteDraftUseCaseProvider).call(draft.id);
              ref.invalidate(currentUserDraftsProvider);
            },
            icon: const Icon(Icons.delete_outline, color: ViralTokens.textMuted, size: 20),
          ),
        ],
      ),
    );
  }
}

class _ProfileEmptyState extends StatelessWidget {
  const _ProfileEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 56, color: ViralTokens.textDim),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: ViralTokens.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ViralTokens.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: ViralGradientButton(label: buttonLabel, height: 48, onPressed: onPressed),
          ),
        ],
      ),
    );
  }
}
