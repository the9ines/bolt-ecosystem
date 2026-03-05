# Bolt Ecosystem — Governance Workstreams

> **Status:** Normative
> **Created:** 2026-03-02
> **Tag:** ecosystem-v0.1.55-audit-gov-49
> **Authority:** PM-approved. Phase execution requires separate phase prompts.

---

## Purpose

This document codifies improvement workstreams into governance so that future implementation work is phase-gated, tagged, and non-drifting:

- **Workstream A (A-stream):** WebRTCService decomposition in bolt-core-sdk
- **Workstream B (B-stream):** Daemon file transfer convergence in bolt-daemon
- **Workstream C (C-stream):** LocalBolt application convergence + session UX hardening

These are improvement initiatives — not audit findings, not protocol changes. They decompose existing monolithic code into well-bounded modules (A-stream), extend the daemon toward file transfer capability (B-stream), and converge app-layer behavior across LocalBolt products into a shared `localbolt-core` package (C-stream).

---

## Scope Guardrails

1. **No protocol semantic changes** unless a future phase explicitly authorizes it.
2. **No wire-format changes** unless a future phase explicitly authorizes it.
3. **No cryptographic changes** unless a future phase explicitly authorizes it.
4. **A-stream MUST keep the WebRTCService public API identical.** No breaking changes for localbolt, localbolt-app, or localbolt-v3.
5. **B-stream phases B1–B3 do NOT include** file-hash capability, TOFU persistence activation, or long-lived event loop. Those are deferred phases.
6. **C-stream MUST NOT change protocol semantics, wire format, or cryptographic operations.**
7. **C-stream MUST NOT modify rendezvous subtree policy.** `signal/` subtree in localbolt and localbolt-app remains unchanged.
8. **C-stream MUST NOT use subtree for localbolt-core.** Distribution is package-based with exact version pins.
9. **C-stream MUST NOT change native packaging policy** except adapter wiring in localbolt-app's `src-tauri/` layer.

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
                  │   B3-P3 DONE (sender-side MVP + chunk streaming)
                  ├── coupled deliverable
B6 (event loop) ──┘   B6-P1 DONE (loop container); B3-P3 integrated
                      │
B4 (file-hash) ────── DONE (daemon-v0.2.27-b4-file-hash)
                      │   Receiver-side SHA-256 verification; SA15 superseded
