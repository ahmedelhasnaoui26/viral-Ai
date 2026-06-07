import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/viral_design_tokens.dart';
import '../../../shared/widgets/viral_ui_widgets.dart';
import '../application/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: ViralTokens.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, ViralTokens.paddingH, 0),
              child: Row(
                children: [
                  ViralBackCircleButton(onPressed: () => context.pop()),
                  const Expanded(
                    child: Text(
                      'Notifications',
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
              child: notificationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load: $e')),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notifications yet',
                        style: TextStyle(color: ViralTokens.textSecondary),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: _NotificationIcon(type: item.type),
                        title: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: ViralTokens.textPrimary, fontSize: 15),
                            children: [
                              TextSpan(
                                text: item.title,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: item.body),
                            ],
                          ),
                        ),
                        subtitle: Text(
                          _timeAgo(item.createdAt),
                          style: const TextStyle(color: ViralTokens.textMuted, fontSize: 12),
                        ),
                        trailing: item.feedItemId != null
                            ? Container(
                                width: 48,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: ViralTokens.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      'like' => (Icons.favorite_border, const Color(0xFFEC4899)),
      'comment' => (Icons.chat_bubble_outline, const Color(0xFF8B5CF6)),
      'follow' => (Icons.person_add_alt_1, const Color(0xFF3B82F6)),
      'template_used' => (Icons.shuffle, const Color(0xFFA855F7)),
      'video_trending' => (Icons.trending_up, const Color(0xFF22C55E)),
      _ => (Icons.notifications_none, ViralTokens.textMuted),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: ViralTokens.surface, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
