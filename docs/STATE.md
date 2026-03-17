---
Snapshot Derived From:
- sdk-v0.5.32-tstream1-wasm-policy-wiring (2d4792f)
- daemon-v0.2.38-relarch1-multiarch-matrix (ab56606)
- v3.0.87-domain-rename (69ec25c)
- localbolt-v1.0.34-domain-rename (c8f9fdc)
- localbolt-app-v1.2.22-domain-rename (beb8891)
- ecosystem-v0.1.94-relarch1-multiarch-matrix
Last Refreshed By: REL-ARCH1 — multi-arch daemon build/package matrix (ecosystem-v0.1.94)
---

# Bolt Ecosystem — State

> **Last Updated:** 2026-03-17 (RUSTIFY-BROWSER-CORE-1 RB1 DONE — policy lock, PM-RB-01–05 approved.)
> **Authority:** Informational. Updated after each tagged release or H-phase completion.

---

## H-Phase Truthful Ledger

Status labels: **DONE-MERGED** | **DONE-NOT-MERGED** | **IN-PROGRESS** | **NOT-STARTED**

| Phase | Description | Status | Repo(s) | Tag(s) | Commit(s) |
|-------|-------------|--------|---------|--------|-----------|
| H0 | Protocol enforcement posture | DONE-MERGED | bolt-ecosystem/docs/ | N/A | N/A |
| H1 | Signal server trust-boundary hardening | DONE-MERGED | localbolt-v3 | `v3.0.59-signal-hardening`, `v3.0.62-h1-mainline-merge` | `ac5110c`, `7571d35` (merge) |
| H2 | WebRTC enforcement compliance | DONE-MERGED | bolt-core-sdk | `sdk-v0.5.0-h2-webrtc-enforcement`, `sdk-v0.5.3-h2-h3-mainline` | `b4ce544`, `3f66da9` (mainline tag) |
| H3 | Cross-implementation golden vectors (SDK) | DONE-MERGED | bolt-core-sdk | `sdk-v0.5.1`, `sdk-v0.5.3-h2-h3-mainline` | `9d8617d`, `3f66da9` (mainline tag) |
| H3 | Cross-implementation golden vectors (daemon) | DONE-MERGED | bolt-daemon | `daemon-v0.2.5-h3-golden-vectors`, `daemon-v0.2.10-h3-h6-mainline` | `3751118`, `0b16392` (merge) |
| H3.1 | Hermetic vectors (daemon) | DONE-MERGED | bolt-daemon | `daemon-v0.2.8-h3.1-vectors-hermetic`, `daemon-v0.2.10-h3-h6-mainline` | `e6c8851`, `0b16392` (merge) |
| H4 | Daemon panic surface elimination | DONE-MERGED | bolt-daemon | `daemon-v0.2.6-h4-panic-elimination`, `daemon-v0.2.10-h3-h6-mainline` | `678c808`, `0b16392` (merge) |
| H5 | Daemon downgrade resistance + enforcement validation | DONE-MERGED | bolt-daemon | `daemon-v0.2.7-h5-downgrade-validation`, `daemon-v0.2.10-h3-h6-mainline` | `257c4a4`, `0b16392` (merge) |
| H5-v3 | localbolt-v3 TOFU/SAS identity + pinning wiring | DONE-MERGED | localbolt-v3 | `v3.0.61-h5v3-tofu-sas-pinning` | `532d391` |
| H6 | CI enforcement across repos | DONE-MERGED | bolt-core-sdk, bolt-daemon, bolt-rendezvous, localbolt-v3 | See below | See below |

### Ledger Notes

- **H0** is filesystem-only (bolt-ecosystem root is not a versioned git repo). Status DONE-MERGED by convention.
- **H1** merged into localbolt-v3 main via `--no-ff` at merge train STOP 1. Forward tag `v3.0.62-h1-mainline-merge` on main.
- **H2 + H3 (SDK)** merged into bolt-core-sdk main via `--no-ff` at merge train STOP 2. Forward tag `sdk-v0.5.3-h2-h3-mainline` on main. H3 test files received `cargo fmt` fixup (pre-H6 formatting).
- **H3/H3.1/H4/H5 (daemon)** merged into bolt-daemon main via `--no-ff` at merge train STOP 3. Forward tag `daemon-v0.2.10-h3-h6-mainline` on main.
- **H5-v3** was already on localbolt-v3 main (commits `532d391` and `1e659c3`) before the merge train.
- **H6** was already on main for SDK, rendezvous, and localbolt-v3. Daemon H6 (`398a63d`) was on `feature/h5-downgrade-validation` and merged via STOP 3.
- All feature branches preserved (not deleted).

---

## Merge Train Status

**Status: COMPLETE** (2026-02-25)

| Step | Action | Repo | Result |
|:---:|--------|------|--------|
| 0 | Preflight — sync all repos, push tags to origin | All | PASS |
| 1 | Merge `feature/h1-signal-hardening` → main | localbolt-v3 | PASS — `v3.0.62-h1-mainline-merge` (`7571d35`) |
| 2 | Merge `feature/h2-webrtc-enforcement` + `feature/h3-golden-vectors` → main | bolt-core-sdk | PASS — `sdk-v0.5.3-h2-h3-mainline` (`3f66da9`) |
| 3 | Merge `feature/h5-downgrade-validation` → main | bolt-daemon | PASS — `daemon-v0.2.10-h3-h6-mainline` (`0b16392`) |
| 4 | Verify H6 tag on main | bolt-rendezvous | PASS — `rendezvous-v0.2.1-h6-ci-enforcement` points at HEAD |
| 5 | Governance ledger updates | bolt-ecosystem/docs/ | PASS — this update |

---

## Audit Finding Details (Resolved)

### H5-v3 — TOFU/SAS Wiring + Identity/Pin Store (Security + Correctness)

**Repo:** localbolt-v3
**Status:** DONE-MERGED (tag: `v3.0.61-h5v3-tofu-sas-pinning`, commit: `532d391`)

TOFU identity pinning and SAS verification wired into localbolt-v3 product UI with IndexedDB persistence, verification state bus, and transfer gating. 22 tests.

### H6 — CI Enforcement Across Repos (Operational)

**Repos:** bolt-core-sdk, bolt-daemon, bolt-rendezvous, localbolt-v3
**Status:** DONE-MERGED

| Repo | Tag | Commit | On Main |
|------|-----|--------|:---:|
| bolt-core-sdk | `sdk-v0.5.2-h6-ci-enforcement` | `476881a` | Yes |
| bolt-daemon | `daemon-v0.2.9-h6-ci-enforcement` | `398a63d` | Yes (via merge) |
| bolt-rendezvous | `rendezvous-v0.2.1-h6-ci-enforcement` | `6f48ba7` | Yes |
| localbolt-v3 | `v3.0.60-h6-ci-enforcement` | `3b12f73` | Yes |

---

## S-Phase Ledger

| Phase | Description | Status | Repo(s) | Tag(s) | Commit(s) |
|-------|-------------|--------|---------|--------|-----------|
| S0 | Canonical hardened rendezvous | DONE-MERGED | bolt-rendezvous, localbolt-v3 | `rendezvous-v0.2.2-s0-canonical-lib-verified`, `v3.0.63-s0-canonical-rendezvous` | `fd8d3df`, `2963539` |
| S1 | Core protocol conformance harness (Rust SDK) | DONE-MERGED | bolt-core-sdk | `sdk-v0.5.4-s1-conformance-harness` | `cced058` |
| S2 | Transfer performance program | IN-PROGRESS (S2A DONE) | bolt-core-sdk | `sdk-v0.5.5-s2-policy-skeleton`, `sdk-v0.5.6-s2-policy-contract-tests`, `transport-web-v0.6.1-s2b-instrumentation`, `sdk-v0.5.31-s2a-transfer-policy-substantive` | `31bdc0b`, `39ed6dc`, `02e36b1`, `c67bd68` |

## Governance Phases

| Phase | Description | Status | Repo(s) | Commit(s) |
|-------|-------------|--------|---------|-----------|
| CONFORMANCE-1R | Spec conformance matrix + PR review gate | DONE | bolt-protocol, bolt-ecosystem | bolt-protocol: `69a0907`, bolt-ecosystem: see below |
| CONFORMANCE-2R | Enforceable conformance matrix with minimum coverage | DONE | bolt-protocol, bolt-ecosystem | bolt-protocol: `81171c5` (`v0.1.1-spec`), bolt-ecosystem: `0b68fe2` (`ecosystem-v0.1.1-conformance-2r`) |
| PROTO-HARDEN-1 | Handshake invariants codified in spec (§15, 12 invariants) | DONE | bolt-protocol, bolt-ecosystem | bolt-protocol: `ee024d7` (`v0.1.2-spec`) |
| PROTO-HARDEN-1R1 | Canonical error registry unification in §10 (22 codes) | DONE | bolt-protocol, bolt-ecosystem | bolt-protocol: `6a6de3f` (`v0.1.3-spec`) |

## P-Phase Ledger (Post-H Hardening)

| Phase | Description | Status | Repo(s) | Tag(s) | Commit(s) |
|-------|-------------|--------|---------|--------|-----------|
| P1 | Inbound error validation hardening | DONE | bolt-daemon | `daemon-v0.2.12-p1-inbound-error-validation` | `8c45819` |

---

## C-Stream Ledger (Application Convergence + Session UX Hardening)

