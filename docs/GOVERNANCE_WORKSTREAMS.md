# Bolt Ecosystem — Governance Workstreams

> **Status:** Normative
> **Created:** 2026-03-02
> **Tag:** ecosystem-v0.1.37-audit-gov-31
> **Authority:** PM-approved. Phase execution requires separate phase prompts.

---

## Purpose

This document codifies two improvement workstreams into governance so that future implementation work is phase-gated, tagged, and non-drifting:

- **Workstream A (A-stream):** WebRTCService decomposition in bolt-core-sdk
- **Workstream B (B-stream):** Daemon file transfer convergence in bolt-daemon

These are improvement initiatives — not audit findings, not protocol changes. They decompose existing monolithic code into well-bounded modules (A-stream) and extend the daemon toward file transfer capability (B-stream).

---

## Scope Guardrails

1. **No protocol semantic changes** unless a future phase explicitly authorizes it.
2. **No wire-format changes** unless a future phase explicitly authorizes it.
3. **No cryptographic changes** unless a future phase explicitly authorizes it.
4. **A-stream MUST keep the WebRTCService public API identical.** No breaking changes for localbolt, localbolt-app, or localbolt-v3.
5. **B-stream phases B1–B3 do NOT include** file-hash capability, TOFU persistence activation, or long-lived event loop. Those are deferred phases.

---

## Workstream A — WebRTCService Decomposition (bolt-core-sdk)

**Repo:** bolt-core-sdk
**Goal:** Extract the monolithic WebRTCService into focused, testable modules while preserving the public API surface.

### A-STREAM-1 Completion Summary (A0–A2)

**Status:** DONE
**Tags:** `sdk-v0.5.22-webrtc-decompose-A0` (`6f0bb05`), `sdk-v0.5.22-webrtc-decompose-A1` (`e2d2b76`), `sdk-v0.5.22-webrtc-decompose-A2` (`7f7811d`)
**Date:** 2026-03-02

- WebRTCService reduced 1,369 → 790 LOC
- Public API unchanged
- Transport-web test suite stable at 249 tests (24 test files) across all commits
- No protocol, wire, or crypto changes

**Scope restructuring:** A0 (shared state scaffolding) was added as a prerequisite phase not in the original WORKSTREAMS-1 plan. A2 absorbed the original A3 (TransferManager extraction) scope — both EnvelopeCodec and TransferManager were extracted in a single phase alongside coordinator slimming. Original A3–A5 definitions remain as future work under a subsequent stream.

---

### A0 — Shared State Scaffolding

**Status:** DONE
**Tag:** `sdk-v0.5.22-webrtc-decompose-A0` (`6f0bb05`)

**Goal:** Extract type definitions (TransferStats, TransferProgress, FileChunkMessage, ProfileEnvelopeV1, ActiveTransfer, VerificationState, VerificationInfo, WebRTCServiceOptions) from WebRTCService into dedicated types.ts. Create ConnectionContext interface (context.ts) defining the shared state surface for HandshakeManager and TransferManager extraction in A1/A2.

**Constraints:**
- WebRTCService public API unchanged.
- No protocol semantic changes.
- No behavior change.

**Files changed:**
- `ts/bolt-transport-web/src/services/webrtc/types.ts` (new)
- `ts/bolt-transport-web/src/services/webrtc/context.ts` (new)
- `ts/bolt-transport-web/src/services/webrtc/WebRTCService.ts` (modified)

**Gates:**
- [x] Working tree clean before and after
- [x] All existing transport-web tests pass (249 tests, 24 test files)
- [x] `npm run build` succeeds (bolt-core + transport-web)
- [x] No public API changes (export surface identical)
- [x] Commit + local tag: `sdk-v0.5.22-webrtc-decompose-A0`

**Tag format:** `sdk-vX.Y.Z-webrtc-decompose-A0`

---

### A1 — Extract HandshakeManager

**Status:** DONE
**Tag:** `sdk-v0.5.22-webrtc-decompose-A1` (`e2d2b76`)

**Goal:** Extract HELLO handshake logic (exactly-once guard, capability negotiation, HelloState machine) from WebRTCService into a dedicated HandshakeManager module.

**Constraints:**
- WebRTCService public API unchanged.
- No protocol semantic changes.
- HandshakeManager is internal; not exported from package public surface.

**Allowed files (bolt-core-sdk):**
- `ts/bolt-transport-web/src/handshake-manager.ts` (new)
- `ts/bolt-transport-web/src/webrtc-service.ts` (refactor)
- `ts/bolt-transport-web/src/index.ts` (internal re-exports only)
- `ts/bolt-transport-web/__tests__/handshake-manager.test.ts` (new)
- Existing test files (verify green, no structural changes)

**Files changed (actual):**
- `ts/bolt-transport-web/src/services/webrtc/HandshakeManager.ts` (new)
- `ts/bolt-transport-web/src/services/webrtc/context.ts` (modified)
- `ts/bolt-transport-web/src/services/webrtc/WebRTCService.ts` (modified)

**Gates:**
- [x] Working tree clean before and after
- [x] All existing transport-web tests pass (249 tests, 24 test files)
- [x] `npm run build` succeeds (bolt-core + transport-web)
- [x] No public API changes (export surface identical)
- [x] Commit + local tag: `sdk-v0.5.22-webrtc-decompose-A1`
- [x] Phase report filed

**Tag format:** `sdk-vX.Y.Z-webrtc-decompose-A1`

---

### A2 — EnvelopeCodec + TransferManager Extraction

**Status:** DONE
**Tag:** `sdk-v0.5.22-webrtc-decompose-A2` (`7f7811d`)

**Goal:** Extract stateless EnvelopeCodec (encodeProfileEnvelopeV1, decodeProfileEnvelopeV1, dcSendMessage) and TransferManager (sendFile, processChunk, pause/resume/cancel, progress, stats, backpressure, metrics) from WebRTCService. Slim WebRTCService to coordinator (~790 LOC, down from ~1,369).

