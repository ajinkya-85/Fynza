# Task: Automatic transaction capture from bank SMS notifications (Android)

> Give this whole file to the agent, or save it as `docs/prompts/auto_capture.md` and tell the agent: "Read and execute docs/prompts/auto_capture.md".

## 0. Ground rules (read first)

1. Read `AGENTS.md` and follow it strictly: feature-oriented MVVM (View -> ViewModel -> Repository -> Service), Drift as the only database, money as integer cents, Material 3 theming, Riverpod.
2. Before writing any code, inspect the existing project and report what you find: the Drift database class and `schemaVersion`, the transactions/categories tables and how income vs expense is represented, the existing add-transaction screen (we will reuse it prefilled), the backup feature (`features/backup`), how `workmanager` background isolates are already set up, and how settings and navigation are done. Never assume names.
3. Produce a short implementation plan (files, packages, open questions, and the capture-layer decision in section 4) and **wait for my approval before coding**.
4. Work in the phases in section 13. A phase is finished only when `flutter analyze` shows no new issues and `flutter test` is green.
5. This feature is Android only. Do NOT request `READ_SMS`, `RECEIVE_SMS` or any SMS permission. Do NOT use an Accessibility service. The only mechanism is Android's `NotificationListenerService` (the user grants "Notification access" in system settings).
6. Put the whole feature behind one compile-time flag, `const bool kAutoCaptureEnabled = bool.fromEnvironment('AUTO_CAPTURE', defaultValue: true);`, so the UI can be hidden in a build where I decide not to ship it. In the plan, propose (do not implement without approval) how to exclude the native service's manifest entry for such a build.

## 1. Goal and scope

When the user pays or receives money, their bank sends an SMS. The SMS app shows a notification. Our app reads only those notifications, turns them into transactions, and lets the user review or auto-add them.

**In scope**
- Notification listener limited to the device's SMS apps
- Pure-Dart bank-SMS parser (amount, debit/credit, counterparty, reference, account last 4)
- De-duplication
- Pending-review inbox plus an optional "add automatically" mode with Undo
- Onboarding, permission status, and a "paste an SMS to test the parser" tool
- Drift migration and backup/restore integration

**Out of scope (do not build)**
- Reading the SMS database / any SMS permission
- Reading UPI-app notifications (GPay, PhonePe, Paytm...). Design a `CaptureSource` abstraction so it can be added later, but build only the SMS-app source
- Posting our own "transaction detected" notifications
- iOS support
- Cloud sync, ML categorization
- Storing raw message text (see section 11)

Assumption: messages are Indian-bank style (INR, UPI). Keep currency handling and keyword lists in one constants file so they can change. Messages in a different currency are ignored, never converted.

## 2. Architecture and file layout (per AGENTS.md)

```
lib/features/auto_capture/
  presentation/
    views/auto_capture_settings_view.dart
    views/capture_inbox_view.dart
    views/parser_playground_view.dart
    widgets/
    view_models/
      auto_capture_settings_view_model.dart
      capture_inbox_view_model.dart
  domain/
    models/        # RawNotification, ParsedTransaction, CaptureItem, CaptureStatus, CaptureMode
    parsing/       # sms_transaction_parser.dart (pure Dart, no Flutter imports), parser_rules.dart
    repositories/capture_repository.dart   # interface + implementation
  data/
    services/
      notification_capture_service.dart    # platform side (see section 4)
      capture_dao.dart                     # Drift DAO
      capture_preferences_service.dart     # SharedPreferences wrapper
      capture_dedupe.dart
android/app/src/main/kotlin/.../autocapture/   # only if the native route is chosen
```

- Views render state and call ViewModel commands. ViewModels talk only to `CaptureRepository`. The repository composes the services and the existing transaction repository. No layer skipping.
- The parser is a pure function `ParseResult parse(String text, DateTime postedAt)` with zero I/O so it can be tested exhaustively.
- Reuse the existing add-transaction screen/sheet for editing a pending item (open it prefilled). Do not duplicate transaction-entry UI.

## 3. Data model and migration

New Drift table `captured_transactions` (adapt names to project conventions):

