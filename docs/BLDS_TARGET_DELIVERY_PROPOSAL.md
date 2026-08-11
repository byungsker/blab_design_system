# BLDS full-repository Target Delivery Contract

Date: 2026-07-28
Owner: byungsker
State: accepted active release plan
Accepted: 2026-07-28
Decision: `APPROVE_NEXT` for branch, isolated worktree, commit, push, and draft
pull-request creation only

## Purpose

The current worktree contains a coherent BLDS capability-adoption program
across Phases 0–5, component runtime, tests, examples, compatibility, legal
preparation, and delivery tooling. The existing `phase4-evidence` delivery unit
cannot truthfully own that mixed scope.

This document records the exact repository-only delivery contract accepted by
byungsker in the Codex thread on 2026-07-28. The acceptance authorizes the
branch, isolated worktree, commit, push, and draft pull-request creation named
here. It does not authorize merge, tag, release, publication, deployment,
consumer mutation, or GitHub approval.

## Active contract

| Field | Exact accepted value |
| --- | --- |
| delivery profile | `package-or-local` |
| delivery intent | full BLDS repository integration |
| delivery unit | `blab-design-system` |
| target version | `0.2.0` |
| target-version source | owner acceptance of this proposal followed by an active release-plan record |
| change type | `feat` |
| scope slug | `astryx-capability-adoption` |
| canonical repository | `byungsker/blab_design_system` |
| verified source base | current remote `main` at `aa5e857b0c97c6ca9cd86f27b5591c28b5c143ac`, synchronized after the trusted governance bootstrap merge |
| expected head | `codex/feature/blab-design-system/0.2.0/astryx-capability-adoption` |
| pull request | draft PR from the proposed head to `main`, with exact Target Delivery metadata |
| promotion | repository-only review; merge remains unauthorized until trusted CI, branch governance, Design, Quality, rights, and delivery gates pass |
| package publication | explicitly excluded |
| tag or GitHub Release | explicitly excluded |
| deployment | explicitly excluded |
| consumer mutation | explicitly excluded |
| rollback before merge | abandon the isolated delivery branch/worktree; preserve the current source worktree |
| rollback after merge | revert the merge through a separately authorized PR; never move or reuse `v0.1.0` |

## Base synchronization addendum (2026-08-12)

The originally accepted creation base was `main@9ac903c448685c31d37cbaf4340990e7c0e8226c`.
The trusted governance bootstrap was subsequently merged as
`aa5e857b0c97c6ca9cd86f27b5591c28b5c143ac`, and PR #10 now targets that current
canonical `main` commit. The active machine-readable contract and its Phase 5
validator therefore use `aa5e857b0c97c6ca9cd86f27b5591c28b5c143ac` as the
current expected base. This synchronizes delivery metadata only; it does not
grant product merge, release, publication, deployment, or consumer authority.

`0.2.0` is accepted because the package contains substantial additive work and
the compatibility classifier records two approved breaking token-value
corrections. The delivery branch must declare `0.2.0` in `pubspec.yaml`. The
existing `v0.1.0` tag is not a valid target-version authority because it points
to a commit whose `pubspec.yaml` declares `0.0.1`; it must remain immutable and
be documented as an inconsistent historical tag.

## Delivery allowlist

The full-repository unit may include the current BLDS package, example, tests,
tooling, workflows, contracts, generated contract outputs, API snapshot,
documentation, notices, and root package metadata needed by the verified
capability-adoption program.

The following remain excluded:

- `.codex/` and all user-local configuration;
- credentials, ignored secrets, editor state, build products, and arbitrary
  temporary files;
- any `DESIGN.md` content other than the byte-for-byte approved restoration
  whose SHA-256 is
  `3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4`;
- consumer repository mutations;
- tag, release, registry, or deployment artifacts;
- unsigned human attestations represented as signed or approved evidence.

Before isolation, the exact path allowlist must be materialized from the final
worktree inventory and reviewed for unrelated user changes. A mixed dirty
worktree must not be committed directly.

## Required PR metadata

The future draft PR must contain exactly one of each:

```text
Target-Delivery-Unit: blab-design-system
Target-Version: 0.2.0
Delivery-Profile: package-or-local
```

This is a normal work PR, not a release or hotfix PR. `Promotion-Source-SHA`
is forbidden on normal work pull requests and remains required, with the
approved source SHA, only for release and hotfix promotion pull requests.

## Bootstrap dependency

The canonical repository currently has no trusted remote CI run, branch
protection, or ruleset for this delivery. Before normal promotion, an
independently authorized bootstrap governance change must establish the
required target-version check and protected `main` path, or the Company Target
Delivery Contract policy must grant an explicit documented exception.

## Rights and publication boundary

Repository-only delivery does not clear package publication. Copyright-holder
and MIT-notice authority, `baro-app` transfer/relicense authority, contributor
identity and restrictions, per-source Astryx/Figma provenance, exact package
composition, channels, markets, jurisdictions, font policy, signed
attestations, two clean pinned direct consumers, and final release authority
remain unresolved.

## Owner acceptance record

Byungsker accepted the exact delivery unit, version, base, Codex-prefixed head
naming, repository-only draft-PR scope, historical `v0.1.0` treatment, and the
branch/worktree/commit/push/draft-PR actions on 2026-07-28. The separate Phase
4 evidence TDC remains bounded to Phase 4 and does not govern this
full-repository delivery. The machine-readable active TDC is
`contracts/delivery/blab-design-system-0.2.0.yaml`.

In a follow-up approval on 2026-07-28, byungsker authorized one exact exception
for the protected legacy source: restore `DESIGN.md` from the current protected
source worktree into this delivery with SHA-256
`3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4`.
No other edit, reinterpretation, or expected-hash change is authorized.
