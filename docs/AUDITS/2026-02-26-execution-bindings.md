# Execution Binding Contracts — SA-Series (2026-02-26 Audit)

> **Phase:** AUDIT-GOV-2
> **Date:** 2026-02-27
> **Source audit:** [`2026-02-26-security-audit.md`](2026-02-26-security-audit.md)
> **Canonical tracker:** [`../AUDIT_TRACKER.md`](../AUDIT_TRACKER.md)

---

## Purpose

Each open SA finding is bound to a five-section execution contract:

| Section | Purpose |
|---------|---------|
| **Invariant** | What must be true after the fix. One sentence, testable. |
| **Scope Boundary** | File + function + semantic boundary. No changes outside this boundary. |
| **Abort Conditions** | When to stop and escalate instead of continuing. |
| **Evidence Contract** | Invariant-driven tests required for closure. "Must prove X under Y." |
| **Definition of Done** | Concrete, verifiable criteria for DONE-VERIFIED status. |

Line numbers are approximate references from the 2026-02-26 audit. **Each implementation
phase must verify current line numbers before patching.**

---

## Reconciliation Gate (STOP 0.5)

Before contract generation, all SA items were reconciled against current repo state:

| SA_ID | Prior Status | Reconciled Status | Rationale |
|-------|-------------|-------------------|-----------|
| SA1 | OPEN | **OPEN** | Distinct from I6 (CLOSED-NO-BUG). I6 verified crypto algorithm/wire format parity. SA1 identifies identity/ephemeral role conflation in daemon — single keypair serves both signaling and HELLO identity roles, leaking identity via signaling and breaking TOFU semantics. PROTOCOL.md §15.1 mandates separation. Corrected from original "key-type mismatch causes decryption failure" claim (AUDIT-GOV-3A erratum). |
| SA2 | DONE-VERIFIED | **DONE-VERIFIED** | Resolved by PROTO-HARDEN-2A. No contract needed. |
| SA3 | DONE-VERIFIED | **DONE-VERIFIED** | Resolved by PROTO-HARDEN-2A. No contract needed. |
| SA4 | OPEN | **OPEN** | No intervening fix. |
| SA5 | OPEN | **OPEN** | No intervening fix. |
| SA6 | OPEN | **OPEN** | No intervening fix. |
| SA7 | OPEN | **OPEN** | No intervening fix. |
| SA8 | DONE-VERIFIED | **DONE-VERIFIED** | Resolved by I5. No contract needed. |
| SA9 | IN-PROGRESS | **IN-PROGRESS** | Partial fix from PROTO-HARDEN-2A. Legacy silent-drop gap confirmed extant. |
| SA10 | OPEN | **OPEN** | No intervening fix. |
| SA11 | DONE-BY-DESIGN | **DONE-BY-DESIGN** | Documented in PROTOCOL.md §3, §15.2. No contract needed. |
| SA12 | OPEN | **OPEN** | No intervening fix. |
| SA13 | OPEN | **OPEN** | No intervening fix. |
| SA14 | OPEN | **OPEN** | No intervening fix. |
| SA15 | OPEN | **OPEN** | No intervening fix. |
| SA16 | OPEN | **OPEN** | No intervening fix. |
| SA17 | OPEN | **OPEN** | No intervening fix. |
| SA18 | OPEN | **OPEN** | No intervening fix. |
| SA19 | OPEN | **OPEN** | No intervening fix. |

**Contract count:** 15 (14 OPEN + 1 IN-PROGRESS)

---

## PROTOCOL Track

### SA1 — HELLO Identity/Ephemeral Role Conflation (HIGH)

**Invariant:** HELLO `identityPublicKey` MUST be a persistent identity key distinct from the per-connection ephemeral seal key; identity keys MUST NOT appear in signaling `publicKey` and MUST only travel inside the encrypted HELLO payload, per PROTOCOL.md §15.1 and `identity.rs:21-22`.

**Scope Boundary:**
- `bolt-daemon/src/rendezvous.rs` — keypair generation and signaling key assignment (offerer and answerer paths). Currently calls `generate_identity_keypair()` per connection and uses the same keypair for both signaling `publicKey` and HELLO `identityPublicKey`.
- `bolt-daemon/src/web_hello.rs` — `build_hello_message()` inner payload construction. Currently sets `identityPublicKey` to `local_keypair.public_key` — the same key used for sealing.
- Out of scope: bolt-core-sdk crypto primitives (`seal_box_payload`, `open_box_payload`), web client key generation, PROTOCOL.md spec edits.

