## Production-Readiness Review (2026-09-21)

### 🔴 Critical — Fix before any public release

- [x] **Schema migration strategy**: `schemaVersion` is `2` with `onUpgrade` handler supporting clean migration and foreign key preservation.
- [ ] **Missing tests**: DAO integration tests and ViewModel unit tests are required by AGENTS.md but not yet written. Add tests for:
  - `CategoryDao`, `TransactionDao`, `BudgetDao` (using `NativeDatabase.memory()`)
  - `CategoriesNotifier`, `TransactionsNotifier`, `BudgetNotifier` (mocked repositories)
  - Critical widget tests: add transaction, view dashboard totals, edit budget

### 🟡 Important — Should fix before shipping

- [ ] **No error handling in ViewModels**: `addCategory()`, `addTransaction()`, etc. have no `try/catch`. A Drift write failure will silently fail. Wrap repository calls and expose an error state.
- [ ] **`app_database.g.dart` tracked by Git**: The generated file was committed before the `.gitignore` rule was added. Remove it from tracking:
  ```bash
  git rm --cached lib/data/db/app_database.g.dart
  ```
- [ ] **`pubspec.yaml` description**: Still shows the default Flutter placeholder text. Update to a meaningful description e.g. `"Fynza – a beautiful offline-first personal expense tracker."`.
- [ ] **App package name / bundle ID**: Rename from `expense_tracker` to `com.yourname.fynza` (or similar) in Android `build.gradle` and iOS `Info.plist` before releasing to the Play Store / App Store.

### 🟢 Nice-to-Have — Recommended for polish

- [ ] **`pubspec.lock` in version control**: Commit `pubspec.lock` for reproducible CI/CD builds. Remove the comment from `.gitignore`.
- [ ] **App icon & splash screen**: Add a branded launcher icon and splash screen using `flutter_launcher_icons` and `flutter_native_splash` packages.
- [ ] **`analysis_options.yaml`**: Confirm it references `flutter_lints` to enforce consistent code quality checks across the team.
- [ ] **Riverpod codegen (`@riverpod`)**: Migrate `StateNotifierProvider` + `StreamProvider` to the modern annotation-based `riverpod_generator` pattern for cleaner, less boilerplate-heavy providers.

