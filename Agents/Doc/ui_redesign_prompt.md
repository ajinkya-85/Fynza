# Task: Full UI redesign, green budget style (light + dark)

> Give this file to the agent together with the two reference images, or save it as `docs/prompts/ui_redesign.md` and tell the agent: "Read and execute docs/prompts/ui_redesign.md". Mockups of the target look: https://claude.ai/artifact/CisNMAnPf3KZnbA88ZRnKB (if you cannot open that link, rely on the spec below and the reference images).

## 0. Ground rules (read first)

1. Read `AGENTS.md` and follow it strictly (feature-oriented MVVM, Drift, Riverpod, money as integer cents, Material 3).
2. This is a **UI-only redesign**. Do NOT change business logic, repositories, database schema, backup format, or the auto-capture pipeline. Views and shared widgets change. A ViewModel may change only if a view needs a small piece of derived display state, and then only with a test.
3. Before writing any code, inspect the project and report: every screen and route, the current theme setup, existing shared widgets, hardcoded colors (`grep -rn "Color(0x" lib`), packages in use, and whether a theme-mode setting already exists. Produce a **screen inventory** (screen, file, exists yes/no) and an implementation plan. **Wait for my approval before coding.**
4. If a reference element needs data or logic that does not exist (for example "+25% vs last month"), either compute it from data the repositories already expose (only if trivial and unit-tested) or leave it out and list it in the plan. Never invent fake numbers in production UI.
5. Work in the phases in section 9. A phase is finished only when `flutter analyze` shows no new issues and `flutter test` is green. Existing tests must be updated, not deleted.

## 1. Design language (from the reference)

- Green identity. **Light:** soft gray page, white rounded cards, a lime-tinted hero header behind a stacked bar chart. **Dark:** charcoal page, darker cards, deep olive-green hero.
- Cards are large and rounded, separated by tone (not shadow). Hero header is flat color; the summary card overlaps it by 40dp.
- Circular gauges (a big "Remaining" donut and small per-category rings) are the signature element. Progress bars are rounded.
- Numbers are big and bold. Labels are small and quiet.
- Typography: **Plus Jakarta Sans** (500 / 600 / 700 / 800). The app is offline-first, so **bundle the font files** under `assets/fonts/` (include the OFL license), declare them in `pubspec.yaml`, and never fetch fonts at runtime.
- Money: format from integer cents with `intl` `NumberFormat.currency` using the app's existing currency setting (mockups show ₹ with Indian grouping only as placeholders). Use tabular figures (`FontFeature.tabularFigures()`) for amounts.

## 2. Theme tokens

Build `ColorScheme.fromSeed(seedColor: Color(0xFF5E9E0C))` for light and dark, then override the roles below. Semantic colors Material has no role for go in a `ThemeExtension<AppColors>`. These are the ONLY places hex values may appear.

| token | light | dark |
|---|---|---|
| background | `#F2F3EF` | `#2B2A28` |
| card / surface | `#FFFFFF` | `#1F1F1D` |
| onSurface | `#1A1F14` | `#F2F2EE` |
| onSurfaceVariant | `#4A5142` | `#B4B4AD` |
| outline | `#E6E7E2` | `#343432` |
| hero background | `#DDF7A6` | `#3B5F12` |
| onHero | `#1A1F14` | `#FFFFFF` |
| primary (buttons, active nav, links) | `#3F7A00` | `#BFF060` |
| onPrimary | `#FFFFFF` | `#1A2A06` |
| chart outer (income) | `#BFEF6B` | `#B8EA5C` |
| chart inner (expense) | `#5E9E0C` | `#6BAA14` |
| insight container | `#E8FAC0` | `#3B5F12` |
| income text | `#3F7A00` | `#BFF060` |
| expense text | `#C62341` | `#FF7A8A` |
| expense graphic | `#E5304F` | `#FF7A8A` |
| ring colors (both themes) | yellow `#F5C842`, red `#E5304F`, blue `#3B82F6`, gray `#7A7A74`, cyan `#22B8CF` | same |

- Radii: card 22, large card 28, pill/chip 24, input 16, bar 10. Spacing on a 4dp grid (4, 8, 12, 16, 20, 24).
- Theme mode: System by default, with a Light / Dark / System selector in Settings stored in `SharedPreferences` (reuse the existing setting if one exists).
- **Contrast rule:** every text-on-background pair must reach 4.5:1 (3:1 for graphics and 24px+ text). Add a unit test with a WCAG contrast helper that checks every text/background pair above in both themes. Never convey meaning by color alone (always pair with a label, sign, or percent).

## 3. Shared components

Put them in `lib/shared/widgets/` (design system). Each is documented with a short doc comment, themed only through tokens, and has light + dark widget tests.

- `AppCard`, `SectionHeader`, `MoneyText` (cents in, formatted out, positive/negative styling), `EmptyState`, `ErrorState`, `LoadingSkeleton`
- `HeroHeader` (title row, month selector, optional legend, content slot, bottom overlap support)
- `WeeklyBarChart` (stacked rounded bars: outer = income, inner = expense, day labels; built with `fl_chart`)
- `RingGauge` (CustomPainter: track + round-cap progress arc + center child; used for the large "Remaining" donut and the small category rings)
- `SummaryRow` (colored dot, label, amount, chevron, tappable)
- `InsightCard` (icon, title, one line, highlighted container)
- `CategoryProgressTile` (icon, name, rounded progress bar, "₹X left", "₹Y total", "+" button; over-budget state in red with a warning icon and "₹Z exceeded")
- `DetectedTransactionsBanner` ("N detected transactions, Review before adding"; shown only when auto-capture is enabled and pending > 0)
- `MonthPill` (month selector with calendar icon and chevron)
- `AppNavigationBar` (Material 3 `NavigationBar`, themed)

