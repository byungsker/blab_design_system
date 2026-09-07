# BLab React/Next.js

The React package is the Web implementation of the BLab visual and interaction
contract. It follows the Flutter package at the repository root as the semantic
authority and keeps product routes, data, authentication and product copy in
consuming applications.

## Installation

```bash
npm install @byungsker/blab-design-system
```

Import the public package and its shared CSS entry point:

```tsx
import {
  BLabButton,
  BLabCard,
  BLabTextField,
} from "@byungsker/blab-design-system";
import "@byungsker/blab-design-system/styles.css";
```

Set `data-blab-theme="dark"` on the application surface for dark mode. Without
the attribute, the light token set is used. The package does not read product
routes or application state.

## Public surface

| Flutter export | React export | Web contract |
| --- | --- | --- |
| `BLabColors` | `BLabColors` | Light/dark semantic color values |
| `BLabTypography` | `BLabTypography` | Shared type scale |
| `BLabButton` | `BLabButton` | Primary, secondary, destructive and loading |
| `BLabCard` | `BLabCard` | Static and keyboard-accessible pressable surface |
| `BLabTextField` | `BLabTextField` | Label, hint, obscured, multiline, clear and error |
| `BLabSnackbar` | `BLabSnackbar` | Status/alert live region |
| `BLabPressableWrapper` | `BLabPressableWrapper` | Press and long-press feedback |
| `BLabBottomBar` | `BLabBottomBar` | Selected navigation and optional action |
| `BLabTabBar` | `BLabTabBar` | Tab semantics and arrow-key navigation |
| `BLabSegmentedControl` | `BLabSegmentedControl` | Pressed selection and arrow-key navigation |
| `BLabKeyboardAccessoryBar` | `BLabKeyboardAccessoryBar` | Keyboard actions, capability flags and repeatable undo/redo |
| Loading state | `BLabLoadingState` | Localized loading label |
| Empty state | `BLabEmptyState` | Consumer-owned title, message and action |
| Error state | `BLabErrorState` | Consumer-owned error and retry copy |
| Retry action | `BLabRetryButton` | Disabled/loading-safe retry button |

React event props use `onClick`, `onChange`, `onTabSelected` and `onChanged` in
place of Flutter callbacks. `BLabTextField` is controlled and uses a string
value. `BLabBottomBar` action callbacks do not expose native coordinates; a
consuming product should calculate layout-specific placement itself.

## Next.js usage

Token objects and static components can be rendered by Server Components. Keep
interactive consumers at client leaves and pass serializable labels and state
from the route or feature owner. Import the CSS entry from the root layout or a
global stylesheet accepted by the Next.js build.

```tsx
import "@byungsker/blab-design-system/styles.css";

export function ReadingAction() {
  return <BLabButton text="Start reading" onClick={() => undefined} />;
}
```

## Accessibility and motion

Interactive controls use native buttons or keyboard-operable roles, expose
visible focus rings, and maintain 44px minimum targets where the Flutter
component uses compact controls. Error fields expose an alert message and
described relationship. The CSS `prefers-reduced-motion` rule removes
non-essential transitions and spinner motion without hiding state changes.

Labels, errors, status messages, retry copy and navigation names are required
consumer decisions. Pass localized Korean and English strings from the product;
the package does not embed product vocabulary.

## Verification

```bash
npm run lint
npm run typecheck
npm test
npm run build
```

The package-local parity fixture is exported for browser verification and does
not contain Bookgolas routes, data or authentication behavior.

Serve the package directory after `npm run build` and open
`fixture/index.html` for a standalone Chromium surface:

```bash
python3 -m http.server 4173
```