D-E2E-A ────────────── DONE (daemon-v0.2.28-d-e2e-a-live-transfer)
D-E2E-B ────────────── DONE (daemon-v0.2.30-d-e2e-b-cross-impl)
```

**Progress update (AUDIT-GOV-31):** B4 delivered receiver-side SHA-256 hash verification gated by `bolt.file-hash` capability negotiation. `DAEMON_CAPABILITIES` now advertises `bolt.file-hash`. TransferSession extended with `expected_hash` field; `on_file_offer` accepts optional hash; `on_file_finish` verifies via `bolt_core::hash::sha256_hex` (case-insensitive). Capability gating at loop level: negotiated + missing hash → `INTEGRITY_FAILED` + disconnect; not negotiated → hash on wire ignored. New `TransferError::IntegrityFailed` variant. +9 tests (default: 291→300, test-support: 371→380). SA15 superseded. Sender-side hashing out of scope (daemon is receive-only). Remaining for D-E2E: B3 full (pause/resume, cancel, disk writes, send-side) + B6 full.

**Progress update (AUDIT-GOV-43):** B3-P3 delivered sender-side SendSession with cursor-driven chunk streaming. SendSession state machine: Idle→OfferSent→Sending→Completed/Cancelled. `begin_send()` computes metadata and optional SHA-256 hash (gated by `file_hash_negotiated`). FileAccept and Cancel carved out from `route_inner_message` to Ok(None) for loop-level interception. Loop-level FileAccept drives send-side SM: stream all chunks (DEFAULT_CHUNK_SIZE = 16,384 bytes) then send FileFinish; absorbed gracefully when no active outbound transfer. Cancel same pattern. Pause/Resume remain INVALID_STATE. No new DcMessage variants, no new EnvelopeError variants, no new canonical error codes. dc_messages.rs unchanged. +16 tests (default: 302→318, test-support: 382→398 + 1 ignored). Remaining B3 work: pause/resume semantics, disk writes, concurrent transfers.

**Previous update (AUDIT-GOV-30):** B3-P2 extended TransferSession with full receive path: auto-accept (FileOffer→accept→send FileAccept), chunk receive (base64 decode→sequential index enforcement→in-memory reassembly), and transfer completion (FileFinish→Completed). MAX_TRANSFER_BYTES (256 MiB) cap enforced. FileChunk and FileFinish carved out to Ok(None) in `route_inner_message`. Loop interception expanded to match on FileOffer/FileChunk/FileFinish. +12 tests (default: 279→291, test-support: 359→371). No disk writes, no hashing, no send-side. Remaining B3 work: pause/resume, cancel, disk writes, send-side, concurrent transfers. B5 complete (independent).

**Amendment from WORKSTREAMS-1:** B5 was previously listed as dependent on B3. This is incorrect — TOFU pin wiring requires only the HELLO-derived identity key (already present post-INTEROP-2). B6 was previously listed as dependent on B5. This is also incorrect — the event loop routes messages to the transfer engine, not to the pin store.

---

### B3 — Transfer Engine State Machine

**Status:** IN-PROGRESS (B3-P1, B3-P2, B3-P3 complete)
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

#### B3-P3 — Sender-Side Transfer MVP (DONE)

**Tag:** `daemon-v0.2.29-b3-transfer-sm-p3-sender` (`4fd55e3`)
**Date:** 2026-03-03

Added sender-side `SendSession` struct (separate from receive-side `TransferSession`) with cursor-driven chunk streaming. State machine: Idle→OfferSent→Sending→Completed/Cancelled. `begin_send()` stores payload, computes metadata (total_chunks from DEFAULT_CHUNK_SIZE = 16,384 bytes), generates monotonic transfer_id, optionally computes SHA-256 hash. `on_accept()` transitions OfferSent→Sending. `next_chunk()` yields one chunk at a time from cursor. `finish()` validates all chunks yielded, transitions Sending→Completed. `on_cancel()` transitions OfferSent/Sending→Cancelled. One outbound transfer per connection max.

FileAccept and Cancel carved out from `route_inner_message` to Ok(None) (previously INVALID_STATE disconnect). Loop-level interception: FileAccept drives send-side SM when active (stream all chunks + FileFinish), absorbed gracefully when idle. Cancel same pattern. Pause/Resume remain INVALID_STATE in `route_inner_message`.

**Files changed:** `src/transfer.rs` (extended), `src/envelope.rs` (carve-outs), `src/rendezvous.rs` (loop interception), `src/lib.rs` (test_support re-exports)
**Tests:** +16 (default: 302→318, test-support: 382→398 + 1 ignored)
**Gates:** All green (fmt, clippy -D warnings, no unsafe, no unwrap in production)

**Tag naming deviation:** Governance spec defined format `daemon-vX.Y.Z-transfer-converge-B3`. Actual tag is `daemon-v0.2.29-b3-transfer-sm-p3-sender`. Tag is immutable; deviation documented.

**Remaining B3 work:** Pause/resume semantics, disk writes, multiple concurrent transfers. (Hashing delivered in B4. Send-side delivered in B3-P3. Cancel handling delivered in B3-P3.)

#### B3 Original Description

The daemon recognizes all seven file transfer message types at the wire level (B2: `daemon-v0.2.21-transfer-converge-B1B2`). As of B3-P3, FileOffer, FileChunk, FileFinish, FileAccept, and Cancel are all intercepted at loop level. FileOffer/FileChunk/FileFinish are processed by TransferSession (receive-side, auto-accept + in-memory reassembly). FileAccept and Cancel are processed by SendSession (send-side, cursor-driven chunk streaming). Pause and Resume remain `INVALID_STATE("transfer SM not active")` via `route_inner_message`.

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

**Gates (B3-P3 — sender-side MVP):**
- [x] Working tree clean before and after
- [x] All existing daemon tests pass: `cargo test` (318 default)
- [x] All existing daemon tests pass: `cargo test --features test-support` (398 test-support + 1 ignored)
- [x] New B3-P3 tests pass (16 tests: 10 unit + 3 loop integration + 3 net envelope routing)
- [x] `cargo clippy -- -D warnings` clean
- [x] `cargo fmt -- --check` clean
- [x] dc_messages.rs unchanged, run_post_hello_loop signature unchanged
- [x] No new DcMessage/EnvelopeError variants, no new canonical error codes
- [x] Commit + tag: `daemon-v0.2.29-b3-transfer-sm-p3-sender`
- [x] Pushed to origin

**Gates (full B3 — remaining):**
- [x] Send-side transfer (B3-P3)
- [x] Cancel handling (B3-P3)
- [ ] State machine covers: PAUSE, RESUME transitions
- [ ] Disk writes
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

**B3-P3 integration (AUDIT-GOV-43):** B3-P3 (`daemon-v0.2.29-b3-transfer-sm-p3-sender`) added SendSession to `run_post_hello_loop`. FileAccept and Cancel carved out from `route_inner_message` to Ok(None) for loop-level interception. FileAccept drives send-side SM when active (stream chunks + FileFinish), absorbed when idle. Cancel same pattern. Pause/Resume remain INVALID_STATE.

**Remaining B6 work:** Full B6 completion requires full B3 — pause/resume transitions and remaining transfer lifecycle routing into the event loop.

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

**Status:** DONE (D-E2E-A + D-E2E-B complete)
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

#### D-E2E-A Completion (AUDIT-GOV-40)

**Status:** DONE
**Tag:** `daemon-v0.2.28-d-e2e-a-live-transfer` (`b105344`)
**Date:** 2026-03-03

D-E2E-A proves live end-to-end file transfer with SHA-256 hash verification using a synthetic Rust offerer and a real bolt-daemon answerer. The test exercises the full protocol stack:

1. Real bolt-rendezvous child process (WebSocket signaling)
2. Real bolt-daemon answerer child process (WebRTC, web_v1 interop)
3. Synthetic offerer in the Rust test process (datachannel crate, tungstenite)
4. Full signaling: register → hello/ack → SDP offer/answer → ICE exchange
5. Real WebRTC DataChannel (libdatachannel, localhost)
6. Encrypted HELLO exchange (NaCl box, capability negotiation)
7. File transfer: FileOffer (with hash) → FileChunk (4096 bytes) → FileFinish
8. Evidence: `[B4_VERIFY_OK]` emitted on daemon stderr

**Dev-dependencies added (mirrored from deps):** tungstenite, serde_json, serde, datachannel, webrtc-sdp, bolt-core. No new crate dependencies.

**Runtime src/ changes:** ≤10 lines total — `hash_verified()` method on TransferSession (4 lines) + conditional `[B4_VERIFY_OK]` / `[B3]` emission in `run_post_hello_loop` (5 lines).

#### D-E2E-B Completion (AUDIT-GOV-48)

**Status:** DONE
**Tag:** `daemon-v0.2.30-d-e2e-b-cross-impl` (`a8cf108`)
**Date:** 2026-03-04

D-E2E-B delivers true cross-implementation bidirectional file transfer between a Node.js offerer and a Rust daemon answerer. This completes the convergence proof — daemon file transfer is now validated against a separate implementation in a different language.

1. Real bolt-rendezvous child process (WebSocket signaling)
2. Real bolt-daemon answerer child process (WebRTC, web_v1 interop)
3. Node.js offerer (`tests/ts-harness/harness.mjs`) using `node-datachannel`, `tweetnacl`, `ws`
4. Full signaling: register → hello/ack → SDP offer/answer → ICE exchange
5. Real WebRTC DataChannel (libdatachannel, localhost)
6. Encrypted HELLO exchange (NaCl box, capability negotiation: bolt.file-hash + bolt.profile-envelope-v1)
7. **Bidirectional** file transfer:
   - JS→daemon: Pattern A (4096 bytes, `((i+1)*31) & 0xFF`), SHA-256 verified by daemon `[B4_VERIFY_OK]`
   - Daemon→JS: Pattern B (6144 bytes, `((i+1)*37) & 0xFF`), SHA-256 verified by JS harness
8. Evidence: `BOLT_E2E_BIDIR_OK` (harness stdout) + `[B4_VERIFY_OK]` (daemon stderr)

**Test-only send trigger:** 30 lines in `src/rendezvous.rs`, all `#[cfg(feature = "test-support")]`. Reads `BOLT_TEST_SEND_PAYLOAD_PATH` env var after daemon receives a file and sends it back via SendSession. Helper function `test_send_offer()` builds FileOffer message from file on disk.

