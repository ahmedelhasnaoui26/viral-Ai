import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_error_message.dart';
import '../../../../core/theme/viral_design_tokens.dart';
import '../../../../shared/widgets/viral_gradient_button.dart';
import '../../../../shared/widgets/viral_ui_widgets.dart';
import '../../application/auth_providers.dart';
import '../widgets/auth_form_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _errorMessage;
  String? _successMessage;
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your email address.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _sending = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).sendPasswordResetEmail(email);
      if (!mounted) return;
      setState(() {
        _successMessage =
            'If an account exists for this email, we sent a password reset link. Check your inbox.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = _sending || ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: ViralTokens.black,
      body: AuthScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ViralTokens.paddingScreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                ViralBackCircleButton(onPressed: () => context.pop()),
                const SizedBox(height: 32),
                const ViralGradientText(
                  'Forgot password?',
                  fontSize: 28,
                  gradient: LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFD946EF)]),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We\'ll email you a link to reset your password',
                  style: TextStyle(color: ViralTokens.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null) ...[
                  AuthErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],
                if (_successMessage != null) ...[
                  AuthSuccessBanner(message: _successMessage!),
                  const SizedBox(height: 16),
                ],
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: (_) => loading ? null : _sendResetLink(),
                ),
                const SizedBox(height: 24),
                ViralGradientButton(
                  label: loading ? 'Sending...' : 'Send Reset Link',
                  icon: Icons.mail_outline,
                  onPressed: loading ? null : _sendResetLink,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/auth'),
                  child: const Text(
                    'Back to Sign In',
                    style: TextStyle(color: ViralTokens.textSecondary, fontWeight: FontWeight.w600),
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
