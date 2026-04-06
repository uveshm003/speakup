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
| 🃏 **Card Draw System** | Draw random topic cards from 11 built-in categories with a smooth 3D flip animation |
| 📖 **Mini Guide** | Every card includes 3–5 structured bullet points — context, arguments, and angles to think about before speaking |
| 📚 **Vocabulary Boost** | 5 topic-relevant, intermediate-to-advanced English words with definitions per card — curated, not generic |
| ⏱ **Practice Timer** | Preset durations (30s, 1m, 2m, 3m, 5m) or custom input. Immersive countdown ring changes color as time runs out |
| 👀 **Split Practice View** | Beautifully integrated, scrollable bottom-tab view during active practice to give continuous access to Mini Guide and Vocabulary without structural constraints |
| 📅 **Session History** | Every completed session is logged locally with card title, category, duration, and timestamp |
| 🔥 **Streak Tracking** | Consecutive daily practice streak with a calendar heatmap view |
| 🏆 **Challenges** | Enroll in spaced/repeated learning challenges with pre-assigned daily prompts |
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
| **Preferences** | `hive` + `hive_flutter` | Lightweight key-value store for user settings & challenge progress |
| **Code Generation** | `build_runner` + `freezed` | Immutable models, union types, JSON serialization |
| **DI** | `get_it` + `injectable` | Service locator for repositories and use cases |
| **Fonts** | `google_fonts` | Plus Jakarta Sans (display) + Inter (body) |
| **Platform Sizing** | `window_manager` | Minimum window size control on desktop platforms |
| **App Info** | `package_info_plus` | App version display in Settings |
| **Equality** | `equatable` | Value equality for BLoC states and domain entities |

---

## 🏗 Architecture