**Scope note:** This phase absorbed the original A3 (TransferManager extraction) and A4 (slim coordinator) scope from WORKSTREAMS-1. Both modules were extracted in a single atomic phase for convergence efficiency.

**Constraints:**
- WebRTCService public API unchanged.
- No cryptographic changes — same NaCl box operations, same nonce generation.
- EnvelopeCodec and TransferManager are internal; not exported from package public surface.

**Files changed (actual):**
- `ts/bolt-transport-web/src/services/webrtc/EnvelopeCodec.ts` (new)
- `ts/bolt-transport-web/src/services/webrtc/TransferManager.ts` (new)
- `ts/bolt-transport-web/src/services/webrtc/WebRTCService.ts` (modified)

**Gates:**
- [x] Working tree clean before and after
- [x] All existing transport-web tests pass (249 tests, 24 test files)
- [x] `npm run build` succeeds (bolt-core + transport-web)
- [x] No public API changes (export surface identical)
- [x] Golden vector tests still pass
- [x] Commit + local tag: `sdk-v0.5.22-webrtc-decompose-A2`
- [x] Phase report filed

**Tag format:** `sdk-vX.Y.Z-webrtc-decompose-A2`

---

### A3 — Extract TransferManager (Absorbed into A2)

**Status:** ABSORBED — TransferManager extraction was executed as part of A2 (`sdk-v0.5.22-webrtc-decompose-A2`). This phase definition is retained for traceability.

**Goal:** Extract file transfer orchestration (FILE_OFFER/ACCEPT/CHUNK/FINISH, transfer state tracking, progress reporting) from WebRTCService into a dedicated TransferManager module.

**Constraints:**
- WebRTCService public API unchanged.
- No wire-format changes.
- TransferManager is internal; not exported from package public surface.

**Allowed files (bolt-core-sdk):**
- `ts/bolt-transport-web/src/transfer-manager.ts` (new)
- `ts/bolt-transport-web/src/webrtc-service.ts` (refactor)
- `ts/bolt-transport-web/src/index.ts` (internal re-exports only)
- `ts/bolt-transport-web/__tests__/transfer-manager.test.ts` (new)
- Existing test files (verify green, no structural changes)

**Gates:**
- [ ] Working tree clean before and after
- [ ] All existing transport-web tests pass (report actual count)
- [ ] New TransferManager unit tests pass (report actual count)
- [ ] `npm run build` succeeds (bolt-core + transport-web)
- [ ] No public API changes (export surface identical)
- [ ] Commit + local tag: `sdk-vX.Y.Z-webrtc-decompose-A3`
- [ ] Phase report filed

**Tag format:** `sdk-vX.Y.Z-webrtc-decompose-A3`

---

### A4 — Slim WebRTCService to Coordinator (Absorbed into A2)

**Status:** ABSORBED — Coordinator slimming was executed as part of A2 (`sdk-v0.5.22-webrtc-decompose-A2`). WebRTCService reduced to ~790 LOC. This phase definition is retained for traceability.

**Goal:** Reduce WebRTCService to a thin coordinator that delegates to HandshakeManager, EnvelopeCodec, and TransferManager. Public API surface remains identical.

**Constraints:**
- WebRTCService public API unchanged — same constructor, same methods, same events, same types.
- All three extracted modules (A1–A3) must be wired.
- No protocol semantic changes.

**Allowed files (bolt-core-sdk):**
- `ts/bolt-transport-web/src/webrtc-service.ts` (refactor — should shrink significantly)
- `ts/bolt-transport-web/src/index.ts` (if re-export adjustments needed)
- Existing test files (verify green, no structural changes)

**Gates:**
- [ ] Working tree clean before and after
- [ ] All existing transport-web tests pass (report actual count)
- [ ] `npm run build` succeeds (bolt-core + transport-web)
- [ ] No public API changes (export surface identical)
- [ ] WebRTCService line count reduced (report before/after)
- [ ] Commit + local tag: `sdk-vX.Y.Z-webrtc-decompose-A4`
- [ ] Phase report filed

**Tag format:** `sdk-vX.Y.Z-webrtc-decompose-A4`

---

### A5 — Decomposition Test Hardening

**Goal:** Ensure all existing tests remain green and add targeted unit tests for the three extracted modules to establish standalone coverage independent of WebRTCService integration tests.

**Constraints:**
- No functional changes.
- No public API changes.
- Test-only phase.

**Allowed files (bolt-core-sdk):**
- `ts/bolt-transport-web/__tests__/handshake-manager.test.ts` (extend)
- `ts/bolt-transport-web/__tests__/envelope-codec.test.ts` (extend)
- `ts/bolt-transport-web/__tests__/transfer-manager.test.ts` (extend)
- `ts/bolt-transport-web/__tests__/webrtc-decompose-integration.test.ts` (new, optional)
- Existing test files (verify green, no structural changes)

**Gates:**
- [ ] Working tree clean before and after
- [ ] All existing transport-web tests pass (report actual count)
- [ ] All new module-level tests pass (report actual counts per module)
- [ ] `npm run build` succeeds (bolt-core + transport-web)
- [ ] No public API changes
- [ ] Commit + local tag: `sdk-vX.Y.Z-webrtc-decompose-A5`
- [ ] Phase report filed

**Tag format:** `sdk-vX.Y.Z-webrtc-decompose-A5`

---

## Workstream B — Daemon File Transfer Convergence (bolt-daemon)

**Repo:** bolt-daemon
**Goal:** Extend bolt-daemon toward file transfer capability by converging on the web wire format and building a transfer state machine. Phases B1–B3 only; deferred phases handle the rest.

### B-STREAM-1 Completion Summary (B1–B2)