| Phase | Description | Status | Repo(s) | Tag(s) | Commit(s) |
|-------|-------------|--------|---------|--------|-----------|
| C0 | Policy lock — verification UX decision | DONE | localbolt-v3 | `v3.0.71-localbolt-core-c2` | `aa9e40e` |
| C1 | localbolt-core scaffold + ARCH-08 disposition | DONE | localbolt-v3 | `v3.0.71-localbolt-core-c2` | `aa9e40e` |
| C2 | Extract canonical runtime from v3 baseline | DONE | localbolt-v3 (`@the9ines/localbolt-core`) | `v3.0.71-localbolt-core-c2` | `aa9e40e` |
| C3 | Migrate localbolt-v3 consumer | DONE | localbolt-v3 | `v3.0.71-localbolt-core-c2` | `aa9e40e` |
| C4 | Migrate localbolt consumer | DONE | localbolt | `localbolt-v1.0.21-c4-localbolt-core`, `localbolt-v1.0.22-c6-core-guards` | `ed2d671` |
| C5 | Migrate localbolt-app web consumer | DONE | localbolt-app | `localbolt-app-v1.2.4-c5-localbolt-core`, `localbolt-app-v1.2.5-c6-core-guards` | `d1761e9` |
| C6 | Drift guards + upgrade protocol | DONE | localbolt-v3, localbolt, localbolt-app | `localbolt-v1.0.24-c6-hardening`, `localbolt-app-v1.2.7-c6-hardening`, `v3.0.73-c6-hardening` | Batch 5: upgrade tooling, v3 drift CI, runbook |
| C7 | Session UX race-hardening | DONE | localbolt-v3 (localbolt-core), localbolt, localbolt-app | `v3.0.74-c7-closure`, `localbolt-v1.0.23-c7-tofu-wiring`, `localbolt-app-v1.2.6-c7-tofu-wiring` | `b867426`, `1bcb7b8`, `e902186` |

---

## D-Stream Ledger (CI Stabilization + Package Auth Migration)

> **Codified:** ecosystem-v0.1.60-d-stream-1-codify (2026-03-05)
> **Primary success gate:** Netlify deploy reliability (PAT-independent public package installs)
> **Canonical spec:** `docs/GOVERNANCE_WORKSTREAMS.md` (Workstream D section)

| Phase | Description | Status | Repo(s) | Tag(s) | Commit(s) |
|-------|-------------|--------|---------|--------|-----------|
| D0 | Policy lock | **DONE** | bolt-ecosystem | ecosystem-v0.1.62-d05-d3-registry-migration | — |
| D0.5 | @the9ines npmjs scope verification | **DONE** | bolt-ecosystem | ecosystem-v0.1.62-d05-d3-registry-migration | — |
| D1 | Failure triage + classification | **DONE** | localbolt-v3, bolt-core-sdk, localbolt, localbolt-app | ecosystem-v0.1.61-d1-d4-netlify-unblock | — |
| D2 | CI stabilization (evidence-driven) | NOT-STARTED | per D1 evidence | — | — |
| D3 | Package auth/registry migration | **DONE** | bolt-core-sdk, localbolt-v3 | ecosystem-v0.1.62-d05-d3-registry-migration | See below |
| D4 | Netlify hardening (critical path) | **DONE** | localbolt-v3, localbolt, localbolt-app | `v3.0.76-d4-npmjs-cutover`, `v3.0.77-d4-netlify-build-fix`, `localbolt-v1.0.25-d4-npmjs-cutover`, `localbolt-app-v1.2.8-d4-npmjs-cutover` | `ef0543e`, `0746275`, `9bb3c38`, `55c3e17` |
| D5 | Drift guards + enforcement | **DONE** | localbolt-v3, localbolt, localbolt-app | `v3.0.78-d5-registry-guards`, `localbolt-v1.0.26-d5-registry-guards`, `localbolt-app-v1.2.9-d5-registry-guards` | `fec153b`, `76ae224`, `93afc2c` |
| D6 | Burn-in + closure | NOT-STARTED (UNBLOCKED) | all affected | — | — |

### D-Stream Policy Decisions (D0, locked at codification)

1. Public deploy-critical `@the9ines` packages MUST install without GitHub PAT.
2. GitHub Packages MAY remain for private artifacts only.
3. Netlify builds MUST succeed with standard project-managed env/config (no personal PAT reliance).
4. npmjs.org publication approved for deploy-critical public packages.

### D-Stream Deploy-Critical Packages (seed set, verify in D1)

| Package | Owner Repo |
|---------|-----------|
| `@the9ines/bolt-core` | bolt-core-sdk |
| `@the9ines/bolt-transport-web` | bolt-core-sdk |
| `@the9ines/localbolt-core` | localbolt-v3 |

---

### Ledger Notes

- **C0** DONE — PM policy decision: `unverified` peer status blocks file transfer. Codified in `v3.0.70-session-hardening-cpre2`. Runtime, tests, and docs aligned. Q8 resolved.
- **C1** DONE — ARCH-08 resolved via non-violating location: `localbolt-v3/packages/localbolt-core` (inside existing workspace). No waiver needed. Package: `@the9ines/localbolt-core@0.1.0`.
- **C2** DONE — Extracted session state machine, verification state bus, transfer gating policy, and generation guards into `@the9ines/localbolt-core`. 41 core tests. Source: `v3.0.71-localbolt-core-c2` (`aa9e40e`).
- **C3** DONE — localbolt-v3 consumer migrated in same commit as C2. Web imports from `@the9ines/localbolt-core` via workspace dependency. 59 web tests (unchanged). Session-hardening tests kept in web as consumer wiring integration test.
- **C4** DONE — localbolt consumer migrated to `@the9ines/localbolt-core@0.1.0`. Tags: `localbolt-v1.0.21-c4-localbolt-core`, `localbolt-v1.0.22-c6-core-guards` (`ed2d671`).
- **C5** DONE — localbolt-app web consumer migrated to `@the9ines/localbolt-core@0.1.0`. Tags: `localbolt-app-v1.2.4-c5-localbolt-core`, `localbolt-app-v1.2.5-c6-core-guards` (`d1761e9`).
- **C6** DONE — Batch 5 completed: `upgrade-localbolt-core.sh` (check + write modes) added to localbolt and localbolt-app; `check-core-drift.sh` added to localbolt-v3 CI (`packages/localbolt-web/src`); workspace exemption documented (v3 is origin, pin/single-install not applicable); manual drift runbook in `docs/LOCALBOLT_CORE_DRIFT_RUNBOOK.md`.
- **C7** DONE — Session UX race-hardening closed. Canonical evidence in `@the9ines/localbolt-core` (`v3.0.74-c7-closure`, `b867426`): rapid 7-cycle connect/reset monotonicity + late verification callback rejection. Combined with prior: session state machine (5-phase), generation guards, A→B→C isolation, stale signal rejection, phase guards, transfer/verification cleanup. Consumer wiring: localbolt 300 tests (`localbolt-v1.0.23-c7-tofu-wiring`, `1bcb7b8`), localbolt-app 11 tests (`localbolt-app-v1.2.6-c7-tofu-wiring`, `e902186`). No runtime changes needed — existing code already handles all C7 scenarios.
- **Session hardening (pre-C7):** `v3.0.70-session-hardening-cpre2` (`cac5e4a`) delivered session orchestration layer + race hardening. Now lives in `@the9ines/localbolt-core`. Transfer gating policy codified as `isTransferAllowed()`.
- **localbolt-core** located at `localbolt-v3/packages/localbolt-core`. Tags follow localbolt-v3 convention (`v3.0.<N>-<slug>`). Published as `@the9ines/localbolt-core@0.1.0` to GitHub Packages (`v3.0.72-localbolt-core-publish`, `7cb8d8d`). All three consumers now resolve via npm registry (not workspace-only).

---

## C-STREAM-R1 Ledger (UI/State Regression Recovery)

> **Status:** DONE
> **Scope:** localbolt-v3 app-layer UX/state reliability (pause/stop, disconnect/reconnect, trust UI)

| Phase | Description | Status | Repo(s) | Tag(s) | Commit(s) |
|-------|-------------|--------|---------|--------|-----------|
| C-STREAM-R1 | UI/state regression recovery (generation guards, snapshot fix, trust truth table) | **DONE** | localbolt-v3 | `v3.0.80-c-stream-r1-ui-state-fix` | `9f3546e` |

> **Runner-context note:** `faq.test.ts` and `app.test.ts` appear to fail when `npx vitest run` is invoked from the monorepo root (missing workspace config → wrong env + unresolved aliases). When run in-package (`packages/localbolt-web`), all 70 tests pass. This is a runner-context/config artifact, not a product regression or residual.
>
> **Tech debt (LOW):** Consider adding `vitest.workspace.ts` at `localbolt-v3` root to prevent root-run false failures.

---

## S-STREAM-R1 Ledger (Security/Foundation Recovery)

> **Codified:** ecosystem-v0.1.65-s-stream-r1-codify (2026-03-06)
> **R1-0:** ecosystem-v0.1.66-s-stream-r1-r1.0-baseline (2026-03-06)
> **R1-1:** ecosystem-v0.1.67-s-stream-r1-r1.1-disposition (2026-03-06)
> **Status:** **DONE** (S-STREAM-R1 CLOSED)

| Phase | Description | Status | Repo(s) | Tag(s) | Commit(s) |
|-------|-------------|--------|---------|--------|-----------|
| R1-0 | Baseline evidence + risk classification | **DONE** | bolt-daemon, localbolt-v3, localbolt, localbolt-app, bolt-core-sdk | `ecosystem-v0.1.66-s-stream-r1-r1.0-baseline` | `1feddff` |
| R1-1 | Architecture decision (evidence-informed) | **DONE** | bolt-ecosystem | `ecosystem-v0.1.67-s-stream-r1-r1.1-disposition` | `c49d86f` |
| R1-2 | Daemon remediation + security tests | **DONE-NO-ACTION** | — | — | — |
| R1-3 | Product crypto-path convergence | **DONE-NO-ACTION** | — | — | — |
| R1-4 | Security-focused product test lift | **DONE** | localbolt, localbolt-app, localbolt-v3 | See R1-4 evidence below | `fc360c5`, `71c3181`, `31046ac` |
| R1-5 | Validation gates | **DONE** | localbolt, localbolt-app, localbolt-v3 | `ecosystem-v0.1.69-s-stream-r1-closeout` | See R1-5 evidence below |
| R1-6 | Governance reconciliation + closure | **DONE** | bolt-ecosystem | `ecosystem-v0.1.69-s-stream-r1-closeout` | See this commit |