**Tests added:** 2 `#[ignore]` integration tests in `tests/d_e2e_bidirectional.rs`:
- `d_e2e_b_bidirectional_cross_impl` — happy-path bidirectional transfer
- `d_e2e_b_negative_integrity_mismatch` — flipped hash nibble, harness fails, daemon still verifies its receive

**Test counts:** 318 default (unchanged), 398 test-support + 3 ignored (was +1 ignored).

---

## Workstream C — LocalBolt Application Convergence + Session UX Hardening

**Repos:** localbolt-v3 (extraction baseline), localbolt, localbolt-app, TBD (localbolt-core — location pending C1 ARCH-08 disposition)
**Goal:** Converge app-layer behavior across all three LocalBolt products into a single shared `localbolt-core` package, then harden session UX against disconnect/reconnect race conditions.

### Background

localbolt-v3 has the most advanced app-layer verification and session wiring (H5-v3 TOFU/SAS, DP-3b peer persistence, DP-4 verification gate removal). localbolt and localbolt-app independently implement overlapping app-layer behavior with divergent and lagging implementations. This creates:

- **Behavior drift** — three codebases evolving independently without conformance contracts (Q9)
- **Verification policy ambiguity** — runtime, tests, and docs disagree on whether `unverified` blocks transfer (Q8)
- **Stale callback races** — disconnect/reconnect cycles leave stale verification state and transfer UI callbacks (Q7)
- **Missing drift guards** — transport layer has subtree drift prevention; app layer has none (Q10)

