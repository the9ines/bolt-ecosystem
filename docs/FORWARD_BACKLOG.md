# Bolt Ecosystem — Forward Backlog

> **Status:** Normative
> **Created:** 2026-03-08
> **Updated:** 2026-03-13 (RC2-GOV executed — shared core API governance lock, RC2 EXEC-READY)
> **Codified:** ecosystem-v0.1.120-rustify-core1-rc1-executed
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
  RECON-XFER-1 (transfer reconnect recovery) ──── PHASE-A-DONE

NOW:
  CONSUMER-BTR1 (consumer BTR rollout) ──────── depends on SEC-BTR1 completion (DONE)

NEXT:
  SEC-DR1 (Double Ratchet security gate) ──────── SUPERSEDED-BY: SEC-BTR1
  SEC-BTR1 (Bolt Transfer Ratchet) ──────────── COMPLETE (pre-ByteBolt, replaces SEC-DR1)
  T-STREAM-0 (Rust transfer core) ────────────── depends on B-XFER-1 completion
  SEC-CORE2 (Rust-first security consolidation) ── depends on S1 (DONE)

NEXT:
  RUSTIFY-CORE-1 (native-first transport + core) ── RC1 DONE; RC2 GOV-DONE, EXEC-READY (2026-03-13)
    Provisionally SUPERSEDES: SEC-CORE2, PLAT-CORE1 (pending PM-RC-07)
    Provisionally REFACTORS/DEPENDS-ON: MOB-RUNTIME1, ARCH-WASM1 (pending PM-RC-07)

LATER:
  T-STREAM-1 (browser selective WASM) ────────── depends on T-STREAM-0
  PLAT-CORE1 (shared Rust core + thin UIs) ────── provisionally SUPERSEDED-BY RUSTIFY-CORE-1 (pending PM-RC-07)
  MOB-RUNTIME1 (mobile embedded runtime) ─────── depends on RUSTIFY-CORE-1 RC4 (pending PM-RC-07)
  ARCH-WASM1 (WASM protocol engine) ──────────── depends on RUSTIFY-CORE-1 RC2 (pending PM-RC-07)
  EGUI-NATIVE-1 (desktop UI → egui) ──────────── EN1 openable now; EN2+ depends on RUSTIFY-CORE-1 RC4

NEXT (independent):
  DISCOVERY-MODE-1 (discovery mode policy) ───── no upstream dependencies; DM1 unblocked immediately
  BTR-SPEC-1 (algorithm-grade BTR spec) ──────── no upstream dependencies; BS1 unblocked immediately

