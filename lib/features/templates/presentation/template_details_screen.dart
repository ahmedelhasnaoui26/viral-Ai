import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/viral_design_tokens.dart';
import '../../../core/utils/format_count.dart';
import '../../../shared/widgets/viral_gradient_button.dart';
import '../../feed/application/feed_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../application/template_providers.dart';

class TemplateDetailsScreen extends ConsumerWidget {
  const TemplateDetailsScreen({required this.templateId, super.key});

  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync = ref.watch(templateByIdProvider(templateId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Template'),
        backgroundColor: ViralTokens.black,
      ),
      backgroundColor: ViralTokens.black,
      body: templateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load template: $error')),
        data: (template) {
          if (template == null) {
            return const Center(
              child: Text('Template not found', style: TextStyle(color: ViralTokens.textSecondary)),
            );
          }

          final creatorAsync = template.creatorId != null
              ? ref.watch(creatorProfileProvider(template.creatorId!))
              : null;

          return Padding(
            padding: const EdgeInsets.all(ViralTokens.paddingH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(ViralTokens.radiusMd),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: template.thumbnailUrl.startsWith('http')
                        ? Image.network(template.thumbnailUrl, fit: BoxFit.cover)
                        : Container(
                            decoration: const BoxDecoration(gradient: ViralTokens.templateCinematic),
                            child: const Center(
                              child: Icon(Icons.play_arrow_rounded, size: 48, color: Colors.white),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  template.title,
                  style: const TextStyle(
                    color: ViralTokens.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  template.description,
                  style: const TextStyle(color: ViralTokens.textSecondary, height: 1.45),
                ),
                const SizedBox(height: 12),
                Text(
                  '${formatCompactCount(template.usesCount)} uses · ${template.style} · ${template.duration}s · ${template.category}',
                  style: const TextStyle(color: ViralTokens.textMuted),
                ),
                if (creatorAsync != null) ...[
                  const SizedBox(height: 12),
                  creatorAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (profile) {
                      if (profile == null) return const SizedBox.shrink();
                      return Text(
                        'by ${profile.displayLabel}',
                        style: const TextStyle(color: ViralTokens.textSecondary, fontSize: 14),
                      );
                    },
                  ),
                ],
                const Spacer(),
                ViralGradientButton(
                  label: 'Use Template',
                  icon: Icons.auto_awesome,
                  gradient: ViralTokens.generateButtonGradient,
                  onPressed: () async {
                    if (template.creatorId != null) {
                      await ref.read(feedRepositoryProvider).recordTemplateUse(
                            templateId: template.id,
                            creatorId: template.creatorId!,
                          );
                    }
                    if (!context.mounted) return;
                    context.go('/create?templateId=${template.id}');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
