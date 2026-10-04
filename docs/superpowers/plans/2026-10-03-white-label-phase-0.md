# EventScan White Label Phase 0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the `default` brand configuration and Android flavor, load the configuration safely at startup, and keep the existing check-in UI and Supabase behavior unchanged.

**Architecture:** Store the current brand's identity, theme, and attendee/staff schema in three JSON assets. Parse them into immutable config objects through `BrandLoader`, expose the loaded config through `BrandScope`, and select the Gradle product flavor from the discovered brand folders. This phase does not apply theme tokens to widgets or change data access; it establishes the configuration boundary for later phases.

**Tech Stack:** Flutter 3.38+, Dart ^3.11, Android Gradle Kotlin DSL, Flutter asset bundles, `flutter_test`.

**Spec:** `docs/specs/white-label.md`, especially §§6.1-6.3, 7, 9 Phase 0, and VAL-3.

## Global Constraints

- Target Android only; backend remains Supabase (PostgREST).
- Keep the two required modules: Asistentes and Staff.
- Preserve current UID normalization, validation, check-in confirmation, and PDF behavior.
- Phase 0 must retain current Supabase `--dart-define` keys and defaults.
- Never place Supabase secrets in `brand.json` or any versioned brand config.
- Keep the existing default application ID (`com.example.event_scan`) for this phase.
- New configuration errors must be shown as a readable startup screen rather than an uncaught exception.
- Do not apply theme tokens, rename domain/data types, change localization, or alter PDF/data behavior in this phase.

## Review Focus

- Missing, malformed, or structurally incomplete JSON must produce a brand-specific readable error; cover with parser and loader tests.
- A missing flavor value must resolve deterministically to `default`; cover the flavor-selection helper.
- A requested brand whose assets are not bundled must reach the config error UI rather than crash; cover loader failure mapping.
- Invalid/duplicate flavor IDs or application IDs must fail Gradle configuration with a useful message; cover the Gradle brand-discovery validation and run the Android flavor build.
- Missing Supabase defines must continue to show the existing setup screen, while configured launch profiles retain their current defines; cover the existing widget test and inspect both VS Code launch profiles.

---

### Task 1: Add the Default Brand Assets

**Files:**
- Create: `brands/default/brand.json`
- Create: `brands/default/theme.json`
- Create: `brands/default/entities.json`
- Create: `brands/default/assets/logo.svg`
- Modify: `pubspec.yaml`

**Interfaces:**
- Produces the three JSON assets at `brands/default/{brand,theme,entities}.json`.
- Flutter bundles the assets only for the `default` flavor.
- Values must mirror the current app and the examples in `docs/specs/white-label.md` §7; no secrets are included.

- [ ] Copy the current brand identity into `brand.json`: `id` is `default`, `appName` is `Event Scan`, `android.applicationId` remains `com.example.event_scan`, `locale` is `es`, and `logo.primary` points to `assets/logo.svg`. Add a simple, self-contained SVG mark so the required logo asset exists; it is not rendered by the UI in Phase 0.
- [ ] Populate `theme.json` with the current light palette and typography values from `lib/core/theme/app_colors.dart` and `lib/core/theme/app_theme.dart`; include the token sections and component/layout values from §7.2, without changing which theme the app currently renders.
- [ ] Populate `entities.json` with the current `registered` and `staff` tables, identifier columns, check-in columns, display labels, payment-pending rules, and PDF exclusions from §7.3 and `lib/core/network/api_config.dart`/`lib/main.dart`.
- [ ] Add a flavor-filtered asset entry for `brands/default/` under `flutter.assets` in `pubspec.yaml`.
- [ ] Run `flutter pub get` only if the Flutter tool requires lockfile metadata to reflect the asset configuration; do not add a runtime JSON-schema dependency in this phase.

**Validation:** `flutter pub get` (if required) and `flutter test test/widget_test.dart`.

### Task 2: Parse and Load Immutable Brand Configuration

**Files:**
- Create: `lib/core/brand/brand_config.dart`
- Create: `lib/core/brand/brand_loader.dart`
- Create: `test/core/brand/brand_config_test.dart`
- Create: `test/core/brand/brand_loader_test.dart`

**Interfaces:**
- `BrandConfig` contains immutable `BrandIdentity`, theme JSON, and entity JSON values.
- `BrandConfig.fromJson({required String brandId, required Map<String, dynamic> brand, required Map<String, dynamic> theme, required Map<String, dynamic> entities})` validates required Phase 0 fields and `brand.id == brandId`.
- `BrandLoader.load({required String brandId, AssetBundle? bundle})` asynchronously reads the three `brands/<brandId>/...json` assets and returns `Future<BrandConfig>`.
- `BrandConfigException` carries a user-readable message and the config/asset path that failed.

