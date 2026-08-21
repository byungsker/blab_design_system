# BLDS Agent Consumption Layer PRD

**Status:** Execution baseline implemented locally; delivery pending authorized Git review
**Date:** 2026-08-09
**Product surface:** BLab Design System shared internal capability
**Accountable teams:** Product Team, Design Team, Engineering Team / Frontend / Design System
**Source of truth:** `contracts/blab.design.yaml`

## 1. Decision summary

BLDS will add an agent-consumption layer on top of its existing machine-readable
design contract. The layer will make tokens, components, states, accessibility
rules, examples, and platform boundaries discoverable through generated
`llms.txt`-style documentation and a read-only local query interface.

Figma will remain a downstream visual mirror. Figma MCP or remote mutation is
not the source of semantic truth and is not part of the first implementation
step.

## 2. Context and evidence

The supplied SEED analysis identifies four connected capabilities:

1. one token source producing multiple platform outputs;
2. LLM-oriented documentation and `llms.txt` entry points;
3. Docs MCP for component, foundation, and guideline lookup; and
4. Figma-layer-to-code mapping contracts.

BLDS already has important foundations:

- `contracts/blab.design.yaml` as an approved machine-readable SSOT;
- deterministic Dart, CSS, Markdown, Figma mapping, and capability generation;
- generated component-state applicability and absence evidence;
- local Figma token mapping with remote mutation explicitly disabled; and
- explicit accessibility, authority, provenance, and claim boundaries.

The current gap is not another visual language. It is the discoverability and
query contract between those existing artifacts and an AI agent. The current
capability manifest also records `distribution-mirrors` as not started.

### Sources

