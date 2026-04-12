# Bolt Ecosystem — Forward Backlog

> **Status:** Normative
> **Created:** 2026-03-08
> **Updated:** 2026-03-23 (Architecture audit codified. Drift tracking + anti-patterns + 4 migration streams added.)
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
  SEC-CORE2 (Rust-first security consolidation) ── SUPERSEDED-BY RUSTIFY-CORE-1 (PM-RC-07)

NEXT:
  RUSTIFY-CORE-1 (native-first transport + core) ── RC1 DONE; RC2 DONE; RC3 DONE; RC4 DONE (2026-03-14, AC-RC-12–20 PASS); PM-RC-02 APPROVED (WebSocket-direct, 2026-03-14); RC5 DONE (2026-03-14, AC-RC-21–24 PASS); PM-RC-03 APPROVED (app-first rollout, 2026-03-14); PM-RC-05 APPROVED (deprecate-but-retain, 2026-03-14); RC6 DONE (2026-03-14, AC-RC-25–28 PASS); RC7 DONE (2026-03-14, AC-RC-29–33 PASS, PM-RC-06 APPROVED)
    SUPERSEDES: SEC-CORE2, PLAT-CORE1 (PM-RC-07 APPROVED 2026-03-14)
    REFACTORS/DEPENDS-ON: MOB-RUNTIME1, ARCH-WASM1 (PM-RC-07 APPROVED 2026-03-14)

LATER:
  T-STREAM-1 (browser selective WASM) ────────── depends on T-STREAM-0
  PLAT-CORE1 (shared Rust core + thin UIs) ────── SUPERSEDED-BY RUSTIFY-CORE-1 (PM-RC-07)
  MOB-RUNTIME1 (mobile embedded runtime) ─────── depends on RUSTIFY-CORE-1 RC4 (PM-RC-07)
  ARCH-WASM1 (WASM protocol engine) ──────────── depends on RUSTIFY-CORE-1 RC2 (PM-RC-07)
  EGUI-NATIVE-1 (desktop UI → egui) ──────────── EN1 openable now; EN2+ depends on RUSTIFY-CORE-1 RC4

NEXT (independent):
  DISCOVERY-MODE-1 (discovery mode policy) ───── no upstream dependencies; DM1 unblocked immediately
  BTR-SPEC-1 (algorithm-grade BTR spec) ──────── no upstream dependencies; BS1 unblocked immediately
  WEBTRANSPORT-BROWSER-APP-1 (browser↔app WT) ── extends RUSTIFY-CORE-1 (complete); WT1 unblocked immediately

Priority constraint: MOB-RUNTIME1 ≤ PLAT-CORE1 (mobile cannot exceed shared core priority).
Priority constraint: RUSTIFY-CORE-1 execution blocked until CONSUMER-BTR1 closes.
Priority constraint: EGUI-NATIVE-1 EN2+ blocked until RUSTIFY-CORE-1 RC4 completes.
No dependency constraints for DISCOVERY-MODE-1 (orthogonal to all other streams).
No dependency constraints for WEBTRANSPORT-BROWSER-APP-1 (extends completed RUSTIFY-CORE-1).
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

**Priority:** ~~NEXT~~ → SUPERSEDED
**Status:** **SUPERSEDED-BY: RUSTIFY-CORE-1** (PM-RC-07 APPROVED 2026-03-14). AC-SC-01–04 absorbed by AC-RC-08–11.
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
| AC-SC-01 | Golden vectors generated from Rust, consumed by both Rust and TS | Rust vector generator + TS consumer tests | **DONE** (absorbed by AC-RC-08, RC2-EXEC-A, 2026-03-13) |
| AC-SC-02 | TS vector generation deprecated (frozen, then removed) | Migration plan documented | **DONE** (absorbed by AC-RC-09, RC2-EXEC-A, 2026-03-13) |
| AC-SC-03 | Protocol state machine canonical in Rust | Rust crate with state machine + invariants | **DONE** (absorbed by AC-RC-10, RC2-EXEC-C, 2026-03-13) |
| AC-SC-04 | S1 conformance tests pass against Rust-generated vectors | CI gate | **DONE** (absorbed by AC-RC-11, RC2-EXEC-B, 2026-03-13) |

---

## Item 7: PLAT-CORE1 — Shared Rust Core + Thin Platform UIs

**Priority:** ~~LATER~~ → SUPERSEDED
**Status:** **SUPERSEDED-BY: RUSTIFY-CORE-1** (PM-RC-07 APPROVED 2026-03-14). RC2+RC4 absorbed full scope.
**Routing:** Architecture decision required — new crate structure TBD
**Category:** Platform convergence
**Dependencies:** T-STREAM-0 (transfer core), SEC-CORE2 (Rust protocol authority)

**Context:** Converge daemon, SDK, and app Rust layers into a shared core. Platform-specific UIs (Tauri/web/mobile) become thin adapters over a unified Rust backend. This is the architectural prerequisite for mobile support.

**Acceptance Criteria:** AC: TBD at stream codification. Requires architecture decision on crate boundaries, FFI surface, and platform adapter model.

**Routing:** TBD — architecture decision required. Depends on T-STREAM-0 and SEC-CORE2 outcomes informing crate topology.

---

## Item 8: MOB-RUNTIME1 — Mobile Embedded Runtime Model

**Priority:** LATER
**Status:** **DEPENDS-ON RUSTIFY-CORE-1 RC4** (PM-RC-07 APPROVED 2026-03-14). Retains own stream identity.
**Routing:** TBD — architecture decision required
**Category:** Mobile platform support
**Dependencies:** RUSTIFY-CORE-1 RC4 (shared Rust core adoption, DONE)

**Sequencing constraint:** MOB-RUNTIME1 depends on RUSTIFY-CORE-1 RC4 (shared Rust core adoption, DONE). PLAT-CORE1 is SUPERSEDED; its shared core surface is now delivered by RUSTIFY-CORE-1.

**Context:** Define how Bolt protocol runs on mobile (iOS/Android). Options include:
- Embedded Rust library via FFI (UniFFI, swift-bridge, JNI)
- WASM runtime in mobile WebView
- Hybrid (Rust core + platform-native networking)

**Acceptance Criteria:** AC: TBD at stream codification. Depends on PLAT-CORE1 surface definition and mobile platform constraints.

**Routing:** TBD — architecture decision required. Mobile platform constraints (background execution, networking APIs, app store policies) must inform the runtime model.

---

## Item 9: ARCH-WASM1 — WASM Protocol Engine

**Priority:** ~~LATER~~ SUPERSEDED
**Status:** **SUPERSEDED-BY: RUSTIFY-BROWSER-CORE-1** (PM-RB-05 APPROVED 2026-03-17). Browser WASM protocol authority is now RUSTIFY-BROWSER-CORE-1 scope.
**Routing:** bolt-core-sdk (Rust → WASM), bolt-core-sdk (TS adapter)
**Category:** Architecture — WASM protocol engine (medium risk)
**Dependencies:** T-STREAM-0 (transfer core), RUSTIFY-CORE-1 RC2 (shared core API, DONE), S4 gate

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
**Status:** **RC1 DONE**, **RC2 DONE**, **RC3 DONE** (`daemon-v0.2.40`, 2026-03-14), **RC4 DONE** (`ecosystem-v0.1.130`, 2026-03-14), **RC5 DONE** (`daemon-v0.2.42-rustify-core1-rc5-btr-ws`, `sdk-v0.6.9-rustify-core1-rc5-ws-transport`, `ecosystem-v0.1.133-rustify-core1-rc5-done`, 2026-03-14). AC-RC-21–24 all PASS. **PM-RC-02 APPROVED** (WebSocket-direct, 2026-03-14). **RC6 DONE** (`ecosystem-v0.1.134-rustify-core1-rc6-executed`, 2026-03-14). AC-RC-25–28 all PASS. **PM-RC-03 APPROVED** (app-first rollout, 2026-03-14). **PM-RC-05 APPROVED** (deprecate-but-retain TS paths, 2026-03-14). **RC7 DONE** (`ecosystem-v0.1.135-rustify-core1-rc7-executed`, 2026-03-14). AC-RC-29–33 all PASS (governance artifacts delivered). **PM-RC-06 APPROVED** (CLI trigger *defined*: RC4 + Stage 1 burn-in). **CLI execution stream NOT OPEN** — Stage 1 burn-in evidence pending.
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

