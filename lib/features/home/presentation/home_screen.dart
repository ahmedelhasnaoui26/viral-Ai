import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/viral_layout.dart';
import '../../../core/theme/viral_design_tokens.dart';
import '../../../shared/widgets/viral_gradient_card.dart';
import '../../../shared/widgets/viral_ui_widgets.dart';
import '../../feed/application/feed_providers.dart';
import '../../profile/application/profile_providers.dart';
import 'widgets/featured_creator_tile.dart';
import '../../templates/application/template_providers.dart';
import '../../templates/domain/template_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = ViralLayout.scrollPaddingAboveBottomNav(context);
    final templatesAsync = ref.watch(templatesProvider);
    final feedAsync = ref.watch(feedControllerProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 16, ViralTokens.paddingH, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const ViralBrandHeader(),
                const Spacer(),
                ViralNotificationBell(
                  onTap: () => context.push('/notifications'),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 20, ViralTokens.paddingH, 0),
          sliver: SliverToBoxAdapter(
            child: ViralHomeHeroCard(onCreateTap: () => context.go('/create')),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 28, ViralTokens.paddingH, 0),
          sliver: SliverToBoxAdapter(
            child: ViralSectionHeader(
              title: 'Trending Templates',
              trailingLabel: 'View All >',
              onTrailingTap: () => context.go('/explore'),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 14, 0, 0),
          sliver: templatesAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            ),
            error: (error, _) => SliverToBoxAdapter(child: Text('Failed to load: $error')),
            data: (templates) {
              final trending = templates.where((t) => t.isTrending).toList();
              final items = trending.isNotEmpty ? trending : templates;
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: ViralTokens.paddingH),
                    itemCount: items.take(8).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _TemplateCarouselCard(item: items[index]),
                  ),
                ),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 28, ViralTokens.paddingH, 0),
          sliver: SliverToBoxAdapter(
            child: ViralSectionHeader(
              title: 'Viral Videos',
              leadingIcon: const Icon(Icons.trending_up, color: Color(0xFFEC4899), size: 22),
              trailingLabel: 'See More >',
              onTrailingTap: () => context.go('/feed'),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 14, 0, 0),
          sliver: feedAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox(height: 48)),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (items) {
              if (items.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: ViralTokens.paddingH),
                    itemCount: items.take(6).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ViralVideoCard(
                        creator: item.creatorDisplayName,
                        views: _formatCount(item.viewsCount),
                        onTap: () => context.go('/feed'),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 28, ViralTokens.paddingH, 0),
          sliver: const SliverToBoxAdapter(
            child: ViralSectionHeader(title: 'Featured Creators'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 14, ViralTokens.paddingH, 0),
          sliver: ref.watch(featuredCreatorsProvider).when(
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (creators) {
              if (creators.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Column(
                  children: creators
                      .map((c) => FeaturedCreatorTile(creator: c))
                      .toList(),
                ),
              );
            },
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(ViralTokens.paddingH, 24, ViralTokens.paddingH, bottomInset),
          sliver: SliverToBoxAdapter(
            child: ViralProUpgradeBanner(onTap: () => context.push('/paywall')),
          ),
        ),
      ],
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M views';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K views';
    return '$n views';
  }
}

class _TemplateCarouselCard extends StatelessWidget {
  const _TemplateCarouselCard({required this.item});

  final TemplateItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/create?templateId=${item.id}'),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ViralGradientCard(
                gradient: ViralTokens.templateCinematic,
                borderRadius: ViralTokens.radiusLg,
                padding: EdgeInsets.zero,
                child: const Center(
                  child: Icon(Icons.play_arrow_rounded, color: ViralTokens.textPrimary, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ViralTokens.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${_formatUses(item.usesCount)} uses',
              style: const TextStyle(color: ViralTokens.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatUses(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _ViralVideoCard extends StatelessWidget {
  const _ViralVideoCard({
    required this.creator,
    required this.views,
    required this.onTap,
  });

  final String creator;
  final String views;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ViralTokens.surface,
                  borderRadius: BorderRadius.circular(ViralTokens.radiusLg),
                ),
                child: const Center(
                  child: Icon(Icons.play_arrow_rounded, color: ViralTokens.textPrimary, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              creator,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ViralTokens.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(views, style: const TextStyle(color: ViralTokens.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
