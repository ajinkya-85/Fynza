# Fynza — Project Memory

## Purpose

Fynza is an offline-first Flutter expense tracker. It supports income and expense tracking, categories, monthly budgets, dashboard summaries, currency selection, backup/restore, auto-capture from SMS and UPI payment apps, and local persistence with Drift.

## Stack

- Flutter / Dart with Material 3
- `google_fonts: ^6.2.1` (**Poppins** typography system)
- Riverpod (`StateNotifierProvider`) for UI state and dependency injection
- Drift for the local relational database
- `shared_preferences` for app settings, including currency and backup frequency
- `fl_chart` for the dashboard spending chart
- `file_picker`, `share_plus`, `path_provider`, `workmanager`, `package_info_plus` for backup & storage

## Architecture

The project uses feature-oriented MVVM with layer boundaries:

```
View → ViewModel → Domain contract → Data implementation → DAO / Service
```

Key locations:

- `lib/core/` — theming, utilities, DI, and settings services
- `lib/data/db/` — Drift database and tables
- `lib/shared/` — models, reusable widgets, and shared providers
- `lib/features/` — dashboard, transactions, budget, categories, settings, navigation, and backup

Architecture rules currently applied:

- Domain repository contracts and entities do not import Drift, database rows, or data-layer services.
- Drift rows are mapped to domain `Category`, `Transaction`, and `Budget` entities at the data boundary.
- Repository implementations live under each feature's `data/repositories/`; contracts remain under `domain/repositories/`.
- Presentation code consumes domain contracts/service interfaces and app-level Riverpod providers rather than importing data services or generated database models.
- `lib/core/di/database_provider.dart` is the composition root for repositories and infrastructure-backed providers. `AppStartupCoordinator` keeps startup scheduling orchestration out of the navigation view.
- Backup file metadata and service abstractions used by presentation live in the domain layer; the repository contract exposes paths and value types rather than `File` or `CurrencyService`.

## Current UI and Feature State

### Branding, Typography and Design System

- **Brand Name**: **Fynza** (root widget: `FynzaApp`).
- **Typography**: **Poppins** geometric font family applied globally via `google_fonts` (`AppTheme._buildOpticalTextTheme`), configured with tailored optical tracking (`-1.0` to `-0.1` for headlines/titles, `0.0` for body, `+0.1` to `+0.3` for labels) and comfortable leading.
- **Cute Modern Finance Theme & Color Palette**:
  - **Scaffold Background**: Warm Vanilla Oat Cream (`#FDF8F3` in light mode, `#191715` in dark mode).
  - **Cards & Surfaces**: Cloud White (`#FFFFFF` in light mode, `#1F1D1A` in dark mode) with soft hairline borders (`#F0E7DC` / `#38332E`).
  - **Primary & Accent Brand**: Warm Apricot / Honey Amber (`#F6A63C`).
  - **Expense Cards**: Soft Rose Blush (`#FDECE9` / `#331D1C` dark) with warm coral text (`#D94136` / `#FF8A80` dark).
  - **Income Cards**: Matcha Mint (`#E6F5EC` / `#162D20` dark) with forest jade text (`#238244` / `#81C784` dark).
  - **Pastel Chart Palette**: `[#F49E8C, #7DBCE6, #C2A5E7, #F7CE72, #7FDCB8]`.
  - **Category Accent Palette**: 24 coordinated warm pastel accents (apricot, sage, denim, lavender, rose, berry, teal, honey, jade, sea glass, terracotta, cocoa, sky, marigold, eucalyptus, and more) shared by the category picker and default category seeding. Schema v4 migrates existing stored categories using the old palette to the new palette while preserving arbitrary custom colors.

### Dashboard & Financial Summary

