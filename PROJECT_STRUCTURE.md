# SpeakUp - Project Structure & Architecture Guide

Welcome to the **SpeakUp** application source code. This document outlines the architectural patterns and folder structures used in this repository, to help you quickly understand and navigate the codebase.

## Architectural Pattern

This project follows a **Feature-Driven Clean Architecture**. Instead of organizing files by their type (e.g., placing all models in one folder and all views in another), the codebase is organized by business **features**. 

Within each feature, the code is structurally divided into layers based on Clean Architecture principles, ensuring a separation of concerns:

1. **Domain Layer (`domain/`)**: The innermost core. Contains business logic, which is independent of any outer layers (UI, frameworks, databases).
2. **Data Layer (`data/`)**: Handles the retrieval and storage of data (e.g., API calls, local databases like ObjectBox or Hive). It implements the interfaces defined in the domain layer.
3. **Presentation Layer (`presentation/`)**: Contains the UI elements (Widgets, Screens) and state management components (BLoCs).

---

## High-Level Directory Overview

The primary source code is located inside the `lib/` directory.

### 1. `lib/config/`
Contains global, cross-feature configuration files that dictate how the application runs.
- **`router/`**: Holds GoRouter configuration (`app_router.dart`, `app_routes.dart`). Defines all application routes, branches (for the bottom navigation shell), and page transitions.
- **`theme/`**: Holds configuration for colors, spacing, typography, and other theming design tokens.
- **`app.dart`**: The root configuration of the app, heavily involved in setting up Dependency Injection (`RepositoryProvider` and `BlocProvider`) and wrapping the application in global services.

### 2. `lib/core/`
Contains shared utilities, constants, base classes, and widgets that are meant to be used seamlessly across *multiple* features.
- **`errors/`**: Defines common `Failure` or `Exception` types.
- **`widgets/`**: Reusable generic UI components (e.g., `AppShell`, custom buttons, dialogs) that aren't specific to any one feature but form the building blocks of the app's visual identity.

### 3. `lib/features/`
This is where the actual business logic of the application lives. Each sub-directory represents an independent slice of the app.
Key features include:
- **`card_draw/`**: Everything related to the library of topic cards (prompts) and the logic for drawing/shuffling them.
- **`challenges/`**: The system for users enrolling in spaced/repeated learning challenges.
- **`custom_categories/`**: The system allowing users to define their own topics and prompts.
- **`favorites/`**: Let users manage a wishlist / liked list of cards.
- **`history/`**: Keeps a log of past practice sessions (`SessionEnd` records).
- **`home/`**: The dashboard landing screen.
- **`navigation/`**: Manages the overarching state of which tab is active in the `AppShell`.
- **`onboarding/`**: The initial tutorial & setup screens.
- **`practice/`**: The core interactive capability (Timer, Audio recording, Session wrap-up).
- **`settings/`**: User preferences (Theme mode, text scaling, notifications).
- **`splash/`**: The initialization and loading screen of the app.

---

## Anatomy of a Feature Directory

If you open any non-trivial feature (e.g., `lib/features/practice/`), you will see the following Clean Architecture separation:

```text
lib/features/practice/
 ├── data/
 │    ├── models/         # Raw data models designed for storage/DBs (e.g., Hive schemas)
 │    └── repositories/   # Concrete implementations of Domain repository interfaces
 ├── domain/
 │    ├── entities/       # Pure Dart classes representing core business objects
 │    └── repositories/   # Interfaces definitions (abstract classes) for Data access
 └── presentation/
      ├── bloc/           # State Management (Events, States, and BLoC classes)
      ├── screens/        # Full-page Flutter widgets where users navigate
      └── widgets/        # Smaller UI components specific only to this feature
```

---

## State Management

The application heavily utilizes the **BLoC (Business Logic Component)** library for state management. 
- You will find a `bloc/` directory inside most feature `presentation/` folders.
- State is emitted back to the UI, enabling a reactive architecture.
- Global BLoCs (ones that persist beyond a single screen) are typically declared in `lib/config/app.dart` inside the `MultiBlocProvider`.

## Databases & Persistence

The project relies on two primary databases:
1. **[ObjectBox](https://docs.objectbox.io/)**: A superfast local database used for heavy objects or static collections (You'll see `objectbox.g.dart` generated in `lib/`).
2. **[Hive](https://pub.dev/packages/hive)**: A lightweight key-value database commonly used for settings and simple serializable data like challenge progress.

## How to use this structure correctly

- **Do not import `data/` directly from `presentation/`:** The UI should only ever communicate directly with the state manager (BLoC) or read entities from the `domain/`.
- **Global vs Local:** If a widget or function is used only inside `card_draw`, put it in `features/card_draw/presentation/widgets/`. If it is used by both `card_draw` AND `practice`, it belongs in `lib/core/widgets/`.
- **Always update Dependency Injection:** Whenever creating a new Repository or global BLoC, remember to provide it in the `MultiRepositoryProvider` or `MultiBlocProvider` inside `lib/config/app.dart`.
