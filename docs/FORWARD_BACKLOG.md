# Bolt Ecosystem — Forward Backlog

> **Status:** Normative
> **Created:** 2026-03-08
> **Updated:** 2026-03-09 (RECON-XFER-1 — transfer reconnect recovery codification)
> **Codified:** ecosystem-v0.1.86-roadmap-codify-transfer-security-mobile
> **Authority:** PM-approved. Execution requires separate phase prompts per item.

---

## Purpose

This document codifies the post-R17 forward backlog: 10 items spanning transfer completion, release architecture, security, transfer reliability, platform convergence, and mobile readiness. Items are prioritized into NOW / NEXT / LATER tiers with acceptance criteria defined for NOW and NEXT items. LATER items have AC deferred to stream codification.

Linked from `docs/GOVERNANCE_WORKSTREAMS.md` (summary) and `docs/ROADMAP.md` (dependency map).

---

## Priority / Dependency Matrix

```
NOW:
  B-XFER-1 (transfer pause/resume completion) ─── DONE (daemon-v0.2.35)
  REL-ARCH1 (multi-arch build matrix) ─────────── DONE (daemon-v0.2.38)
  RECON-XFER-1 (transfer reconnect recovery) ──── NOT-STARTED

NEXT:
  SEC-DR1 (Double Ratchet security gate) ──────── independent (pre-ByteBolt)
  T-STREAM-0 (Rust transfer core) ────────────── depends on B-XFER-1 completion
  SEC-CORE2 (Rust-first security consolidation) ── depends on S1 (DONE)

LATER:
  T-STREAM-1 (browser selective WASM) ────────── depends on T-STREAM-0
  PLAT-CORE1 (shared Rust core + thin UIs) ────── depends on T-STREAM-0 + SEC-CORE2
  MOB-RUNTIME1 (mobile embedded runtime) ─────── depends on PLAT-CORE1
  ARCH-WASM1 (WASM protocol engine) ──────────── depends on T-STREAM-0

Priority constraint: MOB-RUNTIME1 ≤ PLAT-CORE1 (mobile cannot exceed shared core priority).
```

---

## Guardrails (All Items)

| ID | Guardrail | Applies To |
|----|-----------|-----------|
| G1 | Browser retains native WebRTC transport — no browser webrtc-rs swap | T-STREAM-0, T-STREAM-1, ARCH-WASM1 |
| G2 | No UDP in transfer-core v1 | T-STREAM-0 |
| G3 | No ownership/topology reversal from A0 Option A (app owns signal) | All items |
| G4 | No protocol semantic changes without PM approval | All items |
| G5 | Tags are immutable; SRE policy enforced | All items |

---

## Item 1: B-XFER-1 — Transfer Pause/Resume Completion

**Priority:** NOW
**Status:** **DONE** — `daemon-v0.2.35-bxfer1-pause-resume` (`9f087a1`)
**Routing:** bolt-daemon
**Category:** Daemon transfer state machine remaining scope

**Context:** B-stream B3 (transfer engine) delivered P1–P3: control plane skeleton, receive + reassembly, sender-side MVP. Cancel handling is complete. Pause/Resume remain `INVALID_STATE` in `route_inner_message`. Remaining B3 work per GOVERNANCE_WORKSTREAMS.md:
- Pause/resume state transitions
- Disk writes (currently in-memory only)
- Multiple concurrent transfers

**Neutral naming:** Transfer pause/resume completion (daemon transfer SM remaining scope).

**Boundary note:** This item completes the current daemon-local pause/resume behavior within the existing B3/B6 coupled deliverable. It is **distinct from** T-STREAM-0 (Item 4), which extracts shared transfer-core architecture for cross-platform reuse. B-XFER-1 operates entirely within bolt-daemon's existing `src/transfer.rs` and `src/rendezvous.rs`. T-STREAM-0 creates a new shared Rust crate consumed by daemon, app, and potentially WASM targets.

