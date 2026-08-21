# BLDS Phase 3 BottomBar status

Status: implementation verified; independent Design and Quality approved

As of: 2026-07-26

Task scope: `BLabBottomBar` family only

Design authority:
`BLDS-PHASE3-NAVIGATION-BOTTOMBAR-DESIGN-DECISION-2026-07-26`

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

## Scope and compatibility

The current family work changes only BottomBar-owned source, tests, story,
canonical decision/state/token evidence, deterministic shared outputs, API
snapshot metadata/body for the three approved additions, README/phase status,
and this packet. Button, TextField, SegmentedControl, TabBar, other component
sources, `DESIGN.md`, dependencies, fonts, assets, products, and consumers are
protected.

The legacy constructor and `BLabBottomBarItem` remain source-compatible.
`selectedIndex`, reactivation callback behavior, `noMargin`, the 62px baseline,
equal allocation, and caller-owned labels are retained. The only public
additions are optional null-default `actionSemanticLabel`,
`firstTabChevronSemanticLabel`, and `firstTabChevronExpanded`.

## State matrix

| State | Classification | Implementation evidence |
| --- | --- | --- |
| unselected | required | inactive icon and component unselected foreground |
| selected-current | required | persistent selected surface/foreground, active icon, native selected adapter |
| hover-pointer | required | pointer overlay |
| pressed | required | pressed replaces hover |
| keyboard-visible focus | required | additive 2px outline and 3px ring |
| touch-only long-press drag | required | RTL-correct logical drag and committed callback |
| optional action | conditional | conformant only with callback plus localized label |
| expanded disclosure | conditional | conformant only with callback, localized label, and controlled expanded state |
| disabled, loading, invalid | not applicable | absent and not simulated |

Precedence is environment modifiers first, persistent selection, then
`drag > pressed > hover > rest`, with keyboard-visible focus additive.

## Verification evidence

The focused specification contains 18 tests. Its test-first red load failed on
the three intentionally absent additive fields before production changes.
Parent execution outside the restricted socket profile then exposed and closed
runtime-only semantic-tree, shrink-wrap, pointer-state, RTL-drag, and
controlled-return defects. Independent review then added separate disclosure
semantics, nonblank-label, consumed-safe-area, cancelled-drag,
interrupted-key-cycle, and generated-state-evidence regressions. The final
focused run passes 23/23 and the reconciled repository run passes 267/267.

| Local non-socket gate | Result |
| --- | --- |
| contract/schema/validator | PASS, including exact BottomBar decision/token modes, raw inventory, immutable/current digests, and negative-drift rules |
| generator write twice/check | PASS, 8 outputs, byte-identical digest `79e5a0b1202a243bc9dc5fe4e8f58d7c78131e28e9e147e025e2b48c2c25e482` |
| API write twice/check | PASS; reviewed additive-only three-field drift |
| formatter | PASS, 5 files checked with zero remaining change |
| root analyzer | PASS, no issues |
| focused Flutter tests | PASS, 23/23 |
| full Flutter tests | PASS, 267/267 |
| workflow validator | PASS |
| example offline resolution/analyze/release bundle | PASS; no issues; generated directories removed; lockfile unchanged |
| Doctor human/JSON | PASS; 5 pass, 3 expected warnings, 0 failures, 1 information |

The canonical raw inventory contains 75 BottomBar source entries and 310
repository component entries. The three Doctor warnings remain the existing
release-authority, remote-font/assets, and repository-custody boundaries; none
is a BottomBar product failure.

## Hash evidence

- immutable Phase 0 BottomBar:
  `ed6440ff2e40014b501eeaa8548c7f40a9713dad8ef318dd79446e78c0e9f618`
- current BottomBar:
  `93bdad82e4148d36a4dabde98935a742c998aff618a36e73abbe6b3abd50fc9c`
- API snapshot:
  `47ca97f94aefe8e6038b7e4b028368dfaa64b495d51ddc6fa5865125335c447f`
- API input checksum:
  `f595b3c5ae645196859542bf36d80a1a0533587629d63040e4ed037be6dbb0fd`
- API body checksum:
  `b60718ad26bbc71309ad7c6230c83ca302e7356ff20a01cb2a652fdf346c8762`
- protected `DESIGN.md`:
  `3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4`
- protected Button:
  `fca58bb9c9f4ce8056f980f9c843321d04cf3b054062597120abe1f36914b1cb`
- protected TextField:
  `2780bc171dc30de47f7f13c38ea565b4fa2a6343c047e7a74921daa2a55e7ac8`
- protected SegmentedControl:
  `c1911b55046c1bf5633adda645070a2de8d5a4b3ac19437b9dc1a93b9e699cf6`
- protected TabBar:
  `a5ac68dfeec6ca866be28e09cbc997966a791930cf104e418ce0dd5d113a4248`

The individual component, API, contract, generated-output, and protected-file
digests above are the authoritative evidence for this slice; this
self-referential status document is excluded.

## Claim boundary

This remains family-partial evidence. Global component-state implementation,
visual conformance, accessibility conformance, locale conformance, release
authority, and repository-wide capability claims remain false. Phase 4 retains
goldens, real assistive-technology sessions, physical-device rendering, and
platform-matrix confirmation.

## Rollback

Rollback only the BottomBar widget, focused test, story, decision/status
documents, and `component.bottom-bar` canonical entries, then regenerate shared
outputs and reconcile the API snapshot. Never delete or roll back shared
Button, TextField, SegmentedControl, or TabBar outputs.
