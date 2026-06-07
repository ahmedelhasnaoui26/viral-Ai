import 'package:flutter/material.dart';

import '../../core/layout/viral_layout.dart';
import '../../core/theme/viral_design_tokens.dart';

enum ViralNavTab { home, explore, create, feed, profile }

class ViralBottomNav extends StatelessWidget {
  const ViralBottomNav({
    required this.currentTab,
    required this.onTabSelected,
    super.key,
  });

  final ViralNavTab currentTab;
  final ValueChanged<ViralNavTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final metrics = ViralLayout.bottomNavMetrics(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ViralTokens.black,
        border: Border(top: BorderSide(color: Color(0xFF111111), width: 1)),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: metrics.safeAreaMinimumBottom),
        child: Padding(
          padding: EdgeInsets.only(top: metrics.topPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _NavItem(
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                selected: currentTab == ViralNavTab.home,
                metrics: metrics,
                onTap: () => onTabSelected(ViralNavTab.home),
              ),
              _NavItem(
                label: 'Explore',
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                selected: currentTab == ViralNavTab.explore,
                metrics: metrics,
                onTap: () => onTabSelected(ViralNavTab.explore),
              ),
              _CreateNavItem(
                selected: currentTab == ViralNavTab.create,
                metrics: metrics,
                onTap: () => onTabSelected(ViralNavTab.create),
              ),
              _NavItem(
                label: 'Feed',
                icon: Icons.play_circle_outline,
                activeIcon: Icons.play_arrow_rounded,
                selected: currentTab == ViralNavTab.feed,
                metrics: metrics,
                onTap: () => onTabSelected(ViralNavTab.feed),
              ),
              _NavItem(
                label: 'Profile',
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                selected: currentTab == ViralNavTab.profile,
                metrics: metrics,
                onTap: () => onTabSelected(ViralNavTab.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateNavItem extends StatelessWidget {
  const _CreateNavItem({
    required this.selected,
    required this.metrics,
    required this.onTap,
  });

  final bool selected;
  final BottomNavMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = metrics.iconBoxSize + 8;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: selected ? ViralTokens.primaryGradient : null,
                      color: selected ? null : ViralTokens.surface,
                      border: selected
                          ? null
                          : Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      boxShadow: selected ? ViralTokens.primaryButtonGlow : null,
                    ),
                    child: Icon(
                      Icons.add,
                      color: selected ? ViralTokens.textPrimary : ViralTokens.inactiveNav,
                      size: metrics.iconSize + 2,
                    ),
                  ),
                ),
                SizedBox(height: metrics.iconLabelGap - 2),
                Text(
                  'Create',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: metrics.labelFontSize,
                    height: metrics.labelLineHeight / metrics.labelFontSize,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? ViralTokens.textPrimary : ViralTokens.inactiveNav,
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.metrics,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final BottomNavMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: metrics.iconBoxSize,
                  height: metrics.iconBoxSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: selected ? ViralTokens.primaryGradient : null,
                  ),
                  child: Icon(
                    selected ? activeIcon : icon,
                    color: selected ? ViralTokens.textPrimary : ViralTokens.inactiveNav,
                    size: metrics.iconSize,
                  ),
                ),
                SizedBox(height: metrics.iconLabelGap),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: metrics.labelFontSize,
                    height: metrics.labelLineHeight / metrics.labelFontSize,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? ViralTokens.textPrimary : ViralTokens.inactiveNav,
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

class ViralScaffoldWithNav extends StatelessWidget {
  const ViralScaffoldWithNav({
    required this.currentTab,
    required this.onTabSelected,
    required this.body,
    this.floatingActionButton,
    super.key,
  });

  final ViralNavTab currentTab;
  final ValueChanged<ViralNavTab> onTabSelected;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralTokens.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: ViralBottomNav(
        currentTab: currentTab,
        onTabSelected: onTabSelected,
      ),
    );
  }
}