### R1-5 Validation Evidence

| Repo / Package | Gate | Result | Detail |
|----------------|------|--------|--------|
| localbolt | Tests | **PASS** | 319/319 (Vitest), 15 files |
| localbolt | Build | **PASS** | vite build, 501ms |
| localbolt-app | Tests | **PASS** | 32/32 (Vitest), 3 files |
| localbolt-app | Build | **PASS** | vite build, 466ms |
| localbolt-app | Coverage | **PASS** | 100% all metrics (thresholds: 90/90/80/90) |
| localbolt-v3 (core) | Tests | **PASS** | 50/50 (Vitest), 3 files |
| localbolt-v3 (core) | Build | **PASS** | tsc, 0 errors |
| localbolt-v3 (web) | Tests | **PASS** | 59/59 (Vitest), 4 files |
| localbolt-v3 (web) | Build | **PASS** | vite build, 518ms |
| **Total** | | **9/9 PASS** | 460 tests, 0 failures |

### R1-5 Tests-Only Verification (R1-4 commits)

| Repo | Commit | Files Changed | Runtime Modified? |
|------|--------|---------------|:-:|
| localbolt | `fc360c5` | `__tests__/security-session-integrity.test.ts` (+378) | NO |
| localbolt-app | `71c3181` | `__tests__/security-session-integrity.test.ts` (+416) | NO |
| localbolt-v3 | `31046ac` | `__tests__/security-reconnect-integrity.test.ts` (+199) | NO |

Conclusion: All R1-4 commits are strictly tests-only. No D-stream regression. No runtime drift vs R1-1 dispositions.

### R1-5 Tag Integrity (all verified on origin)

| Repo | Code Tag | Commit | Docs Tag | Commit |
|------|----------|--------|----------|--------|
| localbolt | `localbolt-v1.0.27-s-stream-r1-r1.4-security-test-lift` | `fc360c5` | `localbolt-v1.0.27-s-stream-r1-r1.4-security-test-lift-docs` | `490f0cd` |
| localbolt-app | `localbolt-app-v1.2.10-s-stream-r1-r1.4-security-test-lift` | `71c3181` | `localbolt-app-v1.2.10-s-stream-r1-r1.4-security-test-lift-docs` | `bc0ee2a` |
| localbolt-v3 | `v3.0.79-s-stream-r1-r1.4-security-test-lift` | `31046ac` | `v3.0.79-s-stream-r1-r1.4-security-test-lift-docs` | `1871089` |
| bolt-ecosystem | `ecosystem-v0.1.68-s-stream-r1-r1.4-security-test-lift` | `a6bf7a0` | — | — |

All 7 tags confirmed present on origin.

### S-STREAM-R1 Residual

- **Rust SDK reconnect/race tests (LOW):** Deferred — out of R1-4 product scope, not a critical/high risk.

### Ledger Notes

- **R1-0 DONE** (2026-03-06): Baseline evidence + risk classification complete.
- **R1-1 DONE** (2026-03-06): Dispositions locked. SA1 Path C (closure stands). R1-2 DONE-NO-ACTION (no daemon architecture risk). R1-3 DONE-NO-ACTION (products already SDK-mediated). R1-4 confirmed as primary remaining scope.
- **R1-4 DONE** (2026-03-06): Security-focused product test lift complete. All R1-0 gaps covered. See R1-4 evidence section below.
- Full specification in `docs/GOVERNANCE_WORKSTREAMS.md` (S-STREAM-R1 section).

### R1-0 Baseline Metrics (command-backed, 2026-03-06)

| Repo | Package/Feature | Tests | Build | Notes |
|------|----------------|------:|:-----:|-------|
| bolt-daemon | default (`cargo test`) | 318 | PASS | 0 failed, 0 ignored |
| bolt-daemon | test-support (`cargo test --features test-support`) | 398 | PASS | 3 ignored (E2E) |
| bolt-core-sdk | TS bolt-core (`npm test`) | 120 | PASS | 12 test files |
| bolt-core-sdk | TS transport-web (`npm test`) | 253 | PASS | 25 test files |
| bolt-core-sdk | Rust default (`cargo test`) | 97 | PASS | |
| bolt-core-sdk | Rust vectors (`cargo test --features vectors`) | 127 | PASS | |
| localbolt | web (`npm test`) | 300 | PASS | 14 test files |
| localbolt-app | web (`npm test`) | 11 | PASS | 2 test files |
| localbolt-v3 | localbolt-core (`npm test`) | 43 | PASS | 2 test files |
| localbolt-v3 | localbolt-web (`npm test`) | 59 | PASS | 4 test files |

### R1-0 Daemon Key-Role Finding

**SA1 separation is complete and well-tested.** No ambiguous or mixed-role key usage found:
- Identity keypair: persistent (`~/.bolt/identity.key`), used only for TOFU trust binding (HELLO inner `identityPublicKey` field)
- Ephemeral session keypair: per-connection, used only for NaCl box sealing/opening (HELLO + post-HELLO envelopes)
- 12 separation tests in `tests/sa1_identity_separation.rs` + 10 identity store tests in `tests/sa1_identity_store.rs`
- `.take()` ownership pattern prevents ephemeral key cloning
- `[SA1]` log markers confirm separation at runtime
- **R1-1 preliminary signal:** SA1 Path A (new finding) likely not needed for daemon key-role. Evidence supports SA1 closure holding.

### R1-0 Product Crypto-Path Finding

**All three product repos use SDK-mediated crypto exclusively.** Zero direct tweetnacl/nacl calls in product-layer code:
- Identity: `getOrCreateIdentity()` from `@the9ines/bolt-transport-web`
- Peer codes: `generateSecurePeerCode()` from `@the9ines/bolt-core`
- Encryption: `sealBoxPayload()`/`openBoxPayload()` via WebRTCService (SDK-internal)
- TOFU: `IndexedDBPinStore`, `VerificationInfo` from `@the9ines/bolt-transport-web`
- Session: `@the9ines/localbolt-core` for state machine + verification bus
- **R1-3 signal:** No product crypto-path migrations needed. Convergence is already complete.

### R1-0 Security Test Gap Summary

**Strong at SDK level (755 tests in transport-web). Critical gaps in v2 products:**

| Gap | Severity | Repos Affected | Category |
|-----|----------|---------------|----------|
| localbolt (v2): no handshake, crypto-path, or session state tests | HIGH | localbolt | B, C, D |
| localbolt-app: smoketest only, no security-critical tests | HIGH | localbolt-app | All |
| No product-layer crypto-path integration tests (D-category) | MEDIUM | localbolt-v3, localbolt, localbolt-app | D |
| No cross-session key isolation integration tests at product layer | MEDIUM | all products | C+D |
| Rust SDK: no reconnect/race tests | LOW | bolt-core-sdk (Rust) | C |

### R1-4 Execution Evidence (2026-03-06)

**All R1-0 HIGH and MEDIUM security test gaps covered. No runtime changes required.**

#### Test Deltas

| Repo | Package | Baseline | Final | Delta | New File |
|------|---------|----------|-------|-------|----------|
| localbolt | web | 300 | 319 | +19 | `web/src/components/__tests__/security-session-integrity.test.ts` |
| localbolt-app | web | 11 | 32 | +21 | `web/src/components/__tests__/security-session-integrity.test.ts` |
| localbolt-v3 | localbolt-core | 43 | 50 | +7 | `packages/localbolt-core/src/__tests__/security-reconnect-integrity.test.ts` |
| localbolt-v3 | localbolt-web | 59 | 59 | 0 | (no change needed — existing coverage adequate) |

#### Tags

| Repo | Tag | Commit |
|------|-----|--------|
| localbolt | `localbolt-v1.0.27-s-stream-r1-r1.4-security-test-lift` | `fc360c5` |
| localbolt-app | `localbolt-app-v1.2.10-s-stream-r1-r1.4-security-test-lift` | `71c3181` |
| localbolt-v3 | `v3.0.79-s-stream-r1-r1.4-security-test-lift` | `31046ac` |

#### Scenario-to-Test Matrix

**localbolt (19 tests covering 4 R1-0 gap scenarios):**
- Stale callback cannot mutate trust/session state after reset/reconnect (4 tests)
- Trust transitions correct across reconnect/session boundary (5 tests)
- Transfer gating integrity under reconnect/security edges (5 tests)
- No unintended downgrade/legacy fallback when verification state is known (5 tests)

**localbolt-app (21 tests covering 4 R1-0 gap scenarios):**
- Identity/trust wiring in realistic connect/reconnect paths (4 tests)
- Stale generation callbacks rejected across distinct timing patterns (7 tests)
- Gating/security behavior under unverified/verified/mismatch transitions (4 tests)
- Reconnect does not leak prior session trust/verification state (6 tests)

**localbolt-v3 (7 tests covering 2 R1-0 medium-gap scenarios):**
- Crypto-path integrity around reconnect boundary (3 tests)
- Trust/verification state isolation between consecutive peers/sessions (4 tests)

#### Validation Matrix

| Repo | Tests | Build (tsc) | Coverage Non-Regression | Guards |
|------|:-----:|:-----------:|:----------------------:|:------:|
| localbolt | PASS (319) | PASS | PASS (thresholds: 80/80/70/80) | N/A |
| localbolt-app | PASS (32) | PASS | PASS (thresholds: 90/90/80/90) | N/A |
| localbolt-v3 core | PASS (50) | PASS | N/A (no thresholds) | N/A |
| localbolt-v3 web | PASS (59) | PASS | PASS (thresholds: 45/5/31/48) | N/A |

