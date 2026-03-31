import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/core/widgets/shimmer_widget.dart';
import 'package:speakup/features/settings/domain/entities/user_settings.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_event.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_state.dart';

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
      if (mounted) {
        setState(() => _packageInfo = info);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listenWhen: (SettingsState p, SettingsState c) => c.errorMessage != null && c.errorMessage != p.errorMessage,
      listener: (BuildContext context, SettingsState state) {
        final String? m = state.errorMessage;
        if (m != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
        }
      },
      builder: (BuildContext context, SettingsState state) {
        if (state.status == SettingsStatus.initial || state.status == SettingsStatus.loading) {
          return const Scaffold(body: ShimmerListPlaceholder(itemCount: 6, itemHeight: 56));
        }

        final ThemeData theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: <Widget>[
              _sectionLabel(context, 'Practice defaults'),
              _card(
                context,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: const Text('Default timer'),
                      subtitle: Text(_formatTimerLabel(state.settings.defaultTimerSeconds)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showTimerPicker(context, state.settings.defaultTimerSeconds),
                    ),
                  ],
                ),
              ),
              // _sectionLabel(context, 'App'),
              // _card(
              //   context,
              //   child: Column(
              //     children: <Widget>[
              //       // ListTile(
              //       //   title: const Text('Clear session history'),
              //       //   subtitle: const Text('Removes all practice sessions from this device'),
              //       //   trailing: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
              //       //   onTap: () => _confirmClearHistory(context),
              //       // ),
              //     ],
              //   ),
              // ),
              _sectionLabel(context, 'About'),
              _card(
                context,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: const Text('Privacy policy'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy policy link coming soon.')));
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Rate the app'),
                      trailing: const Icon(Icons.star_outline_rounded),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks! App store rating coming soon.')));
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('App version'),
                      trailing: Text(
                        _packageInfo == null ? '…' : '${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Center(
                  child: Text(
                    'Built with Flutter 💙',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Clear all session history?'),
        content: const Text('This removes every saved practice session. Your streak will be recalculated. This cannot be undone.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error, foregroundColor: Theme.of(ctx).colorScheme.onError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<SettingsBloc>().add(const SessionHistoryClearRequested());
    }
  }

  Future<void> _showTimerPicker(BuildContext context, int currentSeconds) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return _DefaultTimerSheet(
          initialSeconds: currentSeconds,
          onPick: (int seconds) {
            Navigator.pop(sheetContext);
            context.read<SettingsBloc>().add(DefaultTimerChanged(seconds));
          },
        );
      },
    );
  }

  static String _formatTimerLabel(int seconds) {
    if (seconds < 60) {
      return '$seconds second${seconds == 1 ? '' : 's'}';
    }
    if (seconds % 60 == 0) {
      final int m = seconds ~/ 60;
      return '$m minute${m == 1 ? '' : 's'}';
    }
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m}m ${s}s';
  }
}

class _DefaultTimerSheet extends StatefulWidget {
  const _DefaultTimerSheet({required this.initialSeconds, required this.onPick});

  final int initialSeconds;
  final ValueChanged<int> onPick;

  @override
  State<_DefaultTimerSheet> createState() => _DefaultTimerSheetState();
}

class _DefaultTimerSheetState extends State<_DefaultTimerSheet> {
  static const List<int> _presets = <int>[30, 60, 120, 180, 300];
  static const List<String> _labels = <String>['30s', '1m', '2m', '3m', '5m'];

  late int _selected;
  bool _custom = false;
  final TextEditingController _customField = TextEditingController();
  bool _customMinutes = true;

  @override
  void initState() {
    super.initState();
    final int i = _presets.indexOf(widget.initialSeconds);
    if (i >= 0) {
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Default practice timer', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: List<Widget>.generate(_presets.length, (int i) {
              final int sec = _presets[i];
              final bool on = !_custom && _selected == sec;
              return FilterChip(
                label: Text(_labels[i]),
                selected: on,
                onSelected: (_) {
                  setState(() {
                    _custom = false;
                    _selected = sec;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilterChip(
            label: const Text('Custom'),
            selected: _custom,
            onSelected: (_) {
              setState(() {
                _custom = true;
                if (_customField.text.isEmpty) {
                  _customField.text = _customMinutes ? '2' : '120';
                }
              });
            },
          ),
          if (_custom) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _customField,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: _customMinutes ? 'Minutes' : 'Seconds', border: const OutlineInputBorder()),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _customMinutes = !_customMinutes;
                  });
                },
                child: Text(_customMinutes ? 'Enter seconds instead' : 'Enter minutes instead'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () {
              int seconds = _selected;
              if (_custom) {
                final int? n = int.tryParse(_customField.text.trim());
                if (n == null || n <= 0) {
                  return;
                }
                seconds = _customMinutes ? n * 60 : n;
                seconds = seconds.clamp(1, 3600);
              }
              widget.onPick(seconds);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