**Acceptance Criteria:**

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-BX-01 | Pause transition: TRANSFERRING → PAUSED (both sender and receiver) | Unit tests + loop integration tests |
| AC-BX-02 | Resume transition: PAUSED → TRANSFERRING (both sender and receiver) | Unit tests + loop integration tests |
| AC-BX-03 | Pause/Resume messages parsed and routed at loop level (no longer INVALID_STATE) | Route tests |
| AC-BX-04 | Disk write path for received files (replaces in-memory buffer) | Unit tests with temp filesystem |
| AC-BX-05 | MAX_TRANSFER_BYTES cap enforced on disk path | Cap enforcement test |
| AC-BX-06 | B6 event loop routes Pause/Resume through transfer SM | Loop integration tests |
| AC-BX-07 | All existing daemon tests pass (no regression) | `cargo test` + `cargo test --features test-support` |
| AC-BX-08 | `cargo clippy -- -D warnings` clean | CI gate |
| AC-BX-09 | `scripts/check_no_panic.sh` passes | CI gate |

**Out of scope:** Multiple concurrent transfers (separate future item), sender-side disk streaming (sender reads from disk — currently in-memory only via `begin_send()`).

---

## Item 2: REL-ARCH1 — Multi-Arch Daemon Build/Package Matrix

**Priority:** NOW
**Routing:** bolt-daemon, bolt-ecosystem (governance)
**Category:** Release architecture
**Status:** **DONE** (`daemon-v0.2.38-relarch1-multiarch-matrix`, `ab56606`)

**Acceptance Criteria:**

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-RA-01 | CI matrix builds daemon for all 5 targets | GitHub Actions workflow with cross-compilation | **DONE** — `.github/workflows/release.yml` |
| AC-RA-02 | Release artifacts published per tag | `gh release create` with binaries attached | **DONE** — `softprops/action-gh-release@v2` in publish job |
| AC-RA-03 | Binary naming convention codified | Documented in bolt-daemon docs/STATE.md | **DONE** — `bolt-daemon-<ver>-<target>.<ext>` |
| AC-RA-04 | Code signing strategy defined (at minimum: macOS notarization) | Governance decision recorded | **RESIDUAL** — not implemented, documented as follow-on |
| AC-RA-05 | localbolt-app N1 packaging matrix compatibility verified | Tauri sidecar integration test | **RESIDUAL** — deferred to N-STREAM GA

---

## Item 3: SEC-DR1 — Double Ratchet Pre-ByteBolt Security Gate

**Priority:** NEXT
**Routing:** bolt-core-sdk (Rust crate), bolt-protocol (spec amendment)
**Category:** Security — pre-ByteBolt gate

**Context:** Current protocol uses static ephemeral keys per connection (no mid-session key rotation, SEC-05). For ByteBolt (persistent connections, relay-mediated), forward secrecy degrades without ratcheting. Double Ratchet (or equivalent) is a pre-ByteBolt security requirement.

**Scope assessment:** This is stream-scale work — DR-STREAM with phased plan required.

**Phased Plan (DR-STREAM):**

| Phase | Description | Status |
|-------|-------------|--------|
| DR-0 | Threat model + protocol gap analysis (relay MITM, session duration, key compromise window) | NOT-STARTED |
| DR-1 | Protocol specification amendment (PROTOCOL.md §new — ratchet lifecycle, state serialization) | NOT-STARTED |
| DR-2 | Rust reference implementation in bolt-core-sdk | NOT-STARTED |
| DR-3 | TypeScript implementation + golden vector parity | NOT-STARTED |
| DR-4 | Integration into existing handshake flow (backward-compatible negotiation) | NOT-STARTED |

**Acceptance Criteria (NEXT-tier — DR-0 and DR-1 only):**

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-DR-01 | Threat model documents relay-mediated session risks | Published analysis in docs/ |
| AC-DR-02 | Protocol amendment drafted with MUST-level invariants | PROTOCOL.md PR or draft |
| AC-DR-03 | Backward compatibility plan (capability negotiation) | Spec section |
| AC-DR-04 | Key schedule formally specified (ratchet inputs, outputs, state) | Spec section |

**AC for DR-2 through DR-4:** TBD at DR-1 completion — depends on protocol design decisions.

---

## Item 4: T-STREAM-0 — Rust Transfer Core (No UDP in v1)

**Priority:** NEXT
**Status:** **DONE** — `sdk-v0.5.30-tstream0-transfer-core-v1` + `daemon-v0.2.36-tstream0-adapter`
**Routing:** `bolt-transfer-core` (bolt-core-sdk workspace member), bolt-daemon consumer
**Category:** Architecture — shared transfer logic
**Dependencies:** B-XFER-1 (Item 1) complete (SM design stabilized)

