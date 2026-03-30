import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/history/presentation/bloc/history_bloc.dart';
import 'package:speakup/features/history/presentation/bloc/history_event.dart';
import 'package:speakup/features/practice/domain/repositories/session_repository.dart';
import 'package:speakup/features/settings/domain/entities/user_settings.dart';
import 'package:speakup/features/settings/domain/repositories/settings_repository.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_event.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_state.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

class MockHistoryBloc extends Mock implements HistoryBloc {}

void main() {
  late MockSettingsRepository mockSettingsRepository;
  late MockSessionRepository mockSessionRepository;
  late MockHistoryBloc mockHistoryBloc;

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    mockSessionRepository = MockSessionRepository();
    mockHistoryBloc = MockHistoryBloc();
    
    when(() => mockSettingsRepository.getSettings())
        .thenAnswer((Invocation _) async => const Right<Failure, UserSettings>(UserSettings()));
  });

  SettingsBloc buildBloc() {
    return SettingsBloc(
      settingsRepository: mockSettingsRepository,
      sessionRepository: mockSessionRepository,
      historyBloc: mockHistoryBloc,
    );
  }

  group('SettingsBloc', () {
    test('initial state is valid', () {
      expect(buildBloc().state, const SettingsState());
    });

    blocTest<SettingsBloc, SettingsState>(
      'emits [loading, success] on instantiation successfully',
      build: () {
        when(() => mockSettingsRepository.getSettings())
            .thenAnswer((Invocation _) async => const Right<Failure, UserSettings>(UserSettings(defaultTimerSeconds: 60)));
        return buildBloc();
      },
      expect: () => <SettingsState>[
        const SettingsState(status: SettingsStatus.loading),
        const SettingsState(status: SettingsStatus.success, settings: UserSettings(defaultTimerSeconds: 60)),
      ],
      verify: (SettingsBloc bloc) {
        verify(() => mockSettingsRepository.getSettings()).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [loading, failure] on instantiation failure',
      build: () {
        when(() => mockSettingsRepository.getSettings())
            .thenAnswer((Invocation _) async => const Left<Failure, UserSettings>(CacheFailure('Load error')));
        return buildBloc();
      },
      expect: () => <SettingsState>[
        const SettingsState(status: SettingsStatus.loading),
        const SettingsState(status: SettingsStatus.failure, errorMessage: 'Load error'),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'saves new default timer on DefaultTimerChanged',
      build: () {
        when(() => mockSettingsRepository.getSettings())
            .thenAnswer((Invocation _) async => const Right<Failure, UserSettings>(UserSettings()));
        when(() => mockSettingsRepository.saveSettings(any()))
            .thenAnswer((Invocation _) async => const Right<Failure, void>(null));
        return buildBloc();
      },
      setUp: () {
        registerFallbackValue(const UserSettings());
      },
      skip: 2,
      act: (SettingsBloc bloc) => bloc.add(const DefaultTimerChanged(90)),
      expect: () => <SettingsState>[
        const SettingsState(status: SettingsStatus.success, settings: UserSettings(defaultTimerSeconds: 90)),
      ],
      verify: (SettingsBloc bloc) {
        verify(() => mockSettingsRepository.saveSettings(const UserSettings(defaultTimerSeconds: 90))).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'clears history and triggers HistoryLoadRequested on SessionHistoryClearRequested',
      build: () {
        when(() => mockSessionRepository.clearAllSessions())
            .thenAnswer((Invocation _) async => const Right<Failure, void>(null));
        when(() => mockSettingsRepository.updateStreak())
            .thenAnswer((Invocation _) async => const Right<Failure, void>(null));
        when(() => mockSettingsRepository.getSettings())
            .thenAnswer((Invocation _) async => const Right<Failure, UserSettings>(UserSettings()));
        return buildBloc();
      },
      skip: 2,
      act: (SettingsBloc bloc) => bloc.add(const SessionHistoryClearRequested()),
      expect: () => <SettingsState>[
        const SettingsState(status: SettingsStatus.loading, settings: UserSettings()),
        const SettingsState(status: SettingsStatus.success, settings: UserSettings()),
      ],
      verify: (SettingsBloc bloc) {
        verify(() => mockSessionRepository.clearAllSessions()).called(1);
        verify(() => mockSettingsRepository.updateStreak()).called(1);
        verify(() => mockHistoryBloc.add(const HistoryLoadRequested())).called(1);
      },
    );
  });
}