#### Runtime Changes

None. Tests-only. No failing→passing proof needed.

#### Residual Uncovered Scenarios

| Scenario | Status | Rationale |
|----------|--------|-----------|
| Rust SDK reconnect/race tests | LOW — deferred | Out of R1-4 scope (R1-4 targets product repos only). Tracked in R1-0 gap summary. |

---

## Security Audit (SA-series) Snapshot — ecosystem-v0.1.14-audit-gov-12a

- **SA resolved:** 19
- **SA open:** 0
- **SA in-progress:** 0
- **DONE-VERIFIED:** SA1, SA2, SA3, SA4, SA5, SA6, SA7, SA8, SA9, SA10, SA12, SA13, SA14, SA16, SA17, SA18, SA19
- **DONE-BY-DESIGN:** SA11
- **SUPERSEDED:** SA15 (bolt.file-hash now implemented in daemon — B4)

SA-series fully closed. All 19 findings resolved. SA15 superseded by B4 implementation.

> Full detail in `docs/AUDIT_TRACKER.md`. This section is summary-level only.

---

## 2026-02-28 Audit Delta (N-series) — ecosystem-v0.1.18-audit-gov-15

- **Total findings (global):** 71
- **N-series total:** 11
- **N-series resolved:** 11 (N1–N11)
- **N-series open:** 0
- **HIGH open:** 0
- **MEDIUM open:** 0
- **LOW open:** 0
- **DONE / DONE-VERIFIED (global):** 53
- **OPEN (global):** 0

**Canonical audit source:** `docs/AUDITS/2026-02-28-security-audit.md`

> Full detail in `docs/AUDIT_TRACKER.md`. This section is summary-level only.
> N-series fully resolved as of AUDIT-GOV-15. All audit series closed.

---

## 2026-03 Full Ecosystem Audit (AC-Series) — ecosystem-v0.1.19-audit-gov-16

- **Total:** 25
- **HIGH:** 9
- **MEDIUM:** 7
- **LOW:** 6
- **DONE-BY-DESIGN:** 3
- **OPEN:** 0
- **DONE / DONE-VERIFIED (global):** 82
- **OPEN (global):** 0
- **Total findings (global):** 103

**Canonical audit source:** `docs/AUDITS/2026-03-01-full-ecosystem-audit.md`

> Full detail in `docs/AUDIT_TRACKER.md`. This section is summary-level only.
> N-series remains fully resolved. AC-series counters unchanged. DP-series (+7 findings, 7 resolved) added per GOV-32–41.

**AUDIT-GOV-17 delta:**
- AC-1: localbolt-app CI + vitest scaffold → DONE-VERIFIED (`localbolt-app-v1.2.2-ci-harden-1`, `3f07f35`)
- AC-2: bolt-core-sdk ci-gate workflow → DONE-VERIFIED (`sdk-v0.5.16-ci-gate-1`, `1694aa6`)

**AUDIT-GOV-18 delta:**
- AC-3: subtree refresh completed → DONE-VERIFIED
  - `rendezvous-v0.2.6-clean-1` (`632544b`)
  - `localbolt-v1.0.18-subtree-refresh-1` (`e9207db`)
  - `localbolt-app-v1.2.3-subtree-refresh-1` (`1d71e66`)

**AUDIT-GOV-19 delta:**
- AC-14: subtree drift prevention implemented → DONE-VERIFIED
  - `localbolt-v1.0.19-drift-guard-1` (`6a4a006`)
  - Subtree refreshed to `rendezvous-v0.2.6-clean-1`
  - Drift prevention (one-directional tracked-file hash guard)
  - Staleness detection remains future enhancement

**AUDIT-GOV-20 delta:**
- AC-21: spec capability string fixed → DONE-VERIFIED (`v0.1.4-spec`, `ede90be`)
- AC-8: Rust wire error registry added → DONE-VERIFIED (`sdk-v0.5.17-protocol-converge-1`, `16cfa92`)
- AC-9: §14 constants aligned → DONE-VERIFIED (`sdk-v0.5.17-protocol-converge-1`, `16cfa92`)
- AC-5: REDUCED (+6 explicit PROTO-HARDEN regression tests), remains OPEN

**AUDIT-GOV-21 delta:**
- AC-6: signaling interop golden vectors → DONE-VERIFIED (`sdk-v0.5.18-interop-converge-1`, `97352af`)
- AC-19: ServerMessage error typing → DONE-VERIFIED (`sdk-v0.5.18-interop-converge-1`, `97352af`)
- AC-20: signaling golden fixtures → DONE-VERIFIED (`sdk-v0.5.18-interop-converge-1`, `97352af`)
- transport-web test count corrected: 199 → 248 (stale since AUDIT-GOV-16)

**AUDIT-GOV-22 delta:**
- AC-7: verify-constants CI guard fixed and enforced in CI → DONE-VERIFIED (sdk-v0.5.19-governance-sweep-1, 9db3abd)
- AC-18: dead crypto-utils barrel removed → DONE-VERIFIED (sdk-v0.5.19-governance-sweep-1, 9db3abd)
- AC-17: unused VALUE exports reduced (types untouched; WebSocketSignaling kept) → OPEN (REDUCED) (sdk-v0.5.19-governance-sweep-1, 9db3abd)

**AUDIT-GOV-23 delta:**
- AC-4: coverage thresholds enforced in localbolt-v3 CI → DONE-VERIFIED (`v3.0.64-ac4-coverage-enforced`, `a5d0237`)
- AC-5: §15 handshake invariant coverage completed (12/12; 11 explicit + 1 by-design) → DONE-VERIFIED (`sdk-v0.5.20-protocol-converge-2`, `28c3baf`)

**AUDIT-GOV-24 delta:**
- AC-10: CONFORMANCE.md TODO rows reconciled → DONE-VERIFIED (`v0.1.5-spec-consistency-1`, `d795dd5`)
- AC-11: daemon dependency refreshed → DONE-VERIFIED (`daemon-v0.2.20-dep-refresh-1`, `99de9aa`)
- AC-12: ARCHITECTURE.md cargo git dependency documented → DONE-VERIFIED (`ecosystem-v0.1.27-arch-consistency-1`, `fdb5545`)

**AUDIT-GOV-25 delta:**
- AC-13: shadow tests replaced with canonical SDK imports → DONE-VERIFIED (`sdk-v0.5.21-ac13-export-surface-1`, `localbolt-v1.0.20-ac13-shadow-test-fix-1`)
- AC-15: find_peer room isolation enforced → DONE-VERIFIED (`rendezvous-v0.2.7-hardening-1`, `6ae3f77`)
- AC-16: XFF proxy allowlist (fail-closed) → DONE-VERIFIED (`rendezvous-v0.2.7-hardening-1`, `6ae3f77`)
- AC-17: export matrix exhausted (33/33 used) → DONE-VERIFIED
- AC-22: WebSocket connection limit (256 default) → DONE-VERIFIED (`rendezvous-v0.2.8-ac22-ws-conn-limit-1`, `bb59440`)
- **AC-series fully closed. All 25 findings resolved. OPEN = 0.**

---

## 2026-03 Deployment Audit (DP-Series) — GOV-32–47

- **Total:** 9 (DP-1 through DP-9)
- **MEDIUM:** 9
- **OPEN:** 0
- **DONE / DONE-VERIFIED (global):** 85
- **OPEN (global):** 0
- **Total findings (global):** 106

Findings discovered during Fly.io deployment of bolt-rendezvous, SDK publish, and production testing.

- DP-1: Rust version bump (1.84→1.85) → `rendezvous-v0.2.9-dp1-rust-bump` (`449796a`)
- DP-2: HTTP health check for Fly.io proxy → `rendezvous-v0.2.10-dp2-health-check` (`06a0f42`)
- DP-3: Phantom device entries (3 compounding bugs, 3 repos) → `rendezvous-v0.2.11-dp3a`, `v3.0.65-dp3b-dp4`, `sdk-v0.5.23-dp3c`
- DP-4: One-way transfer gate removed → `v3.0.65-dp3b-dp4-phantom-transfer` (`08382f1`)
- DP-5: Session guard race condition → `rendezvous-v0.2.12-dp5-session-guard` (`aa8bed0`)
- DP-6: Responder send button fix → `sdk-v0.5.24-dp6-responder-send-fix` (`3c71407`); `transport-web@0.6.1`
- DP-7: bolt-core 0.5.0 publish (wire error registry) → `sdk-v0.5.25-bolt-core-050` (`c776118`); `v3.0.67-dp7-bolt-core-050`
- DP-8: Netlify .npmrc auth for GitHub Packages → `v3.0.68-dp8-netlify-npmrc` (`b1a2cd4`)
- DP-9: Responder sendFile backpressure hang → `sdk-v0.5.27-dp9-backpressure-fix` (`1be76c1`); `transport-web@0.6.2`; `v3.0.69-dp9-backpressure-fix` (`48617f0`)

> Full detail in `docs/AUDIT_TRACKER.md`. Backfilled to CHANGELOG/STATE in GOV-42. DP-8/DP-9 added in GOV-45–47.

---

## 2026-03-03 Security Re-Audit (NF-Series) — ecosystem-v0.1.50-audit-gov-44

- **Total:** 1
- **MEDIUM:** 1
- **OPEN:** 0
- **DONE / DONE-VERIFIED (global):** 85
- **OPEN (global):** 0
- **Total findings (global):** 106

Findings from the 2026-03-03 4-agent security re-audit (crypto correctness,
protocol state machine, interop compatibility, memory/lifecycle).

- NF-1: Envelope path filename validation gap → DONE-VERIFIED (`transport-web-v0.6.10-nf1-envelope-filename`)

