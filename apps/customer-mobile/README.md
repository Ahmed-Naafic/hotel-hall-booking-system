# Customer Mobile — Flutter

Flutter application for **Customers**: search, reserve, and book hotel halls; manage
account, bookings, payments, and reviews.

**Status:** Workspace initialized (`docs/02-architecture/adr/0004-workspace-initialization.md`).
The Flutter project is bootstrapped (Android and iOS targets) with a minimal placeholder home
widget. No feature, screen, or authentication logic exists yet.

## Local Development

```bash
flutter pub get
flutter run
flutter analyze
flutter test
dart format lib test
```

## Structure

```
apps/customer-mobile/
├── lib/
│   └── main.dart      Placeholder MaterialApp shell
├── assets/
├── test/
│   └── widget_test.dart
└── pubspec.yaml
```

`lib/features/`, `lib/core/`, `lib/shared/` are created only once a module's Business
Specification, Technical Design, and Implementation Plan are `Approved` and it reaches
`Development-Lifecycle.md` Phase 8 — see `docs/Team-Management.md` for current feature
status. Full structure: `docs/02-architecture/folder-structure.md` §2.
