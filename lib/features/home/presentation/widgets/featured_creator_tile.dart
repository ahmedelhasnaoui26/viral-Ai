import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/creator_display.dart';
import '../../../../core/utils/format_count.dart';
import '../../../auth/application/auth_gate.dart';
import '../../../auth/domain/auth_gated_action.dart';
import '../../../feed/application/feed_providers.dart';
import '../../../profile/application/profile_providers.dart';
import '../../../profile/domain/profile_models.dart';
import '../../../../shared/widgets/viral_ui_widgets.dart';

class FeaturedCreatorTile extends ConsumerWidget {
  const FeaturedCreatorTile({required this.creator, super.key});

  final FeaturedCreator creator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ViralCreatorRow(
      name: creator.displayName,
      subtitle: CreatorDisplay.subtitleHandle(
        displayName: creator.displayName,
        handle: creator.handle,
      ),
      followers: '${formatCompactCount(creator.followersCount)} followers',
      isFollowing: creator.isFollowing,
      followEnabled: !creator.isSelf,
      onFollow: creator.isSelf
          ? null
          : () => _toggleFollow(context, ref),
    );
  }

  Future<void> _toggleFollow(BuildContext context, WidgetRef ref) async {
    final allowed = await requireAuthentication(
      context,
      ref,
      action: AuthGatedAction.profileFeatures,
    );
    if (!context.mounted || !allowed) return;

    HapticFeedback.mediumImpact();
    try {
      await ref.read(toggleFollowUseCaseProvider).call(creator.id);
      ref.invalidate(featuredCreatorsProvider);
      ref.invalidate(feedControllerProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update follow: $e')),
      );
    }
  }
}