### Extraction Baseline Evidence (localbolt-v3)

The following files constituted the extraction baseline for C2 (pre-extraction locations):

- `packages/localbolt-web/src/services/session-state.ts` → **extracted to** `packages/localbolt-core/src/session-state.ts`
- `packages/localbolt-web/src/services/verification-state.ts` → **extracted to** `packages/localbolt-core/src/verification-state.ts`
- `packages/localbolt-web/src/sections/transfer.ts` → inline gating logic **extracted to** `packages/localbolt-core/src/transfer-policy.ts`
- `packages/localbolt-web/src/components/peer-connection.ts` — peer session controller (now imports from `@the9ines/localbolt-core`)
- `packages/localbolt-web/src/services/identity.ts` — identity bootstrap, keypair persistence (**NOT extracted** — product-specific persistence)
- `packages/localbolt-web/src/__tests__/h5-tofu-verification.test.ts` — TOFU/SAS verification tests (now imports from `@the9ines/localbolt-core`)

### Scope Guardrails

1. **No protocol semantic changes.**
2. **No wire-format changes.**
3. **No cryptographic changes.**
4. **No rendezvous subtree policy changes.** `signal/` subtree in localbolt and localbolt-app remains unchanged.
5. **No native packaging policy changes** except adapter wiring in localbolt-app's `src-tauri/` layer.
6. **No subtree for localbolt-core.** Distribution is package-based with exact version pins.
7. **localbolt-core consumption model:** Published package (npm or equivalent) with exact-pinned versions in consumer `package.json`. NOT a git subtree.

### C-Stream Audit Findings

| Finding | ID | Severity | Status | C-Phase |
|---------|------|----------|--------|---------|
| Disconnect/reconnect stale callback races | Q7 | MEDIUM | OPEN | C7 |
| Verification policy mismatch (runtime vs tests/docs) | Q8 | MEDIUM | DONE-VERIFIED | C0 (locked in `v3.0.70`) |
| App-layer behavior drift across products | Q9 | MEDIUM | DONE-VERIFIED | C2–C5 (all three consumers migrated to `@the9ines/localbolt-core@0.1.0`) |
| Missing app-layer drift guards | Q10 | MEDIUM | DONE-VERIFIED | C6 (guards + upgrade tooling + v3 drift check + runbook; Batch 5) |

---

### C0 — Policy Lock (Verification UX)

**Status:** DONE
**Tag:** `v3.0.70-session-hardening-cpre2` (`cac5e4a`)
**Prerequisites:** PM policy decision required → **RESOLVED**

**Goal:** Establish a single authoritative policy for verification-gated transfer behavior. Before extraction can proceed, runtime behavior, test expectations, and documentation must be consistent.

**PM decision (locked):** `unverified` peer status **blocks** file transfer (Option A). Transfer UI hidden until SAS verification completes or peer is legacy (pre-SAS). DP-4 direction partially reverted — unverified state blocks transfer, but legacy peers (no SAS capability) are allowed.

**Policy codified as `isTransferAllowed()`:**
- `verified` + connected → transfer allowed
- `legacy` + connected → transfer allowed (pre-SAS peer, encryption still active)
- `unverified` + connected → transfer **BLOCKED** (SAS pending)
- any state + disconnected → transfer **BLOCKED**

