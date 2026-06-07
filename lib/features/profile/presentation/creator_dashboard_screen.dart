import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/viral_design_tokens.dart';
import '../../../core/utils/format_count.dart';
import '../../../shared/widgets/viral_ui_widgets.dart';
import '../application/profile_providers.dart';
import '../domain/profile_models.dart';

class CreatorDashboardScreen extends ConsumerWidget {
  const CreatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(creatorDashboardProvider);

    return Scaffold(
      backgroundColor: ViralTokens.black,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1),
            radius: 1.1,
            colors: [
              const Color(0xFF6D28D9).withValues(alpha: 0.2),
              ViralTokens.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, ViralTokens.paddingH, 0),
                child: Row(
                  children: [
                    ViralBackCircleButton(onPressed: () => context.pop()),
                    const Expanded(
                      child: Text(
                        'Creator Dashboard',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ViralTokens.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: statsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Failed to load stats: $e')),
                  data: (stats) => ListView(
                    padding: const EdgeInsets.fromLTRB(
                      ViralTokens.paddingH,
                      24,
                      ViralTokens.paddingH,
                      24,
                    ),
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.05,
                        children: [
                          _StatCard(
                            icon: Icons.visibility_outlined,
                            label: 'Total Views',
                            value: formatCompactCount(stats.totalViews),
                            iconColor: const Color(0xFFA855F7),
                          ),
                          _StatCard(
                            icon: Icons.favorite_border,
                            label: 'Total Likes',
                            value: formatCompactCount(stats.totalLikes),
                            iconColor: const Color(0xFFEC4899),
                          ),
                          _StatCard(
                            icon: Icons.share_outlined,
                            label: 'Total Shares',
                            value: formatCompactCount(stats.totalShares),
                            iconColor: const Color(0xFF3B82F6),
                          ),
                          _StatCard(
                            icon: Icons.shuffle,
                            label: 'Template Uses',
                            value: formatCompactCount(stats.templateUses),
                            iconColor: const Color(0xFF14B8A6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _MiniStat(label: 'Videos', value: '${stats.videoCount}'),
                          const SizedBox(width: 12),
                          _MiniStat(label: 'Templates', value: '${stats.templateUses}'),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Top Performing Videos',
                          style: TextStyle(
                            color: ViralTokens.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (stats.topVideos.isEmpty)
                        const Text(
                          'Publish videos to see performance here.',
                          style: TextStyle(color: ViralTokens.textSecondary),
                        )
                      else
                        ...stats.topVideos.map((v) => _TopVideoRow(video: v)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ViralTokens.surface,
        borderRadius: BorderRadius.circular(ViralTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: ViralTokens.textSecondary, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: ViralTokens.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ViralTokens.surface,
          borderRadius: BorderRadius.circular(ViralTokens.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: ViralTokens.textSecondary, fontSize: 12)),
            Text(
              value,
              style: const TextStyle(
                color: ViralTokens.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopVideoRow extends StatelessWidget {
  const _TopVideoRow({required this.video});

  final ProfileVideoItem video;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ViralTokens.surface,
        borderRadius: BorderRadius.circular(ViralTokens.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ViralTokens.cardDark,
              borderRadius: BorderRadius.circular(28),
            ),
            child: video.thumbnailUrl != null && video.thumbnailUrl!.startsWith('http')
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(video.thumbnailUrl!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.play_arrow_rounded, color: ViralTokens.textPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Video ${video.id.substring(0, 6)}',
                  style: const TextStyle(
                    color: ViralTokens.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 14, color: ViralTokens.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      formatCompactCount(video.viewsCount),
                      style: const TextStyle(color: ViralTokens.textMuted, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.favorite_border, size: 14, color: ViralTokens.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      formatCompactCount(video.likesCount),
                      style: const TextStyle(color: ViralTokens.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
