import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_error_message.dart';
import '../../../../core/layout/viral_layout.dart';
import '../../../../core/theme/viral_design_tokens.dart';
import '../../../../shared/widgets/viral_gradient_button.dart';
import '../../../../shared/widgets/viral_ui_widgets.dart';
import '../../../profile/application/profile_providers.dart';
import '../../application/auth_providers.dart';
import '../widgets/auth_form_widgets.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Fill in all fields.';
        _successMessage = null;
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
        _successMessage = null;
      });
      return;
    }
    if (password != confirm) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await ref.read(authControllerProvider.notifier).signUpWithEmailPassword(
            username: username,
            email: email,
            password: password,
          );

      final userId = result.user?.id;
      if (userId != null) {
        final handle = username.startsWith('@') ? username : '@$username';
        await ref.read(profileRepositoryProvider).ensureProfile(userId);
        await ref.read(profileRepositoryProvider).updateProfile(
              userId: userId,
              displayName: username,
              handle: handle,
              bio: '',
            );
      }

      if (!mounted) return;

      if (result.emailConfirmationRequired) {
        await ref.read(authRepositoryProvider).signOut();
        setState(() {
          _successMessage =
              'Account created! Check your email to verify your address, then sign in.';
          _errorMessage = null;
        });
        return;
      }

      context.go('/home');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = friendlyAuthError(error);
        _successMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.isLoading;
    final compact = ViralLayout.isCompact(context);

    return Scaffold(
      backgroundColor: ViralTokens.black,
      body: AuthScreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: ViralTokens.paddingScreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    ViralBackCircleButton(onPressed: () => context.pop()),
                    const Spacer(),
                  ],
                ),
                SizedBox(height: compact ? 16 : 24),
                const ViralGradientText(
                  'Create account',
                  fontSize: 28,
                  gradient: LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFD946EF)]),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join CineMorph AI and start creating',
                  style: TextStyle(color: ViralTokens.textSecondary, fontSize: 15),
                ),
                SizedBox(height: compact ? 24 : 32),
                if (_errorMessage != null) ...[
                  AuthErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],
                if (_successMessage != null) ...[
                  AuthSuccessBanner(message: _successMessage!),
                  const SizedBox(height: 16),
                  ViralGradientButton(
                    label: 'Back to Sign In',
                    onPressed: () => context.go('/auth'),
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  AuthTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'yourname',
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => loading ? null : _createAccount(),
                  ),
                  const SizedBox(height: 24),
                  ViralGradientButton(
                    label: loading ? 'Creating account...' : 'Create Account',
                    icon: Icons.person_add_alt_1,
                    onPressed: loading ? null : _createAccount,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or', style: TextStyle(color: ViralTokens.textDim, fontSize: 14)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AuthSocialButtons(
                    loading: loading,
                    onApple: () => ref.read(authControllerProvider.notifier).signInWithApple(),
                    onGoogle: () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ', style: TextStyle(color: ViralTokens.textMuted)),
                      GestureDetector(
                        onTap: () => context.go('/auth'),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: ViralTokens.textPrimary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
