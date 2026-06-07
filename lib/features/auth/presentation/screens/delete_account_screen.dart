import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../application/auth_providers.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deleting your account removes your profile, generations, and active sessions.',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _deleteAccount,
              child: Text(_busy ? 'Deleting...' : 'Confirm Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _busy = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.functions.invoke('delete-account');
      await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
