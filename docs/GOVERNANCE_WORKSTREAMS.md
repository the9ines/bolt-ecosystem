# Bolt Ecosystem — Governance Workstreams

> **Status:** Normative
> **Created:** 2026-03-02
> **Updated:** 2026-03-12 (DISCOVERY-MODE-1 stream codified)
> **Tag:** ecosystem-v0.1.116-discovery-mode1-codify
> **Authority:** PM-approved. Phase execution requires separate phase prompts.

---

## Purpose

This document codifies improvement workstreams into governance so that future implementation work is phase-gated, tagged, and non-drifting:

- **Workstream A (A-stream):** WebRTCService decomposition in bolt-core-sdk
- **Workstream B (B-stream):** Daemon file transfer convergence in bolt-daemon
- **Workstream C (C-stream):** LocalBolt application convergence + session UX hardening
- **Workstream D (D-stream):** CI stabilization + package auth migration
- **S-STREAM-R1:** Security/foundation recovery (daemon key architecture, product crypto-path convergence, security test lift)
- **N-STREAM-1:** Native app + daemon bundling (app packaging, process lifecycle, IPC contract, supervision)

These are improvement initiatives — not audit findings, not protocol changes. They decompose existing monolithic code into well-bounded modules (A-stream), extend the daemon toward file transfer capability (B-stream), converge app-layer behavior across LocalBolt products into a shared `localbolt-core` package (C-stream), stabilize CI/deploy reliability with PAT-independent public package installs (D-stream), resolve foundational security/runtime risks before further UX work (S-STREAM-R1), and define how native apps bundle and lifecycle-manage bolt-daemon (N-stream).

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
10. **D-stream MUST NOT modify protocol/runtime behavior in bolt-core-sdk.** Only package metadata and publish workflow changes are in-scope (D3).
11. **D-stream MUST NOT modify subtree-managed paths directly.**
12. **D-stream D2 changes MUST be evidence-driven from D1.** No speculative broad hardening.
13. **N-STREAM-1 MUST NOT redefine daemon protocol behavior.** Daemon protocol/runtime is B-stream ownership.
14. **N-STREAM-1 MUST NOT modify bolt-daemon runtime logic** unless explicitly gated by a phase prompt with PM approval.
15. **N-STREAM-1 scope is localbolt-app first.** Future native consumers (e.g., bytebolt-app) require separate approval.
16. **N-STREAM-1 excludes localbolt (web app)** — daemon bundling in web apps requires separate architecture governance approval.
17. **N-STREAM-1 excludes localbolt-v3** — architecture explicitly prohibits bundling native binaries/daemons in web app path (ARCHITECTURE.md §6).
18. **N-STREAM-1 N2 stabilizes only currently available daemon API surface.** Extension clauses for future B-stream phases are permitted but MUST NOT assume unfinished daemon features are complete.
19. **Any N-stream phase requiring new top-level folders MUST resolve ARCH-08 disposition first.**

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
- [x] State machine covers: PAUSE, RESUME transitions — **B-XFER-1 DONE** (`daemon-v0.2.35-bxfer1-pause-resume`)
- [ ] Disk writes (deferred — separate future item)
- [ ] Multiple concurrent transfers (deferred — PM-FB-01 resolved: out of scope for B-XFER-1)
- [x] `scripts/check_no_panic.sh` passes

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

**B-XFER-1 integration:** B-XFER-1 (`daemon-v0.2.35-bxfer1-pause-resume`) completed sender-side pause/resume. Pause and Resume carved out from `route_inner_message` to Ok(None) for loop-level dispatch. Chunk streaming restructured from tight `while let` loop to incremental one-chunk-per-iteration at top of main loop, allowing Pause/Resume/Cancel interleaving. SendState gains `Paused` variant (Sending→Paused→Sending). 12 new unit tests, 2 updated envelope tests, 2 integration tests. PM-FB-01 resolved: concurrent transfers out of scope.

**Remaining B6 work:** Disk writes (received files currently in-memory only) and multiple concurrent transfers. Pause/resume routing into event loop is complete (B-XFER-1).

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
| Disconnect/reconnect stale callback races | Q7 | MEDIUM | DONE-VERIFIED | C7 |
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

## Workstream D — CI Stabilization + Package Auth Migration (D-STREAM-1)

**Repos:** localbolt-v3 (primary), bolt-core-sdk (D3 only), localbolt, localbolt-app, bolt-ecosystem
**Goal:** Stabilize CI failure noise, migrate deploy-critical public packages to PAT-independent install paths, and harden Netlify deployment reliability.
**Priority:** Netlify deploy reliability is the primary success gate.

### Background

Workstream C is fully closed (C0–C7 DONE). Current operational issues:
1. Recurring CI alert noise across repos
2. PAT-dependent package installs causing deploy fragility (especially Netlify)

**Prior art:** DP-8 (DONE-VERIFIED) mitigated Netlify auth failure via PAT-based `.npmrc` (`${NPM_TOKEN}`) in localbolt-web. D-STREAM addresses root cause: PAT dependency for public install paths.

### Non-Negotiable Priority

**Netlify deploy must be stable and PAT-independent for public package installs.**

### Deploy-Critical Package Seed Set

Verify completeness in D1:

| Package | Owner Repo | Notes |
|---------|-----------|-------|
| `@the9ines/bolt-core` | bolt-core-sdk | Protocol SDK |
| `@the9ines/bolt-transport-web` | bolt-core-sdk | Transport layer |
| `@the9ines/localbolt-core` | localbolt-v3 | App-layer convergence package |

### Repo Scope

| Repo | Phases | Scope |
|------|--------|-------|
| localbolt-v3 | D1, D2, D3, D4, D5, D6 | Primary Netlify path |
| bolt-core-sdk | D3 only | Package metadata/publish workflow updates; no protocol/runtime logic |
| localbolt | D1 (if top recurring CI signature), D3, D5 | Consumer dependency/auth/guard posture |
| localbolt-app | D1 (if top recurring CI signature), D3, D5 | Consumer dependency/auth/guard posture |
| bolt-ecosystem | all | Governance codification |

### D-STREAM-1 Phase Table

| Phase | Description | Status | Dependencies | Acceptance Criteria |
|-------|-------------|--------|-------------|---------------------|
| D0 | Policy lock | **DONE** | None | Policy decisions 1–4 recorded; D0.5 scope verification passed |
| D1 | Failure triage + classification | **DONE** | None | Ranked failure matrix with frequency, repos, first/last seen, owner; Netlify blocker(s) identified |
| D2 | CI stabilization (evidence-driven) | NOT-STARTED | D1 | Per-repo stabilization checklist mapped to D1 signatures; no speculative hardening |
| D3 | Package auth/registry migration | **DONE** | D0.5 | Deploy-critical packages on npmjs.org; PAT not required for public install; GitHub Packages fallback preserved |
| D4 | Netlify hardening (critical path) | **DONE** | D3 | Clean-environment Netlify install/build passes; lockfile + registry deterministic; rollback tested |
| D5 | Drift guards + enforcement | **DONE** | D4 | CI guard matrix with C6 baseline + D-specific additions; ownership assigned |
| D6 | Burn-in + closure | NOT-STARTED | D4, D5 | 48h burn-in; 5 green CI runs/repo; 3 Netlify deploys; zero D1 auth/registry recurrence |

### D0 — Policy Lock

**Status:** DONE

**PM-approved policy decisions (decided at codification):**

1. Public deploy-critical `@the9ines` packages MUST install without GitHub PAT.
2. GitHub Packages MAY remain for private artifacts only.
3. Netlify builds MUST succeed with standard project-managed env/config (no personal PAT reliance).
4. npmjs.org publication approved for deploy-critical public packages.

**D0.5 — @the9ines npmjs scope verification:** DONE (2026-03-05). Scope owned by `the9ines` user on npmjs.org. Automation token configured. All 3 deploy-critical packages published and verified installable without PAT.

**Dependency gate:** D0.5 passed. D3 unblocked.

**`@the9ines/localbolt-core` note:**
- Netlify/localbolt-v3 path may remain workspace-resolved (localbolt-core is in `localbolt-v3/packages/`)
- Registry migration for localbolt-core mainly affects non-workspace consumers (localbolt/localbolt-app CI/install)
- Decision and rationale recorded here; implementation details in D3

---

### D1 — Failure Triage + Classification

**Status:** DONE (2026-03-05)

**Collection window:** Last 20 failed CI runs OR last 14 days (whichever yields more evidence) per in-scope repo. Recent failed Netlify deploys for localbolt-v3 in same window.

**Classification signatures:**
- workflow/config error
- dependency/auth/registry failure
- flaky test
- deterministic regression
- infra/transient

**Deliverable:** Ranked failure matrix (frequency, impacted repos, first/last seen, likely owner). Top blocker signatures, explicitly identifying Netlify blocker(s).

#### D1 Failure Matrix (ranked by Netlify impact)

| Rank | Signature | ID | Count | Repos | First Seen | Last Seen | Owner |
|:----:|-----------|------|:-----:|-------|-----------|----------|-------|
| 1 | auth/registry — GitHub Packages requires PAT for all installs (even public) | GHPKG-AUTH-FAIL | 1 formal (DP-8) + structural | localbolt-v3 (Netlify) | 2026-03-04 | ongoing | D-STREAM-1 |
| 2 | infra/transient — Netlify serves stale code on silent install failure | DEPLOY-STALE | 1 | localbolt-v3 (Netlify) | 2026-03-04 | 2026-03-04 | D-STREAM-1 |
| 3 | dependency/toolchain — SDK package not yet published when consumer needs it | SDK-PUBLISH-LAG | 3 (DP-6, DP-7, DP-9) | localbolt-v3, bolt-core-sdk | 2026-03-04 | 2026-03-04 | SDK maintainer |
| 4 | workflow/config — Tauri build path mismatch + missing icons + ungated release | BUILD-PATH-MISMATCH | 3 | localbolt-app | 2026-02-19 | 2026-02-23 | localbolt-app maintainer |
| 5 | deterministic regression — App-layer code reimplementing core logic | DRIFT-REGRESSION | 4 pattern classes | localbolt-v3, localbolt, localbolt-app | pre-C6 | mitigated (C6 guards) | C-stream |

**No flaky test signatures observed.** All test failures across the collection window were deterministic (missing exports, missing dependencies, or configuration errors).

#### Top Netlify Blocker (explicit)

**GHPKG-AUTH-FAIL** — GitHub Packages (npm.pkg.github.com) requires authentication even for public packages. This is a fundamental GitHub platform limitation, not a configuration error.

- **Current state:** localbolt-v3 Netlify builds depend on `NPM_TOKEN` environment variable containing a GitHub PAT with `packages:read` scope. This PAT is a personal access token, creating a single-person dependency and token rotation risk.
- **Root cause:** All three deploy-critical `@the9ines` packages (`bolt-core`, `bolt-transport-web`, `localbolt-core`) are published exclusively to GitHub Packages. No config-only workaround exists to make GitHub Packages public installs PAT-free.
- **DP-8 workaround (in production):** `.npmrc` files at workspace root and `packages/localbolt-web/` reference `${NPM_TOKEN}`. Token must be set in Netlify dashboard.
- **Resolution path:** D3 (publish to npmjs.org) + D4 (update `.npmrc` to resolve from npmjs.org for public packages).

#### D4 STOP Report (D3 dependency)

D4 **cannot** be completed with existing published artifacts and config changes only.

**Blocked packages:**

| Package | Version | Current Registry | Why PAT-Free Is Impossible |
|---------|---------|-----------------|---------------------------|
| `@the9ines/bolt-core` | 0.5.0 | npm.pkg.github.com | GitHub Packages requires auth for all installs |
| `@the9ines/bolt-transport-web` | 0.6.2 | npm.pkg.github.com | GitHub Packages requires auth for all installs |
| `@the9ines/localbolt-core` | 0.1.0 | npm.pkg.github.com (+ workspace) | Workspace-resolved in localbolt-v3, but consumed from registry by localbolt/localbolt-app |

**Minimum D3 substeps required to unblock D4:**

1. **D0.5** (prerequisite): Verify `@the9ines` scope ownership/availability on npmjs.org
2. **D3.1**: Configure npmjs.org publish credentials (org-level, not personal PAT)
3. **D3.2**: Publish `@the9ines/bolt-core@0.5.0` to npmjs.org
4. **D3.3**: Publish `@the9ines/bolt-transport-web@0.6.2` to npmjs.org
5. **D3.4**: Publish `@the9ines/localbolt-core@0.1.0` to npmjs.org (for non-workspace consumers)
6. **D3.5**: Update `.npmrc` in localbolt-v3 to resolve `@the9ines` from npmjs.org (PAT-free path)

**Note on localbolt-core workspace resolution:** In localbolt-v3, `@the9ines/localbolt-core` resolves via npm workspace link (not registry) during `npm install`. This means D3.4 is only strictly required for localbolt and localbolt-app consumers. However, the `.npmrc` registry mapping applies to all `@the9ines/*` packages uniformly, so D3.2 and D3.3 are hard blockers for any PAT-free install path.

---

### D2 — CI Stabilization (Evidence-Driven)

**Status:** NOT-STARTED
**Prerequisites:** D1

**Scope:** Execute fixes only for D1-proven signatures:
- Deterministic workflow/config fixes first
- Toolchain pinning only where D1 proves version drift caused failures
- Cache/preflight hardening only where tied to observed failures
- Retries only for known transient classes

**Deliverable:** Per-repo stabilization checklist mapped to D1 signatures. No speculative hardening outside proven failure classes.

---

### D3 — Package Auth/Registry Migration

**Status:** DONE (2026-03-05)
**Prerequisites:** D0.5 (PASSED)

**Execution plan (completed):**
1. Verify deploy-critical package inventory (seed list + discovery) — DONE
2. Verify npmjs @the9ines scope readiness (D0.5 gate) — DONE
3. Publish/republish public deploy-critical packages to npmjs.org per policy — DONE
4. Update dependency resolution and `.npmrc` strategy to remove PAT requirement for public install paths — DONE (consumer `.npmrc` cutover deferred to D4)
5. Preserve GitHub Packages path for private artifacts — DONE (existing GH Packages workflows preserved)
6. Preserve existing GitHub Packages publish path as fallback until D6 burn-in completes — DONE
7. Define owner for npm publish token/secret management (team/service account, not personal token) — DONE (`NPM_TOKEN` secret; automation token)
8. Rollback plan for failed cutover: temporary re-enable PAT-based path (DP-8 pattern) with explicit revert criteria — DONE (GH Packages workflows unchanged)

**Published packages:**

| Package | npmjs Version | GitHub Packages Version | Notes |
|---------|--------------|------------------------|-------|
| `@the9ines/bolt-core` | 0.5.1 | 0.5.0 (prior) | Version bump for npmjs (0.5.0 was locked) |
| `@the9ines/bolt-transport-web` | 0.6.4 | 0.6.2 (prior) | Version bumps: 0.6.2/0.6.3 locked on npmjs |
| `@the9ines/localbolt-core` | 0.1.2 | 0.1.0 (prior) | Version bumps: 0.1.0/0.1.1 locked on npmjs |

**Package metadata changes:**
- `publishConfig` changed from `{"registry": "https://npm.pkg.github.com"}` to `{"access": "public"}` in all 3 packages
- Existing GitHub Packages workflows updated with explicit `--registry https://npm.pkg.github.com` flag
- New `workflow_dispatch`-only npmjs publish workflows created for all 3 packages
- PAT-free install verified for all 3 packages from clean environment

**bolt-core-sdk governance detail:**
- Dual-publish (GitHub Packages + npmjs) is temporary during burn-in (D6). Post-D6 closure, GitHub Packages publish for public packages will be evaluated for removal.

---

### D4 — Netlify Hardening (Critical Path)

**Status:** DONE (2026-03-06)
**Prerequisites:** D3

**Execution (completed):**

1. **Consumer `.npmrc` cutover** — All 3 consumer repos (localbolt-v3, localbolt, localbolt-app) switched from `@the9ines:registry=https://npm.pkg.github.com` to `@the9ines:registry=https://registry.npmjs.org`. PAT token references removed from `.npmrc`.
2. **Dependency bumps** — All consumers updated to npmjs versions: bolt-core 0.5.1, transport-web 0.6.4, localbolt-core 0.1.2.
3. **Lockfile regeneration** — All lockfiles regenerated from registry.npmjs.org. Package resolution verified deterministic.
4. **Build/test verification** — localbolt-v3: 102 tests pass; localbolt: 300 tests pass; localbolt-app: 11 tests pass.
5. **Netlify deploy** — Clean-environment build passes PAT-free. Deploy verified: `state=ready`, `commit=0746275`, HTTP 200 at https://localbolt.app.
6. **Netlify build fix** — Root cause: `@the9ines/localbolt-core` workspace symlink has no `dist/` on clean clone. Vite's commonjs-resolver couldn't resolve the entry point. Fixed by building localbolt-core before localbolt-web in `netlify.toml`. `base` removed to avoid monorepo path conflict.

**Netlify site config (post-D4):**
- Build command: controlled by `netlify.toml` only (site-level cleared)
- `NPM_TOKEN` env var: still set (inert GitHub PAT; `.npmrc` no longer references it). Retained through D6 burn-in for rollback safety.
- `VITE_SIGNAL_URL` env var: still set (required for app function)

**Tags:**
- localbolt-v3: `v3.0.76-d4-npmjs-cutover` (`ef0543e`), `v3.0.77-d4-netlify-build-fix` (`0746275`)
- localbolt: `localbolt-v1.0.25-d4-npmjs-cutover` (`9bb3c38`)
- localbolt-app: `localbolt-app-v1.2.8-d4-npmjs-cutover` (`55c3e17`)

**Gates (all passed):**
- [x] localbolt-v3 Netlify install/build passes in clean environment
- [x] PAT not required for public package install path
- [x] Lockfile + registry resolution deterministic
- [x] Required env vars minimal and documented
- [x] Preflight checks validate auth/registry assumptions before full build
- [x] Rollback procedure documented (GH Packages workflows preserved, `NPM_TOKEN` retained)

**Deliverable:** Netlify validation report with successful post-cutover deploy evidence — deploy `state=ready`, `commit=0746275`, HTTP 200 at localbolt.app.

---

### D5 — Drift Guards + Enforcement

**Status:** DONE (2026-03-06)
**Prerequisites:** D4

**Baseline:** C6 guards (version pin, single-install, drift) preserved unchanged.

**D5-specific guards (additive):**

| Guard | Script | Checks | Placement |
|-------|--------|--------|-----------|
| Registry mapping | `check-registry-mapping.sh` | `.npmrc` maps `@the9ines` to `registry.npmjs.org`; rejects `npm.pkg.github.com` and `_authToken` references | Before `npm ci` |
| Lockfile registry | `check-lockfile-registry.sh` | `package-lock.json` resolves `@the9ines` packages from `registry.npmjs.org`; rejects `npm.pkg.github.com` resolved URLs | After `npm ci` |

**CI cleanup (all 3 repos):**
- Removed `registry-url: https://npm.pkg.github.com` from `setup-node` (stale after D4)
- Removed `NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}` from `npm ci` (npmjs.org is PAT-free)
- Removed `packages: read` permission (no GitHub Packages access needed)

**Tags:**
- localbolt-v3: `v3.0.78-d5-registry-guards` (`fec153b`)
- localbolt: `localbolt-v1.0.26-d5-registry-guards` (`76ae224`)
- localbolt-app: `localbolt-app-v1.2.9-d5-registry-guards` (`93afc2c`)

**Guard ownership:** D-stream maintainer (ecosystem-level CI governance).

**Deliverable:** CI guard matrix with C6 baseline + D5 registry/auth additions. All guards pass locally.

---

### D6 — Burn-in + Closure

**Status:** NOT-STARTED
**Prerequisites:** D4, D5

**Burn-in window:** Minimum 48 hours after final D4/D5 changes land.

**Thresholds:**
- Minimum 5 consecutive green CI runs per affected repo
- Minimum 3 consecutive successful Netlify deploys (target app(s))
- Zero recurrence of top D1 auth/registry signatures during burn-in
- Governance counters/status reconciled

**Closure:** D-STREAM-1 moves to DONE only when Netlify reliability gate is satisfied.

---

## S-STREAM-R1 — Security/Foundation Recovery

**Repos:** bolt-daemon (primary), localbolt-v3, localbolt, localbolt-app (product crypto-path convergence + security test lift), bolt-core-sdk (coordinated interface/doc updates only if required), bolt-ecosystem (governance)
**Goal:** Resolve foundational security and runtime risks before further UX work. Priority: daemon identity/ephemeral key architecture, product crypto-path convergence, and security-critical integration coverage.
**Status:** **DONE** (S-STREAM-R1 CLOSED — ecosystem-v0.1.69-s-stream-r1-closeout)
**Codified:** ecosystem-v0.1.65-s-stream-r1-codify (2026-03-06)
**R1-1:** ecosystem-v0.1.67-s-stream-r1-r1.1-disposition (2026-03-06)
**Authority:** PM-approved. Phase execution requires separate phase prompts.

### Background

A revised deep assessment highlights higher-priority foundation risks that must be resolved before further UX work:

1. **Daemon identity/ephemeral key architecture risk** — new evidence to be assessed during R1-0. SA1 (DONE-VERIFIED) addressed identity/ephemeral separation with 12 tests, but revised assessment suggests deeper architecture review may be warranted.
2. **Incomplete product crypto-path convergence** — product repos may contain direct tweetnacl operations in product-layer orchestration code rather than calling SDK-exposed crypto/session APIs.
3. **Product integration coverage gaps** — security-critical flows (key/identity handling, handshake transitions, crypto-path integrity under reconnect/race/security edges) lack targeted test coverage across product repos.

### SA1 Handling Rule

**SA1** (`Daemon conflates identity and ephemeral into single per-connection keypair`) is currently **DONE-VERIFIED** with evidence (Phase A: `daemon-v0.2.14`, Phase B: `daemon-v0.2.15`, 12 separation tests).

During S-STREAM-R1 execution, if new evidence confirms a daemon key-architecture risk beyond SA1's original scope:

- **Path A (new finding):** Register a new finding ID (R1-series, e.g. `R1-F1`) with its own severity, evidence, and resolution. SA1 status remains DONE-VERIFIED. This is the preferred path if the new evidence describes a distinct risk not covered by SA1's original scope.
- **Path B (explicit reopen):** Reopen SA1 with documented new evidence and a status transition rationale entry (e.g. `DONE-VERIFIED → REOPENED: <rationale with evidence hash>`). This path is appropriate only if the new evidence directly contradicts SA1's closure evidence.

**Rule:** The choice between Path A and Path B MUST be made during R1-1 (architecture decision) with explicit evidence. Codification does not pre-decide the path. Whichever path is chosen, it MUST be recorded in `docs/AUDIT_TRACKER.md` with the decision rationale before any R1-2 implementation begins.

### R1-1 Disposition Decisions (2026-03-06)

**D1 — SA1 Disposition: Path C (SA1 closure stands)**

R1-0 evidence confirms SA1 separation is complete. No new daemon key-role risk found. No new finding registered. No SA1 reopen.

Evidence:
- STATE.md R1-0 §"Daemon Key-Role Finding": Identity keypair persistent (`~/.bolt/identity.key`), TOFU-only. Ephemeral keypair per-session, crypto-only.
- 22 SA1 tests (12 separation + 10 additional). `[SA1]` log markers confirm separation at runtime.
- No ambiguous or mixed-role key usage found in daemon codebase (`identity.rs`, `rendezvous.rs`, `web_hello.rs`).
- SA1 DONE-VERIFIED evidence (Phase A: `daemon-v0.2.14`, Phase B: `daemon-v0.2.15`) is not contradicted.

**D2 — R1-2 Disposition: DONE-NO-ACTION**

No unresolved daemon architecture risk remains. SA1 key-role separation is verified complete. No daemon remediation needed.

Evidence:
- D1 Path C confirms no daemon key-architecture gap beyond SA1's resolved scope.
- R1-0 daemon key-role inventory found zero ambiguous usage across `identity.rs`, `rendezvous.rs`, `web_hello.rs`, `web_dc_v1.rs`.
- Daemon test baseline (318/398) is healthy. No regressions to address.

**D3 — R1-3 Disposition: DONE-NO-ACTION**

All three product repos already use SDK-mediated crypto exclusively. No crypto-path convergence work needed.

Evidence:
- R1-0 product crypto-path inventory: zero direct `tweetnacl`/`nacl` calls in product-layer code across localbolt, localbolt-app, localbolt-v3.
- Identity: `getOrCreateIdentity()` from `@the9ines/bolt-transport-web`.
- Crypto: all envelope/handshake operations via `WebRTCService`.
- Session: `@the9ines/localbolt-core` for state machine + verification bus.
- Convergence was already achieved by C-stream (C2–C5) and SDK publish (M3).

**D4 — R1-4 Scope Lock: CONFIRMED as primary remaining scope**

R1-4 is the sole remaining execution scope in S-STREAM-R1. Security test-lift targets per product repo:

| Repo | Gap Severity | Target Categories | R1-0 Evidence |
|------|-------------|-------------------|---------------|
| localbolt | HIGH | Handshake security transitions (A), key/identity handling (B), session state under security edges (C), crypto-path integration (D) | 300 tests, 0 security — STATE.md R1-0 §"Security Test Gap Summary" |
| localbolt-app | HIGH | All categories (A, B, C, D) — smoketest-only baseline | 11 tests (1 smoke + 10 TOFU) — STATE.md R1-0 §"Security Test Gap Summary" |
| localbolt-v3 | MEDIUM (if material gaps remain) | Crypto-path integration (D), cross-session key isolation (C+D) | 43 core + 59 web tests; may already have adequate coverage from C7/H5-v3 — verify in R1-4 |

R1-4 scope boundary: security/crypto path verification only (per S-STREAM-R1 overlap boundary with C-stream). MUST NOT duplicate C7 session race-hardening tests.

### Non-Negotiable Guardrails

1. Preserve protocol compatibility unless explicitly gated by governance.
2. Do NOT modify subtree-managed paths directly (`signal/` in localbolt, localbolt-app).
3. Security changes must be fail-closed and adversarially tested.
4. No `Co-Authored-By` trailers in commits.
5. No protocol semantic, wire-format, or cryptographic changes unless a phase explicitly authorizes it with PM approval.

### Execution Baseline Anchors (to be recorded in R1-0)

| Repo | Metric | Baseline |
|------|--------|----------|
| bolt-daemon | `cargo test` (default) | 318 |
| bolt-daemon | `cargo test --features test-support` | 398 + 3 ignored |
| localbolt | npm test | TBD (record in R1-0) |
| localbolt-app | npm test | TBD (record in R1-0) |
| localbolt-v3 (core) | npm test | TBD (record in R1-0) |
| localbolt-v3 (web) | npm test | TBD (record in R1-0) |
| bolt-core-sdk (TS) | npm test | TBD (record in R1-0) |
| bolt-core-sdk (Rust) | cargo test | TBD (record in R1-0) |

### S-STREAM-R1 Phase Table

| Phase | Description | Status | Dependencies | Acceptance Criteria |
|-------|-------------|--------|-------------|---------------------|
| R1-0 | Baseline evidence + risk classification | **DONE** | None | Daemon key-role inventory, product crypto call path inventory, security test coverage gap inventory, risk-ranked baseline matrix with per-repo test baselines recorded |
| R1-1 | Architecture decision (evidence-informed) | **DONE** | R1-0 | SA1 Path C confirmed (closure stands). R1-2 DONE-NO-ACTION. R1-3 DONE-NO-ACTION. R1-4 locked as primary remaining scope. |
| R1-2 | Daemon remediation + security tests | **DONE-NO-ACTION** | R1-1 | No unresolved daemon architecture risk. SA1 separation verified complete by R1-0 evidence. No remediation needed. |
| R1-3 | Product crypto-path convergence | **DONE-NO-ACTION** | R1-1 | All 3 products already use SDK-mediated crypto exclusively. Zero direct tweetnacl calls. No migrations needed. |
| R1-4 | Security-focused product test lift | **DONE** | R1-1 (R1-3 DONE-NO-ACTION) | All R1-0 HIGH/MEDIUM gaps covered: localbolt 300→319, localbolt-app 11→32, v3-core 43→50. Tests-only, no runtime changes. Tags: `localbolt-v1.0.27-...`, `localbolt-app-v1.2.10-...`, `v3.0.79-...`. Full evidence in STATE.md R1-4 section. |
| R1-5 | Validation gates | **DONE** | R1-4 | All 9 gates PASS: 460 tests, 0 failures. Tests-only verification confirmed. All 7 tags on origin. No D-stream regression. |
| R1-6 | Governance reconciliation + closure | **DONE** | R1-5 | Counters unchanged (110/90/0/0). STATE.md, GOVERNANCE_WORKSTREAMS.md, ROADMAP.md, CHANGELOG.md updated. S-STREAM-R1 CLOSED. |

### Dependency Map

```
R1-0 (baseline evidence) ✓ DONE
 |
 └── R1-1 (dispositions locked) ✓ DONE
      |
      ├── R1-2 (daemon remediation) ✓ DONE-NO-ACTION
      ├── R1-3 (product crypto converge) ✓ DONE-NO-ACTION
      |
      └── R1-4 (security-focused product test lift) ✓ DONE
           |
           └── R1-5 (validation gates) ✓ DONE
                |
                └── R1-6 (governance reconciliation + closure) ✓ DONE
```

### Parallelization

- R1-2 and R1-3 closed as DONE-NO-ACTION (R1-1 disposition).
- R1-4 is the primary remaining execution scope. Unblocked by R1-1.
- R1-5 depends on R1-4 only (R1-2/R1-3 are resolved).
- R1-6 is strictly sequential after R1-5.

### Overlap Boundary with C-STREAM

- S-STREAM-R1 R1-4 scope is **security/crypto path verification only**: key/identity handling, handshake security transitions, crypto-path integrity under reconnect/race/security edges.
- General UX/state scenario expansion and session regression tests belong to C-STREAM (if/when a C-STREAM-R1 is executed).
- R1-4 MUST NOT duplicate C7 session race-hardening tests. If overlap is discovered, R1-4 defers to C7 evidence.

### Finding Registration Rule

- Findings may be registered during R1-0 (inventory), R1-2 (daemon implementation), R1-3 (product convergence), or R1-4 (test lift) when evidence is confirmed.
- Each finding receives a unique ID in the R1-F series (e.g. `R1-F1`, `R1-F2`, ...).
- SA1 handling follows the SA1 Handling Rule above (Path A or Path B, decided in R1-1).
- Final arithmetic reconciliation occurs once in R1-6.

---

## C-STREAM-R1 — UI/State Regression Recovery

**Repo:** localbolt-v3 (localbolt-core + localbolt-web)
**Status:** DONE (`v3.0.80-c-stream-r1-ui-state-fix`, `9f3546e`)
**Scope:** Fix UX/state regressions — pause/stop transfer controls, disconnect/reconnect stale state, trust/verification UI consistency.
**Boundary:** No D-stream infra/auth/deploy paths touched.

**Bugs addressed:**
1. `handleReceiveProgress` / `handleConnectionStateChange` / `handleVerificationState` lack generation guards — late callbacks from previous sessions pollute current session state.
2. `handleConnectionStateChange` resets on intermediate WebRTC states ('new', 'connecting'), not just terminal states.
3. `snapshot()` hardcodes `verificationState: 'legacy'` instead of reading from verification bus.
4. `disconnect()` not idempotent.
5. No transfer terminal flag — late progress callbacks after cancel re-show stale UI.

