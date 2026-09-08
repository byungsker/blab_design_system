# BLab Design System

A cross-platform UI component library for Byungsker's personal products, with
Flutter as the semantic reference and a typed React/Next.js web package.

BLab started as the shared mobile UI foundation for **BookGolas** and was later separated into a reusable package so the same visual language, tokens, and component rules could be applied to **Baroguni** and future BLab apps.

The goal is not to be a full public design system yet. It is a small, product-driven component foundation that keeps repeated mobile UI decisions consistent across personal apps and agent-assisted development workflows.

The React package extends the same token hierarchy and component contracts to
web surfaces without importing product routes, data, authentication or copy.

## What this package contains

### Design tokens and themes

- `BLabColors` — primary, semantic, chart, light/dark surface, and text colors
- `BLabTypography` — shared text styles
- `BLabTheme.light` / `BLabTheme.dark` — Material 3 theme presets built around the BLab color system

### Components

- `BLabButton` — primary, secondary, and destructive button variants with haptic feedback
- `BLabCard` — liquid-glass style card container with optional press interactions
- `BLabTextField` — liquid-glass text field with label, hint, clear affordance, read-only, and multiline support
- `BLabSnackbar` — overlay snackbar for success, error, info, and warning states, including keyboard-aware positioning
- `BLabPressableWrapper` — reusable press animation wrapper
- `BLabBottomBar` — bottom navigation component in the same visual language

### React and Next.js package

The typed Web implementation lives in [`packages/react`](packages/react) and
maps the Flutter exports to React components, CSS tokens and browser-native
accessibility behavior. It includes the parity fixture used for Chromium QA.

## Why it exists

BookGolas and Baroguni share similar mobile-product needs:

- consistent color, typography, button, card, input, and snackbar treatment
- light/dark mode support
- reusable liquid-glass interaction patterns
- fewer one-off Material widget decisions inside app screens
- clearer rules for AI coding agents and human contributors when building UI

Instead of copying UI code from one app to another, this package extracts the reusable foundation into a package and lets consuming apps define strict usage rules.

## Installation

Add the package from Git:

```yaml
dependencies:
  blab_design_system:
    git:
      url: https://github.com/byungsker/blab_design_system.git
      ref: main
```

Then import it:

```dart
import 'package:blab_design_system/blab_design_system.dart';
```

For React and Next.js consumers, use the package-local release line:

```bash
npm install ./packages/react
```

Then import the public Web surface and CSS entry point:

```tsx
import { BLabButton } from "@byungsker/blab-design-system";
import "@byungsker/blab-design-system/styles.css";
```

## Basic usage

### Apply the theme

```dart
import 'package:flutter/material.dart';
import 'package:blab_design_system/blab_design_system.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: BLabTheme.light,
      darkTheme: BLabTheme.dark,
      home: const HomeScreen(),
    );
  }
}
```

### Use BLab components

```dart
BLabCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Reading Goal',
        style: BLabTypography.titleLarge,
      ),
      const SizedBox(height: 12),
      BLabButton(
        text: 'Start reading',
        icon: Icons.play_arrow_rounded,
        onPressed: () {},
      ),
    ],
  ),
)
```

### Show a snackbar

```dart
BLabSnackbar.show(
  context,
  message: 'Saved successfully',
  type: BLabSnackbarType.success,
);
```

For screens with a fixed bottom CTA or visible keyboard, use explicit positioning:

```dart
BLabSnackbar.show(
  context,
  message: 'Please check the required fields',
  type: BLabSnackbarType.error,
  bottomOffset: 100,
);

BLabSnackbar.show(
  context,
  message: 'Copied',
  type: BLabSnackbarType.info,
  aboveKeyboard: true,
);
```

## Usage rules for consuming apps

For consistent UI results, consuming apps should document package usage in their project-level agent or contributor instructions. See [`docs/consuming-app-guide.md`](docs/consuming-app-guide.md) for a copyable app-level guide.

Example rules used in Baroguni:

```md
## BLab Design System Usage

- Use BLab components for Material 3 UI where possible.
- Colors: use `BLabColors.*` instead of app-local color constants.
- Theme: use `BLabTheme.light` / `BLabTheme.dark` instead of custom app themes.
- Typography: use `BLabTypography.*` instead of one-off text styles.
- Buttons: use `BLabButton` instead of `ElevatedButton` / `TextButton`.
- Cards: use `BLabCard` instead of raw `Card`.
- Inputs: use `BLabTextField` instead of raw `TextField` for common form fields.
- Snackbars: use `BLabSnackbar.show()` instead of `ScaffoldMessenger.showSnackBar()`.
```

These rules are intentionally written for both humans and AI coding agents. They make the package more useful in agent-assisted development because the expected component choices and prohibited fallbacks are explicit.

## Adding a new component

When a consuming app needs a new repeated UI pattern:

1. Check whether it is a one-off app screen detail or a reusable BLab pattern.
2. If reusable, add it to this package first.
3. Export it from `lib/blab_design_system.dart`.
4. Use it from the product app through the package import.
5. Update the consuming app's usage rules if the component should become mandatory.

This keeps the design system from becoming a dumping ground while still allowing product needs to drive the component library.

## Current status

This package is an early personal design-system foundation.

- Flutter package: `0.0.1`
- React/Next.js package target: `0.2.0`
- Primary platforms: Flutter mobile and typed React/Next.js Web
- First consumers: BookGolas and Baroguni
- Scope: shared tokens, component consistency, cross-platform parity, and agent-friendly usage rules

The Flutter package is not yet published to pub.dev. The React package is
prepared for its versioned package PR and registry release; use the repository
package path until that release is published.

## Public-facing note

This repository intentionally focuses on package code and usage rules. Product-specific implementation details live in the consuming apps. When linking this repository from a resume or portfolio, the key signal is the extraction of repeated UI foundations into a reusable Flutter package and the explicit rules that help future products and AI-assisted workflows use the same components consistently.
