# Task: Backup & Restore ("Data and storage" screen)

> Give this whole file to the agent, or save it as `docs/prompts/backup_restore.md` and tell the agent: "Read and execute docs/prompts/backup_restore.md".

## 0. Ground rules (read first)

1. Read `AGENTS.md` and follow it strictly: feature-oriented MVVM (View -> ViewModel -> Repository -> Service), Drift as the only database, money as integer cents, Material 3 theming, Riverpod.
2. Before writing any code, inspect the existing project and report what you find: the Drift database class and its `schemaVersion`, every table/column/foreign key, existing DAOs, repositories and providers, how settings and navigation are currently done, and whether `PRAGMA foreign_keys` is enabled. Never assume names. Use what exists.
3. Produce a short implementation plan (files to add/change, packages needed, open questions) and **wait for my approval before coding**.
4. Work in the phases listed in section 9. A phase is finished only when `flutter analyze` shows no new issues and `flutter test` is green.
5. Reference only, do NOT port code: Mihon (https://github.com/mihonapp/mihon) is Kotlin/Android. Its backup logic lives in `app/src/main/java/eu/kanade/tachiyomi/data/backup/` (`create/BackupCreator.kt`, `restore/BackupRestorer.kt`). We copy its UX and ideas, not its code or its file format (Mihon uses gzipped protobuf; we use gzipped JSON).

## 1. Goal and scope

Add a "Data and storage" screen modeled on Mihon's: storage location, Create backup / Restore backup buttons, automatic backup frequency, "last automatically backed up" label, and storage usage.

**In scope**
- Manual create backup (user chooses where to save it)
- Restore from a user-picked file
- Automatic periodic backups with rotation
- Restore from the list of automatic backups (in-app list)
- Automatic safety backup right before every restore

**Out of scope (do not build)**
- Cloud sync or Google Drive upload
- Password encryption of backups
- Merge-restore (v1 restore = replace all data)
- CSV/Excel export
- Custom folder picker for automatic backups
- The "Clear cache" item from the reference screenshot
- iOS background scheduling beyond the launch catch-up in section 6

## 2. Architecture and file layout (per AGENTS.md)

```
lib/features/backup/
  presentation/
    views/data_and_storage_view.dart
    widgets/                      # frequency dialog, restore sheet, info rows, etc.
    view_models/backup_view_model.dart   # + immutable BackupUiState
  domain/
    models/                       # BackupFailure (sealed), BackupSummary, AutoBackupFrequency
    repositories/backup_repository.dart  # interface + implementation
  data/
    services/
      backup_serializer.dart      # DTOs <-> JSON, versioning
      backup_validator.dart       # structural + referential validation
      backup_file_service.dart    # read/write/list/rotate files, gzip
      backup_preferences_service.dart  # SharedPreferences wrapper
      auto_backup_scheduler.dart  # WorkManager + launch catch-up
```

- Views only render `BackupUiState` and call ViewModel commands. ViewModels only call `BackupRepository`. The repository composes the services and the existing feature repositories/DAOs. No layer skipping.
- Backup DTOs are hand-written classes with stable JSON keys. Do NOT use Drift's generated `toJson`/`fromJson` for the file format, so a future column rename can never silently change the backup format.
- Add a "Data and storage" entry to the existing Settings screen (if no Settings screen exists, create a minimal one). Use the project's existing navigation approach.

## 3. Backup file format

- Extension: `.expbak` (define as a single constant). Content: UTF-8 JSON compressed with `dart:io` `gzip`. No extra archive package.
- File names: manual `<app_slug>_YYYY-MM-DD_HH-mm.expbak`, automatic `auto_<app_slug>_YYYY-MM-DD_HH-mm.expbak`. Derive `<app_slug>` from the app name in `pubspec.yaml`.
- Envelope:

```json
{
  "formatVersion": 1,
  "appVersion": "1.0.0",
  "dbSchemaVersion": 1,
  "createdAt": 1760000000000,
  "data": {
    "categories": [],
    "transactions": [],
    "budgets": [],
    "preferences": {}
  }
}
```

- Keep primary-key IDs in the file so foreign keys survive the round trip.
- Money = integer cents. Dates = epoch milliseconds (UTC). Never `double` for money.
- Compatibility: `formatVersion` drives compatibility. Unknown extra fields are ignored; missing optional fields get defaults. A file with `formatVersion` greater than the app supports is rejected with a clear "created by a newer app version" message. For older versions, route through a `BackupMigrator` (a no-op for v1, but the hook must exist).
- `preferences`: whitelist only user-facing settings that already exist (e.g. currency, theme mode). NEVER include backup settings (interval, last-backup time, paths) or anything secret.
- Integrity: gzip's built-in CRC plus structural validation is enough. Do not invent a custom checksum.
- Do NOT back up by copying the raw SQLite file (WAL files and schema version drift make that unsafe).

## 4. Create backup flow

1. Read all tables inside ONE Drift `transaction()` so the snapshot is consistent.
2. Map to DTOs, JSON-encode, gzip. Use `Isolate.run` (or `compute`) for the encode/gzip step when the dataset is large so the UI never janks.
3. Manual: open the system "Save as" dialog (`file_picker` `saveFile`; on mobile the plugin needs the bytes passed in, check the installed version's docs). No storage permissions. A cancelled dialog (null result) is a silent no-op.
4. Automatic: write to `<name>.tmp` in the backup directory, then rename to the final name. Delete the `.tmp` on failure. On every automatic run, first delete stale `.tmp` files left by a killed process.
5. Show a progress state, then a SnackBar with the result (file name on success, friendly message on failure).

## 5. Restore flow (highest risk, be strict)

Order matters. Do not reorder.

1. **Pick**: `FilePicker` with `FileType.any` (custom extensions are unreliable for unknown MIME types on Android). Read the bytes. Cancel = silent no-op.
2. **Decode**: check gzip magic bytes (0x1F 0x8B), gunzip, UTF-8 decode, JSON parse. ANY exception here maps to `BackupFailure.invalidFile`. Truncated or corrupted files must never crash the app.
3. **Validate** (nothing touches the database yet): required envelope fields and types, supported `formatVersion`, required sections, every field of the right type, no duplicate IDs per table, every foreign key points to an existing row (or is legitimately null), amounts are ints, dates are ints. Collect failures and abort with a readable message.
4. **Confirm**: dialog showing backup date and counts (N transactions, N categories, N budgets), plus the warning "This will replace all current data. A safety copy of your current data will be saved first." Destructive-styled confirm button.
5. **Safety backup**: write a backup of the CURRENT data to `<backup dir>/pre_restore/` (keep only the newest 2). If this fails, ABORT the restore.
6. **Apply atomically**: inside ONE Drift `transaction()`: delete child tables first, then parents; insert parents first, then children; use `batch` inserts with explicit IDs. Do not toggle `PRAGMA foreign_keys` inside the transaction (SQLite ignores it there). Apply whitelisted preferences only after the transaction commits.
7. **Failure**: any exception rolls the transaction back, leaving the database exactly as it was. Surface the error. Nothing partial, ever.
8. **Success**: Drift `watch()` streams refresh the UI automatically, so no app restart is needed. Show a success message with counts.
9. **Guard**: while creating/restoring, set a busy state, disable both buttons, and block back navigation with `PopScope`. No two operations may run at the same time inside the app.

## 6. Automatic backups

- Frequency options: Off, Every 6 hours, Every 12 hours (default), Daily, Every 2 days, Weekly. Store as hours in `SharedPreferences` (0 = off), plus `lastAutoBackupAt` (epoch ms) and `maxAutoBackups` (default 3, internal only, no UI).
- Backup directory: Android app-specific external files dir (`getExternalStorageDirectory()` + `/backups`), falling back to `getApplicationDocumentsDirectory()` + `/backups`. This needs no permissions. Do NOT add `READ/WRITE_EXTERNAL_STORAGE` or `MANAGE_EXTERNAL_STORAGE`.
- Android 11+ blocks the system file picker from browsing `Android/data`, so users cannot pick auto backups from the file picker. That is why the in-app "Automatic backups" list (section 7) is required, with per-item Restore / Share / Delete.
- Scheduling: `workmanager` periodic task with a unique name. When the interval changes, replace/update the existing schedule (the exact policy name depends on the package version, check its docs). Cancel the task when set to Off. The interval must always be at least 15 minutes (our options are far above this).
- The WorkManager callback is a top-level function annotated `@pragma('vm:entry-point')` and runs in a SEPARATE isolate:
  - call `DartPluginRegistrant.ensureInitialized()` / `WidgetsFlutterBinding.ensureInitialized()` as the package requires
  - it must open its OWN Drift connection and construct the services manually (no Riverpod container, no shared singletons) and close the connection in `finally`
  - enable WAL and a busy timeout so it does not hit "database is locked" while the app is open; check Drift's multi-isolate docs
- Launch catch-up: after the first frame, if auto backup is enabled and `now - lastAutoBackupAt >= interval`, run one in the background. This covers iOS and OEMs that kill workers. Put the decision in a pure function `shouldRunAutoBackup(now, last, interval)` so it is unit-testable.
- Rotation: after a successful write, list files matching the auto-backup name pattern, sort newest first, delete everything beyond `maxAutoBackups`. Only ever delete files that match our own naming pattern. Never touch other files.
- Update `lastAutoBackupAt` ONLY on success. A failure is logged (without data contents) and never crashes.

## 7. UI spec (Material 3, mirrors the reference screenshot)

`DataAndStorageView`, colors and text styles strictly from `Theme.of(context)` (no hardcoded colors), light and dark mode, text scale up to 200% without overflow, minimum 48dp touch targets, semantic labels on icon-only buttons.

- **AppBar**: back arrow, title "Data and storage", help icon (opens a dialog explaining what is backed up and where files live).
- **Storage location**: `ListTile`, subtitle = the resolved auto-backup directory path. Tap copies the path and shows a SnackBar.
- **Info row**: info icon + "Used for automatic backups. They are deleted if the app is uninstalled, so use Create backup to save a copy elsewhere."
- **Section header** "Backup and restore" (primary color, title-small style).
- **Joined pill button pair**: "Create backup" | "Restore backup", equal width, outlined, stadium shape, a divider between them (two `OutlinedButton`s in one clipped container, or an equivalent that looks the same). Disabled while busy.
- **Restore backup** opens a bottom sheet with: "Choose a file..." and a list "Automatic backups" (newest first, date + size, overflow menu: Restore / Share / Delete). Include an empty state. Pre-restore safety copies are NOT listed here.
- **Automatic backup frequency**: `ListTile` with the current value as subtitle. Tap opens a dialog with `RadioListTile`s for the options. Selecting saves, reschedules, and closes.
- **Info row**: "Keep copies of backups in other places as well. Backups contain your financial data; be careful if sharing." Below it: "Last automatically backed up: <relative time>" ("Never" if null). Write a small relative-time helper (Just now / N minutes ago / N hours ago / Yesterday / date) and unit-test it.
- **Section header** "Storage usage": "Automatic backups: N files, X MB" (computed asynchronously with `dart:io`). Show a device-storage bar (Available / Total) ONLY if a well-maintained package provides it. Otherwise omit it, and do not add an unmaintained dependency.
- **Busy state**: `LinearProgressIndicator` plus a status line ("Creating backup...", "Validating...", "Restoring...").
- **Errors** map from a sealed `BackupFailure` (`invalidFile`, `unsupportedVersion`, `corruptData`, `storageError`, `unknown`) to friendly messages in ONE place. Never show raw exception text.
- User-facing strings: follow the project's existing approach (l10n if present, otherwise constants in one file).

## 8. Packages and platform config

- Allowed (check the latest compatible versions on pub.dev, use caret constraints): `file_picker`, `share_plus`, `path_provider`, `workmanager`, `shared_preferences`, `package_info_plus`, `intl`.
- Do NOT add any other package without asking me first. Do NOT add a second database package.
- Follow each package's current README for Android setup (Gradle/Manifest). Report every platform file you touch.

## 9. Phases

1. **Data layer, no UI**: DTOs, serializer, validator, migrator hook, file service, repository `createBackup` / `restore`, plus all tests from section 10 that cover them.
2. **Manual flow**: ViewModel, `DataAndStorageView`, Create/Restore buttons, restore confirmation, safety backup, error mapping, Settings entry.
3. **Automatic backups**: preferences, frequency dialog, scheduler, background callback, launch catch-up, rotation, automatic-backups list in the restore sheet.
4. **Polish**: storage usage section, help dialog, accessibility pass, dark-mode and text-scale check.

At the end of each phase give me a short summary: what changed, test results, and anything you deviated on.

## 10. Tests (mandatory)

- **Round trip**: create backup, restore into a fresh in-memory Drift DB (`NativeDatabase.memory()`), data is identical. Cover nullable fields, unicode notes, zero amounts, and a large set (10k+ transactions).
- **Validation**: non-gzip bytes, truncated gzip, valid gzip but invalid JSON, missing section, orphan foreign key, duplicate IDs, wrong field types, newer `formatVersion`. Each must produce the right `BackupFailure` and leave the DB untouched.
- **Atomicity**: force a failure halfway through the restore (e.g. a row that violates a constraint), then assert the DB equals its pre-restore state.
- **IDs**: after a restore, inserting a new row gets an ID that does not collide with any restored ID.
- **Rotation**: with N+3 files in a temp dir, only the newest N remain, and unrelated files are never deleted. Stale `.tmp` files are cleaned.
- **Scheduling logic**: `shouldRunAutoBackup` edge cases (never backed up, exactly at the interval, clock moved backwards, interval = Off).
- **ViewModel** (fake repository): state transitions for create/restore, failure mapping, busy state blocks a second operation.
- **Widget**: screen renders all sections; tapping the frequency tile opens the dialog and persists the selection.
- Commands that must pass at the end: `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, `flutter test`.
- Finish with a manual QA checklist on a real Android device or emulator: create, restore, restore a corrupted file, kill the app mid-backup, auto backup after changing frequency, uninstall and reinstall then restore a manually saved file.

## 11. Hard rules (definition of done)

- No data loss: restore is all-or-nothing, and a safety backup always exists before it starts.
- Never log or print backup contents or financial values.
- Never write outside the designated backup directory (except the user-chosen "Save as" target). Never delete files that are not ours.
- Never use `double` for money. Never bypass the layer rules from AGENTS.md.
- No new storage permissions.
- Cancelled pickers and dialogs are silent no-ops.
- No new analyzer warnings, no `// ignore` shortcuts without a written reason.

## 12. Housekeeping when finished

Append this rule to `AGENTS.md`: "Whenever the database schema changes, update the backup DTOs and serializer, bump `formatVersion` (and add a migrator step) if the change is not backward compatible, and add or update a round-trip test."
