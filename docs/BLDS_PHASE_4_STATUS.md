# BLDS Phase 4 local evidence infrastructure status

Date: 2026-07-28
Owner: Engineering Design System Frontend
State: all ten exact local identities have bounded Design approval for
reproducibility and fixture review; independent Quality review, remote matrix
execution, and representative-consumer smoke remain open

## Outcome and claim boundary

Phase 4 has machine-readable story, platform, consumer, font-rights, and
candidate visual-baseline evidence. The repaired golden harness captures ten
scenarios with readable Latin, Korean, and Arabic text and deterministic
Material/Cupertino icons. Every candidate asserts that all nine public
component families are rendered fully inside the frame. Snackbar is displayed
persistently through `BLabSnackbar.showManaged`, not through a private or static
facsimile.

Scenario state is installed at `MaterialApp.builder`, above the Navigator and
Overlay. The root `MaterialApp` declares the scenario locale, while the builder
applies its MediaQuery and Directionality. Runtime assertions read the actual
Snackbar surface context and lock brightness, high contrast, text scaling,
locale, direction, disabled animations, accessible navigation, high-contrast
surface/badge borders, fixed badge geometry, RTL mirroring, and 2×-text control
stacking.

This packet establishes deterministic local image reproducibility, fixture
presence, and bounded Design-approved identity for all ten exact hashes. The
eight standard-mode identities changed under approved decision
`BLDS-BUTTON-CONTRAST-2026-07-28`; the two high-contrast identities remained
byte-identical. It does **not** claim Design-approved visual
conformance, accessibility conformance, production Pretendard evidence,
translation approval, supported physical platforms, consumer compatibility,
release readiness, or publication authority. Golden equality is not an
accessibility result. `DESIGN.md` was not edited by Phase 4.

The former 3.55:1 active Button foreground residual is resolved in automated
property evidence. Disabled Button contrast remains inactive-control
exempt/unverified. Neither the contrast checks nor bounded baseline approval
authorizes Button, Phase 4, or whole-system conformance.

## Design-contract-to-code traceability

| Contract | Machine-readable source | Implementation or evidence | Gate |
| --- | --- | --- | --- |
| nine public component families and applicable implemented states | `contracts/components/state-applicability.yaml` | `contracts/stories/blab.stories.yaml`, runtime story catalog, nine direct story pages | Phase 4 semantic validator |
| unsupported states must not be simulated | component state contract | loading and no-results stay explicit unsupported fixture categories | story schema and exact state-set validator |
| local baseline approval scope is reproducibility and fixture review only | story manifest and `contracts/visual-baselines.yaml` | shared harness plus isolated Latin/Korean and Arabic suites | schema, source-boundary, hash, dimension, and drift checks |
| readable deterministic multilingual fixtures | visual-baseline font fixture records | pinned Noto Sans KR and Noto Sans Arabic from official `google/fonts`; exact hashes and OFL copies | binary hash and notice validation |
| all families must be visibly framed | visual-baseline `required_component_families` | per-scenario geometry assertions for Button, TextField, SegmentedControl, TabBar, BottomBar, PressableWrapper, Card, Snackbar, and KeyboardAccessoryBar | 10/10 candidate capture assertions |
| Snackbar must use public persistent API | story/baseline scope | `BLabSnackbar.showManaged(... persist: true)` | validator source boundary plus visible capture |
| platform and CI claims stay bounded | `pubspec.yaml`, `contracts/platform-support.yaml` | macOS local package evidence, BLabButton-only Chrome widget evidence, and read-only Ubuntu/macOS/Windows workflow syntax | platform/schema validators reject broad web support or omitted browser limitations |
| consumer execution must be pinned and authority-aware | `contracts/consumers/representative-consumers.yaml` | nonmutating preflight and disposable-archive runner | typed skip; no source checkout mutation |

## Story and state coverage

The runtime catalog registers all nine public component contract ids: Button,
TextField, SegmentedControl, TabBar, BottomBar, PressableWrapper, Card,
Snackbar, and KeyboardAccessoryBar. The story manifest covers every state whose
contract evidence is `implemented-local`; it does not fabricate unsupported or
not-applicable states.

| Evidence category | Applicable families |
| --- | --- |
| default/static/visible baseline | all nine using family-owned vocabulary |
| hover | Button, TextField, SegmentedControl, TabBar, BottomBar, PressableWrapper, actionable Card, Snackbar controls, KeyboardAccessoryBar |
| pressed | Button, SegmentedControl, TabBar, BottomBar, PressableWrapper, actionable Card, Snackbar action, KeyboardAccessoryBar |
| focus | Button, TextField, SegmentedControl, TabBar, BottomBar, PressableWrapper, actionable Card, Snackbar controls, KeyboardAccessoryBar |
| disabled | Button, TextField, SegmentedControl item/control, KeyboardAccessoryBar per action |
| selected/current | SegmentedControl, TabBar, BottomBar |
| invalid/error help and empty | TextField |
| scroll overflow | SegmentedControl, TabBar, KeyboardAccessoryBar |
| loading | unsupported and unclaimed; Button `loading-busy` remains conditional without implementation evidence |
| no-results | no public component contract; retained as a product pattern |