**Status:** DONE
**Tag:** `daemon-v0.2.21-transfer-converge-B1B2` (`95d672f`)
**Date:** 2026-03-02

- Fail-closed option C chosen (strict break, documented)
- Defaults flipped to Web* (interop_signal: WebV1, interop_hello: WebHelloV1, interop_dc: WebDcV1)
- Legacy daemon modes require explicit --interop flags
- 7 new DcMessage variants: FileOffer, FileAccept, FileChunk, FileFinish, Pause, Resume, Cancel
- +15 tests added (default: 239→254, test-support: 319→334)
- No transfer state machine
- No bolt.file-hash
- No event loop changes

**Governance deviation:** B1 and B2 were defined as separate phases in this document. For implementation efficiency and atomic convergence, they were executed under a single tag (`daemon-v0.2.21-transfer-converge-B1B2`). This deviation is intentional and documented in the daemon commit body.

---

### B1 — Flip Interop Defaults

**Status:** DONE (combined with B2 under `daemon-v0.2.21-transfer-converge-B1B2`)
**Tag:** `daemon-v0.2.21-transfer-converge-B1B2` (`95d672f`)

**Goal:** Change bolt-daemon default configuration to prefer web-compatible wire format (JSON envelope, web-style signaling) over the legacy binary format.

**Blast radius:**
- Any existing daemon deployment using default configuration will change behavior on upgrade.
- Daemon-to-daemon connections using legacy format will break unless the legacy flag is explicitly set.
- Daemon-to-web connections (the target use case) will work by default.

**Required tests:**
- Default mode: daemon connects and completes HELLO handshake with web-format peer.
- Legacy flag: daemon with `--legacy` (or config equivalent) connects and completes HELLO handshake with legacy-format peer.
- Mixed: web-format daemon rejects legacy-format peer with appropriate error code.
- Flag persistence: config file / CLI flag correctly overrides default.

**Constraints:**
- No protocol semantic changes.
- No wire-format changes (only default selection between existing formats).
- Legacy mode must remain accessible via explicit flag/config.

**Allowed files (bolt-daemon):**
- `src/config.rs` (default flip)
- `src/main.rs` (flag wiring if needed)
- `src/session.rs` or equivalent (format selection)
- `tests/b1_interop_defaults.rs` (new)
- Existing test files (verify green)

**Gates:**
- [x] Working tree clean before and after
- [x] All existing daemon tests pass: `cargo test` (254 tests)
- [x] All existing daemon tests pass: `cargo test --features test-support` (334 tests)
- [x] New B1 tests pass (4 config parsing tests)
- [x] `cargo clippy -- -D warnings` clean
- [x] `scripts/check_no_panic.sh` passes
- [x] Default-mode HELLO handshake test passes
- [x] Legacy-flag HELLO handshake test passes
- [x] Commit + local tag: `daemon-v0.2.21-transfer-converge-B1B2`
- [x] Phase report filed

**Tag format:** `daemon-vX.Y.Z-transfer-converge-B1`

---

### B2 — DataChannel Message Variants + Parsing Tests

**Status:** DONE (combined with B1 under `daemon-v0.2.21-transfer-converge-B1B2`)
**Tag:** `daemon-v0.2.21-transfer-converge-B1B2` (`95d672f`)

**Goal:** Add Rust types and parsing for the DataChannel message variants used in file transfer: `FILE_OFFER`, `FILE_ACCEPT`, `FILE_CHUNK`, `FILE_FINISH`, `PAUSE`, `RESUME`, `CANCEL`. No transfer engine — types and parsing only.

**Constraints:**
- No transfer engine in this phase.
- No protocol semantic changes.
- Message types must match the web wire format exactly (json-envelope-v1 profile).
- Parsing must be strict: unknown fields ignored, missing required fields rejected.

**Allowed files (bolt-daemon):**
- `src/dc_messages.rs` (new — DataChannel message types + serde)
- `src/lib.rs` or `src/main.rs` (module declaration)
- `tests/b2_dc_message_parsing.rs` (new)
- Existing test files (verify green)

**Gates:**
- [x] Working tree clean before and after
- [x] All existing daemon tests pass: `cargo test` (254 tests)
- [x] All existing daemon tests pass: `cargo test --features test-support` (334 tests)
- [x] New B2 parsing tests pass (11 serde roundtrip + classification tests)
- [x] `cargo clippy -- -D warnings` clean
- [ ] `cargo fmt` clean — **NOT MET**: pre-existing drift on 6 files (see FMT-GATE-1). No new drift introduced.
- [x] Round-trip serialize/deserialize tests for every message variant
- [x] Reject-malformed tests for every message variant
- [x] Commit + local tag: `daemon-v0.2.21-transfer-converge-B1B2`
- [x] Phase report filed

**Tag format:** `daemon-vX.Y.Z-transfer-converge-B2`

---

### B3 — Transfer Engine State Machine

**Goal:** Implement a transfer state machine in `src/transfer.rs` that processes DataChannel message variants (from B2) and drives transfer lifecycle (offer → accept → chunks → finish, with pause/resume/cancel). Routing from session to transfer engine.

**Explicit scope boundary:** This phase implements the state machine and message routing ONLY. It does NOT include:
- File-hash capability negotiation or integrity enforcement (deferred to B4)
- TOFU pin persistence activation (deferred to B5)
- Long-lived post-HELLO event loop or IPC/CLI control (deferred to B6)

**Constraints:**
- No protocol semantic changes.
- State machine states must align with PROTOCOL.md transfer lifecycle.
- Transfer engine is internal; session module routes messages to it.

**Allowed files (bolt-daemon):**
- `src/transfer.rs` (new — transfer state machine)
- `src/session.rs` (routing from session to transfer engine)
- `src/lib.rs` or `src/main.rs` (module declaration)
- `tests/b3_transfer_engine.rs` (new)
- Existing test files (verify green)

