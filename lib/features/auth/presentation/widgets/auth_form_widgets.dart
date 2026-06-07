import 'package:flutter/material.dart';

import '../../../../core/theme/viral_design_tokens.dart';
import '../../../../shared/widgets/viral_gradient_button.dart';

/// Shared gradient backdrop for auth flows.
class AuthScreenBackground extends StatelessWidget {
  const AuthScreenBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2E1065).withValues(alpha: 0.55),
            ViralTokens.black,
          ],
        ),
      ),
      child: child,
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ViralTokens.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onSubmitted: onSubmitted,
          style: const TextStyle(color: ViralTokens.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: ViralTokens.inputHint),
            filled: true,
            fillColor: ViralTokens.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ViralTokens.radiusSm),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ViralTokens.radiusSm),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ViralTokens.radiusSm),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(ViralTokens.radiusSm),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFFECACA), fontSize: 14, height: 1.35),
      ),
    );
  }
}

class AuthSuccessBanner extends StatelessWidget {
  const AuthSuccessBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14532D).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(ViralTokens.radiusSm),
        border: Border.all(color: ViralTokens.checkGreen.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFBBF7D0), fontSize: 14, height: 1.35),
      ),
    );
  }
}

class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({
    required this.loading,
    required this.onApple,
    required this.onGoogle,
    super.key,
  });

  final bool loading;
  final VoidCallback onApple;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ViralWhiteButton(
          label: loading ? 'Connecting...' : 'Continue with Apple',
          icon: const Icon(Icons.apple, size: 22, color: ViralTokens.black),
          onPressed: loading ? null : onApple,
        ),
        const SizedBox(height: 14),
        ViralOutlinedDarkButton(
          label: loading ? 'Connecting...' : 'Continue with Google',
          icon: const Icon(Icons.g_mobiledata, color: ViralTokens.textPrimary, size: 28),
          onPressed: loading ? null : onGoogle,
        ),
      ],
    );
  }
}
