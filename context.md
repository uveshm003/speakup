# SpeakUp - AI Context File

This file provides comprehensive context for AI assistants analyzing, navigating, or modifying the SpeakUp repository.

## 🎤 Project Overview
**SpeakUp** is a fully-offline Flutter application designed to help non-native English speakers practice their communication skills. It uses a guided card-draw experience with built-in or custom topic cards featuring mini-guides and vocabulary boosts. It supports all 6 major Flutter platforms: Android, iOS, Web, Windows, macOS, and Linux.

## 🛠 Tech Stack
- **Framework & Language**: Flutter (SDK `^3.11.0` / 3.19+ req), Dart (3.3+)
- **State Management**: `flutter_bloc` + `bloc` (Event-driven state, no UI `setState()` for business logic)
- **Routing**: `go_router` (using `ShellRoute` for persistent app navigation like bottom nav bar or navigation rail)
- **Databases & Local Storage**: 
  - `objectbox` (High-performance reactive queries for heavy entities like `TopicCard`, `PracticeSession`, `CustomCategory`).
  - `hive` (Lightweight key-value store for app settings, theme, and `ChallengeProgress`).
- **Code Generation**: `build_runner`, `freezed` (Immutable models), `json_serializable`, `objectbox_generator`, `hive_generator_io`.
- **Dependency Injection**: Context-based `MultiRepositoryProvider` and `MultiBlocProvider` registered mostly in `lib/config/app.dart`.
- **UI/Styling**: 
  - `google_fonts` (Plus Jakarta Sans for display, Inter for body).
  - Centralized theme definitions in `lib/config/theme/`.

## 🏗 Architecture & Code Structure
The application strictly follows **Feature-Driven Clean Architecture**. The code inside `lib/` is divided into three main root folders:

1. **`lib/config/`**: Global configuration, routing (`app_router.dart`), themes, and app startup logic (`app.dart`).
2. **`lib/core/`**: Shared utilities, constants, cross-feature widgets (`AppShell`), and base error classes.
3. **`lib/features/`**: All business logic grouped by feature boundary. 

Each feature within `lib/features/` (e.g., `practice/`, `card_draw/`, `home/`) is internally split into three Clean Architecture layers:
- **`domain/`**: Pure Dart. Business logic, entity representations, and abstract Repository interfaces.
- **`data/`**: Data models (ObjectBox/Hive wrappers), concrete implementations of Repositories, handling DB retrieval/storage.
- **`presentation/`**: Screen widgets, feature-specific UI components, and the `bloc/` directory (Events, States, BLoCs).

### Architectural Rules
- UI components in `presentation/` *must not* directly access the `data/` layer. They should only emit events to their `BLoC` or read from the `domain/` layer.
- Components used only in one feature belong in that feature's `presentation/widgets/`. Components shared across multiple features belong in `lib/core/widgets/`.

## 🗂 Key Entities
- **TopicCard**: Core unit of practice. Contains prompt, category, difficulty, guide points, and vocabulary. Stored in ObjectBox. Initial deck seeded from `assets/data/cards.json`.
- **PracticeSession**: Logs of a user's practice (duration, timestamp, completion status). Stored in ObjectBox. Drives history and streak heatmaps.
- **ChallengeProgress**: Driven by Hive; tracks spaced/repeated learning pathways.

## 🚀 Navigation Context
The app uses a main `AppShell` with bottom navigation on mobile/tablet and a sidebar navigation rail on desktop/web (widths > 1024px).
Key routes/tabs:
- Dashboard (`/home`)
- Library/Filtering/Drawing (`/home/category-select` -> `/home/card-draw` -> `/home/card-detail`)
- Practice Flow (`/home/timer-setup` -> `/home/active-practice` -> `/home/session-end`) — *These push full-screen over the bottom nav shell.*
- History & Heatmap (`/history`)
- Favorites (`/favorites`)
- Challenges (`/challenges`)
- Settings & Custom Categories (`/settings`, `/custom-categories`)

## 💡 Reminders for Code Modification
1. Always run `flutter pub run build_runner build --delete-conflicting-outputs` if you modify any `*.freezed.dart`, ObjectBox entities, or Hive Box schemas.
2. If introducing a new BLoC or Repository, ensure it is properly injected in `lib/config/app.dart`.
3. Use pre-defined design tokens from `lib/config/theme/` (colors, spacing, typography) rather than hardcoded flutter colors.
4. Keep the offline-first nature intact. Do not introduce network calls for core functionality.
