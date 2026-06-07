import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_error_message.dart';
import '../../../../core/layout/viral_layout.dart';
import '../../../../core/theme/viral_design_tokens.dart';
import '../../../../shared/widgets/viral_gradient_button.dart';
import '../../../../shared/widgets/viral_ui_widgets.dart';
import '../../application/auth_providers.dart';
import '../../application/guest_mode_provider.dart';
import '../../presentation/widgets/auth_flow_header.dart';
import '../widgets/auth_form_widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continueAsGuest() async {
    await ref.read(guestModeProvider.notifier).enterGuestMode();
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Enter your email and password.');
      return;
    }

    setState(() => _errorMessage = null);
    try {
      await ref.read(authControllerProvider.notifier).signInWithEmailPassword(
            email: email,
            password: password,
          );
      if (!mounted) return;
      context.go('/home');
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = friendlyAuthError(error));
    }
  }

  Future<void> _oauthSignIn(Future<void> Function() signIn, String method) async {
    setState(() => _errorMessage = null);
    try {
      await signIn();
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = friendlyAuthError(error));
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: ViralTokens.paddingScreen),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      AuthFlowCloseButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
                      SizedBox(height: compact ? 16 : 32),
                      const Center(
                        child: ViralGradientText(
                          'Welcome back',
                          fontSize: 28,
                          gradient: LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFFD946EF)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to create, publish, and grow',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ViralTokens.textSecondary, fontSize: 15),
                      ),
                      SizedBox(height: compact ? 24 : 32),
                      if (_errorMessage != null) ...[
                        AuthErrorBanner(message: _errorMessage!),
                        const SizedBox(height: 16),
                      ],
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
                        hint: '••••••••',
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => loading ? null : _signInWithEmail(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: loading ? null : () => context.push('/auth/forgot-password'),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ViralGradientButton(
                        label: loading ? 'Signing in...' : 'Sign In',
                        icon: Icons.login_rounded,
                        onPressed: loading ? null : _signInWithEmail,
                      ),
                      const SizedBox(height: 24),
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
                        onApple: () => _oauthSignIn(
                          () => ref.read(authControllerProvider.notifier).signInWithApple(),
                          'apple',
                        ),
                        onGoogle: () => _oauthSignIn(
                          () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                          'google',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'New here? ',
                            style: TextStyle(color: ViralTokens.textMuted, fontSize: 15),
                          ),
                          GestureDetector(
                            onTap: loading ? null : () => context.push('/auth/sign-up'),
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                color: ViralTokens.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ContinueAsGuestButton(
                        onPressed: loading ? () {} : () => _continueAsGuest(),
                      ),
                      SizedBox(height: compact ? 24 : 40),
                      _TermsFooter(onTerms: () => context.push('/terms'), onPrivacy: () => context.push('/privacy')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TermsFooter extends StatelessWidget {
  const _TermsFooter({required this.onTerms, required this.onPrivacy});

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(color: ViralTokens.textMuted, fontSize: 12),
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          WidgetSpan(
            child: GestureDetector(
              onTap: onTerms,
              child: const Text(
                'Terms of Service',
                style: TextStyle(color: ViralTokens.textSecondary, fontSize: 12),
              ),
            ),
          ),
          const TextSpan(text: ' and '),
          WidgetSpan(
            child: GestureDetector(
              onTap: onPrivacy,
              child: const Text(
                'Privacy Policy',
                style: TextStyle(color: ViralTokens.textSecondary, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