**Gates:**
- [ ] Working tree clean before and after
- [ ] All existing daemon tests pass: `cargo test` (report actual count)
- [ ] All existing daemon tests pass: `cargo test --features test-support` (report actual count)
- [ ] New B3 transfer engine tests pass (report actual count)
- [ ] `cargo clippy -- -D warnings` clean
- [ ] `cargo fmt` clean
- [ ] `scripts/check_no_panic.sh` passes
- [ ] State machine covers: IDLE → OFFERED → ACCEPTED → TRANSFERRING → COMPLETE
- [ ] State machine covers: PAUSE, RESUME, CANCEL transitions
- [ ] Commit + local tag: `daemon-vX.Y.Z-transfer-converge-B3`
- [ ] Phase report filed

**Tag format:** `daemon-vX.Y.Z-transfer-converge-B3`

---

## Governance Process Items

### FMT-GATE-1 — Daemon rustfmt Verification Drift

**Severity:** LOW
**Category:** Process Integrity
**Status:** DONE-VERIFIED

**Facts:**
- `cargo fmt -- --check` fails on pre-existing files:
  - `src/identity_store.rs`
  - `src/web_hello.rs`
  - `src/rendezvous.rs`
  - `tests/h5_downgrade_validation.rs`
  - `tests/sa1_identity_separation.rs`
  - `tests/sa1_identity_store.rs`
- Drift present at baseline before B-STREAM-1.
- CI documentation claims fmt enforcement.

**Risk:**
- CI enforcement mismatch
- Formatting drift accumulation
- Refactors inherit noise

**Resolution:**
Tag: `daemon-v0.2.22-fmt-sync-1` (`9d0a485`)
- Mechanical `cargo fmt` sync — all 6 files formatted, no others touched
- No logic changes, no semantic edits
- `cargo fmt -- --check`: PASS
- `cargo clippy -- -D warnings`: PASS
- `scripts/check_no_panic.sh`: PASS
- `cargo test` (default): 254 passed
- `cargo test --features test-support`: 334 passed

---

## Deferred Phases — Enriched (AUDIT-GOV-27)

The following phases are explicitly NOT part of the completed B-STREAM-1 workstream. They are documented here as future work with verified spec references, corrected dependencies, and acceptance definitions. Each requires a separate governance codification before execution.

These are not speculative — they are protocol-bound execution gaps already defined normatively in PROTOCOL.md and referenced in audit findings.

### Corrected Dependency Graph

```
B5 (TOFU wiring) ─── DONE (daemon-v0.2.23-b5-tofu-persist)

B3 (transfer SM) ─┐  B3-P1 DONE (FileOffer→Cancel skeleton)
                  │   B3-P2 DONE (receive + reassembly in memory)
                  ├── coupled deliverable
B6 (event loop) ──┘   B6-P1 DONE (loop container); B3-P2 integrated
                      │
B4 (file-hash) ────── DONE (daemon-v0.2.27-b4-file-hash)
                      │   Receiver-side SHA-256 verification; SA15 superseded
D-E2E ─────────────── blocked on B3 full + B6
```

**Progress update (AUDIT-GOV-31):** B4 delivered receiver-side SHA-256 hash verification gated by `bolt.file-hash` capability negotiation. `DAEMON_CAPABILITIES` now advertises `bolt.file-hash`. TransferSession extended with `expected_hash` field; `on_file_offer` accepts optional hash; `on_file_finish` verifies via `bolt_core::hash::sha256_hex` (case-insensitive). Capability gating at loop level: negotiated + missing hash → `INTEGRITY_FAILED` + disconnect; not negotiated → hash on wire ignored. New `TransferError::IntegrityFailed` variant. +9 tests (default: 291→300, test-support: 371→380). SA15 superseded. Sender-side hashing out of scope (daemon is receive-only). Remaining for D-E2E: B3 full (pause/resume, cancel, disk writes, send-side) + B6 full.

**Previous update (AUDIT-GOV-30):** B3-P2 extended TransferSession with full receive path: auto-accept (FileOffer→accept→send FileAccept), chunk receive (base64 decode→sequential index enforcement→in-memory reassembly), and transfer completion (FileFinish→Completed). MAX_TRANSFER_BYTES (256 MiB) cap enforced. FileChunk and FileFinish carved out to Ok(None) in `route_inner_message`. Loop interception expanded to match on FileOffer/FileChunk/FileFinish. +12 tests (default: 279→291, test-support: 359→371). No disk writes, no hashing, no send-side. Remaining B3 work: pause/resume, cancel, disk writes, send-side, concurrent transfers. B5 complete (independent).

**Amendment from WORKSTREAMS-1:** B5 was previously listed as dependent on B3. This is incorrect — TOFU pin wiring requires only the HELLO-derived identity key (already present post-INTEROP-2). B6 was previously listed as dependent on B5. This is also incorrect — the event loop routes messages to the transfer engine, not to the pin store.

---

### B3 — Transfer Engine State Machine

**Status:** IN-PROGRESS (B3-P1 complete)
**Prerequisites:** B2 (message types — DONE)
**Coupled with:** B6 (post-HELLO event loop)

**Goal:** Implement full transfer state machine inside bolt-daemon per PROTOCOL.md §8 and §9.

#### B3-P1 — Control Plane Skeleton (DONE)

**Tag:** `daemon-v0.2.25-b3-transfer-sm-p1` (`edebe5d`)
**Date:** 2026-03-03

Introduced `TransferSession` (Idle → OfferReceived → Rejected) integrated into `run_post_hello_loop`. FileOffer is intercepted after envelope decrypt via `parse_dc_message` probe — only FileOffer is handled at loop level; all other results fall through to `route_inner_message`. FileOffer carved out of `route_inner_message` combined transfer arm to `Ok(None)`. Deterministic reject via `DcMessage::Cancel` with `cancelled_by="receiver"`. Second offer while not Idle triggers `INVALID_STATE("transfer session ended")` + disconnect.