| column | notes |
|---|---|
| id | autoincrement PK |
| amountCents | int, always positive |
| type | expense / income (reuse the project's existing type representation) |
| counterparty | nullable text, best-effort |
| accountLast4 | nullable text |
| reference | nullable text (UPI ref / txn id) |
| occurredAt | epoch ms = the notification's post time |
| capturedAt | epoch ms |
| sourcePackage | text |
| sender | text (notification title, e.g. `VM-HDFCBK`) |
| dedupeKey | text, **UNIQUE** |
| status | pending / confirmed / dismissed |
| transactionId | nullable FK to transactions (set when confirmed or auto-added) |
| suggestedCategoryId | nullable FK to categories |

- Pending items must NEVER affect totals, charts, or budgets. They live only in this table until confirmed.
- Bump `schemaVersion`, add an `onUpgrade` step following Drift's migration guide, and add a migration test (old schema -> new schema keeps all existing data).
- Also add a small table or preferences list for ignored senders (decide in the plan).
- Retention: purge `confirmed`/`dismissed` rows older than 90 days. Keep `pending` until handled.
- Backup integration (see `features/backup`): add an OPTIONAL `capturedTransactions` section to the backup DTOs. Missing section = empty list, so older backups still restore. Validate its foreign keys like the others. Add it to the round-trip test. Do NOT include capture settings or permission state in backups.

## 4. Capture layer (decision gate, present evidence in the plan)

Candidate plugin: `notification_listener_service` on pub.dev (exposes a `notificationsStream` with package name, title, content, and a removed flag). Many similar forks exist, so verify maintenance on pub.dev before choosing.

The key question is whether events arrive when the app is swiped away or the Flutter engine is not running. Investigate and report one of:

- **Route A (plugin):** only if you can show it delivers and persists events with no running engine.
- **Route B (recommended unless A proves out): small native Kotlin `NotificationListenerService`** in `android/app/src/main/kotlin/...`, declared in the manifest with `android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"` and `android:exported="true"`. It does cheap filtering natively and appends minimal records to a persistent queue. Dart drains the queue through a `MethodChannel`.

Native rules for Route B:
- In `onNotificationPosted`, IMMEDIATELY drop (no storing, no logging) anything not from an SMS app. SMS apps = the device default (`Telephony.Sms.getDefaultSmsPackage(context)`, which needs no permission) plus a fallback list of well-known SMS app packages in ONE constant (Google Messages, Samsung Messages, and the common OEM apps; verify the package names).
- Ignore removal events and notifications with `Notification.FLAG_GROUP_SUMMARY`.
- Read the sender from the title. Read the text from `EXTRA_BIG_TEXT` first, then `EXTRA_TEXT`, and also `Notification.EXTRA_MESSAGES` (SMS apps often use MessagingStyle and the full body is there). Verify on a real device.
- Native pre-filter: queue only if the text contains a currency marker (`Rs`, `Rs.`, `INR`, `₹`, case-insensitive). This keeps OTP and chat messages out of the queue entirely.
- Queue entry: `{key, packageName, title, text, postTime}`. Persist in app-private storage, append-only, bounded to the newest 500 entries, and drained atomically (swap/rename, then delete) with synchronization so nothing is lost or read twice.
- Implement `onListenerDisconnected` with `requestRebind` so the service recovers when the system unbinds it.

Dart side:
- `NotificationCaptureService.drain()` returns queued `RawNotification`s. Call it on app start, on app resume, and from a periodic `workmanager` task (reusing the backup feature's background-isolate pattern: its own Drift connection, closed in `finally`; the system minimum is 15 minutes and may delay it).
- If the engine is running, optionally also push events live through an `EventChannel`; ingestion must still be idempotent (section 7).

## 5. Ingestion pipeline (repository `ingest`)

For each `RawNotification`, in this order, stopping at the first failure:

1. Source gate: package is an SMS app (repeat the check in Dart as defense in depth).
2. Sender gate: the title looks like a bank/service header (e.g. `XX-ABCDEF`, `XX-ABCDEF-S`, or a short alphanumeric ID), not a saved person's name or a plain phone number, and is not in the user's ignored senders.
3. Parse (section 6). `NotATransaction` -> drop silently.
4. Dedupe (section 7). Duplicate -> drop silently.
5. Insert into `captured_transactions` as `pending` with a suggested category (section 8).
6. If mode = "add automatically" AND the parse is high confidence: in ONE Drift transaction insert the real transaction, set `status = confirmed` and `transactionId`. Otherwise leave `pending`.

Ingestion must never throw to the caller. Failures are caught per item and logged without message content.

## 6. Parser spec (pure Dart, table-driven)

Output: sealed `ParseResult` = `Parsed(amountCents, type, counterparty?, accountLast4?, reference?, confidence)` | `NotATransaction(reason)`.

- **Amount:** `Rs`, `Rs.`, `INR`, `₹`, with Indian digit grouping (`5,00,000.00`) and optional decimals. Convert to integer cents with STRING math (split on `.`, strip commas, pad/truncate fraction to 2 digits). Never parse through `double`.
- **Pick the right amount:** the one next to the debit/credit keyword. Ignore amounts after `Avl Bal`, `Bal`, `Balance`, `Limit`, `Available`.
- **Type:** debit keywords (`debited`, `spent`, `paid`, `sent`, `withdrawn`, `purchase`, `payment of`) -> expense. Credit keywords (`credited`, `received`, `deposited`) -> income. If both appear or neither, `NotATransaction`.
- **Must reject (return `NotATransaction`):** OTP/verification messages; promos and offers (`offer`, `pre-approved`, `loan`, `apply`, `click`, `cashback` without a debit/credit keyword); bill reminders and statements (`due`, `minimum amount due`, `statement`); collect/mandate requests; future tense (`will be debited`, `scheduled`); failed/declined/pending (`failed`, `declined`, `unsuccessful`); a currency other than INR.
- **Refunds/reversals** (`refund`, `reversed`): treat as income, counterparty kept, confidence = medium.
- **Reference:** UPI Ref / Ref No / Txn ID patterns -> `reference`.
- **Account:** `A/c XX1234`, `a/c ending 1234`, `card XX1234` -> last 4 digits only.
- **Counterparty (best-effort, nullable):** after `to`, `at`, `from`, `VPA`, `UPI/...`, `Info:`. Strip the handle domain noise. Fall back to null (UI shows "Bank transaction").
- **Date:** use the notification's `postTime` as `occurredAt`. Do NOT parse the date text (formats and time zones vary).
- **Confidence:** high = amount + one unambiguous type keyword + (reference or account). Anything else = medium. Only high is eligible for auto-add.
- All keyword lists and regexes live in `parser_rules.dart`, so adding a bank format means editing data, not logic.

## 7. De-duplication

- `dedupeKey` = SHA-256 of `reference` when present (so the same payment seen twice collapses), otherwise SHA-256 of `type + amountCents + accountLast4 + sender + normalized text`.
- Without a reference, treat identical normalized text within 10 minutes as the same message (covers a notification being re-posted or updated).
- Rely on the UNIQUE constraint. Insert with conflict-ignore so `ingest` is idempotent and safe to run twice on the same queue.
- Dismissed and confirmed rows keep their `dedupeKey`, so a re-delivered message never reappears.
- Known trade-off (document it in code): two truly identical SMS with no reference inside the window collapse into one. The user can always add the second manually.

## 8. Review inbox and automatic mode

- **Mode** (`CaptureMode`): `reviewFirst` (default) or `addAutomatically`. Stored in `SharedPreferences`.
- **Suggested category:** last category the user confirmed for the same normalized counterparty (lowercase, digits and handle noise removed). Needs a tiny lookup table, updated on every confirm. Null if unknown.
- **Confirm:** open the existing add-transaction screen prefilled (amount, type, counterparty as note/title, `occurredAt`, suggested category). On save, in ONE Drift transaction: insert the transaction, set the capture row to `confirmed` with `transactionId`, update the category lookup.
- **Dismiss:** set `dismissed`. Offer Undo for a few seconds via SnackBar.
- **Auto-added items** appear in a "Recently auto-added" section with an Undo action. Undo, in ONE transaction: delete the created transaction and set the capture row to `dismissed`.
- **Ignore this sender:** overflow action that adds the sender to the ignored list and dismisses its pending items.
- Pending count is exposed as a `Stream<int>` for a badge on the dashboard/app bar.

## 9. Permission, onboarding and status

- The settings screen shows a status card: `Active`, `Permission needed`, or `Disabled by you`.
- Enable flow: an explanation dialog first (what is read, that it stays on the device, that Android will show a scary warning), then open Android's Notification access settings (`Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS`). On app resume, re-check whether access is granted and refresh the status.
- Re-check permission on every app resume. If it was revoked, show a banner on the inbox/dashboard with a one-tap fix.
- Battery help dialog: plain instructions (Settings > Apps > this app > Battery > Unrestricted) because some phones stop background services. Do NOT request `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
- Master switch "Auto-capture": off = native side drops everything (use a flag the native code reads), Dart drain is skipped. Also offer "Delete all captured data".

## 10. UI spec (Material 3)

Theme tokens only (no hardcoded colors), light/dark, text scale to 200%, 48dp touch targets, semantic labels.

- **AutoCaptureSettingsView:** status card, enable/disable switch, mode radio (Review first / Add automatically, with a one-line risk note for the second), "Test with a pasted message" entry, "Ignored senders" list with remove, battery help, "Delete captured data" (confirm dialog).
- **CaptureInboxView:** pending items first (amount colored by type via theme roles, counterparty or "Bank transaction", date/time, suggested category chip, sender in small text). Per item: primary "Add" and "Dismiss"; overflow "Ignore this sender". Then "Recently auto-added" with Undo. Empty state with a short explanation. Include a loading and error state.
- **ParserPlaygroundView:** multiline field to paste an SMS, a "Parse" button, and a result card showing each extracted field, or the rejection reason. Optional button "Add as pending" that runs the same pipeline from step 3 onward. This is also the manual fallback when detection misses something. Pasted text is kept in memory only.
- Entry points: Settings > "Auto-capture", plus an inbox icon with a badge in the dashboard app bar.

## 11. Privacy and security (non-negotiable)

- Process everything on the device. No network calls from this feature.
- Do NOT store raw message text anywhere (database, queue after processing, preferences, logs). Store only parsed fields. The native queue entry is deleted as soon as it is processed.
- Never log message text, amounts, or senders. Log only counts and error types.
- The native service must discard any notification not from an SMS app immediately and without persisting or logging it.
- OTP messages must never reach the database or logs. Add a test that proves it.
- No new permissions other than the notification-listener service declaration. No network, SMS, contacts, or accessibility permissions.

## 12. Packages and platform config

- Allowed: `notification_listener_service` (only if Route A is chosen; verify maintenance first), plus packages already in the project (`workmanager`, `shared_preferences`, `crypto` for SHA-256, `intl`).
- Do NOT add other packages without asking me. Do NOT add a second database package.
- Follow each package's current README for Android setup. Report every platform file you touch (manifest, Gradle, Kotlin files).

## 13. Phases

1. **Pure logic, no UI, no platform code:** `parser_rules`, `SmsTransactionParser`, dedupe key logic, models, and the full parser test suite from section 14.
2. **Data layer:** Drift table + migration + DAO, `CaptureRepository.ingest/confirm/dismiss/undo`, backup DTO integration, tests (including migration and backup round trip).
3. **Capture layer:** the Route A/B decision implemented, queue drain, resume/start/background drain, permission checks.
4. **UI:** settings, onboarding, inbox, playground, badge, auto-add mode with Undo, ignored senders.
5. **Polish:** suggested-category lookup, retention purge, accessibility, dark mode and text-scale pass, battery help.

At the end of each phase give me a short summary: what changed, test results, and anything you deviated on.

## 14. Tests (mandatory)

- **Parser (table-driven, in `test/fixtures/sms_samples.txt` or similar, one case per line with expected result):** accept debit with UPI ref, credit with reference, card spend, refund, amounts with Indian grouping and with/without decimals, balance after the amount (must not be picked), multiple amounts in one message. Reject OTP, promo/loan offer, bill due, statement, mandate/collect request, future-tense debit, failed transaction, non-INR currency, person-to-person chat containing a number. Include 25+ cases. I will add anonymized real messages to this fixture file later, so keep the format easy to extend.
- **Amount math:** `Rs 1,234.5` -> 123450, `Rs 5,00,000` -> 50000000, `Rs.0.99` -> 99. Assert no `double` is used.
- **Dedupe:** same reference twice -> one row; identical text re-posted within 10 minutes -> one row; same text with different reference -> two rows; `ingest` run twice on the same input is a no-op the second time.
- **Pipeline:** non-SMS package dropped; person-name sender dropped; ignored sender dropped; exceptions on one item don't stop the rest.
- **Pending isolation:** a pending row does not change any total, chart query, or budget calculation.
- **Confirm/undo atomicity:** force a failure mid-confirm and assert no half-created transaction; undo removes exactly the transaction it created.
- **Auto-add:** only high-confidence items are auto-added; medium stays pending.
- **Migration:** old schema -> new schema keeps all existing data; new table usable.
- **Backup:** round trip with captures; restoring an old backup without the section works.
- **Privacy:** an OTP message produces no DB row and no log output containing its text.
- **ViewModels** (fake repository): inbox state transitions, badge count, mode changes, permission-missing state.
- **Widget:** inbox renders pending and auto-added sections; playground shows parsed fields and rejection reasons.
- Commands that must pass at the end: `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, `flutter test`.
- **Manual QA on a real Android device:** grant/revoke notification access; real bank SMS (debit and credit) with the app open, in the background, and swiped away; reboot the phone and confirm capture resumes; swap the default SMS app (Google Messages vs the phone's own); a re-posted notification; grouped notifications; an OTP and a promo SMS (nothing captured); a phone with aggressive battery management.

## 15. Hard rules (definition of done)

- Pending items never change totals. Confirm and undo are all-or-nothing.
- Never use `double` for money. Never bypass the layer rules from AGENTS.md.
- No SMS permissions, no accessibility service, no network access in this feature.
- Never store or log raw message text.
- `ingest` is idempotent and never throws to the caller.
- Cancelled dialogs are silent no-ops.
- No new analyzer warnings, no `// ignore` shortcuts without a written reason.

## 16. Housekeeping when finished

Append these rules to `AGENTS.md`:
- "Any new bank SMS format must be added to the parser fixtures first, then to `parser_rules.dart`; do not change parser logic to special-case one bank."
- "Captured/pending data must never be included in totals, charts, or budgets until confirmed."
