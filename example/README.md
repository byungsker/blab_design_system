# BLab Storybook

An example Flutter app that showcases the tokens and widgets of the `blab_design_system` package. Treat it as a living storybook and a smoke test for anything you add to the package.

## Run

```bash
cd example
flutter pub get
flutter run
```

## Navigation

The home screen groups stories by category:

- **Foundations** — Tokens (color, typography, spacing, radius, shadow)
- **Inputs** — Button, TextField, SegmentedControl
- **Surfaces** — Card
- **Feedback** — Snackbar

Use the icon in the top-right app bar to toggle **light / dark** mode.

## Add a story

1. Create a new widget in `lib/stories/your_story.dart` following the pattern of `button_story.dart`.
2. Import it in `lib/stories_home.dart` and append a `_Story(...)` entry with the right `category`.

## Extending

This storybook intentionally has zero non-Flutter dependencies. If it grows large enough to need knobs, devices, or theme addons, consider migrating to [widgetbook](https://widgetbook.io) at that point.