**Policy lock (explicit truth table):**
- `verified + connected` → allowed
- `legacy + connected` → allowed
- `unverified + connected` → blocked
- `mismatch + connected` → blocked (fail-closed)
- `any + disconnected` → blocked

---

## Workstream N — Native App + Daemon Bundling (N-STREAM-1)

**Repos:** localbolt-app (primary), bolt-ecosystem (governance). Future: bytebolt-app (as approved).
**Goal:** Define how native apps bundle and lifecycle-manage bolt-daemon so they operate as one product safely and predictably.
**Status:** N0–N6 DONE, A0 DONE, N7 DONE (CLOSED)
**Codified:** ecosystem-v0.1.72-n-stream-1-codify (2026-03-07)
**N0 locked:** ecosystem-v0.1.73-n-stream-1-n0-policy-lock (2026-03-07)
**N1+N2 locked:** ecosystem-v0.1.74-n-stream-1-n1-n2-lock (2026-03-07)
**N3 locked:** ecosystem-v0.1.75-n-stream-1-n3-supervision (2026-03-07)
**Authority:** PM-approved. Phase execution requires separate phase prompts.

### Ownership Boundary: N-STREAM-1 vs B-STREAM

**N-STREAM-1 owns:** App bundling, process lifecycle, packaging, supervision, operator UX for daemon integration, IPC contract stabilization (consumer side), rollout/migration strategy, acceptance harness for bundling/lifecycle.

**B-STREAM owns:** Daemon protocol/runtime implementation, transfer state machine, event loop, wire format, capability negotiation, cryptographic operations, IPC API definition (provider side). B-STREAM is the logical label for daemon protocol/runtime implementation work encompassing H4 (panic elimination), H5 (downgrade resistance), B1-B6 (transfer convergence), and D-E2E (cross-stack integration). B-STREAM is not separately codified as a full stream in this pass — its phases are governed under the existing B-stream sections of this document and the H-phase ledger.

**Boundary rule:** N-STREAM-1 consumes the daemon API/runtime surface as defined by B-STREAM. N-STREAM-1 MUST NOT redefine daemon protocol behavior. If N-STREAM-1 requires daemon-side changes (e.g., new IPC endpoints, health check surface), those changes MUST be proposed to B-STREAM governance and executed under B-STREAM phase discipline.

### Product Scope

- **In scope:** `localbolt-app` (native Tauri v2 app — primary daemon bundling target)
- **Future in scope (requires approval):** `bytebolt-app` (commercial native app)
- **Out of scope:** `localbolt` (web app — daemon bundling requires separate architecture governance approval)
- **Out of scope:** `localbolt-v3` (architecture explicitly prohibits bundling native binaries/daemons per ARCHITECTURE.md §6)

### Daemon Maturity Dependency

N-STREAM-1 depends on B-STREAM maturity for its IPC and lifecycle surface:

- N2 (IPC contract) MUST stabilize only the currently available daemon API surface. The daemon IPC API (`src/ipc/`) and runtime surface as of B-STREAM-1 completion (B1-B6, D-E2E) constitute the baseline.
- Extension clauses for future B-STREAM phases are permitted: N2 MAY define forward-compatible IPC versioning that accommodates future daemon capabilities without breaking existing contracts.
- N-STREAM-1 MUST NOT assume unfinished daemon features (e.g., remaining B3 pause/resume, disk writes, concurrent transfers) are complete. Phases that depend on not-yet-delivered daemon features MUST declare explicit B-STREAM blockers.

### ARCH-08 Gate

Any N-stream phase requiring new top-level folders under workspace root MUST resolve ARCH-08 disposition first (per ARCH-08 invariant: "No new top-level folders under workspace root"). This follows the C1 precedent (Option 2: non-violating location).

### N-STREAM-1 Phase Table

| Phase | Description | Status | Dependencies | Acceptance Criteria |
|-------|-------------|--------|-------------|---------------------|
| N0 | Policy lock | **DONE** | None | All 8 policy decisions locked (D0.1–D0.8). See N0 Decision Record below. |
| N1 | Packaging + security matrix | **DONE** | N0 | Per-platform matrix locked (macOS/Windows/Linux). See N1 Specification below. |
| N2 | IPC contract stabilization | **DONE** (spec locked; all implementation dependencies **RESOLVED**) | N0 | IPC contract baseline locked (5 stable + 2 provisional messages). All B-DEPs resolved: B-DEP-N2-1/2 (`daemon-v0.2.31`), B-DEP-N2-3 (`daemon-v0.2.33` + `localbolt-app-v1.2.13`). See N2 Specification below. |
| N3 | Process supervision + diagnostics | **DONE** (spec locked; B-DEP-N2-1/N2-2 **RESOLVED**) | N2 | Watchdog state machine (5 states), retry/backoff (1s/3s/10s, 3 max), stale cleanup algorithm, stderr capture + support bundle, user-visible status transitions. See N3 Specification below. |
| N4 | Rollout + migration | **DONE** | N1, N2 | Stage-gate spec locked (local/dev, alpha, beta, GA). Version-skew policy, update/rollback model, migration strategy, blocker-aware gating. 7 acceptance checks. See N4 Specification below. |
| N5 | Acceptance harness | **DONE** | N2, N3 | Acceptance harness spec locked. 8 test domains, 4 tiers (smoke/integration/failure-injection/pre-release), 44 checks (37 from N1–N3 + 7 new N4), blocker-aware execution rules, evidence contract. See N5 Specification below. |
| N6 | Execution + hardening | **DONE** | N4, N5 | N6-A1 sidecar lifecycle (`localbolt-app-v1.2.11`), N6-A2 IPC bridge + frontend gating (`localbolt-app-v1.2.12`), N6-B3 GA wiring + support bundle + cross-platform IPC (`localbolt-app-v1.2.13-n6b3-ga-wiring`). All B-DEPs resolved. 118 tests (66 Rust + 52 web). Windows runtime validation: R17. |
| N7 | Closure | **DONE** | N6 | Closure gate passed (C1–C5 PASS). Phase ledger finalized. Residual R17 (Windows runtime) tracked with owner/next action. D2 observability deferred to N8/B-stream. Stream status: CLOSED. Tag: `ecosystem-v0.1.82-n-stream-1-n7-closure`. |
| A0 | Signaling ownership evaluation (governance-only) | **DONE** | N6 | Option A (status quo) approved. D2 observability deferred to N8/B-stream. See A0 Decision Record below. |
| N8 | D2 signal observability (post-closure follow-on) | **DONE** | N7, A0 | Signal health probe + unified status indicator. AC-SE-06/07 realized (architecture-neutral). No ownership change, no daemon code, no subtree modification. Tag: `localbolt-app-v1.2.14-n8-signal-observability`. See N8 Record below. |

### N-STREAM-1-SIGNAL-EVAL / A0 — Signaling Ownership Decision Record

**Status:** DONE
**Tag:** `ecosystem-v0.1.81-signal-eval-a0-decision`
**Date:** 2026-03-07
**Approved by:** PM (explicit approval)

#### Context

Governance-only evaluation of signaling runtime ownership for native app flows. Assessed whether signaling server ownership should remain as-is, move to daemon, or route to cross-stream convergence.

#### Audit Findings (Read-Only)

1. **localbolt-app** embeds bolt-rendezvous as an in-process signaling server (`src-tauri/src/lib.rs:19–45`). Runs on `0.0.0.0:3001` on every app launch. Not dev-only — production runtime component. Features dependent: peer discovery, connection approval, SDP/ICE relay, status indicator.
2. **bolt-daemon** has zero signaling server capability. In rendezvous mode, it connects as a WebSocket client to an external bolt-rendezvous server. IPC layer handles pairing/transfer decisions only.
3. **bolt-rendezvous** is dual-mode (binary + embeddable library). Public API: `SignalingServer::new(addr).run()`. Explicitly designed for Tauri embedding. Missing: graceful shutdown hook.
4. **Daemon and signaling are independent failure domains.** Signal server failure does not affect IPC. Daemon crash does not affect peer discovery.

#### Decision: Option A — Status Quo Coexistence

**Approved.** Current architecture preserved:
- App owns embedded signaling server (bolt-rendezvous via `signal/` subtree, port 3001).
- Daemon owns IPC decisions (pairing, transfer approval, status).
- No ownership change. No signaling responsibility added to daemon.

**Rationale:**
1. Current architecture is deployed and validated (N6 complete, 118 tests).
2. Daemon has zero signaling capability — Options B/D1 require substantial new infrastructure.
3. Separation is a strength: independent failure domains for signaling and IPC.
4. Options B/D1 require 7–9 locked-decision amendments and violate guardrail 13.

#### Rejected Options

- **Option B (daemon-only signaling):** Requires 9 locked-decision amendments including D0.1, D0.2, D0.8, guardrail 13, N1, N2, N3, N5, ARCHITECTURE.md §5. Couples signaling availability to daemon health.
- **Option C (S0/cross-stream convergence):** Adds governance overhead without demonstrated need. S0 already resolved signal implementation convergence.
- **Option D1 (daemon spawns signal process):** Requires 7 amendments. Introduces three-level process supervision (app→daemon→signal). N3 watchdog not designed for nested supervision.

#### D2 Observability Follow-On (Deferred)

Signal health monitoring via daemon (read-only `signal.status` IPC event) deferred:
- **Route to N8** if daemon IPC changes are minor (new provisional message type).
- **Route to B-stream** if daemon changes are substantial (new runtime responsibility).
- AC-SE-06 and AC-SE-07 deferred to D2 follow-on phase.

#### Approved Acceptance Criteria

| ID | Criterion | Status |
|----|-----------|--------|
| AC-SE-01 | Signal server starts on every app launch before UI bootstrap | Approved |
| AC-SE-02 | Signal server binds 0.0.0.0:3001 and accepts LAN WebSocket connections | Approved |
| AC-SE-03 | Daemon startup and signal server startup do not conflict | Approved |
| AC-SE-04 | Daemon IPC does not depend on signal server availability | Approved |
| AC-SE-05 | Signal server failure does not trigger daemon watchdog restart | Approved |
| AC-SE-06 | (D2) Signal health is measured by runtime owner and surfaced | **DONE** (N8, architecture-neutral: app probes, not daemon — per Option A) |
| AC-SE-07 | (D2) App aggregates daemon + signal status into unified indicator | **DONE** (N8, `localbolt-app-v1.2.14-n8-signal-observability`) |
| AC-SE-08 | All existing N5 acceptance checks pass without modification | Approved |
| AC-SE-09 | signal/ subtree remains read-only | Approved |
| AC-SE-10 | Rollback possible by reverting single commit per repo | Approved |

#### Residuals

- **R17** (Windows runtime validation): **CLOSED** (2026-03-08). Windows CI provisioned, daemon + app IPC validated on `windows-latest`. Tags: `daemon-v0.2.34-r17-windows-validated`, `localbolt-app-v1.2.15-r17-windows-validated`.
- **OQ-2** (graceful shutdown): bolt-rendezvous `run()` blocks forever. Track as upstream enhancement.
- **OQ-5** (B-stream authority): B-stream may independently route signaling ownership changes under its own governance. This A0 decision covers N-stream scope only.

#### Locked-Decision Impact

**None.** Option A preserves all N0–N6 decisions as-is. No amendments required.

### N7 — Closure (Evidence Package)

**Status:** DONE
**Tag:** `ecosystem-v0.1.82-n-stream-1-n7-closure`
**Date:** 2026-03-07
**Stream Status:** N-STREAM-1 **CLOSED**

#### Baseline Verification (P1)

All required historical anchors verified reachable on origin:

| Anchor | Type | Verified |
|--------|------|:--------:|
| `ecosystem-v0.1.80-n-stream-1-n6-complete` (`83be65a`) | Tag (origin) | PASS |
| `cfaa526` (N6 governance errata) | Commit | PASS |
| `ecosystem-v0.1.81-signal-eval-a0-decision` (`f6b9125`) | Tag (origin) | PASS |
| `localbolt-app-v1.2.11-n6a-sidecar-lifecycle` (`0c218bb`) | Tag (origin) | PASS |
| `localbolt-app-v1.2.12-n6a2-ipc-ui-gating` (`8f4aea9`) | Tag (origin) | PASS |
| `localbolt-app-v1.2.13-n6b3-ga-wiring` (`88954c8`) | Tag (origin) | PASS |
| `daemon-v0.2.31-bdep-n2-ipc-unblock` (`a6b174e`) | Tag (origin) | PASS |
| `daemon-v0.2.32-n6b1-path-flags` (`80fb0af`) | Tag (origin) | PASS |
| `daemon-v0.2.33-n6b2-windows-pipe` (`b8c1f3c`) | Tag (origin) | PASS |

#### Closure Criteria Assessment (P2)

| ID | Criterion | Result | Evidence |
|----|-----------|--------|----------|
| C1 | Phase completion integrity | **PASS** | N0–N6 all DONE with tag anchors. A0 decision locked and routed (D2 → N8/B-stream). No contradictory statuses. |
| C2 | Acceptance harness closure integrity | **PASS** | N5 matrix: 44 total checks across 4 tiers. N6 execution evidence: 118 tests (66 Rust + 52 web) across N6-A1/A2/B3. Aggregate test evidence format accepted as policy-valid — traceable to N5 domains D1–D8. 9 previously-blocked checks (B-DEP-N2-1/N2-2/N1-1/N2-3) all unblocked by daemon tags `v0.2.31`–`v0.2.33` and app tag `v1.2.13`. |
| C3 | Dependency and blocker closure integrity | **PASS** | All 4 B-DEPs RESOLVED with tag evidence. No residual blockers. R17 (Windows runtime) is residual risk, not a blocker — code is compile-validated, runtime untested. |
| C4 | Residual risk handling | **PASS** | R17 OPEN (Low severity). Owner: N-STREAM / B-STREAM. Next action: Windows CI runner or manual Windows runtime validation pass. No other untracked residuals. |
| C5 | Release/readiness narrative integrity | **PASS** | Stream outcome documented: localbolt-app ships bundled daemon with full supervision. Limits: Windows runtime unvalidated (R17), code signing not yet procured (GA gate). Deferred: D2 observability (AC-SE-06/07) routed to N8/B-stream. No scope creep. |

**Decision: N7 DONE. N-STREAM-1 CLOSED.**

#### Final Phase Ledger (N0–N7)

| Phase | Status | Anchor |
|-------|--------|--------|
| N0 | **DONE** | `ecosystem-v0.1.73-n-stream-1-n0-policy-lock` |
| N1 | **DONE** | `ecosystem-v0.1.74-n-stream-1-n1-n2-lock` |
| N2 | **DONE** | `ecosystem-v0.1.74-n-stream-1-n1-n2-lock` |
| N3 | **DONE** | `ecosystem-v0.1.75-n-stream-1-n3-supervision` |
| N4 | **DONE** | `ecosystem-v0.1.76-n-stream-1-n4-n5-lock` |
| N5 | **DONE** | `ecosystem-v0.1.76-n-stream-1-n4-n5-lock` |
| N6 | **DONE** | `ecosystem-v0.1.80-n-stream-1-n6-complete` |
| A0 | **DONE** | `ecosystem-v0.1.81-signal-eval-a0-decision` |
| N7 | **DONE** | `ecosystem-v0.1.82-n-stream-1-n7-closure` |

#### Acceptance Summary Rollup

| Metric | Count |
|--------|------:|
| Total N5 checks specified | 44 |
| Checks unblocked and executable | 44 (all B-DEPs resolved) |
| N6 aggregate test evidence | 118 tests (66 Rust + 52 web) |
| N6 sub-phases | 3 (N6-A1, N6-A2, N6-B3) |
| Previously-blocked checks (B-DEP) | 9 (all unblocked) |
| Tier 4 (Pre-Release, GA-only) | 2 (deferred to GA — code signing not procured) |

**Non-pass rationale:** Tier 4 checks (AC-N1-10 macOS signing, AC-N1-11 Windows signing) are GA-only gates — not required for stream closure, required before GA release. No checks in FAIL status.

#### Blocker/Risk Final Map

**B-DEP Final State:**

| ID | Description | Status | Resolution Evidence |
|----|-------------|--------|---------------------|
| B-DEP-N1-1 | Platform path CLI flags | **RESOLVED** | `daemon-v0.2.32-n6b1-path-flags` (`80fb0af`) |
| B-DEP-N2-1 | `daemon.status` in default mode | **RESOLVED** | `daemon-v0.2.31-bdep-n2-ipc-unblock` (`1ad2db8`) |
| B-DEP-N2-2 | Version handshake messages | **RESOLVED** | `daemon-v0.2.31-bdep-n2-ipc-unblock` (`1ad2db8`) |
| B-DEP-N2-3 | Windows named pipe support | **RESOLVED** | `daemon-v0.2.33-n6b2-windows-pipe` (`b8c1f3c`) |

**Residual Risks:**

| ID | Risk | Severity | Status | Owner | Next Action |
|----|------|----------|--------|-------|-------------|
| R17 | Windows runtime validation — named pipe IPC on Windows | Low | **CLOSED** | N-STREAM / B-STREAM | R17 closed 2026-03-08: Windows CI provisioned (`windows-latest`), daemon and app IPC code validated on real Windows runtime. Critical checks A1–A5 (daemon compilation/clippy/tests) all PASS: CI `22816178593`, 362+429 tests, 0 failures. B6–B8 (app IPC transport compilation/clippy, named pipe path detection) all PASS: CI `22814949072` Tauri clippy step. Out-of-scope failures: Tauri test binary crash (WebView2 DLL, not IPC), signal subtree clippy (read-only), web coverage threshold (instrumentation, not IPC). Full evidence matrix in CHANGELOG.md. Tags: `daemon-v0.2.34-r17-windows-validated` (`82d0f83`), `localbolt-app-v1.2.15-r17-windows-validated` (`7116d12`). |
| OQ-2 | bolt-rendezvous `run()` blocks forever (no graceful shutdown hook) | Low | **OPEN** | bolt-rendezvous upstream | Track as upstream enhancement; non-blocking for N-STREAM-1 |

#### Decision Continuity

- **A0 Option A retained:** App owns embedded signaling server. Daemon owns IPC decisions only. No amendments to N0–N6 decisions.
- **D2 observability deferred:** AC-SE-06 (daemon polls signal health) and AC-SE-07 (unified status indicator) routed to N8 (if minor daemon IPC change) or B-stream (if substantial). Not mixed into N7 closure.
- **D2 observability delivered (N8):** AC-SE-06/07 realized via N8 post-closure follow-on. App-side probe architecture (Path 1). Zero daemon changes. See N8 record below.

### N8 — D2 Signal Observability (Post-Closure Follow-On)

**Status:** DONE
**Tag:** `localbolt-app-v1.2.14-n8-signal-observability` (`a7e4f8b`)
**Ecosystem Tag:** `ecosystem-v0.1.83-n-stream-1-n8-observability`
**Date:** 2026-03-07
**Stream Semantics:** Option C — standalone lineage-linked follow-on. N-STREAM-1 remains CLOSED; N8 executes as post-closure item authorized by A0 D2 deferral clause.

#### Context

A0 decision deferred D2 observability (AC-SE-06/07) with routing criteria:
- Route to N8 if daemon impact is minor.
- Route to B-stream if daemon impact is substantial.

#### Routing Decision: N8 (Zero Daemon Impact)

Under Option A, the app owns the signal server. The daemon has no signal server relationship. Adding daemon-side signal polling would violate AC-SE-04 ("Daemon IPC does not depend on signal server availability"). Therefore:
- **Daemon repo: NOT TOUCHED.** Zero lines changed.
- **Architecture: Path 1** — app-side TCP health probe + app-emitted unified status.
- AC-SE-06 reworded to architecture-neutral: "Signal health is measured by the signaling runtime owner (the app) and surfaced to the user."

#### Implementation Summary

1. **Signal monitor** (`signal_monitor.rs`): TCP connect probe to `127.0.0.1:3001`, 5s interval, 2s timeout, 4-state machine (unknown → active → degraded → offline), 3-failure offline threshold. Shutdown-aware via shared `AtomicBool` flag — probe transitions suppressed during SIGTERM grace window (N3-W4/OQ-2 interaction).
2. **Unified status** (`header.ts`): Three indicators — unified health (HEALTHY/SIG DEGRADED/SIG OFFLINE), individual daemon dot, individual signal dot. Daemon non-ready states dominate unified display.
3. **Frontend subscription** (`daemon.ts`): `signal://status` event listener + `get_signal_status` initial probe. `SignalStatus` type added to `DaemonState`.
4. **Support bundle**: `signal_status` field and manifest section added.
5. **No transfer gating changes.** Observability only — per PM approval.

#### Acceptance Results

| ID | Criterion | Result | Evidence |
|----|-----------|--------|----------|
| AC-SE-06 (realized) | Signal health measured and surfaced | **PASS** | App-side TCP probe, `signal://status` events, header indicator |
| AC-SE-07 (realized) | Unified indicator reflects daemon + signal state | **PASS** | `computeUnifiedStatus()` aggregation, 8 unit tests |
| N6 regression | Existing tests pass unchanged | **PASS** | 66/66 Rust, 52/52 web (N6 baseline intact) |
| Option A guardrail | App remains signaling runtime owner | **PASS** | Daemon repo untouched, no ownership change |
| Subtree guardrail | `signal/` diff empty | **PASS** | `git diff HEAD -- signal/` = 0 lines |

#### Test Evidence

| Surface | Baseline (N6) | After N8 | Delta | Regressions |
|---------|:------------:|:--------:|:-----:|:-----------:|
| Rust | 66 | 82 | +16 | 0 |
| Web | 52 | 64 | +12 | 0 |
| **Total** | **118** | **146** | **+28** | **0** |

#### Residuals

- **R17** (Windows runtime): **CLOSED**, Low. Closed 2026-03-08 — Windows CI provisioned (`windows-latest`), daemon + app IPC code validated on real Windows runtime. Daemon `daemon-v0.2.34-r17-windows-validated`, app `localbolt-app-v1.2.15-r17-windows-validated`.
- **OQ-2** (graceful shutdown): Unchanged. Open, Low. N8 signal monitor handles OQ-2 interaction by checking shutdown flag before state transitions.

### Dependency Map

```
N0 (policy lock) ← gates all
 |
 ├── N1 (packaging + security matrix)
 |    |
 |    └──────────┐
 |               |
 ├── N2 (IPC contract stabilization)
 |    |          |
 |    ├── N3 (process supervision + diagnostics)
 |    |    |    |
 |    |    └────┤
 |    |         |
 |    └─── N4 (rollout + migration)
 |               |
 N5 (acceptance harness) ← depends on N2 + N3
      |
      └── N6 (execution + hardening) ← depends on N4 + N5
           |
           └── N7 (closure)
```

### Parallelization

- N1 and N2 can begin in parallel after N0.
- N3 depends on N2 (needs finalized IPC health/status semantics).
- N4 depends on N1 + N2 (needs packaging model + IPC contract).
- N5 depends on N2 + N3 (needs IPC contract + supervision surface).
- N6 depends on N4 + N5 (needs rollout plan + acceptance harness).
- N7 is strictly sequential after N6.

### AUDIT Finding Reservation

Finding series `N1-F*` is reserved for findings discovered during N-STREAM-1 execution. No speculative findings are registered at codification time. Findings will be registered in `docs/AUDIT_TRACKER.md` when evidence is confirmed during phase execution.

### N0 — Policy Lock (Decision Record)

**Status:** DONE
**Tag:** `ecosystem-v0.1.73-n-stream-1-n0-policy-lock`
**Date:** 2026-03-07
**Approved by:** PM (explicit approval)

#### D0.1 — Lifecycle Ownership

**Decision:** App-managed daemon lifecycle.

The daemon is a product-internal component, not a system service. Tauri v2 natively supports sidecar binaries with spawn/kill lifecycle tied to the app process. Users do not install or manage a system service. App-managed keeps the product self-contained.

**Rejected:** Service-managed (launchd/systemd/Windows Service) — appropriate for headless/server deployments but not for a desktop file transfer app. Adds installation complexity and elevated permission requirements.

**Platform implications:**
- macOS: sidecar in `.app` bundle, no launchd plist.
- Windows: sidecar in install directory, no Windows Service registration.
- Linux: sidecar alongside AppImage/deb binary, no systemd unit.

#### D0.2 — Startup Behavior

**Decision:** On app launch, synchronous — daemon spawned during app initialization, before transfer UI is enabled.

**Rejected:** Login-item auto-start (unnecessary system integration complexity for on-demand file transfer); on-demand/lazy start (adds latency to first transfer, complicates readiness state).

**Readiness criteria:** Daemon emits `daemon.status` IPC event. App considers daemon ready when first `daemon.status` is received via IPC socket.

**Timeout:** 10 seconds. If daemon does not emit `daemon.status` within 10s of spawn, app enters degraded mode: transfer UI disabled, status indicator shows "Daemon unavailable", retry button offered.

**Failed-start UX:** Non-blocking status message ("Connection service unavailable"). Manual retry via UI button. No auto-retry on initial startup failure (avoids boot loops).

#### D0.3 — Shutdown Behavior

**Decision:** On app exit — daemon is terminated when the app process exits (SIGTERM, then SIGKILL after grace period).

**Rejected:** Inactivity-based shutdown (unnecessary complexity; daemon is lightweight); never auto-stop (orphaned daemon processes on app crash).

**Active transfer during shutdown:** App MUST warn user if a transfer is in progress before initiating shutdown. If user confirms, app sends SIGTERM to daemon. Daemon has 5-second grace period to complete or abort active transfer before SIGKILL. Transfer state is not preserved across shutdown — interrupted transfers are lost (consistent with current web app behavior).

**Forced-stop:** SIGKILL after 5-second grace period following SIGTERM. No negotiation.

#### D0.4 — Restart Strategy

**Decision:** Automatic restart with exponential backoff, max 3 retries.

**Rejected:** No automatic restart (poor UX for transient failures); unlimited retries (resource waste, masks persistent failures); fixed-interval restart (no backoff amplifies failure).

**Backoff schedule:** 1s, 3s, 10s (3 attempts). Retry counter resets after 60 seconds of successful operation.

**Degraded mode (after 3 failures):** Transfer UI disabled. Status shows "Connection service stopped — restart required". Manual restart button. App remains functional for non-transfer features.

**User-visible status transitions:** `starting` -> `ready` -> (crash) -> `restarting (1/3)` -> `ready` OR `restarting (2/3)` -> ... -> `degraded`

#### D0.5 — Single-Instance Policy

**Decision:** Per-user, single daemon instance — enforced via lockfile at daemon socket path.

**Rejected:** Per-machine (requires elevated permissions, conflicts across users); per-app-window (unnecessary complexity, IPC designed for single-client).

**Lockfile model:** Socket file at platform-appropriate runtime directory: `$XDG_RUNTIME_DIR/bolt-daemon.sock` (Linux), `$TMPDIR/bolt-daemon.sock` (macOS), `%LOCALAPPDATA%\bolt-daemon\bolt-daemon.sock` (Windows). Stale socket detection via connect-probe before spawn.

**Second app instance:** If a second app instance starts: probe existing socket. If daemon is responsive, second app connects as IPC client. Current daemon behavior is kick-on-reconnect (new client replaces old). This client-replacement behavior may be revised in N2 if multi-client IPC policy changes, but N0 locks single-daemon-per-user regardless. If socket exists but daemon is unresponsive, clean up stale socket and spawn new daemon.

#### D0.6 — Crash Recovery

**Decision:** Reset transient state, preserve persistent state.

**Rejected:** Full state reset (loses identity key, TOFU pins — unacceptable); full state recovery (complex, transfer state is inherently transient and cannot be recovered).

**Recovered (persistent):** Identity keypair (`~/.bolt/identity.key`), TOFU pin store, configuration.

**Reset (transient):** Active transfers, WebRTC sessions, IPC client connections, in-memory buffers.

**Stale cleanup:** On startup, daemon removes stale socket file if it exists (already implemented in `IpcServer::start`). App-side: if daemon process is dead but socket exists, remove socket before respawn. PID file at `$RUNTIME_DIR/bolt-daemon.pid` for reliable stale-process detection.

**Logging:** Daemon stderr captured by app process. Crash events logged with `[DAEMON_CRASH]` token. Last N lines of daemon stderr preserved in app log for supportability. Crash count tracked per session for telemetry readiness (no telemetry sent — counter only).

#### D0.7 — Version Compatibility Policy

**Decision:** Strict version match for major.minor, fail-closed on mismatch.

**Rejected:** No version check (silent incompatibility); semver-range compatibility (premature — IPC surface is not yet stable, pre-1.0).

**Negotiation:** On IPC connect, app sends version handshake message. Daemon responds with its version. If `major.minor` does not match, daemon sends `version_mismatch` error and closes connection. App shows "Daemon version incompatible — update required" with version details.

**Minimum compatibility:** None until N2 stabilizes IPC. Post-N2: backward compatibility within same major version.

**Rollout implication:** App and daemon MUST be updated together (they ship in the same bundle). Version skew only occurs during development or manual daemon replacement.

#### D0.8 — Boundary with Daemon Runtime Stream (Reaffirmed)

N-STREAM-1 consumes daemon API/runtime surface as defined by B-STREAM. N-STREAM-1 MUST NOT redefine daemon protocol behavior.

**N-STREAM may:** Define how to spawn/kill the daemon binary, define socket paths, define version handshake semantics, define readiness criteria based on existing `daemon.status` events.

**N-STREAM may NOT:** Add new protocol message types, change transfer state machine behavior, modify envelope encryption, add new DcMessage variants.

**Change routing:** If N-STREAM-1 requires new daemon IPC endpoints (e.g., health check, graceful shutdown command, version response), those changes MUST be proposed as B-STREAM work items and executed under B-STREAM governance.

**Current daemon IPC baseline (N2 stabilization target):** Unix domain socket at `/tmp/bolt-daemon.sock`, NDJSON protocol, single-client with kick-on-reconnect. Message types: `daemon.status` (event), `pairing.request` (event), `transfer.incoming.request` (event), `pairing.decision` (decision), `transfer.incoming.decision` (decision).

#### N0 Acceptance Criteria Summary for Downstream Phases

| Phase | Criteria passed from N0 |
|-------|------------------------|
| N1 | Daemon binary placed inside app bundle per platform; socket path is platform-appropriate; app+daemon co-versioned in distribution |
| N2 | IPC assumes co-located processes; `daemon.status` is readiness signal; version handshake required as first IPC message; IPC contract stabilizes current baseline (5 message types); fail-closed on version mismatch |
| N3 | Watchdog implements: spawn on app launch, SIGTERM+5s grace+SIGKILL on exit, exponential backoff (1s/3s/10s, 3 retries, 60s reset), degraded mode after exhaustion, stale socket/PID cleanup, stderr capture |

---

### N1 — Packaging + Security Matrix (Specification)

**Status:** DONE
**Tag:** `ecosystem-v0.1.74-n-stream-1-n1-n2-lock`
**Date:** 2026-03-07
**Scope:** localbolt-app only (guardrail 15). Daemon binary = `bolt-daemon`.

#### N1-T1: Bundle Location + Binary Naming

