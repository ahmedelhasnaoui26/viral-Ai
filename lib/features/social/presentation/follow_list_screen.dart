import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/viral_design_tokens.dart';
import '../../../shared/widgets/viral_ui_widgets.dart';
import '../application/social_providers.dart';
import '../domain/follow_user.dart';

enum FollowListType { followers, following }

class FollowListScreen extends ConsumerWidget {
  const FollowListScreen({
    super.key,
    required this.userId,
    required this.type,
  });

  final String userId;
  final FollowListType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = type == FollowListType.followers
        ? ref.watch(followersListProvider(userId))
        : ref.watch(followingListProvider(userId));

    final title = type == FollowListType.followers ? 'Followers' : 'Following';

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
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: ViralTokens.textMuted))),
                data: (users) {
                  if (users.isEmpty) {
                    return Center(
                      child: Text(
                        type == FollowListType.followers ? 'No followers yet' : 'Not following anyone yet',
                        style: const TextStyle(color: ViralTokens.textMuted),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(ViralTokens.paddingH),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _FollowRow(user: users[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowRow extends StatelessWidget {
  const _FollowRow({required this.user});

  final FollowUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ViralTokens.surface,
        borderRadius: BorderRadius.circular(ViralTokens.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: ViralTokens.surfaceElevated,
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    color: ViralTokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user.handle.isNotEmpty)
                  Text(user.handle, style: const TextStyle(color: ViralTokens.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
