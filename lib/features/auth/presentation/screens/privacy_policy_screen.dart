import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'We collect generation prompts, media metadata, and subscription events to operate the app. '
          'Uploaded media is stored in cloud storage and can be deleted from your account settings. '
          'Analytics data is used for product improvement and retention measurement.',
        ),
      ),
    );
  }
}