| Platform | App Bundle Format | Daemon Binary Name | Daemon Location in Bundle | Normative |
|----------|------------------|--------------------|--------------------------|-----------|
| macOS | `.app` inside `.dmg` | `bolt-daemon` (no extension) | `LocalBolt.app/Contents/Resources/bin/bolt-daemon-{arch}` | REQUIRED |
| Windows | `.exe` via NSIS/WiX installer | `bolt-daemon.exe` | `{install_dir}/bin/bolt-daemon-x86_64-pc-windows-msvc.exe` | REQUIRED |
| Linux | `.deb` / `.rpm` | `bolt-daemon` (no extension) | `/usr/lib/localbolt/bin/bolt-daemon-{arch}` (.deb/.rpm) | REQUIRED |

Tauri v2 sidecar convention: binary name includes target triple suffix (e.g., `bolt-daemon-aarch64-apple-darwin`). Tauri resolves the correct binary at runtime based on `std::env::consts`. `tauri.conf.json` MUST declare `bundle.externalBin: ["bin/bolt-daemon"]` — Tauri appends the target triple automatically.

#### N1-T2: Spawn Model

| Aspect | Specification | Normative |
|--------|--------------|-----------|
| Lifecycle owner | App process (Tauri sidecar API) | REQUIRED (N0 D0.1) |
| Spawn timing | Synchronous at app initialization, before transfer UI enabled | REQUIRED (N0 D0.2) |
| Spawn mechanism | `tauri::api::process::Command::new_sidecar("bolt-daemon")` | REQUIRED |
| Daemon CLI args at spawn | `--role answerer --signal rendezvous --pairing-policy ask` (minimum; room/session/peer args per connection) | SHOULD |
| Working directory | App data directory | SHOULD |
| Stdout/stderr | Captured by Tauri sidecar API; stderr logged with `[DAEMON_STDERR]` token | REQUIRED |

#### N1-T3: Signing + Notarization

| Platform | Requirement | Current State | Normative |
|----------|------------|---------------|-----------|
| macOS | Apple Developer ID + notarization via `notarytool` | NOT configured — Gatekeeper bypass in release notes | SHOULD (pre-release); REQUIRED (GA) |
| macOS | Daemon binary MUST be signed with same Developer ID as app (hardened runtime) | NOT configured | REQUIRED (GA) |
| Windows | Authenticode EV code signing certificate | NOT configured — SmartScreen bypass in release notes | SHOULD (pre-release); REQUIRED (GA) |
| Windows | Daemon `.exe` MUST be signed with same certificate as installer | NOT configured | REQUIRED (GA) |
| Linux | No OS-level signing requirement | N/A | N/A |
| Linux | GPG-signed `.deb`/`.rpm` packages | NOT configured | SHOULD |

Out of scope: Certificate procurement, CI signing pipeline setup (deferred to N6 execution).

#### N1-T4: Filesystem Locations

| Resource | macOS | Windows | Linux | Normative |
|----------|-------|---------|-------|-----------|
| Runtime socket | `$TMPDIR/bolt-daemon.sock` | `\\.\pipe\bolt-daemon` (named pipe) | `$XDG_RUNTIME_DIR/bolt-daemon.sock` (fallback: `/tmp/bolt-daemon.sock`) | REQUIRED (N0 D0.5) |
| PID file | `$TMPDIR/bolt-daemon.pid` | `%LOCALAPPDATA%\bolt-daemon\bolt-daemon.pid` | `$XDG_RUNTIME_DIR/bolt-daemon.pid` (fallback: `/tmp/bolt-daemon.pid`) | REQUIRED (N0 D0.6) |
| Logs | `~/Library/Logs/LocalBolt/daemon.log` | `%LOCALAPPDATA%\LocalBolt\logs\daemon.log` | `$XDG_STATE_HOME/localbolt/daemon.log` (fallback: `~/.local/state/localbolt/daemon.log`) | SHOULD |
| Identity key | `~/Library/Application Support/LocalBolt/identity.key` | `%APPDATA%\LocalBolt\identity.key` | `$XDG_DATA_HOME/localbolt/identity.key` (fallback: `~/.local/share/localbolt/identity.key`) | REQUIRED (N0 D0.6) |
| TOFU pin store | `~/Library/Application Support/LocalBolt/pins/` | `%APPDATA%\LocalBolt\pins\` | `$XDG_DATA_HOME/localbolt/pins/` | REQUIRED (N0 D0.6) |
| Config | `~/Library/Application Support/LocalBolt/config.toml` | `%APPDATA%\LocalBolt\config.toml` | `$XDG_CONFIG_HOME/localbolt/config.toml` (fallback: `~/.config/localbolt/config.toml`) | SHOULD |

**B-STREAM dependency (B-DEP-N1-1):** Current daemon hardcodes `/tmp/bolt-daemon.sock` and `~/.bolt/`. Platform-appropriate paths require daemon CLI flags (`--socket-path`, `--data-dir`). Medium severity — defaults work for dev/beta, REQUIRED for GA.

#### N1-T5: Permission Model (Least Privilege)

| Aspect | Specification | Normative |
|--------|--------------|-----------|
| Daemon process privilege | Same user as app (no elevation) | REQUIRED |
| Socket permissions | `0600` (owner-only; already implemented in daemon) | REQUIRED |
| Identity key file | `0600` (owner-only read/write) | REQUIRED |
| TOFU pin store | `0700` directory, `0600` files | REQUIRED |
| Network access | Outbound only (WebSocket to rendezvous, WebRTC P2P) | REQUIRED |
| Filesystem write scope | Data dir + runtime dir only; no writes outside | REQUIRED |
| macOS sandbox | App sandbox enabled; daemon inherits app sandbox profile | SHOULD (GA) |
| Windows | No UAC elevation; standard user permissions | REQUIRED |
| Linux | No root; no capabilities; no setuid | REQUIRED |

#### N1-T6: Update/Rollback + Version Skew

| Aspect | Specification | Normative |
|--------|--------------|-----------|
| Co-versioning | App and daemon ship in same bundle; versions always match | REQUIRED (N0 D0.7) |
| Update mechanism | Whole-bundle update (Tauri updater replaces app + daemon together) | REQUIRED |
| Rollback | Whole-bundle rollback; no independent daemon rollback | REQUIRED |
| Version skew detection | IPC version handshake (N2); fail-closed on mismatch | REQUIRED (N0 D0.7) |
| Partial update | MUST NOT occur; no mechanism to update daemon independently of app | REQUIRED |

#### N1-T7: Explicit Out-of-Scope

| Item | Reason |
|------|--------|
| System service mode (launchd/systemd/Windows Service) | Rejected in N0 D0.1 |
| Login-item auto-start | Rejected in N0 D0.2 |
| Multi-user daemon sharing | Rejected in N0 D0.5 |
| Independent daemon installation | N0 D0.7 requires co-bundling |
| macOS App Store distribution | Separate governance gate |
| Mobile platform packaging (iOS/Android) | localbolt-app v2.1.0 roadmap |
| Certificate procurement / CI signing pipeline | Deferred to N6 |

#### N1 Acceptance Checklist (for N5 harness)

- [ ] AC-N1-1: Daemon binary present in app bundle at platform-correct path
- [ ] AC-N1-2: Daemon binary executable and runs (exits 1 with usage line)
- [ ] AC-N1-3: Socket created at platform-correct path after daemon spawn
- [ ] AC-N1-4: Socket has `0600` permissions (Unix) or equivalent (Windows named pipe)
- [ ] AC-N1-5: PID file created at platform-correct path
- [ ] AC-N1-6: Identity key persists at platform-correct path across app restart
- [ ] AC-N1-7: App and daemon report identical version in IPC handshake
- [ ] AC-N1-8: Daemon runs without elevated privileges
- [ ] AC-N1-9: No writes outside data-dir and runtime-dir
- [ ] AC-N1-10: macOS `.app` contains signed daemon binary (GA gate only)
- [ ] AC-N1-11: Windows installer contains signed daemon `.exe` (GA gate only)

---

### N2 — IPC Contract Stabilization (Specification)

**Status:** DONE (spec locked, implementation dependencies open)
**Tag:** `ecosystem-v0.1.74-n-stream-1-n1-n2-lock`
**Date:** 2026-03-07
**Scope:** Consumer-side contract lock against current daemon IPC baseline. B-DEP-N2-1/2/3 block downstream execution (N3/N6) but not this spec lock.

#### N2-S1: Connection Model

| Aspect | Specification | Evidence | Normative |
|--------|--------------|----------|-----------|
| Transport | Unix domain socket (macOS/Linux); Named pipe (Windows) | `src/ipc/server.rs:19` | REQUIRED |
| Wire format | NDJSON (one JSON object per `\n`-terminated line) | `src/ipc/types.rs:1-4` | REQUIRED |
| Max line size | 1,048,576 bytes (1 MiB) | `src/ipc/server.rs:22` | REQUIRED |
| Client model | Single client; kick-on-reconnect | `src/ipc/server.rs:204-246` | REQUIRED (N0 D0.5) |
| Connection lifecycle | App connects after daemon spawn; disconnection = client lost | `src/ipc/server.rs` | REQUIRED |

#### N2-S2: Readiness Contract

| Aspect | Specification | Evidence | Normative |
|--------|--------------|----------|-----------|
| Readiness signal | `daemon.status` event emitted on client connect | N0 D0.2, `src/main.rs:1098` | REQUIRED |
| Startup timeout | 10 seconds from spawn to first `daemon.status` | N0 D0.2 | REQUIRED |
| Timeout behavior | App enters degraded mode (transfer UI disabled, "Daemon unavailable") | N0 D0.2 | REQUIRED |
| Retry on timeout | No auto-retry; manual retry button | N0 D0.2 | REQUIRED |

**B-STREAM dependency (B-DEP-N2-1):** `daemon.status` is currently emitted only in simulate mode (`src/main.rs:1098`). Default mode MUST emit `daemon.status` on client connect. High severity — blocks N3 readiness check.

#### N2-S3: Version Handshake

| Aspect | Specification | Evidence | Normative |
|--------|--------------|----------|-----------|
| First message after connect | App MUST send `version.handshake` (`kind: "decision"`) | N0 D0.7 (new message) | REQUIRED |
| Handshake payload | `{ "app_version": "<major.minor.patch>" }` | N0 D0.7 | REQUIRED |
| Daemon response | `version.status` event with `{ "daemon_version": "<major.minor.patch>", "compatible": bool }` | N0 D0.7 (new message) | REQUIRED |
| Match rule | `major.minor` of app == `major.minor` of daemon | N0 D0.7 | REQUIRED |
| Mismatch behavior | Daemon sends `version.status` with `compatible: false`, then closes connection | N0 D0.7 | REQUIRED |
| App mismatch UX | "Daemon version incompatible — update required" with version details | N0 D0.7 | REQUIRED |
| Pre-handshake messages | Daemon MUST NOT emit events (except `version.status`) before handshake completes | N0 D0.7 | REQUIRED |

**B-STREAM dependency (B-DEP-N2-2):** `version.handshake` and `version.status` messages do not exist in current daemon. High severity — blocks N3 version-gated supervision.

#### N2-S4: Message Surface (Audited + Classified)

Source code audit baseline: `bolt-daemon/src/ipc/types.rs`, `src/ipc/server.rs`, `src/ipc/trust.rs`, `src/main.rs`.

**Daemon -> App (Events)**

| Message Type | Classification | Lock Status |
|-------------|---------------|-------------|
| `daemon.status` | **STABLE** | Locked |
| `pairing.request` | **STABLE** | Locked |
| `transfer.incoming.request` | **STABLE** | Locked |
| `version.status` | **PROVISIONAL** | Schema locked; B-DEP-N2-2 (implementation) |

**App -> Daemon (Decisions)**

| Message Type | Classification | Lock Status |
|-------------|---------------|-------------|
| `pairing.decision` | **STABLE** | Locked |
| `transfer.incoming.decision` | **STABLE** | Locked |
| `version.handshake` | **PROVISIONAL** | Schema locked; B-DEP-N2-2 (implementation) |

**Internal (NOT app-facing)**

| Aspect | Classification |
|--------|---------------|
| `IpcKind` enum (`event`/`decision` wire values) | INTERNAL (stable, not a message type) |
| `id::generate_request_id()` (monotonic `evt-N`) | INTERNAL |
| `IpcServer::is_ui_connected()` | INTERNAL |

#### N2-S4a: Message Envelope Schema

All messages use a common envelope. All 5 fields REQUIRED:

```json
{
  "id": "evt-<u64>",
  "kind": "event" | "decision",
  "type": "<message_type>",
  "ts_ms": <u64>,
  "payload": { ... }
}
```

Unknown `kind` values MUST cause deserialization failure. Extra fields in `payload` MUST be preserved (forward-compatible). Evidence: `src/ipc/types.rs:12-28`, test `extra_fields_in_payload_are_preserved`.

#### N2-S4b: Payload Schemas (Locked)

**`daemon.status` payload:**
```json
{ "connected_peers": <u32>, "ui_connected": <bool>, "version": "<string>" }
```
Source: `src/ipc/types.rs:65-70` (`DaemonStatusPayload`)

**`pairing.request` payload:**
```json
{
  "request_id": "<string>",
  "remote_device_name": "<string>",
  "remote_device_type": "<string>",
  "remote_identity_pk_b64": "<string>",
  "sas": "<string>",
  "capabilities_requested": ["<string>", ...]
}
```
Source: `src/ipc/types.rs:42-50` (`PairingRequestPayload`)

**`transfer.incoming.request` payload:**
```json
{
  "request_id": "<string>",
  "from_device_name": "<string>",
  "from_identity_pk_b64": "<string>",
  "file_name": "<string>",
  "file_size_bytes": <u64>,
  "sha256_hex": "<string>" | null,
  "mime": "<string>" | null
}
```
Source: `src/ipc/types.rs:52-63` (`TransferIncomingRequestPayload`). Optional fields omitted when null (`skip_serializing_if`).

**`pairing.decision` / `transfer.incoming.decision` payload:**
```json
{
  "request_id": "<string>",
  "decision": "allow_once" | "allow_always" | "deny_once" | "deny_always",
  "note": "<string>" | null
}
```
Source: `src/ipc/types.rs:74-80` (`DecisionPayload`), `src/ipc/types.rs:31-38` (`Decision` enum, `rename_all = "snake_case"`).

**Decision timeout:** 30 seconds, fail-closed deny (`src/ipc/trust.rs:27`).

**`version.handshake` payload (PROVISIONAL):**
```json
{ "app_version": "<major.minor.patch>" }
```

**`version.status` payload (PROVISIONAL):**
```json
{ "daemon_version": "<major.minor.patch>", "compatible": <bool> }
```

#### N2-S5: Error Contract

| Error Condition | Daemon Behavior | App UX Requirement | Normative |
|----------------|----------------|-------------------|-----------|
| Invalid JSON received | `[IPC_INVALID_JSON]` log, client disconnected | Reconnect with backoff | REQUIRED |
| Line exceeds 1 MiB | `[IPC_OVERSIZE]` log, client disconnected | Reconnect with backoff | REQUIRED |
| Unknown message type | `[IPC_UNKNOWN_TYPE]` log, message silently dropped | None (forward-compatible) | REQUIRED |
| Decision timeout (30s) | Fail-closed deny, `None` returned | App SHOULD warn user of timeout | SHOULD |
| Client disconnect | Reader EOF detected, threads exit | App triggers restart per N0 D0.4 | REQUIRED |
| Version mismatch | `version.status` with `compatible: false`, connection closed | Show version mismatch error | REQUIRED |
| Mutex poison (internal) | `is_ui_connected()` returns `false` (fail-closed) | Treated as daemon unavailable | REQUIRED |

**Degraded Mode Transitions:**

| Trigger | State Transition | Recovery |
|---------|-----------------|----------|
| Daemon not started within 10s | `starting` -> `degraded` | Manual retry button |
| Daemon crash | `ready` -> `restarting (N/3)` | Auto-restart per N0 D0.4 |
| 3 consecutive crash restarts | `restarting` -> `degraded` | Manual restart button |
| Version mismatch | `starting` -> `incompatible` | Update app+daemon bundle |
| IPC disconnect (no crash) | `ready` -> `reconnecting` | Auto-reconnect (single attempt, then degrade) |

#### N2-S6: Compatibility Policy

| Aspect | Rule | Normative |
|--------|------|-----------|
| Breaking change | Adding/removing/renaming required envelope fields; changing `kind` or `type` values; removing a STABLE message type; changing STABLE payload field names/types | REQUIRED major version bump |
| Non-breaking change | Adding optional fields to payload (with `skip_serializing_if`); adding new message types; adding new `decision` enum variants | REQUIRED minor version bump |
| Extension mechanism | New message types MUST follow existing envelope schema; unknown `type` values MUST be silently dropped (already implemented) | REQUIRED |
| Deprecation | STABLE messages MUST NOT be removed without one full minor version deprecation cycle | REQUIRED |
| Forward compatibility | Extra fields in `payload` MUST be preserved through roundtrip (already implemented per test `extra_fields_in_payload_are_preserved`) | REQUIRED |

**IPC Version Numbering:** IPC contract version follows daemon `Cargo.toml` version (currently `0.0.1`). Pre-1.0: breaking changes allowed with minor bump. Post-1.0: semver strict. App and daemon MUST match on `major.minor` (N0 D0.7).

#### N2 Acceptance Checklist (for N5 harness)

- [ ] AC-N2-1: App connects to daemon socket within 10s of spawn
- [ ] AC-N2-2: Version handshake completes as first message exchange
- [ ] AC-N2-3: Version mismatch produces fail-closed error (connection terminated)
- [ ] AC-N2-4: `daemon.status` received after successful version handshake
- [ ] AC-N2-5: `pairing.request` event delivered to app with all required fields
- [ ] AC-N2-6: `pairing.decision` accepted by daemon with correct request_id correlation
- [ ] AC-N2-7: `transfer.incoming.request` event delivered with all required fields
- [ ] AC-N2-8: `transfer.incoming.decision` accepted by daemon
- [ ] AC-N2-9: Decision timeout (30s) results in fail-closed deny
- [ ] AC-N2-10: Unknown message types silently dropped (forward-compatible)
- [ ] AC-N2-11: Extra payload fields preserved through roundtrip

---

### B-STREAM Dependency Items (from N1/N2)

These gaps require daemon-side changes. Recorded here; implementation is B-STREAM governance.

| ID | Description | Blocking Phase | Severity |
|----|-------------|---------------|----------|
| B-DEP-N1-1 | Daemon needs `--socket-path` and `--data-dir` CLI flags for platform-appropriate filesystem locations (currently hardcoded `/tmp/bolt-daemon.sock`, `~/.bolt/`) | N6 (execution) | Medium — **RESOLVED** (`daemon-v0.2.32-n6b1-path-flags`, `80fb0af`; consumed by `localbolt-app-v1.2.13-n6b3-ga-wiring`, `88954c8`) |
| B-DEP-N2-1 | `daemon.status` event must be emitted in default mode on client connect (currently simulate-mode only) | N3 (supervision readiness check) | High — **RESOLVED** (`daemon-v0.2.31-bdep-n2-ipc-unblock`, `1ad2db8`) |
| B-DEP-N2-2 | `version.handshake` (app->daemon) and `version.status` (daemon->app) messages must be implemented | N3 (version-gated supervision) | High — **RESOLVED** (`daemon-v0.2.31-bdep-n2-ipc-unblock`, `1ad2db8`) |
| B-DEP-N2-3 | Windows named pipe support (daemon currently Unix socket only) | N6 (Windows platform) | Medium — **RESOLVED** (`daemon-v0.2.33-n6b2-windows-pipe`, `b8c1f3c`; app transport: `localbolt-app-v1.2.13-n6b3-ga-wiring`, `88954c8`). Code complete; Windows runtime validated via R17 (CLOSED 2026-03-08, `daemon-v0.2.34-r17-windows-validated`). |

---

### N3 — Process Supervision + Diagnostics (Specification)

**Status:** DONE (spec locked; B-DEP-N2-1/N2-2 **RESOLVED** — N6 readiness/version-gate unblocked)
**Tag:** `ecosystem-v0.1.75-n-stream-1-n3-supervision`
**Date:** 2026-03-07
**Scope:** localbolt-app supervision of bolt-daemon process. Spec-only — no runtime code.
**Dependencies consumed:** N0 (D0.1–D0.8), N1 (N1-T2 spawn model, N1-T4 filesystem locations), N2 (readiness contract, version handshake, error contract)

#### N3-W1: Watchdog State Machine

The app watchdog manages daemon lifecycle through five states:

| State | Entry Condition | User-Visible Label | Transfer UI |
|-------|----------------|-------------------|-------------|
| `starting` | App launch OR manual restart | "Starting connection service..." | Disabled |
| `ready` | `daemon.status` received via IPC (N2-S2) | "Ready" (or hidden) | Enabled |
| `restarting` | Daemon process exits unexpectedly, retries remaining | "Reconnecting... (N/3)" | Disabled |
| `degraded` | 3 restart attempts exhausted (N0 D0.4) | "Connection service stopped — restart required" | Disabled |
| `incompatible` | `version.status` returns `compatible: false` (N2-S3) | "Daemon version incompatible — update required" | Disabled |

**Transitions:**

```
                    ┌──────────────────────────────────────────┐
                    │                                          ▼
[app launch] → starting ──(daemon.status)──→ ready ──(crash)──→ restarting
                  │                            │                    │
                  │                            │               (retries < 3)
                  │                            │                    │
                  │                            │              restarting ──(daemon.status)──→ ready
                  │                            │                    │
                  │                            │               (retries = 3)
                  │                            │                    │
                  │                            │                    ▼
                  │                            │               degraded ──(manual restart)──→ starting
                  │                            │
                  │                            └──(app exit)──→ [shutdown]
                  │
                  └──(version mismatch)──→ incompatible ──(app update)──→ [restart app]
                  └──(10s timeout)──→ degraded
```

**State invariants:**

| ID | Invariant | Normative |
|----|-----------|-----------|
| W-01 | Transfer UI MUST be disabled in all states except `ready` | REQUIRED |
| W-02 | State transitions MUST be logged with `[WATCHDOG]` token | REQUIRED |
| W-03 | `incompatible` is terminal for the session — no auto-retry | REQUIRED |
| W-04 | `degraded` is recoverable only via explicit user action (manual restart button) | REQUIRED |
| W-05 | Watchdog MUST NOT spawn daemon if already in `ready` state | REQUIRED |
| W-06 | Watchdog MUST track retry count and reset after 60s of continuous `ready` | REQUIRED (N0 D0.4) |

**Implementation note (B-DEP-N2-1):** Transition from `starting` to `ready` requires `daemon.status` event. Daemon currently emits this only in simulate mode (`src/main.rs:1085-1098`). N6 implementation of this transition is BLOCKED until B-STREAM delivers `daemon.status` in default mode.

**Implementation note (B-DEP-N2-2):** Transition from `starting` to `incompatible` requires `version.status` response. `version.handshake` and `version.status` messages do not exist in current daemon. N6 implementation of version-gated supervision is BLOCKED until B-STREAM delivers these messages.

#### N3-W2: Retry and Backoff Semantics

Operationalizes N0 D0.4 policy into concrete algorithm:

| Parameter | Value | Source |
|-----------|-------|--------|
| Max retries | 3 | N0 D0.4 |
| Backoff schedule | 1s, 3s, 10s | N0 D0.4 |
| Success reset window | 60s of continuous `ready` state | N0 D0.4 |
| Retry counter scope | Per app session (reset on app restart) | N0 D0.4 |

**Algorithm:**

```
retry_count = 0
last_ready_time = null

on daemon_exit(exit_code):
    if retry_count >= 3:
        transition(degraded)
        return

    delay = [1s, 3s, 10s][retry_count]
    retry_count += 1
    transition(restarting)
    log("[WATCHDOG] daemon exited (code={exit_code}), retry {retry_count}/3 in {delay}s")
    sleep(delay)
    run_cleanup()       # N3-W3
    spawn_daemon()

on transition_to_ready:
    last_ready_time = now()

on heartbeat_tick (every 10s while ready):
    if now() - last_ready_time >= 60s:
        retry_count = 0
        log("[WATCHDOG] success window reached, retry counter reset")
```

**Edge cases:**

| Scenario | Behavior |
|----------|----------|
| Daemon exits with code 0 during shutdown | NOT a crash — do not retry |
| Daemon exits while app is shutting down | Ignore — app is exiting |
| Rapid crash loop (daemon exits < 1s after spawn) | Normal backoff applies; 3 retries then degraded |
| Manual restart from degraded | Reset retry_count to 0, transition to `starting` |

#### N3-W3: Stale Socket/Process Cleanup Algorithm

**Existing daemon behavior (audited):**
- `IpcServer::start()` (`src/ipc/server.rs:112-116`): removes existing socket file before bind (unconditional `remove_file`)
- `IpcServer::drop()` (`src/ipc/server.rs:344-351`): removes socket file on server drop
- No PID file management exists in daemon code (confirmed: zero PID file references in production source)

**App-side cleanup algorithm (pre-spawn):**

```
function run_cleanup():
    socket_path = platform_socket_path()    # N1-T4
    pid_path = platform_pid_path()          # N1-T4

    # Step 1: Check PID file
    if pid_path.exists():
        pid = read_pid(pid_path)
        if process_alive(pid):
            # Daemon already running — probe socket
            if socket_path.exists() and socket_probe_ok(socket_path):
                log("[WATCHDOG] existing daemon alive (pid={pid}), connecting")
                return CONNECT_EXISTING
            else:
                # Process alive but socket missing — kill and respawn
                log("[WATCHDOG] daemon alive (pid={pid}) but socket missing, killing")
                kill(pid, SIGTERM)
                wait_or_sigkill(pid, 5s)
        # Process dead — clean up PID file
        remove(pid_path)
        log("[WATCHDOG] cleaned stale PID file")

    # Step 2: Check stale socket
    if socket_path.exists():
        if socket_probe_ok(socket_path):
            log("[WATCHDOG] responsive daemon found via socket probe, connecting")
            return CONNECT_EXISTING
        else:
            remove(socket_path)
            log("[WATCHDOG] removed stale socket: {socket_path}")

    return SPAWN_NEW
```

**Socket probe:** Non-blocking connect attempt to Unix socket. If connection succeeds, daemon is alive — return probe success. If connection refused or timeout (500ms), socket is stale.

**PID file contract:**
- Written by app after successful daemon spawn: `write(pid_path, daemon_pid)`
- App-owned (not daemon-owned) — daemon does not write or read PID files
- Permissions: `0600` (owner-only, consistent with N1-T5)
- Removed by cleanup algorithm on stale detection or by app on clean shutdown

**Platform paths (from N1-T4):**

| Platform | Socket | PID File |
|----------|--------|----------|
| macOS | `$TMPDIR/bolt-daemon.sock` | `$TMPDIR/bolt-daemon.pid` |
| Windows | `\\.\pipe\bolt-daemon` | `%LOCALAPPDATA%\bolt-daemon\bolt-daemon.pid` |
| Linux | `$XDG_RUNTIME_DIR/bolt-daemon.sock` | `$XDG_RUNTIME_DIR/bolt-daemon.pid` |

#### N3-W4: Shutdown Lifecycle Contract

Operationalizes N0 D0.3:

```
function shutdown_daemon():
    if active_transfer():
        prompt_user("Transfer in progress — stop anyway?")
        if user_cancels: return    # abort shutdown

    log("[WATCHDOG] initiating daemon shutdown")
    send_signal(daemon_pid, SIGTERM)

    if wait_exit(daemon_pid, 5s):
        log("[WATCHDOG] daemon exited cleanly")
    else:
        log("[WATCHDOG] daemon did not exit in 5s, sending SIGKILL")
        send_signal(daemon_pid, SIGKILL)
        wait_exit(daemon_pid, 1s)  # SIGKILL is guaranteed on Unix

    run_cleanup()  # Remove socket + PID file
