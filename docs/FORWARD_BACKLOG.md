# Bolt Ecosystem — Forward Backlog

> **Status:** Normative
> **Created:** 2026-03-08
> **Updated:** 2026-03-12 (consistency fix — CONSUMER-BTR1 IN-PROGRESS, SEC-CORE2/PLAT-CORE1 provisional status aligned)
> **Codified:** ecosystem-v0.1.107-btr5-pm-resolved
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
  RUSTIFY-CORE-1 (native-first transport + core) ── depends on CONSUMER-BTR1 completion
    Provisionally SUPERSEDES: SEC-CORE2, PLAT-CORE1 (pending PM-RC-07)
    Provisionally REFACTORS/DEPENDS-ON: MOB-RUNTIME1, ARCH-WASM1 (pending PM-RC-07)

LATER:
  T-STREAM-1 (browser selective WASM) ────────── depends on T-STREAM-0
  PLAT-CORE1 (shared Rust core + thin UIs) ────── provisionally SUPERSEDED-BY RUSTIFY-CORE-1 (pending PM-RC-07)
  MOB-RUNTIME1 (mobile embedded runtime) ─────── depends on RUSTIFY-CORE-1 RC4 (pending PM-RC-07)
  ARCH-WASM1 (WASM protocol engine) ──────────── depends on RUSTIFY-CORE-1 RC2 (pending PM-RC-07)

Priority constraint: MOB-RUNTIME1 ≤ PLAT-CORE1 (mobile cannot exceed shared core priority).
Priority constraint: RUSTIFY-CORE-1 execution blocked until CONSUMER-BTR1 closes.
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

**Priority:** NOW
**Status:** IN-PROGRESS. CBTR-1 DONE (burn-in PASSED). CBTR-2 P2 DONE (`localbolt-v1.0.36`, `e75271a`), burn-in active. CBTR-3 awaiting CBTR-2 burn-in.
**Routing:** localbolt-v3, localbolt, localbolt-app
**Category:** Rollout — BTR consumer adoption
**Stream:** CONSUMER-BTR-1 (phased)
**Dependencies:** BTR-STREAM-1 complete (`ecosystem-v0.1.107-btr5-pm-resolved`)

**Context:** BTR-STREAM-1 delivered the Bolt Transfer Ratchet at the SDK level with a kill switch defaulting to OFF. The approved BTR-5 policy (Option C: default-on fail-open) requires consumer apps to adopt the BTR-capable SDK and enable `btrEnabled: true`. This is a rollout stream — no protocol or SDK changes. Each phase updates SDK dependency, enables BTR, and verifies correct behavior including downgrade with legacy peers.

**Phased Plan (CONSUMER-BTR-1):**

| Phase | Description | Repo | Status |
|-------|-------------|------|--------|
| CBTR-1 | localbolt-v3 (localbolt.app) BTR rollout | localbolt-v3 | **DONE** — `v3.0.89-consumer-btr1-p1` (`e34e617`). Burn-in PASSED. |
| CBTR-2 | localbolt (web) BTR rollout | localbolt | **P2 DONE** — `localbolt-v1.0.36-consumer-btr1-p2` (`e75271a`). Burn-in active. |
| CBTR-3 | localbolt-app (Tauri native) BTR rollout | localbolt-app | UNBLOCKED — awaiting CBTR-2 24h burn-in |

**Acceptance Criteria:** 20 ACs defined (AC-CBTR-01 through AC-CBTR-20). See `docs/GOVERNANCE_WORKSTREAMS.md` § CONSUMER-BTR-1 for full list.

**Scope per phase:** Update SDK dependency to BTR-4-capable version. Enable `btrEnabled: true`. Verify BTR↔BTR and BTR↔non-BTR transfers. Verify kill switch rollback. No UI changes required.

**Parallelization:** All three phases are independently deployable and may run in parallel. Recommended: CBTR-1 first (primary reproducer), then CBTR-2 + CBTR-3 in parallel.

**Blocker (RESOLVED):** CBTR-F1 (MEDIUM) — receiver pause/resume fixed in `sdk-v0.5.40-cbtr-f1-receiver-pause` (`c164fc1`). Added `isReceiver` param to pause/resume mirroring cancel pattern. 6 new tests. No longer blocks CBTR-2/3.

---

## Item 13: RUSTIFY-CORE-1 — Native-First Transport + Core Consolidation

**Priority:** NEXT
**Status:** CODIFIED (execution blocked until CONSUMER-BTR1 completes)
**Routing:** bolt-core-sdk (Rust primary), bolt-daemon, bolt-protocol (spec amendments)
**Category:** Architecture — native transport + Rust core consolidation
**Stream:** RUSTIFY-CORE-1 (phased, 7 phases RC1–RC7)
**Dependencies:** CONSUMER-BTR1 complete
**Full specification:** `docs/GOVERNANCE_WORKSTREAMS.md` § RUSTIFY-CORE-1

**Context:** Current ecosystem has split protocol authority (TS owns wire orchestration, Rust owns reference crypto + transfer SM). Native app paths route through IPC to Rust daemon but depend on TS for session lifecycle in Tauri WebView. RUSTIFY-CORE-1 consolidates protocol authority in Rust and introduces native transport for app↔app while retaining WebRTC for browser↔browser.

**Transport matrix (policy draft, pending PM-RC-01):**
- browser↔browser: WebRTC (retained)
- app↔app: Rust native transport (QUIC recommended)
- browser↔app: browser client transport + Rust endpoint/core

**Stream relationship (provisional, pending PM-RC-07):**
- Provisionally SUPERSEDES: SEC-CORE2, PLAT-CORE1
- Provisionally REFACTORS/DEPENDS-ON: MOB-RUNTIME1, ARCH-WASM1

**Acceptance Criteria:** 33 ACs defined (AC-RC-01 through AC-RC-33). See `docs/GOVERNANCE_WORKSTREAMS.md` § RUSTIFY-CORE-1 for full list.

**PM Decisions:** 7 open (PM-RC-01 through PM-RC-07). See `docs/GOVERNANCE_WORKSTREAMS.md` § RUSTIFY-CORE-1 for full table.

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
| PM-RC-01 | RUSTIFY-CORE-1: Native transport protocol (QUIC recommended vs alternative) | RC3 | NEXT |
| PM-RC-02 | RUSTIFY-CORE-1: Browser↔app transport mode default | RC5 | NEXT |
| PM-RC-03 | RUSTIFY-CORE-1: Rollout order (app first, browser↔app second) | RC6 | NEXT |
| PM-RC-04 | RUSTIFY-CORE-1: Performance SLO thresholds for migration gates | RC3 | NEXT |
| PM-RC-05 | RUSTIFY-CORE-1: Legacy TS-path deprecation policy/timeline | RC6 | NEXT |
| PM-RC-06 | RUSTIFY-CORE-1: CLI stream trigger condition | RC7 | NEXT |
| PM-RC-07 | RUSTIFY-CORE-1: Relationship mode to SEC-CORE2/PLAT-CORE1/MOB-RUNTIME1/ARCH-WASM1 | All RC phases | NEXT |
