import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:speakup/features/navigation/presentation/bloc/navigation_event.dart';

/// Persistent 4-tab shell: bottom [NavigationBar] on narrow viewports,
/// [NavigationRail] sidebar when [AppLayout.isWide] (web / desktop).
class AppShell extends StatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((PackageInfo info) {
      if (mounted) {
        setState(() => _packageInfo = info);
      }
    });
  }

  void _onTabSelected(int index) {
    widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex);
    context.read<NavigationBloc>().add(NavigationTabSelected(index));
  }

  @override
  Widget build(BuildContext context) {
    final int shellIndex = widget.navigationShell.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      final NavigationBloc bloc = context.read<NavigationBloc>();
      if (bloc.state.selectedIndex != shellIndex) {
        bloc.add(NavigationRouteSynced(shellIndex));
      }
    });

    final ThemeData theme = Theme.of(context);
    final bool useRail = AppLayout.isWide(context);

    if (useRail) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            _Sidebar(selectedIndex: shellIndex, onDestinationSelected: _onTabSelected, packageInfo: _packageInfo),
            Expanded(child: widget.navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: shellIndex,
        onDestinationSelected: _onTabSelected,
        surfaceColor: theme.colorScheme.surface,
        outlineColor: theme.colorScheme.outline.withValues(alpha: 0.35),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.selectedIndex, required this.onDestinationSelected, required this.surfaceColor, required this.outlineColor});

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Color surfaceColor;
  final Color outlineColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surfaceColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Divider(height: 1, thickness: 1, color: outlineColor),
          NavigationBar(
            height: 72,
            elevation: 0,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: _destinations(context),
          ),
        ],
      ),
    );
  }

  static List<NavigationDestination> _destinations(BuildContext context) {
    return <NavigationDestination>[
      NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: 'Home'),
      NavigationDestination(icon: const Icon(Icons.favorite_border_rounded), selectedIcon: const Icon(Icons.favorite_rounded), label: 'Favorites'),
      NavigationDestination(icon: const Icon(Icons.history_outlined), selectedIcon: const Icon(Icons.history_rounded), label: 'History'),
      NavigationDestination(icon: const Icon(Icons.emoji_events_outlined), selectedIcon: const Icon(Icons.emoji_events_rounded), label: 'Challenges'),
      NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings_rounded), label: 'Settings'),
    ];
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selectedIndex, required this.onDestinationSelected, required this.packageInfo});

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final PackageInfo? packageInfo;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SizedBox(
        width: 260,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.25))),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.xl),
                  child: Text(
                    'SpeakUp',
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
                  ),
                ),
                Expanded(
                  child: NavigationRail(
                    extended: true,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    labelType: NavigationRailLabelType.all,
                    destinations: const <NavigationRailDestination>[
                      NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: Text('Home')),
                      NavigationRailDestination(
                        icon: Icon(Icons.favorite_border_rounded),
                        selectedIcon: Icon(Icons.favorite_rounded),
                        label: Text('Favorites'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.history_outlined),
                        selectedIcon: Icon(Icons.history_rounded),
                        label: Text('History'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.emoji_events_outlined),
                        selectedIcon: Icon(Icons.emoji_events_rounded),
                        label: Text('Challenges'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings_rounded),
                        label: Text('Settings'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Text(
                    packageInfo == null ? '…' : 'v${packageInfo!.version} (${packageInfo!.buildNumber})',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
