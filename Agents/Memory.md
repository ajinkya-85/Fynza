# Fynza — Project Memory

## Purpose

Fynza is an offline-first Flutter expense tracker. It supports income and expense tracking, categories, monthly budgets, dashboard summaries, currency selection, backup/restore, and local persistence with Drift.

## Stack

- Flutter / Dart with Material 3
- Riverpod (`StateNotifierProvider`) for UI state and dependency injection
- Drift for the local relational database
- `shared_preferences` for app settings, including currency and backup frequency
- `fl_chart` for the dashboard spending chart
- `file_picker`, `share_plus`, `path_provider`, `workmanager`, `package_info_plus` for backup & storage

## Architecture

The project uses feature-oriented MVVM:

```
View → ViewModel → Repository → DAO / Service
```

Key locations:

- `lib/core/` — theming, utilities, DI, and settings services
- `lib/data/db/` — Drift database and tables
- `lib/shared/` — models, reusable widgets, and shared providers
- `lib/features/` — dashboard, transactions, budget, categories, settings, navigation, and backup

## Current UI and Feature State

### Branding and navigation

- The app brand is **Fynza**.
- Main screens use a consistent Fynza AppBar treatment.
- Main navigation includes Dashboard, Transactions, Budgets, Categories, and Settings.
- The central transaction FAB uses `FloatingActionButtonLocation.centerFloat` to avoid overlapping the navigation bar.

### Transactions and categories

- Income uses `Icons.arrow_downward`; expenses use `Icons.arrow_upward` throughout the UI.
- Category creation uses a dedicated full-screen form rather than an AlertDialog.
- Category save returns silently without a success SnackBar.
- Transaction creation and editing use `TransactionFormScreen`.

### Currency

- The app supports preset currencies and a persisted custom currency.
- Currency selection is managed by `CurrencyService` and `selectedCurrencyProvider`.
- Currency values are stored as integer cents and formatted through `CurrencyFormatter`.
- Settings uses an expandable Currency section: it expands when tapped and collapses after a selection.

### Shared month selection

- `lib/shared/providers/global_month_provider.dart` is the single source of truth for the selected month.
- Dashboard, Transactions, and Budget screens all display and update this same provider.
- Changing the month with arrows or a horizontal swipe on any one of these screens updates all three feature data streams.
- Feature view models retain a local month only to query their repositories; they listen to the global provider and refresh when it changes.
- `MonthSelector` lives at `lib/shared/widgets/month_selector.dart`.

### Backup and Restore ("Data and Storage")

- Accessible from the Settings screen via "Data & Storage" (`DataAndStorageView`).
- Design modeled after Mihon: Storage location with one-tap copy, pill action buttons (`Create backup` | `Restore backup`), auto-backup frequency tile, relative time indicators, and live storage breakdown (database, backups, total).
- Custom file format: UTF-8 JSON compressed with gzip (`.expbak`), verified by `0x1F, 0x8B` magic bytes.
- Filename conventions with **Fynza** brand:
  - Manual backups: `fynza_YYYY-MM-DD_HH-mm-ss.expbak`
  - Automatic backups: `auto_fynza_YYYY-MM-DD_HH-mm-ss.expbak`
  - Safety backups: `pre_restore_fynza_YYYY-MM-DD_HH-mm-ss.expbak`
- Hand-crafted DTOs with hand-written serialization (`BackupDto`, `BackupSerializer`, `BackupValidator`) to prevent schema rename drift.
- Single-transaction atomic backup creation and restore via Drift (`$writeTracker.writeTransaction`).
- Mandatory pre-restore safety copy saved to `<backup_dir>/pre_restore/` before modifying existing data.
- Automatic background backups using `Workmanager` (`^0.10.0`) with configurable frequency (Off, 6h, 12h, Daily, 2d, Weekly), rotation (keeping newest 2 auto-backups), and app launch catch-up.
- In-app restore sheet with "Choose a file..." file picker and automatic backups list with inline actions (Restore, Share, Delete).

### Auto-Capture Transactions (SMS & Payment Apps)

