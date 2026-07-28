# BLDS Phase 3 BLabTabBar status

Task: `BLDS-PHASE3-NAVIGATION-TABBAR-2026-07-26`

Design authority:
`BLDS-PHASE3-NAVIGATION-TABBAR-DESIGN-DECISION-2026-07-26`, preserved in
[`BLDS_PHASE_3_TAB_BAR_DESIGN_DECISION.md`](BLDS_PHASE_3_TAB_BAR_DESIGN_DECISION.md).

## Scope and current decision

This family scope is `BLabTabBar` only. `BLabSegmentedControl`,
`BLabBottomBar`, Button, TextField, `DESIGN.md`, fonts, assets, dependencies,
product repositories, Figma, release, and publication remain outside this
delivery. Astryx is capability-method evidence only and supplies no Blab
source, value, vocabulary, asset, appearance, or documentation.

The approved Phase 3 state contract is:

| State or condition | Applicability | Local evidence |
| --- | --- | --- |
| unselected | required | canonical tokens and focused widget tests |
| selected-current | required | controller-owned selection, weight, and indicator tests |
| pointer hover | required | overlay and precedence tests |
| pressed | required | confirmed activation and overlay tests |
| keyboard-visible focus | required | 2 px outline plus 3 px outer-ring tests |
| controller-controlled selection | required | external-controller synchronization tests |
| keyboard roving focus | required | LTR/RTL Arrow, Home, End, Enter, and Space tests |
| scrollable overflow | conditional on `isScrollable` | private non-primary reveal and semantics tests |
| disabled | not applicable | no public disabled contract or simulated state |
| loading, busy, invalid, error | not applicable | no public contract or simulated state |
| expanded, disclosure | not applicable | no public contract or simulated state |
| drag-selection, haptic | not applicable | manual scrolling is neutral; no haptic API |
| BottomBar | not applicable | explicitly outside the approved family |

Precedence is keyboard-visible focus composed with selected-current, then
pressed replacing hover, then hover, selected-current, unselected, and
default. Pointer-down records modality and a pending pressed state only;
confirmed tap owns pointer focus and activates exactly once. Horizontal
touch-drag leaves focus, selection, callback count, and roving entry unchanged.

## Public compatibility

`BLabTabBar` remains a `StatelessWidget` implementing `PreferredSizeWidget`.
Its constructor, fields, caller-owned `TabController`, defaults, and localized
caller labels are unchanged. No public API is added. `onTap` is a post-
activation notification: confirmed pointer/touch/semantics activation and
Enter/Space call it exactly once, including selected reactivation; external
controller changes, controller swipe/drag, rebuilds, and Arrow/Home/End do not.

## Visual, accessibility, and motion contract

The exact four-mode `component.tab.*` values and reference graph are canonical
in `contracts/tokens/blab.tokens.yaml` and the Design decision. Default
evidence applies only on the approved Blab base, raised, and overlay surfaces.
Dedicated color arguments override style colors, which override component
tokens. Caller color overrides have caller-owned contrast conformance.

Each target is at least 44 by 44 logical pixels and the bar is at least 56
logical pixels high. Equal-width geometry measures wrapping at the actual item
width, and the height grows without clipping for valid linear and nonlinear
scaling, including `AppBar.bottom`. Ambient scaling is not clamped. Selected
label and indicator transitions use `BLabMotion.durSurface` (300 ms); hover,
pressed, and programmatic reveal use `BLabMotion.durPress` (150 ms). The
selected/unselected label is inherited from `AnimatedDefaultTextStyle`, so
color and weight are genuinely interpolated at the 150 ms midpoint. Reduced
motion resolves these transitions immediately. The default indicator is a
label-width bottom underline with retained positive 3 px thickness and an
optional full-width 1 px divider below it.

The native semantics hierarchy is an explicit parent tab-bar role with direct
child tab roles. Each child exposes selected, mutually-exclusive, and tap
semantics without duplicating the generic button flag, and merges the
caller-provided localized label with
`MaterialLocalizations.tabLabel` index/count copy. Scrollable RTL evidence
covers Arrow/Home/End and external controller reveal at both physical extents,
including native physical `scrollLeft`/`scrollRight` actions.

