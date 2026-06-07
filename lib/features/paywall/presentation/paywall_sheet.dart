import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Legacy bottom sheet entry — opens full-screen paywall matching design.
class PaywallSheet extends StatelessWidget {
  const PaywallSheet({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      context.push('/paywall');
    });
    return const SizedBox.shrink();
  }
}
