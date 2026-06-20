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
      home: BlocProvider<SettingsBloc>.value(value: mockSettingsBloc, child: child),
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
      expect(find.text('Default Timer'), findsOneWidget);
      expect(find.text('Delete All Data'), findsOneWidget);
      expect(find.text('App Version'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Rate the App'), findsOneWidget);
    });

    testWidgets('taps Delete All Data triggers a confirm dialog', (WidgetTester tester) async {
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState(status: SettingsStatus.success, settings: UserSettings()));

      await tester.pumpWidget(buildInjectableWidget(child: const SettingsScreen()));

      await tester.tap(find.text('Delete All Data'));
      await tester.pumpAndSettle();

      expect(find.text('Delete All Data?'), findsOneWidget);

      // The confirm button is gated behind typing DELETE.
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pumpAndSettle();

      // Confirm the destructive action.
      await tester.tap(find.text('Delete Everything'));
      await tester.pumpAndSettle();

      verify(() => mockSettingsBloc.add(const DatabaseDeleteRequested())).called(1);
    });
  });
}
