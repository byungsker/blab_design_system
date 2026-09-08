# BLab React/Next.js

The React package is the Web implementation of the BLab visual and interaction
contract. It follows the Flutter package at the repository root as the semantic
authority and keeps product routes, data, authentication and product copy in
consuming applications.

## Installation

After the 0.2.0 package is published, install it with:

```bash
npm install @byungsker/blab-design-system
```

Until publication, install the package from this repository with
`npm install ./packages/react`.

The package is currently marked `UNLICENSED` for Byungsker-owned consumers;
do not publish or redistribute it until the repository owner selects a public
distribution license.

Import the public package and its shared CSS entry point. The CSS entry also
loads the package-bundled Inter Latin font used by the parity fixture:

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

For `obscureText` fields, the controlled value is omitted from server-rendered
HTML and applied at the client boundary so password values are not serialized
into Next.js responses. Keep sensitive field state in a client component.

## Public surface

| Flutter export | React export | Web contract |
| --- | --- | --- |
| `BLabColors` | `BLabColors` | Light/dark semantic color values |
| `BLabTheme` | `BLabTheme` | Light/dark theme metadata and component defaults |
| Spacing tokens | `BLabSpacing` | Spacing values and CSS variables |
| Radius tokens | `BLabRadii` | Radius values and CSS variables |
| Elevation tokens | `BLabElevation` | Shadow values and CSS variables |
| Glass tokens | `BLabGlass` | Blur and fill contract |
| Motion tokens | `BLabMotion` | Press, surface and repeat timings |
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

Interactive component exports carry a Next.js client boundary. Render them at
client leaves and pass serializable labels and state from the route or feature
owner. Import the CSS entry from the root layout or a global stylesheet accepted
by the Next.js build.

```tsx
"use client";

import { BLabButton } from "@byungsker/blab-design-system";
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

Labels, errors, status messages and navigation names are required consumer
decisions. Pass localized Korean and English strings from the product; the
package does not embed product vocabulary or fallback action labels. The
standalone fixture supplies English labels explicitly for test purposes and is
not part of the public root export.

## Verification

```bash
npm run lint
npm run typecheck
npm test
npm run build
npm run test:browser
```

The package-local parity fixture is included for browser verification and does
not contain Bookgolas routes, data or authentication behavior.

## Versioning

Flutter remains the semantic authority. Additive parity APIs use a compatible
minor release, fixes use a patch release, and breaking React public API or
token changes use a major release. Flutter-only changes do not require a React
release when the public contract and rendered behavior stay unchanged. Any
cross-platform token or interaction change updates both surfaces or records an
intentional divergence. Consumers pin an explicit version and use only the
public package root or `styles.css` entry.

Serve the package directory after `npm run build:fixture` and open
`fixture/index.html` for a standalone Chromium surface:

```bash
npm run build:fixture
node scripts/serve-fixture.mjs 4173
```

`npm run test:browser` reserves an isolated loopback port automatically; set
`PLAYWRIGHT_PORT` only when an explicit port is required by the environment.
