import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakup/core/widgets/shimmer_widget.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_event.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_state.dart';
import 'package:speakup/features/settings/presentation/screens/settings_screen.dart';
import 'package:speakup/features/settings/domain/entities/user_settings.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState> implements SettingsBloc {}

void main() {
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
  });

  Widget buildInjectableWidget({required Widget child}) {
    return MaterialApp(
      home: BlocProvider<SettingsBloc>.value(
        value: mockSettingsBloc,
        child: child,
      ),
    );
  }

  group('SettingsScreen', () {
    testWidgets('renders ShimmerListPlaceholder when status is initial', (WidgetTester tester) async {
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState(status: SettingsStatus.initial));

      await tester.pumpWidget(buildInjectableWidget(child: const SettingsScreen()));

      expect(find.byType(ShimmerListPlaceholder), findsOneWidget);
    });

    testWidgets('renders Settings components when status is success', (WidgetTester tester) async {
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState(status: SettingsStatus.success, settings: UserSettings()));

      await tester.pumpWidget(buildInjectableWidget(child: const SettingsScreen()));

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Default timer'), findsOneWidget);
      expect(find.text('Clear session history'), findsOneWidget);
      expect(find.text('App version'), findsOneWidget);
      expect(find.text('Privacy policy'), findsOneWidget);
      expect(find.text('Rate the app'), findsOneWidget);
    });

    testWidgets('taps Clear session history triggers dialog', (WidgetTester tester) async {
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState(status: SettingsStatus.success, settings: UserSettings()));

      await tester.pumpWidget(buildInjectableWidget(child: const SettingsScreen()));

      await tester.tap(find.text('Clear session history'));
      await tester.pumpAndSettle();

      expect(find.text('Clear all session history?'), findsOneWidget);
      
      // Tap Clear all
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      verify(() => mockSettingsBloc.add(const SessionHistoryClearRequested())).called(1);
    });
  });
}