- Supplied article: [당근 SEED 디자인 시스템 - 에이전트가 읽는 디자인 시스템](https://app.notion.com/p/3b572aa850cf81abaf36ff19f7d70b5d?pvs=204)
- [SEED AI integration](https://seed-design.io/ai-integration)
- [SEED Docs MCP](https://seed-design.io/ai-integration/docs-mcp)
- [SEED GitHub repository](https://github.com/daangn/seed-design)
- [BLDS design contract](../contracts/blab.design.yaml)
- [BLDS Figma mirror contract](./design/FIGMA.md)
- [BLDS component-state coverage](../generated/component-state-coverage.yaml)

### Evidence traceability matrix

| Evidence / as-of | Observed fact or bounded signal | Problem/value hypothesis | Requirements | Issue | Metric or gate |
|---|---|---|---|---|---|
| Supplied SEED article, fetched 2026-08-07; article date 2026-08-08 | SEED exposes LLM-oriented docs, Docs MCP, Figma integration, and a single token source | Agent-readable design-system surfaces can reduce discovery ambiguity when generated from authoritative sources | R1–R6 | BLA-8–BLA-13 | Fixture correctness, source traceability, read-only behavior |
| BLDS contract `0.2.0`, effective 2026-07-25 | BLDS already has a machine-readable semantic SSOT and explicit authority order | The next investment should extend consumption, not create another semantic source | R1, R2, R5 | BLA-8, BLA-9, BLA-11 | No semantic duplication; contract validation remains authoritative |
| `generated/blab-capabilities.v1.json`, local worktree as-of 2026-08-09; source checksum recorded in artifact | `distribution-mirrors` is recorded as not started; token and capability generation already exist | A distribution/discovery layer is the bounded missing capability | R2, R3, R6 | BLA-9, BLA-10, BLA-12 | Deterministic generation and query parity |
| BLA-7 / BAR-86 evidence, 2026-08-03 | A real BLDS consumer needed an app-local adapter after a fixed 62px bottom-bar height and missing action semantic label API were observed | A consumer-facing lookup workflow can test whether state/API evidence is easier to discover and whether unsupported behavior is bounded | R3, R4, R6 | BLA-10, BLA-12, BLA-13 | Named pilot baseline and GO/HOLD decision |

The BLA-7 signal is a bounded operational baseline, not a measured time-saved
claim. The pilot will measure lookup steps and grounded-answer outcomes before
making a value claim.

## 3. Problem

An engineer or AI agent currently has to traverse several surfaces to answer a
basic design-system question:

- Which component should I use?
- Which props and states are supported?
- Is a requested state implemented, not applicable, or merely unverified?
- Which semantic and component tokens are authoritative?
- What accessibility and platform constraints apply?
- Which example demonstrates the supported usage?

The evidence exists, but it is distributed across YAML contracts, generated
files, Dart sources, design documents, examples, and tests. This creates three
risks:

1. agents invent unsupported API or state behavior;
2. humans and agents use stale or non-authoritative documentation; and
3. Figma structure and Flutter implementation drift without a component-level
   mapping contract.

## 4. Target users and jobs

### Primary users

- Engineering agents implementing BLDS consumers;
- product engineers using the Flutter package in byungskerlab products;
- Design and Engineering maintainers reviewing component semantics and states.

### Jobs to be done

- Discover the correct component and token without scanning the repository;
- obtain a verified usage example and state boundary;
- distinguish implemented behavior from not-claimed behavior;
- inspect Figma-to-BLDS mapping without granting mutation authority; and
- validate that an agent answer is grounded in the current contract.

### First pilot and baseline

The first pilot is the `Baroguni BLA-7 / BAR-86 BLabBottomBar
accessibility-large remediation` workflow. Today, the evidence shows a
consumer-side adapter was needed after a fixed 62px height and missing action
semantic label API were identified. The pilot will compare the current manual
workflow—consumer issue plus installed BLDS/source lookup—with the local
agent-consumption query workflow.

The pilot will record, for the same ten versioned questions:

- lookup steps and source surfaces used;
- whether the answer identifies the correct component/state/API boundary;
- whether evidence links resolve; and
- whether the answer makes an unsupported claim.

No time-saved or productivity improvement is assumed before this baseline is
collected.

## 5. Goals

### G1 — Make BLDS knowledge agent-readable

Generate a stable index and component/foundation documents from authoritative
contracts and repository evidence.

### G2 — Make component state boundaries explicit

Expose implemented, conditional, not-applicable, and not-claimed states without
allowing documentation to promote unverified behavior into a claim.

### G3 — Provide a safe query surface

Offer local, deterministic, read-only queries first. A Docs MCP adapter may be
added after the local contract and evaluation fixtures are proven.

### G4 — Make design-to-code mapping inspectable

Define an explicit Figma component/layer → BLDS component → Flutter public type
→ props/states → token IDs mapping.

### G5 — Preserve BLDS authority and delivery boundaries

Keep the design contract as semantic SSOT, keep Figma downstream, and preserve
the existing limits around remote mutation, production conformance, and
release/publication authority.

## 6. Non-goals

- Replacing `contracts/blab.design.yaml` with Figma or an MCP server;
- generating production-ready application code directly from Figma;
- adding React, iOS, Android, Lynx, or other platform packages before two real
  product needs and an explicit design/engineering decision;
- introducing new visual primitives or changing existing Blab semantics;
- migrating consumer applications in this PRD;
- remote Figma writes, publishing, deployment, or release activation; and
- making accessibility or visual-conformance claims beyond current evidence.

## 7. Product architecture

```text
contracts/blab.design.yaml
        │
        ├── existing deterministic token/component outputs
        │
        ├── component registry + state/evidence index
        │       ├── llms.txt / llms-full.txt
        │       └── component and foundation documents
        │
        ├── local read-only query CLI + evaluation fixtures
        │       └── optional Docs MCP adapter
        │
        └── Figma mapping contract / read-only integration surface

Flutter components, examples, tests, and Figma remain downstream consumers.
```

## 8. Scope and requirements

### R1 — Component registry contract

Create a generated or contract-backed registry for every component represented
by the existing component-state coverage. Each entry must include:

- stable component ID and public type;
- source path and example path;
- purpose and usage boundary;
- props or configuration axes;
- implemented, conditional, not-applicable, and not-claimed states;
- token references;
- accessibility requirements;
- platform-specific constraints; and
- evidence links.

### R2 — Agent-readable documentation

Generate:

- `llms.txt` as a concise discovery index;
- `llms-full.txt` as a bounded complete index;
- per-component documents;
- foundation/token documents;
- accessibility and state-boundary documents; and
- explicit generated-source checksums and source references.

The generator must fail or report drift when referenced contracts, examples, or
evidence paths are missing.

Regeneration is owned by Engineering Team / Frontend / Design System and is
triggered by changes to the canonical contract, registry schema, component-state
coverage, examples, accessibility policy, or Figma mapping. Generated outputs
must be checked by the repository verification path and must not be manually
edited as a repair strategy.

### R3 — Local read-only query interface

Provide deterministic queries for:

- component listing and lookup;
- token lookup and resolved modes;
- state matrix lookup;
- accessibility rule lookup;
- example lookup; and
- platform exception lookup.

The interface must not mutate source files, Figma, consumer repositories, or
external accounts.

### R4 — Evaluation fixtures

Create a small question/answer fixture set covering discovery, state support,
token resolution, accessibility, examples, and unsupported-state handling.

The fixtures must prove that the query surface returns “not claimed” or
“not applicable” when the repository does not support a requested behavior.

### R5 — Figma-to-BLDS mapping contract

Define a repository-local, read-only mapping for a non-empty first reviewed set:
`BLab/BottomBar` plus its pilot-relevant `selected`, `unselected`, `pressed`,
`focus`, and action states. The mapping must identify component, variant, state,
public Flutter type, props, and token IDs. It must distinguish an absent mapping
from a verified mapping. Additional components require an explicit selection
rule and evidence status.

### R6 — Optional Docs MCP adapter

After R1–R5 pass and a pilot `GO` decision, expose the local query contract
through a Docs MCP adapter.
The adapter must preserve the same schemas, read-only boundary, versioning,
error behavior, and evidence links as the local interface.

### R6 implementation boundary

The first adapter is a repository-local JSON-RPC stdio process:

```text
dart run tool/agent_docs_mcp.dart
```

It exposes `initialize`, `tools/list`, and `tools/call` for three bounded tools:
`list_components`, `list_tokens`, and `query_design_system`. The latter two
delegate to the same `AgentQueryEngine` used by `tool/query_agent.dart`, so the
local CLI and MCP results share the same generated registry, source contracts,
errors, and evidence. Token queries return resolved values for all four
repository-approved modes and label compatibility-preserved CSS/Dart mappings
without promoting them to normalized semantics. The process has no network
client, write API, Figma credential, or consumer-repository path. Host
installation/configuration beyond this local stdio contract is intentionally
unsupported until separately evidenced.

## 9. Sequencing and roadmap

The work is intentionally sequential:

1. Registry and evidence schema;
2. generated agent-readable docs;
3. local query CLI and evaluation fixtures;
4. Figma-to-BLDS mapping contract;
5. pilot adoption gate and separate decision on MCP/multi-platform expansion;
6. optional Docs MCP adapter only after a pilot `GO` decision.

No calendar commitment or target release is assigned by this PRD.

## 10. Acceptance criteria

- Every currently covered BLDS component has a registry entry or an explicit
  documented exclusion.
- Every generated document points back to an authoritative contract or
  evidence path.
- Generated outputs are deterministic and included in the repository
  verification path.
- At least ten evaluation fixtures cover normal lookup, state boundaries,
  accessibility, token lookup, examples, and unsupported behavior.
- The ten fixtures are versioned, each has an expected answer and authoritative
  evidence path, and each is scored with the same pass/fail rules.
- The first pilot produces a `GO` or `HOLD` decision before Docs MCP work
  begins. `GO` requires at least 9/10 fixtures passing, zero critical
  unsupported-state claims, and all evidence links resolving. `HOLD` applies
  otherwise.
- Unsupported or unverified behavior is never presented as implemented.
- The local query interface is read-only and has explicit malformed/missing
  input behavior.
- Figma mapping entries are distinguishable between verified, absent, and
  not-yet-reviewed.
- The first mapping set is non-empty and includes `BLab/BottomBar` plus the
  pilot-relevant states named in R5.
- No Figma mutation, consumer mutation, release, deployment, or publication is
  performed as part of this scope.

## 11. Success and kill metrics

### Success signals

- 100% of registry entries resolve to existing source/evidence paths;
- 100% of generated indexes pass drift and schema validation;
- the fixed pilot gate passes at least 9/10 fixtures with zero critical
  unsupported-state claims;
- unsupported-state fixtures produce bounded non-claims; and
- at least one real BLDS consumer workflow uses the local query surface without
  manual repository-wide searching.

### Hold/kill thresholds

- If two consecutive verification runs report registry or generated-document
  drift, hold MCP work and repair the generator/contract boundary.
- Maintenance cost is measured per regeneration cycle as manual repair count,
  unresolved drift count, verification duration, and critical claim defects.
  The regeneration owner and trigger are recorded with the implementation.
- Hold MCP work when two consecutive cycles have unresolved drift, any manual
  edit to generated output, more than one maintainer repair per cycle, or any
  critical unsupported-state claim/read-only violation.
- If the first consumer pilot cannot demonstrate repeatable value, keep the
  output as repository-local generated documentation and do not expand to
  remote MCP or new platform packages.
- If a requested capability requires a new shared primitive without two real
  product needs, defer it or request an explicit exception.

## 12. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Generated docs become a second SSOT | Generate only from canonical contracts and include checksums |
| Agents over-trust Figma-generated code | Label Figma as downstream reference; require human/engineering verification |
| Unsupported states become accidental promises | Reuse state applicability and absence-evidence classifications |
| MCP introduces mutation or credential risk | Local read-only interface first; no external writes |
| Scope expands into a multi-platform rewrite | Apply Rule of Two and require separate evidence |
| Existing dirty repository changes are overwritten | Additive files only; preserve unrelated worktree changes |

## 13. Authority and review gates

- Product Team owns the PRD, sequencing, and acceptance framing.
- Design Team owns semantics, token meaning, accessibility policy, and Blab
  mapping.
- Engineering owns schemas, generators, query implementation, tests, and
  verification.
- Figma remote mutation, release, publication, deployment, and consumer
  migration require separate explicit authority.
- Product decision review is required before implementation begins.

## 14. Open questions

1. Resolved for the first slice: use a Dart-first local query engine with a
   language-neutral JSON output and JSON-RPC stdio adapter.
2. Resolved for the first slice: start with the non-empty `BLab/BottomBar`
   mapping set and its pilot-relevant states.
3. Resolved for the first slice: check generated outputs into the repository
   and enforce `--check` drift detection in the verification path.
4. The first adoption pilot is the BLA-7 / BAR-86 Baroguni bottom-bar
   accessibility-large remediation workflow.

Questions 1–3 do not block writing the initial registry and documentation
contracts; they block broader MCP and multi-platform commitments only.

## 15. Implementation status

The first local execution cycle is complete:

- BLA-8 registry and validator: implemented;
- BLA-9 generated `llms.txt`, `llms-full.txt`, and component/foundation docs:
  implemented;
- BLA-10 read-only query CLI and ten-fixture evaluator: implemented;
- Token discovery and lookup now expose 146 normalized tokens plus 273
  compatibility mappings with explicit status and evidence boundaries;
- BLA-11 BottomBar-first Figma mapping and validator: implemented;
- BLA-13 pilot: `GO` with 10/10 fixtures, 0 critical failures, and 18 evidence
  paths resolved; multi-platform expansion deferred without Rule-of-Two evidence;
- BLA-12 local Docs MCP adapter: implemented after the pilot `GO` gate.

The canonical issues remain `In Progress` until an authorized PR is merged.