**Abort Conditions:**
- If fix requires PROTOCOL.md edits — escalate (spec change, not runtime fix).
- If fix requires altering NaCl box seal/open primitives or key exchange math — escalate.
- If implementing persistent identity key storage in the daemon exceeds single-phase scope — split into: Phase A (daemon identity key storage infrastructure), Phase B (role separation enforcement).

**Evidence Contract:**
Evidence Minimum: INTEROP + ADVERSARIAL (severity = HIGH).
- Must prove: daemon uses a persistent identity key that survives across sessions/reconnections.
- Must prove: signaling `publicKey` corresponds only to the ephemeral seal key and rotates per connection.
- Must prove: HELLO `identityPublicKey` is the persistent identity key, distinct from signaling `publicKey` within the same session.
- Must prove: TOFU pinning binds to the persistent identity key and produces meaningful mismatch on identity change.
- Adversarial: MITM substituting a different identity key inside HELLO triggers detectable TOFU mismatch. Attempt to pin on ephemeral (signaling) key must fail or be impossible by construction.

**Definition of Done:**
- Persistent identity key exists in daemon and survives reconnection.
- For any given session: signaling `publicKey` ≠ HELLO `identityPublicKey`.
- No identity key material travels via signaling channel.
- TOFU mismatch is demonstrable when identity key changes between sessions.
- `identity.rs:21-22` constraint enforced: identity keys only inside encrypted DataChannel messages.

---

### SA9 — Silent Drop in routeInnerMessage (MEDIUM) — IN-PROGRESS

**Invariant:** No message type is silently dropped in any code path. Unknown types trigger `UNKNOWN_MESSAGE_TYPE` error + disconnect in both envelope and legacy plaintext paths.

**Scope Boundary:**
- `WebRTCService.ts` — `routeInnerMessage()`, specifically the early-return guard for non-`file-chunk` types.
- Envelope path already handles unknown types correctly (out of scope for this finding).

**Abort Conditions:**
- If fix requires changing file-chunk handling semantics — escalate.
- If legacy path removal is proposed instead — that is a separate effort, not this finding's scope.

**Evidence Contract:**
- Must prove: unknown message type in legacy plaintext path triggers `UNKNOWN_MESSAGE_TYPE` + disconnect.
- Must prove: missing `type` field in legacy plaintext message triggers error + disconnect.
- Must prove: empty string `type` field triggers error + disconnect.

**Definition of Done:**
- `routeInnerMessage()` calls `sendErrorAndDisconnect('UNKNOWN_MESSAGE_TYPE', ...)` for non-`file-chunk` types.
- No silent return paths remain in `routeInnerMessage()`.
- Tests cover unknown type, missing type, empty type scenarios.

**Resolution:**
Implemented in `sdk-v0.5.8-proto-correctness-2` (`01e76e4`), phase PROTO-CORRECTNESS-2.
Enforcement applied at the legacy plaintext call site in `handleMessage()` before
`routeInnerMessage()` is reached — unknown/missing/empty type → `UNKNOWN_MESSAGE_TYPE` +
disconnect; malformed file-chunk with missing/empty filename → `INVALID_MESSAGE` + disconnect.
`routeInnerMessage()` internal guard retained as defense-in-depth; envelope path unmodified
(already validated upstream). Invariant satisfied.
Evidence: 3 UNIT + 3 ADVERSARIAL tests in `sa9-legacy-plaintext-drops.test.ts`.

---

### SA12 — Async Race in processHello (MEDIUM)

**Invariant:** Only one `processHello()` execution runs at a time. A second HELLO arriving during async processing is rejected synchronously before any await point.

**Scope Boundary:**
- `WebRTCService.ts` — `processHello()` entry point. Add synchronous guard state before first `await`.
- If `sessionState` enum is extended, the new state value is scoped to this function's entry guard.

**Abort Conditions:**
- If guard state introduction changes `sessionState` enum values that other state machine checks depend on — audit all `sessionState` comparisons before proceeding.
- If the `sessionState` type is a string union consumed by external callers — escalate (public API change).

**Evidence Contract:**
- Must prove: second HELLO during `processHello` async execution is rejected with `DUPLICATE_HELLO` + disconnect.
- Must prove: three rapid-fire HELLOs result in only the first being processed; second and third are rejected.
- Must prove: guard state is set synchronously (before any `await`) and cleared on both success and error paths.

**Definition of Done:**
- Synchronous guard state set at `processHello()` entry, before any `await`.
- Concurrent entry returns `DUPLICATE_HELLO` error + disconnect.
- Guard state cleared on all exit paths (success, error, disconnect).

