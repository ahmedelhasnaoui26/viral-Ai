import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/viral_design_tokens.dart';
import '../../auth/application/auth_gate.dart';
import '../../auth/domain/auth_gated_action.dart';
import '../application/reports_providers.dart';

const _reportReasons = [
  'Spam or misleading',
  'Harassment or hate',
  'Violence or dangerous acts',
  'Intellectual property',
  'Other',
];

Future<void> showReportSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String targetType,
  required String targetId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _ReportSheetBody(
        targetType: targetType,
        targetId: targetId,
        parentRef: ref,
      ),
    ),
  );
}

class _ReportSheetBody extends ConsumerStatefulWidget {
  const _ReportSheetBody({
    required this.targetType,
    required this.targetId,
    required this.parentRef,
  });

  final String targetType;
  final String targetId;
  final WidgetRef parentRef;

  @override
  ConsumerState<_ReportSheetBody> createState() => _ReportSheetBodyState();
}

class _ReportSheetBodyState extends ConsumerState<_ReportSheetBody> {
  String? _selected;
  bool _submitting = false;

  Future<void> _submit() async {
    final reason = _selected;
    if (reason == null) return;

    final allowed = await requireAuthentication(
      context,
      ref,
      action: AuthGatedAction.profileFeatures,
    );
    if (!context.mounted || !allowed) return;

    setState(() => _submitting = true);
    try {
      await widget.parentRef.read(submitReportUseCaseProvider).call(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reason: reason,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. Thank you.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: ViralTokens.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Report',
                      style: TextStyle(
                        color: ViralTokens.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: ViralTokens.textSecondary),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: _reportReasons.map((r) {
                    final selected = _selected == r;
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: Icon(
                        selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: selected ? const Color(0xFF8B5CF6) : ViralTokens.textMuted,
                        size: 22,
                      ),
                      title: Text(
                        r,
                        style: const TextStyle(color: ViralTokens.textPrimary, fontSize: 15),
                      ),
                      onTap: _submitting
                          ? null
                          : () => setState(() => _selected = r),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _submitting || _selected == null ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
