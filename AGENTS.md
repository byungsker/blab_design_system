# BLab Design System Agent Instructions

These instructions apply when an AI coding agent or human contributor works inside the `blab_design_system` repository.

This repository owns the shared Flutter UI foundation used by BLab mobile products such as BookGolas and Baroguni. Keep the package small, product-driven, and safe for consuming apps.

## Repository purpose

BLab Design System is a reusable Flutter package for shared mobile UI foundations:

- design tokens: `BLabColors`, `BLabTypography`
- themes: `BLabTheme.light`, `BLabTheme.dark`
- components: `BLabButton`, `BLabCard`, `BLabTextField`, `BLabSnackbar`, `BLabBottomBar`, `BLabPressableWrapper`

The goal is not to create a generic public design system for every Flutter app. The goal is to extract repeated UI decisions from BLab products into stable package APIs that consuming apps and agent-assisted workflows can use consistently.

## Core rules

- MUST keep public APIs stable for consuming apps unless the task explicitly asks for a breaking change.
- MUST export new public tokens, themes, and components from `lib/blab_design_system.dart`.
- MUST preserve light and dark mode compatibility when changing visual components.
- MUST prefer product-driven components over generic abstractions. Add a component when it is repeated or likely to be reused by consuming apps.
- MUST update `README.md` when adding or changing public usage patterns.
- MUST update `docs/consuming-app-guide.md` when a change affects how product apps should use BLab.
- MUST NOT add app-specific business logic to this package.
- MUST NOT hard-code product-specific copy, routes, database models, or feature flows in reusable components.
- MUST NOT introduce raw one-off visual styles that bypass existing BLab tokens without explaining why.

## When adding a new component

1. Confirm the pattern is reusable across screens or apps, not a one-off screen detail.
2. Add the component under `lib/src/widgets/` or the appropriate `lib/src/` subdirectory.
3. Use existing tokens such as `BLabColors`, `BLabTypography`, and `BLabTheme` where practical.
4. Support light/dark mode if the component renders surfaces, borders, shadows, or text.
5. Export the component from `lib/blab_design_system.dart`.
6. Add a short usage example or component mention to `README.md`.
7. If consuming apps should prefer this component over a raw Material widget, update `docs/consuming-app-guide.md`.
8. Run verification before finishing.

## When changing an existing component

1. Check whether the change affects existing consuming apps.
2. Preserve constructor names and parameter behavior when possible.
3. If a breaking API change is necessary, document the migration path in the commit or PR summary.
4. Keep haptics, animation behavior, keyboard handling, and accessibility behavior intentional.
5. Run verification before finishing.

## Public API checklist

Before finishing, check:

- [ ] New public APIs are exported from `lib/blab_design_system.dart`.
- [ ] README examples still compile conceptually with the exported names.
- [ ] Consuming-app guidance is updated if usage rules changed.
- [ ] No product-specific business logic was added to the package.
- [ ] Light/dark behavior remains consistent.

## Verification

Run these commands before considering a code or public-documentation change complete:

```bash
flutter analyze
flutter test
```

If the change is documentation-only, still run at least `flutter analyze` when practical, because README/API changes often expose export or naming mismatches.

## Consuming app guidance

Other projects do not automatically inherit this repository's `AGENTS.md` just because they import this package. Product apps that use BLab should carry their own project-level agent instructions and can copy or reference the rules in:

```txt
docs/consuming-app-guide.md
```

Use that guide when updating BookGolas, Baroguni, or future BLab app repositories.