**Canonical audit source:** `docs/AUDITS/2026-03-03-security-audit.md`

> Full detail in `docs/AUDIT_TRACKER.md`. NF-series fully resolved.

---

## 2026-03-05 Quality Findings (Q-Series Extension) — Batch 6 C7 Closure

- **Total (Q-series extension):** 4
- **MEDIUM:** 4
- **IN-PROGRESS:** 0
- **DONE-VERIFIED:** 4 (Q4, Q7, Q8, Q9, Q10)
- **DONE / DONE-VERIFIED (global):** 90
- **IN-PROGRESS (global):** 0
- **OPEN (global):** 0
- **Total findings (global):** 110

App-layer convergence and session UX findings registered as part of Workstream C codification.

- Q4: localbolt-app test coverage → DONE-VERIFIED (Batch 5: `@vitest/coverage-v8` installed, thresholds 90/90/80/90, CI wired to `test:coverage`, baseline 100% on tested files)
- Q7: Disconnect/reconnect stale callback races → DONE-VERIFIED (C7 closed: canonical evidence in `@the9ines/localbolt-core` — rapid 7-cycle monotonicity + late verification callback rejection + prior session SM/generation guard/isolation tests. `v3.0.74-c7-closure` (`b867426`))
- Q8: Verification policy mismatch (runtime vs tests/docs) → DONE-VERIFIED (C0 locked: unverified blocks transfer; `v3.0.70`)
- Q9: App-layer behavior drift across products → DONE-VERIFIED (C2–C5 scope; all three consumers migrated to `@the9ines/localbolt-core@0.1.0`)
- Q10: Missing app-layer drift guards → DONE-VERIFIED (Batch 5: upgrade tooling + v3 drift CI + workspace exemption documented + runbook)

> Full detail in `docs/AUDIT_TRACKER.md`. Q-series registered for Workstream C governance.

---

### S1 Completion Notes

- **bolt-core-sdk** (`cced058`): Deterministic Rust conformance harness under `rust/bolt-core/tests/conformance/`. 27 tests (16 envelope + 5 SAS + 6 error mapping, with 11 error_code_mapping tests running under default `cargo test`). Enforces MUST-level invariants: envelope roundtrip determinism (PROTO-01, PROTO-07), MAC verification (SEC-06), nonce freshness/uniqueness (SEC-01, SEC-02), SAS determinism (PROTO-06), and error code mapping stability (Appendix A, Rust surface). No protocol behavior, wire format, or crypto logic changed.
- **TS-owned invariants (not tested in S1):** Handshake gating (WebRTCService state machine), downgrade resistance (capability negotiation), HELLO exactly-once enforcement (WebRTCService), and 11 of 14 Appendix A error frame codes (transport-level, not core SDK types).
- **Test delta:** Default 55→66 (+11), vectors 69→96 (+27). No regressions.

### S2 Progress Notes

- **S2A scope (this sub-phase):** Policy core types + deterministic stub + contract tests. Greenfield Rust module `transfer_policy` in bolt-core-sdk. No behavior change; no callers wired.
- **S2B (instrumentation):** DONE — `transport-web-v0.6.1-s2b-instrumentation` (`02e36b1`). Passive observability for TS transfer path: RingBuffer, TransferMetricsCollector, summarizeTransfer. Stall detection (retroactive, no timers). Feature-gated via `ENABLE_TRANSFER_METRICS` (default false). 24 new tests. Zero overhead when disabled. No behavior change.
- **S2B (remaining):** WASM build/plumbing, TS runtime opt-in integration, rollback proof (flag OFF). NOT-STARTED.
- **Architecture:** Policy core is greenfield; transfer runtime remains TS; WASM consumption planned but no WASM infrastructure exists yet.
- **bolt-core-sdk** (`31bdc0b`): Policy skeleton — `transfer_policy/` module with types (ChunkId, LinkStats, DeviceClass, TransferConstraints, FairnessMode, PolicyInput, Backpressure, ScheduleDecision, MAX_PACING_DELAY_MS) and deterministic `decide()` stub. 4 inline unit tests.
- **bolt-core-sdk** (`39ed6dc`): 15 integration contract tests in `tests/s2_policy_contracts.rs`. Validates determinism, bounds, backpressure, and sanity contracts. Any future real policy must pass these contracts.
- **Test delta:** Default 66→85 (+19), vectors 96→115 (+19). No regressions.

### S0 Completion Notes

- **bolt-rendezvous** (`fd8d3df`): Promoted trust-boundary API (5 constants, 4 validation functions, RateLimit struct + methods) from `pub(crate)` to `pub`. Added `Default` impl for clippy compliance. These pub items exist solely so the wrapper/tests reuse identical validation/rate-limit logic without reimplementation — internal server policy exposure, not a public SDK-like API. 49 tests pass.
- **localbolt-v3** (`2963539`): Replaced `packages/localbolt-signal` local implementation (protocol.rs, server.rs, room.rs) with canonical bolt-rendezvous wrapper via cargo git dependency pinned to `rendezvous-v0.2.2-s0-canonical-lib-verified`. 36 tests (up from 32). Wire-format parity verified. LAN-only compatibility preserved.
- **Wire-format parity evidence:** 8 fixture-based tests in `localbolt-signal/src/lib.rs::tests` (`wire_deserialize_register`, `wire_deserialize_signal`, `wire_deserialize_ping`, `wire_serialize_peers`, `wire_serialize_peer_joined`, `wire_serialize_peer_left`, `wire_serialize_signal_relay`, `wire_serialize_error`). These exercise canonical `bolt-rendezvous-protocol` types through the wrapper using the same JSON shapes as the upstream golden snapshots (`protocol/src/lib.rs::tests::wire_*`). Since localbolt-signal imports canonical types directly (no local reimplementation), parity is structural — drift eliminated by construction.
- **Git dependency resolution:** Tag confirmed on origin. `Cargo.lock` pins both `bolt-rendezvous` and `bolt-rendezvous-protocol` to exact commit `fd8d3df7196b25bfeb25d99868c0525c4a75f917`. Fly builds resolve deterministically.
- **Dockerfile:** git installed in builder stage. Dev-dep stripping via awk documented inline (sibling-path dev-deps unavailable in Docker build context).
- **Smoke test:** Peer discovery, peer_joined, signal relay verified. LAN test: bound `0.0.0.0`, connected via LAN IP `192.168.4.210`.

---

## Interop Path Status

| Milestone | Daemon Tag | Commit | Status |
|-----------|-----------|--------|--------|
| INTEROP-1 — Web signaling payloads | `daemon-v0.2.1-interop-1-web-signal-payload` | `14c7448` | Merged to main |
| INTEROP-2 — Web HELLO handshake | `daemon-v0.2.2-interop-2-web-hello` | `dd82669` | Merged to main |
| INTEROP-3 — Session context + Profile Envelope v1 | `daemon-v0.2.3-interop-3-session-envelope` | `a39fefc` | Merged to main |
| INTEROP-4 — Minimal post-HELLO message set | `daemon-v0.2.4-interop-4-min-msgset` | `d7a79c4` | Merged to main |
| H3 — Golden vector integration tests | `daemon-v0.2.5-h3-golden-vectors` | `3751118` | Merged to main |

---

## Current Enforcement Posture

| Invariant | TS Implementation | Rust Implementation | Test Evidence | On Main? |
|-----------|-------------------|---------------------|---------------|----------|
| Exactly-once HELLO | `WebRTCService` (H2) | `web_hello.rs` HelloState | SDK: 21 H2 tests, daemon: 20 tests | Yes |
| Envelope-required binary enforcement | `WebRTCService` envelope mode (H2) | `envelope.rs` (INTEROP-3) | SDK: H2 rejection tests, daemon: 12 tests | Yes |
| Fail-closed semantics | All protocol errors → disconnect (H2) | Error framing + disconnect | SDK: per-error-code tests, daemon: EnvelopeError | Yes |
| Error code registry (22 codes — §10, unified in v0.1.3-spec) | WIRE_ERROR_CODES | CANONICAL_ERROR_CODES | H2+: emission tests per code | Yes |
| Downgrade resistance | No runtime flag disables enforcement (H2) | web_dc_v1 no-downgrade gate | H2: downgrade resistance suite | Yes |
| Golden vector parity | SAS, HELLO-open, envelope-open (H3) | SAS, HELLO-open, envelope-open (H3) | SDK: 97 TS + 96 Rust (incl. S1 conformance), daemon: 318 tests + 3 E2E | Yes |

---

## Repository Tag Snapshot

| Repo | Latest Tag (main) | Main HEAD |
|------|-------------------|-----------|
| bolt-core-sdk | `sdk-v0.5.28-d3-registry-migration` | `66aaa3a` |
| bolt-daemon | `daemon-v0.2.38-relarch1-multiarch-matrix` | `ab56606` |
| bolt-rendezvous | `rendezvous-v0.2.12-dp5-session-guard` | `aa8bed0` |
| localbolt | `localbolt-v1.0.27-s-stream-r1-r1.4-security-test-lift` | `fc360c5` (code), `490f0cd` (docs HEAD) |
| localbolt-app | `localbolt-app-v1.2.10-s-stream-r1-r1.4-security-test-lift` | `71c3181` (code), `bc0ee2a` (docs HEAD) |
| localbolt-v3 | `v3.0.79-s-stream-r1-r1.4-security-test-lift` | `31046ac` (code), `1871089` (docs HEAD) |
| bolt-protocol | `v0.1.5-spec-consistency-1` | `d795dd5` |
| bytebolt-app | `bytebolt-v0.0.1` | — |
| bytebolt-relay | `relay-v0.0.1` | — |

> **Note:** Snapshots include DP-series changes. bolt-core-sdk: DP-3c, DP-6, DP-7. bolt-rendezvous: DP-1/2/3a/5. localbolt-v3: DP-3b/4/6/7. All pushed to origin.