- [ ] Write parser tests for a valid brand, missing required identity/application ID/locale fields, wrong JSON value types, a malformed theme root, malformed entities root, and a `brand.id` that differs from the requested folder ID.
- [ ] Run `flutter test test/core/brand/brand_config_test.dart` and verify the new parser tests fail before implementation.
- [ ] Implement typed immutable identity fields and defensive unmodifiable copies for the theme and entity JSON trees. Keep detailed theme/entity semantics for their owning later phases; phase 0 validates that each file is a JSON object and that required top-level module/config sections exist.
- [ ] Write loader tests with an in-memory `AssetBundle` for successful three-file loading, a missing asset, invalid JSON, and forwarding of the requested `brandId`.
- [ ] Run `flutter test test/core/brand/brand_loader_test.dart` and verify those tests fail before implementation.
- [ ] Implement `BrandLoader` with `rootBundle` as the production default and convert asset/JSON failures into `BrandConfigException` messages naming the brand and file.
- [ ] Run `flutter test test/core/brand/` and `flutter analyze lib/core/brand`.

### Task 3: Expose Brand Config and Integrate Startup

**Files:**
- Create: `lib/core/brand/brand_scope.dart`
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart` only if the constructor injection needs an explicit brand-config fixture.
- Create: `test/core/brand/brand_scope_test.dart` if direct inherited-scope behavior is not already covered by startup widget tests.

**Interfaces:**
- `BrandScope({required BrandConfig config, required Widget child})` exposes `BrandConfig` through `BrandScope.of(context)` and `BrandScope.maybeOf(context)`.
- `main()` initializes Flutter bindings, selects `appFlavor ?? 'default'`, loads that brand before constructing the existing app, and wraps the configured app in `BrandScope`.
- A `ConfigErrorApp` displays the readable `BrandConfigException` message when brand loading fails; the existing `MissingConfigApp` remains responsible for invalid Supabase settings.
- `EventScanApp` remains directly constructible in widget tests and retains current title, theme, home page, repositories, and exports.

- [ ] Add tests that `BrandScope.of` returns the exact immutable config and that `maybeOf` returns `null` outside a scope.
- [ ] Add a startup-selection unit test for an explicit flavor and a `null` flavor resolving to `default`.
- [ ] Integrate asynchronous brand loading at startup without changing `ApiConfig.fromEnvironment`, existing `EventScanApp` constructor requirements, or current check-in wiring.
- [ ] Render `ConfigErrorApp` for only brand-load/config failures; preserve `MissingConfigApp` for missing Supabase values.
- [ ] Run `flutter test test/core/brand/ test/widget_test.dart` and `flutter analyze lib/main.dart lib/core/brand`.

### Task 4: Register Android Flavors and Preserve VS Code Launch

**Files:**
- Modify: `android/app/build.gradle.kts`
- Modify: `.vscode/launch.json`
- Modify: `.vscode/settings.json`
- Modify: `android/app/src/main/AndroidManifest.xml` only if Gradle requires the generated `app_name` resource for flavor configuration.

**Interfaces:**
- Gradle discovers `brands/*/brand.json`, validates that brand IDs are valid flavor names and application IDs are unique, and registers one `brand` dimension flavor per config.
- The `default` flavor keeps `com.example.event_scan`; launcher label remains unchanged in Phase 0 unless changing it is necessary for Gradle resource resolution.
- VS Code launch/run profiles add `--flavor=default` while preserving every current Supabase define.

- [ ] Add a Gradle configuration helper that reads brand ID and Android application ID from each `brand.json`, rejects missing/duplicate IDs with actionable errors, and registers the discovered product flavors under a `brand` dimension.
- [ ] Keep the current default application ID and release/debug signing behavior unchanged.
- [ ] Add `--flavor=default` to the existing VS Code launch configuration and global Flutter run arguments; do not remove or rewrite Supabase defines.
- [ ] Run `flutter test test/core/brand/ test/widget_test.dart` and `flutter analyze`.
- [ ] Run `flutter build apk --debug --flavor default` to verify Gradle flavor registration and flavor-filtered JSON asset bundling.
- [ ] Run `flutter build apk --debug --flavor default --dart-define=SUPABASE_URL=https://example.supabase.co --dart-define=SUPABASE_ANON_KEY=example-key` only if a debug build is needed to verify the retained defines are accepted; the flavor build itself must not require live Supabase credentials.

## Phase 0 Acceptance Check

- [ ] `flutter build apk --debug --flavor default` succeeds.
- [ ] Startup loads `brands/default/brand.json`, `theme.json`, and `entities.json` and exposes the result in `BrandScope`.
- [ ] Bad/missing brand config displays a readable config error; bad/missing Supabase config still displays the existing Supabase setup screen.
- [ ] Existing widget, domain, BLoC, data-source, and PDF tests pass unchanged.
- [ ] No existing check-in, theme, data-model, localization, or PDF behavior is changed in this phase.

## Scope Notes

Phase 0 intentionally does not implement the rest of the white-label spec. Design-token application, dark mode, logos in the UI/launcher/PDF, ARB localization, dynamic registrants/rules, configurable PDF columns, JSON Schema tooling, local secret files, and CI validation remain separate later-phase deliverables. Before those phases, revise this plan into phase-specific plans so each subsystem has its own working validation point.