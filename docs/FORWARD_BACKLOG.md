# Bolt Ecosystem — Forward Backlog

> **Status:** Normative
> **Created:** 2026-03-08
> **Codified:** ecosystem-v0.1.86-roadmap-codify-transfer-security-mobile
> **Authority:** PM-approved. Execution requires separate phase prompts per item.

---

## Purpose

This document codifies the post-R17 forward backlog: 9 items spanning transfer completion, release architecture, security, platform convergence, and mobile readiness. Items are prioritized into NOW / NEXT / LATER tiers with acceptance criteria defined for NOW and NEXT items. LATER items have AC deferred to stream codification.

Linked from `docs/GOVERNANCE_WORKSTREAMS.md` (summary) and `docs/ROADMAP.md` (dependency map).

---

## Priority / Dependency Matrix

```
NOW:
  B-XFER-1 (transfer pause/resume completion) ─── daemon-local scope
  REL-ARCH1 (multi-arch build matrix) ─────────── independent

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

**Context:** Daemon builds currently target the CI runner architecture only. For production distribution (N-STREAM-1 GA rollout per N4), pre-built binaries are needed for:
- macOS (aarch64-apple-darwin, x86_64-apple-darwin)
- Linux (x86_64-unknown-linux-gnu, aarch64-unknown-linux-gnu)
- Windows (x86_64-pc-windows-msvc)

**Acceptance Criteria:**

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-RA-01 | CI matrix builds daemon for all 5 targets | GitHub Actions workflow with cross-compilation |
| AC-RA-02 | Release artifacts published per tag | `gh release create` with binaries attached |
| AC-RA-03 | Binary naming convention codified | Documented in bolt-daemon README or RELEASE.md |
| AC-RA-04 | Code signing strategy defined (at minimum: macOS notarization) | Governance decision recorded |
| AC-RA-05 | localbolt-app N1 packaging matrix compatibility verified | Tauri sidecar integration test |

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
**Routing:** New crate (e.g., `bolt-transfer-core`), bolt-daemon consumer, bolt-core-sdk consumer
**Category:** Architecture — shared transfer logic
**Dependencies:** B-XFER-1 (Item 1) should be complete first to stabilize transfer SM design

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
