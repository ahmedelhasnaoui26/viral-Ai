import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/viral_design_tokens.dart';
import '../../auth/application/auth_providers.dart';
import '../application/profile_providers.dart';
import '../../../shared/widgets/viral_gradient_button.dart';
import '../../../shared/widgets/viral_ui_widgets.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _displayNameController = TextEditingController();
  final _handleController = TextEditingController();
  final _bioController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  bool _saving = false;
  bool _fieldsInitialized = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _initFieldsFromProfile(WidgetRef ref) {
    final profile = ref.read(currentUserProfileProvider).asData?.value;
    if (profile == null || _fieldsInitialized) return;
    _displayNameController.text = profile.displayName;
    _handleController.text = profile.handle;
    _bioController.text = profile.bio;
    _avatarUrlController.text = profile.avatarUrl ?? '';
    _fieldsInitialized = true;
  }

  String _friendlySaveError(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('duplicate') || message.contains('unique')) {
        return 'That username is already taken. Try another handle.';
      }
      if (error.code == 'PGRST116' || error.code == '404') {
        return 'Could not update your profile. Sign out and sign in again.';
      }
      return error.message;
    }
    return error.toString();
  }

  Future<void> _save() async {
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save your profile.')),
      );
      context.push('/auth');
      return;
    }

    final displayName = _displayNameController.text.trim();
    final handle = _handleController.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty.')),
      );
      return;
    }
    if (handle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            userId: userId,
            displayName: displayName,
            handle: handle,
            bio: _bioController.text.trim(),
            avatarUrl: _avatarUrlController.text.trim().isEmpty
                ? null
                : _avatarUrlController.text.trim(),
          );
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(currentUserStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlySaveError(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    ref.listen(currentUserProfileProvider, (_, next) {
      if (next.asData?.value != null && !_fieldsInitialized && mounted) {
        setState(() {
          _initFieldsFromProfile(ref);
        });
      }
    });

    return Scaffold(
      backgroundColor: ViralTokens.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, ViralTokens.paddingH, 0),
              child: Row(
                children: [
                  ViralBackCircleButton(onPressed: () => context.pop()),
                  const Expanded(
                    child: Text(
                      'Account Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ViralTokens.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: profileAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(ViralTokens.paddingH),
                    child: Text(
                      'Failed to load profile: $e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: ViralTokens.textMuted),
                    ),
                  ),
                ),
                data: (profile) {
                  if (profile != null && !_fieldsInitialized) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || _fieldsInitialized) return;
                      setState(() => _initFieldsFromProfile(ref));
                    });
                  }

                  return ListView(
                    padding: const EdgeInsets.all(ViralTokens.paddingH),
                    children: [
                      _field('Display name', _displayNameController),
                      const SizedBox(height: 12),
                      _field('Username / handle', _handleController),
                      const SizedBox(height: 12),
                      _field('Bio', _bioController, maxLines: 3),
                      const SizedBox(height: 12),
                      _field('Avatar URL', _avatarUrlController),
                      const SizedBox(height: 24),
                      ViralGradientButton(
                        label: _saving ? 'Saving...' : 'Save Changes',
                        icon: Icons.check_rounded,
                        onPressed: _saving ? null : () => _save(),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _saving ? null : _logout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ViralTokens.textPrimary,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Log Out'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _saving ? null : () => context.push('/delete-account'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF453A),
                          side: const BorderSide(color: Color(0xFFFF453A)),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Delete Account'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: ViralTokens.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: ViralTokens.textSecondary),
        filled: true,
        fillColor: ViralTokens.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
        ),
      ),
    );
  }
}
