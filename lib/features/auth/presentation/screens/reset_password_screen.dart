import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_error_message.dart';
import '../../../../core/theme/viral_design_tokens.dart';
import '../../../../shared/widgets/viral_gradient_button.dart';
import '../../../../shared/widgets/viral_ui_widgets.dart';
import '../../application/auth_providers.dart';
import '../widgets/auth_form_widgets.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() => _errorMessage = null);

    try {
      await ref.read(authControllerProvider.notifier).updatePassword(password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
      context.go('/home');
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = friendlyAuthError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    final hasSession = ref.watch(authServiceProvider).currentSession != null;

    return Scaffold(
      backgroundColor: ViralTokens.black,
      body: AuthScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ViralTokens.paddingScreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                const ViralGradientText(
                  'Reset password',
                  fontSize: 28,
                  gradient: LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFD946EF)]),
                ),
                const SizedBox(height: 8),
                Text(
                  hasSession
                      ? 'Choose a new password for your account'
                      : 'Open the reset link from your email to continue',
                  style: const TextStyle(color: ViralTokens.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null) ...[
                  AuthErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],
                if (!hasSession) ...[
                  const AuthErrorBanner(
                    message: 'Waiting for a valid reset session. Tap the link in your email again.',
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.go('/auth/forgot-password'),
                    child: const Text('Resend reset email'),
                  ),
                ] else ...[
                  AuthTextField(
                    controller: _passwordController,
                    label: 'New Password',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _confirmController,
                    label: 'Confirm Password',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => loading ? null : _updatePassword(),
                  ),
                  const SizedBox(height: 24),
                  ViralGradientButton(
                    label: loading ? 'Updating...' : 'Update Password',
                    icon: Icons.lock_reset,
                    onPressed: loading ? null : _updatePassword,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