## Candidate golden inventory

Capture uses Flutter 3.38.5, Dart 3.10.4, Flutter test renderer, macOS arm64,
device-pixel ratio 1, no network, no customer data, and no clock or randomness.
All ten hashes are `design-approved-local` under the 2026-07-28 review evidence
`design-final-gate-handoff:button_contrast_standard_goldens:2026-07-28`.
The non-generated durable approval artifact is
`contracts/approvals/phase4-local-baselines.design-approval.yaml`. It binds
each exact path/hash pair and fails closed on drift.

| Candidate | Status | Fixture | Dimensions | SHA-256 |
| --- | --- | --- | ---: | --- |
| `phase4-light.png` | Design-approved local | en-US, light | 800×1200 | `07369ba292a3d540e204ab825abfa7d60839cb7a36adce49146111a15be38e8a` |
| `phase4-dark.png` | Design-approved local | en-US, dark | 800×1200 | `8d00c1ba78a0fa4cdf25a2622b0126685a06630b62ee08f1d5f2fcfb22fb2333` |
| `phase4-high-contrast-light.png` | Design-approved local | en-US, high contrast light | 800×1200 | `ff9d5ba52b372b2a08b5137444e7b584d8a2689ca4f7b233ca3956312c09218c` |
| `phase4-high-contrast-dark.png` | Design-approved local | en-US, high contrast dark | 800×1200 | `2fe76e4b4bf7f7627fec63030298128a78143236faba34a5bc44eb620f6a0735` |
| `phase4-text-scale-2.png` | Design-approved local | en-US, 2× text | 800×1600 | `73c93244f71155738165cf10958d5165310cd73c30f39cadf7990c3a0df5eefa` |
| `phase4-ko-kr.png` | Design-approved local | ko-KR, real Korean copy | 800×1200 | `97056006505cd2e5b0f83ee5f9f1c9d7186bd05002c7096cc0ad096f2e509fa6` |
| `phase4-expansion-40.png` | Design-approved local | en-XA, deterministic 40% rune-count-only stress | 800×1400 | `aabdc7f64c9ce0e0cfcb66a5713c5a97617dc62a265f46007688c5e3b811ea9a` |
| `phase4-ar-rtl.png` | Design-approved local | ar, real Arabic RTL/bidi copy | 800×1200 | `4c29bab888348e9f6f6e472be72c76e15c781f2efb6a6b6dd4cacb9731d3a31c` |
| `phase4-reduced-motion.png` | Design-approved local | en-US, settled reduced motion | 800×1200 | `07369ba292a3d540e204ab825abfa7d60839cb7a36adce49146111a15be38e8a` |
| `phase4-narrow.png` | Design-approved local | en-US, 360px narrow | 360×1400 | `0624b9a312d119a6899df9ae0b40eef9a898c08f438081c3b7af1a3fe492a065` |

The reduced-motion image intentionally matches the settled light image;
behavioral duration/property tests remain separate. The text-scale-2 and narrow
captures visibly include both KeyboardAccessoryBar and persistent Snackbar,
as do all other candidates.

The synthetic expansion claim is limited to deterministic rune-count growth
within rounding tolerance. It does not claim that rendered width increases by
40%.

## Test-font rights and runtime boundary

The authoritative notice is
`test/assets/fonts/THIRD_PARTY_NOTICES.md`.

| Fixture | Pinned source | SHA-256 | License |
| --- | --- | --- | --- |
| Noto Sans KR variable | `google/fonts` commit `7ff85c87f93ea6cca5f41c69f2e4edcb90240f26` | `194018e6b2b293a7964f037b25c0249ce1418bc9ab3c971060a03aa57861e252` | OFL-1.1 |
| Noto Sans Arabic variable | same pinned `google/fonts` commit | `63111b5b2e074dd48cc67692e0a2726d86ee94c1c37fe8598257b7b4e87e869e` | OFL-1.1 |
| Material Icons | Flutter font artifact `3012db47f3130e62f7cc0beabff968a33cbec8d8` | `d9865b671a09d683d13a863089d8825e0f61a37696ce5d7d448bc8023aa62453` | CC-BY-4.0 |
| Cupertino Icons | `flutter/packages` commit `701d60a08941da4c6c5633af5263881963ed07b3` | `67c44fe9183b002e79dde7f6977e2988661c9a3e4a3c5fce968787efdbed823c` | MIT |

Latin/Korean and Arabic captures run in isolated Flutter test processes so
each process loads one appropriate Noto font under the process-local family
alias explicitly requested by the widgets. This avoids false glyph fallback.
The alias is not a claim that Noto is Pretendard. No font is declared in
`pubspec.yaml`; none becomes a package or runtime asset.

## Platform and representative-consumer boundary