**Files changed:** `src/transfer.rs` (new), `src/envelope.rs`, `src/rendezvous.rs`, `src/lib.rs`, `src/main.rs`
**Tests:** +6 (default: 273→279, test-support: 353→359)
**Gates:** All green (fmt, clippy -D warnings, no unsafe, no unwrap in production)

**Tag naming deviation:** Governance spec defined format `daemon-vX.Y.Z-transfer-converge-B3`. Actual tag is `daemon-v0.2.25-b3-transfer-sm-p1`. Tag is immutable; deviation documented.

#### B3-P2 — MVP Data Plane: Receive + Reassembly in Memory (DONE)

**Tag:** `daemon-v0.2.26-b3-transfer-sm-p2` (`5844199`)
**Date:** 2026-03-03

Extended TransferSession beyond P1 cancel-only behavior to support receiver-side accept, chunk receive with in-memory reassembly, and transfer completion. TransferState extended with Receiving and Completed variants. Auto-accept policy: FileOffer triggers `on_file_offer` (validates size/chunks/cap) → `accept_current_offer` (OfferReceived→Receiving, pre-allocates buffer) → send `DcMessage::FileAccept`. FileChunk: base64 decoded via `bolt_core::encoding::from_base64` in loop before `on_file_chunk` (sequential index enforcement, buffer overflow guard). FileFinish: `on_file_finish` (Receiving→Completed). `completed_bytes()` accessor for test verification. MAX_TRANSFER_BYTES (256 MiB) enforced at offer and chunk level. FileChunk and FileFinish carved out of `route_inner_message` to `Ok(None)` for loop-level handling. Loop interception expanded from `if let` FileOffer pattern to `match` on FileOffer/FileChunk/FileFinish with full error handling. No disk writes, no send-side, no hashing (B4 scope), no pause/resume, no concurrent transfers.

**Files changed:** `src/transfer.rs` (extended), `src/envelope.rs` (carve-outs), `src/rendezvous.rs` (loop interception)
**Tests:** +12 (default: 279→291, test-support: 359→371)
**Gates:** All green (fmt, clippy -D warnings, no unsafe, no unwrap in production)

**Tag naming deviation:** Governance spec defined format `daemon-vX.Y.Z-transfer-converge-B3`. Actual tag is `daemon-v0.2.26-b3-transfer-sm-p2`. Tag is immutable; deviation documented.

**Remaining B3 work:** Pause/resume semantics, cancel handling, disk writes (sender-side streaming), multiple concurrent transfers. (Hashing delivered in B4.)

#### B3 Original Description

The daemon recognizes all seven file transfer message types at the wire level (B2: `daemon-v0.2.21-transfer-converge-B1B2`). As of B3-P2, FileOffer, FileChunk, and FileFinish are intercepted at loop level and processed by TransferSession (auto-accept + in-memory reassembly). FileAccept, Pause, Resume, and Cancel remain `INVALID_STATE("transfer SM not active")` via `route_inner_message`.

**Derived From:**
- PROTOCOL.md §8 (File Transfer — chunking, backpressure, integrity, replay, resource limits)
- PROTOCOL.md §9 (State Machines — Transfer State: IDLE → OFFERED → ACCEPTED → TRANSFERRING ↔ PAUSED → COMPLETED, with ERROR and CANCELLED)
- I2 tracker note: "transport-level E2E (daemon ↔ web live transfer) not yet in CI"
- SA15 (DONE-BY-DESIGN): "Daemon does not implement file transfer" — rationale will be superseded when B3 lands

**Constraints:**
- No protocol semantic changes.
- State machine states must align with PROTOCOL.md §9 transfer lifecycle.
- Transfer engine is internal; session module routes messages to it.
- No async runtime introduced.

**Allowed files (bolt-daemon):**
- `src/transfer.rs` (new — transfer state machine)
- `src/session.rs` or `src/envelope.rs` (routing from session/envelope to transfer engine)
- `src/lib.rs` or `src/main.rs` (module declaration)
- `tests/b3_transfer_engine.rs` (new)
- Existing test files (verify green)

**Gates (B3-P1 — control plane skeleton):**
- [x] Working tree clean before and after
- [x] All existing daemon tests pass: `cargo test` (279 default)
- [x] All existing daemon tests pass: `cargo test --features test-support` (359 test-support)
- [x] New B3-P1 tests pass (6 tests: 3 TransferSession unit, 2 envelope routing, 1 updated loop test + 1 new second-offer disconnect = net +6 from 1 updated + 5 new)
- [x] `cargo clippy -- -D warnings` clean
- [x] `cargo fmt -- --check` clean
- [x] Fail-closed on invalid transitions (INVALID_STATE + disconnect)
- [x] No silent drop paths — FileOffer intercepted, all others route through existing path
- [x] Commit + local tag: `daemon-v0.2.25-b3-transfer-sm-p1`
- [x] Pushed to origin

**Gates (B3-P2 — receive data plane):**
- [x] Working tree clean before and after
- [x] All existing daemon tests pass: `cargo test` (291 default)
- [x] All existing daemon tests pass: `cargo test --features test-support` (371 test-support)
- [x] New B3-P2 tests pass (12 tests: 9 unit + 1 envelope + 2 loop integration)
- [x] `cargo clippy -- -D warnings` clean
- [x] `cargo fmt -- --check` clean
- [x] State machine covers: IDLE → OFFERED → RECEIVING → COMPLETED
- [x] FileAccept sent on auto-accept
- [x] Chunk receive with base64 decode + sequential index enforcement
- [x] In-memory reassembly with MAX_TRANSFER_BYTES cap
- [x] Commit + local tag: `daemon-v0.2.26-b3-transfer-sm-p2`
- [x] Pushed to origin

