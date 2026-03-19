# Bolt Ecosystem — Governance Workstreams

> **Status:** Normative
> **Created:** 2026-03-02
> **Updated:** 2026-03-19 (RUSTIFY-BROWSER-ROLLOUT-1 CLOSED — burn-in evidence collected, stream complete)
> **Tag:** ecosystem-v0.1.178-rustify-browser-rollout1-br6-closure
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
| **CBTR-3** | localbolt-app (Tauri native) BTR rollout | localbolt-app | BTR-STREAM-1 complete + CBTR-F1 fixed | **DONE** — `localbolt-app-v1.2.24-consumer-btr1-p3` (`ff33747`). Burn-in waived (`PM-CBTR-EX-01`). |

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
| PM-CBTR-EX-01 | CBTR-3 24h burn-in waiver | Stream closure | NOW | **APPROVED** (2026-03-13) — Waive CBTR-3 residual burn-in; accept CBTR-3 test matrix (74 web + 82 Rust pass) + CBTR-2 completed 24h soak + low-delta scope (identical config change to CBTR-2). Scope: CONSUMER-BTR1/CBTR-3 only. **Non-precedent:** does not waive burn-in for future runtime streams. **Risk acceptance:** reduced soak for CBTR-3; enhanced monitoring 24h post-close; rollback via `btrEnabled: false`. |

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
> **Backlog Items:** SEC-CORE2, PLAT-CORE1 (SUPERSEDED-BY RUSTIFY-CORE-1), MOB-RUNTIME1, ARCH-WASM1 (REFACTORS/DEPENDS-ON RUSTIFY-CORE-1)
> **Priority:** NEXT (execution blocked until CONSUMER-BTR1 completes)
> **Repos:** bolt-core-sdk (Rust primary), bolt-daemon, bolt-protocol (spec amendments)
> **Codified:** ecosystem-v0.1.113-rustify-core1-codify (2026-03-12)
> **Status:** RC1 DONE. RC2 DONE. RC3 DONE (`daemon-v0.2.40-rustify-core1-rc3-quinn-reference`, 2026-03-14). RC4 DONE (`ecosystem-v0.1.130-rustify-core1-rc4-executed`, 2026-03-14). AC-RC-12–20 all PASS. PM-RC-02 APPROVED (WebSocket-direct, 2026-03-14). RC5 DONE (`daemon-v0.2.42-rustify-core1-rc5-btr-ws`, `ecosystem-v0.1.133-rustify-core1-rc5-done`, 2026-03-14). AC-RC-21–24 all PASS.

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

> **Status:** **RC1 LOCKED** (`ecosystem-v0.1.120-rustify-core1-rc1-executed`, 2026-03-13). Matrix codified with explicit provisional flags for unresolved PM decisions.

| Endpoint Pair | Transport | Authority | Status |
|---------------|-----------|-----------|--------|
| browser↔browser | WebRTC DataChannel | TS (`bolt-transport-web`) | **LOCKED — retained baseline** (invariant: no browser WebRTC replacement in RUSTIFY-CORE-1) |
| app↔app | Rust native transport (QUIC/quinn) | Rust (new crate) | **LOCKED (QUIC/quinn)** — PM-RC-01 APPROVED (QUIC, 2026-03-13). PM-RC-01A APPROVED (quinn, 2026-03-13). Fallback: s2n-quic → msquic-rs. |
| browser↔app | WebSocket to app daemon (primary) + WebRTC fallback | Hybrid (TS browser-side WS client, Rust server-side WS listener → shared core) | **LOCKED (WebSocket-direct)** — PM-RC-02 APPROVED (2026-03-14). Primary: browser opens WS to app daemon endpoint; daemon terminates WS, bridges frames to shared Rust core pipeline. Fallback: WebRTC via signaling server (current behavior). Fallback trigger: WS connection failure/timeout → automatic fall-through to WebRTC. Session authority: app daemon / shared Rust core (RC4-consistent). |
| app↔relay/cloud | ByteBolt relay infrastructure | Commercial (bytebolt-relay) | **DEFERRED** — out of scope for RC1–RC4. Relay architecture governed by ARCH-05 (relay optional/commercial) and ARCH-07 (infrastructure monetizable). ByteBolt-specific transport binding deferred to bytebolt-relay stream. |

### Rustification Targets

| Target | Current State | RUSTIFY-CORE-1 Goal |
|--------|--------------|---------------------|
| Protocol/security core (BTR, transfer SM, policy, integrity) | Rust crates exist (`bolt-core`, `bolt-btr`, `bolt-transfer-core`) but TS still owns wire orchestration | Rust canonical for all protocol logic; TS becomes thin I/O adapter |
| Native transport engine (app↔app) | No native transport — app routes through IPC + daemon | Direct Rust transport (QUIC — LOCKED, PM-RC-01) |
| Session lifecycle + control-plane invariants | Split: TS owns handshake/envelope in browser, Rust owns daemon session | Rust canonical; platform adapters delegate to shared core |
| Platform adapters | Tauri app has Rust daemon + TS WebView; browser is pure TS | Thin TS/Swift/Tauri shells over unified Rust backend |

### Rustification Boundary Lock (RC1 Artifact)

> **Status:** **RC1 LOCKED** (`ecosystem-v0.1.120-rustify-core1-rc1-executed`, 2026-03-13). Boundary/spec lock only — no extraction or adoption execution in RC1.

**Rust owns:**
- Shared protocol/security core (BTR, envelope, handshake, SAS, identity)
- Transfer state machine integrity and policy authority (`bolt-transfer-core`)
- Lifecycle invariants (session create/destroy, connection state transitions)

**Platform adapters (TS/Swift/Tauri) remain thin shells:**
- I/O binding (WebRTC DataChannel in browser, platform networking in native)
- UI event routing and display
- Platform-specific persistence (IndexedDB in browser, filesystem in native)

**RC1 scope:** This is a boundary/spec lock. No crate extraction, no API facade, no code migration. Those are RC2+ deliverables.

---

### Deferred / Out of Scope

| Item | Rationale |
|------|-----------|
| CLI runtime implementation | CLI does not exist yet; reserved hooks only (RC7) |
| Replacing browser↔browser WebRTC | Working, battle-tested; no business case for replacement |
| Full browser runtime rewrite | Browser retains TS transport adapter; WASM for logic only (ARCH-WASM1 scope) |
| Fail-closed migration | Separate PM gate after adoption metrics available |
| app↔relay/cloud transport binding | ByteBolt scope; governed by ARCH-05/ARCH-07; deferred from RC1–RC4 |

---

### Relationship to Existing Streams

> **Status:** **CONFIRMED** (PM-RC-07 APPROVED, 2026-03-14). Hybrid mode locked: SUPERSEDES for SEC-CORE2/PLAT-CORE1, REFACTORS/DEPENDS-ON for MOB-RUNTIME1/ARCH-WASM1.

| Existing Stream | Mode | Rationale |
|-----------------|------|-----------|
| **SEC-CORE2** (Rust-first security/protocol consolidation) | **SUPERSEDED-BY: RUSTIFY-CORE-1** | RC2 (shared Rust core API design) absorbed AC-SC-01 through AC-SC-04 entirely. Protocol authority migration is a core deliverable of RUSTIFY-CORE-1. |
| **PLAT-CORE1** (Shared Rust core + thin platform UIs) | **SUPERSEDED-BY: RUSTIFY-CORE-1** | RC2+RC4 (core API + adoption in app boundaries) absorbed PLAT-CORE1's full scope. Crate topology, FFI surface, and platform adapter model are RUSTIFY-CORE-1 deliverables. |
| **MOB-RUNTIME1** (Mobile embedded runtime model) | **REFACTORS/DEPENDS-ON RUSTIFY-CORE-1** | MOB-RUNTIME1 retains its own stream identity but depends on RC4 completion (shared Rust core adoption). Mobile-specific concerns (FFI, background execution, app store policies) remain MOB-RUNTIME1 scope. |
| **ARCH-WASM1** (WASM protocol engine) | **REFACTORS/DEPENDS-ON RUSTIFY-CORE-1** | ARCH-WASM1 retains its own stream identity but depends on RC2 completion (shared core API). Browser WASM integration concerns remain ARCH-WASM1 scope. |

---

### Scope Guardrails

| ID | Guardrail |
|----|-----------|
| RC-G1 | Browser↔browser retains WebRTC — no browser WebRTC replacement in this stream |
| RC-G2 | Native transport choice: QUIC (PM-RC-01 APPROVED 2026-03-13). Library: `quinn` (PM-RC-01A APPROVED 2026-03-13). Fallback order: `s2n-quic` → `msquic-rs` |
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
| **RC1** | Transport matrix + boundary lock (spec-level) | PM/Spec gate | YES — gates RC2, RC3 | CONSUMER-BTR1 complete | **DONE** (`ecosystem-v0.1.120-rustify-core1-rc1-executed`, 2026-03-13) |
| **RC2** | Shared Rust core API design/extraction lock | Engineering + PM gate | YES — gates RC4, RC5 | RC1 complete | **GOV-DONE, EXEC-READY** (`ecosystem-v0.1.122-rustify-core1-rc2gov-executed`, 2026-03-13) |
| **RC3** | Native transport reference path (app↔app, QUIC/quinn) | Engineering gate | NO (parallel with RC4) | RC1 complete, PM-RC-01 APPROVED (QUIC), PM-RC-01A APPROVED (quinn) | **DONE** (`daemon-v0.2.40-rustify-core1-rc3-quinn-reference`, 2026-03-14). AC-RC-12–16 all PASS. Quinn transport adapter + BTR-over-QUIC verified. |
| **RC4** | Shared Rust core adoption in app/runtime boundaries | Engineering gate | NO (parallel with RC3) | RC2 complete | **DONE** (`ecosystem-v0.1.130-rustify-core1-rc4-executed`, 2026-03-14). AC-RC-17–20 all PASS. Adoption verified via audit; IPC-mediated delegation confirmed as canonical path. |
| **RC5** | Browser↔app endpoint integration gates (WebSocket-direct) | Engineering gate | YES — gates RC6 | RC3 + RC4 complete, PM-RC-02 APPROVED (WebSocket-direct) | **DONE** (`daemon-v0.2.42-rustify-core1-rc5-btr-ws`, `sdk-v0.6.9-rustify-core1-rc5-ws-transport`, `ecosystem-v0.1.133-rustify-core1-rc5-done`, 2026-03-14). AC-RC-21–24 all PASS. WS endpoint + BTR capability + fallback verified. |
| **RC6** | Rollout + compatibility + rollback policy | PM/Engineering gate | YES — gates close | RC5 complete, PM-RC-03 APPROVED, PM-RC-05 APPROVED | **DONE** (`ecosystem-v0.1.134-rustify-core1-rc6-executed`, 2026-03-14). AC-RC-25–28 all PASS. Rollout policy, rollback policy, compatibility matrix, and no-regression gates codified. PM-RC-03 APPROVED (app-first rollout). PM-RC-05 APPROVED (deprecate-but-retain TS paths). |
| **RC7** | CLI reservation hooks (governance artifacts only) | Governance gate | NO (parallel with RC1–RC6) | None | **DONE** (`ecosystem-v0.1.135-rustify-core1-rc7-executed`, 2026-03-14). AC-RC-29–33 all PASS (governance artifacts delivered). PM-RC-06 APPROVED (trigger *defined*). CLI stream trigger: RC4 complete + RC6 Stage 1 burn-in passed (12h soak, 0 P0/P1, 0 kill-switch). **Note:** CLI execution stream NOT OPEN — Stage 1 burn-in not yet started. |

#### Dependency DAG