Chart/gauge widgets expose a `Semantics` label summarizing their values (for example "74 percent of budget remaining, 6,580 rupees").

## 4. Screens

Keep the existing routes, deep links, and data flow. Restyle or rebuild only the View layer.

1. **Home ("My Budget")**, mockups A (light) and C (dark): hero header with title, edit action, month, and Income/Expense legend; weekly stacked bar chart; summary card overlapping the hero with Income / Expense / Left for saving rows (tap = go to the filtered list); Insight card; detected-transactions banner; bottom navigation.
2. **Monthly Budget**, mockup B: month pill; large "Remaining" donut with an insights button (left) and an add-budget button (right); category rings grid (up to 5, percent in the center, label below); below it, category groups using `CategoryProgressTile`, including the over-budget state and "Add new category".
3. **Spending / transactions list:** search, filter chips (type, category, date range), grouped by day with day totals, rows with letter or icon avatar, title, category, and signed colored amount. Swipe to delete with Undo. Empty and loading states.
4. **Add / edit transaction:** large amount field, Expense/Income segmented button, category chips, date chip, note field, primary Save. Reuse the existing screen's logic; also used prefilled by auto-capture.
5. **Categories and budgets management:** list, add/edit dialog or sheet, budget amount input.
6. **Budget Insights** (only if the data exists, see rule 4): overview card, expense summary with change vs last month, spent vs earned comparison, category breakdown.
7. **Settings:** grouped list (Appearance, Data and storage, Auto-capture, About). Appearance holds the theme selector.
8. **Data and storage (backup)** and **Auto-capture (settings, inbox, parser playground):** restyle with the new tokens and components only. Behavior and copy stay exactly as built.

**Navigation:** Material 3 `NavigationBar` with four destinations (Home, Budget, Spending, Settings), mapped onto the existing router. Keep each tab's state when switching tabs. **Add transaction** is a Material 3 `FloatingActionButton` (primary container) on Home and Spending, above the bar. The mockups don't draw it, but it is required.

## 5. States, accessibility, motion

- Every screen has loading, empty, and error states built from the shared components.
- Edge-to-edge with correct status/navigation bar icon brightness in both themes. Respect safe areas.
- Text scale up to 200% without overflow. Touch targets at least 48dp. Semantic labels on icon-only buttons and charts. Directional paddings (`EdgeInsetsDirectional`).
- Motion is subtle: rings and bars animate in once on first load (about 500ms, `easeOutCubic`). Skip animations when `MediaQuery.disableAnimations` is true. No heavy or looping animation.
- Performance: `const` constructors, builder-based lists, `RepaintBoundary` around charts, no work in `build()`.

## 6. File layout

```
lib/core/theme/        app_theme.dart, app_colors.dart (ThemeExtension), app_text_theme.dart, app_spacing.dart, app_shapes.dart
lib/shared/widgets/    design-system components from section 3
lib/features/*/presentation/views|widgets/   restyled screens
assets/fonts/          Plus Jakarta Sans files + OFL license
```

Do not add UI logic to ViewModels. Do not let features import each other's internals.

## 7. Packages

- Allowed: `fl_chart` (charts), `intl` (money/date formatting), `shared_preferences` (theme mode), plus anything already in the project.
- Do NOT add `google_fonts` for runtime fetching (fonts are bundled). Ask me before adding any other package.

## 8. Hard rules

- No behavior, schema, or backup-format changes. No new permissions.
- No `Color(0x...)` literals, raw font sizes, or magic spacing numbers in `lib/features` (everything comes from tokens and the theme). `grep -rn "Color(0x" lib/features` must return nothing when finished.
- Light and dark must both look correct on every screen. Check each one.
- No new analyzer warnings and no `// ignore` shortcuts without a written reason.

## 9. Phases

1. **Theme foundation:** bundled fonts, tokens, `AppColors` extension, text theme, light/dark `ThemeData`, theme-mode setting, contrast unit test. Swap the app theme and fix anything that breaks. No screen redesign yet.
2. **Shared components** with light + dark widget tests (including a 200% text-scale test per component that asserts no overflow).
3. **Core screens:** navigation bar + FAB, Home, Monthly Budget, Spending, Add/Edit transaction.
4. **Secondary screens:** categories and budgets management, Insights (if data exists), Settings.
5. **Backup and Auto-capture screens** restyled.
6. **Polish:** animations, accessibility pass, empty/loading/error states, remove leftover hardcoded styles and dead theme code, final grep for `Color(0x`.

At the end of each phase give me a short summary: what changed, test results, and anything you deviated on or skipped.

## 10. Tests (mandatory)

- Contrast unit test for every token pair in both themes (section 2).
- Widget tests per shared component in light and dark; text-scale 2.0 test asserting `tester.takeException()` is null.
- Money formatting: cents to display string, including negatives and Indian grouping, with no `double` math.
- Existing ViewModel and repository tests stay green and unchanged in behavior.
- Screen smoke tests: each main screen renders in light, dark, loading, empty, and error states.
- Use golden tests only if the project already has them.
- Commands that must pass at the end: `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, `flutter test`.
- Manual QA on a real device or emulator: switch light/dark/system live, set system font size to the maximum, rotate the device, open every screen from a cold start.

## 11. Housekeeping when finished

Append these rules to `AGENTS.md`:
- "All colors, text styles, radii, and spacing come from `lib/core/theme` tokens. No `Color(0x...)` or hardcoded sizes in features."
- "New reusable UI goes in `lib/shared/widgets` with light and dark widget tests. The contrast test must keep passing when tokens change."
