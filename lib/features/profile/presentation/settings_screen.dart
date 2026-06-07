import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_env.dart';
import '../../../core/theme/viral_design_tokens.dart';
import '../../../shared/widgets/viral_settings_widgets.dart';
import '../../../shared/widgets/viral_ui_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      'Settings',
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ViralTokens.paddingH,
                  24,
                  ViralTokens.paddingH,
                  24,
                ),
                children: [
                  const ViralSettingsSectionLabel('ACCOUNT'),
                  ViralSettingsGroup(
                    children: [
                      ViralSettingsTile(
                        icon: Icons.person_outline,
                        label: 'Account Settings',
                        onTap: () => context.push('/account-settings'),
                      ),
                      ViralSettingsTile(
                        icon: Icons.lock_outline,
                        label: 'Privacy',
                        onTap: () => context.push('/privacy'),
                      ),
                      ViralSettingsTile(
                        icon: Icons.notifications_none,
                        label: 'Notifications',
                        onTap: () => context.push('/notifications'),
                      ),
                      ViralSettingsTile(
                        icon: Icons.credit_card,
                        label: 'Subscription',
                        onTap: () => context.push('/paywall'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const ViralSettingsSectionLabel('SUPPORT'),
                  ViralSettingsGroup(
                    children: [
                      ViralSettingsTile(
                        icon: Icons.help_outline,
                        label: 'Support',
                        onTap: () async {
                          final uri = Uri.parse(AppEnv.supportUrl);
                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Email us at ${AppEnv.supportEmail}')),
                              );
                            }
                          }
                        },
                      ),
                      ViralSettingsTile(
                        icon: Icons.leaderboard_outlined,
                        label: 'Leaderboards',
                        onTap: () => context.push('/leaderboards'),
                      ),
                      ViralSettingsTile(
                        icon: Icons.info_outline,
                        label: 'Terms of Service',
                        onTap: () => context.push('/terms'),
                      ),
                      ViralSettingsTile(
                        icon: Icons.lock_outline,
                        label: 'Privacy Policy',
                        onTap: () => context.push('/privacy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  ViralDestructiveTile(
                    icon: Icons.logout,
                    label: 'Delete Account',
                    onTap: () => context.push('/delete-account'),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'CineMorph AI v1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ViralTokens.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '© 2026 CineMorph AI. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ViralTokens.textDim, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
