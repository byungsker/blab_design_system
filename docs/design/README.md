# BLab Design Docs

## Purpose
This directory contains the design documentation for BLab Design System.
The authoritative machine-readable source is `../../contracts/blab.design.yaml`.
Use these documents as Design-owned explanatory guidance; where a legacy
statement conflicts with the approved contract, the contract wins.

## Documents
- `BRAND.md` — BLab visual identity, atmosphere, and design philosophy
- `TOKENS.md` — semantic tokens for color, typography, spacing, radius, elevation, and overlays
- `COMPONENTS.md` — shared component rules and styling expectations
- `PATTERNS.md` — multi-component layout and UI flow patterns
- `MOTION.md` — animation, transition, and feedback rules
- `A11Y.md` — accessibility requirements and constraints
- `DO_DONT.md` — practical guardrails with strong recommendations and anti-patterns

## Suggested reading order
1. `BRAND.md`
2. `TOKENS.md`
3. `COMPONENTS.md`
4. `PATTERNS.md`
5. `MOTION.md`
6. `A11Y.md`
7. `DO_DONT.md`

## How to use these docs
- Treat the repository-root `DESIGN.md` as an unreconciled legacy draft until
  Design reviews its protected pre-existing changes against the contract.
- Use these documents to guide UI decisions before introducing new component styles.
- Prefer updating the system documentation over creating one-off visual exceptions.