- Located at `lib/features/auto_capture/`.
- Enables automatic detection, parsing, and bookkeeping of bank SMS notifications and direct push notifications from UPI/payment apps (Google Pay, PhonePe, Paytm, CRED, BHIM, Amazon Pay, Samsung Pay, and major mobile banking apps) on Android via a privacy-first, on-device pipeline.
- **Native Android Listener (`SmsNotificationListenerService.kt`)**:
  - Registered in `AndroidManifest.xml` with `android.permission.BIND_NOTIFICATION_LISTENER_SERVICE`.
  - Filters out grouped summaries (`FLAG_GROUP_SUMMARY`) to prevent duplicates.
  - Verifies package matches default SMS app, messaging packages, or supported payment/banking apps (`KNOWN_PAYMENT_PACKAGES`: GPay, PhonePe, Paytm, BHIM, CRED, Amazon Pay, Samsung Pay, HDFC, ICICI, SBI YONO, Axis, Kotak 811, etc.).
  - Runs a fast regex pre-filter for Indian currency tokens (`Rs`, `INR`, `₹`) before enqueueing.
  - Rebinds automatically on disconnection via `requestRebind(ComponentName(...))`.
- **Thread-Safe Native Queue (`AutoCaptureQueue.kt`)**:
  - Bounded JSON queue (up to 500 entries) in app-private storage (`autocapture_queue.json`).
  - Thread-safe synchronized locks with atomic staging file rename on drain to avoid race conditions and data loss.
- **Platform Channel (`AutoCapturePlugin.kt` & `NotificationCaptureService.dart`)**:
  - Communicates via `MethodChannel("com.example.fynza/auto_capture")`.
  - Exposes `drainQueue`, `isNotificationListenerGranted`, and `openNotificationListenerSettings`.
  - Periodically drained via `Workmanager` (`auto_capture_periodic_drain`) and catch-up drained on app launch in `MainScaffold`.
- **Pure Dart Parser (`SmsTransactionParser.dart` & `ParserRules.dart`)**:
  - Extracts amount directly to integer cents with exact arithmetic (zero floating-point math).
  - Determines transaction type (`expense`/`income`), counterparty/merchant, account last 4, reference number.
  - Supports both SMS formats and modern UPI app notification structures (e.g. `"Paid ₹150 to Swiggy using HDFC Bank •••• 1234"`).
  - Evaluates confidence score (`high`, `medium`, `low`).
  - Rejects OTPs, balance queries, promotional spam, and loan offers.
- **Cross-Source Deduplication & Duplicate Prevention (`CaptureDedupe.dart`, `CaptureDao.dart`, `CaptureRepository.dart`)**:
  - **Exact Deduplication**: Generates deterministic SHA-256 dedupe keys based on UPI reference / transaction ID or sender + normalized text + amount. Automatically deduplicates identical incoming notifications (e.g. UPI app push + bank SMS for the same transaction) via a SQLite UNIQUE constraint with `InsertMode.insertOrIgnore`.
  - **Possible Duplicate Detection**: Detects potential duplicates when:
    1. A transaction with the exact same amount in cents was already logged into the `transactions` table within ±24 hours (`CaptureDao.hasMatchingLoggedTransaction`).
    2. Multiple pending items in the same capture inbox batch share the same amount within a 24-hour window.
  - **Duplicate Warning UI (Yellow Treatment)**:
    - Items identified as potential duplicates are highlighted in `CaptureInboxView` with an amber/yellow border (`Colors.amber.shade700`), warm background tint (`#FFFBEB` in light mode, `Colors.amber.withAlpha(20)` in dark mode).
    - Features a prominent warning badge: `⚠️ Possible Duplicate • A similar transaction was already recorded around this time`.
    - Contextual action buttons update to `"Add Anyway"` and `"Dismiss Duplicate"`, allowing the user to review before deciding whether to log it or discard it.
- **Database & DAO (`captured_transactions_table.dart`, `counterparty_rules_table.dart`, `capture_dao.dart`)**:
  - Drift schema v2 with migration strategy from v1 preserving all existing tables and data.
  - Stores status (`pending`, `confirmed`, `dismissed`) and nullable foreign key `transaction_id`.
  - `CounterpartyRules` stores learned category mappings for merchant names.
  - Includes auto-purge for dismissed/confirmed captures older than 90 days.