**Boundary note vs B-XFER-1:** Item 1 completes the current daemon-local pause/resume behavior. Item 4 extracts the proven transfer state machine into a shared Rust crate for cross-platform reuse. The extraction boundary is:
- **B-XFER-1 scope:** `bolt-daemon/src/transfer.rs` pause/resume + disk writes
- **T-STREAM-0 scope:** New `bolt-transfer-core` crate extracted from daemon, consumed by daemon + app + WASM

**Context:** Transfer state machine logic (B3) currently lives in bolt-daemon. For platform convergence (PLAT-CORE1), this logic must be a shared Rust crate. Related to existing S2 (Transfer Performance Program) and S3 (Logic Not Transport) in ROADMAP.md. T-STREAM-0 is the concrete extraction; S2/S3 define the strategic direction.

**Guardrail:** No UDP transport in v1. Transfer core operates over abstract channels (WebRTC DataChannel, IPC, etc.) — transport binding is Profile-level.

**Acceptance Criteria:**

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-TC-01 | `bolt-transfer-core` crate with transport-agnostic transfer SM | Crate compiles, no transport dependencies |
| AC-TC-02 | Daemon consumes `bolt-transfer-core` (replaces inline `transfer.rs`) | Daemon tests pass with crate dependency |
| AC-TC-03 | Transfer SM states match PROTOCOL.md §9 | State enum coverage test |
| AC-TC-04 | No UDP transport binding in v1 | Code review / crate dependency audit |
| AC-TC-05 | Chunk pacing and backpressure signals (S2 subset) | Unit tests |
| AC-TC-06 | WASM build target compiles | `cargo build --target wasm32-unknown-unknown` |

---

## Item 5: T-STREAM-1 — Browser Selective WASM Integration

**Priority:** LATER
**Routing:** bolt-core-sdk (TS adapter), bolt-transfer-core (WASM target)
**Category:** Architecture — browser WASM integration
**Dependencies:** T-STREAM-0 (transfer core crate must exist)

**Context:** After T-STREAM-0 provides a WASM-compatible transfer core, the browser (TS) can selectively use WASM for transfer scheduling/state-machine decisions while retaining native WebRTC for I/O. This aligns with S2 and S4 in ROADMAP.md.

**Guardrail:** Browser retains native WebRTC transport. WASM handles logic (state machine, scheduling, backpressure), not I/O. No browser webrtc-rs swap.

**Acceptance Criteria:** AC: TBD at stream codification. Depends on T-STREAM-0 API surface and WASM bundle size constraints.

---

## Item 6: SEC-CORE2 — Rust-First Security/Protocol Consolidation

**Priority:** NEXT
**Routing:** bolt-core-sdk (Rust crate primary), bolt-core-sdk (TS secondary)
**Category:** Security — protocol authority migration
**Dependencies:** S1 conformance harness (DONE)

**Context:** Continues S3 direction (Logic Not Transport). Migrate protocol authority from TS to Rust:
- Golden vectors generated from Rust (currently TS-generated)
- Protocol state machine defined in Rust
- TS becomes consumer of Rust-generated vectors and WASM state machine

**Acceptance Criteria:**

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-SC-01 | Golden vectors generated from Rust, consumed by both Rust and TS | Rust vector generator + TS consumer tests |
| AC-SC-02 | TS vector generation deprecated (frozen, then removed) | Migration plan documented |
| AC-SC-03 | Protocol state machine canonical in Rust | Rust crate with state machine + invariants |
| AC-SC-04 | S1 conformance tests pass against Rust-generated vectors | CI gate |

---

## Item 7: PLAT-CORE1 — Shared Rust Core + Thin Platform UIs

**Priority:** LATER
**Routing:** Architecture decision required — new crate structure TBD
**Category:** Platform convergence
**Dependencies:** T-STREAM-0 (transfer core), SEC-CORE2 (Rust protocol authority)

**Context:** Converge daemon, SDK, and app Rust layers into a shared core. Platform-specific UIs (Tauri/web/mobile) become thin adapters over a unified Rust backend. This is the architectural prerequisite for mobile support.

**Acceptance Criteria:** AC: TBD at stream codification. Requires architecture decision on crate boundaries, FFI surface, and platform adapter model.

**Routing:** TBD — architecture decision required. Depends on T-STREAM-0 and SEC-CORE2 outcomes informing crate topology.

---

## Item 8: MOB-RUNTIME1 — Mobile Embedded Runtime Model