**Resolution:**
Implemented in `sdk-v0.5.8-proto-correctness-2` (`01e76e4`), phase PROTO-CORRECTNESS-2.
Synchronous `helloProcessing` boolean guard set at `processHello()` entry before any `await`.
Concurrent entry rejected with `DUPLICATE_HELLO` + disconnect via `sendErrorAndDisconnect`.
Guard reset in `disconnect()` for clean new-session semantics. Invariant satisfied.
Evidence: 2 UNIT + 2 ADVERSARIAL tests in `sa12-hello-reentrancy.test.ts`.

---

## LIFECYCLE Track

### SA5 — PeerConnection Leaked on handleOffer Error (MEDIUM)

**Invariant:** Every code path that creates a PeerConnection either succeeds to completion or calls `disconnect()` before surfacing the error.

**Scope Boundary:**
- `WebRTCService.ts` — `handleSignal()` catch block. Add `this.disconnect()` before `this.onError()`.
- No changes to `handleOffer()` internal logic, `createPeerConnection()`, or `disconnect()` itself.

**Abort Conditions:**
- If calling `disconnect()` in the catch block causes cascading state issues — run existing lifecycle tests first to establish baseline.
- If `handleOffer()` throw points are all before PeerConnection creation (making the leak impossible) — reclassify as CLOSED-NO-BUG with evidence.

**Evidence Contract:**
- Must prove: `handleOffer()` failure after PeerConnection creation results in PC closed and ICE agent stopped.
- Must prove: no orphaned PeerConnection is observable after `handleSignal()` catch fires.

**Definition of Done:**
- `this.disconnect()` called before `this.onError()` in `handleSignal()` catch block.
- No PeerConnection outlives a failed offer handling path.

---

### SA6 — Signaling Listener Never Unregistered (MEDIUM)

**Invariant:** `SignalingProvider` supports listener removal. `disconnect()` unregisters the signaling callback. Post-disconnect signals do not invoke `handleSignal`.

**Scope Boundary:**
- `SignalingProvider.ts` — interface definition. Add `offSignal()` method or change `onSignal()` to return an unsubscribe function.
- `WebRTCService.ts` — constructor (store unsubscribe handle) and `disconnect()` (call unsubscribe).
- Consumer implementations of `SignalingProvider` in localbolt, localbolt-app, localbolt-v3 must be updated to implement the new interface method.

**Abort Conditions:**
- If `SignalingProvider` has more than 3 consumer implementations — escalate for coordinated rollout.
- If `onSignal()` return-type change breaks backward compatibility — prefer additive `offSignal()` method instead.

**Evidence Contract:**
- Must prove: after `disconnect()`, signaling messages do not invoke `handleSignal()`.
- Must prove: callback reference is released after `disconnect()` (no strong capture preventing GC).
- Must prove: all `SignalingProvider` implementations in consumer repos implement the new method.

**Definition of Done:**
- `SignalingProvider` interface supports listener removal.
- `WebRTCService.disconnect()` calls the removal method.
- Post-disconnect signals are no-ops.
- All consumer implementations updated.

---

### SA13 — DC Handlers Not Nulled Before Close (LOW)

**Invariant:** DataChannel event handlers are nulled before `dc.close()`, matching PeerConnection cleanup discipline already applied elsewhere in `disconnect()`.

**Scope Boundary:**
- `WebRTCService.ts` — `disconnect()` DataChannel teardown section. Null `onmessage`, `onopen`, `onclose`, `onerror` before `close()`.

**Abort Conditions:**
- None anticipated. Change is mechanical and additive.

**Evidence Contract:**
- Must prove: after `disconnect()`, no DataChannel event handler fires for buffered messages post-close.

**Definition of Done:**
- Four handler nullifications (`onmessage`, `onopen`, `onclose`, `onerror`) present before `dc.close()` call.

---

### SA14 — helloTimeout Stale Callback Race (LOW)

**Invariant:** A timeout callback from session N cannot mutate state in session N+1.

**Scope Boundary:**
- `WebRTCService.ts` — add `sessionGeneration` counter field. Increment in `disconnect()`. Capture and check in HELLO timeout callback.

**Abort Conditions:**
- If generation counter introduces issues with legitimate reconnection flows — test against existing lifecycle test suite before merging.

**Evidence Contract:**
- Must prove: rapid `disconnect()` + `connect()` sequence — stale timeout fires but generation guard rejects — new session state is unaffected.

**Definition of Done:**
- `sessionGeneration` field exists, incremented on `disconnect()`, captured and checked in timeout callback.
- Stale timeout callback is a no-op when generation mismatches.

---

## MEMORY Track

### SA4 — KeyPair Not Zeroed on Drop (MEDIUM)

