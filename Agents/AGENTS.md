# AGENTS.md

## Project Overview
A mobile expense tracker built with Flutter & Dart. Users log income/expenses,
categorize them, view summaries and trends, and manage a local budget —
fully offline-first with a local relational database. UI follows Google's
Material 3 design language.

## Tech Stack
- Framework: Flutter (stable channel)
- Language: Dart (null-safety, sound typing)
- UI: Material 3 (`useMaterial3: true`), Google Fonts if custom typography is needed
- Local database: **Drift** (SQL, type-safe, reactive) — DO NOT introduce Isar,
  Hive, or ObjectBox without discussing first; the schema is relational
  (transactions ↔ categories ↔ budgets) and Drift is the chosen ORM.
- State management: Riverpod (preferred) — confirm before switching to
  Bloc/Provider/GetX
- Charts: `fl_chart` for spending trends/pie breakdowns

## Environment
- Flutter SDK: latest stable (check `flutter --version`)
- Install deps: `flutter pub get`
- Generate Drift/code-gen files: `dart run build_runner build --delete-conflicting-outputs`
- Run app: `flutter run`
- Run tests: `flutter test`
- Analyze: `flutter analyze`

## Coding Standards
- Follow the official [Effective Dart](https://dart.dev/effective-dart) style guide
- Use `flutter_lints` — do not merge code that fails `flutter analyze`
- File naming: `snake_case.dart`; class naming: `PascalCase`
- Widgets: prefer small, composable `StatelessWidget`/`ConsumerWidget`
  (Riverpod) over deeply nested build methods
- Keep business logic out of widgets — put it in view models/repositories,
  never in `build()`

## Architecture: Feature-Oriented MVVM
Follow Flutter's officially recommended app architecture
(https://docs.flutter.dev/app-architecture): two layers, **UI** (Views +
ViewModels) and **Data** (Repositories + Services), organized per feature.

- **View** — a widget (`StatelessWidget`/`ConsumerWidget`). Renders UI from
  the ViewModel's state only. No business logic, no direct DB/service calls.
- **ViewModel** — holds UI state (e.g. `ChangeNotifier` or a Riverpod
  `Notifier`), exposes state to the View and **commands** (methods the View
  calls in response to user actions, e.g. `addTransaction()`). Talks only to
  repositories, never directly to Drift or a DAO.
- **Repository** — the single source of truth for a piece of data (e.g.
  `TransactionRepository`). Wraps one or more services/DAOs, applies
  business rules, and exposes a clean API + streams to ViewModels. Views
  and ViewModels never bypass this to hit Drift directly.
- **Service** — thin wrapper around an external dependency: the Drift DAO,
  a `SharedPreferences` wrapper, a currency-formatting utility, etc.
  Repositories compose services; nothing above the repository layer talks
  to a service directly.

Dependency direction is one-way: **View → ViewModel → Repository → Service**.
Never call upward (a service must not know about a ViewModel), and never
skip a layer (a View must not call a Repository or Service directly).

### Folder structure (feature-first)
```
lib/
  core/                     # app-wide: theme, constants, DI setup, utils
    theme/
    di/
    utils/
  data/
    db/                     # Drift tables, generated database class
      tables/
  shared/                   # widgets/models reused across features
  features/
    transactions/
      presentation/
        views/              # screens
        widgets/            # feature-local widgets
        view_models/
      domain/
        repositories/       # repository interfaces (+ impl if simple)
      data/
        services/           # DAOs / service wrappers for this feature
    categories/
      presentation/...
      domain/...
      data/...
    budget/
      presentation/...
      domain/...
      data/...
    dashboard/
      presentation/...
      domain/...
      data/...
  main.dart
```
Each feature is self-contained (its own views, view models, repository,
service) and only reaches into `core/` or `shared/` — never into another
feature's internals directly. Cross-feature data sharing goes through a
shared repository in `data/db/` or `shared/`.

## Database Rules (Drift)
- Define tables in `lib/data/db/tables/` — one file per table
  (`transactions_table.dart`, `categories_table.dart`, `budgets_table.dart`)
- Use DAOs per feature, placed in that feature's `data/services/` folder
  (e.g. `features/transactions/data/services/transaction_dao.dart`) rather
  than one giant database class with all queries
- DAOs are wrapped by that feature's repository (`domain/repositories/`) —
  ViewModels depend on the repository interface, never the DAO directly
- Prefer `Stream` queries (`watch()`) over one-off `get()` for anything
  bound to UI, so ViewModel state updates reactively
- All schema changes must include a migration step in `MigrationStrategy`
  — never silently break existing installs
- Money values: store as integer cents (`int`), never `double`, to avoid
  floating-point rounding errors in totals

## Theming & Design System (Material 3 + Apple Fluid Design)
- Central theme lives in `lib/core/theme/` — `app_theme.dart` with
  `ColorScheme.fromSeed(seedColor: ...)`
- Support light + dark mode via `ThemeMode.system` by default
- Use `Theme.of(context).colorScheme` / `.textTheme` — no hardcoded colors
  in widgets
- Prefer Material 3 components: `FilledButton`, `SegmentedButton`,
  `NavigationBar` (not the old `BottomNavigationBar`), `Card` with
  `surfaceContainer` tones

### Apple Fluid Interaction Standards (Mobile Adaptation)
Incorporate Apple's Human Interface Guidelines and fluid motion principles
(WWDC *Designing Fluid Interfaces*, *Designing Audio-Haptic Experiences*):
- **Instant Press Feedback (Response)**: Respond on pointer-down / touch-down,
  not on tap release. Interactive cards, buttons, and tiles scale subtly
  (`0.97x`–`0.98x`) with instant feedback on press.
- **Physical Spring Motion**: Use critically damped springs (`damping: 1.0`,
  response: `0.35s`) for standard UI state changes; add slight momentum bounce
  (`damping: ~0.8`) only when preceded by a physical flick or throw gesture.
  Never lock out user interaction during transitions.
- **Multi-Modal Haptics**: Pair visual state changes with subtle, synchronized
  tactile haptics (`HapticFeedback.lightImpact()`, `selectionClick()`). Haptics
  must fire on the exact same frame as the visual commit and must only be used
  for meaningful feedback (state flips, snap points, completions).
- **Materials, Depth & Translucency**: Use floating frosted glass
  (`BackdropFilter` with blur, semi-transparent tints, and light-catching
  1px borders) for AppBars, sticky Month Selectors, and bottom sheets so
  content flows naturally underneath without opaque hard dividers.
- **Soft Boundaries (Rubber-banding)**: Ensure lists and scrollables employ
  natural `BouncingScrollPhysics` with progressive resistance at edges.
- **Optical Typography**: Display currency and headline figures must use
  tightened optical tracking (`letter-spacing: -0.02em`) with strong weight
  hierarchies and comfortable body leading.
- **Accessibility & Reduced Motion**: Honor `prefers-reduced-motion` and
  system text scaling. Replace springs/bounces with gentle cross-fades when
  reduced motion is active.

## Testing & Verification
- Every new DAO/service method needs a unit test using an in-memory Drift
  database (`NativeDatabase.memory()`)
- Every ViewModel needs unit tests covering its commands and state
  transitions, with the repository mocked/faked (no real DB in ViewModel
  tests)
- Widget tests for critical Views: adding a transaction, viewing dashboard
  totals, editing a budget
- Run `flutter analyze` and `flutter test` before considering a task done

## Constraints (never do this)
- Never store money as `double`
- Never let a View call a Repository or Service directly — always go
  through its ViewModel
- Never let a ViewModel call a DAO/Drift table directly — always go
  through its Repository
- Never add a new local DB package (Isar/Hive/ObjectBox/sqflite) alongside
  Drift — one source of truth
- Never let one feature import another feature's `presentation/` or
  `data/` internals — share via `core/`, `shared/`, or a common repository
- Never commit generated files if `.gitignore` excludes them (`*.g.dart`
  from build_runner) — regenerate instead

## Notes for Agents
- If a UI request doesn't specify Material 3 details, default to
  `ColorScheme.fromSeed` with a sensible seed color and state the choice
- Prefer small, verifiable diffs over large rewrites
- If ambiguous whether something is a feature or a schema change, flag the
  schema/migration impact explicitly before proceeding
- Whenever the database schema changes, update the backup DTOs and serializer, bump `formatVersion` (and add a migrator step) if the change is not backward compatible, and add or update a round-trip test.