**Stream relationship (CONFIRMED, PM-RC-07 APPROVED 2026-03-14):**
- SUPERSEDES: SEC-CORE2, PLAT-CORE1
- REFACTORS/DEPENDS-ON: MOB-RUNTIME1, ARCH-WASM1

**Acceptance Criteria:** 33 ACs defined (AC-RC-01 through AC-RC-33). RC1–RC7: **all 33 ACs PASS/DONE**. See `docs/GOVERNANCE_WORKSTREAMS.md` § RUSTIFY-CORE-1 for full list.

**PM Decisions:** 8 total (PM-RC-01 through PM-RC-07 + PM-RC-01A). **All 8 APPROVED.** PM-RC-01 (QUIC). PM-RC-01A (quinn). PM-RC-02 (WebSocket-direct). PM-RC-03 (app-first rollout). PM-RC-04 (SLO thresholds). PM-RC-05 (deprecate-but-retain). PM-RC-06 (CLI trigger). PM-RC-07 (stream relationships). See `docs/GOVERNANCE_WORKSTREAMS.md` § RUSTIFY-CORE-1 for full table.

---

## Item 14: EGUI-NATIVE-1 — Native Desktop UI Consolidation (egui)

**Priority:** LATER
**Status:** **COMPLETE** (`ecosystem-v0.1.162-egui-native1-en5-closure`, 2026-03-16). EN1–EN4 delivered AC-EN-01–20; EN5 closure (AC-EN-21–24). PM-EN-01/02/03/04 APPROVED. PM-EN-05 deferred. Stream CLOSED.
**Routing:** localbolt-app (primary), bolt-ecosystem (governance)
**Category:** UI architecture — desktop WebView→egui migration
**Stream:** EGUI-NATIVE-1 (phased, 5 phases EN1–EN5)
**Dependencies:** RUSTIFY-CORE-1 RC4 (shared Rust core adoption) for EN2+

**Context:** Current desktop app (localbolt-app) uses Tauri v2 with React/TypeScript/Tailwind WebView UI. EGUI-NATIVE-1 migrates desktop UI to egui (Rust-native immediate-mode GUI) for unified Rust desktop application. Browser and mobile UI migration are explicitly deferred to separate future streams (EGUI-WASM-1, EGUI-MOBILE-1).