- **Friendly Greeting Header**: "Welcome back! 👋 / Financial Overview".
- **Floating Frosted `MonthSelector`**: Apple-style floating frosted glass pill with tactile chevron buttons, haptic ticks, and directional `AnimatedSwitcher` slide transitions.
- **Hero Net Balance Card**: Tactile card wrapped in `PressableScale` with warm amber glow, pill badge ("Net Balance" / "This Month"), and bold headline balance.
- **Side-by-Side Summary Cards**:
  - Left card: Soft Rose Blush (`#FDECE9`) Expense card with upward arrow circular badge (`Icons.arrow_upward_rounded`) and coral text.
  - Right card: Matcha Mint (`#E6F5EC`) Income card with downward arrow circular badge (`Icons.arrow_downward_rounded`) and jade text.
- **Spending Overview & Breakdown**: Dashboard shows a compact donut and category summary styled after the finance inspiration reference. The `Detail` action opens a dedicated breakdown page with the existing larger chart and full category list. Both charts and legend rows are informational only, with no tap-to-focus, animation selection, or haptic interaction.
- **Dashboard Refresh & Entrance Motion**: Pulling down on the dashboard drains the Android notification capture queue when auto-capture is enabled; capture and dashboard streams update from the newly ingested items. Dashboard sections fade and rise in with a short stagger on first appearance.
- **Scrollable Edge Fades**: Wrap vertical scrollable screens and scrollable dialogs/bottom sheets in the shared `FadingScrollBoundary` (`lib/shared/widgets/fading_scroll_boundary.dart`) for soft top/bottom content fades. It observes vertical scroll notifications and adjusts each edge fade as the user approaches or leaves that boundary; horizontal scrollers and nested non-scrollable lists do not need wrapping. Use this reusable wrapper for future vertical scroll surfaces.
- **Quick-Access Budgets & Categories Cards**: Side-by-side square squircle widget cards (1:1 aspect ratio, 22px radius, 44px circular pastel badges, and top-right arrow pills) positioned above Recent Transactions on the Dashboard:
  - **Budgets Card**: Displays total monthly budget limit pill (`$X,XXX.XX`) above the Budgets name and subtitle.
  - **Categories Card**: Displays dual count badges (rose blush circle with upward arrow for expenses, matcha mint circle with downward arrow for income) above the Categories name and subtitle.
- **Smooth Fading Scroll Boundaries (`FadingScrollBoundary`)**: Soft Apple-style top and bottom fading edge gradient masks applied to scroll views with bouncy scroll physics for smooth content dissolution during scrolling.
- **Streamlined Navigation Bar**: 3 core tabs (Dashboard, Transactions, Settings) with center-floating transaction add FAB.
- **Tactile `TransactionTile`**: Squircle cards (18px radius) with instant press feedback (`PressableScale`), subtle hairline borders, and smooth list scrolling with `BouncingScrollPhysics`.
- **`MoneyText`**: Dynamic colored text using `AppTheme.incomeAccent` and `AppTheme.expenseAccent`.

### Transactions and categories

- Income uses `Icons.arrow_downward`; expenses use `Icons.arrow_upward` throughout the UI.
- Category creation uses a dedicated full-screen form with tactile icon picker grid and color palette with animated glowing selection rings.
- Category save returns silently without a success SnackBar.
- Transaction creation and editing use `TransactionFormScreen`.
- **Fluid Segmented Filter Bar** (`lib/shared/widgets/fluid_segmented_control.dart`): Apple-style sliding pill segmented control (`All / Expenses / Income`) with spring-animated sliding background indicator, haptic selection clicks, and instant press feedback.
- **Tactile Search Field** (`lib/features/transactions/presentation/widgets/transaction_search_bar.dart`): Apple-style search field with subtle contrast, squircle borders, instant query response, and tactile clear interaction.
- **Date Section Headers** (`lib/features/transactions/presentation/widgets/transaction_date_header.dart`): Grouped calendar days displaying friendly titles (`Today, Nov 5`, `Yesterday, Nov 4`) with color-coded daily net totals.
- **Tactile Swipe Dismissal**: `Dismissible` with `HapticFeedback.mediumImpact()` triggered when swiping reaches the threshold, paired with a rounded red delete action background.

