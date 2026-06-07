import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/viral_design_tokens.dart';
import '../../../../shared/widgets/viral_gradient_button.dart';
import '../../application/auth_gate.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_gated_action.dart';

/// Premium sign-in modal shown when guests attempt protected actions.
Future<bool> showAuthRequiredModal(
  BuildContext context, {
  required AuthGatedAction action,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (sheetContext) => AuthRequiredModal(
      action: action,
      onClose: () => Navigator.of(sheetContext).pop(false),
      onSignedIn: () => Navigator.of(sheetContext).pop(true),
    ),
  ).then((value) => value ?? false);
}

class AuthRequiredModal extends ConsumerStatefulWidget {
  const AuthRequiredModal({
    required this.action,
    required this.onClose,
    required this.onSignedIn,
    super.key,
  });

  final AuthGatedAction action;
  final VoidCallback onClose;
  final VoidCallback onSignedIn;

  @override
  ConsumerState<AuthRequiredModal> createState() => _AuthRequiredModalState();
}

class _AuthRequiredModalState extends ConsumerState<AuthRequiredModal> {
  bool _loading = false;

  Future<void> _signIn(Future<void> Function() signIn, String method) async {
    if (_loading) return;
    setState(() => _loading = true);
    final success = await signInFromGate(
      ref,
      signIn: signIn,
      method: method,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      widget.onSignedIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0F),
          borderRadius: BorderRadius.circular(ViralTokens.radiusXl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      onPressed: _loading ? null : widget.onClose,
                      icon: const Icon(Icons.close, color: ViralTokens.textPrimary),
                    ),
                  ],
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: ViralTokens.crownGradient,
                    shape: BoxShape.circle,
                    boxShadow: ViralTokens.primaryButtonGlow,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.action.modalTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ViralTokens.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.action.modalSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ViralTokens.textSecondary,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                ViralWhiteButton(
                  label: _loading ? 'Connecting...' : 'Continue with Apple',
                  icon: const Icon(Icons.apple, size: 22, color: ViralTokens.black),
                  onPressed: _loading
                      ? null
                      : () => _signIn(
                            () => ref.read(authControllerProvider.notifier).signInWithApple(),
                            'apple',
                          ),
                ),
                const SizedBox(height: 12),
                ViralOutlinedDarkButton(
                  label: _loading ? 'Connecting...' : 'Continue with Google',
                  icon: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ViralTokens.textPrimary,
                    ),
                  ),
                  onPressed: _loading
                      ? null
                      : () => _signIn(
                            () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                            'google',
                          ),
                ),
                const SizedBox(height: 12),
                ViralGradientButton(
                  label: 'Continue with Email',
                  icon: Icons.mail_outline,
                  onPressed: _loading
                      ? null
                      : () async {
                          if (_loading) return;
                          setState(() => _loading = true);
                          await trackGuestConversionStarted(ref, 'email');
                          if (!mounted) return;
                          final router = GoRouter.of(context);
                          widget.onClose();
                          await router.push('/auth');
                          if (!mounted) return;
                          setState(() => _loading = false);
                          final user = ref.read(authServiceProvider).currentUser;
                          if (user != null) {
                            await onGuestConversionCompleted(ref);
                            widget.onSignedIn();
                          }
                        },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loading ? null : widget.onClose,
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: ViralTokens.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