**Acceptance Criteria:**
- [x] PM policy decision recorded (unverified blocks transfer)
- [x] Runtime behavior matches policy decision (`v3.0.70`)
- [x] Tests match policy decision (33 session-hardening tests)
- [x] Documentation matches policy decision (transfer.ts comments, test assertions)
- [x] Consistency verified across localbolt-v3 extraction baseline

**Q8 resolved:** Verification policy mismatch eliminated. Runtime, tests, and docs all agree.

---

### C1 — localbolt-core Scaffold + ARCH-08 Disposition

**Status:** DONE
**Tag:** `v3.0.71-localbolt-core-c2` (`aa9e40e`)
**Prerequisites:** C0 (policy lock) → **DONE**

**Goal:** Establish the localbolt-core package structure, governance ownership model, and resolve the ARCH-08 disposition gate.

**ARCH-08 Disposition: Option 2 — Non-violating location**

ARCH-08 invariant ("No new top-level folders under workspace root") resolved by placing `localbolt-core` inside `localbolt-v3/packages/` — an existing npm workspace with `packages/*` glob. No waiver needed. No new top-level folder created.

**Location:** `localbolt-v3/packages/localbolt-core/`

**Package distribution model:**
- `@the9ines/localbolt-core@0.1.0` (private, workspace-resolved)
- Consumer dependency: `"@the9ines/localbolt-core": "*"` (npm workspace symlink)
- NOT a git subtree. NOT published to npm registry (workspace-internal).
- Future external consumers (localbolt, localbolt-app) will require publishing or workspace restructuring.

**Tag discipline:** localbolt-core follows localbolt-v3 tag convention (`v3.0.<N>-<slug>`). No separate tag prefix — core is part of the localbolt-v3 workspace.

**Governance ownership:** localbolt-v3 repo owns localbolt-core. Same CI pipeline, same branch, same tag discipline.

**Acceptance Criteria:**
- [x] ARCH-08 disposition decision recorded with rationale (Option 2: non-violating location)
- [x] localbolt-core scaffold created at `localbolt-v3/packages/localbolt-core/`
- [x] Package.json with version 0.1.0 (`@the9ines/localbolt-core`)
- [x] Governance ownership model documented (localbolt-v3 repo)
- [x] Tag prefix defined (localbolt-v3 convention)
- [x] CI pipeline: tsc build + vitest tests

---

### C2 — Extract Canonical Runtime from v3 Baseline

**Status:** DONE
**Tag:** `v3.0.71-localbolt-core-c2` (`aa9e40e`)
**Prerequisites:** C1 (scaffold + location) → **DONE**

**Goal:** Extract shared app-layer behavior from localbolt-v3 into localbolt-core. This is the canonical extraction — localbolt-v3 is the source of truth.

**Extracted modules:**

| Module | Source (web) | Destination (core) |
|--------|-------------|-------------------|
| Session state machine | `src/services/session-state.ts` | `src/session-state.ts` |
| Verification state bus | `src/services/verification-state.ts` | `src/verification-state.ts` |
| Transfer gating policy | inline in `src/sections/transfer.ts` | `src/transfer-policy.ts` (new) |
| Barrel export | — | `src/index.ts` (new) |

**What was NOT extracted (deferred / stays in web):**
- Identity bootstrap (`src/services/identity.ts`) — stays in web (persistence adapter is product-specific)
- Pin store — stays in web (IndexedDB-specific)
- All UI components and DOM elements

**Test evidence:**
- 33 session-hardening tests in core (`src/__tests__/session-hardening.test.ts`)
- 8 transfer-policy tests in core (`src/__tests__/transfer-policy.test.ts`)
- 41 total core tests pass
- 59 web tests pass (no regression)

**Acceptance Criteria:**
- [x] Verification state bus extracted and tested (verification-state.ts, 6 bus tests)
- [ ] Identity bootstrap extracted and tested — **DEFERRED** (product-specific persistence)
- [x] Peer session controller extracted and tested (session-state.ts, 33 tests)
- [x] Transfer gating behavior extracted and tested (transfer-policy.ts, 8 tests)
- [x] All extracted modules pass unit tests in localbolt-core (41 tests)
- [x] localbolt-v3 extraction baseline tests still pass (59 tests, no regression)