---

## Active Governance Workstreams

> **Canonical doc:** `docs/GOVERNANCE_WORKSTREAMS.md`
> **Codified:** ecosystem-v0.1.50-audit-gov-44 (2026-03-03)
> **Note:** These are improvement initiatives, not audit findings. Not part of audit counters.

### A-STREAM-1 — WebRTCService Decomposition (bolt-core-sdk): COMPLETE

| ID | Goal | Status | Tag |
|----|------|--------|-----|
| A0 | Shared state scaffolding | DONE | `sdk-v0.5.22-webrtc-decompose-A0` (`6f0bb05`) |
| A1 | Extract HandshakeManager | DONE | `sdk-v0.5.22-webrtc-decompose-A1` (`e2d2b76`) |
| A2 | EnvelopeCodec + TransferManager extraction | DONE | `sdk-v0.5.22-webrtc-decompose-A2` (`7f7811d`) |
| A3 | Extract TransferManager | ABSORBED into A2 | — |
| A4 | Slim WebRTCService to coordinator | ABSORBED into A2 | — |
| A5 | Decomposition test hardening | NOT-STARTED | — |

WebRTCService reduced 1,369 → 790 LOC. Public API unchanged. 249 transport-web tests stable.

### B-STREAM-1 — Daemon Transfer Convergence (bolt-daemon): IN-PROGRESS

| ID | Goal | Status | Tag |
|----|------|--------|-----|
| B1 | Flip interop defaults | DONE | `daemon-v0.2.21-transfer-converge-B1B2` (`95d672f`) |
| B2 | DataChannel message variants + parsing | DONE | `daemon-v0.2.21-transfer-converge-B1B2` (`95d672f`) |
| B3-P1 | Transfer SM skeleton (FileOffer → Cancel) | DONE | `daemon-v0.2.25-b3-transfer-sm-p1` (`edebe5d`) |
| B3-P2 | Receive data plane (accept + chunks + reassembly) | DONE | `daemon-v0.2.26-b3-transfer-sm-p2` (`5844199`) |
| B3-P3 | Sender-side transfer MVP (send session + chunk streaming) | DONE | `daemon-v0.2.29-b3-transfer-sm-p3-sender` (`4fd55e3`) |
| B4 | File-hash capability (receiver-side SHA-256) | DONE | `daemon-v0.2.27-b4-file-hash` (`b41f814`) |
| B5 | TOFU pin persistence | DONE | `daemon-v0.2.23-b5-tofu-persist` (`0faa729`) |
| B6-P1 | Post-HELLO event loop container | DONE | `daemon-v0.2.24-b6-loop-container` (`8666f44`) |
| D-E2E-A | Live E2E transfer (synthetic Rust offerer) | DONE | `daemon-v0.2.28-d-e2e-a-live-transfer` (`b105344`) |
| D-E2E-B | Cross-implementation bidirectional TS↔Rust E2E | DONE | `daemon-v0.2.30-d-e2e-b-cross-impl` (`a8cf108`) |

Fail-closed option C. Defaults flipped to Web*. B5 wired persistent TOFU pinning. B6-P1 introduced shared `run_post_hello_loop()`. B3-P1 integrated TransferSession into loop — FileOffer intercepted after envelope decrypt, rejected via Cancel. B3-P2 replaced Cancel reject with auto-accept + receive path: FileOffer→accept→send FileAccept, FileChunk→base64 decode→sequential reassembly in memory, FileFinish→Completed. 256 MiB cap enforced. B4 added receiver-side SHA-256 hash verification gated by `bolt.file-hash` capability negotiation; `DAEMON_CAPABILITIES` now advertises `bolt.file-hash` (SA15 superseded). Mismatch → `INTEGRITY_FAILED` + disconnect. D-E2E-A proved live hash-verified transfer via synthetic Rust offerer: real rendezvous, real WebRTC, real NaCl, `[B4_VERIFY_OK]` evidence asserted. B3-P3 added sender-side SendSession (Idle→OfferSent→Sending→Completed/Cancelled) with cursor-driven chunk streaming, SHA-256 hash gating, FileAccept/Cancel loop-level interception. Pause/Resume remain INVALID_STATE.

### Governance Process Items

| ID | Description | Severity | Status |
|----|------------|----------|--------|
| FMT-GATE-1 | Daemon rustfmt verification drift | LOW | DONE-VERIFIED (`daemon-v0.2.22-fmt-sync-1`, `9d0a485`) |

### Deferred Phases — Corrected Dependencies (AUDIT-GOV-30)

| ID | Goal | Status | Dependencies | Notes |
|----|------|--------|-------------|-------|
| B5 | TOFU pin persistence | DONE | None (independent) | `daemon-v0.2.23-b5-tofu-persist` (`0faa729`) |
| B3 | Transfer engine state machine | IN-PROGRESS | B2 (DONE) | B3-P1+P2+P3 done; remaining: pause/resume, disk writes, concurrent transfers |
| B6 | Post-HELLO persistent event loop | IN-PROGRESS | Coupled with B3 | B6-P1 done; B3-P2 integrated into loop; full B6 requires full B3 |
| B4 | File-hash capability (receiver-side) | DONE | B3-P2 (receive path) | `daemon-v0.2.27-b4-file-hash` (`b41f814`); SA15 superseded |
| D-E2E-A | Live E2E transfer (synthetic Rust offerer) | DONE | B3-P2 + B4 + B6-P1 | `daemon-v0.2.28-d-e2e-a-live-transfer` (`b105344`) |
| D-E2E-B | Cross-implementation TS↔Rust E2E | DONE | `daemon-v0.2.30-d-e2e-b-cross-impl` (`a8cf108`) | Bidirectional hash-verified transfer: TS offerer ↔ Rust answerer |

**Dependency amendment (AUDIT-GOV-27):** B5 is independent (was incorrectly listed as dependent on B3). B6 does not depend on B5 (was incorrectly listed). B3+B6 are the coupled critical path. See `docs/GOVERNANCE_WORKSTREAMS.md` for full enriched definitions with verified spec references.

**B5/B6-P1 completion (AUDIT-GOV-28):** B5 delivered persistent TOFU pinning bound to HELLO identity key. B6-P1 delivered shared `run_post_hello_loop()` — deterministic recv→decode→route loop with deadline exit, periodic ping (2s), and fail-closed transfer message policy.

**B3-P1 completion (AUDIT-GOV-29):** B3-P1 delivered TransferSession (Idle→OfferReceived→Rejected) integrated into `run_post_hello_loop`. FileOffer intercepted after envelope decrypt, rejected via Cancel (`cancelled_by="receiver"`). Second offer while not Idle triggers INVALID_STATE disconnect. FileOffer carved out of `route_inner_message` combined transfer arm to `Ok(None)`. All other transfer messages remain INVALID_STATE. Tag naming deviates from governance spec (see GOVERNANCE_WORKSTREAMS.md).

**B3-P2 completion (AUDIT-GOV-30):** B3-P2 replaced Cancel reject with auto-accept + full receive path. TransferState extended with Receiving and Completed variants. FileOffer auto-accepted (on_file_offer→accept_current_offer→send FileAccept). FileChunk decoded from base64 via `bolt_core::encoding::from_base64` then sequential index enforcement and in-memory reassembly. FileFinish transitions Receiving→Completed. MAX_TRANSFER_BYTES (256 MiB) enforced at offer and chunk level. FileChunk and FileFinish carved out to Ok(None) in `route_inner_message`. Loop interception expanded from if-let to match on FileOffer/FileChunk/FileFinish. +12 tests (9 unit, 1 envelope, 2 loop integration). No disk writes, no hashing, no send-side.

**B4 completion (AUDIT-GOV-31):** B4 delivered receiver-side SHA-256 hash verification gated by `bolt.file-hash` capability negotiation. `DAEMON_CAPABILITIES` now advertises `bolt.file-hash` (SA15 superseded). TransferSession extended with `expected_hash` field; `on_file_offer` accepts optional hash; `on_file_finish` verifies via `bolt_core::hash::sha256_hex` (case-insensitive). New `TransferError::IntegrityFailed` variant. Capability gating at loop level: negotiated + missing hash → `INTEGRITY_FAILED` + disconnect; not negotiated → hash on wire ignored. No new dependencies, no new EnvelopeError variants, no wire format changes, no new canonical error codes. +9 tests (4 unit, 5 loop integration). Sender-side hashing out of scope.

**D-E2E-A completion (AUDIT-GOV-40):** D-E2E-A delivered a live end-to-end transfer integration test proving hash verification via `[B4_VERIFY_OK]` evidence token. Synthetic Rust offerer drives real bolt-rendezvous + bolt-daemon answerer through WebRTC signaling, encrypted HELLO handshake, capability negotiation (bolt.file-hash + bolt.profile-envelope-v1), and file transfer (4096-byte deterministic payload, single chunk, SHA-256 verified). Stage 1: `hash_verified()` on TransferSession + evidence emission in `run_post_hello_loop`. Stage 2: `#[ignore]` integration test in `tests/d_e2e_web_to_daemon.rs`. +2 unit tests, +1 ignored E2E test.

**D-E2E-B completion (AUDIT-GOV-48):** D-E2E-B delivered true cross-implementation bidirectional E2E transfer between Node.js offerer and Rust daemon answerer. JS harness (`tests/ts-harness/harness.mjs`) implements full Bolt protocol: WebSocket rendezvous signaling, WebRTC DataChannel via `node-datachannel`, NaCl box encryption via `tweetnacl`, Profile Envelope v1, encrypted HELLO exchange with capability negotiation, and bidirectional file transfer with SHA-256 verification. Pattern A (4096 B, `((i+1)*31) & 0xFF`) flows JS→daemon; Pattern B (6144 B, `((i+1)*37) & 0xFF`) flows daemon→JS. Test-only send trigger in `src/rendezvous.rs` (30 lines, all `#[cfg(feature = "test-support")]`) reads `BOLT_TEST_SEND_PAYLOAD_PATH` env var to drive SendSession. Two `#[ignore]` tests: happy-path bidirectional + negative integrity mismatch. D-E2E now fully complete (both A and B).

