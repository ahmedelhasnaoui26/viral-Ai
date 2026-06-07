import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/viral_bottom_nav.dart';
import '../../explore/presentation/explore_screen.dart';
import '../../feed/presentation/feed_screen.dart';
import '../../generation/presentation/generation_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  ViralNavTab get _currentTab {
    switch (navigationShell.currentIndex) {
      case 1:
        return ViralNavTab.explore;
      case 2:
        return ViralNavTab.create;
      case 3:
        return ViralNavTab.feed;
      case 4:
        return ViralNavTab.profile;
      case 0:
      default:
        return ViralNavTab.home;
    }
  }

  void _onTabSelected(ViralNavTab tab) {
    final index = switch (tab) {
      ViralNavTab.home => 0,
      ViralNavTab.explore => 1,
      ViralNavTab.create => 2,
      ViralNavTab.feed => 3,
      ViralNavTab.profile => 4,
    };
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ViralScaffoldWithNav(
      currentTab: _currentTab,
      onTabSelected: _onTabSelected,
      body: navigationShell,
    );
  }
}

/// Branch roots used by [StatefulShellRoute].
class HomeBranchScreen extends StatelessWidget {
  const HomeBranchScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeScreen();
}

class ExploreBranchScreen extends StatelessWidget {
  const ExploreBranchScreen({super.key});

  @override
  Widget build(BuildContext context) => const ExploreScreen();
}

class ProfileBranchScreen extends StatelessWidget {
  const ProfileBranchScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}

class CreateBranchScreen extends StatelessWidget {
  const CreateBranchScreen({super.key});

  @override
  Widget build(BuildContext context) => const GenerationScreen();
}

class FeedBranchScreen extends StatelessWidget {
  const FeedBranchScreen({super.key});

  @override
  Widget build(BuildContext context) => const FeedScreen();
}
