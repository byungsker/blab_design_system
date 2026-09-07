# React and Next.js Contract

The React package at `packages/react` is a typed Web mapping of the Flutter
public BLab package. Flutter remains the semantic reference implementation.

## Cross-platform mapping

| Concern | Flutter | React/Next.js |
| --- | --- | --- |
| Primary color | `BLabColors.primary` | `BLabColors.primary` and `--blab-color-primary` |
| Type scale | `BLabTypography.*` | `BLabTypography.*` |
| Primary action | `BLabButton(variant: primary)` | `BLabButton variant="primary"` |
| Glass surface | `BLabCard` | `BLabCard` with `backdrop-filter` fallback |
| Form control | `BLabTextField` | Controlled `BLabTextField` |
| Feedback | `BLabSnackbar.show` | `BLabSnackbar` live-region component |
| Press feedback | `BLabPressableWrapper` | `BLabPressableWrapper` pointer and keyboard events |
| Navigation | `BLabBottomBar` | `BLabBottomBar` with `aria-current` |
| Tabs | `BLabTabBar` | `BLabTabBar` with `role="tablist"` |
| Segments | `BLabSegmentedControl<T>` | `BLabSegmentedControl<T>` with `aria-pressed` |
| Keyboard accessory | `BLabKeyboardAccessoryBar` | Capability flags and repeatable undo/redo actions |

## State matrix

| Component | Variants | Required states | Accessibility evidence |
| --- | --- | --- | --- |
| Button | primary, secondary, destructive | default, hover, pressed, focus, disabled, loading | Native button, name, `aria-busy`, visible focus |
| Card | static, interactive | default, pressed, focus, disabled | Interactive role only when actionable |
| Text field | single, multiline, obscured, read-only | empty, filled, focused, disabled, error | Explicit label, described error, native control |
| Snackbar | success, error, info, warning | visible, dismissible | `status` or `alert` live region |
| Bottom bar | selected, unselected, action | default, focus, selected | Navigation name and current item |
| Tab bar | distributed, scrollable | selected, unselected, focus | `tablist`, `tab`, arrow keys |
| Segmented control | generic values | selected, unselected, focus | Group label and `aria-pressed` |
| Keyboard accessory | navigation, clipboard, editing | enabled, disabled, focus, repeat | Native buttons with consumer labels |
| Feedback states | loading, empty, error/retry | visible, action, reduced motion | Consumer-provided localized labels |

## Platform differences

- Flutter haptic feedback has no automatic Web equivalent; pointer and keyboard
  feedback are preserved without requiring a device vibration API.
- Flutter snackbar positioning is owned by an overlay. React consumers place
  `BLabSnackbar` in their toast/overlay owner and provide keyboard-aware layout.
- Flutter bottom-bar action callbacks expose coordinates for native animations.
  React exposes an action callback and leaves coordinates to the browser layout.
- Web responsive geometry adapts to viewport width, while tokens, hierarchy,
  component anatomy and state transitions remain shared.
- The browser keyboard accessory exposes native buttons and consumer-owned
  labels; undo and redo preserve Flutter's long-press repeat behavior.

## Boundaries

The package must not import product routes, authentication, Supabase clients,
database models, billing logic or product-specific copy. Consuming apps provide
all user-facing localized strings and application state. Private component
files are not a supported import path; only the package root and `styles.css`
entry are public.