**B3-P3 completion (AUDIT-GOV-43):** B3-P3 delivered sender-side SendSession (Idle→OfferSent→Sending→Completed/Cancelled) with cursor-driven chunk streaming (DEFAULT_CHUNK_SIZE = 16,384 bytes). `begin_send()` computes metadata and optional SHA-256 hash. `on_accept()` transitions to Sending. `next_chunk()` yields one chunk at a time. `finish()` validates all chunks yielded. FileAccept and Cancel carved out from `route_inner_message` to Ok(None) for loop-level interception. Loop drives send-side SM on FileAccept (stream chunks + finish); absorbs gracefully when no outbound transfer active. Cancel absorbed similarly. Pause/Resume remain INVALID_STATE. No new DcMessage variants, no new EnvelopeError variants, no new canonical error codes. dc_messages.rs unchanged. +16 tests (10 unit, 3 loop integration, 3 net envelope).

**Scope guardrails:** No protocol, wire-format, or cryptographic changes. A-stream preserves WebRTCService public API.

### N-STREAM-1 — Native App + Daemon Bundling (localbolt-app): **CLOSED**

| ID | Goal | Status | Tag |
|----|------|--------|-----|
| N0 | Policy lock (D0.1–D0.8) | **DONE** | `ecosystem-v0.1.73-n-stream-1-n0-policy-lock` |
| N1 | Packaging + security matrix (macOS/Windows/Linux) | **DONE** | `ecosystem-v0.1.74-n-stream-1-n1-n2-lock` |
| N2 | IPC contract stabilization | **DONE** (spec locked, all impl deps **RESOLVED**) | `ecosystem-v0.1.74-n-stream-1-n1-n2-lock` |
| N3 | Process supervision + diagnostics | **DONE** (spec locked; B-DEP-N2-1/N2-2 **RESOLVED**) | `ecosystem-v0.1.75-n-stream-1-n3-supervision` |
| N4 | Rollout + migration | **DONE** (spec locked) | `ecosystem-v0.1.76-n-stream-1-n4-n5-lock` |
| N5 | Acceptance harness | **DONE** (spec locked) | `ecosystem-v0.1.76-n-stream-1-n4-n5-lock` |
| N6 | Execution + hardening | **DONE** | `localbolt-app-v1.2.13-n6b3-ga-wiring` (`88954c8`) |
| A0 | Signaling ownership evaluation | **DONE** | `ecosystem-v0.1.81-signal-eval-a0-decision` |
| N7 | Closure | **DONE** | `ecosystem-v0.1.82-n-stream-1-n7-closure` |
| N8 | D2 signal observability (post-closure follow-on) | **DONE** | `localbolt-app-v1.2.14-n8-signal-observability` (`a7e4f8b`) |

Codified: ecosystem-v0.1.72-n-stream-1-codify (2026-03-07). N0 locked: ecosystem-v0.1.73-n-stream-1-n0-policy-lock (2026-03-07). N1+N2 locked: ecosystem-v0.1.74-n-stream-1-n1-n2-lock (2026-03-07). N3 locked: ecosystem-v0.1.75-n-stream-1-n3-supervision (2026-03-07). N4+N5 locked: ecosystem-v0.1.76-n-stream-1-n4-n5-lock (2026-03-07). N7 closure: ecosystem-v0.1.82-n-stream-1-n7-closure (2026-03-07). N-STREAM-1 governs app bundling, process lifecycle, packaging, supervision, and operator UX for daemon integration. B-STREAM governs daemon protocol/runtime. N-STREAM-1 consumes daemon API surface; does not redefine it. Primary target: localbolt-app. Finding series `N1-F*` reserved. **Stream status: CLOSED.** Residual R17 (Windows runtime validation) CLOSED 2026-03-08 — Windows CI provisioned, daemon + app IPC validated on `windows-latest`. D2 observability delivered via N8 post-closure follow-on (`localbolt-app-v1.2.14-n8-signal-observability`, `a7e4f8b`). AC-SE-06/07 realized with architecture-neutral wording (app-side probe, not daemon).

**A0 Signal Ownership Decision (2026-03-07):** Option A (status quo coexistence) approved. App owns embedded signaling server (bolt-rendezvous via signal/ subtree, 0.0.0.0:3001). Daemon owns IPC decisions only. D2 observability (signal.status monitoring) deferred to N8 or B-stream. Options B and D1 rejected (7–9 amendment burden, guardrail 13 violation). AC-SE-01..05/08..10 approved; AC-SE-06/07 deferred. Residuals: R17 (Windows, CLOSED 2026-03-08), OQ-2 (graceful shutdown). Tag: `ecosystem-v0.1.81-signal-eval-a0-decision`.

**N0 decisions (summary):** App-managed lifecycle (D0.1). Daemon spawned on app launch with 10s readiness timeout (D0.2). SIGTERM+5s grace+SIGKILL on app exit (D0.3). Exponential backoff restart 1s/3s/10s, 3 max, degraded mode (D0.4). Per-user single instance via socket lockfile (D0.5). Persistent state survives crashes, transient state resets (D0.6). Strict major.minor version match, fail-closed (D0.7). B-STREAM boundary reaffirmed (D0.8). N1 and N2 unblocked.

**N1 (summary):** Per-platform packaging matrix locked: macOS (`.app`+`.dmg`, sidecar in `Contents/Resources/bin/`), Windows (NSIS/WiX, sidecar in `{install_dir}/bin/`), Linux (`.deb`/`.rpm`, sidecar in `/usr/lib/localbolt/bin/`). Platform-appropriate socket/PID/identity/pin paths defined. Signing SHOULD (pre-release), REQUIRED (GA). Least-privilege: no elevation, `0600` socket, data-dir-only writes. Co-versioned bundle, whole-bundle update/rollback. 11 acceptance checks for N5 harness. B-DEP-N1-1 (platform path CLI flags) recorded for N6 GA.

**N2 (summary):** IPC contract baseline locked: 5 stable messages (daemon.status, pairing.request, transfer.incoming.request, pairing.decision, transfer.incoming.decision) + 2 provisional (version.handshake, version.status). NDJSON wire format, single-client kick-on-reconnect, 1 MiB max line, 30s decision timeout (fail-closed). Version handshake required as first exchange, strict major.minor match. Compatibility policy: breaking = major bump, non-breaking = minor bump, unknown types silently dropped. 5 degraded mode transitions defined. 11 acceptance checks for N5 harness. B-DEP-N2-1, B-DEP-N2-2, B-DEP-N2-3 — all RESOLVED (see B-DEP table in GOVERNANCE_WORKSTREAMS.md).

**N3 (summary):** Supervision + diagnostics spec locked. Watchdog state machine: 5 states (starting/ready/restarting/degraded/incompatible), 6 invariants (W-01–W-06). Retry/backoff: 1s/3s/10s, 3 max, 60s success reset (operationalizes N0 D0.4). Stale socket/process cleanup: PID file + socket probe algorithm, app-owned PID file. Shutdown: SIGTERM+5s grace+SIGKILL (operationalizes N0 D0.3). stderr capture: 1000-line ring buffer, crash snapshots to log dir, `[DAEMON_CRASH]`/`[WATCHDOG]` tokens. Support bundle: 6 required items, sensitive data exclusion list. User-visible status: 5 state indicators with action affordances, ARIA accessibility. 15 acceptance checks for N5 harness. N6 implementation plan: 9-step Rust/Tauri sequence + 7-step UI sequence. B-DEP-N2-1 (readiness transition) and B-DEP-N2-2 (version-gate transition) block N6 implementation, not this spec lock.

**N4 (summary):** Rollout + migration spec locked. 4-stage rollout (Local/Dev, Alpha, Beta, GA) with explicit entry/exit criteria and blocker-aware gating. Local/Dev unblocked; Alpha requires B-DEP-N2-1; Beta requires B-DEP-N2-2; GA requires B-DEP-N1-1 + all B-DEPs. Version-skew policy: strict major.minor match, fail-closed on mismatch (N0 D0.7, N2-S3). Whole-bundle update/rollback with data preservation (identity keys, TOFU pins survive). Migration strategy: purely additive (no existing daemon config), transparent to user, 5 invariants (M-01–M-05). 7 acceptance checks for N5 harness (AC-N4-1 through AC-N4-7). Rollout cannot-progress decision tree maps all 4 B-DEPs to stage gates.

**N5 (summary):** Acceptance harness spec locked. 8 test domains (packaging, lifecycle, IPC readiness, IPC messages, degraded UX, update/rollback, diagnostics, data safety). 4 tiers: Smoke (8 checks, <30s), Integration (26 checks, <5min), Failure Injection (8 checks, <10min), Pre-Release (2 checks, GA-only). 44 total checks: 37 from N1–N3 + 7 new from N4. 9 checks blocked by B-DEPs (8 full + 1 partial); blocked checks report SKIP status, not FAIL. Pass/fail criteria: hard fail blocks stage progression; soft fail tracked but non-blocking. Evidence contract: 9 artifact types, CI-automatable vs human-review classification, retention until N7. All AC-N1/AC-N2/AC-N3/AC-N4 checks incorporated without contradiction or duplication (verified by arithmetic).

### Forward Backlog (Post-R17)

**Codified:** ecosystem-v0.1.86-roadmap-codify-transfer-security-mobile (2026-03-08)
**Full specification:** `docs/FORWARD_BACKLOG.md`