**Invariant:** `KeyPair.secret_key` is zeroed when the struct is dropped. No unzeroed secret key copies persist in memory after drop.

**Scope Boundary:**
- `bolt-core-sdk/rust/bolt-core/src/crypto.rs` — `KeyPair` struct. Add `zeroize` crate dependency. Implement `Drop`.
- `bolt-core-sdk/rust/bolt-core/Cargo.toml` — add `zeroize` dependency.
- Audit `.clone()` call sites in `bolt-daemon/src/rendezvous.rs` to ensure cloned copies also zeroize on drop.

**Abort Conditions:**
- If `zeroize` crate version introduces dependency conflicts with existing `Cargo.lock` — escalate.
- If removing `Clone` derive is required but breaks bolt-daemon session lifecycle — find alternative (e.g., keep `Clone` but ensure `Drop` still fires on each copy).

**Evidence Contract:**
- Must prove: `KeyPair` drop zeroes `secret_key` (via `zeroize` crate guarantees documented in crate docs, or explicit test that reads memory post-drop via unsafe).
- Must prove: cloned `KeyPair` independently zeroes its own `secret_key` on drop.

**Definition of Done:**
- `zeroize` crate in `Cargo.toml` dependencies.
- `Drop` impl calls `self.secret_key.zeroize()`.
- `cargo test` passes. `cargo clippy` clean.
- Each `Clone` independently zeroes on drop (inherent from `Drop` impl).

---

### SA7 — remoteIdentityKey Not Zeroed on Disconnect (MEDIUM)

**Invariant:** `remoteIdentityKey` buffer is zeroed before null assignment, consistent with `secretKey` zeroing discipline applied elsewhere in `disconnect()`.

**Scope Boundary:**
- `WebRTCService.ts` — `disconnect()`, specifically the `remoteIdentityKey` teardown line.

**Abort Conditions:**
- None anticipated. One-line addition.

**Evidence Contract:**
- Must prove: after `disconnect()`, `remoteIdentityKey` buffer is zeroed before being set to null.

**Definition of Done:**
- `this.remoteIdentityKey?.fill(0)` precedes `this.remoteIdentityKey = null` in `disconnect()`.

---

### SA19 — remotePublicKey Not Zeroed on Disconnect (LOW)

**Invariant:** `remotePublicKey` buffer is zeroed before null assignment, consistent with zeroing discipline.

**Scope Boundary:**
- `WebRTCService.ts` — `disconnect()`, specifically the `remotePublicKey` teardown line.

**Abort Conditions:**
- None anticipated. One-line addition.

**Evidence Contract:**
- Must prove: after `disconnect()`, `remotePublicKey` buffer is zeroed before being set to null.

**Definition of Done:**
- `this.remotePublicKey?.fill(0)` precedes `this.remotePublicKey = null` in `disconnect()`.

---

## TRANSPORT Track

### SA10 — HELLO Timeout Legacy Fallback (MEDIUM)

**Invariant:** When caller provides `identityPublicKey`, HELLO timeout results in session failure — not silent downgrade to unauthenticated legacy mode.

**Scope Boundary:**
- `WebRTCService.ts` — HELLO timeout handler in `initiateHello()` or `connect()`/`handleOffer()`. Add strict-mode conditional gated on `identityPublicKey` presence.
- No changes to legacy fallback behavior when `identityPublicKey` is absent.

**Abort Conditions:**
- If strict mode breaks existing consumers that intentionally support mixed legacy/authenticated peers — audit localbolt, localbolt-app, localbolt-v3 usage of `identityPublicKey` before implementing.
- If `identityPublicKey` is always set in current consumers (making legacy path dead) — document and escalate for legacy path removal decision.

**Evidence Contract:**
- Must prove: with `identityPublicKey` configured, HELLO timeout triggers error + disconnect (not legacy downgrade).
- Must prove: without `identityPublicKey`, HELLO timeout triggers legacy mode (backward compatibility preserved).
- Must prove: delayed HELLO beyond timeout with strict mode results in connection failure.

**Definition of Done:**
- Strict-mode conditional in timeout handler: `identityPublicKey` set means timeout is fatal.
- `identityPublicKey` absent means legacy fallback is preserved.
- Tests cover both paths.

---

### SA15 — bolt.file-hash Missing from Daemon Capabilities (LOW)

**Invariant:** Daemon capabilities accurately reflect implemented functionality. Advertised capabilities have working implementations; unadvertised capabilities are documented gaps.

**Scope Boundary:**
- `bolt-daemon/src/web_hello.rs` — `DAEMON_CAPABILITIES` const.
- If file-hash implementation is added: daemon transfer path (file send/receive functions).
- If reclassified: documentation only.