```

**App exit integration:** Tauri `on_exit` hook triggers `shutdown_daemon()`. Watchdog suppresses restart attempts during shutdown (shutdown flag).

#### N3-W5: stderr/Log Capture Contract

**Daemon output model:** Daemon writes all diagnostic output to stderr via `eprintln!()`. No structured logging framework. Log tokens (e.g., `[IPC]`, `[dc]`, `[simulate]`) provide grep-friendly categorization.

**App capture contract:**

| Aspect | Specification | Normative |
|--------|--------------|-----------|
| Capture method | Pipe daemon subprocess stderr to app-side ring buffer | REQUIRED |
| Buffer size | Last 1000 lines (configurable, minimum 500) | REQUIRED |
| Persistence | In-memory only; written to disk on crash or support bundle export | REQUIRED |
| Crash snapshot | On daemon crash: write last 200 lines to `{log_dir}/daemon-crash-{timestamp}.log` | REQUIRED |
| Crash token | App logs `[DAEMON_CRASH] exit_code={code} pid={pid} retry={N}/3` | REQUIRED |
| Crash count | Per-session counter, no telemetry transmission | REQUIRED (N0 D0.6) |

**Log directory (from N1-T4):**

| Platform | Log Directory |
|----------|--------------|
| macOS | `~/Library/Logs/LocalBolt/` |
| Windows | `%LOCALAPPDATA%\LocalBolt\logs\` |
| Linux | `$XDG_STATE_HOME/localbolt/log/` (fallback: `~/.local/state/localbolt/log/`) |

**Support bundle minimums:**

A support bundle export MUST include:
1. Last 1000 lines of daemon stderr (or all captured if < 1000)
2. All crash snapshots from current app session
3. Watchdog state transition log (with timestamps)
4. App version + daemon version (if obtained via version handshake)
5. Platform identifier (OS, arch)
6. Daemon spawn count and current retry state

Support bundle MUST NOT include:
- Identity keys or TOFU pins
- Transfer content or filenames
- Peer codes or IP addresses

#### N3-W6: User-Visible Status Transitions and Action Affordances

| State | Status Indicator | Primary Action | Secondary Action |
|-------|-----------------|---------------|-----------------|
| `starting` | Spinner + "Starting connection service..." | None (auto) | — |
| `ready` | Green dot (or hidden) | Transfer UI enabled | — |
| `restarting` | Spinner + "Reconnecting... (N/3)" | None (auto) | — |
| `degraded` | Red indicator + "Connection service stopped — restart required" | "Restart" button | "Export logs" button |
| `incompatible` | Warning icon + "Daemon version incompatible — update required" with version details | "Check for updates" or app store link | "Export logs" button |

**Transition notifications:**
- `ready → restarting`: Non-blocking toast/banner: "Connection interrupted — reconnecting..."
- `restarting → ready`: Toast auto-dismiss, transfer UI re-enables
- `restarting → degraded`: Persistent banner (does not auto-dismiss)
- `starting → degraded` (10s timeout): Same as above

**Accessibility:** Status text MUST be screen-reader accessible. State changes MUST update ARIA live region.

#### N3 Readiness Matrix (P1 Result)

| N3 Sub-item | Spec Status | N6 Implementation Status | Blocker |
|-------------|------------|------------------------|---------|
| N3-W1: Watchdog state machine | **LOCKED** | Partially blocked | B-DEP-N2-1 (readiness transition), B-DEP-N2-2 (incompatible transition) |
| N3-W2: Retry/backoff | **LOCKED** | Unblocked | — |
| N3-W3: Stale cleanup | **LOCKED** | Unblocked | — |
| N3-W4: Shutdown lifecycle | **LOCKED** | Unblocked | — |
| N3-W5: stderr/log capture | **LOCKED** | Unblocked | — |
| N3-W6: User-visible status | **LOCKED** | Partially blocked | B-DEP-N2-1 (ready indicator), B-DEP-N2-2 (incompatible indicator) |

**Conclusion:** All 6 N3 sub-items are spec-locked. N6 implementation of readiness detection (`starting → ready`) and version-gated supervision (`starting → incompatible`) is blocked by B-DEP-N2-1 and B-DEP-N2-2 respectively. Remaining N3 sub-items (retry, cleanup, shutdown, stderr capture, degraded UX) are fully unblocked for N6 implementation.

#### N3 Acceptance Checklist (for N5 harness)

- [ ] AC-N3-1: Watchdog transitions through all 5 states correctly
- [ ] AC-N3-2: `starting → ready` transition on `daemon.status` receipt (BLOCKED: B-DEP-N2-1)
- [ ] AC-N3-3: `starting → incompatible` on version mismatch (BLOCKED: B-DEP-N2-2)
- [ ] AC-N3-4: Crash triggers retry with correct backoff (1s, 3s, 10s)
- [ ] AC-N3-5: 3 consecutive crashes → `degraded` state
- [ ] AC-N3-6: Retry counter resets after 60s continuous `ready`
- [ ] AC-N3-7: Manual restart from `degraded` resets counter and transitions to `starting`
- [ ] AC-N3-8: Stale socket detected and removed before respawn
- [ ] AC-N3-9: PID file written after spawn, cleaned on shutdown/stale detection
- [ ] AC-N3-10: Daemon stderr captured in ring buffer (minimum 500 lines)
- [ ] AC-N3-11: Crash snapshot written to log directory with `[DAEMON_CRASH]` token
- [ ] AC-N3-12: Support bundle export includes all required items, excludes sensitive data
- [ ] AC-N3-13: SIGTERM + 5s grace + SIGKILL shutdown sequence
- [ ] AC-N3-14: Transfer UI disabled in all non-ready states
- [ ] AC-N3-15: Status transitions logged with `[WATCHDOG]` token

#### N3 → N6 Implementation Readiness Plan

**Implementation sequence (N6, by component/repo):**

1. **localbolt-app (Rust/Tauri side):**
   a. Add `bolt-daemon` as Tauri sidecar in `tauri.conf.json` (N1-T1)
   b. Implement `DaemonWatchdog` struct with state machine (N3-W1)
   c. Implement `run_cleanup()` pre-spawn logic (N3-W3)
   d. Implement subprocess spawn + stderr pipe capture (N3-W5)
   e. Implement PID file write/cleanup
   f. Implement shutdown hook via Tauri `on_exit` (N3-W4)
   g. Implement retry/backoff timer (N3-W2)
   h. Wire `daemon.status` IPC parsing for readiness (BLOCKED: B-DEP-N2-1)
   i. Wire `version.handshake`/`version.status` flow (BLOCKED: B-DEP-N2-2)

2. **localbolt-app (TypeScript/UI side):**
   a. Add watchdog status component (N3-W6)
   b. Wire Tauri event bridge for state transitions
   c. Implement degraded mode UI (restart button, log export)
   d. Implement incompatible mode UI (update prompt)
   e. Transfer UI gating based on watchdog state (W-01)

3. **bolt-daemon (B-STREAM — handoff items):**
   a. B-DEP-N2-1: Emit `daemon.status` on client connect in default mode
   b. B-DEP-N2-2: Implement `version.handshake` (inbound) and `version.status` (outbound) messages

**Test/validation hooks needed for N5 harness:**
- Watchdog state machine unit tests (all transitions, edge cases)
- Retry/backoff timing tests (mock clock)
- Stale socket cleanup tests (mock filesystem)
- stderr capture + crash snapshot tests
- Support bundle content validation
- Shutdown sequence tests (mock process signals)
- Integration test: spawn real daemon binary, verify readiness flow (requires B-DEP-N2-1)
- Integration test: version mismatch → incompatible state (requires B-DEP-N2-2)

**Dependency handoff list to B-STREAM:**

| Handoff | B-DEP ID | Priority | N6 Impact |
|---------|----------|----------|-----------|
| Emit `daemon.status` in default mode on client connect | B-DEP-N2-1 | **High** | Blocks readiness detection — core supervision flow |
| Implement `version.handshake` + `version.status` | B-DEP-N2-2 | **High** | Blocks version-gated supervision — incompatible state |

**Rollback requirements:**
- App MUST function without daemon (degraded mode) if daemon binary is missing or fails to start
- If watchdog implementation regresses app stability, revert to pre-N6 state (no daemon bundling) via standard Tauri sidecar removal
- No daemon-side rollback needed — N6 does not modify daemon runtime

**Observability requirements:**
- `[WATCHDOG]` log token for all state transitions
- `[DAEMON_CRASH]` log token for crash events
- `[DAEMON_SPAWN]` log token for spawn events
- `[DAEMON_SHUTDOWN]` log token for clean shutdown
- Crash count metric (in-memory, per session)

---

### N4 — Rollout + Migration (Specification)

**Status:** DONE (spec locked)
**Tag:** `ecosystem-v0.1.76-n-stream-1-n4-n5-lock`
**Date:** 2026-03-07
**Scope:** Staged rollout strategy, version-skew policy, update/rollback model, migration path from current localbolt-app (no daemon) to bundled daemon lifecycle. Spec-only — no runtime code.
**Dependencies consumed:** N0 (D0.1–D0.8), N1 (packaging matrix, co-versioning, N1-T6), N2 (IPC contract, version handshake N2-S3, compatibility policy N2-S6)

#### N4-R1: Rollout Stage-Gate Table

| Stage | Entry Criteria | Required Artifacts | Blocker Policy | Exit Criteria |
|-------|---------------|-------------------|---------------|--------------|
| **Local/Dev** | N0–N3 spec locked; daemon binary builds (`cargo build --release`); app builds with sidecar config in `tauri.conf.json` | Built app+daemon bundle on dev machine (unsigned); N5 Tier 1 (smoke) green | B-DEP-N2-1/N2-2 do NOT block (degraded mode acceptable); B-DEP-N1-1 does NOT block (default paths acceptable) | App launches, spawns daemon, captures stderr, handles crash/restart cycle in degraded mode; Tier 1 smoke tests pass |
| **Internal Alpha** | Local/Dev exit met; **B-DEP-N2-1 RESOLVED** | Dev-signed builds for macOS and Linux; N5 Tier 1 + Tier 2 (unblocked checks) green | B-DEP-N2-1 MUST be resolved (readiness detection required); B-DEP-N2-2 does NOT block (version gating not required for internal team); B-DEP-N1-1 does NOT block | Full watchdog state machine functional (except `incompatible` state); IPC message flow for all 5 stable messages verified; retry/backoff demonstrated |
| **Beta** | Alpha exit met; **B-DEP-N2-2 RESOLVED** | Pre-release builds for all 3 platforms; N5 Tier 1 + Tier 2 + Tier 3 green | B-DEP-N2-1 AND B-DEP-N2-2 MUST be resolved; B-DEP-N1-1 SHOULD be resolved (defaults acceptable for beta); B-DEP-N2-3 does NOT block (Windows beta may use Unix socket via WSL or defer Windows) | All N5 tiers except Tier 4 pass; no P0/P1 regressions from non-daemon baseline; version handshake + mismatch handling verified; 48h burn-in with no degraded-state entries during normal operation |
| **GA** | Beta exit met; **B-DEP-N1-1 RESOLVED**; code signing complete per N1-T3 (REQUIRED) | Signed, notarized production builds for all platforms; N5 Tier 4 (pre-release gate) green; release notes | ALL B-DEPs RESOLVED (B-DEP-N2-3 for Windows GA); N1-T3 signing requirements met at REQUIRED level; all N5 tiers pass including Tier 4 | Published release on all platforms; rollback tested and documented; support bundle export verified |

**Cannot-progress gates (hard blocks):**

| Gate | Blocked Until | Reason |
|------|-------------|--------|
| Alpha entry | B-DEP-N2-1 resolved | Cannot validate readiness detection without `daemon.status` in default mode |
| Beta entry | B-DEP-N2-2 resolved | Cannot validate version safety without `version.handshake`/`version.status` |
| GA entry | B-DEP-N1-1 resolved | Cannot ship production builds with hardcoded `/tmp/` paths |
| Windows GA | B-DEP-N2-3 resolved | Cannot ship Windows release without named pipe support |

**What can proceed while blockers remain open:**

- Local/Dev stage is fully unblocked — degraded mode acceptable for development
- N5 smoke tests and unblocked integration tests can be authored and executed
- Packaging infrastructure, CI pipeline setup, signing certificate procurement (N6 pre-work)
- Migration UX design and implementation (additive, no daemon dependency)
- Failure injection tests for crash/restart (no B-DEP dependency)

#### N4-R2: Version-Skew Policy

Derived from N0 D0.7 and N2-S3/S6.

| Aspect | Rule | Normative |
|--------|------|-----------|
| Co-versioning | App and daemon MUST ship in the same bundle with identical `major.minor.patch` versions | REQUIRED (N0 D0.7) |
| Match rule | `major.minor` of app MUST equal `major.minor` of daemon | REQUIRED (N2-S3) |
| Detection mechanism | IPC version handshake (N2-S3): app sends `version.handshake`, daemon responds with `version.status` | REQUIRED |
| Mismatch behavior | Daemon sends `version.status` with `compatible: false`, then closes connection | REQUIRED (N2-S3) |
| App UX on mismatch | "Daemon version incompatible — update required" with both version numbers displayed | REQUIRED (N2-S3) |
| Watchdog state on mismatch | Transition to `incompatible` (terminal for session, no auto-retry) | REQUIRED (N3-W1, W-03) |

**Accidental skew scenarios and handling:**

| Scenario | How It Occurs | Detection | Resolution |
|----------|--------------|-----------|------------|
| Partial update (daemon only) | Manual file replacement or failed installer | Version handshake mismatch → `incompatible` state | Re-install full bundle |
| Partial update (app only) | Manual file replacement or failed installer | Version handshake mismatch → `incompatible` state | Re-install full bundle |
| Stale daemon from previous version | Previous daemon instance not terminated before update | Version handshake mismatch after IPC connect | Watchdog enters `incompatible`; user restarts app (triggers clean daemon respawn with new binary) |
| Corrupted daemon binary | Disk error or incomplete download | Daemon fails to start; no IPC connection within 10s | Watchdog enters `degraded` after 3 retries; re-install required |
| Intentional rollback | Explicit user action via re-install | Clean — rollback replaces both app and daemon atomically | No skew; version handshake matches |

**Fail-closed guarantee:** Version skew ALWAYS results in a user-visible error state (`incompatible` or `degraded`). Transfer UI MUST remain disabled until a matching app+daemon pair is running (W-01).

#### N4-R3: Update/Rollback Model

Derived from N0 D0.7 and N1-T6.

**Update semantics:**

| Aspect | Specification | Normative |
|--------|--------------|-----------|
| Update unit | Whole bundle (app + daemon binary together) | REQUIRED (N0 D0.7) |
| Update mechanism | Platform-native installer replaces full bundle | REQUIRED |
| Pre-update check | If daemon is running: initiate shutdown (N3-W4) before update proceeds | REQUIRED |
| Active transfer guard | Warn user if transfer is in progress before allowing update | REQUIRED (N3-W4) |
| Post-update | App restarts, spawns new daemon from updated bundle, watchdog enters `starting` | REQUIRED |

**Rollback semantics:**

| Aspect | Specification | Normative |
|--------|--------------|-----------|
| Rollback unit | Whole bundle (app + daemon binary together) | REQUIRED |
| Rollback mechanism | Re-install previous version bundle via platform-native installer | REQUIRED |
| Data preservation | Identity keys, TOFU pins, and user preferences MUST survive rollback | REQUIRED (N0 D0.6) |
| Transient state | Active transfers, sessions, and daemon runtime state are lost on rollback | EXPECTED (N0 D0.6) |
| Socket/PID cleanup | Stale socket and PID file cleaned by watchdog on next launch (N3-W3) | REQUIRED |

**Rollback triggers (when to recommend rollback):**

| Trigger | Severity | Action |
|---------|----------|--------|
| Daemon crash loop on new version (3 retries exhausted → `degraded`) | High | Rollback to previous bundle |
| Version mismatch after whole-bundle update (should not occur) | High | Re-install; if persists, rollback |
| Transfer regression (transfers fail that worked in previous version) | Medium | Verify with clean re-install first; rollback if regression confirmed |
| UI regression (non-transfer functionality broken) | Low | Report bug; rollback optional |

**Rollback verification checklist:**

- [ ] Previous version bundle installs cleanly over current version
- [ ] App launches and spawns daemon from rolled-back binary
- [ ] Watchdog reaches `ready` state (requires B-DEP-N2-1 resolved)
- [ ] Identity key and TOFU pins still present and valid at N1-T4 paths
- [ ] File transfer completes successfully
- [ ] No stale socket/PID artifacts from failed version

#### N4-R4: Migration Strategy

**Context:** Current localbolt-app has no daemon integration. Migration is purely additive — adding daemon bundling to an app that previously had none. There is no existing daemon configuration, data, or state to migrate.

**Migration path:**

| Step | Description | User Impact | Data Safety |
|------|------------|-------------|-------------|
| 1. Bundle update | User installs new localbolt-app version containing bundled daemon | Standard app update flow; no additional user action required | No data loss — existing app-only data (if any) preserved |
| 2. First launch | App detects no existing daemon socket/PID; spawns daemon for first time | Brief "Starting connection service..." status during daemon initialization | No data risk — fresh daemon state |
| 3. Directory creation | App creates platform-appropriate directories per N1-T4 (identity, pins, logs, config) | Invisible to user | New directories only; no existing data touched |
| 4. Identity generation | Daemon generates fresh identity keypair on first run | User may need to re-pair with previously known peers (if any existed via app-level pairing) | Identity key stored at N1-T4 path; TOFU pins directory created empty |
| 5. Operational | App enters normal daemon-supervised mode | "Ready" status; transfer UI enabled | — |

**Migration invariants:**

| ID | Invariant | Normative |
|----|-----------|-----------|
| M-01 | Migration MUST NOT delete or modify any pre-existing user data | REQUIRED |
| M-02 | Migration MUST be transparent to the user (no migration wizard or manual steps) | REQUIRED |
| M-03 | App MUST function in degraded mode if daemon fails to start on first migration launch | REQUIRED |
| M-04 | Created directories MUST follow N1-T4 platform-appropriate paths | REQUIRED |
| M-05 | Created directories MUST have N1-T5 permissions (owner-only) | REQUIRED |

**Future migration note (not in N4 scope):** If localbolt-app later stores identity keys at app level, migration from app-level to daemon-level key store would require a one-time key migration step. This is NOT part of current N4 scope because current localbolt-app does not persist identity keys at the daemon level. Multi-version config format migration is B-STREAM ownership.

#### N4-R5: Blocker-Aware Gating

**Dependency integration matrix:**

| B-DEP | Description | Blocks Stage(s) | What Can Proceed | Unblock Owner |
|-------|-------------|-----------------|-----------------|---------------|
| B-DEP-N2-1 | `daemon.status` in default mode | Alpha, Beta, GA | Local/Dev (degraded mode); packaging infra; migration UX; failure-injection tests | B-STREAM |
| B-DEP-N2-2 | `version.handshake` + `version.status` messages | Beta, GA | Local/Dev; Alpha (without version gating) | B-STREAM |
| B-DEP-N1-1 | `--socket-path` / `--data-dir` CLI flags | GA | Local/Dev; Alpha; Beta (default paths acceptable) | B-STREAM |
| B-DEP-N2-3 | Windows named pipe support | Windows GA only | All stages for macOS/Linux; Windows Local/Dev + Alpha + Beta via WSL or deferred | B-STREAM |

**Rollout cannot-progress decision tree:**

```
Can we enter Local/Dev?
  → YES (no B-DEP blocks Local/Dev)

Can we enter Alpha?
  → Is B-DEP-N2-1 resolved? → YES → proceed
                              → NO  → STOP: cannot validate readiness detection

Can we enter Beta?
  → Is B-DEP-N2-1 resolved? → NO → STOP (Alpha gate)
  → Is B-DEP-N2-2 resolved? → YES → proceed
                              → NO  → STOP: cannot validate version safety

Can we enter GA?
  → Is B-DEP-N2-1 resolved? → NO → STOP (Alpha gate)
  → Is B-DEP-N2-2 resolved? → NO → STOP (Beta gate)
  → Is B-DEP-N1-1 resolved? → NO → STOP: cannot ship production paths
  → Is B-DEP-N2-3 resolved? → NO → Windows GA blocked (macOS/Linux GA can proceed)
  → All resolved → proceed to GA