**Phased Plan (EGUI-NATIVE-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| EN1 | PM framework lock gate (egui vs alternatives) | YES (gates EN2) | **DONE** (AC-EN-01–04 PASS, PM-EN-01/02 APPROVED, 2026-03-15) |
| EN2 | Desktop `bolt-ui` scaffold + theme baseline | YES (gates EN3) | **DONE** (AC-EN-05–09 PASS, 2026-03-15) |
| EN3 | Desktop feature parity migration (core screens/workflows) | YES (gates EN4) | **DONE** (AC-EN-10–15 PASS, 2026-03-15) |
| EN4 | Rollback/compatibility gate + packaging | YES (gates EN5) | **DONE** (AC-EN-16–20 PASS, PM-EN-03 APPROVED, 2026-03-15) |
| EN5 | Closure + handoff | YES (closes stream) | **DONE** (AC-EN-21–24, 2026-03-16) |

**Acceptance Criteria:** 24 ACs (AC-EN-01–24). EN1–EN4 delivered AC-EN-01–20; EN5 delivered AC-EN-21–24. All 24 satisfied.

**PM Decisions:** 5 total. PM-EN-01 APPROVED (egui). PM-EN-02 APPROVED (minimal parity). PM-EN-03 APPROVED (condition-gated rollback). PM-EN-04 APPROVED (early, EGUI-WASM-1 opened). PM-EN-05 PENDING (EGUI-MOBILE-1 deferred).

**Scope guardrails:**
- EN-G1: No protocol/transport changes
- EN-G2: Desktop only; browser/mobile deferred
- EN-G3: Rollback to pre-egui path required during migration window
- EN-G4: `bolt-ui` must be transport-independent
- EN-G5: No CLI deliverables

**Follow-on streams:**
- EGUI-WASM-1: Browser UI migration to egui via WASM — **ABANDONED** (2026-03-17). EW2 PoC: 1,296 KiB gzipped (2.6× over 500 KiB kill). Stream CLOSED with findings.
- EGUI-MOBILE-1: Mobile UI via egui — **DEFERRED PROPOSAL** (PM-EN-05 PENDING). Not codified. No phases, ACs, or spec defined.

---

## Item 15: DISCOVERY-MODE-1 — Dual Discovery Mode Policy Codification

**Priority:** NEXT
**Status:** **COMPLETE** (`ecosystem-v0.1.160`, 2026-03-15). All 16 ACs PASS. All 4 PM decisions APPROVED. DM1–DM4 DONE.
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
- **HYBRID** (available, NOT default for LocalBolt): Local + cloud active. ByteBolt/web context only.
- **CLOUD_ONLY** (deferred): Reserved as future extension. PM-DM-04 must approve before codification.

**Phased Plan (DISCOVERY-MODE-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| DM1 | PM mode policy lock (default mode, UI reqs, CLOUD_ONLY disposition) | YES (gates DM2) | **DONE** (AC-DM-01–04 PASS, PM-DM-01–04 APPROVED, 2026-03-15) |
| DM2 | Mode indicator implementation across consumers | YES (gates DM3) | **DONE** (AC-DM-05–08 PASS, 2026-03-15) |
| DM3 | Mode-aware acceptance test harness | YES (gates DM4) | **DONE** (AC-DM-10–13 PASS, 11 tests, 2026-03-15) |
| DM4 | Env var harmonization + documentation alignment + closure | YES (closes stream) | **DONE** (AC-DM-14–16 PASS, 2026-03-15) |

**Acceptance Criteria:** 16 ACs defined (AC-DM-01 through AC-DM-16). **All 16 ACs PASS.** All 4 PM decisions APPROVED. Stream COMPLETE.

**PM Decisions:** 4 total, all APPROVED. PM-DM-01 (LAN_ONLY default). PM-DM-02 (no toggle). PM-DM-03 ("Nearby" wording). PM-DM-04 (CLOUD_ONLY deferred).

**Risk register:** No material discovery-policy risks identified at codification.

---

## Item 16: BTR-SPEC-1 — Algorithm-Grade BTR Protocol Specification

**Priority:** NEXT
**Status:** **COMPLETE** (`ecosystem-v0.1.143-btr-spec1-bs5-closeout`, 2026-03-15). All 22 ACs PASS. All 6 PM decisions APPROVED. BS1–BS5 DONE.
**Routing:** bolt-protocol (primary — spec text), bolt-ecosystem (governance)
**Category:** Specification — formal BTR protocol documentation
**Stream:** BTR-SPEC-1 (phased, 5 phases BS1–BS5)
**Dependencies:** None (COMPLEMENTS SEC-BTR1, CONSUMER-BTR1, RUSTIFY-CORE-1)

**Context:** BTR has full implementation coverage (341 tests, 10 vector files) and substantial spec text in PROTOCOL.md §16 (300+ lines). P0 audit confirmed 5/7 modules fully specified; 2 gaps: flow control/backpressure (BTR-FC) and resume/recovery (BTR-RSM). BTR-SPEC-1 fills gaps, formalizes module boundaries, and adds change-control policy for independent-implementation-grade specification.

**Phased Plan (BTR-SPEC-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| BS1 | Module taxonomy + boundary lock | YES (gates BS2) | **DONE** (AC-BS-01–03 PASS, 2026-03-14) |
| BS2 | State machines + crypto/key-schedule lock | YES (gates BS3) | **DONE** (AC-BS-04–08 PASS, PM-BS-01/02 APPROVED, 2026-03-14) |
| BS3 | Wire format + failure/recovery semantics lock | YES (gates BS4) | **DONE** (AC-BS-09–13 PASS, PM-BS-03/04 APPROVED, 2026-03-14) |
| BS4 | Conformance vectors + negative-test matrix lock | YES (gates BS5) | **DONE** (AC-BS-14–17 PASS, 2026-03-14) |
| BS5 | Versioning/change-control + external review readiness | YES (closes stream) | **DONE** (AC-BS-18–22 PASS, PM-BS-05/06 APPROVED, 2026-03-15) |

**Acceptance Criteria:** 22 ACs defined (AC-BS-01 through AC-BS-22). **All 22 ACs PASS.** All 6 PM decisions APPROVED. Stream COMPLETE.

**PM Decisions:** 6 open (PM-BS-01 through PM-BS-06). See `docs/GOVERNANCE_WORKSTREAMS.md` § BTR-SPEC-1.

**Risk register:** 4 risks (BS-R1–R4), all LOW–MEDIUM.

---

## Item 17: WEBTRANSPORT-BROWSER-APP-1 — Browser↔App WebTransport Migration

**Priority:** NEXT
**Status:** **COMPLETE** (`ecosystem-v0.1.147-webtransport-browser-app1-wt5-closeout`, 2026-03-15). All 20 ACs PASS. All 5 PM decisions APPROVED. WT1–WT5 DONE.
**Routing:** bolt-daemon (WebTransport endpoint), bolt-core-sdk (browser adapter), bolt-ecosystem (governance)
**Category:** Architecture — browser↔app transport evolution
**Stream:** WEBTRANSPORT-BROWSER-APP-1 (phased, 5 phases WT1–WT5)
**Dependencies:** RUSTIFY-CORE-1 complete (RC5 WS baseline operational). EXTENDS, does not modify.

**Context:** RC5 established WebSocket-direct as browser↔app primary transport. WebTransport (QUIC/HTTP3) offers multiplexed streams, no head-of-line blocking, built-in flow control, and unifies the transport substrate with app↔app QUIC (RC3). WebTransport was previously rejected for RC5 (PM-RC-02 Option C) due to Safari support concerns and scope risk. This stream re-evaluates with WS and WebRTC as explicit fallback tiers.

**Transport matrix (post-adoption):**
- browser↔app primary: WebTransport (daemon endpoint)
- browser↔app fallback 1: WebSocket-direct (RC5)
- browser↔app fallback 2: WebRTC (baseline)
- browser↔browser: WebRTC (G1 invariant, unchanged)
- app↔app: QUIC/quinn (RC3, unchanged)

**Phased Plan (WEBTRANSPORT-BROWSER-APP-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| WT1 | Policy lock + browser support matrix | YES (gates WT2) | **DONE** (AC-WT-01–04 PASS, PM-WT-01/02 APPROVED, 2026-03-15) |
| WT2 | Daemon endpoint + TLS policy lock | YES (gates WT3) | **DONE** (AC-WT-05–08 PASS, PM-WT-03 APPROVED, 2026-03-15) |
| WT3 | Browser adapter + fallback orchestration lock | YES (gates WT4) | **DONE** (AC-WT-09–12 PASS, 2026-03-15) |
| WT4 | Conformance + rollout/rollback gate lock | YES (gates WT5) | **DONE** (AC-WT-13–16 PASS, PM-WT-04 APPROVED, 2026-03-15) |
| WT5 | Closure + WS disposition | YES (closes stream) | **DONE** (AC-WT-17–20 PASS, PM-WT-05 APPROVED, 2026-03-15) |

**Acceptance Criteria:** 20 ACs defined (AC-WT-01 through AC-WT-20). **All 20 ACs PASS.** All 5 PM decisions APPROVED. Stream COMPLETE.

**PM Decisions:** 5 open (PM-WT-01 through PM-WT-05). See `docs/GOVERNANCE_WORKSTREAMS.md` § WEBTRANSPORT-BROWSER-APP-1.

**Risk register:** 5 risks (WT-R1–R5). Safari support (HIGH), TLS cert complexity (HIGH), API instability (MEDIUM), fallback latency (MEDIUM), UDP firewall blocking (MEDIUM).

---

## Item 18: EGUI-WASM-1 — Browser UI Migration to egui via WASM (Experimental)

**Priority:** LATER (experimental)
**Status:** **ABANDONED** (`ecosystem-v0.1.164-egui-wasm1-ew2-poc`, 2026-03-17). EW2 PoC built and measured. 1,296 KiB gzipped (2.6× over 500 KiB kill). 26% presentation reuse. Stream CLOSED.
**Routing:** localbolt-v3 (primary), localbolt (secondary), bolt-ecosystem (governance)
**Category:** UI architecture — browser egui shell via WASM (experimental)
**Stream:** EGUI-WASM-1 (phased, 5 phases EW1–EW5)
**Dependencies:** None (PM-EN-04 approved early, 2026-03-15). Non-blocking to EGUI-NATIVE-1.

**Context:** Browser UIs currently use vanilla TypeScript/Tailwind (not React). EGUI-WASM-1 explores a browser egui shell compiled to WASM, sharing presentation/state/core with desktop bolt-ui where viable. Experimental — ABANDON is the default outcome. Current TS UI retained as default-safe production path. Browser transport is WebTransport-class (not native QUIC/quinn).

**Success gates (quantitative):** Bundle size ≤500 KiB gzipped, cold start ≤2s (EW1 revised to ≤3s), ≥30 FPS, accessibility parity, ≥90% feature parity, cross-browser rendering.

**Phased Plan (EGUI-WASM-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| EW1 | Feasibility + success gate definition | YES (gates EW2) | **DONE** (AC-EW-01–04, 2026-03-16) |
| EW2 | WASM scaffold + measurement PoC | YES (gates EW3) | **DONE** (2026-03-17). Q1 FAIL → ABANDON. |
| EW3 | Parity assessment + gate evaluation | YES (gates EW4) | NOT-STARTED |
| EW4 | Adoption decision (adopt/abandon/defer) | YES (gates EW5 or closes) | NOT-STARTED |
| EW5 | Migration rollout (if adopt) | YES (closes stream) | NOT-STARTED |

**Acceptance Criteria:** 19 ACs defined (AC-EW-01 through AC-EW-19). See `docs/GOVERNANCE_WORKSTREAMS.md` § EGUI-WASM-1.

**PM Decisions:** 5 open (PM-EW-01 through PM-EW-05). See `docs/GOVERNANCE_WORKSTREAMS.md` § EGUI-WASM-1.

**Risk register:** 6 risks (EW-R1–R6). Bundle size (HIGH), accessibility (HIGH), cold start (MEDIUM), cross-browser (MEDIUM), API instability (LOW), dual-build complexity (LOW).

---

## Item 19: RUSTIFY-BROWSER-CORE-1 — Browser-Path Rust/WASM Protocol Authority

**Priority:** NEXT (unblocked)
**Status:** **CLOSED** (`ecosystem-v0.1.171`, 2026-03-17). All 23 ACs, all 5 PM decisions. localbolt-v3 rolled out; others PM-RB-04 deferred. Stream CLOSED.
**Routing:** bolt-core-sdk (WASM bindings), bolt-transport-web (TS adapter thinning), consumers (rollout), bolt-ecosystem (governance)
**Category:** Architecture — browser protocol authority migration from TS to Rust/WASM
**Stream:** RUSTIFY-BROWSER-CORE-1 (phased, 6 phases RB1–RB6)
**Dependencies:** RUSTIFY-CORE-1 complete (satisfied). T-STREAM-1 WASM integration pattern available.

**Context:** Post-RUSTIFY-CORE-1 audit found browser protocol path is a complete independent TS implementation (tweetnacl + @noble/hashes). Parity with Rust by convention (test vectors), not construction. RUSTIFY-BROWSER-CORE-1 migrates browser protocol authority into Rust/WASM so TS retains only browser API bindings, persistence, and UI. Follow-on to RUSTIFY-CORE-1 (which completed daemon/native-first scope). Operationalizes the browser-path portion that ARCH-WASM1 left deferred.

**Phased Plan (RUSTIFY-BROWSER-CORE-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| RB1 | Policy lock + bundle budget | YES (gates RB2) | **DONE** (PM-RB-01–05 APPROVED, 2026-03-17) |
| RB2 | Authority boundary audit + adapter inventory | YES (gates RB3) | **DONE** (67 KiB WASM, inventory complete, 2026-03-17) |
| RB3 | Rust/WASM crypto + session core | YES (gates RB4) | **DONE** (61 KiB WASM, TS wired, 2026-03-17) |
| RB4 | Rust/WASM BTR + transfer core | YES (gates RB5) | **DONE** (102 KiB, 42 μs/chunk, 2026-03-17) |
| RB5 | TS adapter thinning | YES (gates RB6) | **DONE** (production WASM wired, 2026-03-17) |
| RB6 | Rollout + closure | YES (closes stream) | **DONE** (stream CLOSED, 2026-03-17) |

**Acceptance Criteria:** 23 ACs defined (AC-RB-01 through AC-RB-23). See `docs/GOVERNANCE_WORKSTREAMS.md` § RUSTIFY-BROWSER-CORE-1.

**PM Decisions:** 5 (PM-RB-01 through PM-RB-05). Bundle budget, transport binding posture, rollback model, consumer scope, ARCH-WASM1 disposition.

**Risk register:** 7 risks (RB-R1–R7). Bundle size (HIGH), debugging (MEDIUM), perf (MEDIUM), dual-path (MEDIUM), transport binding (MEDIUM), crypto parity (LOW), accessibility (NONE).

**Key distinction from EGUI-WASM-1:** Protocol logic only (crypto, session, BTR, transfer SM). No UI rendering. Structurally smaller WASM — no font renderer, no GL backend. Existing `bolt-transfer-policy-wasm` (20 KiB) demonstrates viable protocol-only WASM.

---

## Item 20: RUSTIFY-BROWSER-ROLLOUT-1 — Package + Deploy + Burn-In

**Priority:** NEXT (unblocked)
**Status:** **CLOSED** (`ecosystem-v0.1.178`, 2026-03-19). All 17 ACs. Burn-in evidence collected. Stream CLOSED.
**Routing:** bolt-core-sdk (publish), localbolt-v3 (burn-in), localbolt / localbolt-app (follow-on), bolt-ecosystem (governance)
**Category:** Operations — publish, deploy, observe, validate browser WASM authority
**Stream:** RUSTIFY-BROWSER-ROLLOUT-1 (phased, 6 phases BR1–BR6)
**Dependencies:** RUSTIFY-BROWSER-CORE-1 CLOSED (satisfied).

**Context:** Architecture delivered but not yet deployed. npm packages need publishing with WASM code, runtime observability is missing, no burn-in evidence exists. This stream turns architectural completion into product reality.

**Phased Plan (RUSTIFY-BROWSER-ROLLOUT-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| BR1 | Package + artifact delivery audit | YES (gates BR2) | **DONE** (PM-BR-01/02 APPROVED, 2026-03-18) |
| BR2 | Publish-ready SDK release | YES (gates BR3) | **DONE** (published to npmjs, 2026-03-18) |
| BR3 | Observability + fallback telemetry | YES (gates BR4) | **DONE** (authority mode query, 2026-03-18) |
| BR4 | Burn-in harness + validation checklist | YES (gates BR5) | **DONE** (checklist defined, 2026-03-18) |
| BR5 | Follow-on consumer rollout | YES (gates BR6) | **DONE** (all consumers, 2026-03-19) |
| BR6 | Burn-in execution + disposition | YES (closes stream) | **DONE** (stream CLOSED, 2026-03-19) |

**Acceptance Criteria:** 17 ACs defined (AC-BR-01–17). See `docs/GOVERNANCE_WORKSTREAMS.md` § RUSTIFY-BROWSER-ROLLOUT-1.

**PM Decisions:** 2 (PM-BR-01: WASM delivery path, PM-BR-02: follow-on consumer timing).

---

## Item 21: LOCALBOLT-RELIABILITY-UX-1 — Transfer Reliability + UX Hardening

**Priority:** NEXT (unblocked)
**Status:** **CLOSED** (`ecosystem-v0.1.185`, 2026-03-19). All 17 ACs. 10 UX improvements. Zero regressions. Stream CLOSED.
**Routing:** localbolt-v3 (primary), bolt-transport-web (SDK components), localbolt / localbolt-app (follow-on), bolt-ecosystem (governance)
**Category:** Product quality — reliability and UX clarity
**Stream:** LOCALBOLT-RELIABILITY-UX-1 (phased, 6 phases RU1–RU6)
**Dependencies:** None (RUSTIFY-BROWSER-CORE-1 and RUSTIFY-BROWSER-ROLLOUT-1 both CLOSED).

**Context:** Architecture and rollout complete. Next highest-value work is product quality: transfer state visibility, error handling, receive-flow clarity, and reconnect polish. Five concrete issues identified as the opening problem set.

**Phased Plan (LOCALBOLT-RELIABILITY-UX-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| RU1 | Reliability/UX audit + prioritized list | YES (gates RU2, RU3) | **DONE** (10 issues, 4 HIGH, 2026-03-19) |
| RU2 | Transfer-state visibility hardening | YES (gates RU4) | **DONE** (2026-03-19) |
| RU3 | Error/failure/retry UX | YES (gates RU5) | **DONE** (2026-03-19) |
| RU4 | Receive-flow clarity + completion | YES (gates RU6) | **DONE** (2026-03-19) |
| RU5 | Reconnect/cancel/resume polish | YES (gates RU6) | **DONE** (2026-03-19) |
| RU6 | Validation + closure | YES (closes stream) | **DONE** (stream CLOSED, 2026-03-19) |

**Acceptance Criteria:** 17 ACs defined (AC-RU-01–17). See `docs/GOVERNANCE_WORKSTREAMS.md` § LOCALBOLT-RELIABILITY-UX-1.

**PM Decisions:** 1 (PM-RU-01: SAS verification guidance text — APPROVED).

---

## Item 22: LOCALBOLT-PERF-1 — Transfer Throughput + Performance Hardening

**Priority:** NEXT (unblocked)
**Status:** **CLOSED** (`ecosystem-v0.1.193`, 2026-03-20). Baseline ~33–38 Mbps → tuned ~47 Mbps on tested path. All closure criteria satisfied.
**Routing:** bolt-core-sdk (transfer policy, metrics), localbolt-v3 (primary target), bolt-ecosystem (governance)
**Category:** Product performance — throughput measurement and tuning
**Stream:** LOCALBOLT-PERF-1 (phased, 6 phases PF1–PF6)
**Dependencies:** None (RUSTIFY-BROWSER-CORE-1, RUSTIFY-BROWSER-ROLLOUT-1, LOCALBOLT-RELIABILITY-UX-1 all CLOSED).

**Context:** Architecture, rollout, and UX streams complete. Next concern is real-world transfer throughput. Measure current path, identify bottlenecks, tune where justified. Not a reuse of S2 — operates on the shipped product stack.

**Phased Plan (LOCALBOLT-PERF-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| PF1 | Performance audit + bottleneck model | YES (gates PF2) | **DONE** (6 hypotheses, plan defined, 2026-03-20) |
| PF2 | Instrumentation + measurement harness | YES (gates PF3, PF4) | **DONE** (baseline: ~33–38 Mbps LAN, 2026-03-20) |
| PF3 | Browser/browser throughput tuning | YES (gates PF6) | **DONE** (tuned: ~47 Mbps, +42% at 50 MiB, 2026-03-20) |
| PF4 | Chunking/buffering/backpressure tuning | YES (gates PF6) | **DONE** (64KB chunks, 256KB threshold, 2026-03-20) |
| PF5 | Comparative transport assessment (conditional, PM-PF-01) | NO (optional) | **DONE** (ceiling assessed, transport comparison N/A, 2026-03-20) |
| PF6 | Validation + closure | YES (closes stream) | **DONE** (stream CLOSED, 2026-03-20) |

**Acceptance Criteria:** 17 ACs defined (AC-PF-01–17). See `docs/GOVERNANCE_WORKSTREAMS.md` § LOCALBOLT-PERF-1.

**PM Decisions:** 2 (PM-PF-01: conditional PF5, PM-PF-02: throughput target after baseline).

---

## Item 23: WEBTRANSPORT-BROWSER-APP-IMPL-1 — Browser↔App WebTransport Implementation

**Priority:** NEXT (unblocked)
**Status:** **COMPLETE** (2026-03-21). All 23 ACs satisfied. WTI1–WTI6 DONE. Daemon WT endpoint + browser adapter + three-tier fallback + capability negotiation + kill-switches + E2E proof + benchmark + TLS docs. 381 daemon + 417 browser tests. Stream CLOSED.
**Routing:** bolt-daemon (HTTP/3 endpoint), bolt-core-sdk/ts/bolt-transport-web (browser adapter), bolt-ecosystem (governance)
**Category:** Transport implementation — browser↔app WebTransport over HTTP/3
**Stream:** WEBTRANSPORT-BROWSER-APP-IMPL-1 (phased, 6 phases WTI1–WTI6)
**Dependencies:** WEBTRANSPORT-BROWSER-APP-1 governance COMPLETE. RUSTIFY-CORE-1 RC3/RC5 DONE.

**Context:** Implementation successor to the fully locked WEBTRANSPORT-BROWSER-APP-1 governance stream (20 ACs, 5 PM decisions, all approved). Builds a real browser↔app WebTransport path using HTTP/3 over QUIC. Browser "QUIC" means WebTransport over HTTP/3 — not raw QUIC in-browser, not peer-to-peer. Safari/WebKit does NOT support WebTransport; those users fall to WS/WebRTC via three-tier fallback. G1 invariant preserved: browser↔browser remains WebRTC.

**Phased Plan (WEBTRANSPORT-BROWSER-APP-IMPL-1):**

| Phase | Description | Serial Gate | Status |
|-------|-------------|-------------|--------|
| WTI1 | Implementation audit + integration plan | YES (gates WTI2) | **DONE** (audit complete, 2026-03-21) |
| WTI2 | Daemon HTTP/3 WebTransport endpoint | YES (gates WTI3) | **DONE** (endpoint implemented, 2026-03-21) |
| WTI3 | Browser WebTransport adapter + three-tier fallback | YES (gates WTI4) | **DONE** (adapter + fallback implemented, 2026-03-21) |
| WTI4 | Feature gating + capability negotiation + TLS provisioning | YES (gates WTI5) | **DONE** (capability + gating implemented, 2026-03-21) |
| WTI5 | Validation, measurement, rollout criteria | YES (gates WTI6) | **DONE** (E2E + fallback + BTR proven, benchmark + TLS docs, 2026-03-21) |
| WTI6 | Closure | YES (closes stream) | **DONE** (stream CLOSED, 2026-03-21) |

**Acceptance Criteria:** 23 ACs defined (AC-WTI-01–23). See `docs/GOVERNANCE_WORKSTREAMS.md` § WEBTRANSPORT-BROWSER-APP-IMPL-1.

**PM Decisions:** 2 (PM-WTI-01: daemon WT port, PM-WTI-02: default-on vs opt-in at close).

---

## Item 24: WEBTRANSPORT-BROWSER-APP-E2E-1 — Browser Runtime WebTransport Validation

**Priority:** NEXT (unblocked)
**Status:** **COMPLETE** (2026-03-21). Real browser-runtime WT + WS proof. 4 Playwright tests pass. Stream CLOSED.
**Routing:** bolt-daemon (echo server + harness), bolt-ecosystem (governance)
**Category:** Validation — real browser-runtime transport proof
**Stream:** WEBTRANSPORT-BROWSER-APP-E2E-1 (single-phase)
**Dependencies:** WEBTRANSPORT-BROWSER-APP-IMPL-1 CLOSED (`ecosystem-v0.1.196`).

**Context:** Post-ship validation for the WEBTRANSPORT-BROWSER-APP-IMPL-1 stream. Proves that a real Chrome browser can connect to the daemon's WebTransport endpoint and exchange length-prefixed frames, and that the WebSocket fallback path works in the same browser session. Scope is transport-layer runtime connectivity — not full app-protocol E2E (HELLO + ProfileEnvelopeV1 + file transfer).

**Harness:** `bolt-daemon/examples/wt_e2e_echo.rs` (WT+WS echo server), `bolt-daemon/tests/e2e-browser/` (Playwright). Run: `cd bolt-daemon/tests/e2e-browser && npm install && npm test`.

**Acceptance Criteria:** 6 criteria, all PASS. See `docs/evidence/WTE1_EVIDENCE.md`.

**Scope caveat:** Transport-layer runtime proof only. Full browser HELLO + envelope + file transfer over WT would require bundling the SDK into a browser page — deferred.

---

## Item 25: NATIVE-APP-CORE-1 — Shared App Logic Extraction

**Priority:** NEXT (unblocked)
**Status:** **NAC1–NAC3 DONE** (2026-03-22). `bolt-app-core` extracted (9 modules, 75 tests). `bolt-ui` refactored to consume shared core (15 tests). Standalone native binary builds. NAC4 READY.
**Routing:** bolt-core-sdk (`bolt-app-core` crate + `bolt-ui` refactor), localbolt-app (thin adapter), bolt-ecosystem (governance)
**Category:** Architecture — shared app-level Rust core
**Stream:** NATIVE-APP-CORE-1 (phased, 4 phases NAC1–NAC4)
**Dependencies:** EGUI-NATIVE-1 CLOSED. RUSTIFY-CORE-1 CLOSED.
**ADR:** `docs/ADR-001-NATIVE-APP-ARCHITECTURE.md`

**Context:** Extract shared app-level logic from localbolt-app Tauri backend into `bolt-app-core` crate. Daemon lifecycle, IPC contract/transport/bridge, watchdog SM, platform paths, signal monitoring, crash diagnostics. Foundation for egui desktop (bolt-ui), SwiftUI iOS, and Kotlin Android shells.

**Phased Plan:**

| Phase | Description | Gate | Status |
|-------|-------------|------|--------|
| NAC1 | Audit Tauri backend, define crate boundary | YES (gates NAC2) | **DONE** (2026-03-22) |
| NAC2 | Create bolt-app-core crate, extract logic | YES (gates NAC3) | **DONE** (2026-03-22). 9 modules, 75 tests. |
| NAC3 | Refactor bolt-ui to use bolt-app-core | YES (gates NAC4) | **DONE** (2026-03-22). 15 bolt-ui tests pass. |
| NAC4 | Validation + closure | YES (closes stream) | READY |

---

## Item 26: NATIVE-DESKTOP-PKG-1 — Desktop egui Packaging

**Priority:** NEXT (unblocked — NATIVE-APP-CORE-1 NAC3 DONE)
**Status:** **COMPLETE** (2026-03-22). PM-EN-03 resolved: rollback CLOSED for macOS + Linux. Windows conditionally open. Stream CLOSED.
**Routing:** bolt-core-sdk (bolt-ui packaging), localbolt-app (legacy/transitional), bolt-ecosystem (governance)
**Category:** Packaging — desktop native binary distribution
**Stream:** NATIVE-DESKTOP-PKG-1 (phased, 3 phases NDP1–NDP3)
**Dependencies:** NATIVE-APP-CORE-1 NAC3 DONE (bolt-ui using bolt-app-core).

**Context:** Replaced Tauri WebView build with egui-only binary. Platform installers proven. PM-EN-03 rollback window closed for macOS + Linux.

**Phased Plan:**

| Phase | Description | Gate | Status |
|-------|-------------|------|--------|
| NDP1 | Packaging scaffold (cargo-bundle or equivalent) | YES (gates NDP2) | **DONE** (2026-03-22). macOS `LocalBolt.app`. Embedded rendezvous. |
| NDP2 | Platform installer generation + smoke test | YES (gates NDP3) | **DONE** (2026-03-22). macOS + Linux deb proven. Win/AppImage config-ready. |
| NDP3 | Tauri removal + rollback window closure (PM-EN-03) | YES (closes stream) | **DONE** (2026-03-22). PM-EN-03 Option A approved. |

**PM-EN-03 Resolution:**

| Platform | Rollback Window | Rationale |
|----------|----------------|-----------|
| **macOS** | **CLOSED** | `LocalBolt.app` (7.4 MB) proven, embedded rendezvous, one-app model |
| **Linux** | **CLOSED** | `bolt-ui_0.2.0_arm64.deb` (4.0 MB) proven, `.deb` accepted as deliverable |
| **Windows** | **Conditionally open** | MSI config-ready, closure pending Windows CI (WiX toolset) |

**Desktop authority (historical, 2026-03-22):** `bolt-ui` was the primary desktop path when this stream closed. **Superseded (2026-04-12):** Forward desktop path is platform-native shells. macOS: `localbolt-app` SwiftUI shell (shipping v2.0.0). `bolt-ui` (egui) is historical.

**Remaining follow-on items (not stream blockers):**
- Windows MSI: CI validation when Windows runner available
- Professional icon design: operational polish
- `localbolt-app/src-tauri/` cleanup: after Windows closure or explicit PM approval

---

## Item 27: NATIVE-IOS-1 — iOS App

**Priority:** NEXT (unblocked — NATIVE-APP-CORE-1 NAC2 DONE)
**Status:** NOT-STARTED
**Routing:** localbolt-ios (new repo), bolt-core-sdk, bolt-ecosystem (governance)
**Category:** Product — iOS native app
**Stream:** NATIVE-IOS-1 (phased, 4 phases NI1–NI4)
**Dependencies:** NATIVE-APP-CORE-1 NAC2 DONE (bolt-app-core crate exists).

**Context:** SwiftUI thin shell + UniFFI-generated Swift bindings + bolt-app-core. Native file picker, share sheet, backgrounding.

**Phased Plan:**

| Phase | Description | Gate | Status |
|-------|-------------|------|--------|
| NI1 | UniFFI scaffold + bolt-app-core Swift bindings | YES (gates NI2) | NOT-STARTED |
| NI2 | SwiftUI launcher + peer discovery screen | YES (gates NI3) | NOT-STARTED |
| NI3 | Transfer screen + file picker + share sheet | YES (gates NI4) | NOT-STARTED |
| NI4 | App Store packaging + TestFlight | YES (closes stream) | NOT-STARTED |

---

## Item 28: NATIVE-ANDROID-1 — Android App

**Priority:** NEXT (unblocked — NATIVE-APP-CORE-1 NAC2 DONE)
**Status:** NOT-STARTED
**Routing:** localbolt-android (new repo), bolt-core-sdk, bolt-ecosystem (governance)
**Category:** Product — Android native app
**Stream:** NATIVE-ANDROID-1 (phased, 4 phases NA1–NA4)
**Dependencies:** NATIVE-APP-CORE-1 NAC2 DONE (bolt-app-core crate exists).

**Context:** Kotlin/Compose thin shell + UniFFI-generated Kotlin bindings + bolt-app-core. Native file picker, share intent, background service.

**Phased Plan:**

| Phase | Description | Gate | Status |
|-------|-------------|------|--------|
| NA1 | UniFFI scaffold + bolt-app-core Kotlin bindings | YES (gates NA2) | NOT-STARTED |
| NA2 | Compose launcher + peer discovery screen | YES (gates NA3) | NOT-STARTED |
| NA3 | Transfer screen + file picker + share intent | YES (gates NA4) | NOT-STARTED |
| NA4 | Play Store packaging + internal testing | YES (closes stream) | NOT-STARTED |

---

## Item 29: NATIVE-DESKTOP-WINDOWS-1 — Windows Desktop Validation

**Priority:** ~~NEXT~~ CLOSED
**Status:** **COMPLETE** (2026-03-22). Windows `.exe` build proven on `windows-latest`. 84 tests pass. PM approved. Desktop rollback CLOSED all platforms. Stream CLOSED.
**Routing:** bolt-core-sdk (CI workflow + bolt-ui), bolt-ecosystem (governance)
**Category:** Validation — Windows desktop packaging proof
**Stream:** NATIVE-DESKTOP-WINDOWS-1 (single-phase)
**Dependencies:** NATIVE-DESKTOP-PKG-1 CLOSED.

**CI Evidence:**
- Run: [23412620528](https://github.com/the9ines/bolt-core-sdk/actions/runs/23412620528) (`windows-latest`, Windows Server 2025)
- `bolt-ui.exe`: 7,044,096 bytes — **PASS**
- `bolt-app-core` tests: 69 passed, 0 failed — **PASS**
- `bolt-ui` tests: 15 passed, 0 failed — **PASS**
- MSI: cargo-bundle WiX `KeyPath` bug — non-blocking (`.exe` accepted as distribution)
- Artifact: `windows-desktop-artifacts` uploaded

**Desktop rollback closure (all platforms):**

| Platform | Artifact | Status |
|----------|----------|--------|
| macOS | `LocalBolt.app` (7.4 MB) | **CLOSED** |
| Linux | `bolt-ui_0.2.0_arm64.deb` (4.0 MB) | **CLOSED** |
| Windows | `bolt-ui.exe` (6.7 MB) | **CLOSED** |

**Tauri desktop path: RETIRED.** `localbolt-app/src-tauri/` is legacy code, safe for removal.

**Non-blocking follow-on:** MSI installer (fix cargo-bundle WiX config or use alternative tooling).

---

## Item 30: DESKTOP-INSTALLER-POLISH-1 — Desktop Packaging Polish + Retired Code Cleanup

**Priority:** LOW (non-blocking follow-on)
**Status:** NOT-STARTED
**Routing:** bolt-core-sdk (bolt-ui packaging), localbolt-app (cleanup), bolt-ecosystem (governance)
**Category:** Polish — installer, assets, retired-code cleanup
**Stream:** DESKTOP-INSTALLER-POLISH-1 (unphased, task list)
**Dependencies:** NATIVE-DESKTOP-WINDOWS-1 CLOSED. Desktop rollback CLOSED all platforms.

**Context:** Low-priority operational polish after full desktop-native migration. Desktop rollback is CLOSED. `bolt-ui` was the canonical desktop shell; **superseded by localbolt-app native shells (2026-04-12)**. These items are non-blocking improvements, not architecture or rollback gates.

**This stream does NOT reopen any rollback decisions.**

**Task list (execute in any order, when convenient):**

| Task | Description | Priority | Notes |
|------|-------------|----------|-------|
| MSI installer fix | Fix cargo-bundle WiX `KeyPath` bug or switch to `wix` crate | Low | `.exe` is the accepted Windows distribution. MSI is installer polish only. |
| Icon design asset | Replace placeholder gradient icons with professional design | Low | Functional placeholders exist (icns/ico/png). Design task, not engineering. |
| Retired Tauri cleanup | Delete `localbolt-app/src-tauri/` and `localbolt-app/web/` | Low | Safe — desktop rollback is CLOSED. Code is inert. Do when convenient. |

**Why this is one stream (not three):**
- All three items are low-priority, non-blocking, desktop-packaging-related polish
- None have upstream dependencies or downstream consumers
- None require phased gates or PM decisions
- Splitting would create governance overhead disproportionate to the work

**Why these are non-blocking:**
- Desktop rollback is CLOSED across macOS, Linux, and Windows
- `.exe` is accepted as the Windows distribution format
- Placeholder icons are functional
- `localbolt-app/src-tauri/` is retired code with no active consumers

---

## Item 31: BROWSER-APP-DIRECT-1 — Browser↔Desktop Direct Transport Adoption

**Priority:** NEXT (in progress)
**Status:** **IN PROGRESS** (2026-03-23). Desktop daemon WS endpoint exposed after approval. localbolt-v3 wired to use `BrowserAppTransport` for desktop peers.
**Routing:** bolt-core-sdk (bolt-ui), localbolt-v3, bolt-daemon, bolt-ecosystem
**Category:** Integration — browser↔app direct transport (WS/WT, not WebRTC)
**Stream:** BROWSER-APP-DIRECT-1

**Context:** Wire the already-built direct browser↔app transport stack into the production web app. After approval, browser uses `BrowserAppTransport` to connect to daemon WS endpoint instead of WebRTC. Browser↔browser keeps WebRTC.

---

## Item 32: WASM-CRYPTO-FIRST-1 — Browser Crypto Convergence

**Priority:** NEXT (unblocked)
**Status:** NOT-STARTED
**Routing:** bolt-core-sdk (Rust WASM + TS transport-web), bolt-ecosystem
**Category:** Architecture — converge browser crypto to Rust/WASM authority
**Stream:** WASM-CRYPTO-FIRST-1

**Context:** Browser currently has dual crypto paths: TS NaCl (fallback) + Rust/WASM NaCl (preferred when available). Make WASM the default and sole authority. Remove or gate TS crypto as legacy fallback only. Prevents AP-03 (new TS crypto logic) from growing.

---

## Item 33: TRANSFER-SM-CONVERGENCE-1 — Browser Transfer Orchestration Convergence

**Priority:** LOW (acceptable drift, not urgent)
**Status:** NOT-STARTED
**Routing:** bolt-core-sdk (Rust SM + TS TransferManager), bolt-ecosystem
**Category:** Architecture — converge browser transfer toward Rust SM authority
**Stream:** TRANSFER-SM-CONVERGENCE-1

**Context:** `TransferManager.ts` (~865 lines) owns chunk processing, backpressure, progress, stall detection. Rust SM (bolt-transfer-core) + WASM already exist. Over time, thin the TS layer and let Rust/WASM own transfer orchestration. Not urgent — current TS layer works correctly.

---

## Item 34: LOCALBOLT-APP-FREEZE-1 — Archive Retired Tauri Repo

**Priority:** LOW (non-blocking cleanup)
**Status:** NOT-STARTED
**Routing:** localbolt-app (archive), bolt-ecosystem
**Category:** Cleanup — archive retired Tauri desktop path
**Stream:** LOCALBOLT-APP-FREEZE-1

**Context:** `localbolt-app` is retired (desktop rollback CLOSED all platforms). Repo should be archived on GitHub to prevent accidental new commits. Violates AP-01 if left open.

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
| WEBTRANSPORT-BROWSER-APP-1 | bolt-daemon + bolt-core-sdk + bolt-ecosystem | Confirmed |
| EGUI-WASM-1 | localbolt-v3 + localbolt + bolt-ecosystem | Confirmed |
| RUSTIFY-BROWSER-CORE-1 | bolt-core-sdk + bolt-transport-web + consumers + bolt-ecosystem | Confirmed |
| RUSTIFY-BROWSER-ROLLOUT-1 | bolt-core-sdk + consumers + bolt-ecosystem | Confirmed |
| LOCALBOLT-RELIABILITY-UX-1 | localbolt-v3 + bolt-transport-web + consumers + bolt-ecosystem | Confirmed |
| LOCALBOLT-PERF-1 | bolt-core-sdk + localbolt-v3 + bolt-ecosystem | Confirmed |
| WEBTRANSPORT-BROWSER-APP-IMPL-1 | bolt-daemon + bolt-core-sdk + bolt-ecosystem | Confirmed |
| WEBTRANSPORT-BROWSER-APP-E2E-1 | bolt-daemon + bolt-ecosystem | Confirmed |
| NATIVE-APP-CORE-1 | bolt-core-sdk + bolt-ui + bolt-ecosystem | Confirmed |
| NATIVE-DESKTOP-PKG-1 | localbolt-app + bolt-ecosystem | Confirmed |
| NATIVE-IOS-1 | localbolt-ios (new) + bolt-core-sdk + bolt-ecosystem | Confirmed |
| NATIVE-ANDROID-1 | localbolt-android (new) + bolt-core-sdk + bolt-ecosystem | Confirmed |
| NATIVE-DESKTOP-WINDOWS-1 | bolt-core-sdk (CI) + bolt-ecosystem | Confirmed |
| DESKTOP-INSTALLER-POLISH-1 | bolt-core-sdk + localbolt-app (cleanup) + bolt-ecosystem | Confirmed |
| BROWSER-APP-DIRECT-1 | bolt-core-sdk + localbolt-v3 + bolt-daemon + bolt-ecosystem | Confirmed |
| WASM-CRYPTO-FIRST-1 | bolt-core-sdk (Rust WASM + TS) + bolt-ecosystem | Confirmed |
| TRANSFER-SM-CONVERGENCE-1 | bolt-core-sdk (Rust SM + TS) + bolt-ecosystem | Confirmed |
| LOCALBOLT-APP-FREEZE-1 | localbolt-app (archive) + bolt-ecosystem | Confirmed |

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
| PM-RC-01A | RUSTIFY-CORE-1: QUIC runtime/library selection — **APPROVED (quinn, 2026-03-13)**. Fallback: `s2n-quic` → `msquic-rs`. | ~~RC3~~ | **APPROVED** |
| PM-RC-02 | RUSTIFY-CORE-1: Browser↔app transport mode default | RC5 | **APPROVED (WebSocket-direct, 2026-03-14)** |
| PM-RC-03 | RUSTIFY-CORE-1: Rollout order (app first, browser↔app second) | RC6 | **APPROVED** (app-first, 2026-03-14) |
| PM-RC-04 | RUSTIFY-CORE-1: Performance SLO thresholds for migration gates | RC3 | **APPROVED** (SLO defined, 2026-03-14) |
| PM-RC-05 | RUSTIFY-CORE-1: Legacy TS-path deprecation policy/timeline | RC6 | **APPROVED** (deprecate-but-retain, 2026-03-14) |
| PM-RC-06 | RUSTIFY-CORE-1: CLI stream trigger condition | RC7 | **APPROVED** (RC4 + Stage 1 burn-in, 2026-03-14) |
| PM-RC-07 | RUSTIFY-CORE-1: Relationship mode to SEC-CORE2/PLAT-CORE1/MOB-RUNTIME1/ARCH-WASM1 | All RC phases | **APPROVED** (hybrid: SUPERSEDES + REFACTORS, 2026-03-14) |
| PM-EN-01 | EGUI-NATIVE-1: Desktop UI framework | EN2 | **APPROVED** (egui, 2026-03-15) |
| PM-EN-02 | EGUI-NATIVE-1: Visual direction scope | EN2 | **APPROVED** (minimal parity, 2026-03-15) |
| PM-EN-03 | EGUI-NATIVE-1: Rollback window duration before legacy UI removal | EN5 | **APPROVED** (condition-gated, 2026-03-15) |
| PM-EN-04 | EGUI-NATIVE-1: Whether to open EGUI-WASM-1 after EN3 results | Post-stream | **APPROVED** (early resolution, 2026-03-15) |
| PM-EN-05 | EGUI-NATIVE-1: Whether to open EGUI-MOBILE-1 after EN4 results | Post-stream | PENDING |
| PM-DM-01 | DISCOVERY-MODE-1: Default discovery mode | DM2 | **APPROVED** (LAN_ONLY AirDrop-style, 2026-03-15) |
| PM-DM-02 | DISCOVERY-MODE-1: Mode toggle | DM2 | **APPROVED** (no toggle, auto LAN, 2026-03-15) |
| PM-DM-03 | DISCOVERY-MODE-1: UX wording | DM2 | **APPROVED** ("Nearby", no "Online", 2026-03-15) |
| PM-DM-04 | DISCOVERY-MODE-1: CLOUD_ONLY disposition | DM4 | **APPROVED** (deferred, ByteBolt scope, 2026-03-15) |
| PM-DM-04 | DISCOVERY-MODE-1: CLOUD_ONLY — codify now as optional mode, or defer entirely? | DM4 | NEXT |
| PM-BS-01 | BTR-SPEC-1: Crypto primitive baseline confirmation (NaCl box + HKDF-SHA256) | BS2 | NEXT |
| PM-BS-02 | BTR-SPEC-1: Rekey thresholds/lifecycle policy | BS2 | NEXT |
| PM-BS-03 | BTR-SPEC-1: Wire format versioning policy | BS3 | NEXT |
| PM-BS-04 | BTR-SPEC-1: Compatibility contract (strict vs tolerant parsing) | BS3 | NEXT |
| PM-BS-05 | BTR-SPEC-1: External review gate (scope, reviewer profile, acceptance bar) | BS5 | NEXT |
| PM-BS-06 | BTR-SPEC-1: Ratify relationship mode (COMPLEMENTS) with SEC-BTR1/CONSUMER-BTR1/RUSTIFY-CORE-1 | BS5 | NEXT |
| PM-WT-01 | WEBTRANSPORT-BROWSER-APP-1: Browser support matrix (Safari disposition) | WT1 | **APPROVED** (Option B: ship supported, Safari fallback, 2026-03-15) |
| PM-WT-02 | WEBTRANSPORT-BROWSER-APP-1: WebTransport capability string naming | WT1 | **APPROVED** (Option A: `bolt.transport-webtransport-v1`, 2026-03-15) |
| PM-WT-03 | WEBTRANSPORT-BROWSER-APP-1: TLS certificate provisioning strategy | WT2 | **APPROVED** (C2 local CA primary, C1 dev fallback, 2026-03-15) |
| PM-WT-04 | WEBTRANSPORT-BROWSER-APP-1: Performance SLO thresholds for WebTransport | WT4 | **APPROVED** (Option B balanced, 2026-03-15) |
| PM-WT-05 | WEBTRANSPORT-BROWSER-APP-1: WS disposition after WebTransport adoption | WT5 | **APPROVED** (Option B: deprecate-with-sunset, 2026-03-15) |
| PM-EN-04 | EGUI-NATIVE-1: Open EGUI-WASM-1 (browser egui via WASM) | Post-EN3 | **APPROVED** (early resolution, 2026-03-15) |
| PM-EW-01 | EGUI-WASM-1: WASM bundle size budget | EW1 | **DEFERRED TO EW2** (threshold ≤500 KiB retained; EW2 measures actuals) |
| PM-EW-02 | EGUI-WASM-1: Browser rendering backend preference | EW2 | LATER |
| PM-EW-03 | EGUI-WASM-1: Accessibility mitigation strategy | EW3 | LATER |
| PM-EW-04 | EGUI-WASM-1: Adoption decision (adopt/abandon/defer) | EW4 | LATER |
| PM-EW-05 | EGUI-WASM-1: React/TS disposition after adoption | EW5 | LATER |
| PM-RB-01 | RUSTIFY-BROWSER-CORE-1: WASM bundle budget | RB1 | **APPROVED** (≤300 KiB gzipped, 2026-03-17) |
| PM-RB-02 | RUSTIFY-BROWSER-CORE-1: Browser transport binding posture | RB1 | **APPROVED** (WebRTC retained, WebTransport deferred, 2026-03-17) |
| PM-RB-03 | RUSTIFY-BROWSER-CORE-1: Rollback/deprecation model | RB1 | **APPROVED** (condition-gated sunset, 2026-03-17) |
| PM-RB-04 | RUSTIFY-BROWSER-CORE-1: Consumer scope | RB1 | **APPROVED** (localbolt-v3 first, staged, 2026-03-17) |
| PM-RB-05 | RUSTIFY-BROWSER-CORE-1: ARCH-WASM1 disposition | RB1 | **APPROVED** (superseded, 2026-03-17) |
| PM-BR-01 | RUSTIFY-BROWSER-ROLLOUT-1: WASM delivery path | BR2 | **APPROVED** (embedded in transport-web, 2026-03-18) |
| PM-BR-02 | RUSTIFY-BROWSER-ROLLOUT-1: Follow-on consumer timing | BR5 | **APPROVED** (after burn-in, 2026-03-18) |
| PM-RU-01 | LOCALBOLT-RELIABILITY-UX-1: SAS verification guidance text | RU2 | **APPROVED** (concise + action-oriented, 2026-03-19) |
| PM-PF-01 | LOCALBOLT-PERF-1: Whether PF5 comparative transport executes | PF5 | PENDING |
| PM-PF-02 | LOCALBOLT-PERF-1: Throughput improvement target (after PF1 baseline) | PF3 | PENDING |

---

## Follow-Up: RDVZ-PEERID-1 — Rendezvous Peer ID Validation + Clear Error

**Priority:** LATER (non-blocking, discovered during N-STREAM-TIMEOUT drill 2026-03-16)
**Routing:** bolt-rendezvous (server-side error) + bolt-ui / localbolt-app (client-side validation)
**Category:** UX / input-validation / error handling
**Scope:** Strictly validation and error messaging. No transport or protocol changes.

### Problem

Peer IDs containing non-alphanumeric characters (e.g., hyphens: `studio-host`) are silently rejected by bolt-rendezvous with a WebSocket connection reset. The client sees `FATAL: WebSocket protocol error: Connection reset without closing handshake` with no indication that the peer ID was invalid.

### Root Cause

bolt-rendezvous validates peer codes as alphanumeric-only and logs `invalid peer code ... Peer code must be alphanumeric` server-side, but drops the WebSocket without sending an error frame to the client.

### Acceptance Criteria

| ID | Criterion |
|----|-----------|
| AC-RP-01 | bolt-rendezvous sends a structured error message (e.g., `{"error":"invalid_peer_code","message":"..."}`) before closing the WebSocket when peer code validation fails |
| AC-RP-02 | bolt-ui and localbolt-app validate peer IDs client-side before sending to rendezvous (alphanumeric check) |
| AC-RP-03 | User-visible error message when peer ID is rejected (not a raw WebSocket error) |
| AC-RP-04 | No transport, protocol, or session authority changes |