**Priority:** LATER
**Routing:** TBD — architecture decision required
**Category:** Mobile platform support
**Dependencies:** PLAT-CORE1 (shared Rust core surface must be defined first)

**Sequencing constraint:** MOB-RUNTIME1 priority MUST NOT exceed PLAT-CORE1 priority. Mobile runtime depends on the shared core surface definition from PLAT-CORE1. Attempting mobile runtime before the shared core is defined risks building on unstable abstractions.

**Context:** Define how Bolt protocol runs on mobile (iOS/Android). Options include:
- Embedded Rust library via FFI (UniFFI, swift-bridge, JNI)
- WASM runtime in mobile WebView
- Hybrid (Rust core + platform-native networking)

**Acceptance Criteria:** AC: TBD at stream codification. Depends on PLAT-CORE1 surface definition and mobile platform constraints.

**Routing:** TBD — architecture decision required. Mobile platform constraints (background execution, networking APIs, app store policies) must inform the runtime model.

---

## Item 9: ARCH-WASM1 — WASM Protocol Engine

**Priority:** LATER
**Routing:** bolt-core-sdk (Rust → WASM), bolt-core-sdk (TS adapter)
**Category:** Architecture — WASM protocol engine (medium risk)
**Dependencies:** T-STREAM-0 (transfer core), S4 gate (S2 must demonstrate viable WASM-in-browser)

**Context:** Extends S4 vision. WASM module owns state machine, enforcement codes, and message routing. TS becomes thin I/O adapter: WebRTC ↔ WASM ↔ UI. Medium risk — WASM bundle size, browser compatibility, and debugging complexity are open concerns.

**Risk factors:**
- WASM bundle size target (<100KB gzipped) may be challenging with full state machine + crypto
- Browser debugging of WASM is less mature than native JS
- Some browsers may have WASM limitations (older Safari, etc.)

**Acceptance Criteria:** AC: TBD at stream codification. Depends on T-STREAM-0 crate API and S2/S4 viability assessment.

---

## Item 10: RECON-XFER-1 — Transfer Reconnect Recovery After Mid-Transfer Disconnect

**Priority:** NOW
**Risk:** HIGH
**Status:** NOT-STARTED
**Routing:** bolt-core-sdk (`ts/bolt-transport-web` — session + transfer coordination), consumers for verification
**Category:** Reliability — transfer lifecycle across disconnect boundary
**Dependencies:** T-STREAM-1 completion (DONE) provides prerequisite context (WASM policy layer)

**Context:** User-facing reliability bug observed: if disconnect occurs during active file transfer, reconnect can get stuck and new transfers fail to start. Browser path (`localbolt.app`) confirmed. Daemon-only repro unknown/unconfirmed.

**Relationship to prior work:** This is a **distinct post-C7 transfer-recovery bug**, not a regression of prior fixes:
- Q7/C7 (DONE-VERIFIED): addressed stale callback *pollution* (wrong state shown in UI). RECON-XFER-1 is about *stuck state* (transfer path blocked, cannot start new transfer).
- C-STREAM-R1 (DONE): fixed generation guards and disconnect idempotency. RECON-XFER-1 is about transfer SM + session coordination not resetting on mid-transfer disconnect.
- UI-XFER-1 (DONE): fixed emit path correctness for pause/resume/cancel. RECON-XFER-1 is about lifecycle coordination across disconnect boundaries.

**Repro:**
1. Start file transfer between two peers.
2. Disconnect mid-transfer (network drop, tab close, WebRTC ICE failure).
3. Reconnect.
4. Attempt new transfer.
- **Actual:** Transfer path remains stuck / cannot start new transfer.
- **Expected:** Clean reconnect and immediate new-transfer capability.

**Root-cause hypothesis (docs-level):**
1. **SDK session/transfer coordination** (primary suspect) — transfer state machine does not transition to terminal reset on `disconnect` event when transfer is in-progress. `transferId`, queue pointers, and paused/sending/cancel flags survive across reconnect boundary.
2. **Consumer UI state** (secondary) — even if SDK resets, consumer-side transfer state (progress callbacks, file queue, UI flags) may not be cleaned up on reconnect.
3. **Daemon lifecycle** (conditional, escalation-only) — only relevant if daemon-side transfer SM also fails to reset on IPC disconnect during active transfer. Currently unconfirmed.