SpeakUp follows **Feature-Driven Clean Architecture**. Each feature is self-contained and composed of three distinct layers:

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
│   ├── theme/             # AppTheme, AppColors, AppRadius, AppSpacing
│   └── app.dart           # Root App widget, MultiBlocProvider setup
├── core/
│   ├── constants/         # AppStrings, AppAssets, AppConstants
│   ├── errors/            # Failure base classes
│   ├── extensions/        # BuildContext, String, DateTime helpers
│   ├── utils/             # ObjectBoxStore, Responsive, StreakCalculator
│   └── widgets/           # AppShell, AppButton, TopicCard UI
├── features/
│   ├── home/              # Dashboard & built-in categories
│   ├── card_draw/         # Library, Shuffle algorithm, DTOs
│   ├── practice/          # Timer Setup & Active Practice loop
│   ├── challenges/        # Streak-based learning track features
│   ├── history/           # Completed session logs & Heatmaps
│   ├── favorites/         # Wishlist management
│   ├── custom_categories/ # User-uploaded prompt entries 
│   ├── navigation/        # Persistent AppShell handling
│   ├── onboarding/        # First-time app tutorials
│   ├── splash/            # Pre-load routing logic
│   └── settings/          # Design token preferences & app cache management
└── main.dart
```

For more details on the structural breakdown, refer to the [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) file.

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
| Challenges | `/challenges` | Streak-based guided pathways with predefined prompts |
| Timer Setup | `/home/timer-setup` | Premium duration selector with horizontal pills and custom inputs |
| Active Practice | `/home/active-practice` | Fullscreen focus mode. Immersive countdown ring + embedded sticky helper tabs |
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
  String category;         // One of 11 built-in categories, or custom
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

### `ChallengeProgress` *(Hive)*

```dart
class ChallengeProgress {
  String challengeId;      // UUID maps to Challenge course
  int currentLevel;
  Map<String, String> dailyPromptIds; // Dynamic prompts mapped contextually
}
```

---

## 🔄 State Management

SpeakUp uses **flutter_bloc** throughout. Every screen is driven by a dedicated BLoC — no `setState()` is used in any screen with business logic.

### BLoC Inventory

| BLoC | Responsibility |
|------|---------------|
| `HomeBloc` | Streak, session count, recent categories |
| `CategoryBloc` | Category list, difficulty filtering |
| `CardDrawBloc` | Current card, flip state, favorite toggle |
| `ChallengesBloc` | Challenge tracking, daily progression, prompt assignment |
| `TimerBloc` | Countdown via `Stream.periodic`, pause/resume/stop |
| `SessionEndBloc` | Session persistence, streak recalculation |
| `HistoryBloc` | Session log, heatmap data |
| `FavoritesBloc` | Favorites list, quick draw |
| `CustomCategoryBloc` | CRUD for user categories |
| `SettingsBloc` | Read/write all user settings |
| `ThemeBloc` | App-wide theme mode |

---

## 🧭 Navigation

Navigation uses **go_router** with a `ShellRoute` wrapping the 5 main tabs (`Home`, `Favorites`, `History`, `Challenges`, `Settings`). The practice flow screens (Card Draw → Timer → Active Practice → Session End) push full-screen over the shell with no bottom nav visible.

**Responsive navigation:** Bottom `NavigationBar` on mobile/tablet. Left `NavigationRail` sidebar on screens wider than 1024px.

---

## 💾 Local Storage Strategy

| Store | Used For | Why |
|-------|----------|-----|
| **ObjectBox** | `TopicCard`, `PracticeSession`, `CustomCategory` entities | High-performance reactive queries; indexed on `category` and `completedAt` |
| **Hive** | `UserSettings`, `ChallengeProgress` | Lightweight key-value store for preferences and tracked progression models |
| **JSON Asset** | Built-in card deck (`assets/data/cards.json`) | Bundled at build time; seeded into ObjectBox on first launch via a `cardsSeeded` Hive flag |

---

## 🃏 Built-in Card Deck

SpeakUp ships with **110+ curated topic cards** across 11 categories. Each card includes a Mini Guide and Vocabulary Boost authored specifically for that topic — not generated at runtime.

| Category | Topics Include |
|----------|---------------|
| 💬 Opinion & Debate | Social media age limits, remote work vs office, free speech |
| 📰 Current Affairs | AI in everyday life, climate responsibility, digital privacy |
| 🌱 Personal Growth | Overcoming failure, building habits, dealing with criticism |
| 💻 Technology | Smartphones and human connection, coding in schools, automation |
| 🌍 Culture & Society | Beauty standards, second languages, generational differences |
| 💼 Business & Work | What makes a great leader, gig economy, workplace communication |
| 📖 Storytelling & Personal | Moments that changed you, someone who influenced you, life goals |
| 🤔 Big Questions | Existence, philosophy of happiness, moral thought experiments |
| 🧘 Health & Lifestyle | Mental wellness, holistic diets, fitness disciplines |
| 🤝 Relationships & People | Maintaining trust, navigating conflicts, psychology of friendship |
| ✨ Imagine & What If | Time travel ethics, surviving mars, rewriting history |

---

## 🗺 Roadmap

### v1.0 — MVP *(Current)*
- [x] 110+ built-in cards across 11 categories with Mini Guide + Vocabulary
- [x] Immersive Card flip animations & filtering 
- [x] Guided Challenges Pathways integrated efficiently
- [x] Premium Split View Practice timer design 
- [x] Session history, streak tracking, calendar heatmap
- [x] Custom categories and cards locally via ObjectBox
- [x] Favorites, onboarding, dark/light/system theme
- [x] All 6 Flutter platforms supported

### v1.1 — Post-MVP
- [ ] Voice recording with self-review playback
- [ ] Daily practice reminders (push notifications)
- [ ] Exportable session history (CSV)

---

## 📄 License

```
MIT License

Copyright (c) 2026 SpeakUp Contributors

Permission is hereby granted, free of charge...
```

<div align="center">

Made with ♥ by developers who believe everyone deserves a confident voice.

**SpeakUp — Speak with confidence. Every day.**

</div>