**Note:** Identity bootstrap deferred — `identity.ts` depends on `IndexedDBIdentityStore` which is product-specific. A persistence adapter interface will be needed before extracting to core.

---

### C3 — Migrate localbolt-v3 Consumer

**Status:** DONE
**Tag:** `v3.0.71-localbolt-core-c2` (`aa9e40e`) — executed in same commit as C2
**Prerequisites:** C2 (extraction) → **DONE**

**Goal:** localbolt-v3 consumes localbolt-core for shared app-layer behavior. localbolt-v3 retains ownership of SEO/content/shell only.

**Migration details:**
- `packages/localbolt-web/package.json` depends on `"@the9ines/localbolt-core": "*"` (workspace-resolved)
- `peer-connection.ts`: imports from `@the9ines/localbolt-core` (was `@/services/session-state` + `@/services/verification-state`)
- `transfer.ts`: imports `getVerificationState`, `onVerificationStateChange`, `isTransferAllowed` from `@the9ines/localbolt-core`
- `h5-tofu-verification.test.ts`: imports from `@the9ines/localbolt-core`
- `session-hardening.test.ts`: kept in web (imports from `@the9ines/localbolt-core`) as consumer wiring integration test
- Deleted: `src/services/session-state.ts`, `src/services/verification-state.ts`

**Acceptance Criteria:**
- [x] localbolt-v3 `package.json` depends on localbolt-core (`"@the9ines/localbolt-core": "*"`)
- [x] Duplicated behavior modules removed (session-state.ts, verification-state.ts deleted)
- [x] localbolt-v3 retains SEO, content, layout, and shell ownership
- [x] All localbolt-v3 tests pass (59 web tests, no regression)
- [x] Vite build succeeds

---

### C4 — Migrate localbolt Consumer

**Status:** DONE
**Tags:** `localbolt-v1.0.21-c4-localbolt-core`, `localbolt-v1.0.22-c6-core-guards` (`ed2d671`)
**Prerequisites:** C2 (extraction)

**Goal:** localbolt (lite self-hosted app) consumes localbolt-core for shared app-layer behavior. Remove duplicated behavior modules.

**Acceptance Criteria:**
- [x] localbolt `package.json` depends on `@the9ines/localbolt-core@0.1.0` with exact version pin
- [x] Duplicated behavior modules removed from localbolt
- [x] All localbolt tests pass (no regression)
- [x] Self-hosted deployment verified

---

### C5 — Migrate localbolt-app Web Consumer

**Status:** DONE
**Tags:** `localbolt-app-v1.2.4-c5-localbolt-core`, `localbolt-app-v1.2.5-c6-core-guards` (`d1761e9`)
**Prerequisites:** C2 (extraction)

**Goal:** localbolt-app web layer consumes localbolt-core for shared app-layer behavior. `src-tauri/` native layer and Tauri-specific adapters remain local.

**Acceptance Criteria:**
- [x] localbolt-app web layer `package.json` depends on `@the9ines/localbolt-core@0.1.0` with exact version pin
- [x] Duplicated behavior modules removed from web layer
- [x] `src-tauri/` native ownership preserved (IPC, system tray, file system access)
- [x] Tauri build succeeds
- [x] localbolt-app tests pass (no regression)

---

### C6 — Drift Guards + Upgrade Protocol

**Status:** DONE
**Prerequisites:** C3, C4, C5 (all consumers migrated — DONE)

**Goal:** Prevent app-layer drift by establishing CI-enforceable guards and a deterministic upgrade protocol for localbolt-core across all consumers.

**Delivered (Batch 3):**
- Enforcement guards added to localbolt (`localbolt-v1.0.22-c6-core-guards`) and localbolt-app (`localbolt-app-v1.2.5-c6-core-guards`)
- Guards verify localbolt-core version pin and import consistency

**Delivered (Batch 5 — C6 hardening):**
- `upgrade-localbolt-core.sh` added to localbolt and localbolt-app — check mode (`--check`) validates version pin, lockfile consistency, and single install; upgrade mode bumps pin, reinstalls, runs build+test gates
- `check-core-drift.sh` added to localbolt-v3 — detects ad-hoc orchestration reimplementation in `packages/localbolt-web/src`
- localbolt-v3 CI updated: core drift guard wired using explicit `packages/localbolt-web/src` path
- Manual drift validation executed and documented in `docs/LOCALBOLT_CORE_DRIFT_RUNBOOK.md`
- **localbolt-v3 workspace exemption:** consumer-style guards (version-pin, single-install) are not applicable because localbolt-v3 is the origin workspace — localbolt-core is resolved via npm workspace, not registry install. Only the drift check applies. Rationale documented in runbook.

