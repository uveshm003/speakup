import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/practice/presentation/bloc/session_end_bloc.dart';
import 'package:speakup/features/practice/presentation/bloc/session_end_event.dart';
import 'package:speakup/features/practice/presentation/bloc/session_end_state.dart';
import 'package:speakup/features/practice/presentation/utils/practice_format.dart';
import 'package:speakup/features/practice/presentation/widgets/confetti_burst.dart';

/// Shown after practice; [SessionEndBloc] is provided by the router.
class SessionEndScreen extends StatelessWidget {
  const SessionEndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SessionEndBloc, SessionEndState>(
          builder: (BuildContext context, SessionEndState state) {
            if (state.status == SessionEndStatus.loading || state.status == SessionEndStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == SessionEndStatus.failure) {
              return _FailureView(message: state.errorMessage ?? 'Something went wrong');
            }
            return _SuccessView(state: state);
          },
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () {
              context.read<SessionEndBloc>().add(const SessionEndLoadRequested());
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.state});

  final SessionEndState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final card = state.card!;
    final String durationLabel = formatPracticeDurationLabel(state.elapsedSeconds);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const ConfettiBurst(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Great session! 🎉',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(card.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.md),
                  _SummaryRow(label: 'Duration', value: durationLabel),
                  const SizedBox(height: AppSpacing.sm),
                  _SummaryRow(label: 'Category', value: card.category),
                  const SizedBox(height: AppSpacing.lg),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _CompletedBadge(completed: state.wasCompleted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: state.streakIncreased
                ? TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.82, end: 1),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.elasticOut,
                    builder: (BuildContext context, double scale, Widget? child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Column(
                      children: <Widget>[
                        Text('🔥', style: GoogleFonts.plusJakartaSans(fontSize: 56)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${state.streak} day streak!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: <Widget>[
                      Text('🔥', style: GoogleFonts.plusJakartaSans(fontSize: 56)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${state.streak}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 36, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Keep it up!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                context.go(AppRoutes.categorySelect);
              },
              child: const Text('Draw New Card'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                context.pushReplacement(AppRoutes.timerSetup, extra: card);
              },
              child: const Text('Practice This Again'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: () => context.go(AppRoutes.home), child: const Text('Go Home')),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'This week: ${state.weekSessionsCount} sessions',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 96,
          child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color bg = completed ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer;
    final Color fg = completed ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onErrorContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(
        completed ? 'Completed' : 'Incomplete',
        style: theme.textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}
