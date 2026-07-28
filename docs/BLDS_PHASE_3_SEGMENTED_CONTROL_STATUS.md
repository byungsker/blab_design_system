# BLDS Phase 3 family 3A: BLabSegmentedControl

Status: approved overflow addendum and focused re-gate repair independently approved

As of: 2026-07-26

Contract version: `0.2.0`

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

## Authority and boundary

This packet covers only `BLabSegmentedControl`, the first approved boundary of
the Phase 3 navigation family. The canonical Design authority is
`BLDS-PHASE3-NAVIGATION-SEGMENTED-DESIGN-DECISION-2026-07-26`, durably recorded
in
[`BLDS_PHASE_3_SEGMENTED_CONTROL_DESIGN_DECISION.md`](./BLDS_PHASE_3_SEGMENTED_CONTROL_DESIGN_DECISION.md)
and cited by `contracts/blab.design.yaml`.

The corrective Design authority is
`BLDS-PHASE3-NAVIGATION-SEGMENTED-SCROLLABLE-OVERFLOW-ADDENDUM-2026-07-26`,
durably recorded in
[`BLDS_PHASE_3_SEGMENTED_CONTROL_SCROLLABLE_OVERFLOW_ADDENDUM.md`](./BLDS_PHASE_3_SEGMENTED_CONTROL_SCROLLABLE_OVERFLOW_ADDENDUM.md)
and cited canonically by `contracts/blab.design.yaml`.

`BLabTabBar` and `BLabBottomBar` remain unchanged and unclaimed. Global
component-state, visual, accessibility, locale, and release claims remain
false. Phase 4 goldens and real assistive-technology verification remain
deferred.

## Applicability and evidence

| State or behavior | Applicability | Local evidence |
| --- | --- | --- |
| unselected | required | component source and focused tests |
| selected | required | controlled visual, weight, indicator, semantics tests |
| hover-pointer | required | mouse-only overlay and precedence tests |
| pressed | required | pressed-replaces-hover and exact-token tests |
| keyboard-visible-focus | required | 2px outline, 3px ring, pointer-focus absence tests |
| controlled-selection | required | callback, external update, selected reactivation tests |
| disabled-item-or-control | conditional | all-disabled, disabled-selected, activation/focus suppression tests |
| scrollable-overflow | conditional on finite insufficient width | owned controller, exact threshold, LTR/RTL reveal, focus priority, motion, manual scroll, and native semantics tests |
| keyboard-roving-focus | required with enabled items | LTR/RTL, vertical, Home/End, wrap, one-Tab-stop tests |
| loading, busy, invalid, error, overlay | not applicable | typed source inspection and this packet |
| expanded, current, disclosure, drag, haptic | not applicable | typed source/API inspection and this packet |

The focused suite also verifies all four visual modes, exact generated token
resolution, text/non-text contrast minima, standard shadow versus
high-contrast no-shadow behavior, 44×44 targets, ambient linear/nonlinear
text scaling, reduced motion, caller-owned labels, native selected/enabled and
mutually-exclusive semantics, and controlled focus synchronization. Narrow
finite layouts use an owned, non-primary horizontal scroll viewport so two
items under 80px and three items under 120px retain 44×44 semantic and hit
targets. Initial, focus, and controlled-selection reveal preserve the 3px ring
allowance; unbounded and sufficient layouts do not create scroll semantics.
Pointer-down establishes pointer modality and pending pressed feedback only.
Roving ownership and focus move only after a confirmed tap, so a horizontal
touch drag preserves external focus and the next roving Tab entry. Narrow RTL
tests exercise both logical ends and external enabled/disabled selection
reveal with the full 3px allowance without stealing outside focus.

## Compatibility

Existing constructor parameters, generic value handling, selection ownership,
labels, height 40, padding 3, radius, font size 13, weight 600/400, 180ms
selection opacity/color motion, and exactly-once `onChanged` behavior remain source
compatible. `BLabSegmentedControl<T>` again publicly extends
`StatelessWidget`; private state owns interaction and animation. The only
additive, default-safe API is `enabled = true` on `BLabSegmentedItem<T>` and
`BLabSegmentedControl<T>`.

No loading, haptic, positional-label, generic-value stringification, movement,
scale, scroll-controller, or uncontrolled-selection API was added.
`_moveAndRequest` contains one explicit destination focus request; handled
navigation does not issue a duplicate request.

## Test-first and verification evidence

The original focused run was red because the approved `enabled` parameters and
`component.segmented` token fields did not yet exist. Independent Design and
Quality then returned corrective findings. Repair-first tests reproduced the
public stateful inheritance, narrow target shrinkage, missing stable indicator,
incorrect contrast pair evidence, and unrelated-rebuild focus snap. The API
check was red for the required inheritance restoration. After repair, the API
diff contains only `StatefulWidget/createState` returning to the established
`StatelessWidget/build` shape; the two previously approved default-safe
`enabled = true` parameters remain the only additions.

The approved addendum was then reproduced red with missing per-item indicator
nodes, an `AnimatedPositioned` sliding indicator, an implicit
primary-eligible controller, no reveal policy, and no conditional overflow
evidence. The corrected focused run is green with fixed per-item indicator
nodes and the complete owned-overflow policy.

