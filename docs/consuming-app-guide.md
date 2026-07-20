# Consuming App Guide for BLab Design System

Use this guide when a Flutter product app imports `blab_design_system`.

This document is meant to be copied into, summarized by, or referenced from the consuming app's own `AGENTS.md`, `CLAUDE.md`, or contributor guide. A consuming app's agent will not reliably read `blab_design_system/AGENTS.md` automatically, so the rules that affect app work must live in the app repository too.

## Purpose

`blab_design_system` is the default UI foundation for BLab mobile products. It exists to reduce repeated UI decisions and keep human-written and AI-assisted UI implementation consistent across apps.

Use it for:

- color and surface decisions
- typography choices
- buttons and press interactions
- reusable card surfaces
- common form fields
- snackbar/toast feedback
- bottom navigation patterns

Do not use it for:

- app-specific business logic
- feature-specific data models
- route definitions
- product copy that belongs to a screen
- one-off layouts that are not reusable

## Recommended consuming app instructions

Add a section like this to the consuming app's `AGENTS.md`.

```md
## BLab Design System

This app uses `blab_design_system` as its default UI foundation.

When building or modifying UI:

- MUST import `package:blab_design_system/blab_design_system.dart` for shared UI tokens and components.
- MUST use `BLabColors.*` instead of hard-coded colors or app-local color constants.
- MUST use `BLabTypography.*` instead of one-off `TextStyle` definitions for common text styles.
- MUST use `BLabTheme.light` / `BLabTheme.dark` instead of custom app themes unless the task is specifically about app-level theme integration.
- MUST use `BLabButton` instead of raw `ElevatedButton`, `TextButton`, or `OutlinedButton` for common actions.
- MUST use `BLabCard` instead of raw `Card` for reusable card surfaces.
- MUST use `BLabTextField` instead of raw `TextField` for common form fields.
- MUST use `BLabSnackbar.show()` instead of `ScaffoldMessenger.showSnackBar()` for app feedback.
- MUST use existing BLab components before creating app-local UI primitives.
- MUST NOT bypass BLab tokens with arbitrary hard-coded color, spacing, or text-style decisions unless the exception is explained in code or task notes.

If a repeated UI pattern appears in two or more screens, consider extracting it into `blab_design_system` instead of duplicating it inside this app.
```

## Decision table

| UI need | Prefer | Avoid by default |
| --- | --- | --- |
| App theme | `BLabTheme.light`, `BLabTheme.dark` | fully custom `ThemeData` with unrelated colors |
| Colors | `BLabColors.*` | hard-coded `Color(0x...)` for reusable UI |
| Typography | `BLabTypography.*` | one-off `TextStyle(...)` for common roles |
| Primary/secondary/destructive actions | `BLabButton` | raw `ElevatedButton`, `TextButton`, `OutlinedButton` |
| Reusable card surface | `BLabCard` | raw `Card`, one-off `Container` decoration |
| Common input | `BLabTextField` | raw `TextField` |
| Feedback message | `BLabSnackbar.show()` | `ScaffoldMessenger.showSnackBar()` |
| Press animation | `BLabPressableWrapper` | repeated local gesture/scale animation code |
| Bottom navigation | `BLabBottomBar` | unrelated app-local bottom bar styling |

## Working on screens

When an agent modifies or builds a screen in a consuming app:

1. Search for existing BLab imports or usage in nearby screens.
2. Import `package:blab_design_system/blab_design_system.dart` if shared UI tokens or components are needed.
3. Use BLab components first for common UI primitives.
4. Keep screen-specific layout and feature logic inside the app.
5. Avoid adding new app-local primitives if the pattern belongs in the design system.
6. If the screen needs a reusable pattern that BLab does not have yet, note it as a candidate for `blab_design_system` extraction.

## When to modify BLab itself

Modify the `blab_design_system` package when:

- the same visual pattern appears in multiple screens or apps
- a raw Material widget is repeatedly wrapped to look like BLab
- a token or component API is missing for a common design decision
- app-level agent instructions keep needing the same exception

Do not modify BLab itself when:

- the UI is feature-specific and unlikely to repeat
- the change depends on product data or routes
- the design is an experiment limited to one screen

## Verification in consuming apps

After UI changes in a consuming app, run the app's normal verification commands. For Flutter apps, prefer:

```bash
flutter analyze
flutter test
```

If the consuming app has custom checks, run those too.

## Verification in BLab package

After changing `blab_design_system`, run:

```bash
flutter analyze
flutter test
```

Also check that the changed public API is exported from:

```txt
lib/blab_design_system.dart
```
