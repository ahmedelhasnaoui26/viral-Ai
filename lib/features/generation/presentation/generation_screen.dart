import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../core/di/providers.dart';
import '../../../core/layout/viral_layout.dart';
import '../../../core/theme/viral_design_tokens.dart';
import '../../auth/application/auth_gate.dart';
import '../../auth/domain/auth_gated_action.dart';
import '../../../shared/widgets/viral_dotted_upload_box.dart';
import '../../../shared/widgets/viral_gradient_button.dart';
import '../../../shared/widgets/viral_ui_widgets.dart';
import '../../drafts/application/drafts_providers.dart';
import '../../drafts/domain/draft_generation.dart';
import '../application/generation_providers.dart';
import '../../templates/application/template_providers.dart';

class GenerationScreen extends ConsumerStatefulWidget {
  const GenerationScreen({this.templateId, this.draftId, super.key});

  final String? templateId;
  final String? draftId;

  @override
  ConsumerState<GenerationScreen> createState() => _GenerationScreenState();
}

class _StyleOption {
  const _StyleOption(this.id, this.label, this.gradient);

  final String id;
  final String label;
  final Gradient gradient;
}

class _GenerationScreenState extends ConsumerState<GenerationScreen> {
  final _promptController = TextEditingController();

  static const _styles = [
    _StyleOption('cinematic', 'Cinematic', ViralTokens.styleCinematic),
    _StyleOption('dreamy', 'Dreamy', ViralTokens.styleDreamy),
    _StyleOption('dramatic', 'Dramatic', ViralTokens.styleDramatic),
    _StyleOption('ethereal', 'Ethereal', ViralTokens.styleEthereal),
    _StyleOption('anime', 'Anime', ViralTokens.styleAnime),
    _StyleOption('viral', 'Viral TikTok', ViralTokens.styleViralTikTok),
  ];

