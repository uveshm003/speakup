import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/core/widgets/shimmer_widget.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_event.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Settings Screen
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((PackageInfo info) {
      if (mounted) setState(() => _packageInfo = info);
    });
  }

  // ── Timer picker ──────────────────────────────────────────────────────────

  Future<void> _showTimerPicker(int currentSeconds) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (BuildContext sheetCtx) {
        return _DefaultTimerSheet(
          initialSeconds: currentSeconds,
          onPick: (int seconds) {
            Navigator.pop(sheetCtx);
            context.read<SettingsBloc>().add(DefaultTimerChanged(seconds));
          },
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _timerLabel(int seconds) {
    if (seconds < 60) return '$seconds second${seconds == 1 ? '' : 's'}';
    if (seconds % 60 == 0) {
      final int m = seconds ~/ 60;
      return '$m minute${m == 1 ? '' : 's'}';
    }
    return '${seconds ~/ 60}m ${seconds % 60}s';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listenWhen: (SettingsState p, SettingsState c) => c.errorMessage != null && c.errorMessage != p.errorMessage,
      listener: (BuildContext ctx, SettingsState state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(ctx)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!), behavior: SnackBarBehavior.floating));
        }
      },
      builder: (BuildContext ctx, SettingsState state) {
        if (state.status == SettingsStatus.initial || state.status == SettingsStatus.loading) {
          return const Scaffold(body: ShimmerListPlaceholder(itemCount: 6, itemHeight: 56));
        }

        final ThemeData theme = Theme.of(context);
        final bool isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerLowest,
          body: CustomScrollView(
            slivers: <Widget>[
              // ── Gradient app bar ────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: isDark ? theme.colorScheme.surface : theme.colorScheme.primary,
                foregroundColor: isDark ? theme.colorScheme.onSurface : Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
                  title: Text(
                    'Settings',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: isDark ? theme.colorScheme.onSurface : Colors.white,
                    ),
                  ),
                  background: _AppBarBackground(isDark: isDark, theme: theme),
                ),
              ),

              // ── Body content ────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    // ── PRACTICE DEFAULTS ─────────────────────────────────
                    _SectionLabel(label: 'Practice Defaults'),
                    const SizedBox(height: AppSpacing.sm),
                    _SettingsCard(
                      children: <Widget>[
                        _SettingsTile(
                          icon: Icons.timer_outlined,
                          iconColor: theme.colorScheme.primary,
                          title: 'Default Timer',
                          subtitle: _timerLabel(state.settings.defaultTimerSeconds),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showTimerPicker(state.settings.defaultTimerSeconds),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── ABOUT ─────────────────────────────────────────────
                    _SectionLabel(label: 'About'),
                    const SizedBox(height: AppSpacing.sm),
                    _SettingsCard(
                      children: <Widget>[
                        _SettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          iconColor: const Color(0xFF6366F1),
                          title: 'Privacy Policy',
                          trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                          onTap: () {
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(const SnackBar(content: Text('Privacy policy link coming soon.'), behavior: SnackBarBehavior.floating));
                          },
                        ),
                        _TileDivider(),
                        _SettingsTile(
                          icon: Icons.star_outline_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Rate the App',
                          trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                          onTap: () {
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                const SnackBar(content: Text('Thanks! App store rating coming soon.'), behavior: SnackBarBehavior.floating),
                              );
                          },
                        ),
                        _TileDivider(),
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: theme.colorScheme.onSurfaceVariant,
                          title: 'App Version',
                          trailing: Text(
                            _packageInfo == null ? '—' : '${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),

              // ── Footer ────────────────────────────────────────────
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.huge),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      'Built with Flutter 💙',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar background
// ─────────────────────────────────────────────────────────────────────────────

class _AppBarBackground extends StatelessWidget {
  const _AppBarBackground({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (isDark) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8), theme.colorScheme.surface],
          ),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Opacity(opacity: 0.06, child: Icon(Icons.settings_rounded, size: 130, color: theme.colorScheme.primary)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.85)],
        ),
      ),
      child: const Align(
        alignment: Alignment.centerRight,
        child: Opacity(opacity: 0.1, child: Icon(Icons.settings_rounded, size: 130, color: Colors.white)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings card container
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: isDark
            ? null
            : <BoxShadow>[BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single settings tile
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.iconColor, required this.title, this.subtitle, this.trailing, this.onTap});

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            // Icon badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              IconTheme(
                data: IconThemeData(color: theme.colorScheme.onSurfaceVariant, size: 20),
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thin divider between tiles
// ─────────────────────────────────────────────────────────────────────────────

class _TileDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpacing.lg + 36 + AppSpacing.md, // align with text
      endIndent: 0,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Default timer bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DefaultTimerSheet extends StatefulWidget {
  const _DefaultTimerSheet({required this.initialSeconds, required this.onPick});

  final int initialSeconds;
  final ValueChanged<int> onPick;

  @override
  State<_DefaultTimerSheet> createState() => _DefaultTimerSheetState();
}

class _DefaultTimerSheetState extends State<_DefaultTimerSheet> {
  static const List<int> _presets = <int>[30, 60, 120, 180, 300];
  static const List<String> _labels = <String>['30 sec', '1 min', '2 min', '3 min', '5 min'];

  late int _selected;
  bool _custom = false;
  final TextEditingController _customField = TextEditingController();
  bool _customMinutes = true;

  @override
  void initState() {
    super.initState();
    final int idx = _presets.indexOf(widget.initialSeconds);
    if (idx >= 0) {
      _selected = widget.initialSeconds;
      _custom = false;
    } else {
      _custom = true;
      _selected = widget.initialSeconds;
      if (widget.initialSeconds % 60 == 0) {
        _customMinutes = true;
        _customField.text = '${widget.initialSeconds ~/ 60}';
      } else {
        _customMinutes = false;
        _customField.text = '${widget.initialSeconds}';
      }
    }
  }

  @override
  void dispose() {
    _customField.dispose();
    super.dispose();
  }

  void _confirm() {
    int seconds = _selected;
    if (_custom) {
      final int? n = int.tryParse(_customField.text.trim());
      if (n == null || n <= 0) {
        HapticFeedback.lightImpact();
        return;
      }
      seconds = (_customMinutes ? n * 60 : n).clamp(1, 3600);
    }
    HapticFeedback.mediumImpact();
    widget.onPick(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, MediaQuery.paddingOf(context).bottom + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Sheet handle area header
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.timer_outlined, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Default Practice Timer', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(
                    'Sets the starting countdown for each session',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Preset chips grid
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: List<Widget>.generate(_presets.length, (int i) {
              final int sec = _presets[i];
              final bool on = !_custom && _selected == sec;
              return GestureDetector(
                onTap: () => setState(() {
                  _custom = false;
                  _selected = sec;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: on
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : (isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35) : theme.colorScheme.surfaceContainerLow),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: on ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: on ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: on ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Custom chip
          GestureDetector(
            onTap: () => setState(() {
              _custom = true;
              if (_customField.text.isEmpty) {
                _customField.text = _customMinutes ? '2' : '120';
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: _custom
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : (isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35) : theme.colorScheme.surfaceContainerLow),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: _custom ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: _custom ? 2 : 1,
                ),
              ),
              child: Text(
                'Custom…',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _custom ? FontWeight.w700 : FontWeight.w500,
                  color: _custom ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // Custom input — animated expand
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _custom
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextField(
                          controller: _customField,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16),
                          decoration: InputDecoration(
                            labelText: _customMinutes ? 'Minutes' : 'Seconds',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() => _customMinutes = !_customMinutes);
                            },
                            child: Text(_customMinutes ? 'Enter seconds instead' : 'Enter minutes instead'),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Save button
          FilledButton(
            onPressed: _confirm,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
