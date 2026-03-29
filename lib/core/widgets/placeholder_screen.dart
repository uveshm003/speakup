import 'package:flutter/material.dart';

import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/core/widgets/app_scaffold.dart';

/// Temporary route body until feature screens are implemented.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('SpeakUp', style: theme.textTheme.displayMedium),
              SizedBox(height: AppSpacing.md),
              Text('Design system is active — replace this screen with feature UI.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
