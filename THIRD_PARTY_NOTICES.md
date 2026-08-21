# Third-party notices and provenance boundaries

This repository is locally prepared but unreleased. This notice inventories
observed third-party material and capability evidence; it does not authorize
publication, establish the project copyright holder, prove non-derivation, or
replace review by an authorized human or qualified counsel.

## Repository test fixtures

The following files are used only by Phase 4 Flutter tests and are not declared
as runtime assets in `pubspec.yaml`:

- Noto Sans KR and Noto Sans Arabic — SIL Open Font License 1.1.
- Material Icons — Creative Commons Attribution 4.0 International.
- Cupertino Icons — MIT.

Exact source revisions, file and license SHA-256 identities, purposes, and
license copies are recorded in
[`test/assets/fonts/THIRD_PARTY_NOTICES.md`](test/assets/fonts/THIRD_PARTY_NOTICES.md)
and `contracts/legal/rights-provenance.yaml`.

## Remote CSS font references

Every repository CSS path containing a remote `@import` is listed below:

| Path | Current dry-run package disposition | Role |
| --- | --- | --- |
| `docs/design/tokens.css` | Excluded by the existing `docs/` package rule | Design-token authoring source and optional browser CSS reference; not a runtime asset |
| `contracts/compatibility/baselines/head-ee78fbe.tokens.css` | Excluded by the candidate compatibility-baseline package rule | Immutable compatibility baseline; not runtime CSS and not production activation evidence |

Both files contain imports for Pretendard Variable v1.3.9 through jsDelivr and
JetBrains Mono weights 400, 500, and 600 through Google Fonts. Google Fonts CSS
may in turn reference font binaries from `fonts.gstatic.com`; exact returned
URLs and bytes are not pinned by this repository.

Merely storing or packaging either CSS file issues no request. Remote requests
would occur only if a consumer explicitly loads that CSS and its imports.
Nothing in Phase 5 loads either file at runtime or authorizes production
activation. Both are absent from the current candidate archive; that exclusion
and exact package composition remain unapproved human/TDC decisions.

Both font upstreams are observed as OFL-1.1, but provider terms, required
notices, production activation, and the production font strategy remain
unresolved. Phase 5 does not authorize those remote requests or distribution.

## Astryx method study

Astryx 0.1.3 was studied as a capability and operating-method source. The
implementation owner states, without a signed attestation, that the intended
scope was methods and contract patterns only. Copy, derivation, value, identity,
and distribution facts remain unknown pending signed, scope-bound attestation.
Registry integrity, the
`v0.1.3` tag at commit
`6d57c8d9126b768ee6fdb90e74e060a8e3494e8e`, package license metadata, and
the observed root notice state are recorded in
`contracts/legal/astryx-0.1.3-evidence.yaml`. That evidence and a repository
scan do not prove non-derivation.

## Unresolved rights gates

Publication remains blocked pending the copyright-holder and MIT notice
authority, the historical `baro-app` transfer or relicense chain, contributor
aliases and restrictions, canonical repository custody, exact package
composition, non-derivation and Figma/asset origin attestations, production font
strategy, jurisdiction/channel decisions, and final human release authority.