**Abort Conditions:**
- If daemon transfer path does not support SHA-256 hash computation — do NOT advertise `bolt.file-hash`. Reclassify as DONE-BY-DESIGN with documented rationale for the capability gap.
- If adding file-hash to daemon requires significant transfer path refactoring — escalate as separate work item.

**Evidence Contract:**
- Must prove: `DAEMON_CAPABILITIES` matches actual daemon functionality (no false advertisements).
- Must prove: if `bolt.file-hash` is advertised, daemon computes and verifies file hash during transfer.

**Definition of Done:**
- Either: `bolt.file-hash` added to `DAEMON_CAPABILITIES` with working implementation.
- Or: gap explicitly documented and finding reclassified as DONE-BY-DESIGN with rationale.

---

### SA16 — TLS Stream Skips set_read_timeout (LOW)

**Invariant:** All stream types (plain TCP and TLS) enforce a read timeout. No `ws.read()` call blocks indefinitely.

**Scope Boundary:**
- `bolt-daemon/src/rendezvous.rs` — TLS match arm in stream timeout setup. Set timeout on underlying TLS stream or use a timeout wrapper around `ws.read()`.

**Abort Conditions:**
- If `tungstenite` TLS stream type (`MaybeTlsStream<TcpStream>` or similar) does not expose `set_read_timeout` and no wrapper is feasible without switching to an async runtime — escalate.
- If the underlying `TcpStream` inside the TLS wrapper can be accessed for timeout setting — use that approach.

**Evidence Contract:**
- Must prove: TLS connection with a silent (non-responding) peer triggers timeout within the configured deadline.

**Definition of Done:**
- TLS match arm enforces read timeout (directly or via wrapper).
- Silent skip comment replaced with active timeout enforcement.
- No indefinite-block path remains for any stream type.

---

### SA17 — Unbounded Remote Capabilities List (LOW)

**Invariant:** Remote capabilities array is bounded at a defined maximum. Excess entries are rejected.

**Scope Boundary:**
- `bolt-daemon/src/web_hello.rs` — `negotiate_capabilities()` and/or HELLO parsing (`parse_hello_typed()`). Add length check.
- `WebRTCService.ts` — `processHello()` capabilities extraction. Add length check.
- Check PROTOCOL.md for any existing cap limit before choosing a maximum.

**Abort Conditions:**
- If PROTOCOL.md already defines a capabilities limit — enforce that limit, do not invent a new one.
- If no spec limit exists, propose one (e.g., 64) and document the rationale.

**Evidence Contract:**
- Must prove: capabilities list exceeding the defined maximum is rejected with error.
- Must prove: capabilities list at exactly the maximum length is accepted.

**Definition of Done:**
- Both daemon and web enforce a maximum capabilities count.
- Excess capabilities trigger `PROTOCOL_VIOLATION` + disconnect.
- Maximum value is documented (in PROTOCOL.md or inline with spec reference).

---

## GOVERNANCE Track

### SA18 — decodeProfileEnvelopeV1 Dead Code (LOW)

**Invariant:** No envelope decoding function returns silent `null` on failure. Failure either throws or the function is removed.

**Scope Boundary:**
- `WebRTCService.ts` — `decodeProfileEnvelopeV1()` method. Audit all call sites before deciding throw-vs-remove.
- No changes to the active envelope decoding path in `handleMessage()`.

**Abort Conditions:**
- If `decodeProfileEnvelopeV1()` is discovered to be wired into an active code path during call-site audit — cannot delete without replacement. Convert to throw-on-failure instead.

**Evidence Contract:**
- Must prove: decrypt failure in envelope decoding results in a thrown error (not `null`).
- Or: function is removed with zero callers confirmed by static analysis.

**Definition of Done:**
- No silent `null` return path exists in any envelope decoding method.
- Either: function throws on all failure paths. Or: function removed, all callers verified absent.

---

## Summary

| Track | IDs | Count |
|-------|-----|-------|
| PROTOCOL | SA1, SA9, SA12 | 3 |
| LIFECYCLE | SA5, SA6, SA13, SA14 | 4 |
| MEMORY | SA4, SA7, SA19 | 3 |
| TRANSPORT | SA10, SA15, SA16, SA17 | 4 |
| GOVERNANCE | SA18 | 1 |
| **Total** | | **15** |

| Severity | IDs | Count |
|----------|-----|-------|
| HIGH | SA1 | 1 |
| MEDIUM | SA4, SA5, SA6, SA7, SA9, SA10, SA12 | 7 |
| LOW | SA13, SA14, SA15, SA16, SA17, SA18, SA19 | 7 |