Scrollable layout reconciliation tracks viewport width, content width,
`Directionality`, and `isScrollable` re-entry. After a changed layout is
committed, it immediately reveals the internally focused tab or otherwise the
current controller tab. This post-layout correction changes no focus,
selection, callback, public controller ownership, or semantics. Every content-
width change, including selected/unselected style width changes caused by
selection, receives this post-layout reconciliation. Reduced motion remains
immediate.

## Evidence status

The original focused implementation suite established a 17-test red baseline
and later passed 17/17. The parent subsequently closed the first ordered-suite
semantics harness repair at 235/235. Independent Design then returned four new
scoped blockers: native tab roles/localized position copy, inherited label
interpolation, equal-width/RTL/contrast geometry evidence, and the retained
positive indicator-weight constraint.

The current repair added the complete assertions before production edits. Its
red run executed 21 focused tests: 16 passed and 5 failed, directly exposing
the four findings plus their coupled geometry/semantics behavior. After the
TabBar-only repair, the focused suite passes 21/21. Phase 1A/1B contract,
generation, negative-drift, API, coverage, and doctor pipeline tests pass
38/38. The selected Phase 2 and SegmentedControl regression set passes 97/97.

The parent aggregate command was:

```text
CI=true FLUTTER_ALREADY_LOCKED=true FLUTTER_SUPPRESS_ANALYTICS=true /opt/homebrew/Caskroom/flutter/3.19.2/flutter/bin/cache/dart-sdk/bin/dart /opt/homebrew/Caskroom/flutter/3.19.2/flutter/bin/cache/flutter_tools.snapshot test --no-pub --concurrency=1 --reporter compact
```

It exited 0 with `All tests passed` after executing 239/239 tests against the
current source, including the narrow semantic cleanup. The cleanup adds
explicit `isButton == false` assertions for both native tab children and
removes only the redundant generic-button flag.

Independent Design approved that source. Independent Quality then returned one
P2 blocker: scroll reveal was not reconciled after viewport/content width
changes, `Directionality` changes, or `isScrollable` false-to-true re-entry.
Three focused regressions were added before production changes for those
boundaries. The focused suite now contains 24 tests. The implementation-owner
profile could not open Flutter's loopback test socket, so it stopped before
executing a case. The parent then ran the full package against the current
source; it exited 0 with `All tests passed` after 242/242 tests. This aggregate
includes all 24 TabBar cases, the selected navigation/foundation regressions,
and the Phase 1A/1B pipeline. The Quality re-gate remains required.

A subsequent read-only Quality re-gate found that the first layout repair
excluded selection-induced content-width changes. One additional focused
regression selects an end tab whose selected label style is wider, proving the
target must become fully visible without focus theft or callback emission. The
exclusion is removed: every content-width change now schedules the same
immediate post-layout reveal. The focused suite contains 25 tests. The local
restricted runner remained socket-blocked, but the parent focused suite then
passed 25/25 and the parent full package passed 243/243 with
`All tests passed`. The initial parent run exposed an invalid test fixture
whose selected end tab was wider than its 100 px viewport; changing only that
fixture to a 120 px viewport retained the intended geometry-growth regression
while making full visibility physically possible.

A second Quality re-gate identified the equal-total-width case: selected and
unselected item widths can swap while aggregate content width stays unchanged.
The layout signature now also tracks `selectedIndex` without excluding any
content-width change. A middle-tab regression proves that equal aggregate
width, selected-item growth, outside focus, controller ownership, and callback
silence are all preserved. The focused suite passes 26/26 and the full parent
package passes 244/244 with `All tests passed`.

| Command or gate | Result |
| --- | --- |
| focused red baseline for this repair | RED as intended, 16 passed / 5 failed of 21 |
| focused four-blocker repair before semantic cleanup | PASS, 21/21 |
| current focused suite after semantic cleanup | PASS as part of the current aggregate; 21/21 |
| current focused suite after layout reconciliation | PASS as part of the current aggregate; 24/24 |
| current focused suite after selection-width reconciliation | PASS, 25/25, exit 0, `All tests passed` |
| current focused suite after equal-total-width reconciliation | PASS, 26/26, exit 0, `All tests passed` |
| selected Phase 2 + SegmentedControl regression | PASS as part of the current aggregate; 97/97 |
| parent full package after equal-total-width reconciliation | PASS, 244/244, exit 0, `All tests passed` |
| contract validator | PASS, including TabBar token, raw-value inventory, phase, immutable-history, and current digest |
| generator `--write` twice and `--check` | PASS, 8 deterministic outputs; both writes byte-identical |
| API snapshot check | PASS, body checksum unchanged at `01a64a8509f8a7ed779f4bff7a45dee0effa3907bf4f1d445a1783bbbe9c91be` |
| current Phase 1A/1B pipeline | PASS as part of the current aggregate, 38/38 including negative drift protection |
| formatter | PASS |
| root analyzer | PASS, no issues |
| example analyzer | PASS, no issues |
| example platform-neutral release bundle | PASS |
| doctor human/JSON | PASS, 5 pass, 3 expected warnings, 0 failures, 1 information |

