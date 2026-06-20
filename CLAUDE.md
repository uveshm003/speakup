# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**SpeakUp** — a fully offline Flutter app for English communication practice via guided card-draw sessions. Single codebase targeting all 6 Flutter platforms (Android, iOS, Web, Windows, macOS, Linux). No network calls are part of core functionality; keep it offline-first.

## Commands

```bash
flutter pub get                                                # install deps
flutter pub run build_runner build --delete-conflicting-outputs # codegen (see below)
flutter run                                                    # device/emulator (-d chrome|windows|macos|linux)
flutter analyze                                                # lint (uses package:flutter_lints)
flutter test                                                   # all tests
flutter test test/features/settings/presentation/bloc/settings_bloc_test.dart  # single file
flutter test --name "substring of test name"                  # single test by name
```

`build_runner` is **required before the first build and after any change** to Freezed models (`*.freezed.dart`), ObjectBox entities (regenerates `lib/objectbox.g.dart` + `lib/objectbox-model.json`), or Hive adapters (`*.g.dart`). Note: `hive_generator_io` is used instead of the classic `hive_generator` because the latter conflicts with `objectbox_generator` over `source_gen`.

## Architecture

Feature-Driven Clean Architecture. `lib/` has three roots:

- **`lib/config/`** — app startup (`app.dart`), GoRouter (`router/`), theme design tokens (`theme/`).
- **`lib/core/`** — cross-feature utilities, constants, errors, and shared widgets (`AppShell`, buttons, etc.).
- **`lib/features/`** — one directory per feature, each split into Clean Architecture layers.

Features: `card_draw`, `challenges`, `custom_categories`, `favorites`, `history`, `home`, `navigation`, `onboarding`, `practice`, `settings`, `splash`.

Each non-trivial feature follows:
```
feature/
 ├── data/          # models (ObjectBox/Hive wrappers), mappers, repository implementations
 ├── domain/        # pure Dart: entities, abstract repository interfaces, usecases
 └── presentation/  # bloc/ (events, states, BLoC), screens/, widgets/
```

### Rules (enforce in reviews and new code)
- **`presentation/` must not import `data/` directly.** UI talks only to its BLoC or reads `domain/` entities.
- Single-feature widgets → that feature's `presentation/widgets/`. Widgets shared across features → `lib/core/widgets/`.
- Use design tokens from `lib/config/theme/` (colors, spacing, radius, typography) — never hardcode Flutter colors/sizes.
- New BLoC or Repository → register it in the `MultiRepositoryProvider` / `MultiBlocProvider` in `lib/config/app.dart`.
- Most directories have a barrel file (e.g. `card_draw.dart`, `domain.dart`, `widgets.dart`) — add new public exports there.

## State, Persistence & Startup

- **State management:** `flutter_bloc` everywhere. No `setState()` for business logic. Global/persistent BLoCs live in `lib/config/app.dart`; screen-scoped ones are provided locally.
- **ObjectBox** — high-performance store for heavy entities (`TopicCard`, `PracticeSession`, `CustomCategory`). Accessed via `ObjectBoxStore`. Has a web/io conditional split (`objectbox_store_web.dart` / `objectbox_store_io.dart`).
- **Hive** — lightweight key-value store for `UserSettings` and `ChallengeProgress`. Box names are constants in `lib/core/constants/app_constants.dart`.
- **Startup** (`lib/main.dart` → `bootstrapDataLayer`): registers Hive adapters, opens boxes, and on non-web initializes ObjectBox + seeds the built-in deck from `assets/data/cards.json`. **ObjectBox is disabled on web** (`enableObjectBox: !kIsWeb`) — guard ObjectBox-dependent code paths accordingly. Google Fonts runtime fetching is disabled; all fonts are bundled under `assets/fonts/`.

## Navigation

GoRouter with a `ShellRoute`/`AppShell` providing bottom nav (mobile/tablet) and a navigation rail (desktop/web > 1024px). Tabs: `/home`, `/history`, `/favorites`, `/challenges`, `/settings`. The practice flow (`timer-setup` → `active-practice` → `session-end`) and card flow (`category-select` → `card-draw` → `card-detail`) push full-screen over the shell. Routes/branches are defined in `lib/config/router/`.

## Key Entities

- **TopicCard** — core practice unit (prompt, category, difficulty, guide points, vocab). ObjectBox; initial deck seeded from `assets/data/cards.json`.
- **PracticeSession** — practice log (duration, timestamp, completion). ObjectBox; drives history and streak heatmaps (`streak_calculator.dart`).
- **ChallengeProgress** — spaced/repeated learning pathways. Hive.
