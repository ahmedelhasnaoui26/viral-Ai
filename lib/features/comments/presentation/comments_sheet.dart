import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/viral_design_tokens.dart';
import '../../auth/application/auth_gate.dart';
import '../../auth/domain/auth_gated_action.dart';
import '../../feed/application/feed_providers.dart';
import '../application/comments_providers.dart';
import '../domain/comment.dart';

Future<void> showCommentsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String feedItemId,
  required String videoOwnerId,
  required int initialCount,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CommentsSheetBody(
      feedItemId: feedItemId,
      videoOwnerId: videoOwnerId,
      initialCount: initialCount,
      parentRef: ref,
    ),
  );
}

class _CommentsSheetBody extends ConsumerStatefulWidget {
  const _CommentsSheetBody({
    required this.feedItemId,
    required this.videoOwnerId,
    required this.initialCount,
    required this.parentRef,
  });

  final String feedItemId;
  final String videoOwnerId;
  final int initialCount;
  final WidgetRef parentRef;

  @override
  ConsumerState<_CommentsSheetBody> createState() => _CommentsSheetBodyState();
}

class _CommentsSheetBodyState extends ConsumerState<_CommentsSheetBody> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final allowed = await requireAuthentication(
      context,
      ref,
      action: AuthGatedAction.profileFeatures,
    );
    if (!context.mounted || !allowed) return;

    final text = _controller.text;
    _controller.clear();
    _focusNode.unfocus();
    try {
      await ref.read(postCommentUseCaseProvider).call(
            feedItemId: widget.feedItemId,
            text: text,
            videoOwnerId: widget.videoOwnerId,
          );
      ref.invalidate(commentsForFeedProvider(widget.feedItemId));
      await widget.parentRef.read(feedControllerProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not post comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final commentsAsync = ref.watch(commentsForFeedProvider(widget.feedItemId));
    final count = commentsAsync.value?.length ?? widget.initialCount;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.72,
        decoration: const BoxDecoration(
          color: ViralTokens.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Text(
                    '$count Comments',
                    style: const TextStyle(
                      color: ViralTokens.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: ViralTokens.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: ViralTokens.borderSubtle),
            Expanded(
              child: commentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Failed to load comments', style: TextStyle(color: Colors.white70)),
                ),
                data: (comments) {
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'Be the first to comment',
                        style: TextStyle(color: ViralTokens.textMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: comments.length,
                    itemBuilder: (_, i) => _CommentTile(
                      comment: comments[i],
                      onDelete: () async {
                        await ref.read(deleteCommentUseCaseProvider).call(comments[i].id);
                        ref.invalidate(commentsForFeedProvider(widget.feedItemId));
                        await widget.parentRef.read(feedControllerProvider.notifier).refresh();
                      },
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: ViralTokens.surface,
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(color: ViralTokens.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Add comment...',
                        hintStyle: TextStyle(color: ViralTokens.textMuted.withValues(alpha: 0.8)),
                        filled: true,
                        fillColor: ViralTokens.black,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _submit();
                    },
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF8B5CF6)),
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

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onDelete});

  final Comment comment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: ViralTokens.surface,
            child: Text(
              comment.authorLabel.isNotEmpty ? comment.authorLabel[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.w700, color: ViralTokens.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorLabel,
                      style: const TextStyle(
                        color: ViralTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (comment.isOwn) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: ViralTokens.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(color: ViralTokens.textSecondary, fontSize: 14, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