**Gates (full B3 — remaining):**
- [ ] State machine covers: PAUSE, RESUME, CANCEL transitions
- [ ] Disk writes (sender-side streaming)
- [ ] Multiple concurrent transfers
- [ ] `scripts/check_no_panic.sh` passes

**Acceptance Definition (full B3):**
- Transfer state machine implemented with all normative state transitions enforced
- Fail-closed on invalid transitions (ERROR + disconnect)
- No silent drop paths — every message variant either advances state or errors
- All tests passing, no warnings
- Tagged release

**Tag format:** `daemon-vX.Y.Z-transfer-converge-B3`

---

### B4 — File-Hash Capability + Integrity Enforcement

**Status:** DONE
**Tag:** `daemon-v0.2.27-b4-file-hash` (`b41f814`)
**Date:** 2026-03-03
**Prerequisites:** B3 (transfer engine — B3-P2 receive path sufficient)

**Goal:** Add SHA-256 integrity verification to daemon transfer path. Advertise `bolt.file-hash` in `DAEMON_CAPABILITIES`.

Receiver-side only (daemon is receive-only per B3-P2). After reassembly, computes SHA-256 via `bolt_core::hash::sha256_hex` and verifies against `FILE_OFFER` file_hash (case-insensitive). Capability gating at loop level: if `bolt.file-hash` negotiated and offer hash missing → `INTEGRITY_FAILED` + disconnect. If not negotiated → hash on wire ignored. Sender-side hashing is out of scope (daemon does not send files).

**Derived From:**
- PROTOCOL.md §8 "File Integrity Verification": when `bolt.file-hash` negotiated, `FILE_OFFER` MUST include SHA-256; receiver MUST verify after reassembly; mismatch → `ERROR(INTEGRITY_FAILED)`
- PROTOCOL.md §4 (Version and Capability Negotiation)
- SA15 (DONE-BY-DESIGN): superseded — `bolt.file-hash` now advertised and enforced

**Constraints (enforced):**
- No protocol semantic changes — capability already defined in spec.
- Hash computation uses `bolt_core::hash::sha256_hex` (same SHA-256 as web implementation).
- Mismatch is fail-closed: `INTEGRITY_FAILED` error + disconnect.
- No new dependencies, no new EnvelopeError variants, no wire format changes.
- No new canonical error codes (INTEGRITY_FAILED already in registry).

**Files changed (bolt-daemon):**
- `src/transfer.rs` (extended — IntegrityFailed variant, expected_hash field, on_file_offer signature, on_file_finish verify)
- `src/web_hello.rs` (DAEMON_CAPABILITIES += `bolt.file-hash`, SA15 comment superseded)
- `src/rendezvous.rs` (loop: capability gating, hash threading, IntegrityFailed error path)

**Gates (all green):**
- [x] Working tree clean before and after
- [x] All existing daemon tests pass (default + test-support)
- [x] New B4 tests pass (+9: 4 unit, 5 loop integration)
- [x] `cargo clippy -- -D warnings` clean
- [x] `cargo fmt -- --check` clean
- [x] Hash verified receiver-side (sender-side out of scope — daemon is receive-only)
- [x] Mismatch aborts transfer with `INTEGRITY_FAILED`
- [x] Missing hash when negotiated aborts with `INTEGRITY_FAILED`
- [x] Capability negotiation respected (no hash check when not negotiated)
- [x] Hash on wire ignored when not negotiated
- [x] Commit + tag: `daemon-v0.2.27-b4-file-hash` (`b41f814`)

**Tests:** +9 (default: 291→300, test-support: 371→380)

**Tag naming deviation:** Governance spec defined format `daemon-vX.Y.Z-transfer-converge-B4`. Actual tag is `daemon-v0.2.27-b4-file-hash`. Tag is immutable; deviation documented.

**Note:** SA15 supersession applies — see SA15 Supersession Note below. SA15 is now superseded: `bolt.file-hash` is advertised and receiver-side enforcement is operational.

---

### B5 — TOFU Pin Persistence Activation

**Status:** DONE
**Tag:** `daemon-v0.2.23-b5-tofu-persist` (`0faa729`)
**Date:** 2026-03-02
**Prerequisites:** None (independent)

**Goal:** Wire `TrustStore` to HELLO-derived identity public key. Enable persistent `save()`. Replace ephemeral peer_id binding. Infrastructure exists but persistence is disabled.

**Derived From:**
- PROTOCOL.md §2 (Identity — TOFU pinning requirement)
- `src/identity_store.rs`: persistent identity key generation/loading (SA1 delivered separation)
- `src/ipc/trust.rs`: TrustStore with pin/verify/revoke operations (17 tests passing)
- SA1: identity separation delivered persistent identity keys as prerequisite
- SA15 Supersession Note: TOFU guarantee effectively disabled without pin persistence

**Dependency correction (AUDIT-GOV-27):** WORKSTREAMS-1 listed B3 as a prerequisite. This is incorrect. TOFU pin wiring requires only the HELLO-derived identity public key, which is already available after `parse_hello_message()` returns `inner.identity_public_key`. No transfer engine is needed. B5 is truly independent.

**Constraints:**
- No protocol semantic changes — spec already mandates TOFU.
- Permissions 0600 preserved on pin store files.
- Zeroization guarantees preserved for secret key material.
- This is wiring work, not architectural expansion.

**Allowed files (bolt-daemon):**
- `src/rendezvous.rs` (wire TrustStore into HELLO completion path)
- `src/ipc/trust.rs` (modifications if needed for persistence path)
- `tests/b5_tofu_persistence.rs` (new)
- Existing test files (verify green)