The package floor remains Dart `^3.10.4` and Flutter `>=3.38.5`. Package-wide
local execution evidence remains Flutter 3.38.5/Dart 3.10.4 on macOS arm64.
One additional component-scoped browser result covers only the 61-test
BLabButton widget suite in Chrome 150.0.7871.187 on that host. It is not a
full-package web test, web build, deployment, browser matrix, physical-device,
assistive-technology, haptic, golden/rendering-conformance, shared-web-package,
or public-support claim. Ubuntu, macOS, and Windows are configured in a
read-only workflow, but no remote run is claimed. iOS, Android, physical
devices, real assistive technology, haptics, and product application builds
remain unverified.

One direct package consumer candidate is recorded: baroguni at observed local
HEAD `efa512c7d3539ba176cb5cb3c085d9906f6c4c84`. Its checkout is dirty and its
custody/task execution authority are unverified, so preflight returns typed
`consumer-worktree-dirty`; no consumer command runs and no consumer file is
mutated. Disposable execution additionally resolves the checkout and package
real paths and rejects absolute, escaping, missing, symlinked, or occupied
override paths before writing. A second direct Flutter package consumer
remains missing.

## Package, bundle, compatibility, and provenance impact

- Within the exact Phase 4 delivery unit declared by
  `contracts/delivery/phase4-custody.yaml`, no package-runtime or public-API
  file changed. This scoped statement does not characterize unrelated or
  pre-existing worktree changes.
- No production dependency, runtime asset declaration, font declaration,
  permission, package version, or publication configuration changed within
  that custody boundary.
- Ten PNGs total 661,718 bytes. Test font/icon fixture binaries and their
  licenses add approximately 13.2 MB of repository-only evidence.
- Public API shape remains unchanged. Button primary/destructive inherited
  foreground behavior changed under the authority-backed contrast amendment.
- Astryx remains a method/capability provenance source; Blab remains semantic
  and visual authority. The methods-only scope is an unsigned owner statement;
  copy, derivation, source, asset, font, and documentation facts remain unknown.
- No consumer source, Git state, release, deployment, or external account was
  mutated.
- Project delivery hygiene is explicit in `AGENTS.md`,
  `contracts/delivery/phase4-custody.yaml`, and `.gitignore`. Local `.codex/`
  content is user-owned, excluded from delivery, and cannot grant authority.

## Verification

Candidate regeneration and drift are separate:

```sh
flutter test test/phase4_candidate_golden_test.dart \
  --update-goldens --concurrency=1
flutter test test/phase4_candidate_rtl_golden_test.dart \
  --update-goldens --concurrency=1
flutter test test/phase4_candidate_golden_test.dart --concurrency=1
flutter test test/phase4_candidate_rtl_golden_test.dart --concurrency=1
```

Running an update changes image identities and therefore creates unapproved
candidates that require a new Design review. Current local results are:

- Latin/Korean candidate suite: 10/10 passed, including the exact 40%
  expansion invariant and nine candidate images;
- Arabic RTL candidate suite: 1/1 passed;
- Phase 4 evidence tests: 11/11 passed;
- Phase 4 schema, font/image hash, dimension, story, and claim-boundary
  validator: passed;
- manual visual inspection: readable Korean, readable Arabic/bidi, rendered
  Material/Cupertino icons, and visible all-family framing confirmed.
- Snackbar overlay-context assertions: all ten scenarios passed; high-contrast
  border/badge treatment, RTL logical mirroring, and 2×-text stacking are read
  from the real overlay surface rather than inferred from the page context.

The final aggregate `dart run tool/verify.dart` passed:

- package command: 413/413 passed (412 non-candidate tests plus the untagged
  40% expansion invariant);
- candidate drift commands: 11/11 passed (the expansion invariant is
  intentionally repeated in the Latin/Korean command);
- total executions across aggregate commands: 424/424; unique local tests:
  423/423;
- root and example analyzers: no issues;
- example platform-neutral release bundle: passed;
- consumer preflight: typed `consumer-worktree-dirty` skip, zero executed
  commands, zero mutation.

## Migration, rollback, and remaining gates

There is no runtime or consumer migration. Roll back this repair by removing
the two candidate test entrypoints, shared harness, ten candidate PNGs,
test-only font/icon files and notices, visual schema, and the repaired Phase 4
story/baseline/status additions. Restore the earlier Phase 4 baseline contract
and aggregate command. Do not change production typography, component
implementations, Phase 0–3 contracts, generated token outputs, consumer
repositories, or `DESIGN.md`.

Open gates:

- The Target Delivery Contract is typed `REQUEST_CHANGES`: observed branch
  `dev`, HEAD `ee78fbeb2e2e49c8e4069d798bab87590cc60fa9`, and package version
  `0.0.1` are recorded, but the authoritative target version/source, expected
  base/head, pull request, delivery authority, promotion path, and rollback
  target require a human decision.
- Independent Quality must re-review the complete packet.
- The remote three-host CI matrix has not run.
- Representative-consumer smoke and a second direct consumer remain open.
- Disabled Button readability remains inactive-control exempt/unverified.

Decision for this local packet: `APPROVE_NEXT` means independent Quality review
and the remaining Phase 4 evidence gates only. It does not authorize Git
mutation, changed-image approval, consumer execution, release, publication,
deployment, or any conformance claim.
