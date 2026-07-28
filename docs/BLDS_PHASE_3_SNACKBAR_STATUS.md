# BLDS Phase 3 Snackbar status

Status: implementation verified; independent Design and Quality gates pending

As of: 2026-07-28

Task scope: `BLabSnackbar` family only

Design authority:
`BLDS-PHASE3-SNACKBAR-DESIGN-DECISION-2026-07-28`

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

## Scope and compatibility

This slice owns the Snackbar source, story, focused test, exact decision/state/
token contract, affected validator and generated outputs, public API snapshot,
and this evidence packet. Other component families, protected `DESIGN.md`,
dependencies, assets, product adapters, Git state, and releases are protected.

The legacy `show` signature/defaults and type enum order remain unchanged.
Managed queueing, controller closure, action/dismiss controls, announcement
priority, queue policy, persistence, and typed close reasons are additive.

## Contract-to-code traceability

| Contract | Canonical token/API | Implementation |
| --- | --- | --- |
| opaque overlay surface | `component.snackbar.surface` | `BLabSnackbar.surface` |
| primary foreground | `component.snackbar.foreground` | message text |
| default/strong border | `component.snackbar.border` | surface border |
| semantic type badges | `component.snackbar.badge-*` | 32×32 type badge |
| black glyph/HC outline | `component.snackbar.badge-glyph/outline` | badge icon/border |
| FIFO/replace/dedup | `BLabSnackbarQueuePolicy` | per-`OverlayState` manager |
| exact close lifecycle | `BLabSnackbarController`, `BLabSnackbarClosedReason` | record/controller completion |
| live message semantics | `BLabSnackbarAnnouncementPriority` | visible-only live region |
| secondary action/44 dismiss | `BLabSnackbarAction` | Button and IconButton adapters |

## Component and state coverage

Required entering, visible, exiting, success, error, warning, info, and
live-announcement states are implemented. Conditional action, dismiss, hover,
pressed, keyboard-visible focus, timer-paused, and programmatic-close routes
are represented directly or inherit the verified secondary Button contract.
Disabled, loading, selected, invalid, current, and expanded remain explicitly
not applicable.

## Accessibility and visual evidence

Focused widget coverage verifies message-only live-region semantics, separate
controls, no initial focus theft, conditional restoration, Enter/Space and
Escape behavior, 44×44 dismiss geometry, unclamped scaling,
RTL/safe-area/keyboard placement, four-mode token rendering, high-contrast
opacity/no-shadow, and reduced-motion opacity bounded by
`BLabMotion.durPress`. Regressions also cover focus capture when a queued
record becomes current, focus movement during exit, route-owned current and
pending disposal, controller idempotence, and nonzero timer pause/resume after
continuously advancing monotonic elapsed time without a preceding frame.

Flutter exposes live-region semantics but does not expose live-region
assertiveness on a semantics node. On platforms reporting explicit
announcement support, the implementation sends exactly one priority-bearing
event and sets the message node's `liveRegion` to false. Without that support,
it sends no explicit event and uses the message-only live-region fallback.
Timeout startup is independent of explicit delivery; thrown and unresolved
platform responses are isolated and cannot make a non-persistent Snackbar
indefinite.
Real assistive-technology behavior remains a Phase 4 platform check; automated
semantics must not be treated as that evidence.

## Package, consumer, provenance, migration, and rollback

No dependency, asset, font, or haptic surface is added. Public API growth is
additive, while existing `show` call sites remain source-compatible. Consumers
can migrate incrementally by replacing `show` with `showManaged` only when
controller, queue, action, or persistence behavior is needed.

Rollback is family-scoped: restore the legacy Snackbar source and snapshot,
remove the Snackbar decision/capability/current-digest additions and component
tokens, then regenerate deterministic outputs. The immutable Phase 0 digest
`ec4ab071ef6163debf9a9aacefe31efc4ce5fd9670e4704ff47bfd4c4354300f`
must remain unchanged.

Astryx is capability evidence. Its methods-only scope is an unsigned owner
statement; copy, derivation, code, values, vocabulary, assets, appearance, and
documentation facts remain unknown. Repository license/provenance remains
unchanged.

## Verification

The implementation packet passed:

- `dart run tool/validate_contract.dart`
- `dart run tool/generate_tokens.dart --write` twice, followed by `--check`
- public API snapshot write and check
- `flutter test test/blab_snackbar_test.dart` — 29/29 tests
- focused `flutter analyze` for the Snackbar source, story, and test — no issues

Exact evidence hashes:

- current Snackbar source:
  `efa9f7d8eccdcae01b913cd4c25a05a14e19e7a1138f12e9e089f4f0a0f33bf8`
- focused Snackbar test:
  `e01d654a16bc36a1f265fd3e1a6b441e08c15e960e2df40574d39c20efbd1e39`
- Snackbar story:
  `b3f927f4d9be27188b827a82a48ff4848194df766d3296379dd67bf93b806e7b`
- public API snapshot:
  `1ca741b996175c998d52543fb8c7cc35ec724cb3c57c8492b00d2f2f40a75bf4`
- deterministic generated-output aggregate:
  `7f00f48ec629e1c7fd2e8bbb9c5d4a1369432392c26a380257d4fa0d70363ef6`

The protected Phase 0 Snackbar digest remains
`ec4ab071ef6163debf9a9aacefe31efc4ce5fd9670e4704ff47bfd4c4354300f`.
Repository-wide analyzer/test aggregation and repaired independent Design and
Quality review remain the parent delivery task's final family gates.

## Remaining risks and decisions

- Goldens, physical-device rendering, real assistive-technology sessions, and
  platform-matrix confirmation remain Phase 4.
- No new Design, localization, terminology, or product decision is inferred.
- Release, publication, deployment, and product-consumer activation remain
  outside this packet.
