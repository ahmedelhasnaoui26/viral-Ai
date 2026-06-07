import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'By using this app, you agree not to upload illegal or prohibited content. '
          'You retain ownership of your content. Subscription renewals are handled by App Store/Google Play '
          'and can be managed in platform settings.',
        ),
      ),
    );
  }
}
