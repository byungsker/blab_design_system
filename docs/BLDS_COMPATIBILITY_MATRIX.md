# BLDS compatibility matrix

As of 2026-07-28, package `0.2.0` is local and unreleased. This matrix is local
evidence, not a support promise or release target.

| Surface | Baseline or floor | Current local evidence | Status |
| --- | --- | --- | --- |
| Dart SDK | `^3.10.4` | local analyzer and tests | floor declared; release support unapproved |
| Flutter SDK | `>=3.38.5` | local Flutter toolchain evidence recorded by Phase 4 | floor declared; physical targets unverified |
| public Dart API | committed `HEAD` `ee78fbe…` analyzer snapshot | 325 additive changes: 317 entries and 8 default-safe/input-widening signatures | 0 breaking; deprecated detection unsupported and typed unknown |
| tokens | committed `HEAD` legacy CSS custom properties plus approved typed-token correction provenance | all legacy CSS values retained; 144 additive typed tokens plus 2 approved breaking value corrections for standard-mode Button foregrounds | 0 removal, type, or semantic change; 2 breaking value corrections under `BLDS-BUTTON-CONTRAST-2026-07-28` |
| Pressable tap contract | legacy non-null exported `onTap` field | nullable constructor input privately controls actionability; exported field is a no-op for null input | source-compatible; no fabricated tap semantics |
| Flutter fonts | no package runtime font assets | family-name preferences only; no bundled or fetched font files | production self-host/fallback/remote strategy unresolved |
| macOS arm64 | Flutter test renderer | package/analyzer/example evidence | local only |
| Ubuntu, Windows, remote macOS | workflow syntax | no remote run evidence | blocked |
| web | no verified release baseline | BLabButton-only Chrome widget suite: 61/61 on Chrome 150.0.7871.187; no full-package web test or build | component-scoped local evidence only; public web support unverified |
| iOS, Android, physical devices, assistive technology | no verified release baseline | no Phase 5 execution | unverified |
| baroguni direct Flutter consumer | pinned observed commit `efa512c…` | dirty checkout; custody and execution authority unverified | smoke not run |
| second direct Flutter consumer | none confirmed | none | exit unmet |
| OpenCS | web adapter experiment | not a Flutter package consumer | excluded from two-consumer exit |

Stable API and token vocabulary follows
`contracts/compatibility/policy.yaml`. Experimental vocabulary must be
explicitly declared; there are currently no experimental entries. A stable
removal requires both two published deprecation releases and 90 elapsed days,
an approved migration, two clean pinned consumer rehearsals, the applicable
Design decision, an exact TDC, and final release authority.
