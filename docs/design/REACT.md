# React and Next.js Contract

The React package at `packages/react` is a typed Web mapping of the Flutter
public BLab package. Flutter remains the semantic reference implementation.

## Cross-platform mapping

| Concern | Flutter | React/Next.js |
| --- | --- | --- |
| Primary color | `BLabColors.primary` | `BLabColors.primary` and `--blab-color-primary` |
| Type scale | `BLabTypography.*` | `BLabTypography.*` |
| Primary action | `BLabButton(variant: primary)` | `BLabButton variant="primary"` with contrast-safe `BLabColors.primaryAction` fill |
| Glass surface | `BLabCard` | `BLabCard` with `backdrop-filter` fallback |
| Form control | `BLabTextField` | Controlled `BLabTextField` |
| Feedback | `BLabSnackbar.show` | `BLabSnackbar` live-region component |
| Press feedback | `BLabPressableWrapper` | `BLabPressableWrapper` pointer and keyboard events |
| Navigation | `BLabBottomBar` | `BLabBottomBar` with `aria-current` |
| Tabs | `BLabTabBar` | `BLabTabBar` with `role="tablist"` |
| Segments | `BLabSegmentedControl<T>` | `BLabSegmentedControl<T>` with `aria-pressed` |
| Keyboard accessory | `BLabKeyboardAccessoryBar` | Capability flags and repeatable undo/redo actions |
| Spacing | Flutter `EdgeInsets` values | `BLabSpacing` and `--blab-space-*` CSS variables |
| Radius | Flutter `BorderRadius` values | `BLabRadii` and `--blab-radius-*` CSS variables |
| Elevation | Flutter glass shadows | `BLabElevation` and `--blab-elevation-*` CSS variables |
| Glass | Flutter blur/fill/border | `BLabGlass` and `--blab-glass-*` CSS variables |
| Motion | Flutter interaction durations | `BLabMotion` and scoped reduced-motion CSS |

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

## Prop and interaction matrix

| React public surface | Flutter counterpart | React props and callback mapping | Motion and state mapping |
| --- | --- | --- | --- |
| `BLabButton` | `LiquidGlassButton` | `text`/`children`, `variant`, `isFullWidth`, `loading`, `loadingLabel`, `onClick` | 150ms press/filter; disabled and `aria-busy` preserve loading state |
| `BLabCard` | `LiquidGlassCard` | `children`, `padding`, `borderRadius`, `onClick`, `onLongPress`, `disabled` | 150ms press; keyboard Enter/Space invokes action |
| `BLabTextField` | `LiquidGlassTextField` | controlled `value`/`onChange`, `label` or `ariaLabel`, `hintText`, `obscureText`, `maxLines`, `error`, `onClear` | Native focus/error/disabled states; error is described and announced |
| `BLabSnackbar` | `BLabSnackbar.show` | `message`, `type`, `icon`, `onDismiss`, required `dismissLabel` when dismissible | Live-region role and assertive error behavior; placement belongs to consumer |
| `BLabPressableWrapper` | `PressableWrapper` | `children`, `onTap`, `onLongPress`, `scaleEnd`, `brightnessEnd`, `animationDuration` | 150ms press feedback; pointer cancellation clears state |
| `BLabLoadingState` | Loading surface pattern | required `label`, `size` | Spinner animation is non-essential and clamped by reduced motion |
| `BLabEmptyState` | Empty surface pattern | required `title`, optional `message`, `actionLabel`, `onAction` | Consumer owns localized copy and action state |
| `BLabErrorState` / `BLabRetryButton` | Error/retry pattern | required `title`, `message`, `retryLabel`, `onRetry`, `retryLoading` | Alert role, disabled/loading-safe retry action |
| `BLabBottomBar` | `LiquidGlassBottomBar` | `tabs`, `selectedIndex`, `onTabSelected`, required `ariaLabel`, optional labeled action/chevron | Selected item uses `aria-current`; Web action has no native coordinates |
| `BLabTabBar` | `LiquidGlassTabBar` | `tabs`, `selectedIndex`, `onTabSelected`, required `ariaLabel`, indicator tokens | Roving tab focus with Arrow/Home/End; selected indicator is stateful |
| `BLabSegmentedControl<T>` | `BLabSegmentedControl<T>` | `items`, `selectedValue`, `onChanged`, required `ariaLabel` | Roving focus with ArrowLeft/Right and `aria-pressed` |
| `BLabKeyboardAccessoryBar` | `BLabKeyboardAccessoryBar` | required `onDone`, `ariaLabel`, `doneLabel`; optional labeled navigation/editing callbacks and capability flags | 500ms long-press delay, 100ms repeat interval for undo/redo |

Every user-facing accessible name in the React package is supplied by the
consumer. The standalone fixture passes English test labels explicitly; it is
not a source of product copy.

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
- The Web primary and destructive action fills use contrast-safe derived
  tokens while the source semantic colors remain unchanged; this is the only
  intentional action-color adaptation and is covered by the parity snapshots.

## Boundaries

The package must not import product routes, authentication, Supabase clients,
database models, billing logic or product-specific copy. Consuming apps provide
all user-facing localized strings and application state. Private component
files are not a supported import path; only the package root and `styles.css`
entry are public.
