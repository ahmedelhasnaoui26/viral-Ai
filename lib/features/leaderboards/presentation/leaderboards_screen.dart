import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/viral_design_tokens.dart';
import '../../../core/utils/format_count.dart';
import '../../../shared/widgets/viral_ui_widgets.dart';
import '../application/leaderboards_providers.dart';
import '../domain/leaderboard_entry.dart';

class LeaderboardsScreen extends ConsumerStatefulWidget {
  const LeaderboardsScreen({super.key});

  @override
  ConsumerState<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends ConsumerState<LeaderboardsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
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
                      'Leaderboards',
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
            TabBar(
              controller: _tabs,
              indicatorColor: const Color(0xFF8B5CF6),
              labelColor: ViralTokens.textPrimary,
              unselectedLabelColor: ViralTokens.textMuted,
              tabs: const [
                Tab(text: 'Creators'),
                Tab(text: 'Videos'),
                Tab(text: 'Templates'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _LeaderboardList(async: ref.watch(topCreatorsLeaderboardProvider)),
                  _LeaderboardList(async: ref.watch(topVideosLeaderboardProvider)),
                  _LeaderboardList(async: ref.watch(topTemplatesLeaderboardProvider)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({required this.async});

  final AsyncValue<List<LeaderboardEntry>> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: ViralTokens.textMuted))),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Text('No rankings yet', style: TextStyle(color: ViralTokens.textMuted)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(ViralTokens.paddingH),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final e = entries[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ViralTokens.surface,
                borderRadius: BorderRadius.circular(ViralTokens.radiusMd),
              ),
              child: Row(
                children: [
                  Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ViralTokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (e.subtitle.isNotEmpty)
                          Text(
                            e.subtitle,
                            style: const TextStyle(color: ViralTokens.textMuted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    formatCompactCount(e.score),
                    style: const TextStyle(
                      color: ViralTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