  static const _durations = [5, 15, 30, 60];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generationControllerProvider);
    final isTemplateMode = widget.templateId != null && widget.templateId!.isNotEmpty;

    return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            ViralTokens.paddingH,
            16,
            ViralTokens.paddingH,
            ViralLayout.scrollPaddingAboveBottomNav(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ViralGradientText('Create', fontSize: 32),
              const SizedBox(height: 24),
              const _FieldLabel('Upload Photo'),
              const SizedBox(height: 12),
              ViralDottedUploadBox(
                imagePath: state.selectedImagePath,
                onTap: state.loading ? () {} : () => _pickImage(context),
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Describe your vision'),
              const SizedBox(height: 12),
              TextField(
                controller: _promptController,
                maxLines: 4,
                readOnly: isTemplateMode,
                style: const TextStyle(color: ViralTokens.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: isTemplateMode
                      ? 'Template prompt is pre-filled'
                      : 'e.g., Epic cinematic reveal with dramatic zoom...',
                  hintStyle: const TextStyle(color: ViralTokens.textMuted, fontSize: 15),
                  filled: true,
                  fillColor: ViralTokens.surfaceElevated,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ViralTokens.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (isTemplateMode) ...[
                const SizedBox(height: 10),
                const Text(
                  'Using template settings: prompt, style and duration are locked.',
                  style: TextStyle(color: ViralTokens.textMuted, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              const _FieldLabel('Style'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
                children: _styles.map((style) {
                  final selected = state.selectedStyle == style.id;
                  return GestureDetector(
                    onTap: state.loading || isTemplateMode
                        ? null
                        : () => ref
                            .read(generationControllerProvider.notifier)
                            .selectStyle(style.id),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: style.gradient,
                              borderRadius: BorderRadius.circular(ViralTokens.radiusSm),
                              border: selected
                                  ? Border.all(color: const Color(0xFFA855F7), width: 2)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          style.label,
                          style: TextStyle(
                            color: selected ? ViralTokens.textPrimary : ViralTokens.textSecondary,
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Duration'),
              const SizedBox(height: 12),
              Row(
                children: _durations.map((seconds) {
                  final selected = state.selectedDurationSeconds == seconds;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: seconds == 60 ? 0 : 8),
                      child: GestureDetector(
                        onTap: state.loading || isTemplateMode
                            ? null
                            : () => ref
                                .read(generationControllerProvider.notifier)
                                .selectDuration(seconds),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: selected ? ViralTokens.primaryGradient : null,
                            color: selected ? null : ViralTokens.surface,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            '${seconds}s',
                            style: TextStyle(
                              color: selected ? ViralTokens.textPrimary : ViralTokens.textSecondary,
                              fontSize: 15,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: state.loading ? null : () => _saveDraft(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ViralTokens.textPrimary,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              if (state.loading) ...[
                LinearProgressIndicator(
                  value: state.progressPercent > 0
                      ? state.progressPercent / 100
                      : (state.uploadProgress > 0 ? state.uploadProgress : null),
                  backgroundColor: ViralTokens.surface,
                  color: const Color(0xFF8B5CF6),
                ),
                if (state.progressPercent > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${state.progressPercent}%',
                    style: const TextStyle(color: ViralTokens.textMuted, fontSize: 12),
                  ),
                ],
                if (state.statusMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    state.statusMessage!,
                    style: const TextStyle(
                      color: ViralTokens.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ViralTokens.radiusSm),
                  gradient: ViralTokens.generateButtonGradient,
                  boxShadow: ViralTokens.proButtonGlow,
                ),
                child: ViralGradientButton(
                  label: state.loading ? 'Generating...' : 'Generate Video',
                  icon: Icons.auto_awesome,
                  gradient: ViralTokens.generateButtonGradient,
                  showGlow: false,
                  onPressed: state.loading ? null : () => _generate(context),
                ),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14),
                ),
              ],
            ],
          ),
        );
  }

  Future<void> _pickImage(BuildContext context) async {
    final allowed = await requireAuthentication(
      context,
      ref,
      action: AuthGatedAction.uploadImage,
    );
    if (!allowed || !mounted) return;
    await ref.read(generationControllerProvider.notifier).pickImage();
  }

  Future<void> _saveDraft(BuildContext context) async {
    final allowed = await requireAuthentication(
      context,
      ref,
      action: AuthGatedAction.generateVideo,
    );
    if (!allowed || !mounted) return;

    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) return;

    final state = ref.read(generationControllerProvider);
    await ref.read(saveDraftUseCaseProvider).call(
          userId: userId,
          imageUrl: state.selectedImagePath,
          prompt: _promptController.text.trim(),
          style: state.selectedStyle,
          duration: state.selectedDurationSeconds,
          templateId: widget.templateId,
        );
    ref.invalidate(currentUserDraftsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved')),
    );
  }

  Future<void> _generate(BuildContext context) async {
    final allowed = await requireAuthentication(
      context,
      ref,
      action: AuthGatedAction.generateVideo,
    );
    if (!allowed || !mounted) return;

    final prompt = _promptController.text.trim();
    if (_containsBannedPrompt(prompt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompt contains restricted content.')),
      );
      return;
    }
    await ref.read(generationControllerProvider.notifier).generate(
          prompt: prompt,
          templateId: widget.templateId,
        );
    final latest = ref.read(generationControllerProvider).job;
    if (latest == null || !mounted) return;
    if (!context.mounted) return;
    if (latest.status.name == 'completed') {
      final analytics = ref.read(analyticsServiceProvider).asData?.value;
      final revenueCat = ref.read(revenueCatServiceProvider);
      await revenueCat.initialize();
      if (revenueCat.isConfigured) {
        await analytics?.track(
          const AnalyticsEvent(AnalyticsEvents.paywallViewed),
        );
        if (!context.mounted) return;
        await context.push('/paywall');
        if (!context.mounted) return;
      }
      final url = latest.r2VideoUrl ??
          latest.outputObjectKey ??
          latest.outputUrl ??
          '';
      if (!context.mounted) return;
      context.go(
        '/result?videoUrl=${Uri.encodeComponent(url)}&jobId=${latest.id}&templateId=${Uri.encodeComponent(widget.templateId ?? '')}&prompt=${Uri.encodeComponent(prompt)}',
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(latest.errorMessage ?? 'Generation failed')),
    );
  }

  bool _containsBannedPrompt(String prompt) {
    const banned = ['nsfw', 'nude', 'gore', 'child sexual'];
    final lower = prompt.toLowerCase();
    return banned.any(lower.contains);
  }

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      final draftId = widget.draftId;
      if (draftId != null && draftId.isNotEmpty) {
        final drafts = await ref.read(currentUserDraftsProvider.future);
        DraftGeneration? draft;
        for (final d in drafts) {
          if (d.id == draftId) {
            draft = d;
            break;
          }
        }
        if (!mounted || draft == null) return;
        _promptController.text = draft.prompt;
        ref.read(generationControllerProvider.notifier)
          ..selectStyle(draft.style)
          ..selectDuration(draft.duration);
        if (draft.imageUrl != null && draft.imageUrl!.isNotEmpty) {
          ref.read(generationControllerProvider.notifier).setImagePath(draft.imageUrl!);
        }
        return;
      }

      final templateId = widget.templateId;
      if (templateId == null || templateId.isEmpty) return;
      final template = await ref.read(templateByIdProvider(templateId).future);
      if (!mounted || template == null) return;
      _promptController.text = template.prompt;
      ref.read(generationControllerProvider.notifier)
        ..selectStyle(template.style)
        ..selectDuration(template.duration);
    });
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: ViralTokens.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
