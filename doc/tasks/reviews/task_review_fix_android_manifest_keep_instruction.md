task: fix_android_manifest_keep_instruction
reviewer: reviewer
date: 2026-05-17
status: approved
findings: []
summary: |
  The prior stale comment in `notification_service.dart` has been corrected. The manifest no longer contains unsupported `tools:keep` syntax, the `ic_stat_birdle` drawable remains present and aligned with the app's current notification icon constant, and the task now satisfies all completion criteria.
completion_criteria_check:
  - [x] `flutter run` no longer fails during `:app:processDebugMainManifest` with the invalid `keep` instruction error.
  - [x] `android/app/src/main/AndroidManifest.xml` no longer uses unsupported manifest-merger syntax for `tools:keep`; if icon retention is still needed, it is handled with a supported Android resource mechanism outside the manifest.
  - [x] The Android notification small icon `ic_stat_birdle` remains available to the app's current notification setup after the manifest fix, without changing unrelated alarm/notification logic.
  - [x] Any stale inline documentation or comments that claim the icon is kept via `AndroidManifest` are updated to match the final Android-only fix.
  - [x] The implementation stays limited to the planned Android files and `flutter run` reaches the app launch stage past manifest processing.
