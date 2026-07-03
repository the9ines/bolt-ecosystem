# SRE Validation Protocol

> **Status:** Normative. Extracted verbatim 2026-07-03 from
> `docs/GOVERNANCE_WORKSTREAMS.md` ("SRE Validation Protocol", codified 2026-03-29).

All validation and audit slices MUST follow this protocol.

## Result Classification

Every finding/test result must be classified as exactly one of:

| Classification | Meaning | Can we claim it works? |
|---------------|---------|----------------------|
| **CONFIRMED** | Fresh runtime or automated evidence exists | Yes |
| **FALSIFIED** | Tested and failed | No — fix required |
| **BLOCKED** | Cannot test due to environmental/credential constraint | No — document the blocker |
| **INSUFFICIENT EVIDENCE** | Not tested, or only stale/unit evidence | No — qualify any claims |

## Evidence Tiers

Distinguish explicitly:

| Tier | Description | Confidence |
|------|-------------|-----------|
| **Runtime-validated** | Real process/browser/device test with fresh evidence | Highest |
| **Automated-test-validated** | CI/unit/integration test suite passes | High for code path, medium for runtime |
| **Compile-validated** | Builds without error | Low — proves linkage, not behavior |
| **Doc/governance truth** | Written in docs | None — docs can be stale |

## Operational Rules

1. State the hypothesis before running anything.
2. Define success and failure signals before executing.
3. Prefer the smallest reversible validation step first.
4. Do not change architecture while validating.
5. Preserve known-good paths — do not destabilize validated paths while testing others.
6. If blocked, stop and document the blocker. Do not hand-wave.
7. No optimistic wording. Evidence only.
