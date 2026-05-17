# AGENTS.md — Birdle Project

## Project Overview

**Birdle** is a Flutter todo app with SQL persistence, color palettes, item alarms, and a pomodoro timer that survives device reboots.

- **SDK**: Dart ^3.11.5
- **Architecture**: MVVM + Repository pattern
- **State Management**: Provider
- **Database**: Drift (SQLite)
- **Key packages**: `sqflite`, `drift`, `flutter_local_notifications`, `android_alarm_manager_plus`, `workmanager`, `flutter_foreground_task`, `shared_preferences`, `uuid`, `intl`

---

## Agent Strategy

This project uses a **leader → specbuilder → human confirmation → leader → (builder → reviewer loop)** orchestration loop.

### Agents (`.opencode/agents/`)

| Agent | Mode | Role |
|---|---|---|
| `leader` | primary | Orchestrates the loop, requests human confirmation after planning, delegates work, tracks progress in `doc/history.md` |
| `specbuilder` | subagent | Creates the action plan for the task and can only write inside `doc/` |
| `builder` | subagent | Implements code — can write anywhere **except** `doc/plan.md`, `doc/architecture.md`, `doc/history.md` |
| `reviewer` | subagent | Reviews work against task completion criteria — can **only** write to `doc/tasks/reviews/` |

### Leader Rules

- Only writes inside `doc/history.md`, `doc/architecture.md`, `doc/plan.md`
- Only has `edit` and `bash` tools with basic permissions
- One phase at a time
- Always Delegates planning, investigation and implementation to `specbuilder`
- Requests explicit human confirmation before implementation begins
- Maximum 3 builder-reviewer iterations per task
- Tracks progress in `doc/history.md`
- Never review code made by the `builder`

### Specbuilder Rules

- Only writes inside `doc/`
- Investigate the requirements for the implementation
- Investigates bug fixes
- Creates the action plan for the requested task
- Defines tasks in `doc/tasks/task_<name>.md` with `completion_criteria` based on the approved plan
- Returns a proposed task spec for leader review and human confirmation
- Does not implement application code

### Agent Loop

```
Leader → specbuilder (create action plan for the task)
specbuilder → Leader (returns proposed plan / task spec)
Leader → Human (request confirmation to proceed)
Human → Leader (approve or request plan changes)
Leader → builder (start builder-reviewer loop using approved task from doc/tasks/task_<name>.md)
builder → Leader (signals completion, runs dart analyze)
Leader → reviewer (review against completion_criteria)
reviewer → Leader (findings in doc/tasks/reviews/task_review_<name>.md)
Leader → builder (fix observations)          [max 3 iterations]
...
Leader → doc/history.md (mark phase complete)
```

---

## Doc Structure

```
doc/
├── plan.md              # Development plan with phases and steps
├── architecture.md      # MVVM+Repository architecture, data models, DI
├── history.md           # Phase completion log (leader writes here)
└── tasks/
    ├── task_<name>.md   # Task definitions with completion_criteria
    └── reviews/
        └── task_review_<name>.md  # Reviewer findings
```

---

## Available Skills (`.agents/skills/`)

### Flutter Skills

| Skill | Purpose |
|---|---|
| `flutter-add-widget-test` | Generate widget tests |
| `flutter-add-integration-test` | Generate integration tests |
| `flutter-apply-architecture-best-practices` | Enforce Flutter architecture patterns |
| `flutter-fix-layout-issues` | Fix layout problems |
| `flutter-build-responsive-layout` | Build responsive layouts |
| `flutter-add-widget-preview` | Add widget previews |
| `flutter-setup-declarative-routing` | Set up declarative routing |
| `flutter-setup-localization` | Set up app localization |
| `flutter-use-http-package` | Use HTTP package |
| `flutter-implement-json-serialization` | Implement JSON serialization |

### Dart Skills

| Skill | Purpose |
|---|---|
| `dart-add-unit-test` | Generate unit tests |
| `dart-run-static-analysis` | Run static analysis |
| `dart-fix-runtime-errors` | Fix runtime errors |
| `dart-resolve-package-conflicts` | Resolve package conflicts |
| `dart-use-pattern-matching` | Use Dart pattern matching |

---

## Key Architecture Files

- `lib/main.dart` — Entry point
- `lib/app.dart` — MaterialApp + route config
- `lib/di/di_container.dart` — Provider dependency injection
- `lib/core/themes/palettes.dart` — 7 color palette definitions
- `lib/data/services/` — Database, storage, alarm, notification, foreground task services
- `lib/data/repositories/` — User, List, Item, Pomodoro repositories
- `lib/ui/screens/` — MVVM screen implementations
- `lib/ui/widgets/` — Reusable widgets
