<div align="center">

# 🎤 SpeakUp

### Speak with confidence. Every day.

A fully offline Flutter app for English communication practice through guided card-draw sessions — built for all 6 Flutter platforms from a single codebase.

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-5C4EFA?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-22C55E?style=for-the-badge)]()
[![Offline](https://img.shields.io/badge/100%25-Offline-F59E0B?style=for-the-badge)]()

<br/>

[Features](#-features) · [Tech Stack](#-tech-stack) · [Architecture](#-architecture) · [Getting Started](#-getting-started) · [Screens](#-app-screens) · [Roadmap](#-roadmap)

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Running on All Platforms](#-running-on-all-platforms)
- [App Screens](#-app-screens)
- [Data Models](#-data-models)
- [State Management](#-state-management)
- [Navigation](#-navigation)
- [Local Storage Strategy](#-local-storage-strategy)
- [Built-in Card Deck](#-built-in-card-deck)
- [Contributing](#-contributing)
- [Roadmap](#-roadmap)
- [License](#-license)

---

## 🧠 Overview

**SpeakUp** is a fully offline Flutter application that helps beginners practice spoken English and communication skills through a guided card-draw experience. Unlike generic flashcard or topic-picker tools, SpeakUp equips users with contextual guidance and vocabulary support *before* they speak — reducing intimidation and enabling confident daily practice.

> **The core loop:** Pick a category → Draw a card → Read the Mini Guide → Practice with a timer → Build your streak.

### Who is SpeakUp for?

| User | Goal |
|------|------|
| 🌍 Non-native English speakers | Building conversational fluency |
| 🎓 Students | Preparing for IELTS, TOEFL, debates, or public speaking |
| 💼 Working professionals | Improving business communication and presentation skills |
| 👩‍🏫 Educators | Creating guided speaking exercises using custom topic cards |

---

## ✨ Features

### Core Features

| Feature | Description |
|---------|-------------|
| 🃏 **Card Draw System** | Draw random topic cards from 7 built-in categories with a smooth 3D flip animation |
| 📖 **Mini Guide** | Every card includes 3–5 structured bullet points — context, arguments, and angles to think about before speaking |
| 📚 **Vocabulary Boost** | 5 topic-relevant, intermediate-to-advanced English words with definitions per card — curated, not generic |
| ⏱ **Practice Timer** | Preset durations (30s, 1m, 2m, 3m, 5m) or custom input. Countdown ring changes color as time runs out |
| 👀 **Peek Drawer** | Slide-up overlay during active practice gives access to Mini Guide and Vocabulary without stopping the timer |
| 📅 **Session History** | Every completed session is logged locally with card title, category, duration, and timestamp |
| 🔥 **Streak Tracking** | Consecutive daily practice streak with a calendar heatmap view |
| ❤️ **Favorites** | Bookmark any card. Quickly re-draw from your saved favorites |
| 🏷 **Difficulty Filtering** | Filter cards by Beginner, Intermediate, or Advanced before drawing |
| ✏️ **Custom Categories** | Create your own topic decks with custom cards, optional guide bullets, and vocabulary — saved locally |
| 🎯 **Onboarding** | 3-screen carousel shown only on first launch. Replayable from Settings |
| ⚙️ **Settings** | Default timer, text size scaling, dark/light/system theme, clear history |

### Platform Support

| Android | iOS | Web | Windows | macOS | Linux |
|:-------:|:---:|:---:|:-------:|:-----:|:-----:|
| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

All platforms share a single codebase. Navigation adapts: bottom navigation bar on mobile/tablet, sidebar navigation rail on desktop/web (width > 1024px).

---

## 🛠 Tech Stack

| Category | Package | Purpose |
|----------|---------|---------|
| **State Management** | `flutter_bloc` + `bloc` | Predictable, event-driven state across all features |
| **Navigation** | `go_router` | Declarative routing with `ShellRoute` for persistent bottom nav |
| **Structured Storage** | `objectbox` | High-performance local DB for cards, sessions, categories |
| **Preferences** | `hive` + `hive_flutter` | Lightweight key-value store for user settings |
| **Code Generation** | `build_runner` + `freezed` | Immutable models, union types, JSON serialization |
| **DI** | `get_it` + `injectable` | Service locator for repositories and use cases |
| **Fonts** | `google_fonts` | Plus Jakarta Sans (display) + Inter (body) |
| **Platform Sizing** | `window_manager` | Minimum window size control on desktop platforms |
| **App Info** | `package_info_plus` | App version display in Settings |
| **Equality** | `equatable` | Value equality for BLoC states and domain entities |

---

## 🏗 Architecture

SpeakUp follows **Clean Architecture** with a **feature-first folder structure**. Each feature is self-contained and composed of three layers:

```
UI Event  →  BLoC  →  Use Case  →  Repository Interface  →  Repository Impl  →  ObjectBox / Hive / JSON Asset
```

### Layers

**`data/`** — Data access and persistence. Contains ObjectBox entity models, repository implementations, and data sources (bundled JSON asset loader for built-in cards, ObjectBox queries for user data).

**`domain/`** — Pure Dart, zero Flutter dependencies. Contains abstract repository interfaces, domain entity classes, and use case classes. Each use case encapsulates a single business action.

**`presentation/`** — Flutter widgets, screens, and BLoC classes. BLoC handles all business logic triggered by UI events and emits states the UI rebuilds from. No `setState()` in any screen that has a BLoC.

---

## 📁 Project Structure

```
lib/
├── config/
│   ├── router/            # GoRouter configuration & route constants
│   ├── theme/             # AppTheme, AppColors, AppTextStyles, AppSpacing
│   └── app.dart           # Root App widget, MultiBlocProvider setup
├── core/
│   ├── constants/         # AppStrings, AppAssets, AppConstants
│   ├── errors/            # Failure base classes
│   ├── extensions/        # BuildContext, String, DateTime helpers
│   ├── utils/             # ObjectBoxStore, Responsive, StreakCalculator
│   └── widgets/           # AppButton, AppCard, DifficultyBadge, EmptyState...
├── features/
│   ├── home/
│   ├── card_draw/
│   ├── practice/
│   ├── history/
│   ├── favorites/
│   ├── custom_categories/
│   └── settings/
└── main.dart
```

Each feature follows this internal structure:

```
feature/
├── data/
│   ├── models/            # ObjectBox @Entity classes
│   ├── repositories/      # Repository implementations
│   └── sources/           # Data sources (local DB, asset JSON)
├── domain/
│   ├── entities/          # Pure Dart domain models
│   ├── repositories/      # Abstract repository interfaces
│   └── usecases/          # Single-responsibility use case classes
└── presentation/
    ├── bloc/              # BLoC, Event, State files
    ├── screens/           # Screen widgets
    └── widgets/           # Feature-local UI components
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter 3.19+](https://docs.flutter.dev/get-started/install)
- Dart 3.3+ *(bundled with Flutter)*
- Git
- Android Studio or VS Code with the Flutter extension

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/your-username/speakup.git
cd speakup
```

**2. Install dependencies**

```bash
flutter pub get
```

**3. Generate code**

ObjectBox, Hive TypeAdapters, and Freezed models are all generated. Run this before the first build and after any model changes:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**4. Run the app**

```bash
flutter run                     # connected device or emulator
flutter run -d chrome           # web
flutter run -d windows          # Windows desktop
flutter run -d macos            # macOS desktop
flutter run -d linux            # Linux desktop
```

---

## 📦 Running on All Platforms

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS  (requires macOS + Xcode)
flutter build ios --release

# Web
flutter build web --release --web-renderer canvaskit

# Windows
flutter build windows --release

# macOS  (requires macOS)
flutter build macos --release

# Linux
flutter build linux --release
```

> **Note:** iOS and macOS builds require a Mac with Xcode installed. Linux builds require GTK development libraries (`libgtk-3-dev`).

---

## 📱 App Screens

| Screen | Route | Description |
|--------|-------|-------------|
| Splash | `/` | Animated app entry. Navigates to onboarding or home based on first-launch flag |
| Onboarding | `/onboarding` | 3-page carousel explaining the app. Shown only on first launch |
| Home | `/home` | Streak counter, Quick Draw CTA, category grid, recent sessions |
| Category Select | `/home/category-select` | Choose category and difficulty filter before drawing |
| Card Draw | `/home/card-draw` | 3D card flip animation revealing the topic. Swipe to re-draw |
| Card Detail | `/home/card-detail` | Full topic view with expandable Mini Guide and Vocabulary Boost |
| Timer Setup | `/home/timer-setup` | Choose practice duration with presets or custom input |
| Active Practice | `/home/active-practice` | Fullscreen focus mode. Countdown ring + slide-up peek drawer |
| Session End | `/home/session-end` | Session summary, streak celebration, and next-action CTAs |
| History | `/history` | Streak heatmap calendar + session log grouped by date |
| Favorites | `/favorites` | Grid of bookmarked cards with quick draw |
| My Categories | `/custom-categories` | List of user-created category decks. Create, edit, delete |
| Settings | `/settings` | Timer defaults, text size, theme, data management |

---

## 🗂 Data Models

### `TopicCard` *(ObjectBox Entity)*

```dart
class TopicCard {
  String cardId;           // UUID
  String title;            // The speaking topic / prompt
  String category;         // One of 7 built-in categories, or custom
  Difficulty difficulty;   // beginner | intermediate | advanced
  List<String> guide;      // 3–5 structured bullet hints
  List<VocabWord> vocab;   // 4–6 word + meaning pairs
  bool isCustom;           // false for built-in, true for user-created
  bool isFavorite;         // persisted favorite state
}
```

### `PracticeSession` *(ObjectBox Entity)*

```dart
class PracticeSession {
  String sessionId;        // UUID
  String cardId;           // Reference to TopicCard
  String cardTitle;        // Denormalized for history display
  String category;
  int durationSeconds;     // Actual practiced duration
  bool wasCompleted;       // true = timer hit zero, false = manually ended
  DateTime completedAt;
}
```

### `UserSettings` *(Hive)*

```dart
class UserSettings extends HiveObject {
  int defaultTimerSeconds;     // default: 120
  double textSizeScale;        // default: 1.0
  bool hasSeenOnboarding;      // default: false
  String themeModeRaw;         // 'system' | 'light' | 'dark'
  int currentStreak;
  DateTime? lastSessionDate;
}
```

---

## 🔄 State Management

SpeakUp uses **flutter_bloc** throughout. Every screen is driven by a dedicated BLoC — no `setState()` is used in any screen with business logic. All BLoCs share the same structure:

```dart
// 1. Events — what the user or system triggers
sealed class HomeEvent {}
class HomeLoadRequested extends HomeEvent {}
class HomeQuickDrawRequested extends HomeEvent {}

// 2. State — what the UI reads from
class HomeState extends Equatable {
  final int streak;
  final int todaySessions;
  final HomeStatus status; // initial | loading | loaded | error
  ...
}

// 3. BLoC — maps events to states via use cases
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._getStreak) : super(HomeState.initial()) {
    on<HomeLoadRequested>(_onLoad);
  }
}
```

### BLoC Inventory

| BLoC | Responsibility |
|------|---------------|
| `HomeBloc` | Streak, session count, recent categories |
| `CategoryBloc` | Category list, difficulty filtering |
| `CardDrawBloc` | Current card, flip state, favorite toggle |
| `TimerBloc` | Countdown via `Stream.periodic`, pause/resume/stop |
| `SessionEndBloc` | Session persistence, streak recalculation |
| `HistoryBloc` | Session log, heatmap data |
| `FavoritesBloc` | Favorites list, quick draw |
| `CustomCategoryBloc` | CRUD for user categories |
| `CustomCardBloc` | CRUD for cards within a category |
| `SettingsBloc` | Read/write all user settings |
| `ThemeBloc` | App-wide theme mode |

---

## 🧭 Navigation

Navigation uses **go_router** with a `ShellRoute` wrapping the four main tabs (Home, Favorites, History, Settings). The practice flow screens (Card Draw → Timer → Active Practice → Session End) push full-screen over the shell with no bottom nav visible.

```dart
final router = GoRouter(
  redirect: (context, state) {
    final seenOnboarding = settingsRepo.getSettings().hasSeenOnboarding;
    if (!seenOnboarding) return AppRoutes.onboarding;
    return null;
  },
  routes: [
    GoRoute(path: AppRoutes.onboarding, ...),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [ /* Home, Favorites, History, Settings */ ],
    ),
    GoRoute(path: AppRoutes.cardDraw, ...),   // full-screen, outside shell
    GoRoute(path: AppRoutes.activePractice, ...),
  ],
);
```

**Responsive navigation:** Bottom `NavigationBar` on mobile/tablet. Left `NavigationRail` sidebar on screens wider than 1024px, showing the app logo, nav labels, and app version.

---

## 💾 Local Storage Strategy

| Store | Used For | Why |
|-------|----------|-----|
| **ObjectBox** | `TopicCard`, `PracticeSession`, `CustomCategory` entities | High-performance reactive queries; indexed on `category` and `completedAt` |
| **Hive** | `UserSettings` only | Lightweight key-value store for simple preference data |
| **JSON Asset** | Built-in card deck (`assets/data/cards.json`) | Bundled at build time; seeded into ObjectBox on first launch via a `cardsSeeded` Hive flag |

- **Total storage footprint:** < 50 MB including the full bundled card deck and all user data
- **No network calls:** SpeakUp is 100% offline — no analytics, no crash reporting, no cloud sync in the MVP

---

## 🃏 Built-in Card Deck

SpeakUp ships with **70 curated topic cards** across 7 categories. Each card includes a Mini Guide and Vocabulary Boost authored specifically for that topic — not generated at runtime.

| Category | Cards | Topics Include |
|----------|:-----:|---------------|
| 💬 Opinion & Debate | 10 | Social media age limits, remote work vs office, free speech |
| 📰 Current Affairs | 10 | AI in everyday life, climate responsibility, digital privacy |
| 🌱 Personal Growth | 10 | Overcoming failure, building habits, dealing with criticism |
| 💻 Technology | 10 | Smartphones and human connection, coding in schools, automation |
| 🌍 Culture & Society | 10 | Beauty standards, second languages, generational differences |
| 💼 Business & Work | 10 | What makes a great leader, gig economy, workplace communication |
| 📖 Storytelling & Personal | 10 | Moments that changed you, someone who influenced you, life goals |

**Difficulty distribution per category:** ~3 Beginner · ~4 Intermediate · ~3 Advanced

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository and create your branch from `main`
2. Run `flutter analyze` — 0 errors and 0 warnings required before submitting
3. Follow the existing Clean Architecture and BLoC patterns — no `setState()` in screens with BLoCs
4. Do not introduce any network dependencies — SpeakUp must remain fully offline
5. Open a Pull Request with a clear description of what changed and why

### Code Style

- Run `flutter format .` before committing
- Follow Dart naming conventions: `camelCase` for variables/functions, `PascalCase` for classes
- Keep BLoC events and states in separate files from the BLoC class
- No `print()` statements — use a logger in debug mode only

---

## 🗺 Roadmap

### v1.0 — MVP *(Current)*
- [x] 70 built-in cards across 7 categories with Mini Guide + Vocabulary Boost
- [x] Card flip animation, category + difficulty filtering
- [x] Practice timer with peek drawer (guide access mid-session)
- [x] Session history, streak tracking, calendar heatmap
- [x] Custom categories and cards
- [x] Favorites, onboarding, dark/light/system theme
- [x] All 6 Flutter platforms

### v1.1 — Post-MVP
- [ ] Voice recording with self-review playback
- [ ] Daily practice reminders (push notifications)
- [ ] Social sharing of streak milestones
- [ ] Exportable session history (CSV)

### v2.0 — Future
- [ ] On-device AI topic card generation
- [ ] Cloud sync across devices (optional, opt-in)
- [ ] Community card packs — shared decks
- [ ] AI pronunciation and fluency feedback
- [ ] Multiplayer / partner practice mode

---

## 📄 License

```
MIT License

Copyright (c) 2025 SpeakUp Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<div align="center">

Made with ♥ by developers who believe everyone deserves a confident voice.

**SpeakUp — Speak with confidence. Every day.**

</div>