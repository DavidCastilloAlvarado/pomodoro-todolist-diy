name: fix_android_manifest_keep_instruction
phase: 4
description: |
  Fix the Android debug build failure at `:app:processDebugMainManifest` caused by
  Birdle's main manifest declaring `tools:keep` on `<application>`.

  **Suspected root cause:** `tools:keep` is not a valid Android manifest-merger
  instruction. The manifest merger only accepts instructions such as
  `REMOVE`, `REPLACE`, `STRICT`, and `IGNORE_WARNING`, so placing
  `tools:keep="@drawable/ic_stat_birdle"` in `AndroidManifest.xml` causes
  manifest processing to fail before the app can launch. If the notification icon
  still needs explicit resource-retention handling, that must use a supported
  Android resource-keep mechanism outside the manifest.

  **Scope guardrails:**
  - Limit the fix to the Android manifest/resource wiring for `ic_stat_birdle`.
  - Do not change alarm scheduling, notification-channel behavior, or other Dart
    application logic.
  - Preserve the existing notification small-icon resource name unless a minimal
    Android-only adjustment is required.
files:
  - android/app/src/main/AndroidManifest.xml
  - android/app/src/main/res/drawable/ic_stat_birdle.xml
completion_criteria:
  - [ ] `flutter run` no longer fails during `:app:processDebugMainManifest` with the invalid `keep` instruction error.
  - [ ] `android/app/src/main/AndroidManifest.xml` no longer uses unsupported manifest-merger syntax for `tools:keep`; if icon retention is still needed, it is handled with a supported Android resource mechanism outside the manifest.
  - [ ] The Android notification small icon `ic_stat_birdle` remains available to the app's current notification setup after the manifest fix, without changing unrelated alarm/notification logic.
  - [ ] Any stale inline documentation or comments that claim the icon is kept via `AndroidManifest` are updated to match the final Android-only fix.
  - [ ] The implementation stays limited to the planned Android files and `flutter run` reaches the app launch stage past manifest processing.
status: pending