- **Capture Modes & Master Toggle**:
  - **Master Switch**: Auto-Capture is turned **OFF by default** (opt-in privacy). Controlled via `autoCaptureEnabledProvider` backed by `CapturePreferencesService.isMasterEnabled`.
  - When disabled:
    - The Capture Inbox icon button is completely removed from the `DashboardScreen` AppBar.
    - Launch queue catch-up drain in `MainScaffold` is bypassed.
    - Any incoming notifications are dropped immediately.
    - Settings screen Automation tile clearly displays `"Turned off"`.
  - When enabled:
    - The Capture Inbox icon button reactively appears in `DashboardScreen` with pending badge counts.
    - `reviewFirst` (default mode): Captures remain in the capture inbox until user reviews and confirms them.
    - `addAutomatically`: High-confidence debits with a known counterparty rule are immediately created as real transactions with a one-tap Undo option.
- **UI & Navigation**:
  - `CaptureInboxView`: Review pending captures, prefill transaction form, dismiss, undo auto-adds, or block sender. Formats amounts using the app's dynamic currency (`selectedCurrencyProvider`). Surfaces possible duplicate warnings in amber/yellow styling.
  - `AutoCaptureSettingsView`: Master switch, mode radio group, ignored senders list, battery optimization dialog, wipe captures, and link to parser playground.
  - `ParserPlaygroundView`: In-app tool to test and debug SMS parsing on pasted text (accessible from Settings).
  - Dashboard badge: Dynamic inbox icon with pending count pill in `DashboardScreen` AppBar, conditionally rendered only when Auto-Capture is active.
- **Backup & Storage Integration**:
  - Handled in `BackupDto`, `BackupSerializer`, and `BackupValidator` with backward-compatible optional `capturedTransactions` section.
  - Deleted prior to transactions during restore to respect foreign key constraints.

### Apple-Grade Fluid Motion & Design System (Phases 1, 2, 3, 4 & 5 Completed)
- **Phase 1: Motion Primitives & Theming**:
  - `SpringCurves` (`lib/core/theme/spring_curves.dart`): Curated critically damped springs ($\zeta = 1.0$), snappy springs, momentum flick springs ($\zeta \approx 0.8$), and cubic curves.
  - `PressableScale` (`lib/shared/widgets/pressable_scale.dart`): Reusable touch-down interactive wrapper that scales down instantly (`0.975x`) on raw pointer down, triggers synchronized haptics, smoothly cancels on drag-away, and handles reduced-motion accessibility.
  - `FrostedContainer` (`lib/shared/widgets/frosted_container.dart`): Apple-style translucent blur (`BackdropFilter`) with light/dark adaptive tints and light-catching 1px borders.
  - Optical Typography (`lib/core/theme/app_theme.dart`): Negative tracking on display/headline figures (`-1.0` to `-0.2`), comfortable leading on body text, and slightly positive tracking on small labels.
- **Phase 2: Dashboard Experience**:
  - **Floating Frosted `MonthSelector`**: Apple-style floating frosted glass pill with tactile chevron buttons, haptic ticks, and directional `AnimatedSwitcher` slide transitions.
  - **Elevated `SummaryCards`**: Interactive cards wrapped in `PressableScale` with vibrant primary gradients, subtle depth shadow, and optical display typography.
  - **Interactive `SpendingPieChart`**: Spring-expanded chart slices on touch, haptic clicks, animated center focus showing selected category details, and interactive legend rows with tap-to-focus.
  - **Tactile `TransactionTile`**: Squircle cards with instant press feedback (`PressableScale`), subtle light-catching borders, and smooth list scrolling with `BouncingScrollPhysics`.
- **Phase 3: Transactions Screen, Search & Date Grouping**:
  - **Fluid Segmented Filter Bar** (`lib/shared/widgets/fluid_segmented_control.dart`): Apple-style sliding pill segmented control (`All / Expenses / Income`) with spring-animated sliding background indicator, haptic selection clicks, and instant press feedback.
  - **Tactile Search Field** (`lib/features/transactions/presentation/widgets/transaction_search_bar.dart`): Apple-style search field with subtle contrast, squircle borders, instant query response, and tactile clear interaction.
  - **Date Section Headers** (`lib/features/transactions/presentation/widgets/transaction_date_header.dart`): Grouped calendar days displaying friendly titles (`Today, Nov 5`, `Yesterday, Nov 4`) with color-coded daily net totals (`-$45.00` / `+$2,500.00`).
  - **Tactile Swipe Dismissal**: `Dismissible` with `HapticFeedback.mediumImpact()` triggered when swiping reaches the threshold, paired with a rounded red delete action background.
  - **EmptyState Polish**: Responsive scrolling empty states that prevent overflow on small viewports and keyboards.
