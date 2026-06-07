import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/viral_layout.dart';
import '../../../core/theme/viral_design_tokens.dart';
import '../../../shared/widgets/viral_ui_widgets.dart';
import '../../templates/application/template_providers.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  static const _categories = [
    'All',
    'Trending',
    'Anime',
    'Cinematic',
    'Lifestyle',
    'Travel',
    'Fashion',
    'Transformation',
    'Fantasy',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = ViralLayout.scrollPaddingAboveBottomNav(context);
    final filters = ref.watch(templateFiltersProvider);
    final selectedCategory = filters.category;
    final selectedSort = filters.sort;
    final templatesAsync = ref.watch(templatesProvider);

    return CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(ViralTokens.paddingH, 16, ViralTokens.paddingH, 0),
            sliver: SliverToBoxAdapter(child: ViralGradientText('Explore', fontSize: 32)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 20, ViralTokens.paddingH, 0),
            sliver: SliverToBoxAdapter(
              child: TextField(
                style: const TextStyle(color: ViralTokens.textPrimary),
                onChanged: (value) =>
                    ref.read(templateFiltersProvider.notifier).setQuery(value),
                decoration: InputDecoration(
                  hintText: 'Search videos, creators, templates...',
                  hintStyle: const TextStyle(color: ViralTokens.textMuted, fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: ViralTokens.textMuted),
                  filled: true,
                  fillColor: const Color(0xFF121212),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ViralTokens.radiusXs),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ViralTokens.radiusXs),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(ViralTokens.paddingH, 24, ViralTokens.paddingH, 0),
            sliver: SliverToBoxAdapter(child: ViralSectionHeader(title: 'Categories')),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 14, ViralTokens.paddingH, 0),
            sliver: SliverToBoxAdapter(child: _ExploreCategoriesGrid()),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(ViralTokens.paddingH, 24, ViralTokens.paddingH, 0),
            sliver: SliverToBoxAdapter(child: ViralSectionHeader(title: 'Discover')),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 14, ViralTokens.paddingH, 0),
            sliver: SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final selected = category == selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        onSelected: (_) {
                          ref.read(templateFiltersProvider.notifier)
                            ..setCategory(category)
                            ..setSort(category == 'Trending' ? 'trending' : selectedSort);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(ViralTokens.paddingH, 16, ViralTokens.paddingH, 0),
            sliver: SliverToBoxAdapter(
              child: DropdownButtonFormField<String>(
                initialValue: selectedSort,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF121212),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ViralTokens.radiusXs),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'most_used', child: Text('Most Used')),
                  DropdownMenuItem(value: 'trending', child: Text('Trending')),
                  DropdownMenuItem(value: 'newest', child: Text('Newest')),
                  DropdownMenuItem(value: 'most_liked', child: Text('Most Liked')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(templateFiltersProvider.notifier).setSort(value);
                },
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(ViralTokens.paddingH, 16, ViralTokens.paddingH, bottomInset),
            sliver: templatesAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Text('Failed to load templates: $error'),
              ),
              data: (items) => SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return _EffectCard(
                      title: item.title,
                      uses: '${item.usesCount} uses',
                      gradient: item.isPremium
                          ? ViralTokens.templateDreamy
                          : ViralTokens.templateParallax,
                      onTap: () => context.go('/create?templateId=${item.id}'),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
          ),
        ],
    );
  }
}

class _ExploreCategoriesGrid extends StatelessWidget {
  static const _items = [
    (Icons.trending_up, 'Trending', ViralTokens.categoryTrending),
    (Icons.palette_outlined, 'Anime', ViralTokens.styleAnime),
    (Icons.favorite_border, 'Lifestyle', ViralTokens.categoryFavorites),
    (Icons.flight, 'Travel', ViralTokens.templateParallax),
    (Icons.camera_alt_outlined, 'Fashion', ViralTokens.templateDreamy),
    (Icons.movie_creation_outlined, 'Cinematic', ViralTokens.styleDramatic),
    (Icons.auto_awesome, 'Transformation', ViralTokens.categoryPopular),
    (Icons.show_chart, 'Fantasy', ViralTokens.categoryNew),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 8,
      childAspectRatio: 0.78,
      children: _items.map((item) {
        return GestureDetector(
          onTap: () {
            ref.read(templateFiltersProvider.notifier)
              ..setCategory(item.$2)
              ..setSort(item.$2 == 'Trending' ? 'trending' : 'most_used');
          },
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: item.$3,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.$1, color: ViralTokens.textPrimary, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                item.$2,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ViralTokens.textPrimary, fontSize: 11),
              ),
            ],
          ),
        );
      }).toList(),
      ),
    );
  }
}

class _EffectCard extends StatelessWidget {
  const _EffectCard({
    required this.title,
    required this.uses,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String uses;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ViralTokens.radiusLg),
        child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 16),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ViralTokens.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  uses,
                  style: TextStyle(
                    color: ViralTokens.textPrimary.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