| ID | Item | Priority | Routing | Status |
|----|------|----------|---------|--------|
| B-XFER-1 | Transfer pause/resume completion | NOW | bolt-daemon | **DONE** (`daemon-v0.2.35-bxfer1-pause-resume`) |
| REL-ARCH1 | Multi-arch daemon build/package matrix | NOW | bolt-daemon + ecosystem | **DONE** (`daemon-v0.2.38-relarch1-multiarch-matrix`, `ab56606`) |
| SEC-DR1 | Double Ratchet pre-ByteBolt gate (DR-STREAM-1) | ~~NEXT~~ | bolt-core-sdk + bolt-protocol | **SUPERSEDED-BY: SEC-BTR1** (frozen, `ecosystem-v0.1.99-sec-dr1-p0-codify`) |
| SEC-BTR1 | Bolt Transfer Ratchet pre-ByteBolt gate (BTR-STREAM-1) | ~~NEXT~~ DONE | bolt-core-sdk + bolt-protocol | **BTR-STREAM-1 COMPLETE.** BTR-0–5 DONE. Approved policy: Option C (default-on fail-open, downgrade-with-warning). PM-BTR-08/09/11 approved 2026-03-11. Tags: sdk-v0.5.36–v0.5.39, ecosystem-v0.1.100–v0.1.107. |
| CONSUMER-BTR1 | Consumer app BTR rollout (CONSUMER-BTR-1) | ~~NOW~~ DONE | localbolt-v3, localbolt, localbolt-app | **DONE** (burn-in waived via `PM-CBTR-EX-01`, 2026-03-13). CBTR-1 DONE (burn-in PASSED). CBTR-2 DONE (burn-in PASSED, 24h02m). CBTR-3 DONE (`localbolt-app-v1.2.24`, `ff33747`; burn-in started 2026-03-13 04:54 UTC, waived). Residual risk: enhanced monitoring 24h post-close; rollback via `btrEnabled: false`. |
| T-STREAM-0 | Rust transfer core (no UDP in v1) | NEXT | New crate + daemon | NOT-STARTED |
| SEC-CORE2 | Rust-first security/protocol consolidation | ~~NEXT~~ SUPERSEDED | bolt-core-sdk | **SUPERSEDED-BY: RUSTIFY-CORE-1** (PM-RC-07 APPROVED 2026-03-14). AC-SC-01–04 absorbed by AC-RC-08–11. |
| T-STREAM-1 | Browser selective WASM integration | LATER | bolt-core-sdk + WASM + consumers | **SDK DONE, CONSUMERS ADOPTED** (`sdk-v0.5.32`, `localbolt-v1.0.29`, `localbolt-app-v1.2.17`, `v3.0.82`) — manual runtime evidence pending |
| PLAT-CORE1 | Shared Rust core + thin platform UIs | ~~LATER~~ SUPERSEDED | TBD | **SUPERSEDED-BY: RUSTIFY-CORE-1** (PM-RC-07 APPROVED 2026-03-14). RC2+RC4 absorbed full scope. |
| MOB-RUNTIME1 | Mobile embedded runtime model | LATER | TBD | **DEPENDS-ON RUSTIFY-CORE-1 RC4** (PM-RC-07 APPROVED 2026-03-14). Retains own stream identity. |
| ARCH-WASM1 | WASM protocol engine (medium risk) | ~~LATER~~ SUPERSEDED | bolt-core-sdk + WASM | **SUPERSEDED-BY: RUSTIFY-BROWSER-CORE-1** (PM-RB-05 APPROVED 2026-03-17). |
| RUSTIFY-CORE-1 | Native-first transport + core consolidation | NEXT | bolt-core-sdk + bolt-daemon + bolt-protocol | **RC1–RC7 all DONE.** All 33 ACs PASS. **All 8 PM decisions APPROVED.** PM-RC-07: SUPERSEDES SEC-CORE2+PLAT-CORE1, REFACTORS MOB-RUNTIME1+ARCH-WASM1. PM-RC-04: SLO thresholds defined (≥10 MiB/s, 100% integrity, ≥99% connection). CLI execution stream NOT OPEN (Stage 1 burn-in pending). |
| EGUI-NATIVE-1 | Native desktop UI consolidation (egui) | ~~LATER~~ COMPLETE | localbolt-app + bolt-core-sdk + ecosystem | **COMPLETE** (`ecosystem-v0.1.162`, 2026-03-16). EN1–EN4 delivered AC-EN-01–20; EN5 closure (AC-EN-21–24). PM-EN-01/02/03/04 APPROVED. PM-EN-05 deferred. Stream CLOSED. |
| EGUI-WASM-1 | Browser UI migration to egui via WASM (experimental) | ~~LATER~~ ABANDONED | localbolt-v3 + localbolt + ecosystem | **ABANDONED** (`ecosystem-v0.1.164`, 2026-03-17). EW2 PoC: 1,296 KiB gzipped (2.6× over 500 KiB kill). 26% reuse. 20× bundle vs current 65 KiB TS app. Stream CLOSED with findings. |
| DISCOVERY-MODE-1 | Discovery mode policy codification | ~~NEXT~~ COMPLETE | ecosystem + consumers | **COMPLETE** (`ecosystem-v0.1.160`, 2026-03-15). All 16 ACs PASS. All 4 PM decisions APPROVED. |
| BTR-SPEC-1 | Algorithm-grade BTR protocol specification | ~~NEXT~~ COMPLETE | bolt-protocol + ecosystem | **COMPLETE** (`ecosystem-v0.1.143`, 2026-03-15). All 22 ACs PASS. All 6 PM decisions APPROVED. |
| RECON-XFER-1 | Transfer reconnect recovery after mid-transfer disconnect | NOW | bolt-core-sdk (TS) + consumers | **DONE-VERIFIED (evidence tail: RX-EVID-1)** — Phase A: `sdk-v0.5.35-recon-xfer1-phase-a-tests`, `v3.0.88-recon-xfer1-phase-a`. Phase B: `localbolt-v1.0.35-recon-xfer1-phase-b`, `localbolt-app-v1.2.23-recon-xfer1-phase-b`. AC-RX-01–07 satisfied. AC-RX-08 automated PASS, manual runtime PENDING (RX-EVID-1). All code work closed. |
| WEBTRANSPORT-BROWSER-APP-1 | Browser↔app WebTransport migration | ~~NEXT~~ COMPLETE | bolt-daemon + bolt-core-sdk + ecosystem | **COMPLETE** (`ecosystem-v0.1.147`, 2026-03-15). All 20 ACs PASS. All 5 PM decisions APPROVED. |
| RUSTIFY-BROWSER-CORE-1 | Browser-path Rust/WASM protocol authority | NEXT | bolt-core-sdk + bolt-transport-web + consumers + ecosystem | **RB1 DONE** (`ecosystem-v0.1.166`, 2026-03-17). PM-RB-01–05 all APPROVED. ≤300 KiB gzipped budget. Condition-gated sunset. localbolt-v3 first. ARCH-WASM1 superseded. RB2 READY. |

---

## Test Counts (post-merge-train, on main)

| Repo | Tests | Notes |
|------|------:|-------|
| bolt-core-sdk (TS bolt-core) | 232 | Includes H2 enforcement + H3 golden vectors + H6 nonce + BTR-2 parity (78) + BTR-3 lifecycle/adversarial (34) |
| bolt-core-sdk (TS transport-web) | 253 | Includes H2 enforcement + S2B metrics + interop error framing + SA5/SA6 lifecycle harden + SA10 hello timeout + AC-8/AC-9 proto-harden regression + AC-6/AC-19/AC-20 signaling golden vectors + AC-5 send-side atomicity + NF-1 envelope filename validation |
| bolt-core-sdk (Rust, default) | 280 | main (63 bolt-core + 58 bolt-btr + 16 conformance + 93 transfer-core + 36 s2a + 14 wasm) |
| bolt-core-sdk (Rust, vectors) | 291 | main (280 default + 11 bolt-btr vector golden tests) |
| bolt-daemon (default) | 362 | main (195 lib + 128 main + 15 relay + 13 n6b1 + 11 n6b2; includes T-STREAM-0 adapter) |
| bolt-daemon (test-support) | 362 + 3 ignored | main (same suite with test-support feature; includes H3/H5/P1/SA1/B5/B6-P1/B3-P1/B3-P2/B4/B3-P3 + D-E2E-A + D-E2E-B + T-STREAM-0) |
| bolt-rendezvous | 49 | main (48 unit + 1 doc-test) |
| localbolt (TS) | 319 | 15 test files, 80/70/80% coverage thresholds, includes 27 TOFU + 19 security-session-integrity tests |
| localbolt-app (TS) | 64 | 5 test files (1 smoke + 10 TOFU integration + 21 security-session-integrity + 24 daemon service + 8 header unified status), coverage thresholds 90/90/80/90 |
| localbolt-app (Rust) | 82 | 10 modules (watchdog 17, daemon_log 5, ipc_client 5, ipc_types 9, daemon 8, commands 7, platform 8, ipc_transport 4, ipc_bridge 4, signal_monitor 15) |
| localbolt-v3 (TS, localbolt-core) | 50 | Session state machine, verification bus, transfer policy, race hardening, C7 closure + 7 security-reconnect-integrity tests |
| localbolt-v3 (TS, localbolt-web) | 59 | H5-v3 TOFU/SAS tests + session orchestration consumer wiring |
| localbolt-v3 (Rust signal) | 36 | main (S0 canonical bolt-rendezvous wrapper, up from 32) |

> **Reconciliation:** Previous snapshot recorded 199 transport-web tests.
> Verified baseline at `transport-web-v0.6.9-n8-caplen-1` was 218.
> `sdk-v0.5.17-protocol-converge-1` increased to 224.
> `sdk-v0.5.18-interop-converge-1` increased to 248.

