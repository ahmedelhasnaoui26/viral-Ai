import 'package:flutter/material.dart';

import '../../../../core/theme/viral_design_tokens.dart';

/// Top-right close (X) for onboarding and sign-in flows.
class AuthFlowCloseButton extends StatelessWidget {
  const AuthFlowCloseButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.close, color: ViralTokens.textPrimary, size: 26),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }
}

/// Secondary text action for guest entry.
class ContinueAsGuestButton extends StatelessWidget {
  const ContinueAsGuestButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: const Text(
        'Continue as Guest',
        style: TextStyle(
          color: ViralTokens.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: ViralTokens.textDim,
        ),
      ),
    );
  }
}
