---
Snapshot Derived From:
- sdk-v0.5.28-d3-registry-migration (66aaa3a)
- daemon-v0.2.30-d-e2e-b-cross-impl (a8cf108)
- v3.0.78-d5-registry-guards (fec153b)
- localbolt-v1.0.26-d5-registry-guards (76ae224)
- localbolt-app-v1.2.9-d5-registry-guards (93afc2c)
Last Refreshed By: D5 drift guards DONE
---

# Bolt Ecosystem — State

> **Last Updated:** 2026-03-06 (D5 drift guards DONE)
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
| S2 | Transfer performance program | IN-PROGRESS | bolt-core-sdk | `sdk-v0.5.5-s2-policy-skeleton`, `sdk-v0.5.6-s2-policy-contract-tests`, `transport-web-v0.6.1-s2b-instrumentation` | `31bdc0b`, `39ed6dc`, `02e36b1` |

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
| bolt-daemon | `daemon-v0.2.30-d-e2e-b-cross-impl` | `a8cf108` |
| bolt-rendezvous | `rendezvous-v0.2.12-dp5-session-guard` | `aa8bed0` |
| localbolt | `localbolt-v1.0.26-d5-registry-guards` | `76ae224` |
| localbolt-app | `localbolt-app-v1.2.9-d5-registry-guards` | `93afc2c` |
| localbolt-v3 | `v3.0.78-d5-registry-guards` | `fec153b` |
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

---

## Test Counts (post-merge-train, on main)

| Repo | Tests | Notes |
|------|------:|-------|
| bolt-core-sdk (TS bolt-core) | 120 | Includes H2 enforcement + H3 golden vectors + H6 nonce tests + governance-sweep-1 |
| bolt-core-sdk (TS transport-web) | 253 | Includes H2 enforcement + S2B metrics + interop error framing + SA5/SA6 lifecycle harden + SA10 hello timeout + AC-8/AC-9 proto-harden regression + AC-6/AC-19/AC-20 signaling golden vectors + AC-5 send-side atomicity + NF-1 envelope filename validation |
| bolt-core-sdk (Rust, default) | 87 | main (61 unit + 11 S1 conformance + 15 S2 contract) |
| bolt-core-sdk (Rust, vectors) | 117 | main (61 unit + 27 S1 conformance + 14 H3 vectors + 15 S2 contract) |
| bolt-daemon (default) | 318 | main (includes B1B2, B5, B6-P1, B3-P1, B3-P2, B4, D-E2E-A, B3-P3) |
| bolt-daemon (test-support) | 398 + 3 ignored | main (includes H3/H5/P1/SA1/B5/B6-P1/B3-P1/B3-P2/B4/B3-P3 + D-E2E-A + D-E2E-B) |
| bolt-rendezvous | 49 | main (48 unit + 1 doc-test) |
| localbolt (TS) | 300 | 14 test files, 80/70/80% coverage thresholds, includes 27 TOFU tests |
| localbolt-app (TS) | 11 | 2 test files (1 smoke + 10 TOFU integration), coverage thresholds 90/90/80/90 |
| localbolt-v3 (TS, localbolt-core) | 43 | Session state machine, verification bus, transfer policy, race hardening, C7 closure tests |
| localbolt-v3 (TS, localbolt-web) | 59 | H5-v3 TOFU/SAS tests + session orchestration consumer wiring |
| localbolt-v3 (Rust signal) | 36 | main (S0 canonical bolt-rendezvous wrapper, up from 32) |

> **Reconciliation:** Previous snapshot recorded 199 transport-web tests.
> Verified baseline at `transport-web-v0.6.9-n8-caplen-1` was 218.
> `sdk-v0.5.17-protocol-converge-1` increased to 224.
> `sdk-v0.5.18-interop-converge-1` increased to 248.