### Transaction Entry Experience (`TransactionFormScreen`)

- **Hero Optical Amount Display**: Centerpiece container with large display typography (`letterSpacing: -1.0`), adaptive emerald/red coloration, and inline clear button.
- **Quick Amount Chips**: Spring-bouncing increment chips (`+50`, `+100`, `+500`, `+1,000`, `+5,000`) with instant tactile feedback.
- **Fluid Segmented Type Control**: Fluid sliding segmented control for Expense vs Income with haptics.
- **Tactile Category Chips**: Pressable chips with glowing color-matched halo shadows, illuminated icon badges, and selection haptics.
- **Apple-Style Date Card & Note Input**: Tactile squircle date picker card and streamlined note textfield.
- **Spring Submit Button**: Full-width primary action button with `PressableScale` and haptic completion feedback.

### Budgets & Categories Polish

- **Physics Gradient Progress Bar** (`lib/shared/widgets/spring_progress_bar.dart`): Critically damped spring-animated progress bar with adaptive health gradients (emerald $\to$ amber $\to$ crimson).
- **Elevated `BudgetCard`**: Squircle cards with category icon badge, progress percentage / over-limit warning pills, optical amount typography, and tactile edit/delete actions.
- **Elevated `BudgetScreen`**: Gradient hero total budget card, category count chips, and smooth bouncing physics.
- **Tactile `BudgetFormDialog`**: Clean squircle presentation with quick amount chips (`+500`, `+1k`, `+2k`, `+5k`) and tactile save button.
- **Elevated `CategoriesScreen`**: FluidSegmentedControl type switcher (Expenses / Income), squircle category tiles with illuminated badges and tactile delete dialogs.

### Currency

- The app supports preset currencies and a persisted custom currency.
- Currency selection is managed by `CurrencyService` and `selectedCurrencyProvider`.
- Currency values are stored as integer cents and formatted through `CurrencyFormatter`.
- Formatted amounts use international thousands separators (for example, `$ 123,456.78`), including custom currencies, with a space after the currency symbol.
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
  - Communicates via `MethodChannel("io.fynza.app/auto_capture")`.
  - Exposes `drainQueue`, `isNotificationListenerGranted`, and `openNotificationListenerSettings`.
  - Periodically drained via `Workmanager` (`auto_capture_periodic_drain`) and catch-up drained on app launch in `MainScaffold`.
- **Pure Dart Parser (`SmsTransactionParser.dart` & `ParserRules.dart`)**:
  - Extracts amount directly to integer cents with exact arithmetic (zero floating-point math).
  - Determines transaction type (`expense`/`income`), counterparty/merchant, account last 4, reference number.
  - Supports both SMS formats and modern UPI app notification structures (e.g. `"Paid ₹150 to Swiggy using HDFC Bank •••• 1234"`).
  - Evaluates confidence score (`high`, `medium`, `low`).
  - Rejects OTPs, balance queries, promotional spam, and loan offers.
- **Cross-Source Deduplication & Duplicate Prevention (`CaptureDedupe.dart`, `CaptureDao.dart`, `CaptureRepository.dart`)**:
  - **Exact Deduplication**: Generates deterministic SHA-256 dedupe keys based on UPI reference / transaction ID or sender + normalized text + amount. Automatically deduplicates identical incoming notifications via SQLite UNIQUE constraint with `InsertMode.insertOrIgnore`.
  - **Possible Duplicate Detection**: Detects potential duplicates within ±24 hours (`CaptureDao.hasMatchingLoggedTransaction`).
  - **Duplicate Warning UI (Yellow Treatment)**: Highlighted in `CaptureInboxView` with amber/yellow border and warning badge (`⚠️ Possible Duplicate`).
- **Database & DAO (`captured_transactions_table.dart`, `counterparty_rules_table.dart`, `capture_dao.dart`)**:
  - Drift schema v4 with migration strategy from v1-v3 preserving existing tables and data, including migration of legacy category palette colors.
  - Stores status (`pending`, `confirmed`, `dismissed`) and nullable foreign key `transaction_id`.
  - Includes auto-purge for dismissed/confirmed captures older than 90 days.