**Gates:**
- [x] Working tree clean before and after
- [x] All existing daemon tests pass (default: 267, test-support: 347)
- [x] `cargo clippy -- -D warnings` clean
- [x] `cargo fmt -- --check` clean
- [x] Identity public key pinned on first contact (Stage B enforcement in offerer + answerer)
- [x] Subsequent connections validated against pin
- [x] Mismatch aborts connection (fail-closed: `StageBResult::Deny`)
- [x] Commit + local tag: `daemon-v0.2.23-b5-tofu-persist`
- [x] Pushed to origin

**Tag naming deviation:** Governance spec defined format `daemon-vX.Y.Z-tofu-persist-B5`. Actual tag is `daemon-v0.2.23-b5-tofu-persist`. Tag is immutable; deviation documented.

**Note:** SA15 supersession applies — see SA15 Supersession Note below.

---

### B6 — Post-HELLO Persistent Event Loop

**Status:** IN-PROGRESS (B6-P1 complete)
**Prerequisites:** None standalone, but **coupled with B3** for useful operation
**Coupled with:** B3 (transfer state machine)

#### B6-P1 — Loop Container (DONE)

**Tag:** `daemon-v0.2.24-b6-loop-container` (`8666f44`)
**Date:** 2026-03-02

Introduced shared `run_post_hello_loop()` used by both offerer and answerer WebDcV1 paths. The loop is testable without a real DataChannel via injected `send_fn` + `mpsc::Receiver`. Transfer messages (all 7 types) return `INVALID_STATE("transfer SM not active")` and trigger disconnect. AppMessage demo send removed. Initial Ping and periodic 2s Ping apply to both roles symmetrically.

**Files changed:** `src/envelope.rs`, `src/rendezvous.rs`
**Tests:** +6 (default: 267→273, test-support: 347→353)
**Gates:** All green (fmt, clippy -D warnings, no unsafe, no unwrap in production)

**Tag naming deviation:** Governance spec defined format `daemon-vX.Y.Z-event-loop-B6`. Actual tag is `daemon-v0.2.24-b6-loop-container`. Tag is immutable; deviation documented.

**B3-P1 integration (AUDIT-GOV-29):** B3-P1 (`daemon-v0.2.25-b3-transfer-sm-p1`) integrated TransferSession into `run_post_hello_loop`. FileOffer intercepted at loop level and rejected via Cancel.

**B3-P2 integration (AUDIT-GOV-30):** B3-P2 (`daemon-v0.2.26-b3-transfer-sm-p2`) expanded loop interception to handle FileOffer (auto-accept→send FileAccept), FileChunk (base64 decode→reassembly), and FileFinish (Receiving→Completed). FileAccept, Pause, Resume, Cancel still hit INVALID_STATE via `route_inner_message`.

**Remaining B6 work:** Full B6 completion requires full B3 — pause/resume, cancel transitions, and remaining transfer lifecycle routing into the event loop.

**Goal:** Replace the deadline-bounded demo loops (INTEROP-3/4) with a persistent recv → decode → route → respond loop after HELLO completes. Both offerer and answerer paths require parity.

Currently, both paths have post-HELLO loops (`rendezvous.rs` lines ~800 and ~1185) but they are bounded by a phase timeout and only handle ping/pong/app_message. They are not persistent and do not route file transfer messages to a state machine.

**Derived From:**
- PROTOCOL.md §6 (Bolt Message Protection — all post-handshake messages must be enveloped)
- PROTOCOL.md §15.4 (Post-Handshake Envelope Requirement)
- `src/envelope.rs`: encode/decode envelope operations exist
- `src/rendezvous.rs`: offerer loop (line ~800) and answerer loop (line ~1185) — both deadline-bounded demo loops

**Dependency correction (AUDIT-GOV-27):** WORKSTREAMS-1 listed B5 (TOFU persistence) as a prerequisite. This is incorrect. The event loop routes messages to the transfer engine and envelope decoder, not to the pin store. B6 depends only on B3 for useful operation.

**Constraints:**
- No async runtime introduced.
- Deterministic shutdown behavior.
- Unknown message types → `UNKNOWN_MESSAGE_TYPE` + disconnect.
- Malformed known types → `INVALID_MESSAGE` + disconnect.
- No silent drops.

**Allowed files (bolt-daemon):**
- `src/rendezvous.rs` (replace demo loops with persistent loops)
- `src/envelope.rs` (if routing adjustments needed)
- `tests/b6_event_loop.rs` (new)
- Existing test files (verify green)

**Gates (B6-P1 — loop container):**
- [x] Working tree clean before and after
- [x] All existing daemon tests pass (default: 273, test-support: 353)
- [x] New B6-P1 tests pass (6 tests: deadline exit, ping→pong, unknown→disconnect, malformed→disconnect, transfer→INVALID_STATE, rx disconnect)
- [x] `cargo clippy -- -D warnings` clean
- [x] `cargo fmt -- --check` clean
- [x] Unknown message types → `UNKNOWN_MESSAGE_TYPE` + disconnect
- [x] Malformed known types → `INVALID_MESSAGE` + disconnect
- [x] No silent drop paths
- [x] Offerer/answerer parity (shared `run_post_hello_loop`)
- [x] Commit + local tag: `daemon-v0.2.24-b6-loop-container`
- [x] Pushed to origin

**Gates (full B6 — remaining):**
- [ ] Event loop runs until disconnect (currently deadline-bounded)
- [ ] All post-HELLO messages routed through envelope decode → transfer SM
- [ ] Deterministic shutdown on DC close

**Acceptance Definition (full B6):**
- Persistent event loop runs until disconnect
- All post-HELLO messages routed through envelope decode → transfer SM
- Error handling fail-closed (no silent drops)
- No async runtime
- Deterministic shutdown
- All tests passing, no warnings, tagged release

**Tag format:** `daemon-vX.Y.Z-event-loop-B6`

---

### D-E2E — Cross-Stack Integration Test