The latest Design re-gate repair was reproduced red after adding three focused
regressions: both narrow RTL reveal cases passed, while the touch-drag case
failed because pointer-down moved primary focus from the external node to item
`One`. The focused run reported 36 passes and one failure. The smallest
production correction leaves pointer-down responsible only for pointer
modality, then moves roving focus and invokes the callback only from the
confirmed tap. The same suite is green at 37/37.

Independent Design and Quality re-gates both returned `APPROVE_NEXT` after that
repair. This closes only the SegmentedControl boundary; `BLabTabBar`,
`BLabBottomBar`, the remaining Phase 3 component families, and Phases 4–5
remain sequentially gated.

| Command or gate | Result |
| --- | --- |
| `flutter test --no-pub test/blab_segmented_control_test.dart` | PASS, 37/37 |
| `flutter test --no-pub test/phase1a_contract_test.dart test/phase1b_pipeline_test.dart` | PASS, 36/36, including negative drift protection |
| Phase 2 + Button + TextField + SegmentedControl selected regression | PASS, 173/173 |
| `flutter test --no-pub --concurrency=1` | PASS, 216/216 |
| `dart run tool/validate_contract.dart` | PASS, including negative token/phase/digest drift protection |
| `dart run tool/generate_tokens.dart --write` twice, then `--check` | PASS, 8 deterministic outputs |
| `dart run tool/public_api_snapshot.dart --write`, then `--check` twice | PASS, body checksum unchanged; no public API drift |
| targeted `dart format --output=none --set-exit-if-changed ...` | PASS, 5 Dart files, 0 changed |
| root `flutter analyze --no-pub` | PASS, no issues |
| example analyze and platform-neutral bundle | Prior approved-addendum gate retained; unaffected and not rerun |
| doctor human + JSON schema validation | Prior approved-addendum gate retained; unaffected and not rerun |
| `git diff --check` | PASS |

The doctor warnings are pre-existing authority/evidence boundaries:
release/publication authority is absent, remote font/asset activation is
unresolved, and repository custody is unresolved. They are not
SegmentedControl product failures and no conformance claim is inferred.

## Consumer canary

The Baroguni canary used committed HEAD
`efa512c7d3539ba176cb5cb3c085d9906f6c4c84` from `baro-app/app`, archived into
the validated temporary directory
`/private/tmp/blds-segmented-addendum-canary.I3YV5R`. Its single caller,
`lib/ui/invite/invite_code_bottom_sheet.dart`, resolved
`blab_design_system` from the local path override and passed focused analysis
with no issues. A temporary empty `.env` satisfied the committed asset
declaration; this is a canary-environment prerequisite, not a package finding.

The consumer HEAD and complete worktree-status digest were identical before
and after:
`707d65f57101b989b88c362e2a00589dcbca54255ad7d03ec0c52f8ab50d353c`.
The validated temporary directory was removed and its absence confirmed.
The generated `example/build` directory was also removed after bundle
verification and its absence confirmed.

The latest repair did not rerun this canary: it changes no public API and only
delays private roving-focus ownership from touch-down to confirmed tap. The
focused, selected-regression, full-package, and analyzer gates cover that
behavioral boundary without consumer mutation.

## Hash evidence

Protected/current source SHA-256:

- `DESIGN.md`:
  `3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4`
- Button:
  `fca58bb9c9f4ce8056f980f9c843321d04cf3b054062597120abe1f36914b1cb`
- TextField:
  `2780bc171dc30de47f7f13c38ea565b4fa2a6343c047e7a74921daa2a55e7ac8`
- TabBar:
  `6120a861479ca1db44eb1fd14680a48ab046652e4f63bfc262c157a0176d8bc3`
- BottomBar:
  `ed6440ff2e40014b501eeaa8548c7f40a9713dad8ef318dd79446e78c0e9f618`
- SegmentedControl immutable Phase 0:
  `d3fa831d6cf4764130cd4f1430f134f7db840b0dbd1816a067ca7a776cf97628`
- SegmentedControl current:
  `c1911b55046c1bf5633adda645070a2de8d5a4b3ac19437b9dc1a93b9e699cf6`
- API snapshot:
  `d035af8f99cadccc00a7c2ae678c46154cb5bffbb9a8e05c6445a3a3302a6972`

The exact 14-file hand-authored SegmentedControl source-scope digest is
`bf83eb7f4baa643e07aa2022d14cc152505697a390b9f9f8e4f6e597204fb03a`.
The exact 23-file family/artifact combined-scope digest is
`28f70ce95ee89ec751d04230eed7224ba17f6bf1b7fbd632983f646c5d6a3916`.
Each digest is SHA-256 over the ordered `shasum -a 256` output for the paths
enumerated in the task audit packet; this status document is excluded to avoid
self-reference.

## Rollback

Rollback is family coherent: restore the historical SegmentedControl source
and public API, remove only SegmentedControl-owned canonical token,
decision/applicability/capability/current-digest entries, then regenerate all
shared deterministic outputs from the remaining canonical sources. Shared
generated files are regenerated, never deleted, because they also contain
Button and TextField evidence. Remove only SegmentedControl-focused
tests/example/status evidence and restore the reviewed API snapshot. Button,
TextField, TabBar, BottomBar, other component sources, DESIGN.md, and immutable
Phase 0 digests are not part of this rollback.

No commit, push, PR, release, deployment, publication, external service, or
Figma mutation is authorized by this packet.