The canonical raw-value inventory records 55 TabBar entries and 303
repository component entries. Base, raised, and overlay contrast pairings are
tested in all four supported visual modes, including composited hover/pressed
text and actual focus-ring adjacency. No arbitrary-background or custom-
override conformance is claimed.

The doctor warnings are pre-existing authority/evidence boundaries:
release/publication authority is absent, remote font/asset activation is
unresolved, and repository custody is unresolved. They are not TabBar product
failures. This remains family partial; repository-wide capability and global
conformance remain false.

## Consumer canary

The archive-only Baroguni canary used committed HEAD
`efa512c7d3539ba176cb5cb3c085d9906f6c4c84` from the `baro-app` repository,
never the dirty consumer worktree. Its two committed TabBar callers,
`lib/ui/stats/stats_screen.dart` and
`lib/ui/cart/cart_list_screen.dart`, resolved BLDS through a temporary local
path override. Analyzer resolution completed with 45 pre-existing consumer
findings (4 warnings and 41 informational diagnostics), including a declared
but gitignored `.env` asset; none is in the two TabBar calls or caused by this
package. The first bundle therefore stopped at that missing committed asset.
After adding a non-secret placeholder only inside the disposable archive, the
platform-neutral release bundle passed.

The consumer worktree was not mutated. Its before/after HEAD remained the same,
and its before/after worktree-status digest was
`348e5d963852e8f7d1484aa1f93a6ea86105b77f47b5d6bf7e11e26488b3fc54`.
The validated temporary directory `.tmp-tabbar-canary.V67gNo` was removed and
absence confirmed.

## Hash evidence

Protected/current SHA-256 values:

- `DESIGN.md`:
  `3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4`
- SegmentedControl:
  `c1911b55046c1bf5633adda645070a2de8d5a4b3ac19437b9dc1a93b9e699cf6`
- BottomBar:
  `ed6440ff2e40014b501eeaa8548c7f40a9713dad8ef318dd79446e78c0e9f618`
- Button:
  `fca58bb9c9f4ce8056f980f9c843321d04cf3b054062597120abe1f36914b1cb`
- TextField:
  `2780bc171dc30de47f7f13c38ea565b4fa2a6343c047e7a74921daa2a55e7ac8`
- TabBar immutable Phase 0:
  `6120a861479ca1db44eb1fd14680a48ab046652e4f63bfc262c157a0176d8bc3`
- TabBar current:
  `1373b3e8c9a27ad1f6c36b4ea03d23f0bc18496736d010a32684f971a143bac9`
- API snapshot:
  `5539b7eff875a8ca922eedc0961d01babf7b0988247d3c0007f3734fd09c2307`

The exact 16-file hand-authored TabBar source-scope digest is
`148ca18fafa7af38015e23a5a98648a0570bdf17cf1d807aad2ad962a377b9d2`.
The exact 25-file family/artifact combined-scope digest is
`804ef3a4f431b6b911a368eb5a178a7dd34e166b65205d114d08be90787b2949`.
Each is SHA-256 over the ordered `shasum -a 256` output for the paths in the
implementation audit; this status document is excluded to avoid self-
reference.

## Rollback

Rollback is family scoped: restore only the TabBar widget, focused tests,
story, this status/decision documentation, and the `component.tab` canonical
entries, then regenerate the shared deterministic outputs. Do not delete or
roll back shared Button, TextField, or SegmentedControl outputs.

## Deferred boundaries

Phase 4 retains real-device rendering/goldens, real assistive-technology
sessions, and platform-specific focus/scroll confirmation. Independent Design,
Quality, release, deployment, and publication are not performed by this
implementation owner. Independent Design is green for the preceding semantic
source. Parent verification and the independent Quality re-gate must be rerun
against the current layout-reconciliation source before this boundary is
closed.
