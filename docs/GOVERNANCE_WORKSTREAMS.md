# Bolt Ecosystem — Governance Workstreams

> **Status:** Normative
> **Created:** 2026-03-02
> **Tag:** ecosystem-v0.1.31-workstreams-2
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

## Deferred Phases

The following phases are explicitly NOT part of the 8-phase workstream plan. They are documented here as future work with prerequisites. Each requires a separate governance codification before execution.

### B4 — File-Hash Capability + Integrity Enforcement

**Prerequisites:** B2 (message types), B3 (transfer engine)
**Goal:** Implement `bolt.file-hash` capability negotiation and SHA-256 integrity verification on completed transfers.
**Note:** This phase will require alignment with PROTOCOL.md §5 (Capabilities) and §8 (FILE_FINISH).

### B5 — TOFU Pin Persistence Activation

**Prerequisites:** B3 (transfer engine with session routing)
**Goal:** Activate TOFU identity pin persistence in the daemon. The daemon already has pin store infrastructure from INTEROP-2; this phase wires it into the live session lifecycle.
**Note:** SA15 tension applies — see SA15 Supersession Note below.

### B6 — Post-HELLO Long-Lived Event Loop + IPC/CLI Control

**Prerequisites:** B3 (transfer engine), B5 (TOFU persistence)
**Goal:** Implement a persistent post-HELLO event loop that keeps sessions alive for multiple transfers. Add IPC interface for CLI control (list sessions, initiate transfer, cancel, status).
**Note:** This is the phase that transforms the daemon from a handshake-only tool into a usable file transfer service.

### D-E2E — Cross-Stack Integration Test

**Prerequisites:** B3 (minimum), realistically B6 (full daemon file transfer)
**Goal:** End-to-end test proving daemon-to-web (localbolt-v3 or transport-web) file transfer roundtrip. This is the first phase that touches multiple repos simultaneously.
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
| B-stream | bolt-daemon | `daemon-vX.Y.Z-transfer-converge-B{1..3}` | `daemon-v0.2.21-transfer-converge-B1` |
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
- **Within B-stream:** Phases B1–B3 are sequential (B2 depends on B1 defaults; B3 depends on B2 types).
- **Cross-stream dependency:** None until D-E2E, which is gated on B3+ completion (and realistically B6).

---

## No-Push Policy

**Default:** DO NOT push commits or tags to remote repositories during phase execution.

Pushes require explicit PM authorization. Phase reports are filed locally. The PM reviews and authorizes push as a separate action after phase report review.

This policy prevents half-completed workstream states from appearing on remote branches and ensures the PM has review authority over every remote state change.
