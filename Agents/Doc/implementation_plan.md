# Project Initiation & Architecture Setup Plan (AGENTS.md)

This plan outlines the foundational scaffolding and end-to-end implementation for the mobile expense tracker according to the specifications in [AGENTS.md](file:///d:/My_Practice/Dart_Flutter/expense_tracker/AGENTS.md).

## User Review Required

> [!IMPORTANT]
> - **Database**: Drift (SQL relational DB) with tables for `Categories`, `Transactions`, and `Budgets`. Money values are strictly represented as `int` cents.
> - **Architecture**: Feature-oriented MVVM (`View` → `ViewModel` → `Repository` → `Service/DAO`).
> - **Theming**: Google Material 3 (`useMaterial3: true`), Light & Dark mode support via `ThemeMode.system`, utilizing curated financial seed color palette (Emerald/Forest green palette).
> - **Code Generation**: Drift code generation will be run using `dart run build_runner build --delete-conflicting-outputs`.

## Proposed Architecture & Structure

```
lib/
  core/
    theme/
      app_theme.dart             # Material 3 light & dark themes, colorScheme.fromSeed
    utils/
      currency_formatter.dart    # Format cents into currency strings
      date_formatter.dart        # Format DateTime for UI
    di/
      database_provider.dart     # Riverpod providers for database & core services
  data/
    db/
      tables/
        categories_table.dart    # Categories table definition
        transactions_table.dart  # Transactions table definition (FK to categories)
        budgets_table.dart       # Budgets table definition (FK to categories)
      app_database.dart          # Drift database class, DAOs registration, migrations & initial seed data
  shared/
    models/
      transaction_type.dart      # Enum: expense, income
    widgets/
      empty_state.dart           # Reusable empty state view
      money_text.dart            # Consistent currency rendering widget
  features/
    categories/
      data/services/category_dao.dart
      domain/repositories/category_repository.dart
      presentation/
        view_models/categories_notifier.dart
        views/categories_screen.dart
        widgets/category_icon_picker.dart
    transactions/
      data/services/transaction_dao.dart
      domain/repositories/transaction_repository.dart
      presentation/
        view_models/transactions_notifier.dart
        view_models/transaction_form_notifier.dart
        views/transactions_screen.dart
        views/transaction_form_screen.dart
        widgets/transaction_list_tile.dart
        widgets/transaction_filter_bar.dart
    budget/
      data/services/budget_dao.dart
      domain/repositories/budget_repository.dart
      presentation/
        view_models/budget_notifier.dart
        views/budget_screen.dart
        widgets/budget_card.dart
        widgets/budget_dialog.dart
    dashboard/
      domain/repositories/dashboard_repository.dart
      presentation/
        view_models/dashboard_notifier.dart
        views/dashboard_screen.dart
        widgets/summary_cards.dart
        widgets/spending_pie_chart.dart
        widgets/recent_transactions_card.dart
    navigation/
      presentation/views/main_scaffold.dart # NavigationBar with 4 tabs
  main.dart
```

---

## Proposed Changes

### 1. Dependencies & Configuration

#### [MODIFY] [pubspec.yaml](file:///d:/My_Practice/Dart_Flutter/expense_tracker/pubspec.yaml)
- Add required dependencies:
  - `drift: ^2.24.0`
  - `drift_flutter: ^0.2.0`
  - `flutter_riverpod: ^2.6.1`
  - `fl_chart: ^0.70.0`
  - `intl: ^0.20.0`
  - `uuid: ^4.5.1`
- Add dev dependencies:
  - `drift_dev: ^2.24.0`
  - `build_runner: ^2.4.0`
  - `flutter_lints: ^6.0.0`
  - `flutter_test` (with `test` support)

---

#### Recent UI Improvements
- Converted the Category add dialog into a full‑screen `CategoryFormScreen` and moved it to `presentation/views`. Navigation now uses `Navigator.push`.
- Removed all SnackBar success messages for category addition as requested.
- Redesigned `BudgetFormDialog` into a premium Dialog with rounded corners, header icon, filled text fields, and full‑width action buttons.
- Changed FAB alignment from `centerDocked` to `centerFloat` in `MainScaffold` to avoid clipping with the navigation bar.
- Fixed deprecation warnings by replacing `.withOpacity()` calls with `.withValues(alpha: …)` throughout the codebase.

### 2. Core Layer

#### [NEW] [app_theme.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/core/theme/app_theme.dart)
- Material 3 theme configuration with light and dark themes using `ColorScheme.fromSeed` (Seed: `#006C4C` Deep Emerald).
- Configures `cardTheme`, `inputDecorationTheme`, `segmentedButtonTheme`, `navigationBarTheme`.

#### [NEW] [currency_formatter.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/core/utils/currency_formatter.dart)
- Utility functions to convert between integer cents and display currency (e.g. `formatCents(int cents)` -> `"$12.50"`, `parseCents(String input)` -> `1250`).

#### [NEW] [date_formatter.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/core/utils/date_formatter.dart)
- Friendly formatting for dates: Today, Yesterday, `MMM d, yyyy`.

---

### 3. Database Layer (Drift)

#### [NEW] [categories_table.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/data/db/tables/categories_table.dart)
- `Categories` table:
  - `id`: `integer().autoIncrement()()`
  - `name`: `text().withLength(min: 1, max: 50)()`
  - `icon`: `text()` (Material icon key or name)
  - `color`: `integer()` (Color value ARGB)
  - `isIncome`: `boolean().withDefault(const Constant(false))()`

#### [NEW] [transactions_table.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/data/db/tables/transactions_table.dart)
- `Transactions` table:
  - `id`: `integer().autoIncrement()()`
  - `amount`: `integer()()` (in cents!)
  - `type`: `textEnum<TransactionType>()()` (expense, income)
  - `categoryId`: `integer().references(Categories, #id, onDelete: KeyAction.cascade)()`
  - `date`: `dateTime()()`
  - `note`: `text().nullable()()`
  - `createdAt`: `dateTime().withDefault(currentDateAndTime)()`

#### [NEW] [budgets_table.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/data/db/tables/budgets_table.dart)
- `Budgets` table:
  - `id`: `integer().autoIncrement()()`
  - `categoryId`: `integer().references(Categories, #id, onDelete: KeyAction.cascade)()`
  - `amountLimit`: `integer()()` (in cents!)
  - `month`: `integer()()` (1-12)
  - `year`: `integer()()`
  - Unique constraint on `(categoryId, month, year)`.

#### [NEW] [app_database.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/data/db/app_database.dart)
- Connects tables and DAOs.
- Implements `MigrationStrategy` with `onCreate` pre-populating standard default categories (Food & Dining, Groceries, Transport, Entertainment, Utilities, Salary, Freelance, Investments) with appropriate icons and colors.
- Provides factory for production (using `drift_flutter`) and constructor for tests (taking `QueryExecutor`).

---

### 4. Features & MVVM Implementation

#### Categories Feature:
- **Service**: [category_dao.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/categories/data/services/category_dao.dart) — query & stream categories.
- **Repository**: [category_repository.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/categories/domain/repositories/category_repository.dart) — contract & implementation.
- **ViewModel**: [categories_notifier.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/categories/presentation/view_models/categories_notifier.dart) — `AsyncNotifier` of categories, add/update/delete category commands.
- **View**: [categories_screen.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/categories/presentation/views/categories_screen.dart) — lists categories by type with color & icon chips, dialog to add custom categories.

#### Transactions Feature:
- **Service**: [transaction_dao.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/transactions/data/services/transaction_dao.dart) — watch transactions joined with Category, filtered by date range and type.
- **Repository**: [transaction_repository.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/transactions/domain/repositories/transaction_repository.dart) — clean domain models, insert/update/delete transactions.
- **ViewModel**:
  - [transactions_notifier.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/transactions/presentation/view_models/transactions_notifier.dart) — filter state (month, category, type) + transaction stream.
  - [transaction_form_notifier.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/transactions/presentation/view_models/transaction_form_notifier.dart) — form validation, submission.
- **Views**:
  - [transactions_screen.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/transactions/presentation/views/transactions_screen.dart) — list with search/filter bar, swipe to delete, tap to edit.
  - [transaction_form_screen.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/transactions/presentation/views/transaction_form_screen.dart) — SegmentedButton (Expense/Income), Numpad/Amount input, Category picker grid, DatePicker, Note input.

#### Budget Feature:
- **Service**: [budget_dao.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/budget/data/services/budget_dao.dart) — queries budget items with current month spending aggregated per category.
- **Repository**: [budget_repository.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/budget/domain/repositories/budget_repository.dart).
- **ViewModel**: [budget_notifier.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/budget/presentation/view_models/budget_notifier.dart) — monitors budget limits vs actual spend, percentage thresholds.
- **View**: [budget_screen.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/budget/presentation/views/budget_screen.dart) — monthly overview, progress bars per category budget, set/edit budget limits dialog.

#### Dashboard Feature:
- **Repository**: [dashboard_repository.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/dashboard/domain/repositories/dashboard_repository.dart) — aggregates monthly income, expenses, net balance, and spending breakdown by category.
- **ViewModel**: [dashboard_notifier.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/dashboard/presentation/view_models/dashboard_notifier.dart).
- **View**: [dashboard_screen.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/dashboard/presentation/views/dashboard_screen.dart) —
  - Top summary cards: Net Balance, Total Income (green), Total Expense (red).
  - Spending breakdown pie chart powered by `fl_chart`.
  - Recent transactions list with shortcut to "View All".
  - Floating Action Button to quickly add transaction.

#### Navigation & Entrypoint:
- [main_scaffold.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/features/navigation/presentation/views/main_scaffold.dart) — `NavigationBar` with Dashboard, Transactions, Budgets, and Categories.
- [main.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/lib/main.dart) — wrapped in `ProviderScope`, applies `AppTheme.lightTheme` & `AppTheme.darkTheme`.

---

### 5. Verification & Tests

#### [NEW] [transaction_dao_test.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/test/data/services/transaction_dao_test.dart)
- In-memory Drift test database verifying:
  - Inserting category and transaction
  - Calculating monthly totals
  - Cascading deletes and joins

#### [NEW] [budget_dao_test.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/test/data/services/budget_dao_test.dart)
- Testing budget limit upsert and category spend calculation.

#### [NEW] [view_model_tests.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/test/features/transactions/transactions_notifier_test.dart)
- Unit testing ViewModel state transitions with mock/fake repositories.

#### [NEW] [widget_test.dart](file:///d:/My_Practice/Dart_Flutter/expense_tracker/test/widget_test.dart)
- Testing app launch, navigation between tabs, and adding a transaction.

---

## Verification Plan

### Automated Tests
1. **Code Generation**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
2. **Static Analysis**:
   ```bash
   flutter analyze
   ```
3. **Automated Unit & Widget Tests**:
   ```bash
   flutter test
   ```

### Manual Verification
1. Launch app on Windows / Chrome / Emulator.
2. Verify default categories are seeded and visible.
3. Add an expense (e.g. $15.50 for Groceries) and an income (e.g. $2500 for Salary).
4. Verify Dashboard displays updated net balance, income/expense cards, and pie chart.
5. Create a budget for Groceries ($200) and verify progress indicator on the Budget tab.
6. Toggle dark / light mode to ensure Material 3 compliance.

---

# Frontend Elevation: Apple-Grade Fluid UI/UX Roadmap

This roadmap adapts Apple's Human Interface Guidelines, fluid motion principles (WWDC *Designing Fluid Interfaces*, *Designing Audio-Haptic Experiences*, *The Details of UI Typography*), and physics-driven micro-interactions into Fynza's Flutter Material 3 design system.

## Core Architectural Pillars for Frontend Motion

1. **Zero Input Latency (`Response`)**:
   - Provide visual feedback on pointer-down / touch-down (scale down `0.97x`–`0.98x`) via custom reusable `PressableScale` widget instead of waiting for `onTap` release.
2. **Physical Spring Behavior (`Physics over Animation`)**:
   - Critically damped springs ($\zeta = 1.0$, duration `0.35s`) for standard UI transitions; slight momentum bounce ($\zeta \approx 0.8$) only for flick gestures.
   - Interruptible and reversible mid-motion without velocity discontinuities ("brick walls").
3. **Multi-Modal Tactility (`Audio-Haptic Harmony`)**:
   - Synchronized light haptic feedback (`HapticFeedback.lightImpact()` / `selectionClick()`) firing on the exact frame of the commit.
4. **Depth & Translucency (`Materials`)**:
   - Translucent floating layers (`BackdropFilter` with blur, subtle hairline borders catching light) for sticky headers, Month Selector, and bottom sheets so content flows underneath.
5. **Soft Rubber-Banding Boundaries**:
   - `BouncingScrollPhysics` across all scrollables for natural physical resistance at boundaries.
6. **Optical Typography**:
   - Large currency totals with tightened optical tracking (`-0.02em`), robust weight hierarchy, and comfortable line heights.

---

## Phased Implementation Plan

### Phase 1: Shared Motion & Design System Primitives
- **[NEW] `lib/shared/widgets/pressable_scale.dart`**:
  - Reusable tap-down interactive wrapper with spring-backed scale (`0.975x`), optional light haptic feedback on touch-down, cancel on drag-away, and seamless release commit.
- **[NEW] `lib/core/theme/spring_curves.dart`**:
  - Curated physics curves and spring descriptions (critically damped `0.35s`, momentum flick `0.35s`, bottom-sheet spring).
- **[NEW] `lib/shared/widgets/frosted_card.dart` & `frosted_app_bar.dart`**:
  - Translucent blur surfaces (`BackdropFilter`) with light-catching borders and ambient surface tints for light/dark modes.
- **[MODIFY] `lib/core/theme/app_theme.dart`**:
  - Incorporate optical tracking for headline/display text (`-0.02em`), enhanced card surface tints, and unified border radii (`16dp`–`24dp`).

### Phase 2: Dashboard Experience Transformation
- **Floating Frosted Month Selector**:
  - Convert `MonthSelector` into a floating pill or frosted glass bar with directional spring slides and haptic feedback on month switch.
- **Interactive Summary Cards (`SummaryCards`)**:
  - Wrap in `PressableScale` with refined depth, elevated gradient accents, and optical typography for balance/income/expense.
- **Spring-Animated Charts (`SpendingPieChart`)**:
  - Smooth spring transitions between month category slices, interactive touch selection with haptics and tooltip badges.
- **Recent Transactions List**:
  - Polished cards with instant press feedback, smooth swipe reveal for quick actions, and clean empty states.

### Phase 3: Transactions Screen & Search/Filter (Completed)
- **Sticky / Grouped Date Headers** (`lib/features/transactions/presentation/widgets/transaction_date_header.dart`):
  - Group transactions by calendar day with friendly date headers (`Today, Nov 5`, `Yesterday, Nov 4`) and color-coded net totals for that day.
- **Fluid Segmented Control** (`lib/shared/widgets/fluid_segmented_control.dart`):
  - Apple-style sliding pill filter bar (`All / Expenses / Income`) with spring-animated sliding background indicator, haptic selection clicks, and instant press feedback.
- **Tactile Search Field** (`lib/features/transactions/presentation/widgets/transaction_search_bar.dart`):
  - Subtle contrast, squircle borders, instant query updates, and tactile clear interaction.
- **Interactive Swipe Actions**:
  - `Dismissible` swipe-to-delete with `HapticFeedback.mediumImpact()` armed on swipe threshold and smooth rounded red delete background.
- **Responsive Empty State**:
  - Resilient scrolling empty state that adapts cleanly to small screens and active keyboards without overflowing.

### Phase 4: Transaction Entry Experience (`TransactionFormScreen`) (Completed)
- **Hero Optical Amount Display**:
  - Centerpiece container with large display typography (`letterSpacing: -1.0`), adaptive emerald/red coloration, and inline clear button.
- **Quick Amount Chips**:
  - Spring-bouncing increment chips (`+50`, `+100`, `+500`, `+1,000`, `+5,000`) with instant tactile feedback.
- **Fluid Segmented Type Control**:
  - Fluid sliding segmented control for Expense vs Income with haptics.
- **Tactile Category Chips**:
  - Pressable chips with glowing color-matched halo shadows, illuminated icon badges, and selection haptics.
- **Apple-Style Date Card & Note Input**:
  - Tactile squircle date picker card and streamlined note textfield.
- **Spring Submit Button**:
  - Full-width primary action button with `PressableScale` and haptic completion feedback.

### Phase 5: Budgets & Categories Polish (Completed)
- **Physics Gradient Progress Bar** (`lib/shared/widgets/spring_progress_bar.dart`):
  - Critically damped spring-animated progress bar with adaptive health gradients (emerald $\to$ amber $\to$ crimson).
- **Elevated `BudgetCard`**:
  - Squircle cards with category icon badge, progress percentage / over-limit warning pills, optical amount typography, and tactile edit/delete actions.
- **Elevated `BudgetScreen`**:
  - Gradient hero total budget card, category count chips, and smooth bouncing physics.
- **Tactile `BudgetFormDialog`**:
  - Clean squircle presentation with quick amount chips (`+500`, `+1k`, `+2k`, `+5k`) and tactile save button.
- **Elevated `CategoriesScreen`**:
  - FluidSegmentedControl type switcher (Expenses / Income), squircle category tiles with illuminated badges and tactile delete dialogs.
- **Interactive `CategoryFormScreen`**:
  - Tactile icon picker grid and color palette with animated glowing selection rings and haptics.