**Acceptance Criteria:**
- [x] Enforcement guards added to localbolt and localbolt-app consumers
- [x] Upgrade tooling implemented and tested (check + write modes)
- [x] CI gates added to all three consumer repos (3/3 guards in consumers, drift guard in v3)
- [x] Upgrade protocol documented (LOCALBOLT_CORE_DRIFT_RUNBOOK.md)
- [x] Manual drift scenario verified (all guards pass, reproducible commands captured)

---

### C7 — Session UX Race-Hardening

**Status:** IN-PROGRESS
**Prerequisites:** C2 (shared session controller in localbolt-core) — MET

**Goal:** Harden the shared session controller against disconnect/reconnect race conditions that cause incorrect UI and session state.

**Required deliverables:**
- **Canonical session state machine** — explicit states (disconnected, connecting, connected, handshaking, verified, error) with validated transitions. Invalid transitions are fail-closed.
- **Stale callback / session generation guard pattern** — all async callbacks (verification, transfer progress, peer list) check session generation counter before state mutation. Stale callbacks from previous sessions are discarded.
- **Race-focused integration tests** — disconnect during handshake, reconnect during transfer, rapid connect/disconnect cycling, concurrent verification callbacks from different sessions.

**Derived From:**
- SA14 (helloTimeout stale callback — SDK-level fix exists but app-layer callbacks remain unguarded)
- Q7 (disconnect/reconnect stale callback races)

**Acceptance Criteria:**
- [ ] Session state machine formalized in localbolt-core with validated transitions
- [x] Session generation counter guards all async callbacks — localbolt (`1bcb7b8`), localbolt-app (`e902186`)
- [ ] Integration tests cover: disconnect during handshake, reconnect during transfer, rapid cycling
- [x] No stale state leaks across session boundaries (generation guard prevents stale mutation)
- [x] All consumer tests pass — localbolt 300, localbolt-app 11

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
| C-stream (consumers) | localbolt-v3, localbolt, localbolt-app | `<repo-prefix>-C<N>-<slug>` | `v3.0.70-C3-core-migration` |
| C-stream (localbolt-core) | TBD (pending C1) | Deferred to C1 ARCH-08 disposition | — |
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
  - B3+B6: coupled deliverable (transfer SM needs event loop; event loop needs SM). **Critical path.** B3-P1/P2/P3 done; remaining: pause/resume, disk writes, concurrent transfers.
  - B4: **DONE** (`daemon-v0.2.27-b4-file-hash`). Receiver-side only; B3-P2 receive path was sufficient.
  - B5: **DONE** (`daemon-v0.2.23-b5-tofu-persist`). Independent.
  - D-E2E-A: **DONE** (`daemon-v0.2.28-d-e2e-a-live-transfer`). Live Rust↔Rust E2E.
  - D-E2E-B: **DONE** (`daemon-v0.2.30-d-e2e-b-cross-impl`). Cross-implementation TS↔Rust bidirectional E2E.
- **Within C-stream:**
  - C0: blocked on PM policy decision (verification UX). Must complete before C2.
  - C1: blocked on C0. ARCH-08 disposition blocks all physical placement (C2–C7).
  - C2: blocked on C1. Extraction from localbolt-v3.
  - C3, C4, C5: DONE. All three consumers migrated to `@the9ines/localbolt-core@0.1.0`.
  - C6: DONE. Guards + upgrade tooling + v3 drift check + runbook. Batch 5.
  - C7: IN-PROGRESS. Generation guard race hardening landed in localbolt and localbolt-app. Remaining: formalized session state machine, rapid cycling integration tests.
- **Cross-stream dependency:** C-stream is independent of A-stream and B-stream. C-stream operates at app-layer; A/B operate at SDK/daemon protocol layers. No shared code changes.

---

## No-Push Policy

**Default:** DO NOT push commits or tags to remote repositories during phase execution.

Pushes require explicit PM authorization. Phase reports are filed locally. The PM reviews and authorizes push as a separate action after phase report review.

This policy prevents half-completed workstream states from appearing on remote branches and ensures the PM has review authority over every remote state change.