```

#### N4 Acceptance Checklist (for N5 harness)

- [ ] AC-N4-1: App functions in degraded mode when daemon binary is missing from bundle
- [ ] AC-N4-2: App functions in degraded mode when daemon fails to start (e.g., permission denied)
- [ ] AC-N4-3: Whole-bundle update replaces both app and daemon atomically
- [ ] AC-N4-4: Whole-bundle rollback restores previous app+daemon version with data preserved
- [ ] AC-N4-5: Version skew between app and daemon detected via IPC handshake and reported to user (BLOCKED: B-DEP-N2-2)
- [ ] AC-N4-6: First-time migration from non-daemon app creates correct data directories with correct permissions
- [ ] AC-N4-7: Existing app user data (if any) preserved during migration to daemon-bundled version

---

### N5 — Acceptance Harness (Specification)

**Status:** DONE (spec locked)
**Tag:** `ecosystem-v0.1.76-n-stream-1-n4-n5-lock`
**Date:** 2026-03-07
**Scope:** Complete acceptance harness for N-STREAM-1 execution (N6) and closure (N7). Incorporates all AC-N1/AC-N2/AC-N3/AC-N4 checks into tiered, blocker-aware test matrix. Spec-only — no test implementation code.
**Dependencies consumed:** N1 (AC-N1-1 through AC-N1-11), N2 (AC-N2-1 through AC-N2-11), N3 (AC-N3-1 through AC-N3-15), N4 (AC-N4-1 through AC-N4-7, rollout stage gates)

#### N5-H1: Test Domains

| Domain | Description | Acceptance Checks | Primary Phase Source |
|--------|------------|-------------------|---------------------|
| D1: Packaging integrity | Daemon binary presence, executability, platform-correct paths, code signing | AC-N1-1, AC-N1-2, AC-N1-8, AC-N1-10, AC-N1-11 | N1 |
| D2: Process lifecycle/supervision | Watchdog state machine, spawn, shutdown, retry/backoff, stale cleanup | AC-N3-1, AC-N3-4, AC-N3-5, AC-N3-6, AC-N3-7, AC-N3-8, AC-N3-9, AC-N3-13, AC-N3-15 | N3 |
| D3: IPC readiness + compatibility | Socket creation, version handshake, readiness signal, permissions | AC-N1-3, AC-N1-4, AC-N2-1, AC-N2-2, AC-N2-3, AC-N2-4, AC-N3-2, AC-N3-3 | N1, N2, N3 |
| D4: IPC message contract | Stable message delivery, decision correlation, timeouts, forward compatibility | AC-N2-5, AC-N2-6, AC-N2-7, AC-N2-8, AC-N2-9, AC-N2-10, AC-N2-11 | N2 |
| D5: Degraded/incompatible UX | Degraded mode entry, transfer UI gating, version mismatch UX | AC-N3-14, AC-N4-1, AC-N4-2, AC-N4-5 | N3, N4 |
| D6: Update/rollback | Whole-bundle update, rollback with data preservation | AC-N4-3, AC-N4-4 | N4 |
| D7: Logging/diagnostics/support | stderr capture, crash snapshots, support bundle, log tokens | AC-N3-10, AC-N3-11, AC-N3-12, AC-N3-15 | N3 |
| D8: Data safety + migration | Identity key persistence, data directory creation, migration safety, permission model | AC-N1-5, AC-N1-6, AC-N1-7, AC-N1-9, AC-N4-6, AC-N4-7 | N1, N4 |

Note: AC-N3-15 appears in both D2 and D7 (lifecycle logging is cross-cutting). Each check has exactly one canonical tier assignment below.

#### N5-H2: Test Tiers

**Tier 1 — Smoke** (quick, <30s total, run on every build)

Validates basic packaging and spawn functionality. Failure in any smoke test blocks all higher tiers.

| ID | Check | Domain | Blocked By |
|----|-------|--------|------------|
| AC-N1-1 | Daemon binary present in app bundle at platform-correct path | D1 | — |
| AC-N1-2 | Daemon binary executable and runs (exits 1 with usage line) | D1 | — |
| AC-N1-3 | Socket created at platform-correct path after daemon spawn | D3 | — |
| AC-N1-5 | PID file created at platform-correct path | D8 | — |
| AC-N1-8 | Daemon runs without elevated privileges | D1 | — |
| AC-N2-1 | App connects to daemon socket within 10s of spawn | D3 | — |
| AC-N3-14 | Transfer UI disabled in all non-ready states | D5 | — |
| AC-N4-1 | App functions in degraded mode when daemon binary is missing | D5 | — |

**Count:** 8 checks. **Blocked:** 0.

**Tier 2 — Integration** (IPC flow + lifecycle, <5min total)

Validates full IPC contract and watchdog lifecycle. Requires daemon binary and IPC connectivity.

| ID | Check | Domain | Blocked By |
|----|-------|--------|------------|
| AC-N1-4 | Socket has `0600` permissions (Unix) or equivalent (Windows) | D3 | — |
| AC-N1-6 | Identity key persists at platform-correct path across app restart | D8 | — |
| AC-N1-7 | App and daemon report identical version in IPC handshake | D8 | B-DEP-N2-2 |
| AC-N1-9 | No writes outside data-dir and runtime-dir | D8 | — |
| AC-N2-2 | Version handshake completes as first message exchange | D3 | B-DEP-N2-2 |
| AC-N2-3 | Version mismatch produces fail-closed error (connection terminated) | D3 | B-DEP-N2-2 |
| AC-N2-4 | `daemon.status` received after successful version handshake | D3 | B-DEP-N2-1 |
| AC-N2-5 | `pairing.request` event delivered to app with all required fields | D4 | — |
| AC-N2-6 | `pairing.decision` accepted by daemon with correct request_id correlation | D4 | — |
| AC-N2-7 | `transfer.incoming.request` event delivered with all required fields | D4 | — |
| AC-N2-8 | `transfer.incoming.decision` accepted by daemon | D4 | — |
| AC-N2-9 | Decision timeout (30s) results in fail-closed deny | D4 | — |
| AC-N2-10 | Unknown message types silently dropped (forward-compatible) | D4 | — |
| AC-N2-11 | Extra payload fields preserved through roundtrip | D4 | — |
| AC-N3-1 | Watchdog transitions through all 5 states correctly | D2 | B-DEP-N2-1 + B-DEP-N2-2 (partial: 3/5 states testable) |
| AC-N3-2 | `starting → ready` transition on `daemon.status` receipt | D3 | B-DEP-N2-1 |
| AC-N3-3 | `starting → incompatible` on version mismatch | D3 | B-DEP-N2-2 |
| AC-N3-8 | Stale socket detected and removed before respawn | D2 | — |
| AC-N3-9 | PID file written after spawn, cleaned on shutdown/stale detection | D2 | — |
| AC-N3-10 | Daemon stderr captured in ring buffer (minimum 500 lines) | D7 | — |
| AC-N3-13 | SIGTERM + 5s grace + SIGKILL shutdown sequence | D2 | — |
| AC-N3-15 | Status transitions logged with `[WATCHDOG]` token | D2 | — |
| AC-N4-2 | App functions in degraded mode when daemon fails to start | D5 | — |
| AC-N4-5 | Version skew detected via IPC handshake and reported to user | D5 | B-DEP-N2-2 |
| AC-N4-6 | First-time migration creates correct data directories with permissions | D8 | — |
| AC-N4-7 | Existing app user data preserved during migration | D8 | — |

**Count:** 26 checks. **Blocked:** 7 (AC-N1-7, AC-N2-2, AC-N2-3, AC-N2-4, AC-N3-1 partial, AC-N3-2, AC-N3-3, AC-N4-5).

**Tier 3 — Failure Injection** (<10min total)

Validates crash recovery, degraded mode transitions, and rollback. Requires ability to kill daemon process and inject failures.

| ID | Check | Domain | Blocked By |
|----|-------|--------|------------|
| AC-N3-4 | Crash triggers retry with correct backoff (1s, 3s, 10s) | D2 | — |
| AC-N3-5 | 3 consecutive crashes → `degraded` state | D2 | — |
| AC-N3-6 | Retry counter resets after 60s continuous `ready` | D2 | B-DEP-N2-1 |
| AC-N3-7 | Manual restart from `degraded` resets counter and transitions to `starting` | D2 | — |
| AC-N3-11 | Crash snapshot written to log directory with `[DAEMON_CRASH]` token | D7 | — |
| AC-N3-12 | Support bundle export includes all required items, excludes sensitive data | D7 | — |
| AC-N4-3 | Whole-bundle update replaces both app and daemon atomically | D6 | — |
| AC-N4-4 | Whole-bundle rollback restores previous version with data preserved | D6 | — |

**Count:** 8 checks. **Blocked:** 1 (AC-N3-6).

**Tier 4 — Pre-Release Gate** (GA-only, requires signed builds)

Validates code signing, notarization, and platform-specific GA requirements. Run only before GA release.

| ID | Check | Domain | Blocked By |
|----|-------|--------|------------|
| AC-N1-10 | macOS `.app` contains signed daemon binary | D1 | — |
| AC-N1-11 | Windows installer contains signed daemon `.exe` | D1 | — |

**Count:** 2 checks. **Blocked:** 0.

**Tier summary:** 44 total checks (T1: 8, T2: 26, T3: 8, T4: 2). 9 currently blocked by B-DEPs (8 full + 1 partial).

#### N5-H3: Pass/Fail Criteria

**Hard fail (blocks progression to next rollout stage):**

| Condition | Effect | Evidence Required |
|-----------|--------|-------------------|
| Any Tier 1 (smoke) check fails | Blocks all higher tiers and all rollout stages | Test output showing failure + error message |
| Any unblocked Tier 2 check fails | Blocks Alpha+ entry | Test output + relevant log excerpts |
| Any unblocked Tier 3 check fails | Blocks Beta+ entry | Test output + crash logs + watchdog state trace |
| Any Tier 4 check fails | Blocks GA entry | Signing tool output + build artifact manifest |
| Previously-blocked check fails AFTER its B-DEP is resolved | Same as unblocked failure for that tier | Test output + B-DEP resolution evidence |

**Soft fail (does not block progression, requires tracking):**

| Condition | Effect | Evidence Required |
|-----------|--------|-------------------|
| Blocked check fails while its B-DEP is STILL OPEN | Expected — not a regression | Log that check was skipped with B-DEP ID reference |
| Performance degradation (daemon startup > 5s but < 10s timeout) | Track but do not block | Timing measurements across 10 runs |
| Non-functional cosmetic issue (UX text, icon rendering) | Track as bug, do not block | Screenshot |

**Tier progression rule:** Tier N+1 MUST NOT execute if any hard-fail exists in Tier N. Tiers execute sequentially: Smoke → Integration → Failure Injection → Pre-Release.

#### N5-H4: Blocker-Aware Execution Rules

**Currently blocked checks (by B-DEP):**

| Check ID | Description | Blocked By | Temporary Status | Unblock Condition | Owner |
|----------|------------|------------|-----------------|-------------------|-------|
| AC-N1-7 | Version match in IPC handshake | B-DEP-N2-2 | SKIP | `version.handshake` + `version.status` implemented in daemon | B-STREAM |
| AC-N2-2 | Version handshake completes first | B-DEP-N2-2 | SKIP | `version.handshake` + `version.status` implemented | B-STREAM |
| AC-N2-3 | Version mismatch fail-closed | B-DEP-N2-2 | SKIP | `version.status` with `compatible: false` implemented | B-STREAM |
| AC-N2-4 | `daemon.status` after handshake | B-DEP-N2-1 | SKIP | `daemon.status` emitted in default mode on client connect | B-STREAM |
| AC-N3-1 | All 5 watchdog states | B-DEP-N2-1 + N2-2 | PARTIAL (3/5 states testable: starting, restarting, degraded) | Both B-DEPs resolved for full 5/5 | B-STREAM |
| AC-N3-2 | `starting → ready` transition | B-DEP-N2-1 | SKIP | `daemon.status` in default mode | B-STREAM |
| AC-N3-3 | `starting → incompatible` | B-DEP-N2-2 | SKIP | `version.status` with mismatch handling | B-STREAM |
| AC-N3-6 | Retry reset after 60s ready | B-DEP-N2-1 | SKIP | Cannot reach `ready` without readiness signal | B-STREAM |
| AC-N4-5 | Version skew detection | B-DEP-N2-2 | SKIP | Version handshake messages implemented | B-STREAM |

**Execution rules:**

1. Blocked checks MUST be attempted during test runs but MUST report `SKIP(B-DEP-<ID>)` status, not `FAIL`.
2. When a B-DEP is resolved, ALL checks blocked by that B-DEP MUST be re-executed in the next test run.
3. A check transitions from `SKIP` to `PASS`/`FAIL` only after its blocking B-DEP is resolved.
4. If a check fails AFTER its blocker is resolved, it is treated as a hard fail for its tier.
5. Test runner MUST log: `[HARNESS] SKIP AC-<ID>: blocked by <B-DEP-ID> (still open)`

**B-DEP unblock → check cascade:**

| B-DEP Resolved | Resolution Evidence | Checks Unblocked |
|----------------|-------------------|-----------------|
| B-DEP-N2-1 | Daemon emits `daemon.status` on client connect in default mode; verified by AC-N2-4 passing | AC-N2-4, AC-N3-1 (full 5/5), AC-N3-2, AC-N3-6 |
| B-DEP-N2-2 | Daemon accepts `version.handshake` and responds with `version.status`; verified by AC-N2-2 passing | AC-N1-7, AC-N2-2, AC-N2-3, AC-N3-1 (full 5/5), AC-N3-3, AC-N4-5 |

#### N5-H5: Evidence Contract

**Required evidence artifacts per check:**

| Artifact Type | Required For | Format | Retention |
|--------------|-------------|--------|-----------|
| Test runner output (stdout/stderr) | All checks | Plain text with per-check PASS/FAIL/SKIP status | Until N7 closure |
| Watchdog state trace log | D2 checks (lifecycle) | `[WATCHDOG]` token grep from app logs | Until N7 closure |
| Daemon stderr capture | D7 checks (diagnostics) | Plain text from ring buffer dump | Until N7 closure |
| Crash snapshot file | AC-N3-11, AC-N3-12 | File at `{log_dir}/daemon-crash-{timestamp}.log` | Until N7 closure |
| Support bundle archive | AC-N3-12 | Archive containing 6 required items per N3-W5 | Until N7 closure |
| Platform/OS/arch identifier | All checks | Reported in test runner header | Until N7 closure |
| Build artifact manifest | Tier 4 (pre-release) | List of files in bundle with sizes and SHA-256 hashes | Until N7 closure |
| Signing verification output | AC-N1-10, AC-N1-11 | `codesign -v` (macOS), `signtool verify` (Windows) output | Until N7 closure |
| Screenshot | UX-related soft fails only | PNG with annotation | Until N7 closure |

**CI-automatable vs human-review-required:**

| Category | Checks | Method |
|----------|--------|--------|
| CI-automatable (no human judgment) | AC-N1-1, AC-N1-2, AC-N1-3, AC-N1-4, AC-N1-5, AC-N1-8, AC-N1-9, AC-N2-1, AC-N2-4, AC-N2-5, AC-N2-6, AC-N2-7, AC-N2-8, AC-N2-9, AC-N2-10, AC-N2-11, AC-N3-4, AC-N3-5, AC-N3-8, AC-N3-9, AC-N3-10, AC-N3-13, AC-N3-15, AC-N4-1, AC-N4-2, AC-N4-6 | Script / CI pipeline |
| CI-automatable after B-DEP resolution | AC-N1-7, AC-N2-2, AC-N2-3, AC-N3-1, AC-N3-2, AC-N3-3, AC-N3-6, AC-N3-7, AC-N4-5 | Script / CI pipeline (after B-DEP resolution) |
| Human-review-required | AC-N1-6, AC-N1-10, AC-N1-11, AC-N3-11, AC-N3-12, AC-N3-14, AC-N4-3, AC-N4-4, AC-N4-7 | Manual with evidence capture |

**Artifact retention policy:**
- All evidence artifacts MUST be retained until N7 (closure) is marked DONE.
- After N7 closure, artifacts MAY be archived or deleted per project retention policy.
- Evidence MUST be traceable: each artifact references the check ID, run timestamp, platform, and app+daemon version.

**Traceability requirements:**
- Each test run MUST produce a summary report: run ID (timestamp-based), platform, app version, daemon version, per-check status (PASS/FAIL/SKIP with reason), and artifact paths.
- Summary reports MUST be committed to `localbolt-app` repo under `tests/acceptance/runs/` (or equivalent, determined during N6).

#### N5-I1: AC-N1/AC-N2/AC-N3/AC-N4 Incorporation Table

All 44 acceptance checks from N1–N4 are incorporated into N5 tiers. No contradiction or duplication.

| Source Check | N5 Tier | N5 Domain | Blocked By | Notes |
|-------------|---------|-----------|------------|-------|
| AC-N1-1 | T1 (Smoke) | D1 | — | |
| AC-N1-2 | T1 (Smoke) | D1 | — | |
| AC-N1-3 | T1 (Smoke) | D3 | — | |
| AC-N1-4 | T2 (Integration) | D3 | — | |
| AC-N1-5 | T1 (Smoke) | D8 | — | |
| AC-N1-6 | T2 (Integration) | D8 | — | Human-review |
| AC-N1-7 | T2 (Integration) | D8 | B-DEP-N2-2 | |
| AC-N1-8 | T1 (Smoke) | D1 | — | |
| AC-N1-9 | T2 (Integration) | D8 | — | |
| AC-N1-10 | T4 (Pre-Release) | D1 | — | GA-only |
| AC-N1-11 | T4 (Pre-Release) | D1 | — | GA-only |
| AC-N2-1 | T1 (Smoke) | D3 | — | |
| AC-N2-2 | T2 (Integration) | D3 | B-DEP-N2-2 | |
| AC-N2-3 | T2 (Integration) | D3 | B-DEP-N2-2 | |
| AC-N2-4 | T2 (Integration) | D3 | B-DEP-N2-1 | |
| AC-N2-5 | T2 (Integration) | D4 | — | |
| AC-N2-6 | T2 (Integration) | D4 | — | |
| AC-N2-7 | T2 (Integration) | D4 | — | |
| AC-N2-8 | T2 (Integration) | D4 | — | |
| AC-N2-9 | T2 (Integration) | D4 | — | |
| AC-N2-10 | T2 (Integration) | D4 | — | |
| AC-N2-11 | T2 (Integration) | D4 | — | |
| AC-N3-1 | T2 (Integration) | D2 | B-DEP-N2-1 + N2-2 (partial) | 3/5 states testable without B-DEPs |
| AC-N3-2 | T2 (Integration) | D3 | B-DEP-N2-1 | |
| AC-N3-3 | T2 (Integration) | D3 | B-DEP-N2-2 | |
| AC-N3-4 | T3 (Failure Inj.) | D2 | — | |
| AC-N3-5 | T3 (Failure Inj.) | D2 | — | |
| AC-N3-6 | T3 (Failure Inj.) | D2 | B-DEP-N2-1 | Cannot reach `ready` |
| AC-N3-7 | T3 (Failure Inj.) | D2 | — | |
| AC-N3-8 | T2 (Integration) | D2 | — | |
| AC-N3-9 | T2 (Integration) | D2 | — | |
| AC-N3-10 | T2 (Integration) | D7 | — | |
| AC-N3-11 | T3 (Failure Inj.) | D7 | — | Human-review |
| AC-N3-12 | T3 (Failure Inj.) | D7 | — | Human-review |
| AC-N3-13 | T2 (Integration) | D2 | — | |
| AC-N3-14 | T1 (Smoke) | D5 | — | |
| AC-N3-15 | T2 (Integration) | D2 | — | |
| AC-N4-1 | T1 (Smoke) | D5 | — | |
| AC-N4-2 | T2 (Integration) | D5 | — | |
| AC-N4-3 | T3 (Failure Inj.) | D6 | — | Human-review |
| AC-N4-4 | T3 (Failure Inj.) | D6 | — | Human-review |
| AC-N4-5 | T2 (Integration) | D5 | B-DEP-N2-2 | |
| AC-N4-6 | T2 (Integration) | D8 | — | |
| AC-N4-7 | T2 (Integration) | D8 | — | Human-review |

**Incorporation verification:**

| Source | Total | T1 | T2 | T3 | T4 | Verified |
|--------|------:|---:|---:|---:|---:|---------|
| AC-N1-* | 11 | 5 | 4 | 0 | 2 | 11 = 11 |
| AC-N2-* | 11 | 1 | 10 | 0 | 0 | 11 = 11 |
| AC-N3-* | 15 | 1 | 8 | 6 | 0 | 15 = 15 |
| AC-N4-* | 7 | 1 | 4 | 2 | 0 | 7 = 7 |
| **Total** | **44** | **8** | **26** | **8** | **2** | **44 = 44** |

No check is duplicated across tiers. No check contradicts its source phase definition. All 37 pre-existing checks (N1–N3) plus 7 new N4 checks are accounted for.

---

## DR-STREAM-1 — Double Ratchet Pre-ByteBolt Security Gate [SUPERSEDED]

> **Stream ID:** DR-STREAM-1
> **Backlog Item:** SEC-DR1
> **Priority:** ~~NEXT~~ → SUPERSEDED
> **Repos:** bolt-core-sdk (Rust + TS), bolt-protocol (spec amendment)
> **Codified:** ecosystem-v0.1.99-sec-dr1-p0-codify (2026-03-09)
> **Superseded:** ecosystem-v0.1.100-sec-btr1-replaces-dr (2026-03-09)
> **Status:** **SUPERSEDED-BY: BTR-STREAM-1** (SEC-BTR1). Frozen for traceability. No phases will execute.
>
> **Supersession rationale (PM-BTR-01 through PM-BTR-04, 2026-03-09):**
> The Double Ratchet algorithm (Signal protocol) is optimized for asynchronous bidirectional messaging
> with out-of-order delivery. Bolt is a file transfer protocol with ordered chunks, clear transfer
> boundaries, and unidirectional data flow per transfer. PM approved replacement architecture
> (BTR — Bolt Transfer Ratchet) that is purpose-built for file transfer semantics rather than
> adapting a messaging ratchet. DR-STREAM-1 P0 audit findings (codebase state, rendezvous opacity,
> shared-crate feasibility) are inherited by BTR-STREAM-1 and remain valid. All DR-STREAM-1 content
> below is frozen — not deleted — per governance immutability policy.

---

### Context & Motivation

Current Bolt protocol uses **static ephemeral keys per connection** with no mid-session key rotation (SEC-05). Each message within a session is encrypted with the same ephemeral shared secret, differentiated only by a fresh random nonce. This provides:

- **Session-level forward secrecy:** Ephemeral keys discarded on disconnect protect past sessions.
- **No intra-session forward secrecy:** Compromise of the ephemeral secret key during an active session exposes **all messages** in that session.
- **No backward secrecy:** No mechanism to recover from mid-session key compromise.

For **LocalBolt** (short-lived WebRTC sessions, typically minutes), this is acceptable. For **ByteBolt** (persistent relay-mediated connections, potentially hours/days), the security posture degrades significantly:

- Longer sessions increase the window of vulnerability for ephemeral key compromise.
- Relay-mediated transport adds an additional trust boundary (relay sees encrypted traffic).
- Persistent connections mean session-level rotation is insufficient.

**Double Ratchet** (or equivalent continuous key agreement protocol) provides:

- Per-message forward secrecy (compromise of message key N does not reveal message N-1).
- Self-healing after compromise (new DH ratchet step restores secrecy).
- Backward secrecy (future messages protected even if current state is compromised, after next DH ratchet).

This is a **pre-ByteBolt security gate**: ByteBolt development MUST NOT begin until DR-STREAM-1 reaches at minimum DR-4 (wire integration complete with backward-compatible negotiation).

---

### Scope Guardrails

| ID | Guardrail |
|----|-----------|
| DR-G1 | Browser retains native WebRTC transport — no browser webrtc-rs swap |
| DR-G2 | Ratchet layer MUST be transport-independent (Core, not Profile) |
| DR-G3 | Backward compatibility MUST be explicit, testable, and auditable |
| DR-G4 | No retroactive rewrites of completed streams |
| DR-G5 | No protocol-breaking changes without capability negotiation gate |
| DR-G6 | Rust is reference implementation; TS achieves parity via shared vectors |
| DR-G7 | Rendezvous server requires ZERO changes (confirmed opaque to payload) |
| DR-G8 | Consumer apps (localbolt, localbolt-app, localbolt-v3) are OUT OF SCOPE for DR-STREAM-1 |

---

### P0 Audit Summary (Read-Only)

#### bolt-core-sdk

**Rust (`rust/bolt-core/src/`):**
- `crypto.rs`: `KeyPair` (X25519), `seal_box_payload()` / `open_box_payload()` — NaCl box with fresh 24-byte random nonce per message. No KDF, no chain state. `Drop` impl volatile-zeros secret key.
- `identity.rs`: `IdentityKeyPair` (persistent, TOFU-pinned). No persistence logic in core — transport responsibility.
- `sas.rs`: `compute_sas()` — SHA-256 over sorted identity + ephemeral keys. Deterministic, commutative.
- `constants.rs`: `NONCE_LENGTH=24`, `PUBLIC_KEY_LENGTH=32`, `SECRET_KEY_LENGTH=32`, `BOX_OVERHEAD=16`, `BOLT_VERSION=1`, `CAPABILITY_NAMESPACE="bolt."`.
- `errors.rs`: 22 wire error codes (11 PROTOCOL + 11 ENFORCEMENT).

**TypeScript (`ts/bolt-core/src/` + `ts/bolt-transport-web/src/`):**
- `crypto.ts`: TweetNaCl `box.keyPair()`, same seal/open pattern as Rust. No explicit zeroization (done at WebRTCService disconnect level).
- `WebRTCService.ts`: Session state machine (`pre_hello` / `post_hello` / `closed`). Ephemeral `keyPair`, `remotePublicKey`, `remoteIdentityKey` — all nulled on disconnect.
- `HandshakeManager.ts`: HELLO exchange, TOFU verify, SAS compute, capability intersection. 5s timeout (SA10). Reentrancy guard (SA12).
- `EnvelopeCodec.ts`: ProfileEnvelopeV1 `{type: "profile-envelope", version: 1, encoding: "base64", payload: sealBoxPayload_output}`. Gated by `bolt.profile-envelope-v1` capability.

**Test Vectors (5 JSON files in `ts/bolt-core/__tests__/vectors/`):**
- `box-payload.vectors.json` (4 seal + 4 corrupt vectors)
- `envelope-open.vectors.json` (3 envelope round-trip cases)
- `sas.vectors.json` (2 SAS determinism cases)
- `web-hello-open.vectors.json` (1 HELLO open case)
- `framing.vectors.json` (wire format layout)

**Cross-language model:** TS generates vectors → JSON → Rust loads via serde. S1 conformance harness (27 tests) verifies parity.

#### bolt-protocol

- **Envelope wire format:** `senderEphemeralKey` (32B cleartext), `nonce` (24B), `ciphertext` (variable). Receiver needs sender ephemeral key before decryption.
- **HELLO payload (encrypted):** `bolt_version`, `identity_key`, `capabilities[]`, `encoding`, optional `limits`.
- **Capability negotiation:** Intersection model. Unknown capabilities ignored. Immutable after HANDSHAKE_COMPLETE.
- **No ratchet in v1.** PROTOCOL.md Appendix B notes: "v2 will define explicit KEY_ROTATE messages with SAS confirmation."
- **Key constraint:** Ephemeral keys "MUST NOT be rotated mid-session in v1" (§3.3).

#### bolt-daemon

- `session.rs`: `SessionContext` holds `local_keypair: KeyPair`, `remote_public_key`, `negotiated_capabilities`, `hello_state`.
- Imports `bolt-core` (path dep) and `bolt-rendezvous-protocol` (git tag dep `rendezvous-v0.2.6-clean-1`).
- **Shared ratchet crate feasibility: HIGH.** Architecture supports `bolt-core-sdk/rust/bolt-ratchet` as new workspace member consumed by both SDK and daemon.
- Version: `daemon-v0.2.38`, 362 tests, Phase REL-ARCH1 complete.

#### bolt-rendezvous

- **Fully opaque to envelope contents.** `Signal { to, payload: serde_json::Value }` — payload passed through unchanged. Zero crypto operations. Zero format assumptions.
- **CONFIRMED: No rendezvous changes needed for DR-STREAM-1.**
- Version: `rendezvous-v0.2.12-dp5-session-guard`, 49 tests.

---

### DR-STREAM-1 Phase Table

| Phase | Description | Serial Gate | Dependencies | Parallelizable With | Status |
|-------|-------------|-------------|--------------|---------------------|--------|
| **DR-0** | Spec + capability negotiation lock | YES — gates all subsequent phases | None (independent) | — | NOT-STARTED |
| **DR-1** | Rust reference ratchet state machine | YES — gates DR-2, DR-3 | DR-0 complete | — | NOT-STARTED |
| **DR-2** | TypeScript parity implementation | NO | DR-1 complete (vectors available) | DR-3 (partial — can start harness while TS impl proceeds) | NOT-STARTED |
| **DR-3** | Cross-language vectors + conformance harness | NO | DR-1 complete | DR-2 (harness can scaffold before TS impl complete) | NOT-STARTED |
| **DR-4** | Wire integration + compatibility rollout gates | YES — gates ByteBolt start | DR-2 + DR-3 complete | — | NOT-STARTED |
| **DR-5** | Default-on + legacy path deprecation decision | PM decision gate | DR-4 deployed + burn-in data | — | NOT-STARTED |

#### Dependency DAG

```
DR-0 (spec lock)
  │
  ▼
DR-1 (Rust reference)
  │
  ├──────────────┐
  ▼              ▼
DR-2 (TS)    DR-3 (vectors)     ← partially parallelizable
  │              │
  └──────┬───────┘
         ▼
DR-4 (wire integration + rollout)
         │
         ▼
