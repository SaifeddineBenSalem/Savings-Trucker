# Savings Tracker

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.8%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3-0175C2?logo=dart)
![Provider](https://img.shields.io/badge/State%20Management-Provider-5F6FFF)
![Hive](https://img.shields.io/badge/Persistence-Hive-4A7C59)
![Material 3](https://img.shields.io/badge/UI-Material%203-0081CB)

</div>

A Flutter-based personal savings planner for Tunisian Dinar goals. The app helps users define a target amount, breaks it into a 14-month saving plan, and tracks collectible units with monthly progress, credit buffering, search, filtering, and milestone achievements.

This repository is a local-first mobile app; there is no remote backend, user authentication layer, or external API. Data is stored on-device using Hive and the app is designed around the workflow of setting a goal and collecting unit values over time.

## 📖 Overview

Savings Tracker is designed for users who want a structured, visual way to save toward a target amount in a realistic monthly schedule. It converts a total goal into smaller unit amounts, distributes them across 14 months, and lets the user confirm when each amount has been collected.

The project follows a layered Flutter architecture:

- presentation layer for screens, widgets, and provider-driven UI state
- domain layer for the savings logic and engagement rules
- data layer for persistence models and local storage
- core layer for constants, formatting, and theme setup

The app is currently focused on Android/iOS-style mobile experiences. It locks the application to portrait orientation and uses a system-driven light/dark theme with Material 3 styling.

## ✨ Features

### Goal setup and validation

- Users enter a target amount in Tunisian Dinar format such as `123,200` or `50`
- The amount must be representable as a multiple of 100 millimes
- The goal is configured once and stored locally
- The app rejects invalid target values before saving

Relevant implementation:

- [lib/presentation/screens/setup_screen.dart](lib/presentation/screens/setup_screen.dart)
- [lib/core/utils/currency_formatter.dart](lib/core/utils/currency_formatter.dart)
- [lib/domain/services/savings_engine.dart](lib/domain/services/savings_engine.dart)

### 14-month savings plan generation

- The app creates a schedule of collectible units that sum exactly to the configured target
- Units are spread across 14 months using a weighted distribution algorithm
- Each generated unit stores a month index, sequence order, and status
- The engine supports denominations from 100 millimes up to 5000 millimes

Relevant implementation:

- [lib/domain/services/savings_engine.dart](lib/domain/services/savings_engine.dart)
- [lib/data/models/savings_unit.dart](lib/data/models/savings_unit.dart)
- [lib/core/constants.dart](lib/core/constants.dart)

### Monthly progress tracking

- Each month is shown as a dedicated tab in the main home screen
- The app displays pending units, completed units, and month-level progress
- Completion is detected when every unit in a month reaches the done state
- A confetti celebration is triggered on month completion and a snack bar is shown

Relevant implementation:

- [lib/presentation/screens/home_screen.dart](lib/presentation/screens/home_screen.dart)
- [lib/presentation/providers/savings_provider.dart](lib/presentation/providers/savings_provider.dart)

### Manual collection confirmation

- Each unit card can be tapped to confirm that a saved amount was collected
- A confirmation dialog asks the user whether the unit was collected
- Completed units are visually dimmed and marked as done
- A later payment can no longer modify a completed unit without a reset

Relevant implementation:

- [lib/presentation/widgets/unit_card.dart](lib/presentation/widgets/unit_card.dart)

### Credits buffer and FIFO matching

- Users can add extra credits using the Credits action
- Credits are applied in strict chronological order from the earliest pending month
- Unmatched credits remain in a buffer and still count toward overall collected progress
- Matching behavior is FIFO within the same month and across months

Relevant implementation:

- [lib/presentation/widgets/credits_modal.dart](lib/presentation/widgets/credits_modal.dart)
- [lib/domain/services/savings_engine.dart](lib/domain/services/savings_engine.dart)
- [lib/presentation/providers/savings_provider.dart](lib/presentation/providers/savings_provider.dart)

### Filter and search tools

- Users can filter units by All, Pending, or Done
- Search supports amount lookups such as `300`, `1,500`, or `1.5`
- Search is scoped to the active month and supports pagination when results exceed the visible page size

Relevant implementation:

- [lib/presentation/widgets/filter_bar.dart](lib/presentation/widgets/filter_bar.dart)
- [lib/presentation/widgets/search_bar.dart](lib/presentation/widgets/search_bar.dart)
- [lib/presentation/providers/savings_provider.dart](lib/presentation/providers/savings_provider.dart)

### Pagination and month detail views

- Units within each month are paginated in chunks of 10
- Each month has its own page state and navigation controls
- The app keeps separate page indexes for each month and filter combination

Relevant implementation:

- [lib/presentation/widgets/pagination_bar.dart](lib/presentation/widgets/pagination_bar.dart)
- [lib/presentation/providers/savings_provider.dart](lib/presentation/providers/savings_provider.dart)

### Statistics and achievements

- The app shows overall target, collected total, remaining amount, credit buffer, and unlocked badges
- The statistics screen summarizes all 14 months with progress percentages
- Achievement badges are earned at milestones such as 1 DT, 10 DT, 25%, 50%, completion, and month completion

Relevant implementation:

- [lib/presentation/screens/stats_screen.dart](lib/presentation/screens/stats_screen.dart)
- [lib/data/models/app_data.dart](lib/data/models/app_data.dart)
- [lib/presentation/providers/savings_provider.dart](lib/presentation/providers/savings_provider.dart)

### Local persistence and reset control

- Data is stored locally in a Hive box using JSON serialization
- Progress persists across app restarts
- Reset functionality is available using a fixed password: `1234`

Relevant implementation:

- [lib/data/services/storage_service.dart](lib/data/services/storage_service.dart)
- [lib/presentation/widgets/credits_modal.dart](lib/presentation/widgets/credits_modal.dart)
- [lib/core/constants.dart](lib/core/constants.dart)

### UI and interaction polish

- Modern Material 3 look with teal primary palette and dark variant
- Animated cards, progress bars, and month-level celebrations
- Search highlighting and recently matched unit feedback
- Mobile-first experience with fixed portrait orientation

Relevant implementation:

- [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart)
- [lib/presentation/widgets/unit_card.dart](lib/presentation/widgets/unit_card.dart)
- [lib/presentation/widgets/progress_header.dart](lib/presentation/widgets/progress_header.dart)

## 🛠️ Tech Stack

### Frontend

- Flutter
- Dart
- Material 3
- Provider for state management
- Google Fonts for typography
- Confetti for celebratory effects
- UUID for generated unit IDs
- Intl for formatting support

### Persistence

- Hive Flutter for local key/value persistence

### Testing

- Flutter test

### Build and tooling

- Flutter SDK
- Dart SDK
- Android and iOS project scaffolding generated by Flutter

## 🏗️ Architecture

The application is intentionally small but layered to keep business rules separate from UI behavior.

### Layer breakdown

- Core: theme, constants, and formatting utilities
- Data: model classes and local storage implementation
- Domain: savings plan generation, unit matching, and credit logic
- Presentation: screens, widgets, and provider state

### State flow

1. The app initializes Hive storage in [lib/main.dart](lib/main.dart)
2. A provider loads persisted state from storage
3. The setup screen collects a target if the app is not yet configured
4. A savings engine generates a plan and distributes units over 14 months
5. The provider updates progress and statuses as units are collected or credits are added
6. The UI reacts through Provider listeners and rebuilds the relevant widgets

### Design decisions

- Offline-only architecture: no backend requirement
- Local persistence: app state survives restarts without a server
- Sequential matching: credit application follows month order for realistic savings flow
- Single source of truth: `SavingsProvider` manages main state and derived values

## 📂 Project Structure

```text
savings_tracker/
├── android/                     # Android Flutter project files
├── ios/                         # iOS Flutter project files
├── lib/
│   ├── app.dart                 # Root app setup and bootstrap
│   ├── main.dart                # App entry point and device orientation setup
│   ├── core/
│   │   ├── constants.dart       # Core app constants and configured months
│   │   ├── theme/
│   │   │   └── app_theme.dart   # Light/dark theme definitions
│   │   └── utils/
│   │       └── currency_formatter.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── app_data.dart
│   │   │   ├── savings_unit.dart
│   │   │   └── unit_status.dart
│   │   └── services/
│   │       └── storage_service.dart
│   ├── domain/
│   │   └── services/
│   │       └── savings_engine.dart
│   └── presentation/
│       ├── providers/
│       │   └── savings_provider.dart
│       ├── screens/
│       │   ├── home_screen.dart
│       │   ├── setup_screen.dart
│       │   └── stats_screen.dart
│       └── widgets/
│           ├── credits_modal.dart
│           ├── filter_bar.dart
│           ├── pagination_bar.dart
│           ├── progress_header.dart
│           ├── search_bar.dart
│           └── unit_card.dart
├── test/
│   └── savings_engine_test.dart
├── web/                         # Web app assets
├── analysis_options.yaml
├── pubspec.yaml                 # Flutter dependencies and app metadata
├── pubspec.lock
├── README.md
├── savings_tracker.iml
└── .gitignore
```

Important directories:

- [lib/presentation](lib/presentation) contains all screens and interactive widgets
- [lib/domain/services/savings_engine.dart](lib/domain/services/savings_engine.dart) contains the central planning and matching logic
- [lib/data/models](lib/data/models) holds persisted app state and unit metadata
- [lib/data/services/storage_service.dart](lib/data/services/storage_service.dart) manages the Hive box and JSON serialization
- [test/savings_engine_test.dart](test/savings_engine_test.dart) covers the domain logic and validation rules


## ⚙️ Installation

### Prerequisites

- Flutter SDK installed and on your PATH
- Dart SDK bundled with Flutter
- An Android or iOS emulator/device for local testing
- A supported desktop environment for running Flutter apps

### Install dependencies

```bash
git clone <repository-url>
cd savings_tracker
flutter pub get
```

### Environment configuration

This project does not require environment variables or a `.env` file. The app stores state locally in Hive and uses a hard-coded reset password defined in [lib/core/constants.dart](lib/core/constants.dart).

## ▶️ Running the Project

### Development mode

```bash
flutter run
```

### Run tests

```bash
flutter test
```

### Android release build

```bash
flutter build apk --release
```

### Android app bundle

```bash
flutter build appbundle
```

### iOS build

```bash
flutter build ios
```

## 📚 Usage Guide

1. Launch the app.
2. On first start, the app opens the setup screen.
3. Enter a savings target in the format `dinars,millimes` such as `123,200`.
4. Save the target to generate a 14-month unit plan.
5. Open the month tabs to review pending and completed units.
6. Tap a unit card to confirm that a payment was collected.
7. Use the Credits action to add extra funds into the buffer.
8. Use the filter bar to focus on All, Pending, or Done units.
9. Search by exact amount or decimal value to quickly find units.
10. Open the statistics screen to review progress, badges, and monthly totals.
11. Reset app data only when needed using the password `1234`.

## 🗄️ Database and Persistence

This app does not use a server-side database. It uses a local Hive database for persistence.

### Storage behavior

- Box name: `savings_tracker`
- Stored key: `savings_app_data`
- Serialized data: JSON created from the `AppData` model
- Main persistent fields:
  - `targetMillimes`
  - `units`
  - `creditsMillimes`
  - `unlockedBadges`

### Important persisted entities

#### AppData

Stored in the local Hive box and includes:

- target total amount
- list of savings units
- credit buffer value
- badges unlocked by the user

#### SavingsUnit

Each unit stores:

- unique `id`
- `valueMillimes`
- `monthIndex`
- `sequenceOrder`
- `status` (`pending` or `done`)

### Data initialization

The app initializes storage in [lib/data/services/storage_service.dart](lib/data/services/storage_service.dart) and loads the persisted `AppData` from Hive during provider initialization in [lib/presentation/providers/savings_provider.dart](lib/presentation/providers/savings_provider.dart).

## 🔌 API Documentation

This project does not expose a backend API or HTTP server. There are no REST endpoints, GraphQL queries, or remote service integrations in the repository.

All application data and logic are local to the Flutter app itself.

## 🔐 Security

This project implements only local security patterns that are visible in the codebase.

### Verified behaviors

- Data is saved locally in a Hive box instead of a remote service
- Access to reset is protected by a fixed local password: `1234`
- Input validation prevents malformed savings targets and invalid credit amounts
- Amount parsing ensures millimes are bounded to valid ranges and multiples of 100 when required

### Security limitations

- No authentication or authorization system exists
- There is no server-side validation layer
- A hard-coded reset password is used for local device access
- No secret management or environment variable system is implemented

## 📱 Responsive Design

The app is designed primarily for mobile usage and explicitly locks the app to portrait mode through [lib/main.dart](lib/main.dart).

### Verified responsive behavior

- Mobile-first layouts across the setup and home screens
- Tabbed month navigation designed for narrow screens
- Cards and action controls use rounded, touch-friendly Material styling
- Search and filters remain visible above the list area
- The app supports both light and dark system themes

## 🎨 UI / Design

The visual system uses a teal and white palette with Material 3 card surfaces and rounded, soft-edged containers.

### Design characteristics

- Primary color: teal / sea green palette from [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart)
- Typography: Google Fonts Inter styling with Material 3 typography scale
- Layout: stacked cards, tabbed month navigation, and summary panels
- Inputs: rounded text fields and full-width action buttons
- Feedback: snack bars, confetti, badges, and animated progress indicators
- Theme support: system mode with explicit light and dark definitions

## 🚀 Deployment

This repository does not include a production deployment configuration such as Docker, serverless deployment, or CI/CD workflow files. The project is structured as a mobile Flutter application and is intended to be built and distributed through standard Flutter channels.

### Basic distribution path

- Android: `flutter build apk --release` or `flutter build appbundle`
- iOS: `flutter build ios`

## 🧪 Testing

The repository includes unit tests for the core savings logic in [test/savings_engine_test.dart](test/savings_engine_test.dart).

Verified test status:

```bash
flutter test
```

Result: all tests passed in the current repository state.

## 🔮 Future Improvements

The following items are reasonable future enhancements based on the current app scope, but they are not implemented in the repository today:

- cloud sync or export/import for backup
- multiple savings goals within a single account
- recurring monthly contribution automation
- richer reports and analytics dashboards
- locale-based formatting for additional regions and currencies

## 🤝 Contributing

Contributions are welcome if you want to improve the existing savings workflow or add new capabilities. The current project is intentionally lightweight and focused on a local-first savings experience.

Typical areas for contribution:

- improving target validation logic
- adding import/export support
- refining the monthly planning algorithm
- polishing the interface and mobile interactions
- extending analytics and milestone features

## 📄 License

No license file was found in the repository. The project currently does not declare a license in the repository root.

## 👨‍💻 Author

Saifeddine Ben Salem

GitHub: [https://github.com/SaifeddineBenSalem](https://github.com/SaifeddineBenSalem)

LinkedIn: [https://www.linkedin.com/in/saifeddine-ben-salem-7947021ba/](https://www.linkedin.com/in/saifeddine-ben-salem-7947021ba/)

---

This README reflects the current repository state and the verified implementation in the codebase. It intentionally documents only functionality that is present in the project and does not assume features that are not implemented.



## 📸 Screenshots

No screenshots are currently included in the repository. The project currently ships without a dedicated screenshots or demo image directory.

## 🎥 Video Demo

[▶️ Check video here](https://www.youtube.com/shorts/ELZjSDoYR00)