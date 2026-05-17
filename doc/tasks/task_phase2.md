# Phase 2 — Splash & Onboarding

## Tasks

### Task 2.1: SplashScreen
- Display a splash image/logo for 2 seconds
- After 2s, check if user exists (via StorageService)
- Navigate to OnboardingScreen if no user, AppShell if user exists
- Remove duplicate user check from AppEntryPoint

### Task 2.2: OnboardingScreen
- Polished UI with welcome message and name input
- Save name to DB + shared_preferences on submit
- Navigate to AppShell after successful submission

### Task 2.3: Wire Navigation
- App → SplashScreen → (check) → OnboardingScreen or AppShell
- AppEntryPoint should just be a StatelessWidget that returns AppShell (no user check)

## Completion Criteria

1. SplashScreen shows for 2 seconds with visual branding
2. First-time users see OnboardingScreen after splash
3. Returning users go directly to AppShell after splash
4. Onboarding saves name to both DB and shared_preferences
5. No user check logic in AppEntryPoint
6. `dart analyze` passes with no errors