DR-5 (default-on decision)       ← PM gate, not engineering
```

**Serial gates:**
- DR-0 is a hard gate: no implementation may begin without locked spec.
- DR-1 is a hard gate: TS parity and vector corpus require Rust reference to exist.
- DR-4 is the **ByteBolt gate**: ByteBolt development blocked until DR-4 complete.
- DR-5 is a PM decision gate, not an engineering gate.

**Parallelization:**
- DR-2 and DR-3 are partially parallelizable after DR-1:
  - DR-3 conformance harness scaffolding can begin immediately after DR-1 (Rust vectors available).
  - DR-2 TS implementation can proceed in parallel with DR-3 harness setup.
  - DR-3 parity verification requires DR-2 completion.
  - Final DR-3 sign-off requires both DR-1 Rust and DR-2 TS implementations passing all vectors.

---

### Backward-Compatibility Policy

#### Capability Negotiation Matrix

| Sender DR Support | Receiver DR Support | Behavior | Security Level | Fail Mode |
|-------------------|---------------------|----------|----------------|-----------|
| YES | YES | Full double ratchet | Per-message FS + self-healing | — |
| YES | NO | **Downgrade to static ephemeral** | Session-level FS only (current v1) | Fail-open (downgrade-with-warning) |
| NO | YES | **Downgrade to static ephemeral** | Session-level FS only (current v1) | Fail-open (downgrade-with-warning) |
| NO | NO | Static ephemeral (current behavior) | Session-level FS only | — |
| YES | MALFORMED | **Reject + ERROR** | N/A | Fail-closed |
| MALFORMED | YES | **Reject + ERROR** | N/A | Fail-closed |

#### Downgrade Options Analysis

| Option | Description | Security Tradeoff | Recommendation |
|--------|-------------|-------------------|----------------|
| **A: Refuse** | Peers without DR capability cannot connect | Maximum security; breaks all existing clients immediately | **NOT RECOMMENDED** — too disruptive for phased rollout |
| **B: Downgrade-with-warning** | Fall back to static ephemeral; surface warning to user via `onVerificationState` | Users see reduced security indicator; connection still functions | **RECOMMENDED for DR-4** — enables phased rollout without breaking existing clients |
| **C: Silent-downgrade** | Fall back to static ephemeral; no user indication | Users unaware of reduced security | **NOT RECOMMENDED** — violates transparency principle; auditors cannot verify deployment state |

#### Phase-by-Phase Fail Mode

| Phase | Default Behavior | Rationale |
|-------|-----------------|-----------|
| DR-4 (dark launch) | Fail-open (downgrade-with-warning) | Enable testing with mixed fleet; no user disruption |
| DR-4 (opt-in) | Fail-open (downgrade-with-warning) | Early adopters can enable; non-adopters unaffected |
| DR-5 (default-on) | PM decision: fail-open or fail-closed | Trade-off between security enforcement vs backward compat |
| DR-5 (legacy deprecation) | Fail-closed (refuse non-DR peers) | Only after sufficient migration window; PM-approved |

#### Capability String

```
bolt.double-ratchet-v1
```

Follows existing `bolt.*` namespace convention (CAPABILITY_NAMESPACE constant). Negotiated via HELLO `capabilities[]` intersection — identical mechanism to `bolt.file-hash` and `bolt.profile-envelope-v1`.

---

### Wire Delta Summary

#### Current Envelope (ProfileEnvelopeV1)

```json
{
  "type": "profile-envelope",
  "version": 1,
  "encoding": "base64",
  "payload": "<base64(nonce[24] || ciphertext[N+16])>"
}
```

**Overhead per message:** 24 bytes nonce + 16 bytes Poly1305 MAC = 40 bytes crypto overhead.

#### Proposed DR Envelope (ProfileEnvelopeV2 — name TBD at DR-0)

```json
{
  "type": "profile-envelope",
  "version": 2,
  "encoding": "base64",
  "dh": "<base64(ratchet_public_key[32])>",
  "pn": <previous_chain_length>,
  "n": <message_number>,
  "payload": "<base64(nonce[24] || ciphertext[N+16])>"
}
```

**New fields:**

| Field | Type | Size | Purpose |
|-------|------|------|---------|
| `dh` | base64 string | 32 bytes (44 chars encoded) | Current ratchet public key (DH ratchet step) |
| `pn` | uint32 | 4 bytes (JSON number) | Previous sending chain length (enables out-of-order decryption) |
| `n` | uint32 | 4 bytes (JSON number) | Message number in current sending chain |

**Overhead delta per message:**

| Component | Current | DR | Delta |
|-----------|---------|-----|-------|
| Crypto overhead | 40 B | 40 B | 0 (same NaCl box) |
| Wire header | ~95 B JSON | ~175 B JSON | +~80 B |
| `dh` field | — | 44 B (base64) + key | +~50 B |
| `pn` field | — | 1–5 B (JSON int) | +~8 B |
| `n` field | — | 1–5 B (JSON int) | +~6 B |
| `version` field | `1` | `2` | 0 B |

**Estimated per-message overhead increase:** ~80 bytes JSON (~4% increase on a typical 2KB file chunk message). Negligible for file transfer workload.

#### What Remains Unchanged

| Component | Change? | Notes |
|-----------|---------|-------|
| NaCl box algorithm (XSalsa20-Poly1305) | NO | Same AEAD primitive; message key changes, not algorithm |
| Nonce generation (24B CSPRNG) | NO | Same nonce strategy per sealed payload |
| HELLO message format | MINOR | Add `bolt.double-ratchet-v1` to capabilities array |
| SAS computation | NO | Still binds identity + ephemeral keys; ratchet keys NOT in SAS |
| TOFU pinning | NO | Identity keys unchanged; ratchet keys are session-internal |
| Identity key lifecycle | NO | Persistent, TOFU-pinned (unchanged) |
| Signaling/rendezvous protocol | NO | Opaque relay — confirmed zero changes |
| Error codes | MINOR | Add 2-3 new ratchet-specific error codes |
| Ping/Pong (unprotected) | NO | Remain outside envelope |

#### Versioning Strategy

- **Envelope version bump:** `version: 1` → `version: 2` in ProfileEnvelopeV1/V2.
- **Backward compat:** Peers negotiating `bolt.double-ratchet-v1` use version 2 envelopes. Peers without the capability continue using version 1.
- **No major protocol version bump required.** Capability negotiation handles the transition without changing `bolt_version` in HELLO.

---

### Key Material Storage Impact

#### Current Key State (v1)

| Key Material | Persisted? | Location | Protection |
|--------------|-----------|----------|------------|
| Identity keypair | YES | IndexedDB (browser), `~/.bolt/identity.key` (daemon) | Per-origin (browser), 0600 (daemon) |
| Ephemeral session keypair | NO (memory only) | Process memory | Volatile-zeroed on Drop (Rust), loop-zeroed on disconnect (TS) |
| Remote ephemeral public key | NO (memory only) | Process memory | Zeroed on disconnect |
| Remote identity public key | NO (memory only) | Process memory | Zeroed on disconnect |
| TOFU pin store | YES | IndexedDB (browser), `~/.bolt/pins/` (daemon) | Per-origin (browser), 0600 (daemon) |

#### DR Ratchet State (New — Must Persist Per Active Session)

| Key Material | Must Persist? | Lifetime | Size | Sensitivity |
|--------------|--------------|----------|------|-------------|
| Root key (RK) | YES (if session persistence desired) | Per DH ratchet step | 32 B | HIGH — derives all chain keys |
| Sending chain key (CKs) | YES (if session persistence desired) | Per sending chain | 32 B | HIGH — derives message keys |
| Receiving chain key (CKr) | YES (if session persistence desired) | Per receiving chain | 32 B | HIGH — derives message keys |
| Sending ratchet keypair | YES (if session persistence desired) | Per DH ratchet step | 64 B (pub+sec) | CRITICAL — ratchet DH secret |
| Message counter (Ns) | YES | Per sending chain | 4 B | LOW |
| Message counter (Nr) | YES | Per receiving chain | 4 B | LOW |
| Previous chain length (PN) | YES | Per DH ratchet step | 4 B | LOW |
| Skipped message keys | YES (bounded buffer) | Until consumed or evicted | 32 B × max_skip | HIGH — decrypt out-of-order messages |

**Total per-session ratchet state:** ~200 B base + (32 B × `MAX_SKIP`) for skipped keys.

#### Interaction with Existing Invariants

| Invariant | Impact | Resolution |
|-----------|--------|------------|
| **SEC-04** (ephemeral secret keys MUST NOT be persisted to disk) | **TENSION** — ratchet DH secret is ephemeral-like but may need persistence for session resumption | **Decision required (PM-DR-03):** Option A: ratchet state is memory-only (no session resumption — matches current SEC-04 strictly). Option B: ratchet state is persisted with equivalent protection to identity key (file-based, 0600, encrypted-at-rest). |
| **SEC-05** (ephemeral keys MUST be discarded on disconnection) | **COMPATIBLE** — ratchet state can be discarded on disconnect (fresh ratchet on reconnect, same as fresh ephemeral today) | If session resumption is NOT a goal, SEC-05 applies unchanged. Ratchet state zeroed on disconnect. |
| **SEC-01** (fresh CSPRNG nonce per envelope) | **UNCHANGED** — nonce generation is independent of ratchet | No impact. |
| **SEC-03** (fresh ephemeral keypair per connection) | **MODIFIED** — initial ephemeral keypair bootstraps the ratchet; subsequent DH ratchet steps generate new keypairs mid-session | Spec must clarify: initial keypair is per-connection (SEC-03 preserved). Ratchet keypairs are per-DH-step (new invariant). |

#### Storage Location & Protection

| Platform | Ratchet State Location | Protection | Cleanup |
|----------|----------------------|------------|---------|
| Browser (TS) | Memory only (no IndexedDB) | GC on tab close; explicit zero on disconnect | Disconnect handler zeros all ratchet state |
| Daemon (Rust) | Memory only (no disk) | `Drop` impl volatile-zeros | Process exit or session disconnect |
| Future (session resumption) | TBD — requires PM-DR-03 decision | Encrypted-at-rest, 0600, per-session file | Explicit cleanup on session close + TTL expiry |

**Recommendation:** Start with **memory-only ratchet state** (no persistence). This preserves SEC-04/SEC-05 invariants exactly. Session resumption (persisted ratchet state) is a future enhancement that requires separate PM approval and security review.

---

### Test / Vector Strategy

#### Vector Corpus Format

| Field | Value |
|-------|-------|
| Format | JSON (matching existing `__tests__/vectors/*.vectors.json` pattern) |
| Ownership | Generated by **Rust reference** (DR-1), consumed by both Rust and TS |
| Location | `bolt-core-sdk/rust/bolt-core/test-vectors/ratchet/` (source of truth) |
| TS copy | `bolt-core-sdk/ts/bolt-core/__tests__/vectors/ratchet/` (generated, not hand-authored) |
| Generation script | `bolt-core-sdk/rust/bolt-core/src/bin/generate-ratchet-vectors.rs` |

**Note:** This reverses the current TS-generates-vectors model (per SEC-CORE2 direction: Rust becomes vector authority).

#### Vector Categories

| Category | Purpose | Minimum Count |
|----------|---------|---------------|
| `ratchet-init.vectors.json` | Root key derivation from initial DH | 3 |
| `ratchet-symmetric.vectors.json` | Symmetric ratchet step (CK → MK derivation) | 5 |
| `ratchet-dh-step.vectors.json` | DH ratchet step (new keypair, root key update) | 4 |
| `ratchet-encrypt-decrypt.vectors.json` | Full message encrypt/decrypt with ratchet state | 6 |
| `ratchet-out-of-order.vectors.json` | Skipped message key recovery | 4 |
| `ratchet-state-serialization.vectors.json` | Ratchet state serialize/deserialize determinism | 3 |
| `ratchet-error.vectors.json` | Corrupt/invalid ratchet messages | 5 |
| `ratchet-interop.vectors.json` | Cross-language round-trip (Rust seal → TS open, TS seal → Rust open) | 4 |

#### Parity Matrix

| Test Type | Rust | TS | Cross-Language |
|-----------|------|-----|----------------|
| Unit (ratchet SM) | DR-1 | DR-2 | — |
| Vector determinism | DR-1 | DR-2 | DR-3 |
| Interop (seal/open) | DR-3 | DR-3 | DR-3 (primary) |
| Conformance harness | DR-3 | DR-3 | DR-3 |
| Integration (handshake + ratchet) | DR-4 | DR-4 | DR-4 |
| Adversarial (malformed, replay) | DR-3 | DR-3 | DR-3 |

#### Conformance Gate

DR-3 completion requires:
1. All vector categories above pass in both Rust and TS.
2. Cross-language interop: Rust-sealed messages decrypt in TS, and vice versa.
3. State serialization: Rust and TS produce identical ratchet state given identical inputs.
4. Adversarial: Both implementations reject malformed ratchet messages identically.
5. CI gate: `cargo test --features vectors` (Rust) + `npm test` (TS) must both pass.

---

### Acceptance Criteria

#### DR-0 — Spec + Capability Negotiation Lock

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-DR-01 | Threat model documents relay-mediated session risks (ByteBolt-specific) | Published analysis in `bolt-protocol/docs/` or `bolt-ecosystem/docs/` |
| AC-DR-02 | Protocol amendment drafted with MUST-level ratchet invariants | PROTOCOL.md PR or draft section (§new) |
| AC-DR-03 | Capability string `bolt.double-ratchet-v1` specified with negotiation rules | Spec section with all 6 matrix cases |
| AC-DR-04 | Key schedule formally specified: ratchet inputs, outputs, state transitions | Spec section with KDF chain diagram |
| AC-DR-05 | Wire delta locked: envelope v2 field names, types, sizes, encoding | Spec section |
| AC-DR-06 | Backward compatibility policy locked: downgrade-with-warning as default | Spec section |
| AC-DR-07 | Key storage decision locked (memory-only vs persisted) | PM approval recorded |
| AC-DR-08 | New error codes defined (ratchet-specific) | Spec section + constants update |
| AC-DR-09 | Skipped message key policy defined (MAX_SKIP bound, eviction) | Spec section |
| AC-DR-10 | SAS computation unchanged (confirmed no ratchet key input) | Spec confirmation note |

#### DR-1 — Rust Reference Ratchet State Machine

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-DR-11 | `bolt-ratchet` crate created in `bolt-core-sdk/rust/` workspace | Crate compiles with `cargo build` |
| AC-DR-12 | Root key, chain key, message key KDF chain implemented | Unit tests for each derivation step |
| AC-DR-13 | DH ratchet step: new keypair generation + root key update | Unit tests |
| AC-DR-14 | Symmetric ratchet: chain key advancement + message key derivation | Unit tests |
| AC-DR-15 | Encrypt/decrypt using ratchet-derived message keys | Round-trip tests |
| AC-DR-16 | Out-of-order message handling with skipped key buffer | Skipped key tests with MAX_SKIP enforcement |
| AC-DR-17 | Ratchet state serialization (deterministic, for vector generation) | Serialization round-trip tests |
| AC-DR-18 | Vector generation binary produces all vector categories | JSON vector files generated and committed |
| AC-DR-19 | `Drop` impl volatile-zeros all secret key material in ratchet state | Zeroization test (SA4 pattern) |
| AC-DR-20 | No transport dependencies in `bolt-ratchet` crate | Dependency audit |
| AC-DR-21 | All existing `bolt-core` tests pass (no regression) | `cargo test` |

#### DR-2 — TypeScript Parity Implementation

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-DR-22 | TS ratchet module in `ts/bolt-core/src/ratchet/` | Module compiles |
| AC-DR-23 | All Rust-generated vectors pass in TS | Vector test suite |
| AC-DR-24 | Key zeroization on disconnect (loop-zero pattern per SA7/SA19) | Zeroization tests |
| AC-DR-25 | API parity with Rust (same state machine interface) | Interface comparison |

#### DR-3 — Cross-Language Vectors + Conformance Harness

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-DR-26 | Cross-language interop: Rust → TS and TS → Rust round-trip | Interop vector tests |
| AC-DR-27 | Conformance harness (extends S1 pattern) with ratchet test domain | CI-gated harness |
| AC-DR-28 | Adversarial vectors: malformed dh, invalid pn/n, replay, MAX_SKIP exceeded | Adversarial test suite |
| AC-DR-29 | State determinism: identical inputs → identical ratchet state in both langs | State comparison vectors |

#### DR-4 — Wire Integration + Compatibility Rollout Gates

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-DR-30 | Handshake integration: `bolt.double-ratchet-v1` capability negotiated in HELLO | Integration tests |
| AC-DR-31 | Envelope v2 sent/received when capability negotiated | Wire-level tests |
| AC-DR-32 | Downgrade to v1 envelope when capability not negotiated | Downgrade tests |
| AC-DR-33 | Warning surfaced to user on downgrade (via `onVerificationState` or equivalent) | UI callback tests |
| AC-DR-34 | Daemon integration: `bolt-daemon` consumes `bolt-ratchet` crate | Daemon tests pass |
| AC-DR-35 | Dark launch flag: ratchet capability advertised but disabled by default | Feature flag tests |
| AC-DR-36 | Rollback path: disabling ratchet returns to v1 behavior cleanly | Rollback tests |
| AC-DR-37 | All existing test suites pass across all repos (no regression) | CI gate across repos |

#### DR-5 — Default-On + Legacy Path Deprecation Decision

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-DR-38 | AC: TBD at DR-4 completion — depends on burn-in data and PM decision | — |

---

### Risk Register

| ID | Risk | Severity | Mitigation | Owner |
|----|------|----------|------------|-------|
| DR-R1 | KDF implementation divergence between Rust and TS | HIGH | Shared test vectors; conformance harness CI gate (DR-3) | Engineering |
| DR-R2 | Browser crypto API limitations (Web Crypto lacks XSalsa20) | MEDIUM | TweetNaCl already provides XSalsa20; ratchet KDF uses HKDF-SHA256 (Web Crypto native) | Engineering |
| DR-R3 | Skipped message key buffer memory exhaustion | LOW | MAX_SKIP constant (suggest 1000); eviction policy in spec (DR-0) | Engineering |
| DR-R4 | Wire overhead impacts file transfer throughput | LOW | ~80B/message increase is negligible vs chunk size (~16KB) | Engineering |
| DR-R5 | Session resumption demand emerges before persistence is designed | MEDIUM | Memory-only ratchet is the safe default; persistence deferred explicitly with PM gate | PM |
| DR-R6 | Mixed-fleet deployment complexity (v1 + v2 peers coexisting) | MEDIUM | Capability negotiation + downgrade-with-warning; phased rollout (dark → opt-in → default) | Engineering + PM |
| DR-R7 | Ratchet state corruption on unclean disconnect | MEDIUM | Memory-only state + fresh ratchet on reconnect eliminates persistence corruption risk | Engineering |

### Explicit Non-Goals

| ID | Non-Goal | Rationale |
|----|----------|-----------|
| DR-NG1 | Session resumption (persistent ratchet state across disconnects) | Deferred — requires separate security review and PM approval (PM-DR-03) |
| DR-NG2 | Group ratchet / multi-party key agreement | Bolt is peer-to-peer; group semantics are out of scope |
| DR-NG3 | Post-quantum key exchange | Separate security gate; does not block DR-STREAM-1 |
| DR-NG4 | Consumer app UI changes | Consumer apps are out of scope for DR-STREAM-1 (DR-G8) |
| DR-NG5 | Rendezvous server changes | Confirmed unnecessary — server is payload-opaque |
| DR-NG6 | Transport layer changes | Ratchet is Core-level, transport-independent (DR-G2) |
| DR-NG7 | Replacing NaCl box with a different AEAD | NaCl box remains the primitive; ratchet changes key derivation, not encryption algorithm |

---

### PM Open Decisions Table

| ID | Decision | Blocks | Priority | Status |
|----|----------|--------|----------|--------|
| PM-DR-01 | Confirm DR-STREAM (phased) vs single-gate approach | All phases | P0 | **RESOLVED by this P0 — DR-STREAM confirmed** |
| PM-DR-02 | Approve downgrade-with-warning as default compatibility mode | DR-4 | DR-0 | PENDING |
| PM-DR-03 | Key storage: memory-only (recommended) vs persisted ratchet state | DR-0 spec lock | DR-0 | PENDING |
| PM-DR-04 | MAX_SKIP value (suggested: 1000) | DR-0 spec lock | DR-0 | PENDING |
| PM-DR-05 | Envelope version field: bump to `2` vs new capability-only gate | DR-0 spec lock | DR-0 | PENDING |
| PM-DR-06 | Rust crate name: `bolt-ratchet` (recommended) vs alternative | DR-1 | DR-0 | PENDING |
| PM-DR-07 | Vector authority: confirm Rust-generates, TS-consumes (aligns with SEC-CORE2) | DR-1 | DR-0 | PENDING |
| PM-DR-08 | Dark launch duration before opt-in promotion | DR-4 rollout | DR-4 | PENDING |
| PM-DR-09 | Legacy deprecation timeline (how long to support non-DR peers) | DR-5 | DR-5 | PENDING |
| PM-DR-10 | New error code names for ratchet failures (suggestion: `RATCHET_OUT_OF_SYNC`, `RATCHET_DERIVE_FAILED`, `RATCHET_MAX_SKIP_EXCEEDED`) | DR-0 spec lock | DR-0 | PENDING |

---

### Rollout Strategy

| Stage | Criteria to Enter | Behavior | Duration |
|-------|-------------------|----------|----------|
| **Dark launch** | DR-4 complete; all CI gates pass | `bolt.double-ratchet-v1` advertised in HELLO but disabled by default (feature flag) | PM-DR-08 decision |
| **Opt-in** | Dark launch burn-in clean; no regressions | Users can enable ratchet via config/UI toggle; downgrade-with-warning for non-DR peers | 2+ weeks suggested |
| **Default-on** | Opt-in period clean; PM approval (DR-5) | Ratchet enabled by default; downgrade-with-warning for legacy peers | Until PM-DR-09 |
| **Legacy deprecation** | Default-on period complete; migration data shows >95% adoption | Non-DR peers refused (fail-closed) | PM-DR-09 decision |

**Rollback path at every stage:**
- Disable feature flag → immediate return to v1 behavior.
- No persisted ratchet state → no state cleanup needed.
- Capability negotiation ensures clean fallback (intersection removes `bolt.double-ratchet-v1`).

---

## BTR-STREAM-1 — Bolt Transfer Ratchet Pre-ByteBolt Security Gate

> **Stream ID:** BTR-STREAM-1
> **Backlog Item:** SEC-BTR1
> **Priority:** NEXT (pre-ByteBolt gate — blocks ByteBolt start)
> **Repos:** bolt-core-sdk (Rust + TS), bolt-protocol (spec amendment)
> **Codified:** ecosystem-v0.1.100-sec-btr1-replaces-dr (2026-03-09)
> **Status:** BTR-STREAM-1 COMPLETE. BTR-0 through BTR-5 DONE. Approved policy: default-on fail-open (Option C).
> **Replaces:** DR-STREAM-1 (SEC-DR1) — per PM-BTR-01 through PM-BTR-04

---

### Context & Motivation

Current Bolt protocol uses **static ephemeral keys per connection** with no mid-session key rotation (SEC-05). Each message within a session is encrypted with the same ephemeral shared secret, differentiated only by a fresh random nonce. For **ByteBolt** (persistent relay-mediated connections, potentially hours/days), the security posture degrades:

- Longer sessions increase the window for ephemeral key compromise.
- Relay-mediated transport adds a trust boundary.
- Session-level rotation is insufficient for persistent connections.

A continuous key agreement mechanism is required before ByteBolt can proceed. However, **the Signal Double Ratchet is not the right tool for Bolt's use case:**

#### Why Not Double Ratchet?

The Double Ratchet (Signal protocol) is optimized for **asynchronous bidirectional messaging** with these assumptions:

1. **Out-of-order delivery** — messages may arrive in any order (requires skipped-message-key buffer, MAX_SKIP management, complex state).
2. **Bidirectional symmetric flow** — both parties send interleaved messages continuously (requires separate sending/receiving chains, PN counter for chain switching).
3. **Unbounded session duration** — messaging sessions last indefinitely with no clear "transfer complete" boundary.
4. **Small messages** — individual chat messages are small; per-message DH ratchet overhead is acceptable.

Bolt's file transfer protocol has **fundamentally different characteristics:**

1. **Ordered delivery** — file chunks arrive in sequence (`chunk_index` 0, 1, 2, ...). Out-of-order handling is unnecessary complexity.
2. **Unidirectional per transfer** — each file transfer flows sender→receiver. Bidirectional chains are unnecessary.
3. **Clear transfer boundaries** — FILE_OFFER → FILE_CHUNK* → FILE_FINISH provides natural ratchet step points.
4. **Large bulk data** — file chunks are ~16KB; per-chunk DH ratchet would be computationally wasteful. Symmetric ratchet per chunk with DH ratchet per transfer boundary is optimal.

#### Bolt Transfer Ratchet (BTR) Architecture

BTR is a **transfer-scoped key agreement protocol** purpose-built for file transfer:

```
Session Setup (unchanged from v1):
  X25519 ephemeral DH → shared secret → NaCl box for HELLO
                                              │
Transfer Key Derivation (new):                │
  Per transfer: HKDF(session_secret, transfer_id) → transfer_root_key
                                              │
Chunk Ratchet (new):                          │
  Per chunk: KDF(chain_key) → (next_chain_key, message_key)
  Encrypt chunk with message_key              │
                                              │
Inter-Transfer DH Ratchet (new):              │
  Between transfers: new DH keypair → new session_secret
  Forward secrecy across transfer boundaries
```

**Key architectural differences from Double Ratchet:**

| Dimension | Double Ratchet (DR) | Bolt Transfer Ratchet (BTR) |
|-----------|--------------------|-----------------------------|
| **Ratchet scope** | Per-message (session-continuous) | Per-transfer + per-chunk |
| **DH ratchet frequency** | Every message exchange direction change | Every transfer boundary |
| **Symmetric ratchet** | Per-message chain advancement | Per-chunk chain advancement |
| **Out-of-order support** | YES (skipped key buffer, MAX_SKIP) | NO (chunks are ordered) |
| **Bidirectional chains** | YES (sending + receiving chain pair) | NO (unidirectional per transfer) |
| **State complexity** | High (RK, CKs, CKr, Ns, Nr, PN, skipped keys) | Low (session_key, transfer_key, chain_key, chunk_counter) |
| **Key isolation** | Session-level (all messages share ratchet state) | Transfer-level (each transfer has independent key chain) |
| **Transfer boundary awareness** | None (no concept of "transfer") | Native (ratchet steps align with FILE_OFFER/FILE_FINISH) |

**Security properties achieved:**

| Property | How BTR Provides It |
|----------|-------------------|
| Per-chunk forward secrecy | Symmetric ratchet advances chain_key per chunk; old message_keys cannot be derived from current state |
| Per-transfer forward secrecy | DH ratchet step at each transfer boundary; compromise of transfer N's keys cannot reveal transfer N-1 |
| Self-healing after compromise | New DH step at next transfer boundary restores secrecy |
| Transfer isolation | Independent key chain per transfer_id; compromise of one transfer's keys is contained |
| Backward secrecy | After DH ratchet step, future transfers protected even if current state was compromised |

---

### Inherited P0 Audit Findings

The following findings from DR-STREAM-1 P0 (ecosystem-v0.1.99) remain valid and are inherited:

- **bolt-core-sdk:** NaCl box, static ephemeral per session, no KDF chain. 5 cross-language vector files. Rust reference + TS parity model confirmed viable.
- **bolt-protocol:** No ratchet in v1. Capability negotiation via HELLO intersection model supports new capabilities.
- **bolt-daemon:** `SessionContext` holds ephemeral keypair. Shared crate feasibility: HIGH.
- **bolt-rendezvous:** Fully opaque to payload. ZERO changes needed. Confirmed.

---

### Scope Guardrails

| ID | Guardrail |
|----|-----------|
| BTR-G1 | Browser retains native WebRTC transport — no browser webrtc-rs swap |
| BTR-G2 | Ratchet layer MUST be transport-independent (Core, not Profile) |
| BTR-G3 | Backward compatibility MUST be explicit, testable, and auditable |
| BTR-G4 | No retroactive rewrites of completed streams |
| BTR-G5 | No protocol-breaking changes without capability negotiation gate |
| BTR-G6 | Rust is reference implementation; TS achieves parity via shared vectors |
| BTR-G7 | Rendezvous server requires ZERO changes (inherited from DR P0 audit) |
| BTR-G8 | Consumer apps (localbolt, localbolt-app, localbolt-v3) are OUT OF SCOPE for BTR-STREAM-1 |
| BTR-G9 | BTR MUST NOT introduce out-of-order complexity — Bolt chunks are ordered |
| BTR-G10 | DH ratchet steps MUST align with transfer boundaries, not per-message |

---

### BTR-STREAM-1 Phase Table

| Phase | Description | Serial Gate | Dependencies | Parallelizable With | Status |
|-------|-------------|-------------|--------------|---------------------|--------|
| **BTR-0** | Spec + capability negotiation lock | YES — gates all subsequent phases | None (independent) | — | **DONE** (`v0.1.6-spec-btr0-lock`, `ecosystem-v0.1.102-btr0-spec-lock`) |
| **BTR-1** | Rust reference BTR state machine | YES — gates BTR-2, BTR-3 | BTR-0 complete | — | **DONE** (`sdk-v0.5.36-btr1-rust-reference`, `cc4965e`) |
| **BTR-2** | TypeScript parity implementation | NO | BTR-1 complete (vectors available) | BTR-3 (partial) | **DONE** (`sdk-v0.5.37-btr2-ts-parity`, `a9c6d33`) |
| **BTR-3** | Cross-language vectors + conformance harness | NO | BTR-1 complete | BTR-2 (partial) | **DONE** (`sdk-v0.5.38-btr3-conformance-gapfill`, `ec37998`) |
| **BTR-4** | Wire integration + compatibility rollout gates | YES — gates ByteBolt start | BTR-2 + BTR-3 complete | — | **DONE** (`sdk-v0.5.39-btr4-wire-integration`, `a7b3a7b`) |
| **BTR-5** | Default-on + legacy path deprecation decision | PM decision gate | BTR-4 deployed + burn-in data | — | **DONE** (GO — Option C approved: default-on fail-open. PM-BTR-08/09/11 approved 2026-03-11) |

#### Dependency DAG

```
BTR-0 (spec lock)
  │
  ▼
BTR-1 (Rust reference)
  │
  ├──────────────┐
  ▼              ▼
BTR-2 (TS)    BTR-3 (vectors)     ← partially parallelizable
  │              │
  └──────┬───────┘
         ▼
BTR-4 (wire integration + rollout)
         │
         ▼
BTR-5 (default-on decision)       ← PM gate, not engineering
```

**Serial gates:**
- BTR-0 is a hard gate: no implementation may begin without locked spec.
- BTR-1 is a hard gate: TS parity and vector corpus require Rust reference to exist.
- BTR-4 is the **ByteBolt gate**: ByteBolt development blocked until BTR-4 complete.
- BTR-5 is a PM decision gate, not an engineering gate.

---

### Backward-Compatibility Policy

#### Capability String

```
bolt.transfer-ratchet-v1
```

Follows existing `bolt.*` namespace convention. Negotiated via HELLO `capabilities[]` intersection.

#### Capability Negotiation Matrix

| Sender BTR Support | Receiver BTR Support | Behavior | Security Level | Fail Mode |
|--------------------|----------------------|----------|----------------|-----------|
| YES | YES | Full BTR (per-transfer + per-chunk ratchet) | Per-chunk FS + transfer isolation + self-healing | — |
| YES | NO | **Downgrade to static ephemeral** | Session-level FS only (current v1) | Fail-open (downgrade-with-warning) |
| NO | YES | **Downgrade to static ephemeral** | Session-level FS only (current v1) | Fail-open (downgrade-with-warning) |
| NO | NO | Static ephemeral (current behavior) | Session-level FS only | — |
| YES/NO | MALFORMED | **Reject + ERROR** | N/A | Fail-closed |

**Default:** Downgrade-with-warning (**PM-BTR-02 APPROVED**).

#### Phase-by-Phase Fail Mode

| Phase | Default Behavior | Rationale |
|-------|-----------------|-----------|
| BTR-4 (dark launch) | Fail-open (downgrade-with-warning) | Testing with mixed fleet |
| BTR-4 (opt-in) | Fail-open (downgrade-with-warning) | Early adopters can enable |
| BTR-5 (default-on) | PM decision: fail-open or fail-closed | Security vs compat trade-off |
| BTR-5 (legacy deprecation) | Fail-closed (refuse non-BTR peers) | After sufficient migration |

---

### Wire Delta Summary

#### Current Envelope (ProfileEnvelopeV1)

```json
{
  "type": "profile-envelope",
  "version": 1,
  "encoding": "base64",
  "payload": "<base64(nonce[24] || ciphertext[N+16])>"
}
```

#### Proposed BTR Envelope (version TBD at BTR-0)

```json
{
  "type": "profile-envelope",
  "version": 2,
  "encoding": "base64",
  "ratchet": {
    "dh": "<base64(ratchet_public_key[32])>",
    "tid": "<transfer_id>",
    "cn": <chunk_number>
  },
  "payload": "<base64(nonce[24] || ciphertext[N+16])>"
}
```

**New fields:**

| Field | Type | Size | Purpose |
|-------|------|------|---------|
| `ratchet.dh` | base64 string | 32 bytes (44 chars) | Current DH ratchet public key (changes at transfer boundaries) |
| `ratchet.tid` | string | 16 bytes (transfer_id) | Transfer scope identifier (keys scoped per transfer) |
| `ratchet.cn` | uint32 | 4 bytes (JSON number) | Chunk number in current transfer (symmetric ratchet position) |

**Overhead delta:** ~100B JSON increase per message (~5% on typical 2KB chunk). Negligible for file transfer.

**What remains unchanged:**

| Component | Change? |
|-----------|---------|
| NaCl box algorithm (XSalsa20-Poly1305) | NO |
| Nonce generation (24B CSPRNG) | NO |
| HELLO message format | MINOR (add capability string) |
| SAS computation | NO |
| TOFU pinning | NO |
| Identity key lifecycle | NO |
| Rendezvous protocol | NO |
| Ping/Pong (unprotected) | NO |

**Versioning strategy:** Envelope `version: 2` when `bolt.transfer-ratchet-v1` negotiated. Capability negotiation handles transition without changing `bolt_version` in HELLO.

---

### Key Material Storage Impact

#### BTR Ratchet State (Per Active Session)

| Key Material | Must Persist? | Lifetime | Size | Sensitivity |
|--------------|--------------|----------|------|-------------|
| Session DH secret (from initial handshake) | NO (memory only) | Per session | 32 B | CRITICAL |
| Current DH ratchet keypair | NO (memory only) | Per transfer boundary | 64 B | CRITICAL |
| Transfer root key | NO (memory only) | Per transfer | 32 B | HIGH |
| Chunk chain key | NO (memory only) | Per chunk advancement | 32 B | HIGH |
| Chunk counter | NO (memory only) | Per transfer | 4 B | LOW |

**Total per-session state:** ~164 bytes. **No skipped-key buffer needed** (ordered delivery).

**Comparison with DR state:** DR required ~200B base + (32B × MAX_SKIP) for skipped keys. BTR eliminates the skipped-key buffer entirely.

#### Interaction with Existing Invariants

| Invariant | Impact | Resolution |
|-----------|--------|------------|
| **SEC-04** (ephemeral secrets MUST NOT persist to disk) | **COMPATIBLE** — all BTR state is memory-only | No conflict |
| **SEC-05** (ephemeral keys discarded on disconnect) | **COMPATIBLE** — BTR state zeroed on disconnect, fresh ratchet on reconnect | No conflict |
| **SEC-01** (fresh CSPRNG nonce per envelope) | **UNCHANGED** | No impact |
| **SEC-03** (fresh ephemeral keypair per connection) | **COMPATIBLE** — initial ephemeral bootstraps BTR; DH ratchet keypairs are per-transfer-boundary (new invariant) | Spec must clarify |

**Decision (PM-BTR-03 APPROVED):** Memory-only BTR state. SEC-04/SEC-05 preserved exactly. Session resumption (persisted state) deferred as explicit non-goal.

---

### Test / Vector Strategy

#### Vector Corpus

| Field | Value |
|-------|-------|
| Format | JSON (matching existing `__tests__/vectors/*.vectors.json` pattern) |
| Ownership | Generated by **Rust reference** (BTR-1) |
| Location | `bolt-core-sdk/rust/bolt-core/test-vectors/btr/` (source of truth) |
| TS copy | `bolt-core-sdk/ts/bolt-core/__tests__/vectors/btr/` (generated) |

#### Vector Categories

| Category | Purpose | Minimum Count |
|----------|---------|---------------|
| `btr-session-init.vectors.json` | Session DH → initial ratchet state | 3 |
| `btr-transfer-key.vectors.json` | HKDF(session_secret, transfer_id) → transfer_root_key | 4 |
| `btr-chunk-ratchet.vectors.json` | Chain key advancement per chunk → message key derivation | 5 |
| `btr-encrypt-decrypt.vectors.json` | Full chunk encrypt/decrypt with BTR-derived keys | 6 |
| `btr-transfer-boundary.vectors.json` | DH ratchet step at FILE_FINISH → new session secret | 4 |
| `btr-transfer-isolation.vectors.json` | Independent key chains for concurrent transfers | 3 |
| `btr-error.vectors.json` | Corrupt/invalid BTR messages | 5 |
| `btr-interop.vectors.json` | Cross-language round-trip | 4 |

#### Conformance Gate (BTR-3)

1. All vector categories pass in both Rust and TS.
2. Cross-language interop: Rust-sealed chunks decrypt in TS, and vice versa.
3. Transfer isolation: independent transfers produce independent key chains.
4. Adversarial: both implementations reject malformed BTR messages identically.
5. CI gate: `cargo test --features vectors` + `npm test` must both pass.

---

### Acceptance Criteria

#### BTR-0 — Spec + Capability Negotiation Lock

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-BTR-01 | Threat model documents relay-mediated transfer risks (ByteBolt-specific) | Published analysis |
| AC-BTR-02 | BTR protocol specified with MUST-level invariants (KDF chain, DH ratchet timing, chunk ratchet) | PROTOCOL.md PR or draft section |
| AC-BTR-03 | Capability string `bolt.transfer-ratchet-v1` specified with negotiation rules | Spec section with all 5 matrix cases |
| AC-BTR-04 | Transfer key derivation formally specified: HKDF inputs, outputs, binding to transfer_id | Spec section |
| AC-BTR-05 | Chunk ratchet formally specified: chain key → message key KDF, advancement rule | Spec section |
| AC-BTR-06 | Inter-transfer DH ratchet specified: when new DH step occurs, how session secret updates | Spec section |
| AC-BTR-07 | Wire delta locked: envelope v2 field names, ratchet object structure | Spec section |
| AC-BTR-08 | Backward compatibility policy locked (downgrade-with-warning default) | Spec section — **PM-BTR-02 APPROVED** |
| AC-BTR-09 | Key storage confirmed memory-only (no persistence) | PM approval recorded — **PM-BTR-03 APPROVED** |
| AC-BTR-10 | New error codes defined (BTR-specific) | Spec section |
| AC-BTR-11 | SAS computation unchanged (confirmed no ratchet key input) | Spec confirmation note |
| AC-BTR-12 | Ordered-delivery assumption documented: no skipped-key buffer, fail-closed on gap | Spec section |

#### BTR-1 — Rust Reference BTR State Machine

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-BTR-13 | `bolt-btr` crate created in `bolt-core-sdk/rust/` workspace | Crate compiles |
| AC-BTR-14 | Session initialization: DH shared secret → initial ratchet state | Unit tests |
| AC-BTR-15 | Transfer key derivation: HKDF(session_secret, transfer_id) | Unit tests |
| AC-BTR-16 | Chunk ratchet: chain key advancement + message key derivation | Unit tests |
| AC-BTR-17 | Inter-transfer DH ratchet: new keypair + session secret update at transfer boundary | Unit tests |
| AC-BTR-18 | Encrypt/decrypt using BTR-derived message keys | Round-trip tests |
| AC-BTR-19 | Transfer isolation: independent key chains for different transfer_ids | Isolation tests |
| AC-BTR-20 | Vector generation binary produces all vector categories | JSON vectors committed |
| AC-BTR-21 | `Drop` impl volatile-zeros all secret key material | Zeroization test (SA4 pattern) |
| AC-BTR-22 | No transport dependencies in `bolt-btr` crate | Dependency audit |
| AC-BTR-23 | All existing `bolt-core` tests pass (no regression) | `cargo test` |

#### BTR-2 — TypeScript Parity Implementation

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-BTR-24 | TS BTR module in `ts/bolt-core/src/btr/` | Module compiles |
| AC-BTR-25 | All Rust-generated vectors pass in TS | Vector test suite |
| AC-BTR-26 | Key zeroization on disconnect (loop-zero per SA7/SA19) | Zeroization tests |
| AC-BTR-27 | API parity with Rust (same state machine interface) | Interface comparison |

#### BTR-3 — Cross-Language Vectors + Conformance Harness

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-BTR-28 | Cross-language interop: Rust → TS and TS → Rust round-trip | Interop vector tests |
| AC-BTR-29 | Conformance harness (extends S1 pattern) with BTR test domain | CI-gated harness |
| AC-BTR-30 | Adversarial vectors: malformed ratchet fields, invalid chunk numbers, replay attempts | Adversarial test suite |
| AC-BTR-31 | Transfer isolation determinism: identical inputs → identical but independent key chains | Isolation vectors |

#### BTR-4 — Wire Integration + Compatibility Rollout Gates

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-BTR-32 | Handshake integration: `bolt.transfer-ratchet-v1` negotiated in HELLO | Integration tests |
| AC-BTR-33 | Envelope v2 with ratchet object sent/received when capability negotiated | Wire-level tests |
| AC-BTR-34 | Downgrade to v1 envelope when capability not negotiated | Downgrade tests |
| AC-BTR-35 | Warning surfaced to user on downgrade | UI callback tests |
| AC-BTR-36 | Daemon integration: `bolt-daemon` consumes `bolt-btr` crate | Daemon tests pass |
| AC-BTR-37 | Dark launch flag: BTR capability advertised but disabled by default | Feature flag tests |
| AC-BTR-38 | Rollback path: disabling BTR returns to v1 behavior cleanly | Rollback tests |
| AC-BTR-39 | All existing test suites pass across all repos (no regression) | CI gate |

#### BTR-5 — Default-On + Legacy Path Deprecation Decision

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-BTR-40 | PM approval of default-on decision with PM-BTR-08/09/11 resolved | **SATISFIED** — GO decision recorded in `docs/BTR5_DECISION_MEMO.md` (Option C: default-on fail-open). PM-BTR-08/09/11 APPROVED 2026-03-11. |

---

### Risk Register

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| BTR-R1 | KDF implementation divergence between Rust and TS | HIGH | Shared test vectors; conformance harness CI gate (BTR-3) |
| BTR-R2 | HKDF availability in browser (Web Crypto) | LOW | Web Crypto API natively supports HKDF — no polyfill needed |
| BTR-R3 | Transfer boundary detection complexity | MEDIUM | FILE_OFFER/FILE_FINISH are explicit wire messages — clean boundaries |
| BTR-R4 | Wire overhead impacts file transfer throughput | LOW | ~100B/message increase negligible vs ~16KB chunk size |
| BTR-R5 | Concurrent transfer key isolation correctness | MEDIUM | Independent HKDF derivation per transfer_id; isolation vectors in BTR-3 |
| BTR-R6 | Mixed-fleet deployment complexity (v1 + v2 coexisting) | MEDIUM | Capability negotiation + downgrade-with-warning; phased rollout |
| BTR-R7 | Novel protocol (not battle-tested like Signal DR) | HIGH | Formal security analysis at BTR-0; extensive adversarial vectors at BTR-3; external audit recommended pre-GA |

### Explicit Non-Goals

| ID | Non-Goal | Rationale |
|----|----------|-----------|
| BTR-NG1 | Session resumption (persistent ratchet state) | Memory-only; deferred to separate gate |
| BTR-NG2 | Out-of-order chunk delivery | Bolt chunks are ordered; complexity unjustified |
| BTR-NG3 | Group/multi-party key agreement | Bolt is peer-to-peer |
| BTR-NG4 | Post-quantum key exchange | Separate security gate |
| BTR-NG5 | Consumer app UI changes | Out of scope (BTR-G8) |
| BTR-NG6 | Rendezvous server changes | Unnecessary (audit-confirmed opaque) |
| BTR-NG7 | Bidirectional ratchet chains | Bolt transfers are unidirectional; no need |
| BTR-NG8 | Skipped-message-key buffer | Ordered delivery; no out-of-order support |

---

### PM Open Decisions Table

| ID | Decision | Blocks | Priority | Status |
|----|----------|--------|----------|--------|
| PM-BTR-01 | BTR replaces DR as architecture (not rename/complement) | All phases | P0 | **RESOLVED** |
| PM-BTR-02 | Approve downgrade-with-warning as default compatibility mode | BTR-4 | BTR-0 | **APPROVED** |
| PM-BTR-03 | Confirm memory-only key storage (recommended) | BTR-0 spec lock | BTR-0 | **APPROVED** |
| PM-BTR-04 | Approve DR-STREAM-1 deprecation (SUPERSEDED-BY-BTR, frozen) | Governance | P0 | **RESOLVED** |
| PM-BTR-05 | Envelope version field: bump to `2` vs capability-only gate | BTR-0 spec lock | BTR-0 | **RESOLVED** — capability-only gate (conditional fields per §16.2, no version bump needed) |
| PM-BTR-06 | Rust crate name: `bolt-btr` (recommended) vs alternative | BTR-1 | BTR-0 | PENDING |
| PM-BTR-07 | Vector authority: confirm Rust-generates, TS-consumes | BTR-1 | BTR-0 | **RESOLVED** — confirmed in PROTOCOL.md Appendix C (Rust generates, TS consumes) |
| PM-BTR-08 | Dark launch duration before opt-in promotion | BTR-4 rollout | BTR-4 | **APPROVED** — 14 consecutive days, zero BTR protocol errors before default-on |
| PM-BTR-09 | Legacy deprecation timeline | BTR-5 | BTR-5 | **APPROVED** — 6 months after default-on + >95% adoption + external audit complete |
| PM-BTR-10 | New error code names for BTR failures | BTR-0 spec lock | BTR-0 | **RESOLVED** — 4 codes: `RATCHET_STATE_ERROR`, `RATCHET_CHAIN_ERROR`, `RATCHET_DECRYPT_FAIL`, `RATCHET_DOWNGRADE_REJECTED` (PROTOCOL.md §10) |
| PM-BTR-11 | External security audit: required before GA or before default-on? | BTR-4/BTR-5 | BTR-4 | **APPROVED** — required before GA/legacy deprecation, not before default-on fail-open |

---

### Rollout Strategy

| Stage | Criteria to Enter | Behavior | Duration |
|-------|-------------------|----------|----------|
| **Dark launch** | BTR-4 complete; all CI gates pass | `bolt.transfer-ratchet-v1` advertised but disabled by default | PM-BTR-08 |
| **Opt-in** | Dark launch burn-in clean | Users enable via config; downgrade-with-warning for non-BTR peers | 2+ weeks |
| **Default-on** | Opt-in clean; PM approval (BTR-5) | BTR enabled by default; downgrade-with-warning for legacy | Until PM-BTR-09 |
| **Legacy deprecation** | >95% adoption; PM approval | Non-BTR peers refused (fail-closed) | PM-BTR-09 |

**Rollback path:** Disable feature flag → immediate return to v1. No persisted state → no cleanup. Capability negotiation ensures clean fallback.

---

## CONSUMER-BTR-1 — Consumer App BTR Rollout

> **Stream ID:** CONSUMER-BTR-1
> **Backlog Item:** CONSUMER-BTR1 (new — post-BTR-STREAM-1)
> **Priority:** NOW (next after BTR-STREAM-1 completion)
> **Repos:** localbolt-v3, localbolt, localbolt-app
> **Prerequisite:** BTR-STREAM-1 COMPLETE (`ecosystem-v0.1.107-btr5-pm-resolved`)
> **Status:** NOT-STARTED
> **Scope boundary:** BTR-G8 requires consumer rollout to be a separate stream from BTR-STREAM-1.

---

### Context & Motivation

BTR-STREAM-1 delivered the Bolt Transfer Ratchet at the SDK level (bolt-core + bolt-transport-web) with a kill switch defaulting to OFF. The approved BTR-5 policy (Option C: default-on fail-open) requires consumer apps to adopt the BTR-capable SDK version and enable `btrEnabled: true` in their configuration.

CONSUMER-BTR-1 is a rollout stream, not a feature stream. No protocol or SDK changes are expected. Each phase updates the SDK dependency, enables BTR, and verifies correct behavior (including downgrade with legacy peers).

### Scope Guardrails

| ID | Guardrail |
|----|-----------|
| CBTR-G1 | No SDK code changes in this stream (SDK work belongs in bolt-core-sdk) |
| CBTR-G2 | No protocol semantic changes |
| CBTR-G3 | No UI changes required (BTR is transparent to users; downgrade warning is callback-only) |
| CBTR-G4 | Each consumer phase is independently deployable — partial rollout is valid |
| CBTR-G5 | Kill switch (`btrEnabled`) must remain available for per-consumer rollback |
| CBTR-G6 | Mixed-version peer testing required (BTR consumer ↔ non-BTR consumer) |

### CONSUMER-BTR-1 Phase Table

| Phase | Description | Repo | Dependencies | Status |
|-------|-------------|------|--------------|--------|
| **CBTR-1** | localbolt-v3 (localbolt.app) BTR rollout | localbolt-v3 | BTR-STREAM-1 complete | **DONE** — `v3.0.89-consumer-btr1-p1` (`e34e617`). Burn-in PASSED. |
| **CBTR-2** | localbolt (web) BTR rollout | localbolt | BTR-STREAM-1 complete + CBTR-F1 fixed | **DONE** — `localbolt-v1.0.36-consumer-btr1-p2` (`e75271a`). Burn-in PASSED (24h02m). |
| **CBTR-3** | localbolt-app (Tauri native) BTR rollout | localbolt-app | BTR-STREAM-1 complete + CBTR-F1 fixed | **P3 DONE** — `localbolt-app-v1.2.24-consumer-btr1-p3` (`ff33747`). Burn-in active. |

**Parallelization:** CBTR-1, CBTR-2, CBTR-3 are fully independent and MAY run in parallel. Each operates in a separate repo with no shared code changes. Recommended sequencing: CBTR-1 first (primary reproducer for prior BTR testing), then CBTR-2 and CBTR-3 in parallel.

### Acceptance Criteria

#### CBTR-1 — localbolt-v3 BTR Rollout

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-CBTR-01 | SDK dependency updated to BTR-4-capable version (bolt-core + bolt-transport-web) | `package.json` diff |
| AC-CBTR-02 | `btrEnabled: true` in WebRTCService configuration | Config diff |
| AC-CBTR-03 | BTR↔BTR transfer succeeds (two localbolt-v3 peers) | Manual or automated smoke test |
| AC-CBTR-04 | BTR↔non-BTR transfer succeeds with downgrade warning | Mixed-version peer test |
| AC-CBTR-05 | Kill switch rollback: `btrEnabled: false` restores v1 behavior | Rollback test |
| AC-CBTR-06 | All existing tests pass (no regression) | CI gate |
| AC-CBTR-07 | `[BTR_FULL]` and `[BTR_DOWNGRADE]` log tokens observable | Log verification |

> **BLOCKER:** CBTR-F1 (receiver pause/resume defect) — pre-existing transport control asymmetry surfaced during CBTR-1 burn-in. Receiver cannot initiate pause/resume (`sendTransferIds`-only lookup). Fix required in SDK `TransferManager.ts` before CBTR-2/3 advancement. See `AUDIT_TRACKER.md § CBTR-F1`.

**Additional validation criterion (added post-CBTR-F1 discovery):**

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-CBTR-07a | Receiver-initiated pause/resume works (CBTR-F1 resolved) | Receiver pause sends canonical `pause`, resume sends `resume`, sender unchanged |

#### CBTR-2 — localbolt BTR Rollout

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-CBTR-08 | SDK dependency updated to BTR-4-capable version | `package.json` diff |
| AC-CBTR-09 | `btrEnabled: true` in WebRTCService configuration | Config diff |
| AC-CBTR-10 | BTR↔BTR transfer succeeds | Smoke test |
| AC-CBTR-11 | BTR↔non-BTR transfer succeeds with downgrade | Mixed-version test |
| AC-CBTR-12 | Kill switch rollback verified | Rollback test |
| AC-CBTR-13 | All existing tests pass (no regression) | CI gate |

#### CBTR-3 — localbolt-app BTR Rollout

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-CBTR-14 | SDK dependency updated to BTR-4-capable version | `package.json` diff |
| AC-CBTR-15 | `btrEnabled: true` in WebRTCService configuration | Config diff |
| AC-CBTR-16 | BTR↔BTR transfer succeeds | Smoke test |
| AC-CBTR-17 | BTR↔non-BTR transfer succeeds with downgrade | Mixed-version test |
| AC-CBTR-18 | Kill switch rollback verified | Rollback test |
| AC-CBTR-19 | All existing tests pass (no regression) | CI gate |
| AC-CBTR-20 | Tauri native transport path unaffected (BTR is WebRTC-layer only) | Tauri build + smoke |

### PM Decisions

| ID | Decision | Blocks | Priority | Status |
|----|----------|--------|----------|--------|
| PM-CBTR-01 | Confirm CBTR-1 first (localbolt-v3 as primary rollout target) | Phase sequencing | NOW | **APPROVED** — rollout order: localbolt-v3 → localbolt → localbolt-app |
| PM-CBTR-02 | Dark launch burn-in: per-consumer or shared across stream? | Rollout timing | NOW | **APPROVED** — 24h clean run per phase before promoting to next consumer |

### Risk Register

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| CBTR-R1 | Consumer SDK version mismatch during partial rollout | LOW | Capability negotiation handles mixed fleet; downgrade-with-warning |
| CBTR-R2 | Consumer-specific integration issues (Tauri, Netlify, etc.) | LOW | Per-consumer smoke tests; kill switch for immediate rollback |
| CBTR-R3 | Dark launch burn-in period delays security benefit | LOW | 14-day window per PM-BTR-08; parallelizable across consumers |
| CBTR-R4 | CBTR-F1: Receiver pause/resume broken (pre-existing transport asymmetry) | MEDIUM | **RESOLVED** — `sdk-v0.5.40-cbtr-f1-receiver-pause` (`c164fc1`). No longer blocks CBTR-2/3. |

---

## RUSTIFY-CORE-1 — Native-First Transport + Core Consolidation

> **Stream ID:** RUSTIFY-CORE-1
> **Backlog Items:** SEC-CORE2, PLAT-CORE1 (provisionally superseded), MOB-RUNTIME1, ARCH-WASM1 (provisionally refactored/dependent)
> **Priority:** NEXT (execution blocked until CONSUMER-BTR1 completes)
> **Repos:** bolt-core-sdk (Rust primary), bolt-daemon, bolt-protocol (spec amendments)
> **Codified:** ecosystem-v0.1.113-rustify-core1-codify (2026-03-12)
> **Status:** CODIFIED (RC1 unblocked after CONSUMER-BTR1 closes)

---

### Context & Motivation

Current Bolt ecosystem has split authority: TS owns transport orchestration (handshake, envelope, transfer wire flow) while Rust owns reference crypto and transfer state machine. Native app paths (localbolt-app/bolt-daemon) route through IPC to a Rust daemon but still depend on TS for session lifecycle in the Tauri WebView layer. This split:

- Limits native app performance (IPC boundary, JS event loop overhead)
- Prevents pure-Rust transport paths (app↔app without browser involvement)
- Blocks mobile runtime (no TS available in native mobile contexts)
- Duplicates protocol authority (TS and Rust both implement envelope/handshake logic)

RUSTIFY-CORE-1 consolidates protocol authority in Rust and introduces native transport for app↔app paths while explicitly retaining WebRTC for browser↔browser.

### Product Priority Order

1. **Native app reliability + speed** — app↔app via Rust native transport
2. **Browser↔app** — browser client transport + Rust endpoint/core
3. **Browser↔browser** — retained on WebRTC (no change)

---

### Transport Matrix

> **Status:** Policy draft. Final lock depends on PM-RC-01 (transport protocol) and PM-RC-07 (stream relationship mode).

| Endpoint Pair | Transport | Authority | Status |
|---------------|-----------|-----------|--------|
| browser↔browser | WebRTC DataChannel | TS (`bolt-transport-web`) | **Retained baseline** — no change |
| app↔app | Rust native transport (QUIC recommended) | Rust (new crate) | PM-RC-01 PENDING |
| browser↔app | Browser client transport + Rust endpoint/core | Hybrid (TS browser-side, Rust server-side) | PM-RC-02 PENDING |

### Rustification Targets

| Target | Current State | RUSTIFY-CORE-1 Goal |
|--------|--------------|---------------------|
| Protocol/security core (BTR, transfer SM, policy, integrity) | Rust crates exist (`bolt-core`, `bolt-btr`, `bolt-transfer-core`) but TS still owns wire orchestration | Rust canonical for all protocol logic; TS becomes thin I/O adapter |
| Native transport engine (app↔app) | No native transport — app routes through IPC + daemon | Direct Rust transport (QUIC recommended) |
| Session lifecycle + control-plane invariants | Split: TS owns handshake/envelope in browser, Rust owns daemon session | Rust canonical; platform adapters delegate to shared core |
| Platform adapters | Tauri app has Rust daemon + TS WebView; browser is pure TS | Thin TS/Swift/Tauri shells over unified Rust backend |

### Deferred / Out of Scope

| Item | Rationale |
|------|-----------|
| CLI runtime implementation | CLI does not exist yet; reserved hooks only (RC7) |
| Replacing browser↔browser WebRTC | Working, battle-tested; no business case for replacement |
| Full browser runtime rewrite | Browser retains TS transport adapter; WASM for logic only (ARCH-WASM1 scope) |
| Fail-closed migration | Separate PM gate after adoption metrics available |

---

### Relationship to Existing Streams

> **Status:** Provisional pending PM-RC-07. Recommended mode: hybrid (SUPERSEDES for SEC-CORE2/PLAT-CORE1, REFACTORS for MOB-RUNTIME1/ARCH-WASM1).

| Existing Stream | Recommended Mode | Rationale |
|-----------------|-----------------|-----------|
| **SEC-CORE2** (Rust-first security/protocol consolidation) | **SUPERSEDES** | RC2 (shared Rust core API design) absorbs AC-SC-01 through AC-SC-04 entirely. Protocol authority migration is a core deliverable of RUSTIFY-CORE-1. |
| **PLAT-CORE1** (Shared Rust core + thin platform UIs) | **SUPERSEDES** | RC2+RC4 (core API + adoption in app boundaries) absorb PLAT-CORE1's full scope. Crate topology, FFI surface, and platform adapter model are RUSTIFY-CORE-1 deliverables. |
| **MOB-RUNTIME1** (Mobile embedded runtime model) | **REFACTORS/DEPENDS-ON** | MOB-RUNTIME1 retains its own stream identity but becomes dependent on RC4 completion (shared Rust core adoption). Mobile-specific concerns (FFI, background execution, app store policies) remain MOB-RUNTIME1 scope. |
| **ARCH-WASM1** (WASM protocol engine) | **REFACTORS/DEPENDS-ON** | ARCH-WASM1 retains its own stream identity but becomes dependent on RC2 completion (shared core API). Browser WASM integration concerns remain ARCH-WASM1 scope. |

If PM-RC-07 confirms SUPERSEDES for SEC-CORE2 and PLAT-CORE1, those items should be updated to `SUPERSEDED-BY: RUSTIFY-CORE-1` (matching DR-STREAM-1 → BTR-STREAM-1 precedent).

---

### Scope Guardrails

| ID | Guardrail |
|----|-----------|
| RC-G1 | Browser↔browser retains WebRTC — no browser WebRTC replacement in this stream |
| RC-G2 | Native transport choice (QUIC/other) requires PM-RC-01 confirmation before RC3 execution |
| RC-G3 | Shared Rust core API must be transport-independent (logic boundary, not I/O) |
| RC-G4 | CLI implementation is OUT OF SCOPE — RC7 produces governance reservation artifacts only |
| RC-G5 | No protocol semantic changes without PM approval (inherited from G4/G5) |
| RC-G6 | Existing test suites (all repos) must remain green at every phase gate |
| RC-G7 | Platform adapters must provide kill-switch rollback to current TS paths |
| RC-G8 | Consumer app changes in this stream are limited to Rust core adoption wiring — no feature scope creep |

---

### RUSTIFY-CORE-1 Phase Table

| Phase | Description | Type | Serial Gate | Dependencies | Status |
|-------|-------------|------|-------------|--------------|--------|
| **RC1** | Transport matrix + boundary lock (spec-level) | PM/Spec gate | YES — gates RC2, RC3 | CONSUMER-BTR1 complete, PM-RC-01 confirmed | NOT-STARTED |
| **RC2** | Shared Rust core API design/extraction lock | Engineering + PM gate | YES — gates RC4, RC5 | RC1 complete | NOT-STARTED |
| **RC3** | Native transport reference path (app↔app) | Engineering gate | NO (parallel with RC4) | RC1 complete, PM-RC-01 confirmed | NOT-STARTED |
| **RC4** | Shared Rust core adoption in app/runtime boundaries | Engineering gate | NO (parallel with RC3) | RC2 complete | NOT-STARTED |
| **RC5** | Browser↔app endpoint integration gates | Engineering gate | YES — gates RC6 | RC3 + RC4 complete | NOT-STARTED |
| **RC6** | Rollout + compatibility + rollback policy | PM/Engineering gate | YES — gates close | RC5 complete | NOT-STARTED |
| **RC7** | CLI reservation hooks (governance artifacts only) | Governance gate | NO (parallel with RC1–RC6) | None | NOT-STARTED |

#### Dependency DAG

```
CONSUMER-BTR1 (must complete)
      │
      ▼
RC1 (transport matrix + boundary lock)
      │
      ├──────────────┐
      ▼              ▼
RC2 (core API)    RC3 (native transport)    ← RC3 requires PM-RC-01
      │
      ├──────────────┐
      ▼              │
RC4 (core adoption)  │
      │              │
      └──────┬───────┘
             ▼
RC5 (browser↔app integration)
             │
             ▼
RC6 (rollout + rollback)

RC7 (CLI reservation) — parallel, no dependencies
```

#### RC2 API Status Clarification

Existing Rust crates that form the shared core foundation:
- `bolt-core` (v0.4.0) — crypto, identity, SAS, peer code, error codes
- `bolt-btr` — BTR state machine, ratchet, KDF
- `bolt-transfer-core` (v0.1.0) — transfer SM, backpressure
- `bolt-transfer-policy-wasm` — WASM policy layer

**RC2 is primarily an integration/facade phase**, not a greenfield extraction. The crates exist. RC2 must:
1. Define the unified API surface (facade crate or re-export strategy)
2. Define FFI boundary for Tauri/native consumers
3. Migrate protocol authority from TS to Rust for remaining paths (handshake, envelope orchestration)
4. Absorb SEC-CORE2 ACs (AC-SC-01–04): Rust vector authority, TS generation deprecated, canonical Rust state machine

#### RC7 CLI Reservation Artifacts

RC7 produces governance-only artifacts. No runtime code. Concrete deliverables:
- Reserved API extension points (trait/interface boundaries the CLI must satisfy)
- Reserved config schema keys (CLI-specific configuration namespace)
- Reserved capability/version namespace (CLI capability strings)
- Architecture constraints document (what the CLI stream inherits from RUSTIFY-CORE-1)

---

### Acceptance Criteria

#### RC1 — Transport Matrix + Boundary Lock

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-RC-01 | Transport matrix codified with explicit endpoint-pair → transport mapping | Published spec section |
| AC-RC-02 | Browser↔browser WebRTC retention explicitly codified as invariant | Spec invariant + test reference |
| AC-RC-03 | Native transport protocol confirmed (PM-RC-01 resolved) | PM decision recorded |
| AC-RC-04 | Boundary between Rust core and platform adapters formally defined | Architecture doc with API surface |

#### RC2 — Shared Rust Core API Design/Extraction Lock

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-RC-05 | Unified Rust core API surface defined (facade or re-export) | Crate with public API + docs |
| AC-RC-06 | FFI boundary for Tauri/native consumers defined | FFI interface spec or UniFFI/cbindgen output |
| AC-RC-07 | Protocol authority migrated: handshake + envelope canonical in Rust | Rust implementation + TS delegation tests |
| AC-RC-08 | Golden vectors generated from Rust, consumed by both Rust and TS (absorbs AC-SC-01) | Rust vector generator + TS consumer tests |
| AC-RC-09 | TS vector generation deprecated (absorbs AC-SC-02) | Migration plan documented |
| AC-RC-10 | Protocol state machine canonical in Rust (absorbs AC-SC-03) | Rust crate with state machine + invariants |
| AC-RC-11 | S1 conformance tests pass against Rust-generated vectors (absorbs AC-SC-04) | CI gate |

#### RC3 — Native Transport Reference Path

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-RC-12 | Native transport crate compiles and passes unit tests | `cargo test` green |
| AC-RC-13 | App↔app file transfer completes over native transport | Integration test |
| AC-RC-14 | BTR operates correctly over native transport | BTR conformance suite pass |
| AC-RC-15 | Performance meets PM-RC-04 SLO thresholds | Benchmark results |
| AC-RC-16 | No regression in existing daemon/app test suites | CI gate |

#### RC4 — Shared Rust Core Adoption

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-RC-17 | bolt-daemon consumes unified Rust core API | Daemon tests pass |
| AC-RC-18 | localbolt-app Tauri layer delegates to Rust core via FFI | App tests pass |
| AC-RC-19 | TS transport-web delegates protocol logic to Rust core (where feasible) | Integration tests |
| AC-RC-20 | Kill-switch rollback to pre-RUSTIFY TS paths verified | Rollback test |

#### RC5 — Browser↔App Endpoint Integration

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-RC-21 | Browser client connects to Rust endpoint (app) successfully | Integration test |
| AC-RC-22 | File transfer completes browser→app and app→browser | Round-trip tests |
| AC-RC-23 | BTR negotiation works across transport boundary | BTR capability test |
| AC-RC-24 | Downgrade to WebRTC fallback when native transport unavailable | Fallback test |

#### RC6 — Rollout + Compatibility + Rollback

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-RC-25 | Rollout policy codified (staged, per-consumer) | Spec document |
| AC-RC-26 | Rollback from native transport to current paths verified per consumer | Rollback tests |
| AC-RC-27 | Compatibility matrix: all endpoint-pair combinations work | Matrix test suite |
| AC-RC-28 | No-regression gate: all existing test suites across all repos pass | CI evidence |

#### RC7 — CLI Reservation

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-RC-29 | CLI API extension points documented (traits/interfaces) | Architecture doc |
| AC-RC-30 | CLI config schema keys reserved | Schema doc |
| AC-RC-31 | CLI capability namespace reserved | Capability registry entry |
| AC-RC-32 | No runtime code produced in this phase | Code review |
| AC-RC-33 | CLI stream trigger condition defined (PM-RC-06 resolved) | PM decision recorded |

---

### PM Open Decisions Table

| ID | Decision | Blocks | Priority | Status |
|----|----------|--------|----------|--------|
| PM-RC-01 | Native transport protocol confirmation: QUIC (recommended) vs alternative. If QUIC, sub-decision: library (quinn / s2n-quic / etc.) | RC3 | RC1 | PENDING |
| PM-RC-02 | Browser↔app transport mode default (WebSocket upgrade? WebRTC retained? Hybrid?) | RC5 | RC1 | PENDING |
| PM-RC-03 | Rollout order confirmation: app-first, browser↔app second | RC6 | RC1 | PENDING |
| PM-RC-04 | Performance SLO thresholds for native transport migration gates (latency, throughput, overhead) | RC3 (AC-RC-15) | RC1 | PENDING |
| PM-RC-05 | Legacy TS-path deprecation policy/timeline after Rust core adoption | RC6 | RC6 | PENDING |
| PM-RC-06 | CLI stream trigger condition: when to start CLI-specific execution stream | RC7 (AC-RC-33) | RC7 | PENDING |
| PM-RC-07 | Relationship mode to existing streams. Recommended: SUPERSEDES SEC-CORE2 + PLAT-CORE1; REFACTORS/DEPENDS-ON MOB-RUNTIME1 + ARCH-WASM1 | All phases | RC1 | PENDING (recommended: hybrid) |

---

### Risk Register

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| RC-R1 | QUIC library maturity/maintenance risk | MEDIUM | PM-RC-01 evaluates alternatives; quinn is actively maintained with production users |
| RC-R2 | FFI boundary complexity (Tauri + potential mobile) | HIGH | RC2 designs FFI surface before RC4 adoption; UniFFI evaluated for cross-platform |
| RC-R3 | TS→Rust authority migration breaks existing consumers | HIGH | Kill-switch rollback (RC-G7); phased migration; no-regression gates (AC-RC-28) |
| RC-R4 | Browser↔app transport mode selection complexity | MEDIUM | PM-RC-02 locks choice before RC5; fallback to WebRTC always available |
| RC-R5 | Shared core API surface too large or leaky | MEDIUM | RC2 spec gate locks API before adoption; transport-independent invariant (RC-G3) |
| RC-R6 | CONSUMER-BTR1 delayed → RUSTIFY-CORE-1 blocked | LOW | CONSUMER-BTR1 in progress (CBTR-1 done, CBTR-2 burn-in); hard dependency is explicit |

### Explicit Non-Goals

| ID | Non-Goal | Rationale |
|----|----------|-----------|
| RC-NG1 | Replace browser↔browser WebRTC | Working baseline; no business case |
| RC-NG2 | Implement CLI runtime | CLI doesn't exist; reserved hooks only |
| RC-NG3 | Full browser runtime rewrite to WASM | ARCH-WASM1 scope (dependent stream) |
| RC-NG4 | Mobile platform implementation | MOB-RUNTIME1 scope (dependent stream) |
| RC-NG5 | Fail-closed legacy deprecation | Separate PM gate post-adoption |

---

## EGUI-NATIVE-1 — Native Desktop UI Consolidation (egui)

> **Stream ID:** EGUI-NATIVE-1
> **Backlog Item:** New (desktop UI migration)
> **Priority:** LATER (EN1 PM gate openable in parallel with RUSTIFY-CORE-1 RC1–RC2)
> **Repos:** localbolt-app (primary), bolt-ecosystem (governance)
> **Codified:** ecosystem-v0.1.115-egui-native1-codify (2026-03-12)
> **Status:** CODIFIED (EN1 PM gate unblocked after RUSTIFY-CORE-1 RC4 for scaffold/migration phases)

---

### Context & Motivation

Current desktop app (localbolt-app) uses Tauri v2 with a React/TypeScript/Tailwind WebView UI rendered in a system WebView. The Rust backend (`src-tauri/`) handles IPC, daemon lifecycle, and system integration, but all user-facing UI is browser-rendered HTML/CSS/JS inside a WebView.

This architecture:

- Adds a WebView runtime dependency and memory footprint to every desktop installation
- Splits the desktop app between two language ecosystems (Rust backend, TS/React frontend)
- Prevents a single-binary desktop distribution
- Limits UI access to native platform features (system dialogs, GPU rendering, accessibility APIs)
- Creates a maintenance surface spanning npm, Vite, Tailwind, React, and Tauri WebView bindings

EGUI-NATIVE-1 migrates the desktop UI from Tauri WebView to egui (Rust-native immediate-mode GUI), producing a unified Rust desktop application. Browser UI (localbolt, localbolt-v3) and mobile UI are explicitly out of scope.

### Product Priority Order

1. **Desktop feature parity** — egui UI matches current Tauri WebView desktop workflows
2. **Packaging simplification** — single Rust binary, no WebView dependency
3. **Native platform feel** — GPU-rendered, responsive, accessible

---

### Desktop UI Dependency Surface (Current State)

| Component | Technology | Location |
|-----------|-----------|----------|
| Desktop shell | Tauri v2 | `localbolt-app/src-tauri/` |
| UI rendering | React + TypeScript + Vite | `localbolt-app/web/` |
| Styling | Tailwind CSS | `localbolt-app/web/` |
| IPC (UI↔backend) | Tauri IPC (invoke/events) | `src-tauri/src/` ↔ `web/src/` |
| Daemon bundling | Sidecar (N-STREAM-1) | `src-tauri/` |
| Signal server | Vendored subtree | `localbolt-app/signal/` |

### Target Architecture (Post-EGUI-NATIVE-1)

| Component | Technology | Location |
|-----------|-----------|----------|
| Desktop shell + UI | egui (via eframe) | New `bolt-ui` crate |
| Styling/theme | egui native theming | `bolt-ui` |
| Core integration | Direct Rust API calls | No IPC boundary for UI↔core |
| Daemon/signal | Same as current | Unchanged |

### Deferred / Out of Scope

| Item | Rationale |
|------|-----------|
| Browser UI replacement (EGUI-WASM-1) | Separate future stream; browser retains React/TS |
| Mobile UI migration (EGUI-MOBILE-1) | Separate future stream; mobile platform constraints differ |
| Transport/protocol changes | EN-G1; not a transport/protocol stream |
| CLI UI | EN-G5; CLI is text-only, no GUI framework needed |

---

### Relationship to Existing Streams

| Existing Stream | Relationship | Rationale |
|-----------------|-------------|-----------|
| **RUSTIFY-CORE-1** | **DEPENDS-ON** (RC4) | RC4 defines the shared Rust core API surface. `bolt-ui` consumes this API for connection, transfer, verification workflows. EN2+ execution blocked until RC4 completes. |
| **PLAT-CORE1** | **COMPLEMENTARY** (provisionally SUPERSEDED by RUSTIFY-CORE-1) | PLAT-CORE1 envisioned "thin platform UIs" over shared Rust core. EGUI-NATIVE-1 is the concrete desktop realization. If PM-RC-07 confirms PLAT-CORE1 SUPERSEDED, EGUI-NATIVE-1 inherits the desktop UI portion. |
| **MOB-RUNTIME1** | **INDEPENDENT** | Mobile UI is a separate concern. EGUI-NATIVE-1 is desktop-only (EN-G2). |
| **ARCH-WASM1** | **INDEPENDENT** | Browser WASM is a separate concern. EGUI-NATIVE-1 is desktop-only (EN-G2). |
| **N-STREAM-1** | **COMPLEMENTARY** | N-STREAM-1 defined daemon bundling/lifecycle for localbolt-app. EGUI-NATIVE-1 replaces the UI layer but retains daemon bundling patterns. EN4 verifies packaging compatibility. |

---

### Scope Guardrails

| ID | Guardrail |
|----|-----------|
| EN-G1 | No protocol/transport changes in EGUI-NATIVE-1 |
| EN-G2 | Desktop only; browser/mobile are deferred streams (EGUI-WASM-1, EGUI-MOBILE-1) |
| EN-G3 | Rollback to pre-egui desktop path required during migration window |
| EN-G4 | `bolt-ui` must be transport-independent UI layer (consumes core API, no transport awareness) |
| EN-G5 | No CLI deliverables in this stream |
| EN-G6 | Existing desktop test/build gates must remain green at every phase gate |
| EN-G7 | Subtree policy unchanged — `signal/` remains vendored subtree, not modified |
| EN-G8 | No Tauri WebView removal until EN4 rollback gate passes |

---

### EGUI-NATIVE-1 Phase Table

| Phase | Description | Type | Serial Gate | Dependencies | Status |
|-------|-------------|------|-------------|--------------|--------|
| **EN1** | PM framework lock gate (egui vs alternatives) | PM gate | YES — gates EN2 | None (openable in parallel with RUSTIFY-CORE-1 RC1–RC2) | NOT-STARTED |
| **EN2** | Desktop `bolt-ui` scaffold + theme baseline | Engineering gate | YES — gates EN3 | EN1 complete, RUSTIFY-CORE-1 RC4 complete | NOT-STARTED |
| **EN3** | Desktop feature parity migration (core screens/workflows) | Engineering gate | YES — gates EN4 | EN2 complete | NOT-STARTED |
| **EN4** | Rollback/compatibility gate + packaging impact verification | PM/Engineering gate | YES — gates EN5 | EN3 complete | NOT-STARTED |
| **EN5** | Closure + handoff to optional EGUI-WASM-1 / EGUI-MOBILE-1 proposals | Governance gate | YES — closes stream | EN4 complete | NOT-STARTED |

#### Dependency DAG

```
RUSTIFY-CORE-1 RC4 (must complete for EN2+)
      │
      │   EN1 (PM framework lock — can run in parallel with RC1–RC4)
      │     │
      └─────┤
            ▼
      EN2 (bolt-ui scaffold + theme)
            │
            ▼
      EN3 (feature parity migration)
            │
            ▼
      EN4 (rollback/compatibility gate)
            │
            ▼
      EN5 (closure + handoff)

Deferred streams (opened only after EN results):
  EN3 results → PM-EN-04 → EGUI-WASM-1 (if approved)
  EN4 results → PM-EN-05 → EGUI-MOBILE-1 (if approved)
```

#### EN1 Detail — PM Framework Lock

EN1 is a PM decision gate only. No code. Deliverables:
- Framework evaluation document (egui vs iced vs Slint vs other)
- PM-EN-01 resolved: framework confirmed
- PM-EN-02 resolved: visual direction scope (minimal parity vs custom theme)
- Architecture compatibility assessment with RUSTIFY-CORE-1 RC4 API surface

EN1 can open before RC4 completes because it produces only governance artifacts. EN2 (scaffold) is blocked on both EN1 AND RC4.

#### EN2 Detail — Scaffold + Theme

EN2 creates the `bolt-ui` crate with:
- eframe/egui application shell
- Theme baseline (colors, typography, spacing matching or improving current design)
- Skeleton screens for all core workflows (empty implementations)
- Build target verification: macOS, Windows, Linux
- No functional integration with core API yet (mock data acceptable)

#### EN3 Detail — Feature Parity Migration

EN3 implements the core desktop workflows in egui:
1. **Connection flow** — peer code display, peer code entry, connection status
2. **Transfer flow** — file selection, send/receive, progress bars, completion
3. **Verification flow** — SAS display, confirm/reject
4. **Settings/preferences** — any desktop-specific settings
5. **Error/status display** — connection errors, transfer failures, kill-switch state

Feature parity is measured against current Tauri WebView desktop workflows, not browser workflows.

#### EN4 Detail — Rollback + Packaging Gate

EN4 verifies:
- Rollback path: can revert to Tauri WebView build from same codebase
- Desktop packaging: macOS `.app`/`.dmg`, Windows `.exe`/`.msi`, Linux `.AppImage`/`.deb`
- No regression in daemon bundling (N-STREAM-1 patterns preserved or explicitly remediated)
- Install/update flow unaffected or documented changes
- PM-EN-03 resolved: rollback window duration before legacy UI removal

#### EN5 Detail — Closure + Handoff

EN5 produces:
- Stream closure report with parity evidence
- Recommendation on EGUI-WASM-1 opening (PM-EN-04)
- Recommendation on EGUI-MOBILE-1 opening (PM-EN-05)
- Legacy Tauri WebView deprecation timeline (if EN4 passed)

---

### Acceptance Criteria

#### EN1 — PM Framework Lock

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-EN-01 | PM framework lock captured: egui confirmed as desktop UI framework (or alternative selected) | PM-EN-01 decision recorded |
| AC-EN-02 | Visual direction scope locked (minimal parity vs custom theme) | PM-EN-02 decision recorded |
| AC-EN-03 | Framework evaluation document published with pros/cons/risks | Published governance doc |
| AC-EN-04 | Architecture compatibility with RUSTIFY-CORE-1 RC4 API surface assessed | Compatibility assessment doc |

#### EN2 — Desktop `bolt-ui` Scaffold + Theme

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-EN-05 | `bolt-ui` crate scaffold compiles on all desktop targets (macOS, Windows, Linux) | `cargo build` green on all 3 targets |
| AC-EN-06 | eframe/egui application shell launches with themed window | Screenshot + build evidence |
| AC-EN-07 | Skeleton screens for all core workflows present (connection, transfer, verification) | Code review + screenshots |
| AC-EN-08 | Theme baseline codified (colors, typography, spacing) | Theme constants in code |
| AC-EN-09 | No transport or protocol dependencies in `bolt-ui` crate | `cargo tree` audit |

#### EN3 — Feature Parity Migration

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-EN-10 | Connection flow: peer code display + entry + status matches current desktop UX | Side-by-side comparison screenshots |
| AC-EN-11 | Transfer flow: file selection + send/receive + progress + completion functional | Integration test + screenshots |
| AC-EN-12 | Verification flow: SAS display + confirm/reject functional | Integration test + screenshots |
| AC-EN-13 | No transport/protocol behavior regressions | Existing test suites pass (EN-G6) |
| AC-EN-14 | `bolt-ui` consumes shared Rust core API (no direct transport/protocol calls) | Code review + `cargo tree` audit |
| AC-EN-15 | Error/status display functional (connection errors, transfer failures, kill-switch) | Integration test |

#### EN4 — Rollback + Packaging Gate

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-EN-16 | Rollback path verified: Tauri WebView build produces working desktop app from same repo | Rollback build + smoke test |
| AC-EN-17 | Desktop packaging unaffected or explicitly remediated (macOS/Windows/Linux) | Package build evidence per platform |
| AC-EN-18 | Daemon bundling patterns (N-STREAM-1) preserved or documented remediation | N-STREAM compatibility test |
| AC-EN-19 | PM-EN-03 resolved: rollback window duration confirmed | PM decision recorded |
| AC-EN-20 | Install/update flow documented if changed | Updated install docs or no-change confirmation |

#### EN5 — Closure + Handoff

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-EN-21 | Stream closure report with feature parity evidence published | Closure doc |
| AC-EN-22 | EGUI-WASM-1 recommendation produced (PM-EN-04) | Recommendation doc |
| AC-EN-23 | EGUI-MOBILE-1 recommendation produced (PM-EN-05) | Recommendation doc |
| AC-EN-24 | Legacy Tauri WebView deprecation timeline documented (conditional on EN4 pass) | Timeline doc or deferral rationale |

---

### PM Open Decisions Table

| ID | Decision | Blocks | Priority | Status |
|----|----------|--------|----------|--------|
| PM-EN-01 | Confirm egui as desktop UI framework (vs iced, Slint, Dioxus, or other Rust-native GUI) | EN2 | EN1 | PENDING |
| PM-EN-02 | Visual direction scope: minimal parity first (match current look) vs custom theme in-stream (new design language) | EN2 | EN1 | PENDING |
| PM-EN-03 | Rollback window duration: how long must dual-build (egui + Tauri WebView) be maintained before legacy removal? | EN5 (legacy removal) | EN4 | PENDING |
| PM-EN-04 | Whether to open EGUI-WASM-1 (browser egui via WASM) after EN3 results | Post-stream | EN5 | PENDING |
| PM-EN-05 | Whether to open EGUI-MOBILE-1 (mobile egui) after EN4 results | Post-stream | EN5 | PENDING |

---

### Risk Register

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| EN-R1 | egui visual maturity vs polished WebView UI — users may perceive regression | MEDIUM | PM-EN-02 scopes visual expectations; EN3 includes side-by-side comparison gate (AC-EN-10/11/12) |
| EN-R2 | egui accessibility gaps vs browser-native accessibility | MEDIUM | EN1 evaluation document must audit egui accessibility support; EN4 gate verifies |
| EN-R3 | Platform-specific rendering differences (macOS/Windows/Linux) | LOW | EN2 compiles on all 3 targets; EN3 visual verification per platform |
| EN-R4 | `bolt-ui` scope creep — adding features beyond current desktop parity | LOW | EN-G6 (existing tests green); AC-EN-10–15 (parity, not expansion) |
| EN-R5 | RUSTIFY-CORE-1 RC4 API surface instability during EN2/EN3 | MEDIUM | EN2 blocked on RC4 completion; mock data acceptable in scaffold |
| EN-R6 | Daemon bundling regression when Tauri removed | MEDIUM | EN4 gate (AC-EN-18); N-STREAM-1 compatibility verification |

### Explicit Non-Goals

| ID | Non-Goal | Rationale |
|----|----------|-----------|
| EN-NG1 | Replace browser UI (localbolt, localbolt-v3) | EGUI-WASM-1 scope (future, if approved) |
| EN-NG2 | Mobile UI | EGUI-MOBILE-1 scope (future, if approved) |
| EN-NG3 | Transport/protocol changes | EN-G1; this is a UI-only stream |
| EN-NG4 | CLI interface | EN-G5; CLI is text-only |
| EN-NG5 | Feature additions beyond current desktop parity | Parity first; new features via separate governance |

### Deferred Stream Definitions

| Stream ID | Scope | Trigger Condition | Dependencies |
|-----------|-------|-------------------|--------------|
| **EGUI-WASM-1** | Browser UI migration to egui via WASM (localbolt, localbolt-v3) | PM-EN-04 approved after EN3 results | EGUI-NATIVE-1 EN3 complete, ARCH-WASM1 |
| **EGUI-MOBILE-1** | Mobile UI via egui (iOS, Android) | PM-EN-05 approved after EN4 results | EGUI-NATIVE-1 EN4 complete, MOB-RUNTIME1 |

These are governance reservations only. No phases, ACs, or PM decisions are defined for deferred streams. Full codification requires separate stream codification prompts after trigger conditions are met.

---

## DISCOVERY-MODE-1 — Dual Discovery Mode Policy Codification

> **Stream ID:** DISCOVERY-MODE-1
> **Backlog Item:** New (discovery mode policy)
> **Priority:** NEXT (no upstream dependencies; orthogonal to all active streams)
> **Repos:** bolt-ecosystem (governance only — no runtime code)
> **Codified:** ecosystem-v0.1.116-discovery-mode1-codify (2026-03-12)
> **Status:** CODIFIED (DM1 PM gate unblocked immediately)

---

### Context & Motivation

Current consumer apps (localbolt, localbolt-v3, localbolt-app) implement dual discovery via the `DualSignaling` class in bolt-transport-web. Behavior is:

- **Cloud URL configured** → merged local + cloud peer discovery (HYBRID)
- **Cloud URL absent** → local-only peer discovery (LAN_ONLY)

This works correctly at runtime, but:

1. **No governance-level mode policy** — mode is implicit from URL presence/absence, not codified
2. **No user-visible mode indicator** — only console `[SIGNALING]` warning for local-only mode
3. **No peer origin exposed to UI** — `DiscoveredDevice` has no source field; origin tracking is internal
4. **Inconsistent env var naming** — localbolt-v3 uses `VITE_SIGNAL_URL` for cloud; localbolt/localbolt-app use `VITE_CLOUD_SIGNAL_URL`
5. **Dedup policy undocumented** — first-discovery-wins semantics work but are not codified at governance level
6. **CLOUD_ONLY not possible** — no mechanism to disable local signaling while keeping cloud

This stream codifies explicit mode definitions so expected peer visibility is unambiguous and testable.

### P0 Audit Results (2026-03-12)

**Discovery architecture (confirmed across all 3 consumers):**

| Consumer | Cloud URL Var | Local URL Var | Local Server Type |
|----------|--------------|---------------|-------------------|
| localbolt-v3 | `VITE_SIGNAL_URL` | `VITE_LOCAL_SIGNAL_URL` | Cargo git dep (embedded) |
| localbolt | `VITE_CLOUD_SIGNAL_URL` | `VITE_SIGNAL_URL` | Vendored subtree |
| localbolt-app | `VITE_CLOUD_SIGNAL_URL` | `VITE_SIGNAL_URL` | Embedded Rust thread (Tauri) |

**Dedup behavior (confirmed consistent):**
- `DualSignaling.allPeers` Map keyed by `peerCode` — first-discovery-wins
- `DualSignaling.peerSource` Map tracks origin (`'local'` | `'cloud'`)
- App-level double-guard: `peers.some(p => p.peerCode === peer.peerCode)`
- Loss is source-aware: peer removed only if originating source reports loss
- Tests in `DualSignaling.test.ts` cover merge, dedup, source-aware loss

**IP-based room grouping (local server):**
- Peers grouped by source IP address — same IP = same room = mutual discovery
- No manual pairing required for LAN discovery
- Cloud server has no room isolation (flat peer registry)

---

### Mode Definitions

#### `LAN_ONLY` (Required)

| Property | Definition |
|----------|-----------|
| **Description** | Local signaling only. Cloud signaling disabled or unconfigured. |
| **Configuration source of truth** | Cloud URL env var absent, empty, or explicitly set to disable |
| **Expected peer visibility** | MUST contain only peers discovered via local signaling server (same IP room) |
| **Allowed fallback** | None — if local server unreachable, peer list is empty |
| **User-facing status label** | `LAN Only` (or equivalent) — MUST be visible in UI when active |
| **Trigger condition** | Cloud URL not configured OR explicitly disabled |

#### `HYBRID` (Required — Recommended Default)

| Property | Definition |
|----------|-----------|
| **Description** | Local + cloud signaling active simultaneously. Merged peer list. |
| **Configuration source of truth** | Both local URL and cloud URL configured and reachable |
| **Expected peer visibility** | MAY contain LAN peers (local server) AND internet peers (cloud server). Deduplicated. |
| **Deduplication policy** | First-discovery-wins by `peerCode`. Source tracked internally for signal routing. Peer removed only when originating source reports loss. |
| **Allowed fallback** | If one server unreachable, operates as effective LAN_ONLY or effective CLOUD_ONLY. MUST indicate degraded state. |
| **User-facing status label** | `Online` or `Hybrid` (or equivalent) — MUST be visible in UI when active |
| **Trigger condition** | Both local and cloud URLs configured; at least one connected |

#### `CLOUD_ONLY` (Optional Extension — Deferred)

| Property | Definition |
|----------|-----------|
| **Description** | Cloud signaling only. Local signaling unavailable or intentionally disabled. |
| **Status** | **DEFERRED** — reserved as future extension. Not codified for implementation in this stream. |
| **Trigger condition** | TBD — no current mechanism to disable local signaling while keeping cloud |
| **PM gate** | PM-DM-04 must approve before codification proceeds |

### Deduplication Policy (HYBRID Mode)

The following deduplication invariants apply when both local and cloud signaling are active:

| ID | Invariant |
|----|-----------|
| DM-DEDUP-01 | Each unique `peerCode` MUST appear at most once in the merged peer list |
| DM-DEDUP-02 | First source to discover a peer wins origin assignment |
| DM-DEDUP-03 | Signal routing MUST use recorded origin source for known peers |
| DM-DEDUP-04 | Peer removal MUST be source-aware — only the originating source can remove a peer |
| DM-DEDUP-05 | If a peer is discovered via both sources, subsequent discovery events for the same `peerCode` MUST be silently dropped |

### Deferred / Out of Scope

| Item | Rationale |
|------|-----------|
| Runtime implementation changes | DM-G1; governance/policy only |
| Transport/protocol changes | DM-G2; discovery is signaling-layer, not transport |
| CLOUD_ONLY implementation | DM-G4; deferred to future extension |
| Env var naming harmonization | Implementation concern; may be addressed in a future execution phase |
| Peer origin field in `DiscoveredDevice` | Implementation concern; AC defines the requirement, not the implementation |

---

### Scope Guardrails

| ID | Guardrail |
|----|-----------|
| DM-G1 | No runtime code changes in this stream |
| DM-G2 | No transport/protocol changes |
| DM-G3 | LAN_ONLY and HYBRID must be fully specified now |
| DM-G4 | CLOUD_ONLY may be codified only as optional future extension |
| DM-G5 | Existing dual-signaling intent must remain intact |

---

### DISCOVERY-MODE-1 Phase Table

| Phase | Description | Type | Serial Gate | Dependencies | Status |
|-------|-------------|------|-------------|--------------|--------|
| **DM1** | PM mode policy lock (default mode, UI requirements, CLOUD_ONLY disposition) | PM gate | YES — gates DM2 | None | NOT-STARTED |
| **DM2** | Mode indicator implementation across consumers | Engineering gate | YES — gates DM3 | DM1 complete | NOT-STARTED |
| **DM3** | Mode-aware acceptance test harness | Engineering gate | YES — gates DM4 | DM2 complete | NOT-STARTED |
| **DM4** | Env var harmonization + documentation alignment | Engineering gate | YES — closes stream | DM3 complete | NOT-STARTED |

#### Dependency DAG

```
DM1 (PM mode policy lock — no upstream dependencies)
  │
  ▼
DM2 (mode indicator implementation)
  │
  ▼
DM3 (acceptance test harness)
  │
  ▼
DM4 (env var harmonization + doc alignment + closure)
```

No upstream stream dependencies. DISCOVERY-MODE-1 is orthogonal to RUSTIFY-CORE-1, CONSUMER-BTR1, EGUI-NATIVE-1, and all other active streams.

---

### Acceptance Criteria

#### DM1 — PM Mode Policy Lock

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-DM-01 | Default discovery mode confirmed (HYBRID vs LAN_ONLY) — PM-DM-01 resolved | PM decision recorded |
| AC-DM-02 | User-facing mode toggle requirement confirmed — PM-DM-02 resolved | PM decision recorded |
| AC-DM-03 | Mode/origin UX wording requirements confirmed — PM-DM-03 resolved | PM decision recorded |
| AC-DM-04 | CLOUD_ONLY disposition confirmed (codify now vs defer) — PM-DM-04 resolved | PM decision recorded |

#### DM2 — Mode Indicator Implementation

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-DM-05 | Active discovery mode visible in UI for all 3 consumers | Screenshot per consumer |
| AC-DM-06 | Mode selection is deterministic: given configuration, mode is unambiguous | Config → mode mapping test |
| AC-DM-07 | LAN_ONLY enforced when cloud URL absent/disabled — peer list contains only local peers | Unit test + integration test |
| AC-DM-08 | HYBRID degraded state indicated when one server unreachable | Integration test |
| AC-DM-09 | No regressions in existing discovery/connect flows | Existing test suites pass |

#### DM3 — Acceptance Test Harness

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-DM-10 | Peer-list composition test per mode (LAN_ONLY: local-only; HYBRID: merged) | Test suite |
| AC-DM-11 | Deduplication correctness in HYBRID: same peer via both sources → single entry | Dedup test |
| AC-DM-12 | Source-aware loss correctness: peer removed only by originating source | Loss handling test |
| AC-DM-13 | Signal routing uses recorded origin source | Routing test |

#### DM4 — Env Var Harmonization + Closure

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-DM-14 | Env var naming consistent across all 3 consumers (or documented rationale for differences) | Config audit doc |
| AC-DM-15 | Mode semantics documented in each consumer's README/docs | Doc review |
| AC-DM-16 | No non-doc files changed in governance codification pass (this pass) | `git diff --name-only` audit |

---

### PM Open Decisions Table

| ID | Decision | Blocks | Priority | Status |
|----|----------|--------|----------|--------|
| PM-DM-01 | Default discovery mode: HYBRID (recommended) vs LAN_ONLY | DM2 | DM1 | PENDING |
| PM-DM-02 | User-facing mode toggle required? (toggle UI vs config-only) | DM2 | DM1 | PENDING |
| PM-DM-03 | Wording/UX for mode indicator and peer origin display | DM2 | DM1 | PENDING |
| PM-DM-04 | CLOUD_ONLY: codify now as optional mode, or defer entirely? | DM4 (if codified) | DM1 | PENDING |

---

### Risk Register

No material discovery-policy risks identified at codification. Rationale:

- Governance-only stream — no runtime changes in this pass
- Existing dual-signaling behavior is correct and tested
- Mode codification makes implicit behavior explicit without altering it
- No transport, security, or protocol implications

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
| CONSUMER-BTR-1 | localbolt-v3, localbolt, localbolt-app | `<repo-prefix>-cbtr<N>-<slug>` | `v3.0.90-cbtr1-btr-rollout` |
| C-stream (localbolt-core) | TBD (pending C1) | Deferred to C1 ARCH-08 disposition | — |
| D-stream (SDK) | bolt-core-sdk | `sdk-v<next>-d3-registry-migration` | `sdk-v0.5.28-d3-registry-migration` |
| D-stream (v3) | localbolt-v3 | `v3.0.<N>-d<phase>-<slug>` | `v3.0.75-d4-netlify-hardening` |
| D-stream (consumers) | localbolt, localbolt-app | `<repo-prefix>-d<phase>-<slug>` | `localbolt-v1.0.25-d3-registry-migration` |
| S-STREAM-R1 (daemon) | bolt-daemon | `daemon-vX.Y.Z-r1-<phase>-<slug>` | `daemon-v0.2.31-r1-2-key-arch` |
| S-STREAM-R1 (products) | localbolt-v3, localbolt, localbolt-app | `<repo-prefix>-r1-<phase>-<slug>` | `localbolt-v1.0.27-r1-3-crypto-converge` |
| N-stream | localbolt-app | `localbolt-app-vX.Y.Z-n<phase>-<slug>` | `localbolt-app-v1.3.0-n0-policy-lock` |
| N-stream (governance) | bolt-ecosystem | `ecosystem-v0.1.X-n-stream-1-<slug>` | `ecosystem-v0.1.72-n-stream-1-codify` |
| DR-STREAM-1 (SDK) [SUPERSEDED] | bolt-core-sdk | `sdk-vX.Y.Z-dr<phase>-<slug>` | — (no phases will execute) |
| DR-STREAM-1 (governance) [SUPERSEDED] | bolt-ecosystem | `ecosystem-v0.1.X-sec-dr1-<slug>` | `ecosystem-v0.1.99-sec-dr1-p0-codify` |
| BTR-STREAM-1 (SDK) | bolt-core-sdk | `sdk-vX.Y.Z-btr<phase>-<slug>` | `sdk-v0.6.0-btr0-spec-lock` |
| BTR-STREAM-1 (governance) | bolt-ecosystem | `ecosystem-v0.1.X-sec-btr1-<slug>` | `ecosystem-v0.1.100-sec-btr1-replaces-dr` |
| RUSTIFY-CORE-1 (SDK/daemon) | bolt-core-sdk, bolt-daemon | `sdk-vX.Y.Z-rc<phase>-<slug>` / `daemon-vX.Y.Z-rc<phase>-<slug>` | `sdk-v0.6.0-rc1-transport-matrix` |
| RUSTIFY-CORE-1 (governance) | bolt-ecosystem | `ecosystem-v0.1.X-rustify-core1-<slug>` | `ecosystem-v0.1.113-rustify-core1-codify` |
| EGUI-NATIVE-1 (app) | localbolt-app | `localbolt-app-vX.Y.Z-en<phase>-<slug>` | `localbolt-app-v1.3.0-en1-framework-lock` |
| EGUI-NATIVE-1 (governance) | bolt-ecosystem | `ecosystem-v0.1.X-egui-native1-<slug>` | `ecosystem-v0.1.115-egui-native1-codify` |
| DISCOVERY-MODE-1 (consumers) | localbolt-v3, localbolt, localbolt-app | `<repo-prefix>-dm<phase>-<slug>` | `v3.0.90-dm2-mode-indicator` |
| DISCOVERY-MODE-1 (governance) | bolt-ecosystem | `ecosystem-v0.1.X-discovery-mode1-<slug>` | `ecosystem-v0.1.116-discovery-mode1-codify` |
| Governance | bolt-ecosystem | `ecosystem-v0.1.X-workstreams-N` | `ecosystem-v0.1.30-workstreams-1` |

**Rules:**
- Determine next version number dynamically: `git tag --list '<prefix>*' | sort -V | tail -1`
- Tags are immutable. Once created, never moved, deleted, or reused.
- Each phase completion produces exactly one tag.
- Version numbers increment monotonically from the latest tag in each repo.

---

## Forward Backlog (Post-R17)

**Status:** Codified
**Codified:** ecosystem-v0.1.86-roadmap-codify-transfer-security-mobile (2026-03-08)
**Full specification:** `docs/FORWARD_BACKLOG.md`

9-item forward backlog covering transfer completion, release architecture, security, platform convergence, and mobile readiness. Summary:

| ID | Item | Priority | Routing | Status |
|----|------|----------|---------|--------|
| B-XFER-1 | Transfer pause/resume completion (daemon transfer SM remaining scope) | NOW | bolt-daemon | **DONE** (`daemon-v0.2.35-bxfer1-pause-resume`, `9f087a1`) |
| REL-ARCH1 | Multi-arch daemon build/package matrix | NOW | bolt-daemon + ecosystem | **DONE** (`daemon-v0.2.38-relarch1-multiarch-matrix`, `ab56606`) |
| SEC-DR1 | Double Ratchet pre-ByteBolt security gate (DR-STREAM-1) | ~~NEXT~~ | bolt-core-sdk + bolt-protocol | **SUPERSEDED-BY: SEC-BTR1** (frozen) |
| SEC-BTR1 | Bolt Transfer Ratchet pre-ByteBolt security gate (BTR-STREAM-1) | NEXT | bolt-core-sdk + bolt-protocol | **BTR-STREAM-1 COMPLETE** (BTR-0–5 DONE. Option C approved: default-on fail-open. PM-BTR-08/09/11 approved 2026-03-11) |
| CONSUMER-BTR1 | Consumer app BTR rollout (CONSUMER-BTR-1) | NOW | localbolt-v3, localbolt, localbolt-app | IN-PROGRESS. CBTR-1 DONE (burn-in PASSED). CBTR-2 P2 DONE (`localbolt-v1.0.36`, `e75271a`), burn-in active. CBTR-3 awaiting CBTR-2 burn-in. |
| T-STREAM-0 | Rust transfer core (no UDP in v1) | NEXT | `bolt-transfer-core` (bolt-core-sdk workspace) + daemon consumer | **DONE** (`sdk-v0.5.30-tstream0-transfer-core-v1`) |
| SEC-CORE2 | Rust-first security/protocol consolidation | NEXT | bolt-core-sdk | Provisionally SUPERSEDED-BY RUSTIFY-CORE-1 (pending PM-RC-07) |
| T-STREAM-1 | Browser selective WASM integration | LATER | bolt-core-sdk (TS) + WASM | NOT-STARTED |
| PLAT-CORE1 | Shared Rust core + thin platform UIs | LATER | TBD | Provisionally SUPERSEDED-BY RUSTIFY-CORE-1 (pending PM-RC-07) |
| MOB-RUNTIME1 | Mobile embedded runtime model | LATER | TBD | Provisionally DEPENDS-ON RUSTIFY-CORE-1 RC4 (pending PM-RC-07) |
| ARCH-WASM1 | WASM protocol engine (medium risk) | LATER | bolt-core-sdk + WASM | Provisionally DEPENDS-ON RUSTIFY-CORE-1 RC2 (pending PM-RC-07) |
| RECON-XFER-1 | Transfer reconnect recovery after mid-transfer disconnect | NOW | bolt-core-sdk (TS) + consumers | **DONE-VERIFIED (evidence tail: RX-EVID-1)** |
| EGUI-NATIVE-1 | Native desktop UI consolidation (egui) | LATER | localbolt-app + ecosystem | **CODIFIED** (`ecosystem-v0.1.115-egui-native1-codify`). 5 phases (EN1–EN5), 24 ACs, 5 PM decisions. EN1 openable in parallel with RUSTIFY-CORE-1; EN2+ blocked on RC4. |
| DISCOVERY-MODE-1 | Dual discovery mode policy codification | NEXT | ecosystem (governance) + consumers (implementation) | **CODIFIED** (`ecosystem-v0.1.116-discovery-mode1-codify`). 4 phases (DM1–DM4), 16 ACs, 4 PM decisions. No upstream dependencies. |

**SEC-DR1 → SUPERSEDED-BY: SEC-BTR1:** DR-STREAM-1 (Double Ratchet) frozen per PM-BTR-01 through PM-BTR-04. Replaced by BTR-STREAM-1 (Bolt Transfer Ratchet) — purpose-built transfer-scoped key agreement. DR P0 audit findings inherited. Full spec: `docs/GOVERNANCE_WORKSTREAMS.md` § BTR-STREAM-1. Frozen DR spec: `docs/GOVERNANCE_WORKSTREAMS.md` § DR-STREAM-1 [SUPERSEDED].

**RECON-XFER-1 (distinct from Q7/C7):** Post-C7 transfer-recovery bug. If disconnect occurs during active file transfer, reconnect gets stuck and new transfers fail to start. Browser path confirmed. Daemon-only path unconfirmed (escalation-only). Prior C7/Q7 work addressed stale callback pollution; this bug is about transfer SM + session coordination not resetting on mid-transfer disconnect. Full spec in `docs/FORWARD_BACKLOG.md` Item 10.

**B-XFER-1 / T-STREAM-0 boundary:** B-XFER-1 completes current daemon-local pause/resume behavior within existing `src/transfer.rs`. T-STREAM-0 extracts a shared `bolt-transfer-core` crate for cross-platform reuse. These are distinct scopes.

**UI-XFER-1 (companion to B-XFER-1):** SDK-side canonical DC control convergence (`sdk-v0.5.29-uixfer1-canonical-control`). Emit path uses `{ type: "pause"/"resume"/"cancel", transferId }` matching daemon wire format. Legacy file-chunk control flags removed from emit; retained on receive for backward compat (deprecated, removal target: next major). False completion race fixed. 17 new tests, consumers updated to `@the9ines/bolt-transport-web@0.6.5`.

**Sequencing constraint:** MOB-RUNTIME1 priority ≤ PLAT-CORE1 priority.

---

## Parallelization Rules

- **A-stream and B-stream CAN run in parallel.** They operate in different repos (bolt-core-sdk vs bolt-daemon) with no shared code changes.
- **Within A-stream:** Phases A1–A4 are sequential (each depends on the prior extraction). A5 depends on A1–A4.
- **Within B-stream (corrected AUDIT-GOV-27):**
  - B1→B2: sequential (B2 depends on B1 defaults). DONE.
  - B3+B6: coupled deliverable (transfer SM needs event loop; event loop needs SM). **Critical path.** B3-P1/P2/P3 done; pause/resume done (B-XFER-1); remaining: disk writes, concurrent transfers.
  - B4: **DONE** (`daemon-v0.2.27-b4-file-hash`). Receiver-side only; B3-P2 receive path was sufficient.
  - B5: **DONE** (`daemon-v0.2.23-b5-tofu-persist`). Independent.
  - D-E2E-A: **DONE** (`daemon-v0.2.28-d-e2e-a-live-transfer`). Live Rust↔Rust E2E.
  - D-E2E-B: **DONE** (`daemon-v0.2.30-d-e2e-b-cross-impl`). Cross-implementation TS↔Rust bidirectional E2E.
- **Within C-stream:** COMPLETE (C0–C7 all DONE).
- **Within D-stream:**
  - D0: DONE (policy locked; D0.5 scope verification passed).
  - D1: DONE (2026-03-05). Failure matrix produced. Top blocker: GHPKG-AUTH-FAIL.
  - D2: BLOCKED on D1 (evidence-driven).
  - D3: DONE (2026-03-05). All 3 deploy-critical packages published to npmjs.org. PAT-free install verified.
  - D4: DONE (2026-03-06). Consumer `.npmrc` cutover + Netlify deploy verified PAT-free.
  - D5: DONE (2026-03-06). Registry/auth regression guards + CI cleanup.
  - D6: UNBLOCKED. Burn-in window starts now (48h minimum).
- **Cross-stream dependency:** D-stream is independent of A-stream and B-stream. D-stream operates at CI/deploy/registry layer; A/B operate at SDK/daemon protocol layers. D-stream builds on C-stream outcomes (C6 guards as D5 baseline) but does not modify C-stream deliverables.
- **CONSUMER-BTR-1** is independent of all other streams. CBTR-1/2/3 are fully parallelizable (separate repos). Depends only on BTR-STREAM-1 completion (satisfied).
- **N-STREAM-1** is independent of A-stream, C-stream, D-stream, and S-STREAM-R1. N-STREAM-1 consumes B-STREAM API surface but does not modify B-STREAM deliverables. N-STREAM-1 N2 (IPC contract) has an implicit dependency on B-STREAM maturity — it stabilizes only the currently available daemon API surface.
- **Within N-stream:** N0 gates all. N1 ∥ N2 after N0. N3 after N2. N4 after N1+N2. N5 after N2+N3. N6 after N4+N5. N7 after N6.
- **EGUI-NATIVE-1** depends on RUSTIFY-CORE-1 RC4 for EN2+ execution. EN1 (PM framework lock) is a governance-only gate and may open in parallel with RUSTIFY-CORE-1 RC1–RC4. Within EN-stream: EN1 → EN2 → EN3 → EN4 → EN5 (fully serial). Independent of CONSUMER-BTR1, N-STREAM-1, and all other streams except RUSTIFY-CORE-1.
- **DISCOVERY-MODE-1** has no upstream stream dependencies. Fully orthogonal to RUSTIFY-CORE-1, CONSUMER-BTR1, EGUI-NATIVE-1, and all other streams. Within DM-stream: DM1 → DM2 → DM3 → DM4 (fully serial). DM1 (PM gate) unblocked immediately.

---

## No-Push Policy

**Default:** DO NOT push commits or tags to remote repositories during phase execution.

Pushes require explicit PM authorization. Phase reports are filed locally. The PM reviews and authorizes push as a separate action after phase report review.

This policy prevents half-completed workstream states from appearing on remote branches and ensures the PM has review authority over every remote state change.