- **Phase 4: Transaction Entry Experience (`TransactionFormScreen`)**:
  - **Hero Optical Amount Display**: Centerpiece container with large display typography (`letterSpacing: -1.0`), adaptive emerald/red coloration, and inline clear button.
  - **Quick Amount Chips**: Spring-bouncing increment chips (`+50`, `+100`, `+500`, `+1,000`, `+5,000`) with instant tactile feedback.
  - **Fluid Segmented Type Control**: Fluid sliding segmented control for Expense vs Income with haptics.
  - **Tactile Category Chips**: Pressable chips with glowing color-matched halo shadows, illuminated icon badges, and selection haptics.
  - **Apple-Style Date Card & Note Input**: Tactile squircle date picker card and streamlined note textfield.
  - **Spring Submit Button**: Full-width primary action button with `PressableScale` and haptic completion feedback.
- **Phase 5: Budgets & Categories Polish**:
  - **Physics Gradient Progress Bar** (`lib/shared/widgets/spring_progress_bar.dart`): Critically damped spring-animated progress bar with adaptive health gradients (emerald $\to$ amber $\to$ crimson).
  - **Elevated `BudgetCard`**: Squircle cards with category icon badge, progress percentage / over-limit warning pills, optical amount typography, and tactile edit/delete actions.
  - **Elevated `BudgetScreen`**: Gradient hero total budget card, category count chips, and smooth bouncing physics.
  - **Tactile `BudgetFormDialog`**: Clean squircle presentation with quick amount chips (`+500`, `+1k`, `+2k`, `+5k`) and tactile save button.
  - **Elevated `CategoriesScreen`**: FluidSegmentedControl type switcher (Expenses / Income), squircle category tiles with illuminated badges and tactile delete dialogs.
  - **Interactive `CategoryFormScreen`**: Tactile icon picker grid and color palette with animated glowing selection rings and haptics.

## Application Branding & Package Information

- **App Name & Brand**: **Fynza** (root widget: `FynzaApp`).
- **Dart Package Name**: `fynza` in `pubspec.yaml` (all internal imports use `package:fynza/...`).
- **Android Application ID & Namespace**: `io.fynza.app` (backup storage path: `/Android/data/io.fynza.app/files/backups`).
- **iOS & Desktop Bundle IDs**: `io.fynza.app`.

## Android Configuration & Dependencies

- `applicationId = "io.fynza.app"` and `namespace = "io.fynza.app"`.
- `android:label = "Fynza"` in AndroidManifest.xml.
- `workmanager: ^0.10.0` (required for Flutter v2 embedding / Flutter 3.29+ compatibility).
- Root `android/build.gradle.kts` overrides subproject `compileSdk = 36` in an `afterEvaluate` hook to satisfy plugin requirements.
- Native build verified with `flutter build apk --debug`.

## Architecture & Rule Compliance

- **Pattern**: Strict Feature-First MVVM (`View → ViewModel → Repository → Service`).
- **Layer Boundary Guarantee**: Zero views import or communicate with repositories, DAOs, or database classes directly. Views talk exclusively to their ViewModels.
- **Data Integrity**: All money values are strictly integer cents (`int`), with zero floating-point conversions.
- **Drift Database**: Schema v2 with atomic `MigrationStrategy(onUpgrade: ...)` preserving all existing data; DAOs are feature-scoped; all UI data binding uses reactive `.watch()` streams.
- **Material 3 & Apple Fluid Design**: Centralized dynamic theming via `AppTheme`, zero hardcoded colors, full dark/light mode support, and modern components (`NavigationBar`, `FilledButton`, `RadioGroup`). Interactive elements incorporate Apple-grade fluid motion principles: instant touch-down press feedback (`PressableScale`), critically damped springs, multi-modal haptics, frosted glass translucency, rubber-band overscroll, and optical typography tracking.

## Build & Test Commands

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart analyze lib test
flutter test
flutter build apk --debug
```

*Status: 109/109 tests passing; 0 analyzer issues.*