Priority constraint: MOB-RUNTIME1 ≤ PLAT-CORE1 (mobile cannot exceed shared core priority).
Priority constraint: RUSTIFY-CORE-1 execution blocked until CONSUMER-BTR1 closes.
Priority constraint: EGUI-NATIVE-1 EN2+ blocked until RUSTIFY-CORE-1 RC4 completes.
No dependency constraints for DISCOVERY-MODE-1 (orthogonal to all other streams).
```

---

## Guardrails (All Items)

| ID | Guardrail | Applies To |
|----|-----------|-----------|
| G1 | Browser retains native WebRTC transport — no browser webrtc-rs swap | T-STREAM-0, T-STREAM-1, ARCH-WASM1, RUSTIFY-CORE-1 |
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

## Item 3: SEC-DR1 — Double Ratchet Pre-ByteBolt Security Gate [SUPERSEDED]

**Priority:** ~~NEXT~~ → SUPERSEDED
**Status:** **SUPERSEDED-BY: SEC-BTR1** (Item 11). DR-STREAM-1 frozen for traceability.
**Routing:** bolt-core-sdk (Rust crate + TS parity), bolt-protocol (spec amendment)
**Category:** Security — pre-ByteBolt gate
**Stream:** DR-STREAM-1 (frozen — no phases will execute)
**Frozen specification:** `docs/GOVERNANCE_WORKSTREAMS.md` § DR-STREAM-1 [SUPERSEDED]

**Supersession rationale (PM-BTR-01 through PM-BTR-04, 2026-03-09):**
The Signal Double Ratchet is optimized for asynchronous bidirectional messaging with out-of-order delivery. Bolt is a file transfer protocol with ordered chunks, clear transfer boundaries, and unidirectional data flow per transfer. PM approved replacement architecture (BTR — Bolt Transfer Ratchet) purpose-built for file transfer semantics. DR P0 audit findings (codebase state, rendezvous opacity, shared-crate feasibility) inherited by BTR-STREAM-1.

**P0 Audit Results (2026-03-09) — inherited by SEC-BTR1:**
- **bolt-core-sdk:** NaCl box, static ephemeral per session, no KDF chain. Shared crate feasibility: HIGH.
- **bolt-protocol:** No ratchet in v1. Capability negotiation supports new capabilities.
- **bolt-daemon:** `SessionContext` holds ephemeral keypair.
- **bolt-rendezvous:** Fully opaque to payload. ZERO changes needed.

**DR-STREAM-1 phases (all frozen at NOT-STARTED):**
DR-0 through DR-5, AC-DR-01 through AC-DR-38, DR-F1–F99 tracker series — all frozen. See `docs/GOVERNANCE_WORKSTREAMS.md` § DR-STREAM-1 [SUPERSEDED] for full frozen spec.

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
**Status:** Provisionally SUPERSEDED-BY RUSTIFY-CORE-1 (pending PM-RC-07)
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
**Status:** Provisionally SUPERSEDED-BY RUSTIFY-CORE-1 (pending PM-RC-07)
**Routing:** Architecture decision required — new crate structure TBD
**Category:** Platform convergence
**Dependencies:** T-STREAM-0 (transfer core), SEC-CORE2 (Rust protocol authority)

**Context:** Converge daemon, SDK, and app Rust layers into a shared core. Platform-specific UIs (Tauri/web/mobile) become thin adapters over a unified Rust backend. This is the architectural prerequisite for mobile support.

**Acceptance Criteria:** AC: TBD at stream codification. Requires architecture decision on crate boundaries, FFI surface, and platform adapter model.

**Routing:** TBD — architecture decision required. Depends on T-STREAM-0 and SEC-CORE2 outcomes informing crate topology.

---

## Item 8: MOB-RUNTIME1 — Mobile Embedded Runtime Model

**Priority:** LATER
**Status:** Provisionally DEPENDS-ON RUSTIFY-CORE-1 RC4 (pending PM-RC-07)
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
**Status:** Provisionally DEPENDS-ON RUSTIFY-CORE-1 RC2 (pending PM-RC-07)
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
**Status:** PHASE-A-DONE
**Routing:** bolt-core-sdk (`ts/bolt-transport-web` — test-only), localbolt-v3 (primary fix), consumers for Phase B verification
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

**Phase A Root-Cause Determination (CONFIRMED):**

**Verdict: SDK core teardown SUFFICIENT. Bug is localbolt-v3 consumer orchestration.**

Two compounding root causes in `packages/localbolt-web/src/components/peer-connection.ts`:

1. **RC-1**: `serviceGeneration` captured once at init (line 432), never updated across reconnect — all SDK callbacks silently dropped as stale after first disconnect.
2. **RC-2**: SDK `WebRTCService` follows one-shot lifecycle (constructor registers signaling listener, `disconnect()` permanently removes it) — reusing same instance after user-initiated disconnect means no signal delivery for reconnect.

**Fix**: `createFreshRtcService()` factory creates new `WebRTCService` per connection attempt, synchronizes `serviceGeneration`, fully detaches old service before swap (guardrail: `setConnectionStateHandler(() => {})` + `disconnect()` before new instance).

**Tags**: `sdk-v0.5.35-recon-xfer1-phase-a-tests` (2f219d4), `v3.0.88-recon-xfer1-phase-a` (a7e311b)

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

## Item 11: SEC-BTR1 — Bolt Transfer Ratchet Pre-ByteBolt Security Gate

**Priority:** NEXT
**Status:** **BTR-STREAM-1 COMPLETE** (BTR-0–5 DONE. Option C approved: default-on fail-open. PM-BTR-08/09/11 approved 2026-03-11)
**Routing:** bolt-core-sdk (Rust crate + TS parity), bolt-protocol (spec amendment)
**Category:** Security — pre-ByteBolt gate (blocks ByteBolt start)
**Stream:** BTR-STREAM-1 (phased)
**Replaces:** SEC-DR1 / DR-STREAM-1 (per PM-BTR-01 through PM-BTR-04)
**Full specification:** `docs/GOVERNANCE_WORKSTREAMS.md` § BTR-STREAM-1

**Context:** Current protocol uses static ephemeral keys per connection (SEC-05). For ByteBolt (persistent relay-mediated connections), forward secrecy degrades without continuous key agreement. BTR (Bolt Transfer Ratchet) is a transfer-scoped key agreement protocol purpose-built for file transfer — replacing the Signal Double Ratchet approach (SEC-DR1/DR-STREAM-1) which was designed for messaging semantics.

**Why BTR instead of Double Ratchet:**
- Bolt has ordered chunk delivery → no need for out-of-order/skipped-key complexity
- Bolt transfers are unidirectional → no need for bidirectional chain pairs
- Bolt has clear transfer boundaries (FILE_OFFER/FILE_FINISH) → natural DH ratchet points
- Simpler state (~164B vs ~200B+ with skipped keys), same security properties

**Phased Plan (BTR-STREAM-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| BTR-0 | Spec + capability negotiation lock | YES (gates all) | **DONE** (`v0.1.6-spec-btr0-lock`) |
| BTR-1 | Rust reference BTR state machine | YES (gates BTR-2, BTR-3) | **DONE** (`sdk-v0.5.36-btr1-rust-reference`) |
| BTR-2 | TypeScript parity implementation | NO (parallel with BTR-3) | **DONE** (`sdk-v0.5.37-btr2-ts-parity`) |
| BTR-3 | Cross-language vectors + conformance harness | NO (parallel with BTR-2) | **DONE** (`sdk-v0.5.38-btr3-conformance-gapfill`) |
| BTR-4 | Wire integration + compatibility rollout gates | YES (ByteBolt gate) | **DONE** (`sdk-v0.5.39-btr4-wire-integration`) |
| BTR-5 | Default-on + legacy path deprecation decision | PM decision gate | **DONE** (GO — Option C: default-on fail-open) |

**Acceptance Criteria:** 40 ACs defined (AC-BTR-01 through AC-BTR-40). See `docs/GOVERNANCE_WORKSTREAMS.md` § BTR-STREAM-1 for full list.

**Key architectural decisions (from P0):**
- Capability string: `bolt.transfer-ratchet-v1`
- Per-transfer key isolation via HKDF(session_secret, transfer_id)
- Per-chunk symmetric ratchet (chain key → message key)
- Inter-transfer DH ratchet at FILE_FINISH boundaries
- No skipped-key buffer (ordered delivery assumption)
- Memory-only state (SEC-04/SEC-05 preserved)
- Rendezvous: zero changes (inherited from DR P0 audit)
- Wire overhead: ~100B/message (~5% on 2KB chunk). Negligible.
- Crate name: `bolt-btr` (PM-BTR-06 pending)

---

## Item 12: CONSUMER-BTR1 — Consumer App BTR Rollout

**Priority:** ~~NOW~~ DONE
**Status:** **DONE** (burn-in waived via `PM-CBTR-EX-01`, 2026-03-13). CBTR-1 DONE (burn-in PASSED). CBTR-2 DONE (burn-in PASSED, 24h02m). CBTR-3 DONE (`localbolt-app-v1.2.24`, `ff33747`; burn-in waived).
**Routing:** localbolt-v3, localbolt, localbolt-app
**Category:** Rollout — BTR consumer adoption
**Stream:** CONSUMER-BTR-1 (phased)
**Dependencies:** BTR-STREAM-1 complete (`ecosystem-v0.1.107-btr5-pm-resolved`)

**Context:** BTR-STREAM-1 delivered the Bolt Transfer Ratchet at the SDK level with a kill switch defaulting to OFF. The approved BTR-5 policy (Option C: default-on fail-open) requires consumer apps to adopt the BTR-capable SDK and enable `btrEnabled: true`. This is a rollout stream — no protocol or SDK changes. Each phase updates SDK dependency, enables BTR, and verifies correct behavior including downgrade with legacy peers.

**Phased Plan (CONSUMER-BTR-1):**

| Phase | Description | Repo | Status |
|-------|-------------|------|--------|
| CBTR-1 | localbolt-v3 (localbolt.app) BTR rollout | localbolt-v3 | **DONE** — `v3.0.89-consumer-btr1-p1` (`e34e617`). Burn-in PASSED. |
| CBTR-2 | localbolt (web) BTR rollout | localbolt | **DONE** — `localbolt-v1.0.36-consumer-btr1-p2` (`e75271a`). Burn-in PASSED (24h02m). |
| CBTR-3 | localbolt-app (Tauri native) BTR rollout | localbolt-app | **DONE** — `localbolt-app-v1.2.24-consumer-btr1-p3` (`ff33747`). Burn-in waived (`PM-CBTR-EX-01`). |

**Acceptance Criteria:** 20 ACs defined (AC-CBTR-01 through AC-CBTR-20). See `docs/GOVERNANCE_WORKSTREAMS.md` § CONSUMER-BTR-1 for full list.

**Scope per phase:** Update SDK dependency to BTR-4-capable version. Enable `btrEnabled: true`. Verify BTR↔BTR and BTR↔non-BTR transfers. Verify kill switch rollback. No UI changes required.

**Parallelization:** All three phases are independently deployable and may run in parallel. Recommended: CBTR-1 first (primary reproducer), then CBTR-2 + CBTR-3 in parallel.

**Blocker (RESOLVED):** CBTR-F1 (MEDIUM) — receiver pause/resume fixed in `sdk-v0.5.40-cbtr-f1-receiver-pause` (`c164fc1`). Added `isReceiver` param to pause/resume mirroring cancel pattern. 6 new tests. No longer blocks CBTR-2/3.

---

## Item 13: RUSTIFY-CORE-1 — Native-First Transport + Core Consolidation

**Priority:** NEXT
**Status:** **RC1 DONE** (`ecosystem-v0.1.120-rustify-core1-rc1-executed`, 2026-03-13). RC2 **GOV-DONE, EXEC-READY** (`ecosystem-v0.1.122-rustify-core1-rc2gov-executed`, 2026-03-13).
**Routing:** bolt-core-sdk (Rust primary), bolt-daemon, bolt-protocol (spec amendments)
**Category:** Architecture — native transport + Rust core consolidation
**Stream:** RUSTIFY-CORE-1 (phased, 7 phases RC1–RC7)
**Dependencies:** CONSUMER-BTR1 complete (satisfied)
**Full specification:** `docs/GOVERNANCE_WORKSTREAMS.md` § RUSTIFY-CORE-1

**Context:** Current ecosystem has split protocol authority (TS owns wire orchestration, Rust owns reference crypto + transfer SM). Native app paths route through IPC to Rust daemon but depend on TS for session lifecycle in Tauri WebView. RUSTIFY-CORE-1 consolidates protocol authority in Rust and introduces native transport for app↔app while retaining WebRTC for browser↔browser.

**Transport matrix (RC1 LOCKED, 2026-03-13):**
- browser↔browser: WebRTC (LOCKED — retained baseline, invariant)
- app↔app: Rust native transport, QUIC (**LOCKED** — PM-RC-01 APPROVED, 2026-03-13)
- browser↔app: browser client transport + Rust endpoint/core (PROVISIONAL — pending PM-RC-02)
- app↔relay/cloud: DEFERRED (out of scope RC1–RC4, ByteBolt scope per ARCH-05/ARCH-07)

**Rustification boundary (RC1 LOCKED, 2026-03-13):**
- Rust owns: shared protocol/security core, transfer SM integrity/policy authority, lifecycle invariants
- Platform adapters (TS/Swift/Tauri): thin shells for I/O binding, UI routing, platform persistence

**Stream relationship (PROVISIONAL, pending PM-RC-07):**
- Provisionally SUPERSEDES: SEC-CORE2, PLAT-CORE1
- Provisionally REFACTORS/DEPENDS-ON: MOB-RUNTIME1, ARCH-WASM1
- No silent supersession until PM-RC-07 confirms

**Acceptance Criteria:** 33 ACs defined (AC-RC-01 through AC-RC-33). RC1 ACs: AC-RC-01 DONE, AC-RC-02 DONE, AC-RC-03 PROVISIONAL, AC-RC-04 DONE. See `docs/GOVERNANCE_WORKSTREAMS.md` § RUSTIFY-CORE-1 for full list.

**PM Decisions:** 8 total (PM-RC-01 through PM-RC-07 + PM-RC-01A). PM-RC-01 APPROVED (QUIC confirmed). PM-RC-01A PENDING (library selection, blocks RC3 only). PM-RC-02–07 PENDING. See `docs/GOVERNANCE_WORKSTREAMS.md` § RUSTIFY-CORE-1 for full table.

---

## Item 14: EGUI-NATIVE-1 — Native Desktop UI Consolidation (egui)

**Priority:** LATER
**Status:** CODIFIED (EN1 PM gate openable in parallel with RUSTIFY-CORE-1 RC1–RC2; EN2+ blocked on RC4)
**Routing:** localbolt-app (primary), bolt-ecosystem (governance)
**Category:** UI architecture — desktop WebView→egui migration
**Stream:** EGUI-NATIVE-1 (phased, 5 phases EN1–EN5)
**Dependencies:** RUSTIFY-CORE-1 RC4 (shared Rust core adoption) for EN2+

**Context:** Current desktop app (localbolt-app) uses Tauri v2 with React/TypeScript/Tailwind WebView UI. EGUI-NATIVE-1 migrates desktop UI to egui (Rust-native immediate-mode GUI) for unified Rust desktop application. Browser and mobile UI migration are explicitly deferred to separate future streams (EGUI-WASM-1, EGUI-MOBILE-1).

**Phased Plan (EGUI-NATIVE-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| EN1 | PM framework lock gate (egui vs alternatives) | YES (gates EN2) | NOT-STARTED |
| EN2 | Desktop `bolt-ui` scaffold + theme baseline | YES (gates EN3) | NOT-STARTED |
| EN3 | Desktop feature parity migration (core screens/workflows) | YES (gates EN4) | NOT-STARTED |
| EN4 | Rollback/compatibility gate + packaging impact verification | YES (gates EN5) | NOT-STARTED |
| EN5 | Closure + handoff to optional EGUI-WASM-1 / EGUI-MOBILE-1 proposals | YES (closes stream) | NOT-STARTED |

**Acceptance Criteria:** 24 ACs defined (AC-EN-01 through AC-EN-24). See `docs/GOVERNANCE_WORKSTREAMS.md` § EGUI-NATIVE-1 for full list.

**PM Decisions:** 5 open (PM-EN-01 through PM-EN-05). See `docs/GOVERNANCE_WORKSTREAMS.md` § EGUI-NATIVE-1 for full table.

**Scope guardrails:**
- EN-G1: No protocol/transport changes
- EN-G2: Desktop only; browser/mobile deferred
- EN-G3: Rollback to pre-egui path required during migration window
- EN-G4: `bolt-ui` must be transport-independent
- EN-G5: No CLI deliverables

**Deferred streams (governance reservation only):**
- EGUI-WASM-1: Browser UI migration to egui via WASM (trigger: PM-EN-04 after EN3)
- EGUI-MOBILE-1: Mobile UI via egui (trigger: PM-EN-05 after EN4)

---

## Item 15: DISCOVERY-MODE-1 — Dual Discovery Mode Policy Codification

**Priority:** NEXT
**Status:** CODIFIED (DM1 PM gate unblocked immediately; no upstream dependencies)
**Routing:** bolt-ecosystem (governance), localbolt-v3 + localbolt + localbolt-app (implementation phases)
**Category:** Policy — discovery mode semantics
**Stream:** DISCOVERY-MODE-1 (phased, 4 phases DM1–DM4)
**Dependencies:** None (orthogonal to all active streams)

**Context:** Current consumer apps implement dual discovery via `DualSignaling` class. Mode is implicit from URL configuration (cloud URL present → HYBRID; absent → LAN_ONLY). No governance-level mode policy exists, no user-visible mode indicator, no codified dedup invariants. P0 audit confirmed behavior is correct but undocumented at governance level.

**P0 Audit findings (2026-03-12):**
1. No user-visible mode indicator (console-only warning)
2. No peer origin exposed to UI (`DiscoveredDevice` has no source field)
3. Inconsistent env var naming across consumers
4. Dedup policy works but is not codified
5. CLOUD_ONLY not possible (no mechanism to disable local while keeping cloud)

**Mode definitions:**
- **LAN_ONLY** (required): Local signaling only. Cloud disabled/absent. Peers from local server only.
- **HYBRID** (required, recommended default): Local + cloud active. Merged deduplicated peer list. First-discovery-wins, source-aware loss.
- **CLOUD_ONLY** (deferred): Reserved as future extension. PM-DM-04 must approve before codification.

**Phased Plan (DISCOVERY-MODE-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| DM1 | PM mode policy lock (default mode, UI reqs, CLOUD_ONLY disposition) | YES (gates DM2) | NOT-STARTED |
| DM2 | Mode indicator implementation across consumers | YES (gates DM3) | NOT-STARTED |
| DM3 | Mode-aware acceptance test harness | YES (gates DM4) | NOT-STARTED |
| DM4 | Env var harmonization + documentation alignment + closure | YES (closes stream) | NOT-STARTED |

**Acceptance Criteria:** 16 ACs defined (AC-DM-01 through AC-DM-16). See `docs/GOVERNANCE_WORKSTREAMS.md` § DISCOVERY-MODE-1 for full list.

**PM Decisions:** 4 open (PM-DM-01 through PM-DM-04). See `docs/GOVERNANCE_WORKSTREAMS.md` § DISCOVERY-MODE-1 for full table.

**Risk register:** No material discovery-policy risks identified at codification.

---

## Item 16: BTR-SPEC-1 — Algorithm-Grade BTR Protocol Specification

**Priority:** NEXT
**Status:** CODIFIED (BS1 unblocked immediately)
**Routing:** bolt-protocol (primary — spec text), bolt-ecosystem (governance)
**Category:** Specification — formal BTR protocol documentation
**Stream:** BTR-SPEC-1 (phased, 5 phases BS1–BS5)
**Dependencies:** None (COMPLEMENTS SEC-BTR1, CONSUMER-BTR1, RUSTIFY-CORE-1)

**Context:** BTR has full implementation coverage (341 tests, 10 vector files) and substantial spec text in PROTOCOL.md §16 (300+ lines). P0 audit confirmed 5/7 modules fully specified; 2 gaps: flow control/backpressure (BTR-FC) and resume/recovery (BTR-RSM). BTR-SPEC-1 fills gaps, formalizes module boundaries, and adds change-control policy for independent-implementation-grade specification.

**Phased Plan (BTR-SPEC-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| BS1 | Module taxonomy + boundary lock | YES (gates BS2) | NOT-STARTED |
| BS2 | State machines + crypto/key-schedule lock | YES (gates BS3) | NOT-STARTED |
| BS3 | Wire format + failure/recovery semantics lock | YES (gates BS4) | NOT-STARTED |
| BS4 | Conformance vectors + negative-test matrix lock | YES (gates BS5) | NOT-STARTED |
| BS5 | Versioning/change-control + external review readiness | YES (closes stream) | NOT-STARTED |

**Acceptance Criteria:** 22 ACs defined (AC-BS-01 through AC-BS-22). See `docs/GOVERNANCE_WORKSTREAMS.md` § BTR-SPEC-1.

**PM Decisions:** 6 open (PM-BS-01 through PM-BS-06). See `docs/GOVERNANCE_WORKSTREAMS.md` § BTR-SPEC-1.

**Risk register:** 4 risks (BS-R1–R4), all LOW–MEDIUM.

---

## Routing Summary

| Item | Routing | Certainty |
|------|---------|-----------|
| B-XFER-1 | bolt-daemon | Confirmed |
| REL-ARCH1 | bolt-daemon + bolt-ecosystem | Confirmed |
| SEC-DR1 | bolt-core-sdk + bolt-protocol | Confirmed (SUPERSEDED by SEC-BTR1) |
| SEC-BTR1 | bolt-core-sdk + bolt-protocol | Confirmed |
| T-STREAM-0 | New crate + bolt-daemon consumer | Confirmed |
| T-STREAM-1 | bolt-core-sdk (TS) + WASM | Confirmed |
| SEC-CORE2 | bolt-core-sdk (Rust primary) | Confirmed |
| PLAT-CORE1 | TBD — architecture decision required | Uncertain |
| MOB-RUNTIME1 | TBD — architecture decision required | Uncertain |
| ARCH-WASM1 | bolt-core-sdk + WASM | Confirmed |
| RECON-XFER-1 | bolt-core-sdk (TS primary) + consumers (verification) | Confirmed |
| CONSUMER-BTR1 | localbolt-v3 + localbolt + localbolt-app | Confirmed |
| RUSTIFY-CORE-1 | bolt-core-sdk (Rust) + bolt-daemon + bolt-protocol | Confirmed |
| EGUI-NATIVE-1 | localbolt-app + bolt-ecosystem | Confirmed |
| DISCOVERY-MODE-1 | bolt-ecosystem + localbolt-v3 + localbolt + localbolt-app | Confirmed |
| BTR-SPEC-1 | bolt-protocol + bolt-ecosystem | Confirmed |

---

## Open PM Decisions

| ID | Decision Needed | Blocks | Priority |
|----|----------------|--------|----------|
| PM-FB-01 | B-XFER-1: Should concurrent transfers be in scope or deferred further? | AC-BX scope | NOW |
| PM-FB-02 | REL-ARCH1: Code signing budget/infrastructure (macOS notarization, Windows Authenticode) | AC-RA-04 | NOW |
| PM-FB-03 | SEC-DR1: Confirm DR-STREAM (phased) vs single-gate approach | DR scope | **RESOLVED** → **SUPERSEDED** (DR replaced by BTR per PM-BTR-01–04) |
| PM-FB-08 | SEC-BTR1: Confirm downgrade-with-warning as default compat mode | BTR-0 spec lock | **APPROVED** |
| PM-FB-09 | SEC-BTR1: Confirm memory-only key storage | BTR-0 spec lock | **APPROVED** |
| PM-FB-10 | SEC-BTR1: External security audit timing (pre-GA or pre-default-on?) | BTR-4/BTR-5 | **APPROVED** (PM-BTR-11: before GA, not before default-on) |
| PM-FB-04 | T-STREAM-0: Crate naming and repository location (new repo vs bolt-core-sdk workspace member) | AC-TC-01 | NEXT |
| PM-FB-05 | PLAT-CORE1: Crate topology decision — when to start architecture work | Stream codification | LATER |
| PM-FB-06 | MOB-RUNTIME1: Target platforms (iOS-only? Android-only? Both?) | Stream codification | LATER |
| PM-FB-07 | ARCH-WASM1: Bundle size budget and browser support matrix | Stream codification | LATER |
| PM-RX-01 | RECON-XFER-1: Confirm severity NOW / HIGH | Execution priority | **APPROVED** |
| PM-RX-02 | RECON-XFER-1: Confirm Phase A primary reproducer (localbolt.app via localbolt-v3) | Phase A scope | **APPROVED** |
| PM-RX-03 | RECON-XFER-1: Confirm daemon investigation is escalation-only | Phase A scope | **APPROVED** |
| PM-CBTR-01 | CONSUMER-BTR1: Confirm CBTR-1 first (localbolt-v3 as primary rollout target) | Phase sequencing | **APPROVED** — localbolt-v3 → localbolt → localbolt-app |
| PM-CBTR-02 | CONSUMER-BTR1: Dark launch burn-in per-consumer or shared across stream? | Rollout timing | **APPROVED** — 24h clean run per phase before promoting |
| PM-RC-01 | RUSTIFY-CORE-1: Native transport protocol — **APPROVED (QUIC confirmed, 2026-03-13)** | ~~RC3~~ | **APPROVED** |
| PM-RC-01A | RUSTIFY-CORE-1: QUIC runtime/library selection (`quinn`, `s2n-quic`, `msquic-rs`). Owner/deadline TBD. | RC3 only (non-blocking RC2) | NEXT |
| PM-RC-02 | RUSTIFY-CORE-1: Browser↔app transport mode default | RC5 | NEXT |
| PM-RC-03 | RUSTIFY-CORE-1: Rollout order (app first, browser↔app second) | RC6 | NEXT |
| PM-RC-04 | RUSTIFY-CORE-1: Performance SLO thresholds for migration gates | RC3 | NEXT |
| PM-RC-05 | RUSTIFY-CORE-1: Legacy TS-path deprecation policy/timeline | RC6 | NEXT |
| PM-RC-06 | RUSTIFY-CORE-1: CLI stream trigger condition | RC7 | NEXT |
| PM-RC-07 | RUSTIFY-CORE-1: Relationship mode to SEC-CORE2/PLAT-CORE1/MOB-RUNTIME1/ARCH-WASM1 | All RC phases | NEXT |
| PM-EN-01 | EGUI-NATIVE-1: Confirm egui as desktop UI framework (vs iced, Slint, Dioxus) | EN2 | LATER |
| PM-EN-02 | EGUI-NATIVE-1: Visual direction scope (minimal parity vs custom theme) | EN2 | LATER |
| PM-EN-03 | EGUI-NATIVE-1: Rollback window duration before legacy UI removal | EN5 | LATER |
| PM-EN-04 | EGUI-NATIVE-1: Whether to open EGUI-WASM-1 after EN3 results | Post-stream | LATER |
| PM-EN-05 | EGUI-NATIVE-1: Whether to open EGUI-MOBILE-1 after EN4 results | Post-stream | LATER |
| PM-DM-01 | DISCOVERY-MODE-1: Default discovery mode (HYBRID recommended vs LAN_ONLY) | DM2 | NEXT |
| PM-DM-02 | DISCOVERY-MODE-1: User-facing mode toggle required? (toggle UI vs config-only) | DM2 | NEXT |
| PM-DM-03 | DISCOVERY-MODE-1: Wording/UX for mode indicator and peer origin display | DM2 | NEXT |
| PM-DM-04 | DISCOVERY-MODE-1: CLOUD_ONLY — codify now as optional mode, or defer entirely? | DM4 | NEXT |
| PM-BS-01 | BTR-SPEC-1: Crypto primitive baseline confirmation (NaCl box + HKDF-SHA256) | BS2 | NEXT |
| PM-BS-02 | BTR-SPEC-1: Rekey thresholds/lifecycle policy | BS2 | NEXT |
| PM-BS-03 | BTR-SPEC-1: Wire format versioning policy | BS3 | NEXT |
| PM-BS-04 | BTR-SPEC-1: Compatibility contract (strict vs tolerant parsing) | BS3 | NEXT |
| PM-BS-05 | BTR-SPEC-1: External review gate (scope, reviewer profile, acceptance bar) | BS5 | NEXT |
| PM-BS-06 | BTR-SPEC-1: Ratify relationship mode (COMPLEMENTS) with SEC-BTR1/CONSUMER-BTR1/RUSTIFY-CORE-1 | BS5 | NEXT |