- **Capture Modes & Master Toggle**:
  - Master switch OFF by default (opt-in privacy). Controlled via `autoCaptureEnabledProvider`.
  - Modes: `reviewFirst` (default) and `addAutomatically`.
- **Auto-Capture Reliability**:
  - The periodic Workmanager drain is registered at app startup after Workmanager initialization and dispatched using the worker's task type (`auto_capture_periodic`).
  - Background and foreground drains leave the native queue untouched while the master switch is off; Android and Dart both default the switch to OFF.
  - The native listener records whether a notification came from the device's default SMS app, allowing valid notifications from unlisted SMS packages through the Dart source gate.
  - Automatic transaction creation checks the dedupe key and inserts the transaction and capture record in one database transaction, preventing replayed notifications from creating duplicate transactions.
  - Per-notification ingestion and queue/scheduler failures emit diagnostics without logging captured message text.

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

## CI/CD Workflow

- Continuous Integration configured via `.github/workflows/ci.yml`.
- Triggers on push and pull requests to `main` and `master`.
- Automated steps:
  1. Sets up Java 17 and Flutter stable with pub cache.
  2. Runs `flutter analyze` across all codebase and tests.
  3. Runs all 109+ tests via `flutter test`.
  4. Builds release APK (`flutter build apk --release`) signed with debug key so physical Android devices do not trigger "app has a bug" debugger protections, and uploads artifact `fynza-release-apk`.

## Architecture & Rule Compliance

- **Pattern**: Strict Feature-First MVVM (`View → ViewModel → Repository → Service`).
- **Layer Boundary Guarantee**: Zero views import or communicate with repositories, DAOs, or database classes directly (with cross-feature coordination managed via app-level composition). Views talk exclusively to their ViewModels.
- **Offline-First Guarantee**: 100% offline-first operation. Zero internet permissions in `android/app/src/main/AndroidManifest.xml`.
- **Data Integrity**: All money values are strictly integer cents (`int`), with zero floating-point conversions.
- **Drift Database**: Schema v4 with `MigrationStrategy(onUpgrade: ...)` preserving existing data and migrating already-saved legacy category palette colors; DAOs are feature-scoped; all UI data binding uses reactive `.watch()` streams.
- **Material 3 & Apple Fluid Design**:
  - Centralized dynamic theming via `AppTheme`, zero hardcoded colors, full dark/light mode support.
  - AppBar scrolling is seamless with `scrolledUnderElevation: 0` and `surfaceTintColor: Colors.transparent` (zero shade darkening on scroll).
  - Fading edge scroll boundaries (`FadingScrollBoundary`) on Dashboard and Transactions.
  - Interactive elements incorporate instant touch-down press feedback (`PressableScale`), critically damped springs, multi-modal haptics, frosted glass translucency, rubber-band overscroll (`BouncingScrollPhysics`), and optical typography tracking.
- **Dashboard & Navigation**:
  - Bottom Navigation Bar streamlined to 3 core tabs: Dashboard, Transactions, Settings.
  - Quick-Access side-by-side square cards for Budgets and Categories placed on Dashboard with live monthly limits and circular count badges.
  - Clean styling with top-right action arrows removed for a minimalist iOS-widget aesthetic.
  - Arrow directions: Expense = Upward (`arrow_upward_rounded`), Income = Downward (`arrow_downward_rounded`).
- **Testing**:
  - Full unit & widget test coverage across models, DAOs, view models, and UI flows.
  - `widget_test.dart` uses `tester.ensureVisible(...)` for offscreen scrollable elements and silences Drift multi-instance warnings in tests.

## Build & Test Commands

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart analyze lib test
flutter test
flutter build apk --release
```

*Status: `flutter analyze lib test` and the full `flutter test` suite pass after the repository and presentation boundary cleanup.*