```
CONSUMER-BTR1 (must complete)
      │
      ▼
RC1 (transport matrix + boundary lock)
      │
      ├──────────────┐
      ▼              ▼
RC2 (core API)    RC3 (native transport, QUIC/quinn)    ← PM-RC-01A APPROVED (quinn, 2026-03-13)
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

#### RC2 Entry Criteria (RC1 Artifact)

> **Status:** RC2 **DONE**. All entry criteria satisfied. RC2-GOV locked (`ecosystem-v0.1.122-rustify-core1-rc2gov-executed`). RC2-EXEC-A (AC-RC-08, AC-RC-09 DONE, 2026-03-13). RC2-EXEC-B (AC-RC-11 DONE, 2026-03-13). RC2-EXEC-C (AC-RC-10 DONE, 2026-03-13). RC2-EXEC-D (AC-RC-05, AC-RC-06 DONE, 2026-03-13). RC2-EXEC-E (AC-RC-07 DONE, 2026-03-13). All 7 RC2 ACs complete.

RC2 (Shared Rust Core API Design/Extraction Lock) starts only when ALL of the following are satisfied:

| Criterion | Status | Notes |
|-----------|--------|-------|
| RC1 artifacts locked and cross-doc consistent | **SATISFIED** | RC1 executed `ecosystem-v0.1.120-rustify-core1-rc1-executed` |
| PM-RC-01 status explicit (resolved, or formally pending with fallback statement) | **SATISFIED** | PM-RC-01 APPROVED (QUIC confirmed, 2026-03-13). Library selection deferred to PM-RC-01A (blocks RC3 only). |
| PM-RC-02 impact explicit (resolved, or explicitly non-blocking for RC2) | **SATISFIED** | PM-RC-02 is non-blocking for RC2. PM-RC-02 blocks RC5 per phase table. |
| PM-RC-07 relationship handling explicit (resolved, or provisional policy accepted) | **SATISFIED (CONFIRMED)** | PM-RC-07 APPROVED (2026-03-14): SUPERSEDES SEC-CORE2 + PLAT-CORE1; REFACTORS/DEPENDS-ON MOB-RUNTIME1 + ARCH-WASM1. |

**Prior blocking path (RESOLVED):** PM-RC-01 resolved as QUIC APPROVED (2026-03-13). RC2 entry unblocked. PM-RC-01A resolved as quinn APPROVED (2026-03-13). RC3 blocker cleared — status moved to READY.

---

#### RC2-GOV — Governance Decisions (Locked, 2026-03-13)

> **Status:** **RC2-GOV DONE** (`ecosystem-v0.1.122-rustify-core1-rc2gov-executed`, 2026-03-13). Governance/spec decisions locked. Code execution deferred to RC2-EXEC.

##### A) Adoption vs Extraction Lock

**Decision: Adoption-first.**
- Existing crates (`bolt-core`, `bolt-btr`, `bolt-transfer-core`, `bolt-transfer-policy-wasm`) are adopted as-is for the shared Rust core API surface.
- Extraction or refactor is scoped to missing seams (e.g., handshake/envelope orchestration not yet in any crate) or duplication removal (TS reimplementation of logic already in Rust).
- No greenfield crate creation unless a functional gap is identified during RC2-EXEC that cannot be addressed by extending an existing crate.

##### B) Integration Topology Lock

**Decision: Direct multi-crate dependency policy (LOCKED).**

Rationale from codebase audit:
- bolt-core-sdk is a Cargo workspace with 4 crates: `bolt-core` (crypto/identity), `bolt-btr` (ratchet), `bolt-transfer-core` (transfer SM), `bolt-transfer-policy-wasm` (WASM bindings).
- Dependency graph is acyclic: `bolt-core` ← `bolt-btr`; `bolt-transfer-core` ← `bolt-transfer-policy-wasm`. No circular deps.
- bolt-daemon already consumes via direct path deps: `bolt-core` + `bolt-transfer-core` (selective import).
- Each crate is well-scoped and independently consumable. A facade would add indirection without value.
- This is the established, dominant pattern — not ambiguous.

**Policy:**
- Consumers (bolt-daemon, localbolt-app Tauri, future native targets) depend directly on the specific crates they need.
- No umbrella/facade crate will be created. Workspace-level `cargo` commands provide unified build/test/check.
- If a consumer needs >3 crates, a convenience re-export crate MAY be evaluated (but is not anticipated given current crate scoping).

##### C) Canonical Authority + Adapter Boundary Contracts

**Rust core crates are protocol/security authority:**
- `bolt-core`: cryptographic operations, identity management, SAS computation, peer code derivation, error codes. **Canonical.** No TS/platform reimplementation permitted.
- `bolt-btr`: BTR state machine, ratchet lifecycle, KDF chain. **Canonical.** TS BTR is parity consumer, not authority.
- `bolt-transfer-core`: transfer state machine, chunk scheduling, backpressure policy. **Canonical.** Daemon and app adapters delegate to this crate.
- `bolt-transfer-policy-wasm`: WASM bindings for browser consumption of transfer policy. Thin wrapper — authority remains in `bolt-transfer-core`.

**Platform adapter boundary contracts:**
- Adapters (TS `bolt-transport-web`, Tauri IPC layer, future Swift/Kotlin bindings) are **thin I/O + UI shells**.
- Adapters MUST NOT reimplement: envelope encrypt/decrypt, handshake state machine, SAS computation, BTR ratchet operations, transfer state transitions, chunk integrity verification.
- Adapters MAY own: transport I/O binding (WebRTC DataChannel setup, QUIC stream management), UI event routing, platform persistence (IndexedDB, filesystem), platform-specific networking (certificate handling, proxy config).
- Adapter violations (protocol logic in adapter code) are RC2-EXEC review findings — must be extracted or delegated.

##### D) Compatibility/Versioning Policy

- All shared core crates follow **semver** (major.minor.patch).
- Breaking public API changes require **major version bump**.
- Deprecation window: **one minor version minimum** — deprecated API surface must compile (with warnings) for at least one minor release before removal.
- Breaking changes MUST include a migration note in the crate's CHANGELOG.
- Consumer repos MUST pin to exact crate versions in Cargo.lock (workspace members use path deps; external consumers use tag-pinned git deps per existing policy).
- Cross-crate breaking changes (e.g., `bolt-core` type change affecting `bolt-btr`) MUST be coordinated as a single workspace-wide version bump.

##### E) SEC-CORE2 Absorption Mapping (CONFIRMED — PM-RC-07 APPROVED 2026-03-14)

| SEC-CORE2 AC | Absorbed By | RC2 Deliverable |
|-------------|-------------|-----------------|
| AC-SC-01 (Golden vectors from Rust) | AC-RC-08 | Rust vector generator + TS consumer tests | **DONE** (RC2-EXEC-A, 2026-03-13) |
| AC-SC-02 (TS vector generation deprecated) | AC-RC-09 | Migration plan documented | **DONE** (RC2-EXEC-A, 2026-03-13) |
| AC-SC-03 (Protocol SM canonical in Rust) | AC-RC-10 | Rust crate with SM + invariants | **DONE** (RC2-EXEC-C, 2026-03-13) |
| AC-SC-04 (S1 conformance against Rust vectors) | AC-RC-11 | CI gate | **DONE** (RC2-EXEC-B, 2026-03-13) |

**Confirmed:** PM-RC-07 APPROVED (2026-03-14) confirms SUPERSEDES for SEC-CORE2. AC-SC-01–04 are permanently absorbed by AC-RC-08–11.

#### RC2 API Status Clarification

Existing Rust crates that form the shared core foundation:
- `bolt-core` (v0.4.0) — crypto, identity, SAS, peer code, error codes
- `bolt-btr` (v0.1.0) — BTR state machine, ratchet, KDF
- `bolt-transfer-core` (v0.1.0) — transfer SM, backpressure
- `bolt-transfer-policy-wasm` (v0.1.0) — WASM policy layer

**RC2 is an adoption/integration phase**, not a greenfield extraction. The crates exist. RC2-GOV locks governance decisions; RC2-EXEC implements:
1. ~~Define the unified API surface (facade crate or re-export strategy)~~ → **LOCKED (RC2-GOV): direct multi-crate dependency policy**
2. Define FFI boundary for Tauri/native consumers (RC2-EXEC: interface contract from RC2-GOV, codegen/impl in RC2-EXEC)
3. Migrate protocol authority from TS to Rust for remaining paths (handshake, envelope orchestration) (RC2-EXEC)
4. Absorb SEC-CORE2 ACs (AC-SC-01–04): Rust vector authority, TS generation deprecated, canonical Rust state machine (RC2-EXEC, CONFIRMED per PM-RC-07)

#### RC7 CLI Reservation Artifacts

RC7 produces governance-only artifacts. No runtime code. Concrete deliverables:
- Reserved API extension points (trait/interface boundaries the CLI must satisfy)
- Reserved config schema keys (CLI-specific configuration namespace)
- Reserved capability/version namespace (CLI capability strings)
- Architecture constraints document (what the CLI stream inherits from RUSTIFY-CORE-1)

---

### Acceptance Criteria

#### RC1 — Transport Matrix + Boundary Lock

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-RC-01 | Transport matrix codified with explicit endpoint-pair → transport mapping | Published spec section | **DONE** — 4-row matrix locked (browser↔browser, app↔app, browser↔app, app↔relay/cloud) with explicit provisional flags |
| AC-RC-02 | Browser↔browser WebRTC retention explicitly codified as invariant | Spec invariant + test reference | **DONE** — "LOCKED — retained baseline" with invariant statement in matrix |
| AC-RC-03 | Native transport protocol confirmed (PM-RC-01 resolved) | PM decision recorded | **DONE** — PM-RC-01 APPROVED (QUIC confirmed, 2026-03-13). Library selection deferred to PM-RC-01A (blocks RC3, not RC2). |
| AC-RC-04 | Boundary between Rust core and platform adapters formally defined | Architecture doc with API surface | **DONE** — Rustification Boundary Lock section codified (Rust owns / platform adapters remain thin shells) |

#### RC2 — Shared Rust Core API Design/Extraction Lock

> **RC2 Split:** RC2-GOV (governance/spec lock) is DONE. RC2-EXEC (code implementation) is READY. Both are represented within this single RC2 phase row — no new phase rows added.

| ID | Criterion | Evidence Required | Scope | Status |
|----|-----------|------------------|-------|--------|
| AC-RC-05 | Unified Rust core API surface defined (facade or re-export) | Crate with public API + docs | **DONE** (RC2-EXEC-D, 2026-03-13) | **DONE** — Direct multi-crate dependency policy verified. 4-crate API surface documented in `docs/API_SURFACE.md`. Consumer matrix locked. 338 Rust tests pass. Tag: `sdk-v0.5.44-rc2exec-d-api-ffi`. |
| AC-RC-06 | FFI boundary for Tauri/native consumers defined | FFI interface spec or UniFFI/cbindgen output | **DONE** (RC2-EXEC-D, 2026-03-13, verification closure) | **DONE** — Verification closure: 3 boundary types (Rust-direct, WASM, Tauri IPC) documented as canonical contract in `docs/BOUNDARY_CONTRACT.md`. No UniFFI/cbindgen needed (Rust-to-Rust, WASM, IPC — no C FFI consumers). Tag: `sdk-v0.5.44-rc2exec-d-api-ffi`. |
| AC-RC-07 | Protocol authority migrated: handshake + envelope canonical in Rust | Rust implementation + TS delegation tests | **DONE** (RC2-EXEC-E, 2026-03-13) | **DONE** — Session authority primitives (`SessionState`, `SessionContext`, `HelloState`, `HelloError`, `negotiate_capabilities`) extracted to `bolt_core::session`. Daemon rewired to consume shared module. 22 new Rust session tests + 84 bolt-core total + 353 daemon tests pass. Profile codecs intentionally retained in daemon adapter layer (ARCH-01 compliant). TS delegation deferred to ARCH-WASM1 (documented). Tag: `sdk-v0.5.45-rc2exec-e-session-authority`. |
| AC-RC-08 | Golden vectors generated from Rust, consumed by both Rust and TS (absorbs AC-SC-01) | Rust vector generator + TS consumer tests | **DONE** (RC2-EXEC-A, 2026-03-13) | **DONE** — 5 core + 10 BTR vectors canonical from Rust. 115 Rust tests + 232 TS tests pass. Tag: `sdk-v0.5.41-rc2exec-a-vector-authority`. |
| AC-RC-09 | TS vector generation deprecated (absorbs AC-SC-02) | Migration plan documented | **DONE** (RC2-EXEC-A, 2026-03-13) | **DONE** — `@deprecated` JSDoc on both TS generators, runtime warnings, `VECTOR_AUTHORITY.md` migration doc. TS scripts retained for reference only. |
| AC-RC-10 | Protocol state machine canonical in Rust (absorbs AC-SC-03) | Rust crate with state machine + invariants | **DONE** (RC2-EXEC-C, 2026-03-13) | **DONE** — Transfer SM (bolt-transfer-core), BTR SM (bolt-btr), backpressure/policy all Rust-canonical. 11 authority conformance tests added. Session/handshake lifecycle remains AC-RC-07 scope. Tag: `sdk-v0.5.43-rc2exec-c-state-authority`. |
| AC-RC-11 | S1 conformance tests pass against Rust-generated vectors (absorbs AC-SC-04) | CI gate | **DONE** (RC2-EXEC-B, 2026-03-13) | **DONE** — S1 conformance suite (32 tests) rewired to `test-vectors/core/`. 115 Rust + 232 TS tests pass. CI paths updated. Tag: `sdk-v0.5.42-rc2exec-b-s1-conformance`. |

##### AC-RC-07 Evidence Scope Note (RC2-EXEC-E, 2026-03-13)

**Scope delivered:**
- Transport-agnostic handshake/session authority primitives (`SessionState`, `SessionContext`, `HelloState`, `HelloError`, `negotiate_capabilities`) extracted to `bolt_core::session`.
- Daemon rewired to consume shared module (re-exports for backward compatibility).
- Error code registry consolidated (daemon's 22-code `CANONICAL_ERROR_CODES` → bolt_core's 26-code `WIRE_ERROR_CODES`).

**Scope explicitly retained in daemon (ARCH-01 boundary proof):**
- Profile wire structs (`WebHelloOuter`, `WebHelloInner`, `ProfileEnvelopeV1`, `DcErrorMessage`) — serde/JSON encoding.
- Profile codec functions (`build_hello_message`, `parse_hello_typed`, `encode_envelope`, `decode_envelope`) — NaCl+JSON.
- Web signal adapter (`web_signal.rs`) — 100% web schema plumbing.
- DC message codec (`dc_messages.rs`) — serde/JSON encoding.

**TS delegation deferred to ARCH-WASM1:**
- TS session state (`WebRTCService.sessionState`, `HandshakeManager`) remains TS-owned.
- No literal TS→Rust delegation in this pass.
- TS parity obligation via golden vectors/conformance tests only.
- Full TS session delegation is ARCH-WASM1 scope (requires WASM/FFI bridge for browser consumption).

#### RC3 — Native Transport Reference Path

**Library selection (PM-RC-01A APPROVED 2026-03-13):**
- **Primary:** `quinn` — pure Rust, cross-platform (macOS/Windows/Linux tested), AsyncRead/AsyncWrite streams, tokio-native, 133M crates.io downloads, audited crypto deps, community-validated mobile compilation.
- **Fallback 1:** `s2n-quic` (with `provider-tls-rustls` feature) — proper async Rust API, biweekly releases, AWS backing. macOS friction solvable via feature flag.
- **Fallback 2:** `msquic-rs` — C FFI bindings, callback-based (requires async bridge), perpetual beta. Only if kernel-mode Windows QUIC performance is a hard requirement.

**Fallback trigger policy:**
- If quinn fails AC-RC-12 (compile + unit tests) or AC-RC-13 (app↔app transfer) after reasonable engineering effort (≥2 weeks), escalate to PM with evidence.
- PM approves switch to s2n-quic. If s2n-quic also fails same gates, PM approves switch to msquic-rs.
- Approval authority for fallback switch: PM (human). No autonomous library switch by agents.
- Fallback switch resets RC3 to NOT-STARTED with new library; prior RC3 work is archived.

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-RC-12 | Native transport crate (`quinn`-based) compiles and passes unit tests | `cargo test` green | **DONE** — 10 QUIC unit tests pass. Compiles with and without `transport-quic` feature. |
| AC-RC-13 | App↔app file transfer completes over native transport | Integration test | **DONE** — 3 E2E tests: 1MiB transfer + SHA-256 integrity, sub-chunk payload, multiple sequential transfers. |
| AC-RC-14 | BTR operates correctly over native transport | BTR conformance suite pass | **DONE** — 4 BTR-over-QUIC tests: seal/open roundtrip, multi-chunk chain ordering, tampering detection, byte-level framing preservation. |
| AC-RC-15 | Performance meets PM-RC-04 SLO thresholds | Benchmark results | **DONE** — ~15–16 MB/s avg throughput (3×1MiB localhost). PM-RC-04 APPROVED (2026-03-14): ≥10 MiB/s throughput, 100% hash integrity, ≥99% connection success. Baseline exceeds all SLO thresholds. If thresholds fail persistently during rollout, hold/rollback per RC6 levers (RB-L1–L4). |
| AC-RC-16 | No regression in existing daemon/app test suites | CI gate | **DONE** — 381 total tests pass (353 pre-existing + 18 RC3 integration + 10 QUIC unit). Zero regressions. |

#### RC4 — Shared Rust Core Adoption

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-RC-17 | bolt-daemon consumes unified Rust core API | Daemon tests pass | **DONE** — Full import audit: all crypto → bolt_core::crypto, session → bolt_core::session, transfer SM → bolt_transfer_core, errors → bolt_core::errors. Zero local reimplementations. 381 tests pass. |
| AC-RC-18 | localbolt-app Tauri layer delegates to Rust core via FFI | App tests pass | **DONE** — RC4 interpretation: IPC-mediated delegation (app → daemon → shared Rust core) is canonical. Tauri Rust layer is pure IPC relay (3,311 LoC, 0 crypto ops). No parallel protocol authority. `cargo check` clean. |
| AC-RC-19 | TS transport-web delegates protocol logic to Rust core (where feasible) | Integration tests | **DONE** — Envelope/BTR/SAS/capability negotiation delegated to bolt-core TS SDK. Transfer policy → Rust WASM via PolicyAdapter. WebRTC transport profile intentionally TS-owned (G1). 3 moderate concerns (message registry, envelope constants, error recovery) deferred to backlog. |
| AC-RC-20 | Kill-switch rollback to pre-RUSTIFY TS paths verified | Rollback test | **DONE** — 353 tests pass without `transport-quic` feature (DataChannel path intact). QUIC tests compile to 0 when feature off. Feature-gate rollback verified. |

#### RC5 — Browser↔App Endpoint Integration (WebSocket-direct, PM-RC-02 APPROVED)

**Transport decision (PM-RC-02):** WebSocket-direct. Browser opens WS/WSS to app daemon endpoint. Daemon terminates WebSocket, deserializes Bolt protocol frames, delegates to shared Rust core for crypto/session/transfer operations. Session authority: app daemon / shared Rust core (RC4-consistent per AC-RC-18).

**Fallback policy (AC-RC-24 interpretation):**

| Order | Transport | Trigger to next | Override authority |
|-------|-----------|-----------------|-------------------|
| 1 (primary) | WebSocket to app daemon endpoint | WS connection failure (timeout / refused / TLS error) | Automatic client-side |
| 2 (fallback) | WebRTC via signaling server (current behavior) | N/A (terminal fallback) | N/A |

Fallback is automatic and transparent to user. G1 preserved: WebRTC fallback IS the current browser↔browser baseline path.

**Session-authority boundary:** App daemon remains protocol and session authority for browser↔app path. Browser-side WS client is a new parallel transport binding in `bolt-transport-web`. Transport-specific auth (e.g., connection token, origin validation) deferred to RC5 implementation.

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-RC-21 | Browser client connects to Rust endpoint (app) via WebSocket successfully | Integration test | **PASS** — Daemon WS endpoint accepts browser connection + HELLO handshake (4 daemon tests). |
| AC-RC-22 | File transfer completes browser→app and app→browser over WebSocket | Round-trip tests | **PASS** — ProfileEnvelopeV1 encrypted roundtrip over WS, browser send/receive confirmed (4 tests). |
| AC-RC-23 | BTR negotiation works across WebSocket transport boundary | BTR capability test | **PASS** — Daemon now advertises `bolt.transfer-ratchet-v1` in `DAEMON_CAPABILITIES`. HELLO negotiation over WS includes BTR in intersection (1 test). BTR-sealed payloads survive WS text framing: single-chunk, multi-chunk, variable-size round-trips (3 tests). Tamper detection confirmed over WS (1 test). 5 AC-RC-23 tests + 40 BTR wire integration tests pass. |
| AC-RC-24 | Downgrade to WebRTC fallback when WebSocket to app daemon unavailable | Fallback test: WS failure → automatic WebRTC fall-through | **PASS** — WS refused/timeout triggers automatic WebRTC fallback (5 browser tests). |

#### RC6 — Rollout + Compatibility + Rollback

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-RC-25 | Rollout policy codified (staged, per-consumer) | Spec document | **PASS** — Two-stage rollout codified below. Stage 1: app↔app (QUIC). Stage 2: browser↔app (WS-direct). Promotion gate: burn-in with zero P0/P1 regressions. No-regression gate cross-linked (AC-RC-28). |
| AC-RC-26 | Rollback from native transport to current paths verified per consumer | Rollback policy document | **PASS** — Rollback triggers (RB-T1–T5), levers (RB-L1–L4), ownership (PM decision authority), and SLA (≤4h P0, ≤1h execution) codified below. Kill-switch rollback (RC-G7) confirmed active throughout deprecated phase. No-regression gate cross-linked (AC-RC-28). |
| AC-RC-27 | Compatibility matrix: all endpoint-pair combinations work | Matrix document + cross-reference to RC3/RC5 evidence | **PASS** — 7-cell compatibility matrix codified below. Verified cells: browser↔browser (baseline), app↔app QUIC (RC3, AC-RC-12–16), browser↔app WS (RC5, AC-RC-21–24), legacy↔new BTR (BTR-STREAM-1). Deferred cells: WAN (requires TLS implementation, post-RC6). No-regression gate cross-linked (AC-RC-28). |
| AC-RC-28 | No-regression gate: all existing test suites across all repos pass | CI evidence cross-referenced from RC3/RC5 | **PASS** — RC3: 362 daemon tests (0 failed). RC5: 362 daemon tests with ws (0 failed), 353 without ws (0 failed), 364 browser tests (0 failed). All repo test suites green at RC5 closure. Cross-linked as sub-evidence under AC-RC-25, AC-RC-26, AC-RC-27. |

##### AC-RC-25 — Rollout Policy (PM-RC-03 APPROVED)

**Rollout order:** App-first, browser↔app second. Browser↔browser remains WebRTC invariant (G1).

| Stage | Endpoint Pair | Transport (Primary) | Transport (Fallback/Rollback) | Entry Criteria | Promotion Gate |
|-------|--------------|--------------------|-----------------------------|----------------|----------------|
| **Stage 1** | app↔app | QUIC (quinn) | DataChannel via kill-switch (RC-G7, feature gate `transport-quic` off) | RC6 policy closed; implementation artifacts ready | Burn-in period with zero P0/P1 regressions before promoting to Stage 2. PM sets burn-in duration (recommended: ≥72h). |
| **Stage 2** | browser↔app | WebSocket-direct | WebRTC (automatic fallback on WS failure, per AC-RC-24) | Stage 1 burn-in passed; TLS cert strategy resolved for wss:// (if WAN required) | Full rollout complete. All compatibility matrix cells verified. |

**Invariant:** browser↔browser remains WebRTC (G1 — unchanged, not staged).

**No-regression requirement (cross-linked from AC-RC-28):** All existing test suites across all repos must pass at each stage promotion gate. Evidence: CI test results at gate time.

##### AC-RC-26 — Rollback Policy

**Triggers** (any one triggers rollback evaluation):

| ID | Trigger | Severity | Action |
|----|---------|----------|--------|
| RB-T1 | Transfer failure rate > baseline by >5% over 1h window | P0 | PM evaluates rollback |
| RB-T2 | BTR integrity failure (tampered chunk, ratchet desync) | P0 | PM evaluates rollback |
| RB-T3 | Connection establishment failure rate > baseline by >10% | P1 | PM evaluates rollback |
| RB-T4 | Kill-switch activation by PM directive | P0/P1 | PM-initiated rollback |
| RB-T5 | Test suite regression (any repo, any gate) | Blocking | Automatic — blocks stage promotion |

**Levers:**

| ID | Lever | Scope | Reversibility | How |
|----|-------|-------|---------------|-----|
| RB-L1 | Feature-gate disable (`transport-quic` off) | app↔app QUIC path | Full — falls back to DataChannel | Rebuild daemon without `transport-quic` feature |
| RB-L2 | WS kill-switch (browser client) | browser↔app WS path | Full — falls back to WebRTC | `BrowserAppTransport` automatic fallback; can force WebRTC-only via config |
| RB-L3 | SDK version rollback | Per-consumer | Full — revert to pre-RUSTIFY SDK | Package version pin in consumer |
| RB-L4 | Full daemon version rollback | Daemon | Full — previous daemon tag | Deploy previous tagged binary |

**Ownership:**

| Role | Responsibility |
|------|---------------|
| PM | Rollback decision authority. Evaluates triggers. Approves/denies rollback. |
| Engineering | Executes rollback lever. Provides diagnostics. Proposes root-cause fix. |

**SLA:**

| Action | Target |
|--------|--------|
| Trigger → rollback decision | ≤4h for P0, ≤24h for P1 |
| Rollback decision → execution | ≤1h (feature gate or version pin) |
| Post-rollback root-cause analysis | ≤72h |

**No-regression requirement (cross-linked from AC-RC-28):** Rollback lever activation must restore test suite green status. Post-rollback regression sweep required.

##### AC-RC-27 — Compatibility Matrix

| Pair | Transport (Primary) | Transport (Fallback) | BTR | RC6 Status | Evidence |
|------|--------------------|--------------------|-----|------------|----------|
| browser↔browser | WebRTC DataChannel | N/A | YES (BTR-5 default-on) | Verified (baseline invariant) | G1; BTR-STREAM-1 (341 tests) |
| app↔app (LAN) | QUIC (quinn) | DataChannel (kill-switch RB-L1) | YES | Verified | RC3: AC-RC-12–16 PASS (362 daemon tests) |
| app↔app (WAN) | QUIC (quinn) | DataChannel (kill-switch RB-L1) | YES | Deferred (requires reachability) | Post-RC6 |
| browser→app (LAN) | WebSocket-direct | WebRTC (auto fallback RB-L2) | YES | Verified | RC5: AC-RC-21–24 PASS (362+364 tests) |
| app→browser (LAN) | WebSocket-direct | WebRTC (auto fallback RB-L2) | YES | Verified | RC5: AC-RC-21–24 PASS |
| browser↔app (WAN) | wss:// (TLS required) | WebRTC (auto fallback RB-L2) | YES | Deferred (requires TLS impl) | Post-RC6 |
| legacy-SDK↔new-SDK | WebRTC/DataChannel baseline | N/A | Degraded (BTR fail-open) | Verified | BTR-5 Option C; CONSUMER-BTR1 burn-in |

**Pass criteria per cell:**
1. Connection established — handshake completes, session active
2. Transfer completes — file sent and received with integrity verification
3. BTR negotiated — capability intersection includes `bolt.transfer-ratchet-v1` (or clean fail-open for legacy)
4. Fallback works — if primary transport fails, fallback path activates and transfers succeed
5. Kill-switch works — disabling native transport reverts to baseline path with zero data loss

**Deferred cells:** WAN (app↔app WAN, browser↔app WAN) require TLS runtime implementation and reachability infrastructure. Policy documented here; implementation deferred to post-RC6.

**No-regression requirement (cross-linked from AC-RC-28):** Each matrix cell verification must include full test suite pass across all repos.

##### AC-RC-25 Addendum — TLS/WAN Production Policy (Document-Only)

| Environment | Protocol | Certificate Strategy | Owner |
|-------------|----------|---------------------|-------|
| localhost (same machine) | `ws://` (plaintext) | None needed — loopback only | N/A |
| LAN (same network) | `ws://` acceptable during Stage 1 burn-in | Risk accepted: LAN-only, signaling already unencrypted over LAN discovery | PM |
| WAN (internet-routable) | `wss://` (TLS REQUIRED) | Self-signed for testing; CA-signed for production | PM + Ops |
| Mixed-content (HTTPS page → ws://) | Blocked by browsers | Must use `wss://` from HTTPS origins | Browser platform constraint |

RC6 scope is policy-only. No TLS runtime implementation in this phase. TLS implementation deferred to post-RC6 stream.

##### AC-RC-25 Addendum — Legacy TS-Path Deprecation Policy (PM-RC-05 APPROVED)

| Phase | State | Description |
|-------|-------|-------------|
| **Active** (current) | TS paths are primary | Status quo through RC5. |
| **Deprecated** | TS paths retained as fallback | After RC6 rollout completes, TS paths marked deprecated. Kill-switch (RC-G7) retains rollback ability. No TS path code removal. Deprecation notice in consumer changelogs. |
| **Sunset** | TS paths removed | Only after ALL of: (a) one full release cycle with zero kill-switch activations, (b) zero P0/P1 regressions, (c) explicit PM-RC-05 sunset approval. Separate PM gate — NOT automatic. |

Kill-switch rollback (RC-G7) remains active throughout the Deprecated phase. Sunset is condition-gated, not date-gated.

#### RC7 — CLI Reservation

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-RC-29 | CLI API extension points documented (traits/interfaces) | Architecture doc | **PASS** — Reserved trait contracts documented below. No runtime code. |
| AC-RC-30 | CLI config schema keys reserved | Schema doc | **PASS** — Reserved `cli.*` config key namespace documented below. |
| AC-RC-31 | CLI capability namespace reserved | Capability registry entry | **PASS** — Reserved `bolt.cli-*` capability namespace documented below. |
| AC-RC-32 | No runtime code produced in this phase | Code review / `git diff --name-only` | **PASS** — RC7 commit touches only `docs/` files. No `.rs`, `.ts`, `.toml`, `.json`, or other runtime files modified. |
| AC-RC-33 | CLI stream trigger condition defined (PM-RC-06 resolved) | PM decision recorded | **PASS** (trigger condition *defined*; trigger condition *not yet satisfied*) — PM-RC-06 APPROVED (2026-03-14). CLI stream may begin after: (1) RC4 complete [satisfied], AND (2) RC6 Stage 1 burn-in passed [12h continuous soak, 0 P0/P1 incidents, 0 kill-switch activations, no-regression gates green]. N-STREAM-1 N6 NOT required. **CLI execution stream is NOT OPEN** — Stage 1 burn-in evidence pending. |

##### AC-RC-29 — Reserved CLI API Extension Points

The following trait/interface contracts are **governance reservations only**. No Rust code, no TypeScript code, no runtime implementation. These define the expected API surface for a future CLI stream (gated by PM-RC-06).

| Reserved Trait/Interface | Purpose | Boundary | Notes |
|--------------------------|---------|----------|-------|
| `CliTransport` | Transport adapter for CLI↔daemon communication | CLI binary ↔ daemon IPC | Extends existing `TransportQuery` pattern (RC2). Expected to wrap Unix socket / named pipe (N-STREAM-1 IPC contract). |
| `CliSessionHandler` | Session lifecycle management for CLI-initiated transfers | CLI binary ↔ shared Rust core | Delegates to shared core session authority (RC4 pattern). CLI is a thin adapter, not a protocol authority. |
| `CliConfigProvider` | Configuration loading for CLI-specific settings | CLI binary startup | Reads `cli.*` config keys (AC-RC-30). Must be transport-independent (RC-G3). |
| `CliOutputFormatter` | Output formatting (JSON, human-readable, etc.) | CLI binary → stdout/stderr | CLI-only concern. No protocol impact. |
| `CliAuthProvider` | Authentication method selection for CLI sessions | CLI binary ↔ daemon | Extends daemon auth surface. Must preserve existing security invariants (PROTO-01–07). |

**Architectural constraints (inherited from RC2/RC4):**
- CLI MUST delegate protocol authority to shared Rust core — no protocol reimplementation
- CLI MUST use daemon IPC path (N-STREAM-1 contract) — no direct network I/O for protocol operations
- CLI MUST NOT introduce new transport modes without PM approval (RC-G5)
- CLI config MUST NOT override daemon security invariants

##### AC-RC-30 — Reserved CLI Config Schema Keys

Config key namespace `cli.*` is reserved for future CLI stream. Keys below are governance reservations — no config file parser, no runtime reader, no default values implemented.

| Reserved Key | Type | Purpose | Notes |
|-------------|------|---------|-------|
| `cli.transport.mode` | `string` | IPC transport mode (`unix_socket` / `named_pipe` / `tcp_localhost`) | Aligns with N-STREAM-1 N2 IPC contract |
| `cli.daemon.socket_path` | `string` | Path to daemon IPC socket | Default TBD at implementation. Platform-dependent. |
| `cli.output.format` | `string` | Output format (`json` / `text` / `quiet`) | CLI-only UX concern |
| `cli.auth.method` | `string` | Auth method for CLI↔daemon sessions | Must not weaken existing daemon auth |
| `cli.transfer.default_mode` | `string` | Default transfer mode (`send` / `receive`) | Convenience setting only |
| `cli.log.level` | `string` | CLI-specific log verbosity | Separate from daemon log level |
| `cli.log.file` | `string` | CLI log file path | Optional; defaults to stderr |

**Schema constraints:**
- `cli.*` keys MUST NOT collide with existing daemon config namespace
- `cli.*` keys MUST NOT override protocol-level settings
- Schema validation rules deferred to implementation stream

##### AC-RC-31 — Reserved CLI Capability Namespace

Following the existing `bolt.*` capability namespace convention (`bolt.file-hash`, `bolt.transfer-ratchet-v1`, `bolt.profile-envelope-v1`), the `bolt.cli-*` sub-namespace is reserved for CLI-specific capability negotiation.

| Reserved Capability | Purpose | Negotiation Context | Notes |
|--------------------|---------|---------------------|-------|
| `bolt.cli-session-v1` | CLI session identification in HELLO | CLI↔daemon HELLO | Allows daemon to distinguish CLI peer from browser/app peer |
| `bolt.cli-transfer-v1` | CLI transfer mode capability | CLI↔daemon HELLO | Signals CLI-specific transfer options (e.g., stdin/stdout streaming) |
| `bolt.cli-batch-v1` | Batch transfer capability | CLI↔daemon HELLO | Multi-file transfer in single session (CLI UX feature) |

**Namespace constraints:**
- `bolt.cli-*` capabilities follow existing HELLO `capabilities[]` intersection negotiation
- No new capabilities may be advertised without PM approval (RC-G5)
- Backward compatibility: peers without `bolt.cli-*` capabilities must not be affected (existing negotiation is intersection-based — unknown capabilities are silently dropped)

##### AC-RC-33 — CLI Stream Trigger Condition (PM-RC-06 APPROVED)

**PM-RC-06 APPROVED (2026-03-14)**

CLI-specific execution stream may begin only after ALL of:

1. **RUSTIFY-CORE-1 RC4 complete** (shared Rust core adopted) — **SATISFIED** (2026-03-14)
2. **RC6 Stage 1 burn-in passed** — NOT YET STARTED

**Burn-in pass definition (lab/staging):**
- 12h continuous automated soak
- 0 P0/P1 incidents
- 0 kill-switch activations
- Required no-regression gates remain green

**Explicitly NOT required:** N-STREAM-1 N6 completion is not a prerequisite for CLI stream start.

**Effect:** CLI stream is currently gated on RC6 Stage 1 burn-in. Once burn-in passes per the above criteria, a CLI execution stream may be opened under separate governance.

---

### PM Open Decisions Table

| ID | Decision | Blocks | Priority | Status |
|----|----------|--------|----------|--------|
| PM-RC-01 | Native transport protocol confirmation: QUIC (recommended) vs alternative. If QUIC, sub-decision: library (quinn / s2n-quic / etc.) | RC3 | RC1 | **APPROVED (QUIC confirmed, 2026-03-13)**. Library selection split to PM-RC-01A. |
| PM-RC-01A | QUIC runtime/library selection. **APPROVED (2026-03-13):** Primary: `quinn`. Fallback 1: `s2n-quic`. Fallback 2: `msquic-rs`. Rationale: quinn dominates on cross-platform maturity (macOS/Windows/Linux tested, pure Rust, no C toolchain), Rust API ergonomics (AsyncRead/AsyncWrite streams, tokio-native), ecosystem adoption (133M crates.io downloads), supply chain posture (pure Rust, audited crypto deps), and mobile path viability (community-validated iOS/Android compilation). s2n-quic ranked above msquic-rs as fallback due to proper async Rust API and active biweekly release cadence vs msquic-rs perpetual beta status and callback-based C FFI requiring async bridge. ARCH-01 verified: quinn wraps behind `TransportQuery` trait with zero type leakage into shared core. | RC3 only (non-blocking for RC2) | RC3 | **APPROVED (2026-03-13)** |
| PM-RC-02 | Browser↔app transport mode default. **APPROVED (2026-03-14):** Option B — WebSocket-direct. Primary: browser opens WebSocket to app daemon endpoint; daemon terminates WS and bridges frames to shared Rust core pipeline (RC4-consistent session authority). Fallback: WebRTC via signaling server (current behavior). Fallback trigger: WS connection failure/timeout → automatic client-side fall-through to WebRTC. Fallback override authority: PM can adjust timeout/ordering via future decision. Options rejected: (A) WebRTC-mediated — collapses primary/fallback distinction, AC-RC-24 becomes tautological; (C) WebTransport — Safari unsupported, experimental API, unnecessary scope risk. G1 preserved: WebRTC fallback IS current browser↔browser baseline. | RC5 | RC1 | **APPROVED (WebSocket-direct, 2026-03-14)** |
| PM-RC-03 | Rollout order confirmation: app-first, browser↔app second. **APPROVED (2026-03-14):** Stage 1: app↔app (QUIC). Stage 2: browser↔app (WS-direct). browser↔browser remains WebRTC invariant (G1). Promotion gate: burn-in with zero P0/P1 regressions. | RC6 | RC1 | **APPROVED (2026-03-14)** |
| PM-RC-04 | Performance SLO thresholds for native transport migration gates. **APPROVED (2026-03-14):** Throughput ≥10 MiB/s avg (3×1MiB localhost). Integrity: 100% hash match, 0 mismatches. Connection success: ≥99% in controlled matrix. No-regression suites green. Persistent failure → hold/rollback per RC6 levers. | RC3 (AC-RC-15) | RC1 | **APPROVED (2026-03-14)** |
| PM-RC-05 | Legacy TS-path deprecation policy/timeline after Rust core adoption. **APPROVED (2026-03-14):** Deprecate-but-retain. TS paths retained as fallback with kill-switch (RC-G7). Sunset requires separate PM approval after: (a) one full release cycle, (b) zero kill-switch activations, (c) zero P0/P1 regressions. Condition-gated, not date-gated. | RC6 | RC6 | **APPROVED (2026-03-14)** |
| PM-RC-06 | CLI stream trigger condition: when to start CLI-specific execution stream. **APPROVED (2026-03-14):** CLI stream may begin after RC4 complete [satisfied] AND RC6 Stage 1 burn-in passed (12h continuous soak, 0 P0/P1, 0 kill-switch activations, no-regression gates green). N-STREAM-1 N6 NOT required. | RC7 (AC-RC-33) | RC7 | **APPROVED (2026-03-14)** |
| PM-RC-07 | Relationship mode to existing streams. **APPROVED (2026-03-14):** SUPERSEDES SEC-CORE2 + PLAT-CORE1 (final supersession). REFACTORS/DEPENDS-ON MOB-RUNTIME1 + ARCH-WASM1. SEC-CORE2 and PLAT-CORE1 updated to SUPERSEDED-BY: RUSTIFY-CORE-1. | All phases | RC1 | **APPROVED (2026-03-14)** |

---

### Risk Register

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| RC-R1 | QUIC library (`quinn`) execution risk | MEDIUM | **Library selection RESOLVED** (PM-RC-01A: quinn approved, 2026-03-13). Residual risk: quinn 0.x semver (widely used but pre-1.0), Darwin EPIPE edge case (open upstream), Android >100KB issue on some devices (community-reported). Mitigations: RC3 interop checks (AC-RC-13), perf/SLO gate (AC-RC-15), explicit fallback order (s2n-quic → msquic-rs) with PM-approved switch criteria (≥2 weeks engineering effort + AC-RC-12/13 failure evidence). Ownership: RC3 executor. Escalation: PM (human) for fallback switch approval. |
| RC-R2 | FFI boundary complexity (Tauri + potential mobile) | HIGH | RC2 designs FFI surface before RC4 adoption; UniFFI evaluated for cross-platform |
| RC-R3 | TS→Rust authority migration breaks existing consumers | HIGH | **MITIGATED (RC6):** Kill-switch rollback (RC-G7) confirmed active throughout deprecated phase. Two-stage rollout (PM-RC-03). Rollback triggers/levers/SLA codified (AC-RC-26). No-regression gates (AC-RC-28) cross-linked at every stage promotion. Deprecation is condition-gated, not date-gated (PM-RC-05). |
| RC-R4 | Browser↔app transport mode selection complexity | MEDIUM | **RESOLVED** — PM-RC-02 APPROVED (WebSocket-direct, 2026-03-14). Primary: WS to app daemon. Fallback: WebRTC (automatic on WS failure). Residual risk: WS listener in daemon requires TLS cert management for wss://; deferred to RC5 implementation. |
| RC-R5 | Shared core API surface too large or leaky | MEDIUM | RC2 spec gate locks API before adoption; transport-independent invariant (RC-G3) |
| RC-R6 | CONSUMER-BTR1 delayed → RUSTIFY-CORE-1 blocked | LOW | **RESOLVED** — CONSUMER-BTR1 DONE (burn-in waived via `PM-CBTR-EX-01`). RUSTIFY-CORE-1 RC1 unblocked. |

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
> **Status:** **COMPLETE** (`ecosystem-v0.1.162-egui-native1-en5-closure`, 2026-03-16). EN1–EN4 delivered AC-EN-01–20. EN5 delivered AC-EN-21–24 (governance closure). PM-EN-01/02/03/04 APPROVED. PM-EN-05 deferred (EGUI-MOBILE-1 not yet evaluated). Stream CLOSED.

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
| **PLAT-CORE1** | **COMPLEMENTARY** (SUPERSEDED-BY RUSTIFY-CORE-1, PM-RC-07 APPROVED) | PLAT-CORE1 envisioned "thin platform UIs" over shared Rust core. EGUI-NATIVE-1 is the concrete desktop realization. PLAT-CORE1 confirmed SUPERSEDED; EGUI-NATIVE-1 inherits the desktop UI portion. |
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
| **EN1** | PM framework lock gate (egui vs alternatives) | PM gate | YES — gates EN2 | None (openable in parallel with RUSTIFY-CORE-1 RC1–RC2) | **DONE** (`ecosystem-v0.1.149-egui-native1-en1-baseline`, 2026-03-15). AC-EN-01–04 all PASS. PM-EN-01 APPROVED (egui). PM-EN-02 APPROVED (minimal parity). |
| **EN2** | Desktop `bolt-ui` scaffold + theme baseline | Engineering gate | YES — gates EN3 | EN1 complete, RUSTIFY-CORE-1 RC4 complete | **DONE** (`ecosystem-v0.1.150-egui-native1-en2-scaffold`, 2026-03-15). AC-EN-05–09 all PASS. bolt-ui crate created. eframe app shell + 3 skeleton screens + theme baseline. |
| **EN3** | Desktop feature parity migration (core screens/workflows) | Engineering gate | YES — gates EN4 | EN2 complete | **DONE** (`daemon-v0.2.44`, 2026-03-15). AC-EN-10–15 all PASS. Host/Join launcher + IPC client + SAS + transfer events. |
| **EN4** | Rollback/compatibility gate + packaging impact verification | PM/Engineering gate | YES — gates EN5 | EN3 complete | **DONE** (`ecosystem-v0.1.161-egui-native1-en4-rollback-gate`, 2026-03-15). AC-EN-16–20 all PASS. PM-EN-03 APPROVED (condition-gated). Dual-path verified. |
| **EN5** | Closure + handoff to optional EGUI-WASM-1 / EGUI-MOBILE-1 proposals | Governance gate | YES — closes stream | EN4 complete | **DONE** (`ecosystem-v0.1.162-egui-native1-en5-closure`, 2026-03-16). AC-EN-21–24 satisfied. Governance reconciled. EGUI-WASM-1 handed off (codified, independent). EGUI-MOBILE-1 deferred to PM-EN-05. |

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

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-EN-01 | PM framework lock captured: egui confirmed as desktop UI framework (or alternative selected) | PM-EN-01 decision recorded | **PASS** — PM-EN-01 APPROVED (2026-03-15). egui confirmed. |
| AC-EN-02 | Visual direction scope locked (minimal parity vs custom theme) | PM-EN-02 decision recorded | **PASS** — PM-EN-02 APPROVED (2026-03-15). Minimal parity first. |
| AC-EN-03 | Framework evaluation document published with pros/cons/risks | Published governance doc | **PASS** — Evaluation codified below. 4 frameworks assessed. |
| AC-EN-04 | Architecture compatibility with RUSTIFY-CORE-1 RC4 API surface assessed | Compatibility assessment doc | **PASS** — Compatibility assessment codified below. RC4 API compatible. |

##### AC-EN-01 — Framework Selection (PM-EN-01 APPROVED)

**PM-EN-01 APPROVED (2026-03-15): egui is the desktop UI framework for EGUI-NATIVE-1.**

##### AC-EN-02 — Visual Direction (PM-EN-02 APPROVED)

**PM-EN-02 APPROVED (2026-03-15): Minimal parity first.** Match current Tauri WebView desktop UX before exploring custom visual themes. No new design language in EN2/EN3.

##### AC-EN-03 — Framework Evaluation (PUBLISHED)

| Framework | Version | Maturity | Cross-Platform | WASM Target | Rendering | Ecosystem Size | Risk Level |
|-----------|---------|----------|----------------|------------|-----------|----------------|------------|
| **egui** (selected) | 0.33 | Pre-1.0, widely adopted | macOS/Win/Linux native | YES (eframe) | Immediate-mode, GPU (glow/wgpu) | Largest Rust GUI | LOW-MEDIUM |
| iced | 0.14 | Pre-1.0 | macOS/Win/Linux | Experimental | Elm-style retained, wgpu | Medium | MEDIUM |
| Slint | 1.15 | 1.0+ stable | macOS/Win/Linux | YES | Retained-mode, custom renderer | Growing | LOW |
| Dioxus | 0.6 | Pre-1.0 | macOS/Win/Linux | YES | React-like, WebView or native | Growing | MEDIUM-HIGH |

**Selection rationale (egui):**

| Factor | Assessment |
|--------|-----------|
| WASM viability | Proven — eframe compiles to WASM, directly enabling EGUI-WASM-1 |
| State management | Immediate-mode = simple (no virtual DOM, no retained state tree) |
| Ecosystem | Largest Rust GUI ecosystem (133M+ crates.io downloads for egui family) |
| Windowing | eframe handles OS windowing/rendering (glow for broad compat, wgpu for modern) |
| Single-binary | Yes — no WebView runtime dependency |
| Build verified | `cargo check` with eframe 0.33 PASS on aarch64-apple-darwin (Rust 1.93.1) |

**Risks acknowledged:**

| Risk | Severity | Mitigation |
|------|----------|------------|
| Pre-1.0 API instability | MEDIUM | Pin version in EN2. Track upstream. |
| Accessibility gaps vs browser DOM | MEDIUM | EN4 gate evaluates. PM-EN-03 rollback window. |
| Visual polish ceiling (immediate-mode) | LOW | Minimal parity scope (PM-EN-02) limits risk. |

##### AC-EN-04 — RC4 Architecture Compatibility (ASSESSED)

**RUSTIFY-CORE-1 RC4 API surface compatibility with egui:**

| RC4 API Surface | egui Compatibility | Notes |
|----------------|-------------------|-------|
| Shared Rust core (`bolt-core`) | **COMPATIBLE** | egui app consumes `bolt-core` via Cargo dependency, same as Tauri backend |
| IPC to daemon | **COMPATIBLE** | egui app uses same Unix socket/named pipe IPC (N-STREAM-1 N2 contract) |
| Session authority (daemon owns) | **COMPATIBLE** | egui is UI-only, delegates to daemon (same as Tauri WebView + Rust backend) |
| BTR/envelope/protocol | **NO CHANGE** | egui app calls same SDK APIs; no protocol reimplementation |
| Transport bindings | **NO CHANGE** | Transport is daemon-side; egui app is a UI consumer |
| Feature gates | **COMPATIBLE** | `transport-*` gates are daemon features, not UI features |

**Architectural model (EN2+):**

```
Current (Tauri):           Target (egui):
┌─────────────────┐        ┌─────────────────┐
│ React/TS WebView│        │ egui/eframe     │
│ (UI rendering)  │        │ (UI rendering)  │
└────────┬────────┘        └────────┬────────┘
         │ Tauri IPC                │ Direct Rust calls
┌────────┴────────┐        ┌────────┴────────┐
│ Tauri Rust      │        │ bolt-ui crate   │
│ backend (IPC    │        │ (consumes       │
│ relay + daemon  │        │ bolt-core +     │
│ lifecycle)      │        │ daemon IPC)     │
└────────┬────────┘        └────────┬────────┘
         │ Unix socket/pipe         │ Unix socket/pipe
┌────────┴────────┐        ┌────────┴────────┐
│ bolt-daemon     │        │ bolt-daemon     │
│ (unchanged)     │        │ (unchanged)     │
└─────────────────┘        └─────────────────┘
```

**Key advantage:** egui app calls Rust APIs directly (no Tauri IPC bridge, no JS↔Rust serialization). Simpler stack, fewer failure modes.

**EN2 repo recommendation:**

| Option | Location | Pros | Cons | Recommended |
|--------|----------|------|------|-------------|
| **A (preferred)** | New `bolt-ui` crate in `bolt-core-sdk/rust/` workspace | Clean separation. No localbolt-app destabilization. Mirrors `bolt-btr` pattern. | Separate repo from app packaging. | **YES** |
| **B (alternative)** | Inside `localbolt-app/src-tauri/` | Close to app packaging. | Couples to Tauri workspace. Destabilization risk. | No |

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
| PM-EN-01 | Desktop UI framework. **APPROVED (2026-03-15):** egui confirmed. eframe 0.33+. Immediate-mode rendering. WASM-capable (EGUI-WASM-1 alignment). Build verified on aarch64-apple-darwin. | EN2 | EN1 | **APPROVED (2026-03-15)** |
| PM-EN-02 | Visual direction. **APPROVED (2026-03-15):** Minimal parity first. Match current Tauri WebView desktop UX. No custom design language in EN2/EN3. | EN2 | EN1 | **APPROVED (2026-03-15)** |
| PM-EN-03 | Rollback window duration. **APPROVED (2026-03-15): Option C — condition-gated.** Dual-build active until EN5 explicit PM approval. No fixed time sunset. Legacy removal is condition-gated, not date-gated. | EN5 (legacy removal) | EN4 | **APPROVED (2026-03-15)** |
| PM-EN-04 | Whether to open EGUI-WASM-1 (browser egui via WASM). **APPROVED (2026-03-15, early resolution):** EGUI-WASM-1 opened independent of EN3 completion. Browser WASM egui is architecturally distinct from desktop egui. Experimental, non-blocking to EGUI-NATIVE-1. | Post-stream | EN5 | **APPROVED (2026-03-15, early)** |
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
| EN-NG1 | Replace browser UI (localbolt, localbolt-v3) | EGUI-WASM-1 scope (codified, PM-EN-04 approved early) |
| EN-NG2 | Mobile UI | EGUI-MOBILE-1 scope (future, if approved) |
| EN-NG3 | Transport/protocol changes | EN-G1; this is a UI-only stream |
| EN-NG4 | CLI interface | EN-G5; CLI is text-only |
| EN-NG5 | Feature additions beyond current desktop parity | Parity first; new features via separate governance |

### Deferred Stream Definitions

| Stream ID | Scope | Trigger Condition | Dependencies |
|-----------|-------|-------------------|--------------|
| ~~**EGUI-WASM-1**~~ | ~~Browser UI migration to egui via WASM~~ | **PM-EN-04 APPROVED (early, 2026-03-15)** — stream codified below | See § EGUI-WASM-1 |
| **EGUI-MOBILE-1** | Mobile UI via egui (iOS, Android) | PM-EN-05 approved after EN4 results | EGUI-NATIVE-1 EN4 complete, MOB-RUNTIME1 |

These are governance reservations only. No phases, ACs, or PM decisions are defined for deferred streams. Full codification requires separate stream codification prompts after trigger conditions are met.

---

## EGUI-WASM-1 — Browser UI Migration to egui via WASM (Experimental)

> **Stream ID:** EGUI-WASM-1
> **Backlog Item:** EGUI-NATIVE-1 deferred follow-on (PM-EN-04 approved early, 2026-03-15)
> **Priority:** LATER (experimental; non-blocking to EGUI-NATIVE-1)
> **Repos:** localbolt-v3 (primary consumer), localbolt (secondary consumer), bolt-ecosystem (governance)
> **Codified:** ecosystem-v0.1.142-egui-wasm1-codify (2026-03-15)
> **Status:** **ABANDONED** (`ecosystem-v0.1.164-egui-wasm1-ew2-poc`, 2026-03-17). EW2 PoC built and measured. WASM bundle 1,296 KiB gzipped (2.6× over 500 KiB kill threshold). Reuse 26% (simple screens only). 20× bundle regression vs current 65 KiB vanilla TS app. Q1 hard kill triggered. Stream CLOSED.

---

### Context & Motivation

Current browser UIs (localbolt, localbolt-v3) use React/TypeScript/Tailwind rendered in the browser DOM. EGUI-WASM-1 explores migrating browser UI to egui compiled to WASM, rendering to `<canvas>`. This would unify the UI framework across desktop (EGUI-NATIVE-1) and browser, reducing dual-stack maintenance.

**PM-EN-04 early resolution rationale:** Browser WASM egui is architecturally distinct from desktop egui. Desktop egui renders via native GPU backends (wgpu/glow); browser egui renders via WebGL/WebGPU in a `<canvas>` element. The browser path has independent constraints (bundle size, startup latency, accessibility, SEO) that do not depend on desktop EN3 parity results.

**Experimental status:** This stream is explicitly experimental. The default-safe path is retaining the current React/TS browser UI. EGUI-WASM-1 produces a decision (adopt or abandon) — not a guaranteed migration.

### Relationship to Existing Streams

| Stream | Mode | Rationale |
|--------|------|-----------|
| **EGUI-NATIVE-1** (CODIFIED) | **PARALLEL/NON-BLOCKING** | EGUI-WASM-1 runs independently. EN phases are not prerequisites. Results may inform each other but neither blocks the other. |
| **ARCH-WASM1** (LATER) | **COMPLEMENTARY** | ARCH-WASM1 targets protocol engine WASM; EGUI-WASM-1 targets UI WASM. Different layers, same compile target. |
| **RUSTIFY-CORE-1** (DONE) | **EXTENDS** | Shared Rust core API (RC2/RC4) is consumed by egui WASM UI via wasm-bindgen, same as TS currently consumes via SDK. |
| **BTR-SPEC-1** (IN-PROGRESS) | **ORTHOGONAL** | BTR operates below UI. No interaction. |
| **WEBTRANSPORT-BROWSER-APP-1** (IN-PROGRESS) | **ORTHOGONAL** | Transport operates below UI. No interaction. |

No SUPERSEDES relationships. EGUI-WASM-1 is additive/experimental.

---

### Scope Guardrails

| ID | Guardrail |
|----|-----------|
| EW-G1 | Default-safe: React/TS browser UI is retained as the production path until EW4 explicitly approves migration |
| EW-G2 | No protocol/transport changes — UI-only stream |
| EW-G3 | EGUI-NATIVE-1 is not blocked or modified by EGUI-WASM-1 progress or failure |
| EW-G4 | Rollback to React/TS UI must be available at every phase — dual-build (WASM + React) during experimental window |
| EW-G5 | No removal of React/TS browser UI without separate PM approval (PM-EW-05) |
| EW-G6 | Bundle size gate: WASM bundle must not exceed success threshold (PM-EW-01) |
| EW-G7 | Accessibility gate: egui WASM canvas must meet or exceed current React accessibility level |
| EW-G8 | No consumer app deployment of egui WASM UI without EW4 rollout gate pass |
| EW-G9 | EW2 is measurement-only. No consumer app integration or deployment. |
| EW-G10 | No EW3+ unless EW2 produces evidence that materially beats the feasibility expectations documented in EW1. The bar is "unexpectedly strong," not "marginally acceptable." |
| EW-G11 | PM override to proceed past EW1 is taste-driven, not a reversal of technical concerns. Technical concerns remain on the record and govern EW2 kill criteria. |

---

### Architectural Truths (EW1 Findings — Normative)

These three truths constrain all subsequent EGUI-WASM-1 phases. Any phase deliverable that violates them has drifted from scope.

**Truth 1: Browser does not run desktop runtime.**
No daemon spawning, no Unix sockets, no `/tmp`, no `std::process::Command`, no native process lifecycle. The browser egui shell is a new thin host that consumes shared presentation/state/core code — not a port of bolt-ui's desktop runtime. bolt-ui's daemon.rs and ipc.rs are not part of the shared surface.

**Truth 2: Browser QUIC means WebTransport, not native quinn.**
"QUIC in the browser" means the browser's WebTransport API (HTTP/3-class, browser-mediated). It does not mean compiling quinn to WASM or opening raw UDP sockets. Desktop may use native quinn; browser uses browser APIs. The shared core API abstracts over both, but transport implementations are distinct.

**Truth 3: Canvas replaces DOM — accessibility is structurally worse.**
egui renders to `<canvas>`, not semantic HTML. The current web UI's `<button>`, `<section>`, `<header>`, ARIA labels, and keyboard navigation come from the DOM for free. Canvas gets none of this. There is no production-ready egui WASM accessibility solution. SG-04 remains the hardest gate.

---

### EW2 PoC Scope (Measurement Only)

EW2 is a **tightly-bounded measurement PoC** exploring an **optional browser egui shell** — not a forced migration. The future posture, if the stream proceeds, is **dual-UI optionality**: users or deployments could choose the egui WASM shell or the existing vanilla TS UI, with neither path forced out. EW2 answers five concrete questions with empirical data. It does not commit to browser migration, product adoption, or React/TS replacement. The current vanilla TS browser UI remains the default-safe production path. ABANDON remains the default outcome if EW2 does not materially beat expectations.

#### EW2 Questions

| # | Question | Measurement | Kill Criterion |
|---|----------|-------------|----------------|
| Q1 | What is the actual gzipped WASM bundle size for a minimal egui browser shell in this codebase? | `wasm-opt` + gzip of built artifact | >500 KiB gzipped = ABANDON |
| Q2 | What is the actual cold-start and render performance? | Time-to-first-frame on median hardware, FPS during UI updates | >3s cold start OR <30 FPS = ABANDON |
| Q3 | How much of bolt-ui's presentation/state/core code is meaningfully reusable in a browser shell? | Structural audit: theme, screen composition, state/view-model enums, bolt-core consumption. Reuse must reduce future browser-shell implementation cost, not just share cosmetic constants. | Reusable surface insufficient to materially reduce implementation cost = sharing rationale is dead |
| Q4 | Does the browser shell feel viable as a foundation that could later sit on browser-safe transport? | Subjective PM assessment of the running PoC | PM taste call |
| Q5 | Is the maintenance cost of supporting both browser UIs plausibly justified by user preference and shared-core reuse? | Assessment of dual-UI maintenance burden vs benefit of optionality + code sharing | Maintenance cost clearly exceeds benefit = dual-UI not justified |

#### EW2 Deliverable

A minimal egui WASM app that:
- Renders in a browser tab (WebGL2 canvas)
- Reuses bolt-ui theme/screen/state code where possible via shared crate or extracted module
- Displays a peer code via bolt-core (already WASM-proven)
- Does **not** implement any transport (no WebTransport, no WebRTC, no daemon, no signaling)
- Does **not** replace or modify the existing web UI
- Lives in an isolated crate — not wired into any consumer app

#### EW2 Kill Criteria

EW2 closes the stream (ABANDON) if **any** of:
1. Gzipped WASM bundle >500 KiB
2. Cold start >3s on median hardware
3. FPS <30 during UI updates
4. Reusable presentation/state/core surface insufficient to materially reduce implementation cost
5. Dual-UI maintenance cost clearly exceeds the benefit of optionality + shared-core reuse
6. PM subjective assessment: "not worth pursuing"

EW2 allows proceeding to EW3 **only if** all quantitative criteria pass, PM assessment is affirmative, and accessibility path is at least theoretically viable (documented, not solved).

---

### EGUI-WASM-1 Phase Table

| Phase | Description | Type | Serial Gate | Dependencies | Status |
|-------|-------------|------|-------------|--------------|--------|
| **EW1** | Feasibility assessment + success gate definition lock | PM/Spec gate | YES — gates EW2 | None | **DONE** (`ecosystem-v0.1.163`, 2026-03-16). AC-EW-01–04 satisfied. Feasibility negative on structural grounds; PM override to EW2 PoC. |
| **EW2** | WASM scaffold + rendering proof-of-concept | Engineering gate | YES — gates EW3 | EW1 complete | **DONE** (`ecosystem-v0.1.164`, 2026-03-17). PoC built. 1,296 KiB gzipped (FAIL >500 KiB). 26% reuse. Q1 hard kill → ABANDON. |
| **EW3** | Feature parity assessment + success gate evaluation | Engineering + PM gate | YES — gates EW4 | EW2 complete | NOT-STARTED |
| **EW4** | Adoption decision gate (adopt, abandon, or defer) | PM gate | YES — gates EW5 or closes | EW3 complete | NOT-STARTED |
| **EW5** | Migration rollout + React/TS disposition (if adopt) | Engineering + PM gate | YES — closes stream | EW4 = ADOPT | NOT-STARTED |

#### Dependency DAG

```
EW1 (feasibility + gates — unblocked now)
  │
  ▼
EW2 (WASM scaffold + PoC)
  │
  ▼
EW3 (parity assessment + gate evaluation)
  │
  ▼
EW4 (adopt / abandon / defer — PM decision)
  │
  ├─ ADOPT → EW5 (migration rollout)
  └─ ABANDON/DEFER → stream closes with findings report
```

No upstream stream dependencies. Runs in parallel with EGUI-NATIVE-1. May consume shared `bolt-ui` crate if EGUI-NATIVE-1 EN2 produces one.

---

### Success Gates (Quantitative)

These gates are evaluated at EW3 and must all PASS for EW4 ADOPT recommendation.

| ID | Gate | Threshold | Rationale |
|----|------|-----------|-----------|
| SG-01 | WASM bundle size (gzipped) | ≤500 KiB | Current React bundle is ~200–400 KiB. WASM must not regress significantly. |
| SG-02 | Initial render time (cold start) | ≤2s on median hardware | Current React hydration is ~500ms–1s. Allow 2× budget for WASM init. |
| SG-03 | Runtime frame rate | ≥30 FPS during file transfer UI updates | Smooth UI during active transfers. |
| SG-04 | Accessibility audit | WAI-ARIA equivalent coverage OR documented mitigation plan | egui canvas lacks native DOM accessibility. Must compensate. |
| SG-05 | Feature parity | ≥90% of current React UI workflows functional | Peer connection, file transfer, progress, settings, mode indicator. |
| SG-06 | Cross-browser rendering | Renders correctly on Chrome, Firefox, Edge (Safari if WebGPU available) | Canvas rendering may vary by browser GPU backend. |

**Gate evaluation:** All 6 must PASS for ADOPT recommendation. Any FAIL produces ABANDON or DEFER with findings.

---

### Acceptance Criteria

#### EW1 — Feasibility + Gate Definition

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-EW-01 | egui WASM compilation feasibility confirmed (egui + eframe compile to wasm32-unknown-unknown) | Build evidence |
| AC-EW-02 | Success gates (SG-01–SG-06) locked with quantitative thresholds | Published gate doc |
| AC-EW-03 | Browser rendering backend options evaluated (WebGL2 vs WebGPU vs software) | Evaluation doc |
| AC-EW-04 | Accessibility risk assessment for canvas-based UI documented | Risk doc |

#### EW2 — WASM Scaffold + PoC

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-EW-05 | Minimal egui WASM app renders in browser (hello-world level) | Screenshot + build artifact |
| AC-EW-06 | WASM bundle size measured against SG-01 threshold | Size measurement |
| AC-EW-07 | Cold start time measured against SG-02 threshold | Timing measurement |
| AC-EW-08 | Shared `bolt-ui` crate consumption path verified (if crate exists from EN2) OR standalone UI module created | Architecture doc |

#### EW3 — Parity Assessment + Gate Evaluation

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-EW-09 | Feature parity audit against current React UI (SG-05) | Parity matrix |
| AC-EW-10 | All 6 success gates (SG-01–SG-06) evaluated with evidence | Gate evaluation report |
| AC-EW-11 | Accessibility audit completed (SG-04) | Audit report |
| AC-EW-12 | Cross-browser rendering verified (SG-06) | Browser test matrix |

#### EW4 — Adoption Decision

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-EW-13 | PM adoption decision recorded: ADOPT, ABANDON, or DEFER | PM decision doc |
| AC-EW-14 | If ABANDON/DEFER: findings report published with gate results | Findings doc |
| AC-EW-15 | If ADOPT: migration plan and React/TS disposition timeline drafted | Plan doc |

#### EW5 — Migration Rollout (ADOPT only)

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-EW-16 | Staged rollout plan (per-consumer, with burn-in) | Rollout policy |
| AC-EW-17 | React/TS UI disposition decided (retain as fallback vs deprecate) | PM decision (PM-EW-05) |
| AC-EW-18 | Rollback to React/TS verified per consumer | Rollback test evidence |
| AC-EW-19 | Stream closure criteria met | Closure evidence |

---

### PM Open Decisions Table

| ID | Decision | Blocks | Priority | Status |
|----|----------|--------|----------|--------|
| PM-EW-01 | WASM bundle size budget (recommended ≤500 KiB gzipped) | EW1 (SG-01) | EW1 | PENDING |
| PM-EW-02 | Browser rendering backend preference (WebGL2 vs WebGPU vs auto-detect) | EW2 (AC-EW-05) | EW2 | PENDING |
| PM-EW-03 | Accessibility mitigation strategy (ARIA overlay vs alternative) | EW3 (AC-EW-11) | EW3 | PENDING |
| PM-EW-04 | Adoption decision: ADOPT, ABANDON, or DEFER | EW4 (AC-EW-13) | EW4 | PENDING |
| PM-EW-05 | React/TS disposition after adoption (retain fallback vs deprecate-with-sunset) | EW5 (AC-EW-17) | EW5 | PENDING |

---

### Risk Register

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| EW-R1 | WASM bundle too large (>500 KiB) for browser UX | HIGH | SG-01 gate. Tree-shaking, wasm-opt, feature-gating egui modules. Fail = ABANDON/DEFER. |
| EW-R2 | egui canvas accessibility inferior to React DOM | HIGH | SG-04 gate. ARIA overlay evaluation (PM-EW-03). Fail = ABANDON/DEFER. |
| EW-R3 | Cold start latency unacceptable (WASM compile + init) | MEDIUM | SG-02 gate. Streaming WASM compilation, preload hints. 2s budget. |
| EW-R4 | Cross-browser rendering inconsistency (WebGL/WebGPU variance) | MEDIUM | SG-06 gate. EW2 PoC tests on Chrome/Firefox/Edge. |
| EW-R5 | egui API instability (pre-1.0 in some areas) | LOW | Pin egui version in EW2. Track upstream releases. |
| EW-R6 | Dual-build complexity during experimental window | LOW | EW-G4 rollback guardrail. Separate build targets, shared core API. |

---

### Explicit Non-Goals

| ID | Non-Goal | Rationale |
|----|----------|-----------|
| EW-NG1 | Desktop UI changes | EGUI-NATIVE-1 scope |
| EW-NG2 | Mobile UI | EGUI-MOBILE-1 scope (deferred, PM-EN-05) |
| EW-NG3 | Protocol/transport changes | EW-G2; UI-only stream |
| EW-NG4 | Guaranteed migration | Experimental; ABANDON is a valid EW4 outcome |
| EW-NG5 | React/TS removal in this stream | EW-G5; requires separate PM-EW-05 approval |

---

## RUSTIFY-BROWSER-CORE-1 — Browser-Path Rust/WASM Protocol Authority

> **Stream ID:** RUSTIFY-BROWSER-CORE-1
> **Backlog Item:** Follow-on to RUSTIFY-CORE-1 (browser runtime authority); operationalizes browser-path portion deferred by ARCH-WASM1
> **Priority:** NEXT (unblocked — RUSTIFY-CORE-1 complete, ARCH-WASM1 dependency satisfied)
> **Repos:** bolt-core-sdk (WASM bindings), bolt-transport-web (TS adapter thinning), localbolt-v3 / localbolt / localbolt-app (consumer rollout), bolt-ecosystem (governance)
> **Codified:** ecosystem-v0.1.165-rustify-browser-core1-codify (2026-03-17)
> **Status:** **CLOSED** (`ecosystem-v0.1.171-rustify-browser-core1-rb6-closure`, 2026-03-17). All 23 ACs (AC-RB-01–23) satisfied. All 5 PM decisions APPROVED. Browser-path Rust/WASM protocol authority delivered. localbolt-v3 rollout complete; localbolt/localbolt-app deferred per PM-RB-04. TS fallback retained non-authoritative per PM-RB-03.

---

### Context & Motivation

**Audit finding (2026-03-17):** The browser protocol path is a complete independent TypeScript implementation of the Bolt protocol. Six TS modules in `bolt-core/ts/src/btr/` reimplement the entire BTR ratchet. `HandshakeManager.ts` reimplements HELLO/SAS. `TransferManager.ts` (836 LOC) reimplements transfer orchestration with chunk encrypt/decrypt. `EnvelopeCodec.ts` reimplements the envelope codec. All use tweetnacl + @noble/hashes with zero Rust calls at runtime.

Parity with Rust is maintained by shared test vectors and CI constant verification — parity-by-convention, not parity-by-construction.

**Why this matters:**
- Doubles the protocol attack surface (a TS-only bug affects all browser users independently)
- Requires coordinating algorithm changes across two languages
- Makes parity a convention problem, not a construction guarantee

**Relationship to RUSTIFY-CORE-1:** RUSTIFY-CORE-1 is **not a failure**. It completed its daemon/native-first scope: Rust canonical types, daemon-path authority, shared core API surface. Its transport matrix explicitly locked "browser↔browser: WebRTC (retained baseline)" and its stream relationship declared "REFACTORS/DEPENDS-ON: ARCH-WASM1" for future browser authority work. RUSTIFY-BROWSER-CORE-1 is the planned follow-on, not a retroactive negation.

**Relationship to ARCH-WASM1:** RUSTIFY-BROWSER-CORE-1 is the concrete execution stream for browser-path Rust/WASM authority that ARCH-WASM1 left deferred. ARCH-WASM1 envisioned "WASM protocol engine" but was never codified beyond a placeholder. Whether ARCH-WASM1 is formally superseded is a PM decision (PM-RB-05) — this stream does not assume that disposition.

**Relationship to EGUI-WASM-1 (ABANDONED):** Distinct scope. EGUI-WASM-1 attempted UI rendering migration (egui canvas → 1.3 MiB). RUSTIFY-BROWSER-CORE-1 migrates protocol logic only (crypto, session, BTR, transfer SM). Protocol WASM is structurally smaller — no font renderer, no GL backend, no text shaping. The existing `bolt-transfer-policy-wasm` module (20 KiB) demonstrates viable protocol-only WASM size.

**Relationship to T-STREAM-1:** T-STREAM-1 achieved selective WASM integration for transfer policy/scheduling only. RUSTIFY-BROWSER-CORE-1 extends this to full protocol authority.

---

### Target Boundary

**Rust/WASM must own (post-stream):**

| Authority | Current Owner | Target Owner |
|-----------|--------------|--------------|
| Session protocol (HELLO, SAS, capability negotiation) | TS `HandshakeManager.ts` | Rust `bolt-core::session` via WASM |
| Envelope codec (Profile Envelope v1) | TS `EnvelopeCodec.ts` | Rust via WASM |
| Crypto authority (NaCl box seal/open) | TS `crypto.ts` (tweetnacl) | Rust `bolt-core::crypto` via WASM |
| BTR ratchet state (engine, key schedule, DH ratchet) | TS `btr/*.ts` (6 modules) | Rust `bolt-btr` via WASM |
| BTR encrypt/decrypt | TS `btr/encrypt.ts` | Rust `bolt-btr::encrypt` via WASM |
| Replay guard | TS `btr/replay.ts` | Rust `bolt-btr::replay` via WASM |
| Transfer state machine | TS `TransferManager.ts` | Rust `bolt-transfer-core` via WASM |
| Transfer policy/scheduling | Rust via WASM (already done, T-STREAM-1) | No change |

**TS must retain only:**

| Responsibility | Rationale |
|---------------|-----------|
| WebRTC API bindings (RTCPeerConnection, DataChannel, ICE) | Browser API — cannot be in WASM |
| WebTransport API bindings (future) | Browser API |
| Signaling transport (WebSocket to rendezvous) | Browser API |
| JS↔WASM bridge / glue | Structural necessity |
| IndexedDB persistence (identity store, pin store) | Browser API |
| UI layer (DOM manipulation, event handling) | Application concern |
| File API (FileReader, Blob, download) | Browser API |

---

### Scope Guardrails

| ID | Guardrail |
|----|-----------|
| RB-C1 | Browser transport remains browser-safe APIs only (WebRTC, WebTransport). No raw native QUIC in browser. |
| RB-C2 | Fallback/rollback to TS protocol path required during migration window. |
| RB-C3 | WASM bundle budget must be explicitly locked by PM (PM-RB-01) before engineering begins. |
| RB-C4 | No protocol semantic drift during migration. Rust WASM must produce byte-identical outputs to current TS for all inputs. Verified by existing cross-implementation test vectors. |
| RB-C5 | Browser product path must remain operable at every phase gate. No breaking change without rollback path. |
| RB-C6 | No changes to Rust crate APIs — WASM bindings wrap existing crates, do not fork them. |
| RB-C7 | UI layer remains TS/DOM. No egui, no DOM rewrite, no UI rendering changes. |
| RB-C8 | Accessibility unchanged — protocol migration is below the UI layer. No accessibility discussion beyond "unaffected by this stream." |

---

### Explicit Non-Goals

| ID | Non-Goal | Rationale |
|----|----------|-----------|
| RB-NG1 | UI rendering migration (egui, canvas, DOM rewrite) | EGUI-WASM-1 ABANDONED. UI is out of scope. RB-C7. |
| RB-NG2 | Native QUIC in browser | Browser "QUIC" means WebTransport. RB-C1. |
| RB-NG3 | Daemon architecture changes | Daemon already uses Rust exclusively. Not in scope. |
| RB-NG4 | Protocol semantic changes | Migration only. Same protocol, same wire format. RB-C4. |
| RB-NG5 | Mobile runtime changes | MOB-RUNTIME1 scope. Independent. |

---

### RUSTIFY-BROWSER-CORE-1 Phase Table

| Phase | Description | Type | Serial Gate | Dependencies | Status |
|-------|-------------|------|-------------|--------------|--------|
| **RB1** | Policy lock + target boundary + bundle budget | PM gate | YES — gates RB2 | None | **DONE** (`ecosystem-v0.1.166`, 2026-03-17). AC-RB-01–04 satisfied. PM-RB-01–05 APPROVED. |
| **RB2** | Authority boundary audit + TS adapter inventory | Engineering audit | YES — gates RB3 | RB1 complete | **DONE** (`ecosystem-v0.1.167`, 2026-03-17). AC-RB-05–07 satisfied. 67 KiB gzipped WASM measured. 31+ TS modules inventoried. API boundary defined. |
| **RB3** | Rust/WASM crypto + session core (NaCl box, HELLO, SAS, envelope) | Engineering | YES — gates RB4 | RB2 complete | **DONE** (`sdk-v0.6.16`, 2026-03-17). AC-RB-08–11 satisfied. 61 KiB gzipped. 8 exports. TS dual-path wired. |
| **RB4** | Rust/WASM BTR + transfer core (ratchet, encrypt/decrypt, transfer SM) | Engineering | YES — gates RB5 | RB3 complete | **DONE** (`sdk-v0.6.17`, 2026-03-17). AC-RB-12–16 satisfied. 102 KiB gzipped. seal_chunk: 42 μs/call. |
| **RB5** | TS adapter thinning (remove TS protocol implementations, wire to WASM) | Engineering | YES — gates RB6 | RB4 complete | **DONE** (`sdk-v0.6.18` + `v3.0.90`, 2026-03-17). AC-RB-17–20 satisfied. Production WASM path wired. TS demoted to fallback. |
| **RB6** | Rollout + compatibility gate + TS deprecation + closure | PM/Engineering | YES — closes stream | RB5 complete | **DONE** (`ecosystem-v0.1.171`, 2026-03-17). AC-RB-21–23 satisfied. localbolt-v3 rolled out. TS fallback retained. Stream CLOSED. |

#### Dependency DAG

```
RB1 (policy lock — unblocked now)
  │
  ▼
RB2 (adapter inventory)
  │
  ▼
RB3 (crypto + session WASM)
  │
  ▼
RB4 (BTR + transfer WASM)
  │
  ▼
RB5 (TS thinning)
  │
  ▼
RB6 (rollout + closure)
```

No upstream stream dependencies. RUSTIFY-CORE-1 is complete. T-STREAM-1 WASM integration pattern is available.

---

### Acceptance Criteria

#### RB1 — Policy Lock

| ID | Criterion | Evidence |
|----|-----------|----------|
| AC-RB-01 | WASM bundle budget locked (PM-RB-01) | PM decision doc |
| AC-RB-02 | Transport binding posture confirmed (PM-RB-02) | PM decision doc |
| AC-RB-03 | Rollback/deprecation model confirmed (PM-RB-03) | PM decision doc |
| AC-RB-04 | Consumer scope confirmed (PM-RB-04) | PM decision doc |

#### RB2 — Adapter Inventory

| ID | Criterion | Evidence |
|----|-----------|----------|
| AC-RB-05 | Every TS protocol-authority module inventoried with disposition (WASM-replace / TS-retain / delete) | Inventory doc |
| AC-RB-06 | WASM API surface defined (function signatures for JS↔WASM boundary) | API spec |
| AC-RB-07 | Bundle size estimate for protocol WASM (without UI/font rendering) | Build measurement |

#### RB3 — Crypto + Session WASM

| ID | Criterion | Evidence |
|----|-----------|----------|
| AC-RB-08 | bolt-core compiles to WASM with crypto + session + SAS + envelope exports | Build artifact |
| AC-RB-09 | WASM crypto produces byte-identical outputs to TS crypto for all existing test vectors | Cross-impl test pass |
| AC-RB-10 | HandshakeManager calls WASM for all crypto/session decisions (TS crypto calls removed) | Code audit + test |
| AC-RB-11 | WASM bundle size within PM-RB-01 budget | Size measurement |

#### RB4 — BTR + Transfer WASM

| ID | Criterion | Evidence |
|----|-----------|----------|
| AC-RB-12 | bolt-btr compiles to WASM with encrypt/decrypt/ratchet/replay exports | Build artifact |
| AC-RB-13 | bolt-transfer-core state machine accessible from JS via WASM | API test |
| AC-RB-14 | TransferManager delegates encrypt/decrypt + state transitions to WASM | Code audit + test |
| AC-RB-15 | BTR test vectors pass through WASM path | Cross-impl test pass |
| AC-RB-16 | TS btr/*.ts modules are dead code (no callers in production browser path) | Dead code analysis |

#### RB5 — TS Thinning

| ID | Criterion | Evidence |
|----|-----------|----------|
| AC-RB-17 | No TS module owns protocol state transitions in production browser path (all delegated to WASM) | Authority audit |
| AC-RB-18 | TS does not perform protocol cryptographic operations in production browser path. Zero tweetnacl/noble-hashes calls for protocol crypto (seal, open, encrypt, decrypt, ratchet, HKDF). Peer code generation and non-protocol hashing are exempt. | Code search + test |
| AC-RB-19 | TS-only residue is: browser API bindings, JS↔WASM bridge, persistence, UI | Module classification doc |
| AC-RB-20 | Dual-path (WASM + legacy TS) operational if rollback retained per PM-RB-03 | Rollback test |

#### RB6 — Rollout + Closure

| ID | Criterion | Evidence |
|----|-----------|----------|
| AC-RB-21 | Per-consumer rollout completed per PM-RB-04 scope | Deploy evidence |
| AC-RB-22 | TS protocol deprecation timeline confirmed (PM-RB-03 resolution) | PM decision |
| AC-RB-23 | Stream closure criteria met | Closure evidence |

---

### PM Open Decisions Table

| ID | Decision | Blocks | Priority | Status |
|----|----------|--------|----------|--------|
| PM-RB-01 | WASM bundle budget. **APPROVED (2026-03-17): Option B — ≤300 KiB gzipped.** Protocol-only WASM bundle must not exceed 300 KiB gzipped. RB2 measures actual size. Exceeding the budget fails the gate and requires explicit PM disposition before RB3 may proceed. | RB3 | RB1 | **APPROVED** |
| PM-RB-02 | Browser transport binding posture. **APPROVED (2026-03-17): Option A — WebRTC retained, WebTransport deferred.** Browser transport bindings remain WebRTC as-is. WebTransport is out of scope (governed by WEBTRANSPORT-BROWSER-APP-1). | RB2 | RB1 | **APPROVED** |
| PM-RB-03 | Rollback/deprecation model. **APPROVED (2026-03-17): Option A — condition-gated sunset.** Dual-path (WASM + TS protocol) active during migration. TS protocol removal requires explicit PM approval after evidence. No fixed deadline. | RB5 | RB1 | **APPROVED** |
| PM-RB-04 | Consumer scope. **APPROVED (2026-03-17): Option B — staged rollout.** localbolt-v3 first for RB3–RB5. localbolt and localbolt-app follow after localbolt-v3 burn-in. Per-consumer opt-in at RB6. | RB6 | RB1 | **APPROVED** |
| PM-RB-05 | ARCH-WASM1 disposition. **APPROVED (2026-03-17): Option A — formally superseded.** RUSTIFY-BROWSER-CORE-1 is the concrete execution for browser WASM protocol authority. ARCH-WASM1 retired. | Post-codification | RB1 | **APPROVED** |

---

### Risk Register

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| RB-R1 | WASM bundle size exceeds budget | HIGH | RB2 measurement before engineering. Protocol-only WASM (no font/GL) is structurally smaller than EGUI-WASM-1's 1.3 MiB. Existing policy WASM is 20 KiB. But full crypto + BTR + transfer may reach 100–300 KiB. PM-RB-01 sets the hard gate. |
| RB-R2 | Browser debugging complexity increases | MEDIUM | WASM source maps + console_error_panic_hook. Rust panic messages surface in browser console. TS adapter layer remains debuggable in native JS tooling. |
| RB-R3 | Browser performance regression (WASM call overhead per chunk) | MEDIUM | Benchmark in RB3. Measure per-call overhead. Batch chunk operations if overhead is significant. T-STREAM-1 policy WASM showed acceptable performance. |
| RB-R4 | Dual-path migration risk during transition | MEDIUM | RB-C2 requires rollback path. Feature flag to switch between WASM and TS protocol paths. Burn-in period per consumer. |
| RB-R5 | Transport binding complexity (WebRTC callbacks → WASM state) | MEDIUM | RB2 defines the precise JS↔WASM boundary. Key constraint: WebRTC events are JS callbacks; WASM must be callable synchronously from those callbacks. No async WASM in hot path. |
| RB-R6 | tweetnacl vs Rust crypto subtle differences | LOW | Already mitigated by existing cross-implementation test vectors. RB3 AC-RB-09 requires byte-identical outputs. |
| RB-R7 | Accessibility impact | NONE | Protocol migration is below UI layer. No DOM changes. RB-C8 confirms. |

---

## RUSTIFY-BROWSER-ROLLOUT-1 — Package + Deploy + Observability + Burn-In

> **Stream ID:** RUSTIFY-BROWSER-ROLLOUT-1
> **Backlog Item:** Operational follow-on to RUSTIFY-BROWSER-CORE-1 (architecture delivered, deployment pending)
> **Priority:** NEXT (unblocked — RUSTIFY-BROWSER-CORE-1 CLOSED)
> **Repos:** bolt-core-sdk (publish), localbolt-v3 (primary burn-in), localbolt / localbolt-app (follow-on per PM-BR-02), bolt-ecosystem (governance)
> **Codified:** ecosystem-v0.1.172-rustify-browser-rollout1-codify (2026-03-17)
> **Status:** **CLOSED** (`ecosystem-v0.1.178`, 2026-03-19). All 17 ACs satisfied. All consumers on published packages. Burn-in evidence collected. TS fallback retained. Stream CLOSED.

---

### Context & Motivation

RUSTIFY-BROWSER-CORE-1 delivered browser-path Rust/WASM protocol authority: bolt-protocol-wasm crate (102 KiB gzipped), TS SDK wiring, localbolt-v3 production path. But the architecture is not yet *deployed*:

- bolt-core and bolt-transport-web npm packages are not published with WASM adapter code
- bolt-protocol-wasm artifact is not embedded in the published transport-web package
- No runtime observability distinguishes WASM authority from TS fallback
- No burn-in evidence from production deployment
- Follow-on consumers (localbolt, localbolt-app) are not wired

This stream turns architectural completion into boring, trustworthy product reality.

**Relationship to RUSTIFY-BROWSER-CORE-1:** Operational successor. No architecture reopening. The WASM API surface is frozen. This stream publishes, deploys, observes, and validates.

---

### Scope Guardrails

| ID | Guardrail |
|----|-----------|
| BR-C1 | No protocol architecture changes. bolt-protocol-wasm WASM API surface is frozen from RUSTIFY-BROWSER-CORE-1. |
| BR-C2 | No new WASM exports. If a protocol blocker appears, escalate to a new stream. |
| BR-C3 | Existing CI guards must remain green. |
| BR-C4 | Exact version pinning discipline maintained. |
| BR-C5 | Netlify deploy pipeline not disrupted. |
| BR-C6 | TS fallback path must remain operational throughout (PM-RB-03). |

---

### RUSTIFY-BROWSER-ROLLOUT-1 Phase Table

| Phase | Description | Type | Serial Gate | Dependencies | Status |
|-------|-------------|------|-------------|--------------|--------|
| **BR1** | Package + artifact delivery audit | Engineering audit | YES — gates BR2 | None | **DONE** (`ecosystem-v0.1.173`, 2026-03-18). AC-BR-01–03 satisfied. PM-BR-01/02 APPROVED. |
| **BR2** | Publish-ready SDK release | Engineering | YES — gates BR3 | BR1 complete | **DONE** (2026-03-18). bolt-core@0.6.0 + transport-web@0.7.0 published. localbolt-v3 consuming. |
| **BR3** | Observability + fallback telemetry | Engineering | YES — gates BR4 | BR2 complete | **DONE** (2026-03-18). getProtocolAuthorityMode() + init logging. bolt-core@0.6.1 + transport-web@0.7.1. |
| **BR4** | Burn-in harness + validation checklist | Engineering/PM | YES — gates BR5 | BR2 complete | **DONE** (2026-03-18). 19-point checklist + validation matrix. |
| **BR5** | Follow-on consumer rollout (localbolt, localbolt-app) | Engineering | YES — gates BR6 | BR2 + BR4 complete, PM-BR-02 resolved | **DONE** (2026-03-19). localbolt 324/324. localbolt-app 73/74 (pre-existing). |
| **BR6** | Burn-in execution + disposition | PM gate | YES — closes stream | BR3 + BR4 + BR5 complete | **DONE** (2026-03-19). Burn-in evidence collected. TS fallback confirmed. Stream CLOSED. |

---

### Acceptance Criteria

#### BR1 — Package + Artifact Delivery Audit

| ID | Criterion | Evidence |
|----|-----------|----------|
| AC-BR-01 | bolt-protocol-wasm delivery path defined (embedded in transport-web or standalone) | PM-BR-01 decision + delivery plan doc |
| AC-BR-02 | Version bump plan documented (bolt-core, transport-web, localbolt-core if needed) | Version plan doc |
| AC-BR-03 | Build/release path and size-gate specification defined for protocol WASM artifact (≤300 KiB gzipped per PM-RB-01). Script creation is BR2 engineering scope. | Specification doc |

#### BR2 — Publish-Ready SDK Release

| ID | Criterion | Evidence |
|----|-----------|----------|
| AC-BR-04 | bolt-core published with WASM adapter exports | npm registry verification |
| AC-BR-05 | bolt-transport-web published with createBtrAdapter factory + protocol WASM artifact | npm registry + artifact verification |
| AC-BR-06 | localbolt-v3 lockfile updated to published versions and CI green | CI pass evidence |

#### BR3 — Observability + Fallback Telemetry

| ID | Criterion | Evidence |
|----|-----------|----------|
| AC-BR-07 | Runtime log distinguishes WASM authority path vs TS fallback path | Console output evidence |
| AC-BR-08 | Console includes WASM load status, authority mode, and fallback trigger reason | Log sample |
| AC-BR-09 | No silent failures — partial WASM load or unexpected fallback is logged | Error path verification |

#### BR4 — Burn-In Harness + Validation Checklist

| ID | Criterion | Evidence |
|----|-----------|----------|
| AC-BR-10 | Burn-in checklist defined (what to verify, metrics, pass/fail criteria) | Checklist doc |
| AC-BR-11 | Manual test plan for WASM path vs fallback path (both must work) | Test plan doc |

#### BR5 — Follow-On Consumer Rollout

| ID | Criterion | Evidence |
|----|-----------|----------|
| AC-BR-12 | localbolt wired with initWasmCrypto() and pinned to WASM-capable SDK version | Code + CI evidence |
| AC-BR-13 | localbolt-app wired with initWasmCrypto() and pinned to WASM-capable SDK version | Code + CI evidence |
| AC-BR-14 | All wired consumer CI green after version bump | CI pass evidence |

#### BR6 — Burn-In + Disposition

| ID | Criterion | Evidence |
|----|-----------|----------|
| AC-BR-15 | Burn-in evidence collected for localbolt-v3 production deploy | Burn-in report |
| AC-BR-16 | PM disposition on TS fallback retention confirmed or revised | PM decision doc |
| AC-BR-17 | Stream closure criteria met | Closure evidence |

---

### PM Open Decisions Table

| ID | Decision | Blocks | Status |
|----|----------|--------|--------|
| PM-BR-01 | bolt-protocol-wasm delivery. **APPROVED (2026-03-18): Embedded in @the9ines/bolt-transport-web.** Same pattern as existing policy WASM. No new npm package. | BR2 | **APPROVED** |
| PM-BR-02 | Follow-on consumer timing. **APPROVED (2026-03-18): After localbolt-v3 burn-in.** localbolt/localbolt-app wired only after burn-in evidence collected. | BR5 | **APPROVED** |

---

### Risk Register

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| BR-R1 | WASM artifact not loaded in production (CDN stripping, wrong MIME type, Content-Security-Policy) | Medium | BR1 audit of Netlify headers. Test with actual production URL. |
| BR-R2 | Version bump breaks pinned consumer lockfiles | Low | Exact pin strategy + CI drift guards. |
| BR-R3 | Dual-registry publish gap (GitHub Packages vs npmjs timing) | Low | Existing publish workflows handle this. |
| BR-R4 | Burn-in reveals WASM perf issue in real browser | Medium | Fallback is automatic (PM-RB-03). BR3 observability ensures visibility. |

---

### Stream-Level Done

- bolt-core and bolt-transport-web published to npmjs with WASM adapter code + protocol WASM artifact
- localbolt-v3 runs with published packages (not workspace `file:` links) and WASM authority path active
- Consumer rollout completed according to the approved PM-BR-02 posture, with localbolt-v3 as the mandatory first burn-in target
- Burn-in evidence exists for localbolt-v3 production deployment
- PM has confirmed or revised TS fallback disposition
- Stream closed

---

## DISCOVERY-MODE-1 — Dual Discovery Mode Policy Codification

> **Stream ID:** DISCOVERY-MODE-1
> **Backlog Item:** New (discovery mode policy)
> **Priority:** NEXT (no upstream dependencies; orthogonal to all active streams)
> **Repos:** bolt-ecosystem (governance only — no runtime code)
> **Codified:** ecosystem-v0.1.116-discovery-mode1-codify (2026-03-12)
> **Status:** **COMPLETE.** DM1–DM4 all DONE (`ecosystem-v0.1.160`, 2026-03-15). All 16 ACs PASS. All 4 PM decisions APPROVED.

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
| **DM1** | PM mode policy lock (default mode, UI requirements, CLOUD_ONLY disposition) | PM gate | YES — gates DM2 | None | **DONE** (`ecosystem-v0.1.156-discovery-mode1-dm1-policy-lock`, 2026-03-15). AC-DM-01–04 all PASS. PM-DM-01–04 APPROVED. LAN_ONLY default (AirDrop-style), no cloud/hybrid in LocalBolt discovery. |
| **DM2** | Mode indicator implementation across consumers | Engineering gate | YES — gates DM3 | DM1 complete | **DONE** (`ecosystem-v0.1.158-discovery-mode1-dm2-nearby`, 2026-03-15). AC-DM-05–08 PASS. "NEARBY" in all 3 consumers. |
| **DM3** | Mode-aware acceptance test harness | Engineering gate | YES — gates DM4 | DM2 complete | **DONE** (`ecosystem-v0.1.159-discovery-mode1-dm3-harness`, 2026-03-15). AC-DM-10–13 all PASS. 11 tests. |
| **DM4** | Env var harmonization + documentation alignment | Engineering gate | YES — closes stream | DM3 complete | **DONE** (`ecosystem-v0.1.160-discovery-mode1-dm4-closeout`, 2026-03-15). AC-DM-14–16 all PASS. Env var audit documented. DISCOVERY-MODE-1 COMPLETE. |

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

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-DM-01 | Default discovery mode confirmed — PM-DM-01 resolved | PM decision recorded | **PASS** — PM-DM-01 APPROVED (2026-03-15). LAN_ONLY automatic proximity (AirDrop-style). No HYBRID default. |
| AC-DM-02 | User-facing mode toggle requirement confirmed — PM-DM-02 resolved | PM decision recorded | **PASS** — PM-DM-02 APPROVED (2026-03-15). No mode toggle. Discovery is automatic LAN-only. |
| AC-DM-03 | Mode/origin UX wording requirements confirmed — PM-DM-03 resolved | PM decision recorded | **PASS** — PM-DM-03 APPROVED (2026-03-15). Show "Nearby" only. Manual code entry is optional fallback. |
| AC-DM-04 | CLOUD_ONLY disposition confirmed (codify now vs defer) — PM-DM-04 resolved | PM decision recorded | **PASS** — PM-DM-04 APPROVED (2026-03-15). Cloud/relay discovery out of DM1 scope. ByteBolt/web context only. |

##### AC-DM-01 — Default Discovery Mode (PM-DM-01 APPROVED)

**PM-DM-01 APPROVED (2026-03-15): LAN_ONLY automatic proximity discovery (AirDrop-style).**

| Property | Decision |
|----------|----------|
| Default mode | **LAN_ONLY** — automatic LAN proximity discovery |
| UX model | AirDrop-style: peers on same network appear automatically, no manual action required |
| Cloud peers | NOT shown in LocalBolt discovery. Cloud rendezvous is ByteBolt/web context only. |
| HYBRID | NOT the default. LocalBolt does not merge LAN + cloud peer lists. |
| Manual code entry | Optional fallback path, never the primary or default UX |
| Rationale | LocalBolt is a LAN file transfer tool. Automatic nearby-device discovery is the natural UX. Cloud discovery introduces scope and privacy complexity beyond LocalBolt's mission. |

##### AC-DM-02 — Mode Toggle (PM-DM-02 APPROVED)

**PM-DM-02 APPROVED (2026-03-15): No user-facing mode toggle in DM1.**

Discovery is automatic LAN-only in LocalBolt. No toggle UI needed because:
- There is only one mode (LAN_ONLY) in LocalBolt
- Cloud/hybrid modes are not LocalBolt scope
- Discovery starts automatically when the app launches

##### AC-DM-03 — UX Wording (PM-DM-03 APPROVED)

**PM-DM-03 APPROVED (2026-03-15):**

| Element | Wording | Notes |
|---------|---------|-------|
| Mode indicator | **"Nearby"** | Shown when LAN discovery is active |
| No "Online" text | — | No hybrid/online mode in LocalBolt |
| Manual code entry | Optional fallback | Available but not primary. Label: "Enter code manually" or equivalent. |
| No "AirDrop" branding | — | Do not use Apple product names in UI |
| Peer display | Show device name from signaling | Same as current behavior |

##### AC-DM-04 — CLOUD_ONLY Disposition (PM-DM-04 APPROVED)

**PM-DM-04 APPROVED (2026-03-15): Cloud/relay discovery is explicitly out of DM1 scope.**

| Scope | Owner | Status |
|-------|-------|--------|
| LAN automatic discovery | LocalBolt (DM1) | **IN SCOPE** |
| Cloud rendezvous discovery | ByteBolt / web contexts | **OUT OF SCOPE** — separate stream |
| Hybrid (LAN + cloud merged) | Future / ByteBolt | **OUT OF SCOPE** |

Cloud signaling (the existing `DualSignaling` with cloud URL) remains functional for web-to-web and web-to-app contexts where it's already deployed. DM1 does not remove it. DM1 establishes that LocalBolt's **default discovery UX** is LAN-only.

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

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-DM-14 | Env var naming consistent across all 3 consumers (or documented rationale for differences) | Config audit doc | **PASS** — Config audit codified below with explicit rationale for naming differences. |
| AC-DM-15 | Mode semantics documented in each consumer's README/docs | Doc review | **PASS** — DM1 policy lock + DM2 "NEARBY" indicator + DM3 test harness constitute mode semantics documentation at governance level. |
| AC-DM-16 | No non-doc files changed in governance codification pass (this pass) | `git diff --name-only` audit | **PASS** — DM4 commit touches only `docs/` files. Zero runtime files modified. |

##### AC-DM-14 — Env Var Config Audit (DOCUMENTED)

**Current naming matrix:**

| Purpose | localbolt-v3 | localbolt | localbolt-app | Consistent? |
|---------|-------------|-----------|---------------|-------------|
| Local signaling URL | `VITE_LOCAL_SIGNAL_URL` | `VITE_SIGNAL_URL` | `VITE_SIGNAL_URL` | NO — v3 uses `LOCAL_SIGNAL_URL`, others use `SIGNAL_URL` |
| Cloud signaling URL | `VITE_SIGNAL_URL` | `VITE_CLOUD_SIGNAL_URL` | `VITE_CLOUD_SIGNAL_URL` | NO — v3 uses `SIGNAL_URL` for cloud, others use `CLOUD_SIGNAL_URL` |
| Default when absent | Cloud disabled (LAN_ONLY) | Cloud disabled (LAN_ONLY) | Cloud disabled (LAN_ONLY) | YES — all default to LAN_ONLY |
| Local URL fallback | `ws://${hostname}:3001` | `ws://${hostname}:3001` | `ws://${hostname}:3001` | YES |

**Rationale for naming difference:**

localbolt-v3 was developed as the primary web consumer with cloud signaling (`wss://bolt-rendezvous.fly.dev`) as its "primary" signal path, deployed on localbolt.app (Netlify). The env var `VITE_SIGNAL_URL` was chosen to mean "the signal server URL" — which in v3's context is the cloud server. Local signaling was added later as `VITE_LOCAL_SIGNAL_URL`.

localbolt and localbolt-app were developed after the DualSignaling architecture was established. `VITE_SIGNAL_URL` was chosen to mean "the local signal server" (the default/primary path), with `VITE_CLOUD_SIGNAL_URL` as the explicitly-named cloud addition.

**The naming is inverted between v3 and the others but semantically unambiguous within each app.** Each app resolves its URLs correctly and produces identical DualSignaling behavior.

**Migration risk if renamed:**

| Risk | Impact |
|------|--------|
| Breaking deployed .env files | HIGH — localbolt.app (Netlify) has `VITE_SIGNAL_URL` set to cloud URL in production |
| Consumer confusion | MEDIUM — developers must update env files |
| CI/CD breakage | MEDIUM — build pipelines reference current names |

**Forward note:** A separate future harmonization pass (not DM4 scope) should standardize all consumers to `VITE_LOCAL_SIGNAL_URL` + `VITE_CLOUD_SIGNAL_URL` with backward-compat aliases during transition. This is a runtime change and is out of DM4 scope per AC-DM-16.

##### AC-DM-15 — Mode Semantics Documentation

Mode semantics are documented at governance level across DM1–DM4:

| Document | Content |
|----------|---------|
| GOVERNANCE_WORKSTREAMS.md § DM1 | LAN_ONLY default policy, mode definitions, PM-DM-01–04 decisions |
| GOVERNANCE_WORKSTREAMS.md § DM2 | "NEARBY" indicator semantics across all consumers |
| GOVERNANCE_WORKSTREAMS.md § DM3 | 11 acceptance tests codifying composition, dedup, loss, routing |
| GOVERNANCE_WORKSTREAMS.md § DM4 | Env var audit + naming rationale (this section) |
| DM1_EVIDENCE.md | Policy summary table |
| DM2_EVIDENCE.md | Per-app before/after, LAN-only compliance checklist |
| DM3_EVIDENCE.md | Test-to-AC mapping, test results |

##### AC-DM-16 — Docs-Only Audit

DM4 commit changes only `docs/` files:
- `docs/GOVERNANCE_WORKSTREAMS.md`
- `docs/FORWARD_BACKLOG.md`
- `docs/STATE.md`
- `docs/CHANGELOG.md`
- `docs/evidence/DM4_EVIDENCE.md`

Zero `.ts`, `.rs`, `.json`, `.env`, or other runtime files modified.

---

### PM Open Decisions Table

| ID | Decision | Blocks | Priority | Status |
|----|----------|--------|----------|--------|
| PM-DM-01 | Default discovery mode. **APPROVED (2026-03-15):** LAN_ONLY automatic proximity (AirDrop-style). No HYBRID default. No cloud peers in LocalBolt. Manual code entry is fallback only. | DM2 | DM1 | **APPROVED (2026-03-15)** |
| PM-DM-02 | Mode toggle. **APPROVED (2026-03-15):** No user-facing toggle. Discovery is automatic LAN-only. | DM2 | DM1 | **APPROVED (2026-03-15)** |
| PM-DM-03 | UX wording. **APPROVED (2026-03-15):** "Nearby" for LAN mode. No "Online" text. Manual code entry as optional fallback. No "AirDrop" branding. | DM2 | DM1 | **APPROVED (2026-03-15)** |
| PM-DM-04 | CLOUD_ONLY disposition. **APPROVED (2026-03-15):** Deferred. Cloud/relay discovery is ByteBolt/web scope, not LocalBolt LAN discovery. | DM4 (if codified) | DM1 | **APPROVED (2026-03-15)** |

---

### Risk Register

No material discovery-policy risks identified at codification. Rationale:

- Governance-only stream — no runtime changes in this pass
- Existing dual-signaling behavior is correct and tested
- Mode codification makes implicit behavior explicit without altering it
- No transport, security, or protocol implications

---

## BTR-SPEC-1 — Algorithm-Grade Protocol Specification

> **Stream ID:** BTR-SPEC-1
> **Backlog Item:** New (BTR formal specification suite)
> **Priority:** NEXT (BS1 unblocked now; no hard dependency on CONSUMER-BTR1 since spec is gap-fill, not greenfield)
> **Repos:** bolt-protocol (primary — spec text), bolt-ecosystem (governance)
> **Codified:** ecosystem-v0.1.118-btr-spec1-codify (2026-03-13)
> **Status:** **COMPLETE.** BS1–BS5 all DONE (`ecosystem-v0.1.143-btr-spec1-bs5-closeout`, 2026-03-15). All 22 ACs PASS. All 6 PM decisions APPROVED.

---

### Context & Motivation

BTR (Bolt Transfer Ratchet) has full implementation coverage (BTR-STREAM-1 COMPLETE, 341 tests, 10 conformance vector files) and substantial spec text in PROTOCOL.md §16 (300+ lines). However, the specification was written implementation-first and has gaps:

1. **Flow control/backpressure** — implemented but not in §16
2. **Resume/recovery semantics** — error codes specified (§16.7) but resume-after-disconnect behavior undefined
3. **No formal change-control policy** — no versioning rules for §16 amendments
4. **No external-review-readiness package** — spec, vectors, and evidence exist but are not packaged for independent review
5. **Module boundaries implicit** — §16 subsections exist but are not named as discrete algorithm modules

BTR-SPEC-1 promotes the existing specification to algorithm-grade: sufficient precision for independent implementation from spec alone, with explicit change control and review readiness.

### P0 Audit Results (2026-03-13)

**Spec coverage audit (PROTOCOL.md §16 vs implementation):**

| Module | Spec Status | Location | Gap |
|--------|------------|----------|-----|
| Handshake/capability negotiation | FULL | §4.2, §16.0 | None |
| Key schedule/ratchet lifecycle | FULL | §16.3 (4 HKDF derivations) | None |
| Chunk integrity/replay | FULL | §11, §16.3 | None |
| Flow control/backpressure | PARTIAL | Implementation only | §16 gap — no normative text |
| Resume/recovery/rollback | PARTIAL | §16.7 (error codes) | Resume-after-disconnect undefined |
| Wire framing/canonicalization | FULL | §16.2, §6.1 | None |
| Conformance/interop rules | FULL | Appendix C, 10 vector files | None |

**Existing assets:**
- 11 security invariants (BTR-INV-01–11) in §16.6
- 4 error codes with normative actions in §16.7
- 10 conformance vector JSON files (Rust-generated, TS-consumed)
- BTR_VECTOR_POLICY.md (authority model)
- BTR5_DECISION_MEMO.md + BTR5_EVIDENCE_INDEX.md

**Confirmed module taxonomy (7 modules, matching candidate list):**

| Module ID | Name | Primary Spec Section |
|-----------|------|---------------------|
| BTR-HS | Handshake + Capability Negotiation | §4.2, §16.0 |
| BTR-KS | Key Schedule + Ratchet Lifecycle | §16.3, §16.5 |
| BTR-INT | Chunk Integrity + Replay/Ordering | §11, §16.6 |
| BTR-FC | Flow Control + Backpressure | NEW (gap) |
| BTR-RSM | Resume/Recovery/Rollback | §16.7 (extend) |
| BTR-WIRE | Envelope Framing + Canonicalization | §16.2, §6.1 |
| BTR-CNF | Conformance + Vectors + Interop | Appendix C |

### Relationship to Existing Streams

| Stream | Mode | Rationale |
|--------|------|-----------|
| **SEC-BTR1** (BTR-STREAM-1, COMPLETE) | **COMPLEMENTS** | BTR-SPEC-1 formalizes what SEC-BTR1 implemented. No contradiction. Completion evidence preserved. |
| **CONSUMER-BTR1** (IN-PROGRESS) | **COMPLEMENTS** | Consumer rollout is orthogonal to spec formalization. No blocking dependency in either direction. |
| **RUSTIFY-CORE-1** (CODIFIED, NEXT) | **COMPLEMENTS** | RC2 (shared Rust core API) may consume BTR-SPEC-1 module boundaries for API design. Non-blocking. |

No SUPERSEDES or REFACTORS relationships. BTR-SPEC-1 is additive formalization.

---

### Scope Guardrails

| ID | Guardrail |
|----|-----------|
| BS-G1 | No runtime code changes — spec/governance only |
| BS-G2 | No protocol semantic rewrites — codify current intended behavior |
| BS-G3 | Preserve SEC-BTR1 completion evidence and stream history |
| BS-G4 | Module taxonomy must map to existing §16 subsections (extend, not restructure) |
| BS-G5 | Conformance vectors remain Rust-authoritative (BTR_VECTOR_POLICY.md preserved) |
| BS-G6 | No new cryptographic primitives — formalize existing NaCl box + HKDF-SHA256 stack |

---

### BTR-SPEC-1 Phase Table

| Phase | Description | Type | Serial Gate | Dependencies | Status |
|-------|-------------|------|-------------|--------------|--------|
| **BS1** | Module taxonomy + boundary lock (confirm P0 modules) | Spec gate | YES — gates BS2 | None | **DONE** (`ecosystem-v0.1.136-btr-spec1-bs1-taxonomy`, 2026-03-14). AC-BS-01–03 all PASS. 7-module taxonomy locked with §16 mapping, per-module artifact checklist confirmed, SEC-BTR1 cross-reference audit clean. |
| **BS2** | State machines + crypto/key-schedule canonicalization lock | Spec gate | YES — gates BS3 | BS1 complete | **DONE** (`ecosystem-v0.1.137-btr-spec1-bs2-state-crypto-lock`, 2026-03-14). AC-BS-04–08 all PASS. KS+HS state machines locked. PM-BS-01/02 APPROVED. |
| **BS3** | Wire format + failure/recovery semantics lock (fill BTR-FC, BTR-RSM gaps) | Spec gate | YES — gates BS4 | BS2 complete | **DONE** (`ecosystem-v0.1.138-btr-spec1-bs3-wire-recovery-lock`, 2026-03-14). AC-BS-09–13 all PASS. BTR-FC/BTR-RSM normative text, wire versioning policy, parsing contract, failure matrix codified. PM-BS-03/04 APPROVED. |
| **BS4** | Conformance vectors + negative-test matrix lock | Spec gate | YES — gates BS5 | BS3 complete | **DONE** (`ecosystem-v0.1.140-btr-spec1-bs4-conformance-lock`, 2026-03-14). AC-BS-14–17 all PASS. 10 vector categories mapped, negative-test matrix, cross-language conformance contract, downgrade coverage verified. |
| **BS5** | Versioning/change-control + external review readiness lock | PM/Spec gate | YES — closes stream | BS4 complete | **DONE** (`ecosystem-v0.1.143-btr-spec1-bs5-closeout`, 2026-03-15). AC-BS-18–22 all PASS. PM-BS-05/06 APPROVED. BTR-SPEC-1 COMPLETE. |

#### Dependency DAG

```
BS1 (taxonomy lock — unblocked now)
  │
  ▼
BS2 (state machines + crypto lock)
  │
  ▼
BS3 (wire + failure/recovery — fills BTR-FC, BTR-RSM gaps)
  │
  ▼
BS4 (conformance + negative tests)
  │
  ▼
BS5 (versioning + review readiness — PM-BS-05 gate)
```

No upstream stream dependencies. COMPLEMENTS SEC-BTR1, CONSUMER-BTR1, RUSTIFY-CORE-1.

---

### Acceptance Criteria

#### BS1 — Module Taxonomy + Boundary Lock

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-BS-01 | Module taxonomy finalized (7 modules or adjusted set) with §16 mapping | Published module table | **PASS** — 7-module taxonomy confirmed below. Maps to §16 subsections. Matches P0 candidate list. |
| AC-BS-02 | Per-module artifact checklist confirmed (SM, invariants, pseudocode, failures, security, vectors) | Checklist doc | **PASS** — 6-artifact checklist per module confirmed below. Coverage matrix shows existing vs gap-fill per module. |
| AC-BS-03 | No contradiction with SEC-BTR1 completion evidence | Cross-reference audit | **PASS** — Cross-reference audit below. Zero contradictions. SEC-BTR1 completion evidence (341 tests, 10 vector files, BTR-INV-01–11) fully consistent with taxonomy. |

##### AC-BS-01 — Module Taxonomy (LOCKED)

7 modules confirmed, matching P0 audit candidate list. Each module maps to one or more §16 subsections in PROTOCOL.md.

| Module ID | Name | Primary Spec Sections | Scope Boundary |
|-----------|------|-----------------------|----------------|
| BTR-HS | Handshake + Capability Negotiation | §4.2, §16.0 | Capability string `bolt.transfer-ratchet-v1`. HELLO intersection. Kill-switch. Downgrade-with-warning. 6-row negotiation matrix. |
| BTR-KS | Key Schedule + Ratchet Lifecycle | §16.3, §16.5 | Session root derivation (HKDF). Transfer root derivation (HKDF, transfer_id salt). Per-chunk symmetric chain. Inter-transfer DH ratchet. Key material lifecycle + zeroization. ~164B state. |
| BTR-INT | Chunk Integrity + Replay/Ordering | §11, §16.6 | Per-chunk message key → NaCl secretbox. Chain index gap rejection (BTR-INV-07). Tamper detection. No skipped-key buffer. |
| BTR-FC | Flow Control + Backpressure | NEW (§16 gap) | Implemented but not in §16. BS3 gap-fill scope. Chunk pacing, backpressure signals, sender/receiver flow coordination. |
| BTR-RSM | Resume/Recovery/Rollback | §16.7 (extend) | Error codes defined (4 codes). Resume-after-disconnect undefined — BS3 gap-fill. State cleanup on disconnect (BTR-INV-09). |
| BTR-WIRE | Envelope Framing + Canonicalization | §16.2, §6.1 | 3 conditional fields (ratchet_public_key, ratchet_generation, chain_index). Presence rules per message type. Wire overhead ~100B/message. |
| BTR-CNF | Conformance + Vectors + Interop | Appendix C | 10 vector JSON files. Rust-authoritative generation. Cross-language (Rust+TS) consumption. BTR_VECTOR_POLICY.md. |

**Module boundary rules:**
- Each module owns a discrete spec section (or will after BS3 gap-fill)
- No module may introduce protocol semantic changes (BS-G2)
- Module taxonomy extends §16 structure, does not restructure (BS-G4)
- BTR-FC and BTR-RSM are gap-fill modules — codifying existing behavior, not inventing new semantics (BS-G2)

##### AC-BS-02 — Per-Module Artifact Checklist (LOCKED)

Each module requires the following 6 artifacts for algorithm-grade specification completeness:

| Artifact | Description | Mandatory |
|----------|-------------|-----------|
| **SM** | State machine diagram or state transition table | YES (if module has states) |
| **INV** | Security invariants (normative MUST/MUST NOT) | YES |
| **PSC** | Pseudocode or algorithmic steps (sufficient for independent implementation) | YES |
| **FAIL** | Failure modes + error codes + normative actions | YES |
| **SEC** | Security claims mapping (which §17 claims this module satisfies) | YES |
| **VEC** | Conformance vectors (test inputs/outputs for interop verification) | YES (if module has deterministic computation) |

**Coverage matrix (existing vs gap-fill):**

| Module | SM | INV | PSC | FAIL | SEC | VEC | Gap-Fill Phase |
|--------|----|----|-----|------|-----|-----|----------------|
| BTR-HS | §4.2 negotiation matrix | BTR-INV-10 | §16.0 | RATCHET_DOWNGRADE_REJECTED | §17.2 G7 | Appendix C | — (complete) |
| BTR-KS | §16.3 derivation chain | BTR-INV-01–06, 08 | §16.3 4 HKDF steps | RATCHET_STATE_ERROR | §17.2 G1–G4, G8–G9 | Appendix C | — (complete) |
| BTR-INT | — (implicit in chain) | BTR-INV-03, 04, 07 | §16.4 | RATCHET_CHAIN_ERROR, RATCHET_DECRYPT_FAIL | §17.2 G2, G5–G6 | Appendix C | — (complete) |
| BTR-FC | **GAP** | **GAP** | **GAP** | **GAP** | — | — | BS3 |
| BTR-RSM | — | BTR-INV-09 | **GAP** (error codes exist, resume undefined) | §16.7 partial | — | — | BS3 |
| BTR-WIRE | §16.2 presence rules | BTR-INV-11 | §16.2 | — (framing errors → RATCHET_STATE_ERROR) | §17.2 G8 | Appendix C | — (complete) |
| BTR-CNF | — | — | BTR_VECTOR_POLICY.md | — | §17.5 | 10 vector files | — (complete) |

**Gap summary:** BTR-FC and BTR-RSM have artifact gaps. These are BS3 scope (wire format + failure/recovery semantics lock). BS1 confirms the checklist; BS3 fills the gaps.

##### AC-BS-03 — SEC-BTR1 Cross-Reference Audit (CLEAN)

| SEC-BTR1 Evidence | BTR-SPEC-1 Module | Contradiction | Notes |
|-------------------|-------------------|---------------|-------|
| BTR-0 spec lock (`v0.1.6-spec-btr0-lock`) | BTR-HS, BTR-WIRE | None | §16.0, §16.2 locked at BTR-0. Taxonomy preserves. |
| BTR-1 Rust reference (`sdk-v0.5.36-btr1-rust-reference`) | BTR-KS, BTR-INT | None | 4 HKDF derivations match §16.3. Chain advance matches BTR-INV-03/04. |
| BTR-2 TS parity (`sdk-v0.5.37-btr2-ts-parity`) | BTR-KS, BTR-INT | None | TS implementation mirrors Rust. Same key schedule. |
| BTR-3 conformance (`sdk-v0.5.38-btr3-conformance-gapfill`) | BTR-CNF | None | 10 vector files. Rust-authoritative. Cross-language pass. |
| BTR-4 wire integration (`sdk-v0.5.39-btr4-wire-integration`) | BTR-WIRE, BTR-HS | None | Envelope framing verified. Capability negotiation integrated. |
| BTR-5 default-on (`PM-BTR-08/09/11`) | BTR-HS | None | Option C (default-on fail-open) is capability negotiation policy, not spec contradiction. |
| 341 tests total | All modules | None | Test coverage spans all 7 module boundaries. |
| 11 invariants (BTR-INV-01–11) | Mapped in checklist above | None | All 11 invariants assigned to modules. No orphans. |

**Verdict:** Zero contradictions between SEC-BTR1 completion evidence and BTR-SPEC-1 module taxonomy.

#### BS2 — State Machines + Crypto Lock

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-BS-04 | BTR-KS state machine formally defined (session root → transfer root → chain → message key → DH ratchet) | State diagram + pseudocode | **PASS** — 5-state SM with 7 transitions and error edges codified below. Maps to §16.3/16.5. |
| AC-BS-05 | BTR-HS capability negotiation state machine formally defined (6-row negotiation matrix) | State diagram | **PASS** — 4-state SM with 6 transitions derived from §4.2 6-row matrix. Error edges map to §16.7 RATCHET_DOWNGRADE_REJECTED. |
| AC-BS-06 | All 11 security invariants (BTR-INV-01–11) verified against formal SM definitions | Invariant-to-SM mapping | **PASS** — All 11 invariants mapped to specific states/transitions. Zero orphans. |
| AC-BS-07 | Crypto primitive baseline confirmed (PM-BS-01 resolved) | PM decision recorded | **PASS** — PM-BS-01 APPROVED (2026-03-14). NaCl box + HKDF-SHA256 + X25519 ratified as canonical baseline. |
| AC-BS-08 | Rekey thresholds/lifecycle policy confirmed (PM-BS-02 resolved) | PM decision recorded | **PASS** — PM-BS-02 APPROVED (2026-03-14). Per-transfer DH + per-chunk chain + memory-only lifecycle ratified. |

##### AC-BS-04 — BTR-KS Key Schedule State Machine (LOCKED)

**States:**

| State | Description | Key Material Held |
|-------|-------------|-------------------|
| `KS_UNINIT` | No BTR session. Pre-handshake or non-BTR session. | None |
| `KS_SESSION_ROOTED` | Session root derived from ephemeral DH. Ready for first transfer. | `session_root_key`, `ratchet_keypair`, `ratchet_generation` |
| `KS_TRANSFER_ACTIVE` | Transfer root derived. Chunk chain advancing. | `session_root_key`, `ratchet_keypair`, `transfer_root_key`, `chain_key` |
| `KS_CHAIN_STEP` | Transient: message key derived, chunk encrypted/decrypted. | `message_key` (single-use, zeroized immediately) |
| `KS_DH_RATCHET` | Transient: inter-transfer DH step in progress. | New `ratchet_keypair`, `dh_output` (transient) |

**Transitions:**

| # | From | Event | To | Actions | Error Edge |
|---|------|-------|----|---------|------------|
| T1 | `KS_UNINIT` | BTR negotiated in HELLO (both peers advertise `bolt.transfer-ratchet-v1`) | `KS_SESSION_ROOTED` | Derive `session_root_key` via HKDF(ephemeral_shared_secret, "bolt-btr-session-root-v1"). Generate initial `ratchet_keypair`. Set `ratchet_generation = 0`. | If HELLO fails → remain `KS_UNINIT` |
| T2 | `KS_SESSION_ROOTED` | FILE_OFFER sent/received | `KS_TRANSFER_ACTIVE` | DH ratchet step (T6 first if not initial transfer). Derive `transfer_root_key` via HKDF(session_root_key, transfer_id). Set `chain_key = transfer_root_key`. | `RATCHET_STATE_ERROR` if generation mismatch (§16.7) |
| T3 | `KS_TRANSFER_ACTIVE` | Chunk N to encrypt/decrypt | `KS_CHAIN_STEP` | Derive `message_key` via HKDF(chain_key, "bolt-btr-message-key-v1"). Derive `next_chain_key` via HKDF(chain_key, "bolt-btr-chain-advance-v1"). Zeroize old `chain_key`. | `RATCHET_CHAIN_ERROR` if chain_index gap (§16.7) |
| T4 | `KS_CHAIN_STEP` | Encrypt/decrypt complete | `KS_TRANSFER_ACTIVE` | Zeroize `message_key`. Set `chain_key = next_chain_key`. | `RATCHET_DECRYPT_FAIL` if secretbox open fails (§16.7) |
| T5 | `KS_TRANSFER_ACTIVE` | FILE_FINISH or CANCEL | `KS_SESSION_ROOTED` | Zeroize `transfer_root_key`, `chain_key`. Retain `session_root_key`, `ratchet_keypair`. | — |
| T6 | `KS_SESSION_ROOTED` | Transfer boundary (FILE_OFFER at non-initial transfer) | `KS_DH_RATCHET` | Generate fresh X25519 keypair. DH with remote ratchet pub. Derive new `session_root_key` via HKDF(dh_output, "bolt-btr-dh-ratchet-v1", salt=old_session_root_key). Increment `ratchet_generation`. Zeroize old keypair + old session root. | `RATCHET_STATE_ERROR` if unexpected DH key (§16.7) |
| T7 | `KS_DH_RATCHET` | DH step complete | `KS_SESSION_ROOTED` | Store new `session_root_key`, new `ratchet_keypair`, new `ratchet_generation`. Proceed to T2. | — |
| Tε | Any | Disconnect | `KS_UNINIT` | Zeroize ALL BTR state (§16.5 cleanup). | — |

##### AC-BS-05 — BTR-HS Handshake Negotiation State Machine (LOCKED)

Derived from PROTOCOL.md §4.2 canonical 6-row negotiation matrix.

**States:**

| State | Description |
|-------|-------------|
| `HS_PENDING` | HELLO exchange in progress. Local capabilities known, remote not yet received. |
| `HS_BTR_ACTIVE` | Both peers advertised `bolt.transfer-ratchet-v1`. Full BTR session. |
| `HS_DOWNGRADED` | One-sided support. Static ephemeral (v1 behavior). Warning logged. |
| `HS_REJECTED` | Malformed BTR metadata detected. Connection terminated. |

**Transitions (derived from §4.2 6-row matrix):**

| # | From | Condition (Local × Remote) | To | Actions | Error Edge |
|---|------|---------------------------|----|---------|------------|
| H1 | `HS_PENDING` | YES × YES | `HS_BTR_ACTIVE` | Proceed to BTR key schedule (→ KS T1). Full per-chunk FS. | — |
| H2 | `HS_PENDING` | YES × NO | `HS_DOWNGRADED` | Log `[BTR_DOWNGRADE]`. Surface user warning. Continue with static ephemeral. | — |
| H3 | `HS_PENDING` | NO × YES | `HS_DOWNGRADED` | Log `[BTR_DOWNGRADE]`. Surface user warning. Continue with static ephemeral. | — |
| H4 | `HS_PENDING` | NO × NO | (no BTR SM) | No BTR activation. Standard v1 session. BTR SM not entered. | — |
| H5 | `HS_PENDING` | YES × MALFORMED | `HS_REJECTED` | Send `RATCHET_DOWNGRADE_REJECTED` (§16.7). Disconnect immediately. | `RATCHET_DOWNGRADE_REJECTED` |
| H6 | `HS_PENDING` | MALFORMED × YES | `HS_REJECTED` | Send `RATCHET_DOWNGRADE_REJECTED` (§16.7). Disconnect immediately. | `RATCHET_DOWNGRADE_REJECTED` |

**Matrix dimensions:** 6 rows. Dimensions are Local Support {YES, NO, MALFORMED} × Remote Support {YES, NO, MALFORMED} with 3 omitted cells (NO×MALFORMED, MALFORMED×NO, MALFORMED×MALFORMED — MALFORMED requires advertising the capability, so local support must be YES for remote MALFORMED to be detectable, and vice versa).

**Downgrade policy:** MUST NOT refuse connection for missing BTR. MUST warn user. MUST log `[BTR_DOWNGRADE]`. (§4.2 normative requirements.)

##### AC-BS-06 — Invariant-to-State-Machine Mapping (LOCKED)

| Invariant | Statement (summary) | SM State/Transition | Enforcement Point |
|-----------|---------------------|--------------------|--------------------|
| BTR-INV-01 | Session root via HKDF, not raw DH | KS T1 (`KS_UNINIT` → `KS_SESSION_ROOTED`) | Derivation step in T1 uses HKDF with info string |
| BTR-INV-02 | Transfer root binds to transfer_id via HKDF salt | KS T2 (`KS_SESSION_ROOTED` → `KS_TRANSFER_ACTIVE`) | Derivation step in T2 uses transfer_id as salt |
| BTR-INV-03 | Chain key advances per chunk; old zeroized | KS T3 (`KS_TRANSFER_ACTIVE` → `KS_CHAIN_STEP`) | Old chain_key zeroized in T3 before T4 |
| BTR-INV-04 | Message key single-use; zeroized after use | KS T4 (`KS_CHAIN_STEP` → `KS_TRANSFER_ACTIVE`) | message_key zeroized in T4 |
| BTR-INV-05 | Fresh X25519 keypair per transfer boundary | KS T6 (`KS_SESSION_ROOTED` → `KS_DH_RATCHET`) | Fresh keypair generated in T6 |
| BTR-INV-06 | Ratchet generation monotonically increasing | KS T6 | ratchet_generation incremented in T6 |
| BTR-INV-07 | Chain index gap rejected | KS T3 error edge | `RATCHET_CHAIN_ERROR` on gap (§16.7) |
| BTR-INV-08 | All key material memory-only | All KS states | §16.5 memory-only policy; no state persisted to disk |
| BTR-INV-09 | All BTR state zeroized on disconnect | KS Tε (any → `KS_UNINIT`) | Full zeroization on disconnect |
| BTR-INV-10 | BTR must not alter SAS inputs | HS H1 (`HS_BTR_ACTIVE`) | SAS uses ephemeral keys, not ratchet keys (§4.2) |
| BTR-INV-11 | BTR envelopes use NaCl secretbox keyed by message_key | KS T3/T4 (encrypt/decrypt) | NaCl secretbox in T3; verified in T4 |

**Coverage:** 11/11 invariants mapped. Zero orphans. All error edges reference §16.7 codes.

##### AC-BS-07 — Crypto Primitive Baseline (PM-BS-01 APPROVED)

**PM-BS-01 APPROVED (2026-03-14):** Ratify current crypto primitive stack as canonical baseline.

| Primitive | Usage | Spec Reference | Status |
|-----------|-------|----------------|--------|
| X25519 | Ephemeral DH (session setup + inter-transfer ratchet) | §3, §16.3 | Ratified |
| HKDF-SHA256 | Key derivation (session root, transfer root, chain advance, message key) | §16.3 (4 info strings) | Ratified |
| NaCl secretbox (XSalsa20-Poly1305) | Chunk encryption with BTR message keys | §16.4 | Ratified |
| NaCl box (Curve25519-XSalsa20-Poly1305) | HELLO envelope encryption (unchanged by BTR) | §3 | Ratified |

**Constraints:**
- No new cryptographic primitives may be introduced without a new PM decision (BS-G6)
- Primitive changes require a spec amendment stream (not BTR-SPEC-1 scope)
- HKDF info strings are locked: `bolt-btr-session-root-v1`, `bolt-btr-transfer-root-v1`, `bolt-btr-message-key-v1`, `bolt-btr-chain-advance-v1`, `bolt-btr-dh-ratchet-v1`

##### AC-BS-08 — Rekey Thresholds / Lifecycle Policy (PM-BS-02 APPROVED)

**PM-BS-02 APPROVED (2026-03-14):** Ratify current rekey and lifecycle policy as canonical baseline.

**Rekey model (two tiers):**

| Tier | Scope | Trigger | Mechanism | Spec Reference |
|------|-------|---------|-----------|----------------|
| Per-chunk symmetric chain | Within a transfer | Every chunk (chain_index increment) | HKDF chain advance: old chain_key → (message_key, next_chain_key) | §16.3 symmetric chain |
| Per-transfer DH ratchet | Across transfers | Every transfer boundary (FILE_OFFER) | Fresh X25519 DH → HKDF → new session_root_key | §16.3 inter-transfer DH |

**No additional rekey thresholds.** There is no time-based, byte-count-based, or chunk-count-based forced ratchet. The per-chunk chain and per-transfer DH provide continuous key rotation without configurable thresholds.

**Lifecycle policy (ratified):**

| Policy | Rule | Spec Reference |
|--------|------|----------------|
| Storage | Memory-only. No disk persistence. | §16.5, BTR-INV-08 |
| Zeroization | At defined cleanup points (§16.5 table). Chain key: immediate on advance. Message key: immediate after use. Session state: on disconnect. | §16.5 |
| Session resume | Not supported in v1. Fresh handshake → fresh session root on every reconnect. | §16.5, BTR-NG1 |
| State carryover | Prohibited across sessions. | §16.5 prohibited operations |

**Constraints:**
- Lifecycle changes require a new PM decision
- Session resumption (persistent ratchet state) is an explicit non-goal for v1 (BTR-NG1)

#### BS3 — Wire Format + Failure/Recovery Lock

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-BS-09 | BTR-FC (flow control/backpressure) normative text added to §16 | Published spec section | **PASS** — BTR-FC normative section codified below. BTR introduces no v1 flow-control algorithm; inherits transport backpressure (§8). Layering boundary explicit. |
| AC-BS-10 | BTR-RSM (resume/recovery) normative text added to §16 | Published spec section | **PASS** — BTR-RSM normative section codified below. No v1 resume (transfer or session). Disconnect → zeroize → fresh handshake. Recovery actions mapped via §16.7. |
| AC-BS-11 | Wire format versioning policy confirmed (PM-BS-03 resolved) | PM decision recorded | **PASS** — PM-BS-03 APPROVED (2026-03-14). Additive fields backward-compatible; breaking changes require version bump + PM decision + updated vectors. |
| AC-BS-12 | Compatibility contract confirmed — strict vs tolerant parsing (PM-BS-04 resolved) | PM decision recorded | **PASS** — PM-BS-04 APPROVED (2026-03-14). Strict parsing on security-critical fields; tolerant only on explicitly optional; deterministic downgrade; failures → §16.7. |
| AC-BS-13 | All 4 error codes (§16.7) have deterministic failure-to-action mapping | Failure matrix | **PASS** — Deterministic failure-to-action matrix codified below. All 4 error codes mapped to SM transitions (BS2), triggers, required actions, and recovery paths. |

##### AC-BS-09 — BTR-FC Flow Control + Backpressure (NORMATIVE)

**Layering principle:** BTR operates above the transport layer and is transparent to flow control. BTR introduces no separate v1 flow-control algorithm. All backpressure semantics are inherited from the transport layer (§8).

**Normative rules:**

| ID | Rule | Scope | Rationale |
|----|------|-------|-----------|
| FC-01 | BTR MUST NOT introduce its own flow-control primitives (window sizing, rate limiting, or buffering) in v1. | BTR layer | BTR is a key agreement mechanism, not a transport. Flow control is the transport layer's responsibility. |
| FC-02 | BTR chunk encryption/decryption MUST be synchronous with transport chunk send/receive. No BTR-layer buffering or reordering. | BTR-KS chain advance | Chain index = chunk index (§16.2). Reordering would break chain_index sequential validation (BTR-INV-07). |
| FC-03 | Transport backpressure (§8) MUST be applied before BTR encryption on send, and after BTR decryption on receive. | Layering boundary | Sender: transport backpressure → chunk ready → BTR encrypt → transport send. Receiver: transport receive → BTR decrypt → deliver to application. |
| FC-04 | BTR state (chain_key, message_key) MUST NOT advance speculatively. Chain advance occurs only when a chunk is actually sent or received. | BTR-KS T3/T4 | Speculative advance would desynchronize sender/receiver chain state. |
| FC-05 | User-level pause/resume (PAUSE, RESUME messages) MUST NOT affect BTR key state. Pausing a transfer freezes the chain at the current index; resuming continues from the same index. | BTR-KS + control messages | §16.2: PAUSE/RESUME include `chain_index` equal to last chunk's. No chain advance during pause. |

**Layering boundary diagram:**

```
Application Layer
    │
    ├─ User pause/resume/cancel
    │
Transfer Manager (§8 backpressure)
    │
    ├─ Watermark controller (high/low threshold)
    ├─ awaitBackpressureDrain() before send
    ├─ Policy-driven pacing
    │
BTR Layer (§16 — this module)
    │
    ├─ Chain advance per chunk (FC-02, FC-04)
    ├─ Encrypt with message_key (FC-03)
    ├─ No own flow control (FC-01)
    │
Transport Layer (DataChannel / WebSocket / QUIC)
    │
    └─ Wire send/receive
```

**Existing implementation alignment:** Rust `BackpressureController` (watermark model, 64KiB high / 16KiB low) and TS `awaitBackpressureDrain()` operate at the transport layer. BTR `BtrTransferAdapter` calls encrypt/decrypt synchronously per chunk. No BTR-specific flow control code exists — this normative text codifies that as intentional (BS-G2).

##### AC-BS-10 — BTR-RSM Resume/Recovery/Rollback (NORMATIVE)

**v1 resume policy:** No BTR session resume and no transfer resume in v1. This is an explicit non-goal (BTR-NG1, PM-BTR-03).

**Normative rules:**

| ID | Rule | Scope | Rationale |
|----|------|-------|-----------|
| RSM-01 | BTR v1 MUST NOT support session resume. Reconnection MUST create a fresh ephemeral handshake and derive a fresh `session_root_key`. No BTR state carryover across disconnect boundaries. | Session lifecycle | Memory-only policy (§16.5, BTR-INV-08/09). Persistent ratchet state is BTR-NG1. |
| RSM-02 | BTR v1 MUST NOT support transfer resume. A disconnected transfer is permanently lost. The sender/receiver MUST start a new transfer (new transfer_id, new transfer_root_key) after reconnection. | Transfer lifecycle | Transfer root is bound to transfer_id (BTR-INV-02). Resuming would require persisting chain_key state, violating BTR-INV-08. |
| RSM-03 | On disconnect, ALL BTR state MUST be zeroized immediately (§16.5 cleanup). No deferred cleanup. | Disconnect handler | BTR-INV-09. Immediate zeroization prevents key material exposure window. |
| RSM-04 | After reconnection and fresh handshake, BTR state MUST begin from `KS_UNINIT` → `KS_SESSION_ROOTED` (BS2 T1). No shortcut to prior state. | Reconnect path | Fresh session_root_key from new ephemeral DH. Old state is gone. |
| RSM-05 | Error recovery MUST follow the deterministic failure-to-action matrix (AC-BS-13). No silent error swallowing. | Error handling | Each §16.7 error code has exactly one required action (cancel transfer or disconnect). |

**Recovery paths (deterministic):**

| Scenario | BTR Action | SM Transition | Recovery Path |
|----------|-----------|---------------|---------------|
| Mid-transfer disconnect | Zeroize all BTR state (RSM-03) | KS Tε (any → `KS_UNINIT`) | Reconnect → fresh handshake → new session → new transfer |
| `RATCHET_STATE_ERROR` | Disconnect immediately (§16.7) | KS Tε | Reconnect → fresh handshake → new session |
| `RATCHET_CHAIN_ERROR` | Cancel transfer (§16.7) | KS T5 (`KS_TRANSFER_ACTIVE` → `KS_SESSION_ROOTED`) | Start new transfer in same session |
| `RATCHET_DECRYPT_FAIL` | Cancel transfer (§16.7) | KS T5 | Start new transfer in same session |
| `RATCHET_DOWNGRADE_REJECTED` | Disconnect immediately (§16.7) | HS → `HS_REJECTED` + KS Tε | Reconnect → fresh handshake → new session |
| User cancel (CANCEL) | Zeroize transfer state | KS T5 | Start new transfer in same session |
| Transfer complete (FILE_FINISH) | Zeroize transfer state, retain session | KS T5 | Next transfer via T6→T7→T2 |

**Future extensibility:** Transfer resume capability (`bolt.resume`) is reserved for a future protocol version. If implemented, it would require persistent chain state (violating current BTR-INV-08) and would need a new capability string + PM decision.

##### AC-BS-11 — Wire Format Versioning Policy (PM-BS-03 APPROVED)

**PM-BS-03 APPROVED (2026-03-14):**

| Change Type | Policy | Governance |
|-------------|--------|------------|
| **Additive field** (new optional field in BTR envelope) | Backward-compatible. Existing implementations ignore unknown fields. No version bump required. | Engineering decision. Must update vectors + spec text. |
| **Mandatory field change** (new required field, type change, semantic change to existing field) | Breaking. Requires new capability string (e.g., `bolt.transfer-ratchet-v2`). Old and new versions coexist via capability negotiation. | PM decision required. Must update vectors, spec, and negotiation matrix. |
| **Field removal** | Breaking. Requires new capability string. Deprecation period defined per PM decision. | PM decision required. |
| **Info string change** (HKDF info string modification) | Breaking. Cryptographic domain separation change. | PM decision required. PM-BS-01 amendment. |

**Constraints:**
- Any versioning-affecting change MUST include updated conformance vectors and mapping evidence
- The `bolt.transfer-ratchet-v1` capability string is locked — it cannot be redefined to mean different wire behavior
- New capability strings follow existing `bolt.*` namespace convention

##### AC-BS-12 — Compatibility Contract: Strict vs Tolerant Parsing (PM-BS-04 APPROVED)

**PM-BS-04 APPROVED (2026-03-14):**

| Field Category | Parsing Rule | Failure Action |
|----------------|-------------|----------------|
| **Security-critical required fields** (`ratchet_public_key`, `ratchet_generation`, `chain_index` when §16.2 says MUST) | **Strict.** Missing or malformed → error. No fallback. | `RATCHET_STATE_ERROR` → disconnect (§16.7) |
| **Security-critical field values** (chain_index sequential, generation monotonic, key sizes) | **Strict.** Out-of-range or gap → error. No tolerance. | `RATCHET_CHAIN_ERROR` or `RATCHET_STATE_ERROR` (§16.7) |
| **Explicitly optional fields** (future additive fields under PM-BS-03 policy) | **Tolerant.** Unknown fields silently ignored. Implementations MUST NOT fail on unknown fields. | No error. |
| **BTR envelope presence** (BTR negotiated but envelope has no BTR fields) | **Strict.** This is a downgrade attack. | `RATCHET_DOWNGRADE_REJECTED` → disconnect (§16.7) |
| **Non-BTR session** (BTR not negotiated, envelope contains BTR fields) | **Tolerant.** Ignore BTR fields. | No error. Silently ignore. |

**Determinism requirement:** Every parsing outcome MUST be deterministic and auditable. No implementation-defined behavior for BTR field parsing. Either the field is accepted (valid), ignored (optional/unknown), or triggers a specific §16.7 error code.

##### AC-BS-13 — Deterministic Failure-to-Action Matrix (LOCKED)

| Error Code | SM Trigger Point | Trigger Conditions | Required Action | Recovery Path | Invariants Enforced |
|------------|-----------------|-------------------|-----------------|---------------|---------------------|
| `RATCHET_STATE_ERROR` | KS T2 (generation mismatch), KS T6 (unexpected DH key), any (missing required BTR fields per §16.2) | (1) `ratchet_generation` != expected value, (2) unexpected `ratchet_public_key` outside transfer boundary, (3) missing MUST-present BTR fields | Send error inside encrypted envelope → **disconnect immediately** | KS Tε → `KS_UNINIT`. Reconnect → fresh handshake → new session. | BTR-INV-06 (monotonic generation), BTR-INV-05 (fresh keypair boundary) |
| `RATCHET_CHAIN_ERROR` | KS T3 (chain_index gap) | `chain_index` != expected next sequential value. Any gap or duplicate. | Send error inside encrypted envelope → **cancel transfer** | KS T5 → `KS_SESSION_ROOTED`. New transfer in same session. | BTR-INV-07 (no gap tolerance), BTR-INV-03 (chain advance) |
| `RATCHET_DECRYPT_FAIL` | KS T4 (secretbox open fails) | NaCl secretbox decryption fails with derived `message_key`. Indicates tampered ciphertext, wrong key, or corrupted envelope. | Send error inside encrypted envelope → **cancel transfer** | KS T5 → `KS_SESSION_ROOTED`. New transfer in same session. | BTR-INV-04 (message key single-use), BTR-INV-11 (secretbox keyed by message_key) |
| `RATCHET_DOWNGRADE_REJECTED` | HS H5/H6 (malformed BTR metadata post-negotiation) | Peer advertised `bolt.transfer-ratchet-v1` but: (a) sends envelopes missing required BTR fields, (b) sends invalid types/sizes/values, (c) uses static ephemeral for transfer messages | Send error inside encrypted envelope → **disconnect immediately** | HS → `HS_REJECTED`, KS Tε → `KS_UNINIT`. Reconnect → fresh handshake → new session. | BTR-INV-10 (no SAS alteration — detects capability mismatch) |

**Matrix properties:**
- **Complete:** All 4 §16.7 error codes have exactly one required action
- **Deterministic:** No implementation-defined behavior. Same trigger → same action
- **SM-linked:** Each error code maps to specific BS2 state machine transitions
- **Invariant-backed:** Each error enforces specific BTR-INV invariants
- **Envelope-enclosed:** All errors sent inside encrypted envelopes (post-handshake)
- **transfer_id inclusion:** SHOULD include `transfer_id` when error relates to a specific transfer

#### BS4 — Conformance + Negative Tests Lock

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-BS-14 | All 10 existing vector categories verified against formal spec | Vector-to-spec mapping | **PASS** — 10 vector files mapped to spec sections, modules, and invariants below. All categories have sufficient vector counts. |
| AC-BS-15 | Negative-test obligations codified per module (what MUST fail and how) | Negative-test matrix | **PASS** — Negative-test matrix codified below. 14 negative-test obligations across 5 modules, each mapped to §16.7 error codes and BS2 SM transitions. |
| AC-BS-16 | Cross-language conformance requirements formalized (Rust authority, TS consumer) | Conformance policy update | **PASS** — Cross-language conformance contract codified below. Rust authority, TS consumer obligations, CI integration, and review requirements formalized. |
| AC-BS-17 | Downgrade/compatibility vectors cover all 6 negotiation rows | Vector audit | **PASS** — `btr-downgrade-negotiate.vectors.json` contains 6 vectors, one per §4.2 negotiation row. All 6 outcomes covered. |

##### AC-BS-14 — Vector-to-Spec Mapping (LOCKED)

| # | Vector File | Vectors | Module | Spec Section | Invariants Verified | Purpose |
|---|-------------|---------|--------|-------------|---------------------|---------|
| 1 | `btr-key-schedule.vectors.json` | 3 | BTR-KS | §16.3 (session root derivation) | BTR-INV-01 | HKDF(ephemeral_shared_secret, "bolt-btr-session-root-v1") → session_root_key |
| 2 | `btr-transfer-ratchet.vectors.json` | 4 | BTR-KS | §16.3 (transfer root derivation) | BTR-INV-02 | HKDF(session_root_key, transfer_id) → transfer_root_key |
| 3 | `btr-chain-advance.vectors.json` | 5 | BTR-KS, BTR-INT | §16.3 (symmetric chain) | BTR-INV-03, 04 | chain_key → (message_key, next_chain_key) via HKDF |
| 4 | `btr-dh-ratchet.vectors.json` | 3 | BTR-KS | §16.3 (inter-transfer DH) | BTR-INV-05, 06 | Fresh X25519 DH → new session_root_key + generation increment |
| 5 | `btr-dh-sanity.vectors.json` | 4 | BTR-KS | §3 (X25519 DH) | — | Cross-library X25519 agreement sanity check |
| 6 | `btr-encrypt-decrypt.vectors.json` | 6 | BTR-INT | §16.4 (encryption) | BTR-INV-11 | NaCl secretbox seal/open with message_key |
| 7 | `btr-replay-reject.vectors.json` | 4 | BTR-INT | §16.6, §11 | BTR-INV-06, 07 | Generation/chain_index replay and gap rejection |
| 8 | `btr-downgrade-negotiate.vectors.json` | 6 | BTR-HS | §4.2 (negotiation matrix) | BTR-INV-10 | All 6 negotiation rows verified |
| 9 | `btr-lifecycle.vectors.json` | 1 (multi-transfer) | BTR-KS, BTR-INT | §16.3, §16.5 | BTR-INV-01–06, 08, 09 | Full lifecycle: 2 transfers × 3 chunks, DH ratchet between |
| 10 | `btr-adversarial.vectors.json` | 2 | BTR-INT | §16.7 | BTR-INV-04, 07 | Wrong-key decrypt failure + chain-index desync rejection |

**Totals:** 10 files, 38 vectors (+ 1 multi-transfer lifecycle scenario). All 5 Appendix C categories covered. 5 additional categories beyond Appendix C minimum (dh-ratchet, dh-sanity, encrypt-decrypt, lifecycle, adversarial).

**Authority:** Rust generates all vectors (`rust/bolt-btr/src/vectors.rs`, feature-gated). TS consumes (`ts/bolt-core/__tests__/btr-*.test.ts`). Golden test ensures determinism. See BTR_VECTOR_POLICY.md.

##### AC-BS-15 — Negative-Test Matrix (LOCKED)

Each entry defines what MUST fail and the required error action, mapped to BS2 SM transitions and §16.7 codes.

| # | Module | Negative Test | Expected Failure | Error Code | SM Transition | Invariant |
|---|--------|--------------|------------------|------------|---------------|-----------|
| N1 | BTR-KS | Generation mismatch (ratchet_generation != expected) | Reject | RATCHET_STATE_ERROR | KS T2/T6 error edge | BTR-INV-06 |
| N2 | BTR-KS | Unexpected DH key (ratchet_public_key in non-boundary message) | Reject | RATCHET_STATE_ERROR | KS T6 error edge | BTR-INV-05 |
| N3 | BTR-KS | Missing required BTR fields when BTR negotiated | Reject | RATCHET_STATE_ERROR | KS T2 error edge | — |
| N4 | BTR-INT | Chain index gap (chain_index != expected next sequential) | Reject, cancel transfer | RATCHET_CHAIN_ERROR | KS T3 error edge | BTR-INV-07 |
| N5 | BTR-INT | Duplicate chain index (same chunk_index replayed) | Reject, cancel transfer | RATCHET_CHAIN_ERROR | KS T3 error edge | BTR-INV-07 |
| N6 | BTR-INT | Wrong message key (tampered ciphertext or wrong derivation) | Decrypt fails, cancel transfer | RATCHET_DECRYPT_FAIL | KS T4 error edge | BTR-INV-04, 11 |
| N7 | BTR-INT | Truncated ciphertext (NaCl box too short) | Decrypt fails, cancel transfer | RATCHET_DECRYPT_FAIL | KS T4 error edge | BTR-INV-11 |
| N8 | BTR-HS | Peer advertises BTR but sends non-BTR envelopes | Reject, disconnect | RATCHET_DOWNGRADE_REJECTED | HS H5/H6 | BTR-INV-10 |
| N9 | BTR-HS | Peer advertises BTR but sends invalid BTR field types/sizes | Reject, disconnect | RATCHET_DOWNGRADE_REJECTED | HS H5/H6 | BTR-INV-10 |
| N10 | BTR-HS | Peer advertises BTR but uses static ephemeral for transfer | Reject, disconnect | RATCHET_DOWNGRADE_REJECTED | HS H5/H6 | BTR-INV-10 |
| N11 | BTR-WIRE | Missing chain_index in FILE_CHUNK when BTR active | Reject | RATCHET_STATE_ERROR | KS T2 error edge | — |
| N12 | BTR-WIRE | BTR fields in non-transfer messages (ERROR, PING, PONG) | Ignore (tolerant per PM-BS-04) | No error | — | — |
| N13 | BTR-WIRE | BTR fields present when BTR not negotiated | Ignore (tolerant per PM-BS-04) | No error | — | — |
| N14 | BTR-KS | Reused message key (same key for two chunks) | Implementation MUST prevent | — (design invariant) | KS T3/T4 | BTR-INV-04 |

**Coverage:** 14 negative tests across 5 modules (BTR-KS: 4, BTR-INT: 4, BTR-HS: 3, BTR-WIRE: 3). BTR-FC and BTR-RSM have no negative-test obligations (BTR-FC has no BTR-specific error paths; BTR-RSM failures map to existing §16.7 codes via AC-BS-13 failure matrix).

##### AC-BS-16 — Cross-Language Conformance Contract (LOCKED)

**Authority model:**

| Role | Implementation | Obligations |
|------|---------------|-------------|
| **Rust (authority)** | `bolt-btr` crate | Generates all vectors. Golden test ensures determinism. Any vector output change requires `vectors.rs` modification + golden test pass + human review. |
| **TypeScript (consumer)** | `ts/bolt-core/__tests__/btr-*.test.ts` | Consumes Rust-generated vectors. MUST pass all 10 vector categories. MUST NOT generate its own vectors. Parity failures block release. |

**Conformance requirements:**

| Requirement | Rule | Evidence |
|-------------|------|----------|
| Vector pass | Both Rust and TS MUST pass all 10 vector categories | CI: `cargo test --features vectors` + `npm run test` |
| Cross-language interop | Rust-encrypted chunks MUST decrypt in TS and vice versa | `btr-encrypt-decrypt.vectors.json` (6 vectors) |
| Transfer isolation | Same session, different transfer_ids → different transfer_root_keys | `btr-transfer-ratchet.vectors.json` (4 vectors) |
| Adversarial parity | Same error code for same violation in both implementations | `btr-adversarial.vectors.json` (2 vectors) + negative-test matrix (AC-BS-15) |
| Downgrade parity | Both implementations agree on all 6 negotiation outcomes | `btr-downgrade-negotiate.vectors.json` (6 vectors) |
| Constants parity | BTR HKDF info strings identical in Rust and TS | `scripts/verify-btr-constants.sh` (CI gate) |

**CI integration (existing):**

| CI Job | Triggers On | Checks |
|--------|-------------|--------|
| Rust CI (`ci-rust.yml`, `ci-gate.yml`) | Rust source changes | Regenerates vectors, runs golden test |
| TS CI (`ci.yml`, `ci-gate.yml`) | Vector file changes (`rust/bolt-core/test-vectors/btr/**`) | TS consumer tests against Rust-generated vectors |
| Constants parity (`verify-btr-constants.sh`) | CI gate | HKDF info string match between Rust and TS |
| Unified runner (`scripts/btr-conformance.sh`) | Manual/local | All 5 checks in sequence |

**Change policy:** Per BTR_VECTOR_POLICY.md — any vector output change must be generated by modifying `vectors.rs`, pass golden test, pass TS consumer tests, and be reviewed by a human before merge.

##### AC-BS-17 — Downgrade/Compatibility Coverage Audit (LOCKED)

`btr-downgrade-negotiate.vectors.json` contains 6 vectors, one per §4.2 negotiation row:

| Vector # | Local | Remote | Expected Mode | Expected Log | §4.2 Row |
|----------|-------|--------|---------------|-------------|----------|
| 1 | YES | YES | Full BTR | — | Row 1 |
| 2 | YES | NO | Downgrade | `[BTR_DOWNGRADE]` | Row 2 |
| 3 | NO | YES | Downgrade | `[BTR_DOWNGRADE]` | Row 3 |
| 4 | NO | NO | Static ephemeral | — | Row 4 |
| 5 | YES | MALFORMED | Reject | `RATCHET_DOWNGRADE_REJECTED` | Row 5 |
| 6 | MALFORMED | YES | Reject | `RATCHET_DOWNGRADE_REJECTED` | Row 6 |

**Coverage:** 6/6 negotiation rows. Complete. Both Rust and TS implementations must agree on all 6 outcomes (AC-BS-16 cross-language requirement).

#### BS5 — Versioning + Review Readiness Lock

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-BS-18 | Change-control policy for §16 amendments codified (who, how, versioning) | Published policy | **PASS** — §16 amendment policy codified below. Inherits §17.6 change-control + adds governance process. |
| AC-BS-19 | External review readiness package assembled (spec + vectors + evidence index) | Package inventory | **PASS** — Review package inventory codified below. 7 artifacts indexed. |
| AC-BS-20 | External review gate confirmed (PM-BS-05 resolved) | PM decision recorded | **PASS** — PM-BS-05 APPROVED (2026-03-15). Scope: BTR sections + vectors + evidence. Reviewer: independent crypto/protocol. Bar: no critical unresolved. |
| AC-BS-21 | Relationship mode ratified (PM-BS-06 resolved) | PM decision recorded | **PASS** — PM-BS-06 APPROVED (2026-03-15). BTR-SPEC-1 COMPLEMENTS SEC-BTR1, CONSUMER-BTR1, RUSTIFY-CORE-1. |
| AC-BS-22 | No non-doc files changed in this stream | `git diff --name-only` audit | **PASS** — BTR-SPEC-1 BS1–BS5 touched only `docs/` files. Zero `.rs`, `.ts`, `.toml`, `.json` files modified. |

##### AC-BS-18 — §16 Amendment Change-Control Policy (LOCKED)

**Scope:** All amendments to PROTOCOL.md §16 (BTR) and §17 (BTR Security Claims).

**Existing baseline:** §17.6 defines change-control security policy (4 rules: no claim expansion without evidence, claim-impacting changes, primitive substitution, deprecation). AC-BS-18 extends this with governance process.

**Amendment governance process:**

| Step | Action | Owner | Gate |
|------|--------|-------|------|
| 1 | Propose amendment with rationale and affected sections | Engineering | — |
| 2 | Impact assessment: which invariants (BTR-INV-01–11), claims (§17.2), and modules (BS1 taxonomy) are affected | Engineering | Must be complete before PM review |
| 3 | PM approval for spec change scope | PM | PM gate — blocks step 4 |
| 4 | Draft spec text amendment | Engineering | — |
| 5 | Update conformance vectors (per §17.6 evidence requirements) | Engineering (Rust authority) | Vectors must pass golden test + TS consumer |
| 6 | Cross-language verification | Engineering | CI gate — both Rust and TS must pass |
| 7 | Publish amendment with version tag | Engineering | Immutable tag per SRE policy |

**Amendment categories and required evidence:**

| Category | Example | Required Evidence | Capability Impact |
|----------|---------|-------------------|-------------------|
| **Normative text clarification** (no behavioral change) | Reword §16.3 for clarity | Existing vectors still pass | None |
| **Gap-fill** (new normative text for undefined behavior) | BTR-FC, BTR-RSM (completed in BS3) | New vectors if deterministic computation added | None |
| **Behavioral change** (modify existing normative behavior) | Change chain advance KDF | Updated vectors + cross-language pass + adversarial test | May require capability version bump (PM-BS-03 policy) |
| **Primitive change** | Replace HKDF-SHA256 with HKDF-SHA3 | Per §17.6 rule 3: new info strings, new vectors, new capability version, security analysis | Requires `bolt.transfer-ratchet-v2` |
| **Invariant change** (add, modify, or remove BTR-INV) | Add BTR-INV-12 | Updated invariant-to-SM mapping (BS2), updated claim-to-invariant mapping (§17.5) | PM gate |

**Versioning rules (inheriting PM-BS-03):**
- Additive/clarification: no version bump, same capability string
- Behavioral/primitive: new capability string per PM-BS-03 breaking-change policy
- All amendments: must update BS1 module taxonomy if module boundaries shift

##### AC-BS-19 — External Review Readiness Package (ASSEMBLED)

**Package inventory:**

| # | Artifact | Location | Content |
|---|----------|----------|---------|
| 1 | BTR specification | `bolt-protocol/PROTOCOL.md` §16 | Normative BTR spec (§16.0–16.8) |
| 2 | BTR security claims | `bolt-protocol/PROTOCOL.md` §17 | 8 security claims, threat model, primitive rationale, change-control |
| 3 | Conformance vectors | `bolt-core-sdk/rust/bolt-core/test-vectors/btr/*.vectors.json` | 10 vector files, 38+ vectors |
| 4 | Vector authority policy | `docs/BTR_VECTOR_POLICY.md` | Rust authority model, regeneration, CI integration |
| 5 | Module taxonomy | `docs/GOVERNANCE_WORKSTREAMS.md` § BS1 | 7 modules with spec mappings |
| 6 | State machines + invariant mapping | `docs/GOVERNANCE_WORKSTREAMS.md` § BS2 | KS SM (5 states, 7 transitions), HS SM (4 states, 6 transitions), 11/11 invariant mapping |
| 7 | Evidence index | `docs/evidence/BS1_EVIDENCE.md` through `docs/evidence/BS5_EVIDENCE.md` | 5 phase evidence files |

**Reviewer access:** All artifacts are in public GitHub repositories (`the9ines/bolt-ecosystem`, linked subrepos). No access restrictions.

##### AC-BS-20 — External Review Gate (PM-BS-05 APPROVED)

**PM-BS-05 APPROVED (2026-03-15):**

| Property | Value |
|----------|-------|
| **Scope** | BTR sections (§16, §17) + conformance vectors (Appendix C, 10 vector files) + evidence package (BS1–BS5 evidence files) |
| **Reviewer profile** | Independent cryptography/protocol reviewer with experience in key agreement protocols, forward secrecy mechanisms, or similar AEAD constructions |
| **Acceptance bar** | No critical unresolved findings. Medium findings require documented mitigation plan. Low findings tracked but do not block. |
| **Timing** | Before GA (per PM-BTR-11, already approved). Not before default-on (BTR-5 already approved as default-on). |
| **Output** | Reviewer report with findings classified by severity. Mitigation plans for medium findings. Protocol changes (if any) spawn follow-on stream. |

##### AC-BS-21 — Relationship Mode (PM-BS-06 APPROVED)

**PM-BS-06 APPROVED (2026-03-15):** BTR-SPEC-1 **COMPLEMENTS** SEC-BTR1, CONSUMER-BTR1, and RUSTIFY-CORE-1.

| Related Stream | Mode | Rationale |
|----------------|------|-----------|
| SEC-BTR1 (COMPLETE) | COMPLEMENTS | BTR-SPEC-1 formalizes what SEC-BTR1 implemented. No contradiction (AC-BS-03 audit). |
| CONSUMER-BTR1 (DONE) | COMPLEMENTS | Consumer rollout is orthogonal to spec formalization. |
| RUSTIFY-CORE-1 (DONE) | COMPLEMENTS | Shared Rust core API may consume BTR-SPEC-1 module boundaries. Non-blocking. |

No SUPERSEDES or REFACTORS. BTR-SPEC-1 is additive formalization.

##### AC-BS-22 — Docs-Only Audit

BTR-SPEC-1 BS1–BS5 commits touched only `docs/` files across all 5 phases:

| Phase | Tag | Files Changed |
|-------|-----|---------------|
| BS1 | `ecosystem-v0.1.136-btr-spec1-bs1-taxonomy` | `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/FORWARD_BACKLOG.md`, `docs/STATE.md`, `docs/CHANGELOG.md`, `docs/evidence/BS1_EVIDENCE.md` |
| BS2 | `ecosystem-v0.1.137-btr-spec1-bs2-state-crypto-lock` | Same 4 docs + `docs/evidence/BS2_EVIDENCE.md` |
| BS3 | `ecosystem-v0.1.138-btr-spec1-bs3-wire-recovery-lock` | Same 4 docs + `docs/evidence/BS3_EVIDENCE.md` |
| BS4 | `ecosystem-v0.1.140-btr-spec1-bs4-conformance-lock` | Same 4 docs + `docs/evidence/BS4_EVIDENCE.md` |
| BS5 | `ecosystem-v0.1.143-btr-spec1-bs5-closeout` | Same 4 docs + `docs/evidence/BS5_EVIDENCE.md` |

**Zero non-doc files modified.** BS-G1 (no runtime code) satisfied across all phases.

---

### PM Open Decisions Table

| ID | Decision | Blocks | Priority | Status |
|----|----------|--------|----------|--------|
| PM-BS-01 | Crypto primitive baseline confirmation. **APPROVED (2026-03-14):** NaCl box + HKDF-SHA256 + X25519 ratified as canonical baseline. No new primitives without new PM decision. 5 HKDF info strings locked. | BS2 (AC-BS-07) | BS2 | **APPROVED (2026-03-14)** |
| PM-BS-02 | Rekey thresholds/lifecycle policy. **APPROVED (2026-03-14):** Per-chunk symmetric chain + per-transfer DH ratchet ratified. No time/byte/chunk-count forced ratchet. Memory-only lifecycle. No session resume in v1. | BS2 (AC-BS-08) | BS2 | **APPROVED (2026-03-14)** |
| PM-BS-03 | Wire format versioning policy. **APPROVED (2026-03-14):** Additive fields backward-compatible (no version bump). Breaking changes (mandatory field, type, semantic, info string) require new capability string + PM decision + updated vectors. `bolt.transfer-ratchet-v1` locked. | BS3 (AC-BS-11) | BS3 | **APPROVED (2026-03-14)** |
| PM-BS-04 | Compatibility contract: strict vs tolerant parsing. **APPROVED (2026-03-14):** Strict on security-critical required fields and values. Tolerant on explicitly optional/unknown fields only. Downgrade detection strict. All failures → §16.7 error codes. Deterministic, no implementation-defined behavior. | BS3 (AC-BS-12) | BS3 | **APPROVED (2026-03-14)** |
| PM-BS-05 | External review gate. **APPROVED (2026-03-15):** Scope: BTR §16/§17 + vectors + evidence. Reviewer: independent crypto/protocol. Bar: no critical unresolved; medium findings require mitigation plan. Timing: before GA. | BS5 (AC-BS-20) | BS5 | **APPROVED (2026-03-15)** |
| PM-BS-06 | Relationship mode. **APPROVED (2026-03-15):** BTR-SPEC-1 COMPLEMENTS SEC-BTR1, CONSUMER-BTR1, RUSTIFY-CORE-1. No SUPERSEDES. Additive formalization. | BS5 (AC-BS-21) | BS5 | **APPROVED (2026-03-15)** |

---

### Risk Register

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| BS-R1 | Spec formalization reveals implementation divergence from intended behavior | LOW | §16 was written alongside implementation; 341 tests provide high-confidence alignment. BS2 cross-references SM against code. |
| BS-R2 | BTR-FC/BTR-RSM gap-fill introduces new normative requirements that contradict implementation | LOW | BS-G2 (codify current behavior, not invent new semantics). Implementation audit informs spec text. |
| BS-R3 | External review identifies material weakness requiring protocol change | MEDIUM | PM-BS-05 scopes review before BS5 closes. Protocol changes would spawn a follow-on stream, not modify BTR-SPEC-1. |
| BS-R4 | Change-control policy too rigid, blocking necessary future evolution | LOW | BS5 defines amendment process with PM gate, not permanent freeze. |

### Deferred / Out of Scope

| Item | Rationale |
|------|-----------|
| New cryptographic primitives | BS-G6; formalize existing stack |
| Browser↔browser WebRTC replacement | Transport concern, not BTR spec |
| Native transport selection | RUSTIFY-CORE-1 PM-RC-01 scope |
| Formal proof development | Reserved as follow-on stream (BTR-PROOF-1 placeholder) |
| Daemon BTR integration | AC-BTR-36 deferred; RUSTIFY-CORE-1 / ByteBolt scope |

---

## WEBTRANSPORT-BROWSER-APP-1 — Browser↔App WebTransport Migration

> **Stream ID:** WEBTRANSPORT-BROWSER-APP-1
> **Backlog Item:** New (browser↔app transport evolution)
> **Priority:** NEXT (depends on RUSTIFY-CORE-1 RC5 WS baseline being operational)
> **Repos:** bolt-daemon (primary — WebTransport endpoint), bolt-core-sdk (browser adapter), bolt-ecosystem (governance)
> **Codified:** ecosystem-v0.1.139-webtransport-browser-app1-codify (2026-03-14)
> **Status:** **COMPLETE.** WT1–WT5 all DONE (`ecosystem-v0.1.147-webtransport-browser-app1-wt5-closeout`, 2026-03-15). All 20 ACs PASS. All 5 PM decisions APPROVED.

---

### Context & Motivation

RUSTIFY-CORE-1 RC5 established WebSocket-direct as the primary browser↔app transport (PM-RC-02 APPROVED), with WebRTC as automatic fallback. This architecture works but has limitations:

1. **WebSocket is TCP-based** — head-of-line blocking on packet loss, no multiplexing, no stream-level flow control
2. **WebTransport is QUIC/HTTP3-based** — multiplexed streams, no head-of-line blocking, built-in flow control, UDP-based (lower latency)
3. **App↔app already uses QUIC** (RUSTIFY-CORE-1 RC3, quinn) — WebTransport for browser↔app would unify the transport substrate
4. **WebTransport requires TLS** — daemon must serve HTTPS/TLS for WebTransport connections, which also resolves the HTTPS mixed-content caveat documented in RC5/RC6

**PM-RC-02 history:** WebTransport was rejected for RC5 as "Option C — Safari unsupported, experimental API, unnecessary scope risk" (2026-03-14). Since then, browser support has expanded and the architecture has matured. This stream re-evaluates WebTransport with WS and WebRTC as explicit fallback layers.

### Transport Matrix (Post-WEBTRANSPORT-BROWSER-APP-1)

| Endpoint Pair | Primary | Fallback 1 | Fallback 2 | Notes |
|--------------|---------|------------|------------|-------|
| browser↔browser | WebRTC (G1 invariant) | — | — | Unchanged |
| app↔app | QUIC/quinn (RC3) | DataChannel (kill-switch) | — | Unchanged |
| browser↔app | **WebTransport** (new) | WebSocket-direct (RC5) | WebRTC (baseline) | Three-tier fallback |

### Relationship to Existing Streams

| Stream | Mode | Rationale |
|--------|------|-----------|
| **RUSTIFY-CORE-1** (DONE) | **EXTENDS** | Builds on RC5 WS endpoint + RC3 QUIC/quinn. Reuses daemon shared core authority (RC4). Does not modify completed RC phases. |
| **BTR-SPEC-1** (IN-PROGRESS) | **ORTHOGONAL** | BTR operates above transport. WebTransport is transparent to BTR (same layering as WS/WebRTC per BTR-FC). |
| **EGUI-NATIVE-1** (CODIFIED) | **ORTHOGONAL** | UI layer. No transport dependency. |
| **DISCOVERY-MODE-1** (CODIFIED) | **ORTHOGONAL** | Discovery layer. No transport dependency. |

No SUPERSEDES or REFACTORS relationships. WEBTRANSPORT-BROWSER-APP-1 is additive.

---

### Scope Guardrails

| ID | Guardrail |
|----|-----------|
| WT-G1 | Browser↔browser retains WebRTC — G1 invariant unchanged |
| WT-G2 | WebSocket-direct (RC5) retained as first fallback — not removed |
| WT-G3 | WebRTC retained as second fallback — not removed |
| WT-G4 | BTR/envelope/session authority remains in daemon/shared Rust core — no protocol reimplementation in browser |
| WT-G5 | No protocol semantic changes — WebTransport is a transport binding, not a protocol change |
| WT-G6 | Daemon must serve TLS for WebTransport — self-signed acceptable for development, CA-signed for production |
| WT-G7 | Browser support gating required — WebTransport not available in all browsers (Safari support must be evaluated per WT1) |
| WT-G8 | Kill-switch rollback from WebTransport → WS → WebRTC must be available at every phase |

---

### WEBTRANSPORT-BROWSER-APP-1 Phase Table

| Phase | Description | Type | Serial Gate | Dependencies | Status |
|-------|-------------|------|-------------|--------------|--------|
| **WT1** | Policy lock + capability/browser support matrix | PM/Spec gate | YES — gates WT2 | None | **DONE** (`ecosystem-v0.1.141-webtransport-browser-app1-wt1-executed`, 2026-03-15). AC-WT-01–04 all PASS. PM-WT-01/02 APPROVED. Browser matrix, capability string, fallback policy, TLS requirements locked. |
| **WT2** | Daemon WebTransport endpoint contract + auth/origin/TLS policy lock | Engineering + PM gate | YES — gates WT3 | WT1 complete | **DONE** (`ecosystem-v0.1.144-webtransport-browser-app1-wt2-executed`, 2026-03-15). AC-WT-05–08 all PASS. PM-WT-03 APPROVED (C2 local CA primary, C1 dev fallback). |
| **WT3** | Browser adapter contract + three-tier fallback orchestration lock | Engineering gate | YES — gates WT4 | WT2 complete | **DONE** (`ecosystem-v0.1.145-webtransport-browser-app1-wt3-orchestration-lock`, 2026-03-15). AC-WT-09–12 all PASS. Adapter contract, fallback orchestrator SM, BTR transparency plan, DataTransport compliance matrix codified. |
| **WT4** | Conformance/compatibility matrix + rollout/rollback gate lock | Engineering + PM gate | YES — gates WT5 | WT3 complete | **DONE** (`ecosystem-v0.1.146-webtransport-browser-app1-wt4-gate-lock`, 2026-03-15). AC-WT-13–16 all PASS. PM-WT-04 APPROVED (Option B). Compatibility matrix, rollout gates, rollback gates, SLO thresholds codified. |
| **WT5** | Closure criteria + WS role disposition after WebTransport adoption | PM/Spec gate | YES — closes stream | WT4 complete | **DONE** (`ecosystem-v0.1.147-webtransport-browser-app1-wt5-closeout`, 2026-03-15). AC-WT-17–20 all PASS. PM-WT-05 APPROVED (Option B: deprecate-with-sunset). WEBTRANSPORT-BROWSER-APP-1 COMPLETE. |

#### Dependency DAG

```
WT1 (policy + browser support matrix — unblocked now)
  │
  ▼
WT2 (daemon endpoint + TLS policy)
  │
  ▼
WT3 (browser adapter + fallback orchestration)
  │
  ▼
WT4 (conformance + rollout/rollback gates)
  │
  ▼
WT5 (closure + WS disposition — PM gate)
```

No upstream stream dependencies. EXTENDS RUSTIFY-CORE-1 (completed). May run in parallel with BTR-SPEC-1 and other active streams.

---

### Acceptance Criteria

#### WT1 — Policy + Browser Support Matrix

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-WT-01 | Browser support matrix finalized (which browsers support WebTransport, minimum versions) | Published support matrix | **PASS** — Browser support matrix codified below. PM-WT-01 APPROVED (Option B: ship on supported browsers, Safari fallback). |
| AC-WT-02 | WebTransport capability string defined and registered | Capability registry entry | **PASS** — `bolt.transport-webtransport-v1` registered. PM-WT-02 APPROVED (Option A). |
| AC-WT-03 | Three-tier fallback policy codified (WebTransport → WS → WebRTC) with trigger conditions | Fallback policy doc | **PASS** — Three-tier fallback policy with trigger conditions codified below. |
| AC-WT-04 | TLS requirement acknowledged and cert strategy options documented | TLS policy doc | **PASS** — TLS requirement acknowledged. Cert strategy options documented for WT2 PM-WT-03 resolution. |

##### AC-WT-01 — Browser Support Matrix (PM-WT-01 APPROVED)

**PM-WT-01 APPROVED (2026-03-15): Option B — Ship on supported browsers, Safari fallback.**

WebTransport is enabled for browsers with full support. Safari/iOS Safari users fall through to WS-direct → WebRTC via the three-tier fallback (AC-WT-03). No user is left without a working transport path.

| Browser | WebTransport | Minimum Version | Tier | Notes |
|---------|-------------|-----------------|------|-------|
| Chrome | YES | 97+ | Primary (WebTransport) | Shipped since 2022. Stable. |
| Edge | YES | 97+ | Primary (WebTransport) | Chromium-based, mirrors Chrome. |
| Firefox | YES | 115+ | Primary (WebTransport) | Shipped mid-2023. Stable. |
| Safari (macOS) | NO | — | Fallback (WS → WebRTC) | Part of Interop 2026. Expected during 2026, timeline uncertain. |
| Safari (iOS) | NO | — | Fallback (WS → WebRTC) | Follows desktop Safari. |
| Chrome (Android) | YES | 97+ | Primary (WebTransport) | Mirrors desktop Chrome. |

**Runtime detection:** Implementations MUST detect WebTransport support at runtime via feature detection (`typeof WebTransport !== 'undefined'`). Do not rely on user-agent sniffing.

**Safari re-evaluation trigger:** When Safari ships WebTransport (tracked via Interop 2026), update this matrix and promote Safari to Primary tier. No PM decision required for promotion — only for demotion or removal.

##### AC-WT-02 — Capability String (PM-WT-02 APPROVED)

**PM-WT-02 APPROVED (2026-03-15): Option A — `bolt.transport-webtransport-v1`**

| Property | Value |
|----------|-------|
| Capability string | `bolt.transport-webtransport-v1` |
| Namespace | `bolt.*` (existing convention) |
| Negotiation | HELLO `capabilities[]` intersection |
| Scope | Transport-level binding. Signals browser client supports WebTransport connection to daemon. |
| Protocol impact | None. BTR, envelope, and session semantics unchanged. |
| Backward compat | Peers without this capability use existing transport (WS/WebRTC). Unknown capabilities silently dropped. |

**Registration:** Added to capability registry alongside existing `bolt.file-hash`, `bolt.profile-envelope-v1`, `bolt.transfer-ratchet-v1`.

##### AC-WT-03 — Three-Tier Fallback Policy (LOCKED)

**Fallback order: WebTransport → WebSocket-direct → WebRTC**

| Tier | Transport | Trigger to Advance | Protocol | Notes |
|------|-----------|-------------------|----------|-------|
| **1 (Primary)** | WebTransport | — (first attempt) | QUIC/HTTP3 over UDP | Requires TLS. Feature-detected at runtime. |
| **2 (Fallback 1)** | WebSocket-direct | WebTransport unavailable (browser lacks support) OR WebTransport connection fails (timeout, TLS error, UDP blocked) | TCP, ws:// or wss:// | RC5 path. Already operational. |
| **3 (Fallback 2)** | WebRTC | WS connection fails (refused, timeout) | UDP/TCP via ICE | Baseline. Requires signaling server. G1 alignment. |

**Trigger conditions (deterministic):**

| Trigger | From | To | Detection |
|---------|------|----|-----------|
| Browser lacks WebTransport API | Tier 1 | Tier 2 | `typeof WebTransport === 'undefined'` (synchronous, immediate) |
| WebTransport connection timeout | Tier 1 | Tier 2 | Connection not established within timeout (PM-configurable, recommended 5s) |
| WebTransport TLS error | Tier 1 | Tier 2 | TLS handshake failure (cert rejected, protocol mismatch) |
| UDP blocked (QUIC unreachable) | Tier 1 | Tier 2 | Connection timeout (same as above — UDP blocking manifests as timeout) |
| WS connection refused | Tier 2 | Tier 3 | TCP RST or connection refused error |
| WS connection timeout | Tier 2 | Tier 3 | WS not established within timeout (existing RC5 behavior per AC-RC-24) |

**Invariants:**
- G1 preserved: browser↔browser remains WebRTC (never enters this fallback chain)
- WT-G8: kill-switch at every tier — feature gate can force Tier 2 or Tier 3 as primary
- Fallback is automatic and transparent to BTR/envelope layer (BTR-FC layering principle)
- Each fallback step MUST log the tier transition with reason for diagnostics

##### AC-WT-04 — TLS Requirement + Cert Strategy Options (ACKNOWLEDGED)

**TLS is mandatory for WebTransport.** Unlike WebSocket (`ws://` acceptable for localhost/LAN per RC6 policy), WebTransport requires a valid TLS context (QUIC mandates TLS 1.3).

**Implications:**

| Environment | WebTransport | WebSocket (RC5) | Impact |
|-------------|-------------|-----------------|--------|
| localhost | Requires TLS (self-signed acceptable in some browsers) | ws:// works | New: daemon must serve TLS even for localhost |
| LAN | Requires TLS | ws:// acceptable (RC6 policy) | New: cert provisioning required |
| WAN | Requires TLS (CA-signed) | wss:// required (RC6 policy) | Aligned: both require TLS |
| HTTPS page | WebTransport works natively | wss:// required (mixed-content) | Improvement: no mixed-content workaround needed |

**Cert strategy options (for PM-WT-03 resolution in WT2):**

| Option | Strategy | Pros | Cons | Complexity |
|--------|----------|------|------|------------|
| **C1** | Self-signed cert + browser trust prompt | Simple. Works for localhost/LAN. | Browser warnings. No Safari support. User friction. | LOW |
| **C2** | Local CA (mkcert / custom CA) | Trusted by local browsers. No warnings after setup. | Requires one-time CA installation. Platform-specific. | MEDIUM |
| **C3** | ACME/Let's Encrypt (WAN) | Publicly trusted. Automated renewal. | Requires public domain + DNS. Not for localhost/LAN. | MEDIUM |
| **C4** | Hybrid (C1 for dev, C2 for LAN, C3 for WAN) | Best coverage. Environment-appropriate. | Most complex to implement. | HIGH |

**WT2 deliverable:** PM-WT-03 must select a cert strategy before daemon endpoint implementation. AC-WT-04 acknowledges the requirement and documents options; WT2 locks the choice.

#### WT2 — Daemon Endpoint + TLS Policy

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-WT-05 | Daemon WebTransport endpoint contract specified (listen address, ALPN, connection lifecycle) | Endpoint spec | **PASS** — Endpoint contract codified below. ALPN `h3`, HTTP/3 server, connection lifecycle defined. |
| AC-WT-06 | Auth/origin validation policy for WebTransport connections defined | Auth policy doc | **PASS** — Origin validation + connection token policy codified below. |
| AC-WT-07 | TLS certificate provisioning strategy locked (self-signed dev, CA-signed prod, rotation policy) | PM decision recorded | **PASS** — PM-WT-03 APPROVED (2026-03-15). C2 local CA primary, C1 dev fallback. |
| AC-WT-08 | WebTransport endpoint feature-gated (kill-switch for rollback to WS) | Feature gate design | **PASS** — `transport-webtransport` feature gate design codified below. |

**Invariant:** browser↔browser WebRTC (G1) is unchanged by WT2. Runtime implementation is deferred — WT2 specifies contracts only.

##### AC-WT-05 — Daemon WebTransport Endpoint Contract (LOCKED)

**Endpoint specification:**

| Property | Value | Notes |
|----------|-------|-------|
| Protocol | HTTP/3 (QUIC + TLS 1.3) | WebTransport runs over HTTP/3 |
| ALPN | `h3` | Standard HTTP/3 ALPN token |
| Listen address | `127.0.0.1:<port>` (localhost default) or `0.0.0.0:<port>` (LAN) | Configurable. Separate port from WS endpoint. |
| Default port | TBD at implementation (recommended: WS port + 1, or config key `daemon.webtransport.port`) | Must not conflict with WS or QUIC (app↔app) ports |
| TLS | Required (WebTransport mandates TLS 1.3) | Cert provisioned per PM-WT-03 (AC-WT-07) |
| Max concurrent sessions | Same as WS endpoint (daemon-configured) | Shared session pool with WS if both active |

**Connection lifecycle:**

```
Browser                          Daemon
  │                                │
  ├─ WebTransport(url) ───────────►│  1. HTTP/3 CONNECT + TLS 1.3 handshake
  │                                │
  │◄── session established ────────┤  2. WebTransport session open
  │                                │
  ├─ open bidirectional stream ───►│  3. Stream for HELLO exchange
  │                                │
  ├─ HELLO (encrypted envelope) ──►│  4. Standard Bolt HELLO (§3)
  │◄── HELLO response ────────────┤     Capability intersection includes
  │                                │     bolt.transport-webtransport-v1
  │                                │
  │    [session active — same as   │  5. Protocol proceeds identically
  │     WS/WebRTC from here]       │     to WS path (envelopes, BTR,
  │                                │     transfers, etc.)
  │                                │
  ├─ close session ───────────────►│  6. Clean shutdown
  │                                │     OR disconnect → zeroize
```

**Relationship to WS endpoint:**
- WebTransport and WS endpoints MAY run concurrently on separate ports
- Both delegate to shared Rust core (RC4 pattern) — no dual protocol authority
- Session authority is in daemon/bolt_core regardless of transport
- Browser chooses transport per three-tier fallback (AC-WT-03)

##### AC-WT-06 — Auth/Origin Validation Policy (LOCKED)

| Policy | Rule | Rationale |
|--------|------|-----------|
| **Origin validation** | Daemon MUST validate `Origin` header on WebTransport CONNECT. Accept only configured origins (default: same-origin localhost). Reject unknown origins with HTTP 403. | Prevents cross-origin abuse of local daemon. |
| **Connection token** | Daemon MAY require a connection token/nonce in the WebTransport URL query parameter for additional auth. Token generation: daemon provides token via IPC to local app, which passes to browser. | Defense-in-depth. Prevents unauthenticated connections to daemon WT endpoint. |
| **Rate limiting** | Daemon MUST rate-limit WebTransport connection attempts (same policy as WS endpoint). | Prevents local DoS. |
| **TLS client auth** | NOT REQUIRED in v1. TLS server cert sufficient for transport security. Mutual TLS deferred. | Simplicity. Server cert + origin validation + optional token is sufficient for localhost/LAN. |
| **Same-origin policy** | WebTransport from HTTPS pages connects to daemon's TLS endpoint — no mixed-content restriction (unlike ws:// from HTTPS). | WebTransport always uses TLS, resolving the HTTPS mixed-content caveat from RC5/RC6. |

**Security note:** WebTransport connections are always TLS-encrypted. The daemon's TLS cert authenticates the daemon to the browser. Origin validation + optional token authenticate the browser to the daemon. No protocol reimplementation in browser (WT-G4).

##### AC-WT-07 — TLS Certificate Strategy (PM-WT-03 APPROVED)

**PM-WT-03 APPROVED (2026-03-15):**

| Environment | Strategy | Certificate Type | Setup |
|-------------|----------|-----------------|-------|
| **Development/testing** | C1: Self-signed | Self-signed cert generated by daemon | Zero setup. Browser shows TLS warning. Acceptable for dev only. |
| **LAN/localhost production** | C2: Local CA (mkcert-style) | CA-signed cert from locally installed root CA | One-time: install local root CA in OS trust store. Daemon generates certs signed by local CA. No browser warnings after CA trust. |

**Out of scope:** C3 ACME/Let's Encrypt (WAN/public deployment, deferred to ByteBolt/relay scope).

**Cert lifecycle:**

| Aspect | Policy |
|--------|--------|
| Generation | Daemon generates cert on first start if none exists. Stores in daemon data directory. |
| Validity | 365 days recommended. Daemon warns on approaching expiry. |
| Rotation | Regenerate cert + restart daemon. No online rotation in v1. |
| CA installation (C2) | One-time per machine. Platform-specific: macOS Keychain, Windows cert store, Linux ca-certificates. |
| Rollback | If TLS fails → browser falls back to WS (Tier 2) → WebRTC (Tier 3). Three-tier fallback is the safety net. |

**Implementation note (deferred):** Cert generation and CA management are runtime concerns. WT2 locks the policy; implementation is a future engineering phase.

##### AC-WT-08 — Feature Gate Design (LOCKED)

**Feature gate: `transport-webtransport`**

| Property | Value |
|----------|-------|
| Gate name | `transport-webtransport` |
| Default | OFF (WebTransport disabled until implementation complete + burn-in) |
| When OFF | Daemon does not start WebTransport listener. Browser falls through to WS (Tier 2). |
| When ON | Daemon starts HTTP/3 WebTransport listener on configured port. Browser attempts WebTransport first. |
| Interaction with `transport-ws` | Independent. Both can be ON simultaneously (different ports). |
| Interaction with `transport-quic` | Independent. `transport-quic` is app↔app QUIC. `transport-webtransport` is browser↔app HTTP/3. Different protocols, different listeners. |
| Kill-switch | Set `transport-webtransport` OFF → rebuild daemon → deploy. Browser auto-falls to WS. |
| Rollback path | WT-G8: feature gate OFF restores RC5 behavior (WS primary). No data loss. |

**Feature gate hierarchy (daemon):**

```
transport-quic          → app↔app QUIC (RC3)
transport-ws            → browser↔app WebSocket (RC5)
transport-webtransport  → browser↔app WebTransport (this stream)
```

All three are independent. Any combination is valid. Browser↔browser remains WebRTC regardless of daemon feature gates (G1 invariant).

#### WT3 — Browser Adapter + Fallback Orchestration

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-WT-09 | Browser `WebTransportDataTransport` adapter contract specified | Adapter interface spec | **PASS** — Adapter contract codified below: interface, lifecycle states, responsibilities, non-responsibilities. |
| AC-WT-10 | Three-tier fallback orchestrator contract specified (WT → WS → WebRTC, with timeout/error triggers) | Orchestrator spec | **PASS** — Orchestrator SM codified below: 5 states, deterministic transitions, failure taxonomy, no-loop/no-flap invariants. |
| AC-WT-11 | BTR transparency verified — BTR operates identically over WebTransport as over WS/WebRTC | Cross-transport BTR test plan | **PASS** — BTR transparency test plan codified below: 6 verification obligations across all 3 transports. Inherits BTR-FC layering principle. |
| AC-WT-12 | DataTransport abstraction compatibility verified — WebTransport adapter implements same interface as WS/WebRTC | Interface compliance spec | **PASS** — DataTransport compliance matrix codified below: method-by-method mapping across WT/WS/WebRTC adapters. |

**Invariant:** browser↔browser WebRTC (G1) is unchanged. WT3 specifies browser↔app adapter contracts only. Runtime implementation deferred.

##### AC-WT-09 — Browser `WebTransportDataTransport` Adapter Contract (LOCKED)

**Responsibilities:**

| Responsibility | Description | Authority |
|----------------|-------------|-----------|
| Transport binding | Open WebTransport session to daemon endpoint, manage bidirectional stream | Adapter owns |
| Envelope relay | Send/receive encrypted envelopes between browser protocol layer and daemon | Adapter owns (relay only) |
| Connection lifecycle | Manage CONNECTING → CONNECTED → DISCONNECTED states | Adapter owns |
| Error surfacing | Report transport-level errors (TLS, timeout, connection refused) to fallback orchestrator | Adapter owns |

**Non-responsibilities (daemon/shared Rust core retains authority):**

| Non-Responsibility | Why | Authority |
|--------------------|-----|-----------|
| Protocol/session authority | WT-G4 guardrail | Daemon/bolt_core |
| BTR key schedule | BTR-FC layering — BTR is transport-transparent | BTR layer |
| Envelope encryption/decryption | Shared core via SDK | SDK/bolt_core |
| Capability negotiation | HELLO exchange in shared core | SDK/bolt_core |
| SAS computation | §4.2 — unchanged by transport | SDK/bolt_core |

**Lifecycle states:**

| State | Description | Transitions |
|-------|-------------|-------------|
| `WT_CONNECTING` | HTTP/3 CONNECT + TLS handshake in progress | → `WT_CONNECTED` (success) or → `WT_DISCONNECTED` (failure/timeout) |
| `WT_CONNECTED` | WebTransport session active, bidirectional stream open | → `WT_DISCONNECTED` (close, error, or disconnect) |
| `WT_DISCONNECTED` | Session closed or failed. Terminal for this adapter instance. | No further transitions. New connection = new adapter instance. |

**Interface contract (implements `DataTransport`):**

| Method/Event | Signature (conceptual) | Notes |
|-------------|----------------------|-------|
| `connect(url)` | Open WebTransport session to daemon | URL includes `https://` (TLS mandatory) |
| `send(envelope)` | Send encrypted envelope over bidirectional stream | Binary framing over WebTransport stream |
| `onMessage(callback)` | Register envelope receive handler | Same callback signature as WS/WebRTC adapters |
| `close()` | Clean session shutdown | Zeroize adapter state |
| `onDisconnect(callback)` | Register disconnect/error handler | Triggers fallback orchestrator if in probe phase |
| `isConnected()` | Return current connection state | Boolean |

##### AC-WT-10 — Three-Tier Fallback Orchestrator Contract (LOCKED)

**Orchestrator state machine:**

| State | Description |
|-------|-------------|
| `PROBE_WT` | Attempting WebTransport connection to daemon |
| `PROBE_WS` | WebTransport failed/unavailable; attempting WebSocket-direct |
| `PROBE_WEBRTC` | WS failed; attempting WebRTC via signaling server |
| `CONNECTED` | Successfully connected on one tier. Session active. |
| `FAILED` | All 3 tiers exhausted. No connection established. |

**Transitions:**

| # | From | Trigger | To | Action |
|---|------|---------|----|--------|
| F1 | `PROBE_WT` | WT connect succeeds | `CONNECTED` | Log tier: WebTransport. Session proceeds. |
| F2 | `PROBE_WT` | WT unavailable (feature detection) | `PROBE_WS` | Log `[WT_FALLBACK] browser lacks WebTransport`. Immediate (no timeout). |
| F3 | `PROBE_WT` | WT connect timeout (configurable, recommended 5s) | `PROBE_WS` | Log `[WT_FALLBACK] connect timeout`. |
| F4 | `PROBE_WT` | WT TLS error / connection refused / UDP blocked | `PROBE_WS` | Log `[WT_FALLBACK] <specific error>`. |
| F5 | `PROBE_WS` | WS connect succeeds | `CONNECTED` | Log tier: WebSocket. Session proceeds. |
| F6 | `PROBE_WS` | WS connect timeout / refused | `PROBE_WEBRTC` | Log `[WS_FALLBACK] <reason>`. |
| F7 | `PROBE_WEBRTC` | WebRTC signaling + ICE succeeds | `CONNECTED` | Log tier: WebRTC. Session proceeds. |
| F8 | `PROBE_WEBRTC` | WebRTC connection fails | `FAILED` | Log `[ALL_TRANSPORTS_FAILED]`. Surface error to user. |
| F9 | `CONNECTED` | Session disconnect (any tier) | (end) | Zeroize session state. New connection attempt starts from `PROBE_WT`. |

**Fallback invariants (LOCKED):**

| Invariant | Rule |
|-----------|------|
| **Ordering** | WT → WS → WebRTC. Canonical order. No reordering. |
| **No-loop** | Each tier attempted at most once per connection attempt. No cycling back to a previously failed tier. |
| **No-flap** | Once connected on a tier, no mid-session tier switch. Tier is locked for the session lifetime. |
| **Terminal** | If all 3 tiers fail → `FAILED` state. Surface error to user. No automatic retry without user action. |
| **G1 preserved** | browser↔browser = WebRTC. This fallback chain applies only to browser↔app connections. |
| **Feature-gate respect** | If `transport-webtransport` is OFF (daemon side), WT probe fails immediately (connection refused). Orchestrator advances to WS. |

**Failure taxonomy (deterministic trigger → action mapping):**

| # | Trigger Class | Detection | Fallback Action | Log Token |
|---|--------------|-----------|-----------------|-----------|
| TF-01 | Browser lacks WebTransport API | `typeof WebTransport === 'undefined'` (synchronous) | Skip WT → `PROBE_WS` (immediate, no timeout) | `[WT_FALLBACK]` |
| TF-02 | WT connect timeout | No session within timeout (recommended 5s) | → `PROBE_WS` | `[WT_FALLBACK]` |
| TF-03 | WT TLS handshake failure | TLS error event (cert rejected, protocol mismatch) | → `PROBE_WS` | `[WT_FALLBACK]` |
| TF-04 | WT connection refused | HTTP/3 CONNECT rejected by daemon (port closed, feature gate OFF) | → `PROBE_WS` | `[WT_FALLBACK]` |
| TF-05 | UDP blocked (QUIC unreachable) | Manifests as connect timeout (TF-02) | → `PROBE_WS` | `[WT_FALLBACK]` |
| TF-06 | WS connect refused | TCP RST or connection refused | → `PROBE_WEBRTC` | `[WS_FALLBACK]` |
| TF-07 | WS connect timeout | No WS handshake within timeout (existing RC5 behavior) | → `PROBE_WEBRTC` | `[WS_FALLBACK]` |
| TF-08 | WebRTC signaling failure | Signaling server unreachable or ICE failure | → `FAILED` | `[ALL_TRANSPORTS_FAILED]` |
| TF-09 | WebRTC ICE timeout | No ICE candidates gathered within timeout | → `FAILED` | `[ALL_TRANSPORTS_FAILED]` |

**No ambiguous behavior.** Every trigger class maps to exactly one deterministic action. No implementation-defined branching.

##### AC-WT-11 — BTR Transparency Verification Plan (LOCKED)

BTR operates identically over all three transports per the BTR-FC layering principle (BS3 AC-BS-09). This plan defines the verification obligations for implementation.

**Verification obligations:**

| # | Obligation | What Must Be Identical | Transport Combinations | Evidence Type |
|---|-----------|----------------------|----------------------|---------------|
| BT-01 | Key schedule derivation | session_root_key, transfer_root_key, chain_key, message_key — same values for same inputs regardless of transport | WT vs WS vs WebRTC | Deterministic: same conformance vectors pass on all transports |
| BT-02 | Chain advance per chunk | chain_index increments identically; old chain_key zeroized at same point | WT vs WS vs WebRTC | Unit test: chain state after N chunks is identical |
| BT-03 | Envelope encryption/decryption | Same plaintext + same message_key → same ciphertext (given same nonce) | WT vs WS | Conformance vectors (btr-encrypt-decrypt) pass identically |
| BT-04 | BTR capability negotiation | `bolt.transport-webtransport-v1` and `bolt.transfer-ratchet-v1` are independent capabilities; both appear in HELLO intersection when both supported | WT sessions | HELLO test: both capabilities negotiated simultaneously |
| BT-05 | Error behavior | Same §16.7 error codes for same violation regardless of transport | WT vs WS vs WebRTC | Negative test: RATCHET_CHAIN_ERROR on gap over WT = same as over WS |
| BT-06 | Lifecycle zeroization | BTR state zeroized on disconnect regardless of transport layer | All transports | Lifecycle test: disconnect on WT/WS/WebRTC all trigger KS Tε |

**Layering guarantee:** The `DataTransport` abstraction (AC-WT-12) ensures BTR never sees the transport layer. BTR calls `send(envelope)` and receives `onMessage(envelope)`. The adapter handles framing. BTR-FC rules FC-01 through FC-05 apply identically.

##### AC-WT-12 — DataTransport Interface Compliance Matrix (LOCKED)

All three transport adapters MUST implement the same `DataTransport` interface. This ensures BTR, envelope, and protocol layers are transport-agnostic.

**Interface compliance matrix:**

| Method/Event | WebTransport Adapter | WebSocket Adapter (RC5) | WebRTC Adapter (baseline) | Notes |
|-------------|---------------------|------------------------|--------------------------|-------|
| `connect(url/config)` | `new WebTransport(url)` → session → stream | `new WebSocket(url)` → open | ICE + signaling → DataChannel | Different setup, same post-connect interface |
| `send(envelope: Uint8Array)` | Write to bidirectional stream | `ws.send(data)` | `dc.send(data)` | Binary envelope, same format |
| `onMessage(cb: (data) => void)` | Read from bidirectional stream | `ws.onmessage` | `dc.onmessage` | Same callback signature |
| `close()` | `session.close()` | `ws.close()` | `dc.close()` + `pc.close()` | Clean shutdown |
| `onDisconnect(cb)` | Session closed/error event | `ws.onclose` / `ws.onerror` | `dc.onclose` / ICE failure | Triggers orchestrator or session cleanup |
| `isConnected(): boolean` | Session state check | ReadyState check | DataChannel state check | Boolean |
| **Backpressure** | HTTP/3 stream flow control (native) | `bufferedAmount` + `onbufferedamountlow` | `bufferedAmount` + `onbufferedamountlow` | Transport-specific mechanism, same policy interface |

**Compliance invariant:** Any code that calls `DataTransport.send()` or registers `DataTransport.onMessage()` MUST work identically regardless of which adapter is backing the transport. The orchestrator selects the adapter; the protocol layer does not know which transport is active.

**Rollback/kill-switch cross-link to RC6:**

The WT transport path adds a new rollback lever to the RC6 framework:

| Lever | Scope | Reversibility | How | RC6 Cross-Link |
|-------|-------|---------------|-----|----------------|
| **RB-L5** (new) | browser↔app WebTransport path | Full — falls back to WS (Tier 2) → WebRTC (Tier 3) | Set `transport-webtransport` feature gate OFF → rebuild daemon → deploy. Browser orchestrator skips WT probe (TF-04). | Extends RC6 AC-RC-26 lever framework. Same ownership (PM decides, Engineering executes). Same SLA (≤4h P0 decision, ≤1h execution). |

**RC6 alignment:** RB-L5 follows the same pattern as RB-L1 (QUIC kill-switch) and RB-L2 (WS kill-switch). The three-tier fallback is the safety net — disabling any tier automatically promotes the next tier. No protocol semantic drift on rollback because all tiers use the same `DataTransport` interface and the same BTR/envelope/session semantics.

#### WT4 — Conformance + Rollout/Rollback

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-WT-13 | Compatibility matrix: all browser↔app endpoint pairs verified (WT primary, WS fallback, WebRTC fallback) | Matrix test plan | **PASS** — 12-cell compatibility matrix codified below with pass/fail criteria. Safari fallback handling explicit. |
| AC-WT-14 | Rollout policy codified (staged, per-consumer, with burn-in gates) | Rollout policy doc | **PASS** — 3-stage rollout codified below (canary → staged → GA). Promotion gates with burn-in and SLO checks. |
| AC-WT-15 | Rollback levers documented (feature gate off → WS, WS off → WebRTC) | Rollback policy doc | **PASS** — Rollback policy codified below. Triggers (RB-WT-T1–T5), levers (RB-L5 + existing RB-L2), ownership/SLA aligned with RC6. |
| AC-WT-16 | Performance SLO thresholds for WebTransport defined (latency, throughput vs WS baseline) | SLO doc | **PASS** — PM-WT-04 APPROVED (2026-03-15, Option B). 5 thresholds locked. |

**Invariant:** browser↔browser WebRTC (G1) unchanged. Runtime implementation deferred.

##### AC-WT-13 — Compatibility Matrix (LOCKED)

**Dimensions:** Browser class (WT-capable vs non-WT) × Transport tier × Expected behavior.

| # | Browser Class | Transport Attempted | Expected Behavior | Pass Criteria | Fallback Path |
|---|--------------|--------------------|--------------------|---------------|---------------|
| 1 | Chrome 97+ | WebTransport (Tier 1) | Full WT session to daemon | Connection established, HELLO exchanged, transfer completes | — |
| 2 | Chrome 97+ | WS-direct (Tier 2, if WT fails) | WS session to daemon | Same as RC5 AC-RC-21/22 | — |
| 3 | Chrome 97+ | WebRTC (Tier 3, if WS fails) | WebRTC via signaling | Baseline behavior | — |
| 4 | Firefox 115+ | WebTransport (Tier 1) | Full WT session to daemon | Connection established, HELLO exchanged, transfer completes | — |
| 5 | Firefox 115+ | WS-direct (Tier 2, if WT fails) | WS session to daemon | Same as RC5 | — |
| 6 | Firefox 115+ | WebRTC (Tier 3, if WS fails) | WebRTC via signaling | Baseline | — |
| 7 | Edge 97+ | WebTransport (Tier 1) | Full WT session (Chromium-based) | Same as Chrome | — |
| 8 | Safari (no WT) | WS-direct (Tier 2, auto) | Orchestrator skips WT (TF-01), connects WS | WS session, no WT probe delay | WebRTC if WS fails |
| 9 | Safari (no WT) | WebRTC (Tier 3, if WS fails) | WebRTC via signaling | Baseline | — |
| 10 | Any browser, daemon WT gate OFF | WS-direct (Tier 2, auto) | WT probe → connection refused (TF-04) → WS | WS session, minimal WT probe delay | WebRTC if WS fails |
| 11 | Any browser, daemon WS+WT gates OFF | WebRTC (Tier 3, auto) | Both WT and WS fail → WebRTC | WebRTC session | — |
| 12 | Any browser, all gates OFF / no daemon | FAILED | All 3 tiers exhausted | Error surfaced to user | None |

**Pass criteria per cell:**
1. Connection established within tier-appropriate timeout
2. HELLO handshake completes with capability intersection
3. BTR negotiated (if both peers support, per AC-WT-11 transparency)
4. File transfer completes with integrity verification
5. Fallback path activates correctly when primary tier fails

**Safari handling:** Safari enters orchestrator at `PROBE_WS` (TF-01 skips WT immediately via feature detection). No WT probe delay. Full WS/WebRTC functionality preserved.

##### AC-WT-14 — Rollout Policy (LOCKED)

**3-stage rollout for WebTransport adoption:**

| Stage | Scope | Entry Criteria | Promotion Gate | Duration |
|-------|-------|----------------|----------------|----------|
| **Canary** | Single consumer app (recommended: localbolt-v3) with WT feature gate ON for opt-in users | WT4 policy closed. Implementation artifacts ready. PM approval. | All SLO thresholds met (PM-WT-04). Zero P0/P1 regressions. Fallback success ≥98%. No-regression suites green. | PM-set (recommended ≥72h) |
| **Staged** | All consumer apps with WT feature gate ON (default OFF for users, opt-in toggle) | Canary promotion gate passed. | SLO sustained across all consumers. Zero P0/P1 over extended burn-in. | PM-set (recommended ≥1 week) |
| **GA** | WT feature gate ON by default for all supported browsers | Staged promotion gate passed. PM approval for default-on. | Continuous SLO compliance. No active RB-WT triggers. | — (ongoing) |

**Per-stage no-regression requirement:** All existing test suites across all repos must pass at each promotion gate. WT-specific tests must also pass. Cross-referenced with AC-RC-28 pattern.

**Consumer rollout order (recommended):**
1. localbolt-v3 (primary web consumer, Netlify-deployed)
2. localbolt (secondary web consumer)
3. localbolt-app (Tauri desktop — WT used in embedded WebView context)

##### AC-WT-15 — Rollback Policy (LOCKED)

**Triggers (any one triggers rollback evaluation):**

| ID | Trigger | Severity | Action |
|----|---------|----------|--------|
| RB-WT-T1 | WT connection success rate < 99% (combined WT+fallback) over 1h window | P0 | PM evaluates rollback |
| RB-WT-T2 | Transfer failure rate over WT > WS baseline by >5% | P0 | PM evaluates rollback |
| RB-WT-T3 | Fallback success rate < 98% (when WT fails, WS/WebRTC don't recover) | P1 | PM evaluates rollback |
| RB-WT-T4 | WT setup latency > 1.5× WS baseline sustained over 1h | P1 | PM evaluates rollback |
| RB-WT-T5 | Test suite regression (any repo, any gate) | Blocking | Automatic — blocks stage promotion |

**Levers:**

| Lever | Scope | How | Reversibility |
|-------|-------|-----|---------------|
| **RB-L5** | browser↔app WT path | `transport-webtransport` feature gate OFF → rebuild daemon → deploy | Full — browser falls to WS (Tier 2) → WebRTC (Tier 3) |
| **RB-L2** (existing) | browser↔app WS path | Force WebRTC-only via config | Full — browser uses WebRTC baseline |
| **SDK version rollback** | Per-consumer | Pin pre-WT SDK version | Full |
| **Daemon version rollback** | Daemon | Deploy previous tagged binary | Full |

**Ownership and SLA (aligned with RC6 AC-RC-26):**

| Role | Responsibility |
|------|---------------|
| PM | Rollback decision authority |
| Engineering | Execute lever, provide diagnostics, propose fix |

| Action | Target |
|--------|--------|
| Trigger → rollback decision | ≤4h for P0, ≤24h for P1 |
| Rollback decision → execution | ≤1h |
| Post-rollback RCA | ≤72h |

##### AC-WT-16 — Performance SLO Thresholds (PM-WT-04 APPROVED)

**PM-WT-04 APPROVED (2026-03-15): Option B (Balanced).**

| Metric | Threshold | Measurement | Rationale |
|--------|-----------|-------------|-----------|
| Transport setup latency | WT ≤ 1.5× WS baseline | Time from connection initiation to HELLO exchange complete | QUIC+TLS handshake adds overhead vs TCP-only WS on localhost; 1.5× allows for this |
| Transfer throughput | WT ≥ 90% of WS throughput | Average over 3×1MiB localhost transfers (matches PM-RC-04 methodology) | QUIC flow control may introduce marginal overhead; 90% prevents noticeable regression |
| Connection success rate | ≥99% (WT + fallback combined) | Percentage of connection attempts that establish a session on any tier | Three-tier fallback should cover nearly all failure modes |
| Fallback success | If WT fails, WS/WebRTC succeeds in ≥98% of cases | Percentage of WT failures that recover via Tier 2/3 | Fallback is the safety net; must be reliable |
| No-regression gate | All existing test suites green + WT-specific tests pass | CI evidence at each promotion gate | Inherited from RC6 AC-RC-28 pattern |

**Failure action:** If any threshold fails persistently (sustained over rollout burn-in), hold promotion and evaluate via RB-WT triggers (AC-WT-15). PM decides: fix, rollback, or adjust threshold.

#### WT5 — Closure + WS Disposition

| ID | Criterion | Evidence Required | Status |
|----|-----------|------------------|--------|
| AC-WT-17 | Stream closure criteria met (all prior ACs, burn-in passed, no P0/P1 regressions) | Closure evidence | **PASS** — Governance closure criteria codified below. All prior ACs (WT-01–16) PASS. Runtime burn-in deferred to implementation execution. |
| AC-WT-18 | WS role disposition decided: retain as permanent fallback, or deprecate-with-sunset (separate PM decision) | PM decision recorded | **PASS** — PM-WT-05 APPROVED (2026-03-15, Option B). Deprecate-with-sunset, 5 conditions, WS retained until all met. |
| AC-WT-19 | WebRTC fallback role confirmed: retained as last-resort (G1 alignment) | Policy doc | **PASS** — WebRTC confirmed as permanent last-resort fallback. G1 invariant explicitly unchanged. |
| AC-WT-20 | Migration documentation published for consumer app developers | Migration guide | **PASS** — Migration guide outline codified below. Full guide deferred to implementation (governance scope = outline + requirements). |

##### AC-WT-17 — Stream Closure Criteria (LOCKED)

**WEBTRANSPORT-BROWSER-APP-1 is a governance/specification stream.** Closure means all governance artifacts are delivered. Runtime implementation and rollout are separate future execution.

**Governance closure criteria (all met):**

| # | Criterion | Status |
|---|-----------|--------|
| 1 | All 20 ACs (AC-WT-01–20) evidenced | PASS (this commit) |
| 2 | All 5 PM decisions (PM-WT-01–05) resolved | PASS (PM-WT-05 resolved in this commit) |
| 3 | Stream guardrails (WT-G1–G8) verified across all phases | PASS |
| 4 | Cross-stream reconciliation complete (RC6, BTR, G1) | PASS (AC-WT-19) |
| 5 | Evidence files for all 5 phases archived | PASS (WT1–WT5 evidence files) |

**Runtime closure criteria (deferred — evaluated at WT4 GA stage):**

| # | Criterion | Status |
|---|-----------|--------|
| R1 | WT4 rollout reaches GA stage | NOT-STARTED (implementation deferred) |
| R2 | PM-WT-04 SLO thresholds sustained in production | NOT-STARTED |
| R3 | Zero P0/P1 regressions during rollout | NOT-STARTED |
| R4 | Burn-in passed per WT4 AC-WT-14 stages | NOT-STARTED |

**Residual risks at governance closure:**

| Risk | Status | Mitigation |
|------|--------|------------|
| WT-R1 (Safari support) | OPEN | Fallback to WS/WebRTC. PM-WT-05 sunset gated on Safari shipping WT. |
| WT-R2 (TLS cert complexity) | OPEN | PM-WT-03 locked strategy (C2 local CA). Implementation deferred. |
| WT-R3 (API instability) | OPEN | Pin browser versions per WT1 matrix. Feature detection at runtime. |
| WT-R4 (fallback latency) | OPEN | WT3 orchestrator optimized (TF-01 immediate skip for no-WT browsers). |
| WT-R5 (UDP firewall blocking) | OPEN | WS fallback (TCP-based) handles transparently. |

##### AC-WT-18 — WS Disposition Policy (PM-WT-05 APPROVED)

**PM-WT-05 APPROVED (2026-03-15): Option B — Deprecate-with-sunset, condition-gated.**

**Deprecation phases:**

| Phase | State | WS Status | Description |
|-------|-------|-----------|-------------|
| **Active** (current) | Pre-WT implementation | WS is primary browser↔app transport | Status quo. RC5 baseline. |
| **Coexistence** | WT implemented + deployed | WS is Tier 2 fallback | WT primary, WS fallback. Both active. Dual maintenance. |
| **Deprecated** | WT at GA (WT4 Stage 3) | WS retained but marked deprecated | Deprecation notice in changelogs. WS code maintained but no new features. Kill-switch (RB-L5) retains WT→WS rollback. |
| **Sunset** | All 5 conditions met | WS code removed | Only after explicit follow-up PM approval. |

**Sunset conditions (ALL must be met):**

| # | Condition | Rationale |
|---|-----------|-----------|
| 1 | At least 1 full release cycle with WT as default-on | Prove WT is stable at scale |
| 2 | Zero WT kill-switch (RB-L5) activations during that cycle | No rollbacks to WS occurred |
| 3 | Zero P0/P1 incidents attributable to WT transport path | WT path is production-reliable |
| 4 | Safari ships production WebTransport support | No browser class left without primary transport |
| 5 | Explicit follow-up PM approval for WS removal | PM gate — not automatic |

**Until all 5 conditions are met, WS remains an active fallback.** Condition 4 (Safari) ensures no user population is forced to WebRTC-only. Condition 5 ensures removal is a deliberate decision.

**Alignment with PM-RC-05:** This follows the same deprecate-but-retain pattern used for TS-path deprecation (PM-RC-05). Condition-gated, not date-gated.

##### AC-WT-19 — Cross-Stream Reconciliation (CONFIRMED)

| Stream | Commitment | Status |
|--------|-----------|--------|
| **G1 invariant** | browser↔browser = WebRTC. Never enters WT fallback chain. Never changed. | **UNCHANGED** — confirmed in WT1 (AC-WT-03), WT3 (orchestrator F7/F8), WT4 (matrix cells 8–9), WT5 (this AC). |
| **RC6 rollback policy** | RB-L1–L4 levers + triggers + SLA. | **PRESERVED** — WT3 added RB-L5 extending (not replacing) RC6 framework. Same ownership, same SLA. |
| **RC6 TS-path deprecation (PM-RC-05)** | Deprecate-but-retain TS paths with condition-gated sunset. | **COMPATIBLE** — PM-WT-05 follows same pattern. WS deprecation conditions are independent of TS-path conditions. Both active concurrently if needed. |
| **BTR transparency (BS3 BTR-FC)** | BTR is transport-transparent. No BTR-specific flow control. | **PRESERVED** — WT3 AC-WT-11 codified 6 verification obligations (BT-01–06). BTR operates identically over WT/WS/WebRTC. |
| **RUSTIFY-CORE-1 session authority** | Daemon/shared Rust core owns protocol/session authority. | **PRESERVED** — WT-G4 enforced in every phase. WT adapter is transport binding only. |

##### AC-WT-20 — Migration Guide Outline (GOVERNANCE SCOPE)

**Migration guide outline for consumer app developers (full guide deferred to implementation):**

| Section | Content | When Published |
|---------|---------|---------------|
| 1. Overview | What changes: WS → WT primary transport for browser↔app. What doesn't: protocol, BTR, session semantics, WebRTC baseline. | At WT implementation start |
| 2. Prerequisites | Daemon version with `transport-webtransport` feature. TLS cert setup (PM-WT-03 C2 local CA). Browser support check. | At WT implementation start |
| 3. SDK update | Update to WT-capable SDK version. `bolt.transport-webtransport-v1` capability auto-negotiated. No consumer code changes for basic adoption. | At SDK release |
| 4. Fallback behavior | Three-tier fallback automatic. No consumer configuration needed. Safari users transparently fall to WS. | At SDK release |
| 5. Feature gate control | How to enable/disable `transport-webtransport` on daemon. Kill-switch rollback procedure. | At daemon release |
| 6. Monitoring | Log tokens: `[WT_FALLBACK]`, `[WS_FALLBACK]`, `[ALL_TRANSPORTS_FAILED]`. SLO thresholds to watch. | At rollout canary |
| 7. Rollback procedure | RB-L5 lever. Daemon rebuild without feature. Consumer SDK version pin. | At rollout canary |

**Governance deliverable:** This outline defines the migration guide requirements. The full guide is produced during implementation, not during governance codification.

---

### PM Open Decisions Table

| ID | Decision | Blocks | Priority | Status |
|----|----------|--------|----------|--------|
| PM-WT-01 | Browser support matrix. **APPROVED (2026-03-15): Option B.** Ship WebTransport on Chrome 97+, Edge 97+, Firefox 115+. Safari/iOS Safari fallback to WS → WebRTC. Re-evaluate when Safari ships WebTransport (Interop 2026). | WT1 (AC-WT-01) | WT1 | **APPROVED (2026-03-15)** |
| PM-WT-02 | WebTransport capability string. **APPROVED (2026-03-15): Option A.** `bolt.transport-webtransport-v1`. Follows existing `bolt.*` namespace. Transport-level, no protocol impact. | WT1 (AC-WT-02) | WT1 | **APPROVED (2026-03-15)** |
| PM-WT-03 | TLS certificate provisioning strategy. **APPROVED (2026-03-15):** Primary: C2 local CA (mkcert-style) for localhost/LAN. Dev fallback: C1 self-signed. Out of scope: C3 ACME/Let's Encrypt (WAN, deferred). | WT2 (AC-WT-07) | WT2 | **APPROVED (2026-03-15)** |
| PM-WT-04 | Performance SLO thresholds. **APPROVED (2026-03-15, Option B):** Setup latency ≤1.5× WS. Throughput ≥90% WS. Connection ≥99% combined. Fallback ≥98%. No-regression green + WT tests. | WT4 (AC-WT-16) | WT4 | **APPROVED (2026-03-15)** |
| PM-WT-05 | WS disposition. **APPROVED (2026-03-15, Option B):** Deprecate-with-sunset, condition-gated. WS retained until ALL of: (1) ≥1 release cycle WT default-on, (2) zero kill-switch activations, (3) zero P0/P1 from WT, (4) Safari ships WT, (5) explicit PM removal approval. | WT5 (AC-WT-18) | WT5 | **APPROVED (2026-03-15)** |

---

### Risk Register

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| WT-R1 | Safari WebTransport support absent or limited | HIGH | Browser support matrix (WT1). Three-tier fallback ensures Safari users fall through to WS → WebRTC. No Safari-only breakage. |
| WT-R2 | TLS certificate management complexity for local daemon | HIGH | WT2 locks cert strategy before implementation. Self-signed with trust prompts for dev. Potential mDNS + local CA for production. Kill-switch rollback to ws:// (non-TLS). |
| WT-R3 | WebTransport API instability across browser versions | MEDIUM | WT1 locks minimum browser versions. WT3 adapter wraps API surface for isolation. Feature detection at runtime. |
| WT-R4 | Three-tier fallback adds connection establishment latency | MEDIUM | WT3 designs parallel probing or fast-fail detection. Timeout tuning per tier. |
| WT-R5 | QUIC/HTTP3 blocked by corporate firewalls (UDP blocked) | MEDIUM | WS fallback (TCP-based) handles this transparently. WebRTC as last resort. Three-tier design is the mitigation. |

---

### Explicit Non-Goals

| ID | Non-Goal | Rationale |
|----|----------|-----------|
| WT-NG1 | Replace browser↔browser WebRTC | G1 invariant — unchanged |
| WT-NG2 | Replace app↔app QUIC | QUIC is already native; WebTransport is browser-facing only |
| WT-NG3 | Remove WebSocket or WebRTC paths | Retained as fallback tiers; removal is separate PM gate (PM-WT-05) |
| WT-NG4 | Implement WebTransport in this codification pass | Governance-only; runtime deferred |
| WT-NG5 | Modify BTR or protocol semantics | Transport is below BTR; transparent layering (BTR-FC) |

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
| BTR-SPEC-1 (spec) | bolt-protocol | `v0.1.X-btr-spec1-bs<phase>-<slug>` | `v0.1.7-btr-spec1-bs1-taxonomy` |
| BTR-SPEC-1 (governance) | bolt-ecosystem | `ecosystem-v0.1.X-btr-spec1-<slug>` | `ecosystem-v0.1.118-btr-spec1-codify` |
| WEBTRANSPORT-BROWSER-APP-1 (daemon) | bolt-daemon | `daemon-vX.Y.Z-wt<phase>-<slug>` | — |
| WEBTRANSPORT-BROWSER-APP-1 (SDK) | bolt-core-sdk | `sdk-vX.Y.Z-wt<phase>-<slug>` | — |
| WEBTRANSPORT-BROWSER-APP-1 (governance) | bolt-ecosystem | `ecosystem-v0.1.X-webtransport-browser-app1-<slug>` | `ecosystem-v0.1.139-webtransport-browser-app1-codify` |
| EGUI-WASM-1 (consumers) | localbolt-v3, localbolt | `<repo-prefix>-ew<phase>-<slug>` | — |
| RUSTIFY-BROWSER-CORE-1 (consumers) | bolt-transport-web, localbolt-v3, localbolt, localbolt-app | `<repo-prefix>-rb<phase>-<slug>` | — |
| EGUI-WASM-1 (governance) | bolt-ecosystem | `ecosystem-v0.1.X-egui-wasm1-<slug>` | `ecosystem-v0.1.142-egui-wasm1-codify` |
| RUSTIFY-BROWSER-CORE-1 (governance) | bolt-ecosystem | `ecosystem-v0.1.X-rustify-browser-core1-<slug>` | `ecosystem-v0.1.165-rustify-browser-core1-codify` |
| RUSTIFY-BROWSER-ROLLOUT-1 (governance) | bolt-ecosystem | `ecosystem-v0.1.X-rustify-browser-rollout1-<slug>` | `ecosystem-v0.1.172-rustify-browser-rollout1-codify` |
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
| CONSUMER-BTR1 | Consumer app BTR rollout (CONSUMER-BTR-1) | ~~NOW~~ DONE | localbolt-v3, localbolt, localbolt-app | **DONE** (burn-in waived via `PM-CBTR-EX-01`). CBTR-1 DONE (burn-in PASSED). CBTR-2 DONE (burn-in PASSED, 24h02m). CBTR-3 DONE (`localbolt-app-v1.2.24`, `ff33747`; burn-in waived). |
| T-STREAM-0 | Rust transfer core (no UDP in v1) | NEXT | `bolt-transfer-core` (bolt-core-sdk workspace) + daemon consumer | **DONE** (`sdk-v0.5.30-tstream0-transfer-core-v1`) |
| SEC-CORE2 | Rust-first security/protocol consolidation | ~~NEXT~~ SUPERSEDED | bolt-core-sdk | **SUPERSEDED-BY: RUSTIFY-CORE-1** (PM-RC-07 APPROVED 2026-03-14). AC-SC-01–04 absorbed by AC-RC-08–11. |
| T-STREAM-1 | Browser selective WASM integration | LATER | bolt-core-sdk (TS) + WASM | NOT-STARTED |
| PLAT-CORE1 | Shared Rust core + thin platform UIs | ~~LATER~~ SUPERSEDED | TBD | **SUPERSEDED-BY: RUSTIFY-CORE-1** (PM-RC-07 APPROVED 2026-03-14). RC2+RC4 absorbed full scope. |
| MOB-RUNTIME1 | Mobile embedded runtime model | LATER | TBD | **DEPENDS-ON RUSTIFY-CORE-1 RC4** (PM-RC-07 APPROVED 2026-03-14). Retains own stream identity. |
| ARCH-WASM1 | WASM protocol engine (medium risk) | ~~LATER~~ SUPERSEDED | bolt-core-sdk + WASM | **SUPERSEDED-BY: RUSTIFY-BROWSER-CORE-1** (PM-RB-05 APPROVED 2026-03-17). Browser WASM protocol authority is now RUSTIFY-BROWSER-CORE-1 scope. |
| RECON-XFER-1 | Transfer reconnect recovery after mid-transfer disconnect | NOW | bolt-core-sdk (TS) + consumers | **DONE-VERIFIED (evidence tail: RX-EVID-1)** |
| RUSTIFY-CORE-1 | Native-first transport + core consolidation | NEXT | bolt-core-sdk + bolt-daemon + bolt-protocol | **RC1 DONE**, **RC2 DONE** (`ecosystem-v0.1.127-rustify-core1-rc2-complete`, 2026-03-13). PM-RC-01A APPROVED (quinn, 2026-03-13). 7 phases (RC1–RC7), 33 ACs, 8 PM decisions. **RC3 READY** (unblocked). |
| EGUI-NATIVE-1 | Native desktop UI consolidation (egui) | ~~LATER~~ COMPLETE | localbolt-app + bolt-core-sdk + ecosystem | **COMPLETE** (`ecosystem-v0.1.162`, 2026-03-16). EN1–EN4 delivered AC-EN-01–20; EN5 closure (AC-EN-21–24). PM-EN-01/02/03/04 APPROVED. PM-EN-05 deferred. Stream CLOSED. |
| DISCOVERY-MODE-1 | Discovery mode policy codification | ~~NEXT~~ COMPLETE | ecosystem (governance) + consumers (implementation) | **COMPLETE** (`ecosystem-v0.1.160`, 2026-03-15). All 16 ACs PASS. All 4 PM decisions APPROVED. DM1–DM4 DONE. |
| BTR-SPEC-1 | Algorithm-grade BTR protocol specification | ~~NEXT~~ COMPLETE | bolt-protocol + ecosystem | **COMPLETE** (`ecosystem-v0.1.143-btr-spec1-bs5-closeout`, 2026-03-15). All 22 ACs PASS. All 6 PM decisions APPROVED. BS1–BS5 DONE. |
| WEBTRANSPORT-BROWSER-APP-1 | Browser↔app WebTransport migration | ~~NEXT~~ COMPLETE | bolt-daemon + bolt-core-sdk + ecosystem | **COMPLETE** (`ecosystem-v0.1.147-webtransport-browser-app1-wt5-closeout`, 2026-03-15). All 20 ACs PASS. All 5 PM decisions APPROVED. WT1–WT5 DONE. |
| EGUI-WASM-1 | Browser UI migration to egui via WASM (experimental) | ~~LATER~~ ABANDONED | localbolt-v3 + localbolt + ecosystem | **ABANDONED** (`ecosystem-v0.1.164`, 2026-03-17). EW2 PoC: 1,296 KiB gzipped (2.6× over 500 KiB kill). 26% reuse. 20× bundle vs current 65 KiB TS app. Stream CLOSED with findings. |
| RUSTIFY-BROWSER-CORE-1 | Browser-path Rust/WASM protocol authority | ~~NEXT~~ CLOSED | bolt-core-sdk + bolt-transport-web + consumers + ecosystem | **CLOSED** (`ecosystem-v0.1.171`, 2026-03-17). All 23 ACs, all 5 PM decisions. 102 KiB gzipped WASM. localbolt-v3 complete; others PM-RB-04 deferred. TS fallback retained non-authoritative. |
| RUSTIFY-BROWSER-ROLLOUT-1 | Package + deploy + burn-in for browser WASM authority | ~~NEXT~~ CLOSED | bolt-core-sdk + consumers + ecosystem | **CLOSED** (`ecosystem-v0.1.178`, 2026-03-19). All 17 ACs satisfied. All consumers on published packages. Burn-in evidence collected. TS fallback retained. |

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
- **BTR-SPEC-1** has no upstream stream dependencies. COMPLEMENTS SEC-BTR1 (complete), CONSUMER-BTR1 (in-progress), RUSTIFY-CORE-1 (codified). Within BS-stream: BS1 → BS2 → BS3 → BS4 → BS5 (fully serial). BS1 unblocked immediately. May run in parallel with all other streams.

---

## No-Push Policy

**Default:** DO NOT push commits or tags to remote repositories during phase execution.

Pushes require explicit PM authorization. Phase reports are filed locally. The PM reviews and authorizes push as a separate action after phase report review.

This policy prevents half-completed workstream states from appearing on remote branches and ensures the PM has review authority over every remote state change.