**Status:** NOT-STARTED
**Prerequisites:** B3 (transfer SM), B4 (file-hash), B6 (event loop)

**Goal:** End-to-end integration test connecting Rust daemon, bolt-rendezvous signaling server, and TypeScript web client. Complete HELLO, transfer file, verify integrity both ends.

**Derived From:**
- I2 tracker note: "transport-level E2E (daemon ↔ web live transfer) not yet in CI"
- AC-6: signaling golden vectors prove format parity but not live transfer
- H3: golden vectors prove crypto interop (TS seal → Rust open) but not transport-level roundtrip

**Constraints:**
- CI reproducible — no flake.
- Real signaling server instance (bolt-rendezvous).
- Deterministic pass criteria.
- This is the first phase that touches multiple repos simultaneously.

**Acceptance Definition:**
- Daemon-to-web file transfer roundtrip completes
- SHA-256 integrity verified both ends
- CI reproducible with no flake
- Real signaling server instance
- Deterministic pass/fail
- No warnings

**Tag format:** `daemon-vX.Y.Z-e2e-1` (daemon repo) + consumer repo tags as needed

**Note:** This is the convergence proof — until D-E2E passes, daemon file transfer is not validated against the web implementation.

---

## SA15 Supersession Note

**Context:** SA15 was closed as DONE-BY-DESIGN with the rationale: "daemon does not implement file transfer." This was accurate at the time of assessment.

**Governance intent:** If and when B-stream reaches B4 (file-hash), B5 (TOFU persistence), B6 (event loop), or D-E2E (cross-stack integration), SA15's DONE-BY-DESIGN rationale will no longer hold. At that point:
1. SA15 must be re-evaluated against the daemon's actual file transfer capability.
2. The re-evaluation should be recorded in `docs/AUDIT_TRACKER.md` as a supersession entry.
3. Any new findings from re-evaluation receive new finding IDs (not reuse of SA15).

**This note is governance-only.** It does not modify the audit tracker. It codifies the intent and sequencing so that SA15 is not silently invalidated by B-stream progress.

---

## Phase Gate Checklist (Copy-Pasteable Template)

```
## Phase Report: [PHASE_ID]

**Tag:** [tag]
**Commit:** [short SHA] ([full SHA])
**Date:** [YYYY-MM-DD]

### Pre-Phase
- [ ] Working tree clean (`git status --porcelain` empty)
- [ ] Previous phase tag exists (or N/A for first phase)

### Implementation
- [ ] Only allowed files modified (list files changed)
- [ ] No protocol semantic changes
- [ ] No wire-format changes
- [ ] No cryptographic changes
- [ ] [A-stream only] No public API changes

### Tests
- [ ] Existing tests pass (report: X tests, Y passed, Z failed)
- [ ] New tests pass (report: X tests, Y passed, Z failed)
- [ ] [If applicable] Golden vector tests pass
- [ ] [If applicable] `cargo clippy -- -D warnings` clean
- [ ] [If applicable] `scripts/check_no_panic.sh` passes

### Post-Phase
- [ ] Commit created (subject + body)
- [ ] Local tag created
- [ ] Working tree clean after commit
- [ ] DO NOT push (local only until PM authorizes)

### Files Changed
- `path/to/file` (new|modified|deleted)
```

---

## Tag Naming Rules

| Workstream | Repo | Format | Example |
|------------|------|--------|---------|
| A-stream | bolt-core-sdk | `sdk-vX.Y.Z-webrtc-decompose-A{0..5}` | `sdk-v0.5.22-webrtc-decompose-A0` |
| B-stream (B1–B4) | bolt-daemon | `daemon-vX.Y.Z-transfer-converge-B{1..4}` | `daemon-v0.2.21-transfer-converge-B1` |
| B-stream (B5) | bolt-daemon | `daemon-vX.Y.Z-tofu-persist-B5` | `daemon-v0.2.23-tofu-persist-B5` |
| B-stream (B6) | bolt-daemon | `daemon-vX.Y.Z-event-loop-B6` | `daemon-v0.2.24-event-loop-B6` |
| D-E2E | bolt-daemon | `daemon-vX.Y.Z-e2e-1` | `daemon-v0.2.25-e2e-1` |
| Governance | bolt-ecosystem | `ecosystem-v0.1.X-workstreams-N` | `ecosystem-v0.1.30-workstreams-1` |

**Rules:**
- Determine next version number dynamically: `git tag --list '<prefix>*' | sort -V | tail -1`
- Tags are immutable. Once created, never moved, deleted, or reused.
- Each phase completion produces exactly one tag.
- Version numbers increment monotonically from the latest tag in each repo.

---

## Parallelization Rules

- **A-stream and B-stream CAN run in parallel.** They operate in different repos (bolt-core-sdk vs bolt-daemon) with no shared code changes.
- **Within A-stream:** Phases A1–A4 are sequential (each depends on the prior extraction). A5 depends on A1–A4.
- **Within B-stream (corrected AUDIT-GOV-27):**
  - B1→B2: sequential (B2 depends on B1 defaults). DONE.
  - B3+B6: coupled deliverable (transfer SM needs event loop; event loop needs SM). **Critical path.**
  - B4: **DONE** (`daemon-v0.2.27-b4-file-hash`). Receiver-side only; B3-P2 receive path was sufficient.
  - B5: **DONE** (`daemon-v0.2.23-b5-tofu-persist`). Independent.
  - D-E2E: blocked on B3 full + B6.
- **Cross-stream dependency:** None until D-E2E, which is gated on B3+B4+B6 completion.

---

## No-Push Policy

**Default:** DO NOT push commits or tags to remote repositories during phase execution.

Pushes require explicit PM authorization. Phase reports are filed locally. The PM reviews and authorizes push as a separate action after phase report review.

This policy prevents half-completed workstream states from appearing on remote branches and ensures the PM has review authority over every remote state change.