**Acceptance Criteria:**

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-RX-01 | Mid-transfer disconnect transitions transfer/session to terminal reset state | Unit tests showing disconnect during TRANSFERRING → terminal state |
| AC-RX-02 | Reconnect creates fresh session generation/token; stale callbacks are ignored | Session generation tests across disconnect boundary |
| AC-RX-03 | New transfer starts successfully in same app run after reconnect (no app restart) | Integration test: disconnect-during-transfer → reconnect → new transfer succeeds |
| AC-RX-04 | No stale transfer state crosses reconnect (`transferId`, paused/sending/cancel flags, queue pointers) | State inspection tests verifying clean slate after reconnect |
| AC-RX-05 | Pause/resume/cancel controls remain functional after reconnect | Control tests post-reconnect |
| AC-RX-06 | Automated regression test covers disconnect-during-transfer → reconnect → resend | CI-gated regression test |
| AC-RX-07 | Phased consumer verification model: Phase A — SDK + primary reproducer consumer (localbolt-v3 / localbolt.app) verified; Phase B — remaining consumers verified | Per-consumer test evidence |
| AC-RX-08 | Explicit WASM/fallback non-regression gate: reconnect-resend passes in WASM mode and in forced-fallback mode | Dual-mode test evidence |

**Phased verification model:**
- **Phase A (required for core fix DONE):** SDK fix + localbolt-v3 (`localbolt.app`) verified as primary reproducer consumer.
- **Phase B (required for full rollout closeout):** localbolt and localbolt-app verified.

**Daemon scope:** Escalation-only. Not in initial scope unless evidence emerges showing daemon-side lifecycle contribution to the stuck state.

**Open PM Decisions:**

| ID | Decision | Status |
|----|----------|--------|
| PM-RX-01 | Confirm severity NOW / HIGH | **APPROVED** |
| PM-RX-02 | Confirm Phase A primary reproducer (localbolt.app via localbolt-v3) | **APPROVED** |
| PM-RX-03 | Confirm daemon investigation is escalation-only | **APPROVED** |

---

## Routing Summary

| Item | Routing | Certainty |
|------|---------|-----------|
| B-XFER-1 | bolt-daemon | Confirmed |
| REL-ARCH1 | bolt-daemon + bolt-ecosystem | Confirmed |
| SEC-DR1 | bolt-core-sdk + bolt-protocol | Confirmed |
| T-STREAM-0 | New crate + bolt-daemon consumer | Confirmed |
| T-STREAM-1 | bolt-core-sdk (TS) + WASM | Confirmed |
| SEC-CORE2 | bolt-core-sdk (Rust primary) | Confirmed |
| PLAT-CORE1 | TBD — architecture decision required | Uncertain |
| MOB-RUNTIME1 | TBD — architecture decision required | Uncertain |
| ARCH-WASM1 | bolt-core-sdk + WASM | Confirmed |
| RECON-XFER-1 | bolt-core-sdk (TS primary) + consumers (verification) | Confirmed |

---

## Open PM Decisions

| ID | Decision Needed | Blocks | Priority |
|----|----------------|--------|----------|
| PM-FB-01 | B-XFER-1: Should concurrent transfers be in scope or deferred further? | AC-BX scope | NOW |
| PM-FB-02 | REL-ARCH1: Code signing budget/infrastructure (macOS notarization, Windows Authenticode) | AC-RA-04 | NOW |
| PM-FB-03 | SEC-DR1: Confirm DR-STREAM (phased) vs single-gate approach | DR scope | NEXT |
| PM-FB-04 | T-STREAM-0: Crate naming and repository location (new repo vs bolt-core-sdk workspace member) | AC-TC-01 | NEXT |
| PM-FB-05 | PLAT-CORE1: Crate topology decision — when to start architecture work | Stream codification | LATER |
| PM-FB-06 | MOB-RUNTIME1: Target platforms (iOS-only? Android-only? Both?) | Stream codification | LATER |
| PM-FB-07 | ARCH-WASM1: Bundle size budget and browser support matrix | Stream codification | LATER |
| PM-RX-01 | RECON-XFER-1: Confirm severity NOW / HIGH | Execution priority | **APPROVED** |
| PM-RX-02 | RECON-XFER-1: Confirm Phase A primary reproducer (localbolt.app via localbolt-v3) | Phase A scope | **APPROVED** |
| PM-RX-03 | RECON-XFER-1: Confirm daemon investigation is escalation-only | Phase A scope | **APPROVED** |
