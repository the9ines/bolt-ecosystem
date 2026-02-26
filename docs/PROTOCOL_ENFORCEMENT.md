# Bolt Protocol — Enforcement Posture

> **Status:** Normative
> **Created:** 2026-02-25
> **Authority:** This document defines runtime invariants and failure posture for all Bolt Protocol implementations. It complements `PROTOCOL.md` (wire contract). If conflict exists, `PROTOCOL.md` is authoritative for wire semantics; this document is authoritative for enforcement behavior.

This document uses RFC 2119 language: MUST, MUST NOT, SHALL, SHALL NOT, REQUIRED, SHOULD, MAY.

---

## 1. Exactly-Once HELLO Rule

A HELLO exchange MUST occur exactly once per session.

- The offerer MUST send the first HELLO message.
- The answerer MUST reply with exactly one HELLO message.
- After a HELLO exchange completes successfully, any subsequent HELLO message received on the same session MUST be treated as a protocol violation.
- On receiving a duplicate HELLO, the implementation MUST:
  1. Send an error frame with code `DUPLICATE_HELLO`.
  2. Disconnect immediately.
- An implementation MUST NOT process, re-negotiate, or silently discard a duplicate HELLO.

### Rationale

Re-negotiation after HELLO completion would allow an attacker to force a key downgrade or reset session state. Exactly-once eliminates this vector.

---

## 2. Envelope-Required Mode Rule

When both peers negotiate the `bolt.profile-envelope-v1` capability during HELLO, envelope-required mode is active for the remainder of the session.

- In envelope-required mode, ALL post-HELLO messages MUST be wrapped in a Profile Envelope.
- A Profile Envelope MUST contain:
  - A type identifier indicating envelope framing.
  - A version number.
  - An encoding identifier.
  - An encrypted payload sealed with the session's negotiated keys.
- Any post-HELLO inbound message that is NOT a valid Profile Envelope MUST be rejected.
- On receiving a plaintext (non-envelope) frame in envelope-required mode, the implementation MUST:
  1. Send an error frame with code `ENVELOPE_REQUIRED`.
  2. Disconnect immediately.
- An implementation MUST NOT fall back to plaintext processing when envelope-required mode is active.
- An implementation MUST NOT selectively enforce envelope-required mode (e.g., enforcing on some message types but not others).

### Rationale

Selective enforcement creates a channel for plaintext injection. Envelope-required mode is binary: either all post-HELLO messages are enveloped, or none are.

---

## 3. Fail-Closed Rule

All protocol errors MUST result in session termination. There is no recovery path for protocol violations within a session.

The following conditions MUST trigger fail-closed behavior:

| Condition | Error Code | Phase |
|-----------|-----------|-------|
| HELLO parse failure | `HELLO_PARSE_ERROR` | HELLO |
| HELLO decrypt failure | `HELLO_DECRYPT_FAIL` | HELLO |
| HELLO schema violation | `HELLO_SCHEMA_ERROR` | HELLO |
| Identity key does not match pinned key | `KEY_MISMATCH` | HELLO |
| Duplicate HELLO received | `DUPLICATE_HELLO` | Post-HELLO |
| Plaintext frame in envelope-required mode | `ENVELOPE_REQUIRED` | Post-HELLO |
| Envelope decrypt failure | `ENVELOPE_DECRYPT_FAIL` | Post-HELLO |
| Envelope parse failure (valid decrypt, invalid inner) | `ENVELOPE_INVALID` | Post-HELLO |
| Envelope capability not negotiated but envelope received | `ENVELOPE_UNNEGOTIATED` | Post-HELLO |
| Inner message parse failure | `INVALID_MESSAGE` | Post-HELLO |
| Inner message type unrecognized | `UNKNOWN_MESSAGE_TYPE` | Post-HELLO |
| Message exceeds size cap or rate limit | `LIMIT_EXCEEDED` | Any |
| Message received in unexpected session state | `INVALID_STATE` | Any |
| Violation not covered by a specific code | `PROTOCOL_VIOLATION` | Any |

Fail-closed means:
1. Send an error frame (best-effort; do not block on delivery).
2. Terminate the transport connection.
3. Do not attempt reconnection within the same session context.

An implementation MUST NOT:
- Log and continue after a protocol error.
- Silently discard malformed messages and wait for a valid one.
- Retry HELLO or re-negotiate after a failure.
- Fall back to a less-strict processing mode.

### Rationale

Log-and-continue creates a permissive receive path that an attacker can exploit to bypass envelope encryption. Every protocol error is treated as a potential attack.

---

## 4. Downgrade Resistance Rule

An implementation MUST NOT permit capability downgrade within a session or across session re-establishment.

- If both peers advertise `bolt.profile-envelope-v1` in their HELLO capabilities, envelope-required mode MUST be activated. Neither peer MAY subsequently send or accept plaintext.
- If a peer advertises capabilities in HELLO but the peer's subsequent behavior does not conform to those capabilities, this is a protocol violation subject to the Fail-Closed Rule.
- Legacy plaintext behavior (no envelope) is permitted ONLY in sessions where the envelope capability was NOT negotiated by either peer.
- An implementation MUST NOT provide a runtime flag, configuration option, or API that disables envelope enforcement after negotiation has occurred.

### Rationale

Downgrade attacks work by convincing one side to accept a weaker mode than was negotiated. Preventing downgrade at the enforcement layer ensures that capability negotiation is binding.

---

## 5. Legacy Mode Boundary

Legacy mode is defined as: a session in which `bolt.profile-envelope-v1` was NOT negotiated during HELLO.

In legacy mode:
- Plaintext post-HELLO messages MAY be accepted.
- Envelope framing is not required.
- The Envelope-Required Mode Rule does not apply.
- All other rules in this document (Exactly-Once HELLO, Fail-Closed, Disconnect Semantics) still apply.

The boundary between legacy mode and envelope-required mode is determined solely by the outcome of capability negotiation during HELLO. There is no other mechanism to select the mode.

An implementation MAY choose to reject legacy mode entirely (i.e., require envelope capability from all peers). This is a stricter posture and is permitted.

An implementation MUST NOT mix legacy and envelope behavior within a single session. The mode is determined once at HELLO completion and is immutable for the session lifetime.

---

## 6. Error Frame Requirements

Before disconnecting due to a protocol violation, an implementation MUST attempt to send an error frame to the remote peer.

An error frame MUST contain:
- `type`: The string `"error"`.
- `code`: A machine-readable error code from the table in Section 3.
- `message`: A human-readable description of the error.

Error frame delivery is best-effort:
- The implementation MUST NOT block indefinitely waiting for the error frame to be acknowledged or delivered.
- If the transport is already broken, the implementation MUST proceed to disconnect without the error frame.
- The error frame itself is NOT enveloped (it is sent as plaintext JSON on the transport). This is the sole exception to the Envelope-Required Mode Rule, and applies ONLY to error frames sent immediately before disconnect.

An implementation MUST NOT send error frames for non-error conditions. Error frames are exclusively a precursor to disconnect.

---

## 7. Disconnect Semantics

Disconnect means full transport teardown.

- The transport connection MUST be closed (not merely paused or drained).
- All session state (keys, capabilities, HELLO state) MUST be discarded.
- The session context MUST NOT be reused for a new connection.
- If the implementation maintains a session object, it MUST be marked as terminated and MUST NOT accept further messages.

Reconnection after disconnect:
- A new session MUST go through the full HELLO exchange.
- No state from the terminated session MAY carry over.
- The new session is subject to all rules in this document from the beginning.

An implementation MUST NOT implement "soft disconnect" where the transport remains open but the session is considered terminated.

---

## 8. Conformance Test Requirements

An implementation claiming conformance to this enforcement posture MUST pass the following categories of tests:

### 8.1 Exactly-Once HELLO

- Verify that a second HELLO after successful exchange produces `DUPLICATE_HELLO` error and disconnect.
- Verify that a second HELLO is not processed (no state mutation, no re-negotiation).

### 8.2 Envelope-Required Mode

- Verify that plaintext frames after envelope negotiation produce `ENVELOPE_REQUIRED` error and disconnect.
- Verify that ALL post-HELLO message types are rejected when not enveloped.
- Verify that envelope mode activates if and only if both peers negotiate the capability.

### 8.3 Fail-Closed

- Verify that each error condition in the Section 3 table produces the specified error code and disconnect.
- Verify that no error condition results in log-and-continue behavior.
- Verify that malformed HELLO (bad JSON, bad crypto, missing fields) triggers disconnect, not fallback.

### 8.4 Downgrade Resistance

- Verify that after envelope capability negotiation, sending plaintext is rejected.
- Verify that no runtime configuration can disable envelope enforcement post-negotiation.

### 8.5 Legacy Mode Boundary

- Verify that sessions without envelope negotiation accept plaintext.
- Verify that the mode boundary is immutable after HELLO completion.

### 8.6 Error Frames

- Verify that error frames are sent before disconnect for each violation type.
- Verify that error frames contain the required fields (type, code, message).
- Verify that error frames are not enveloped.

### 8.7 Disconnect

- Verify that disconnect tears down the transport fully.
- Verify that session state is not reusable after disconnect.
- Verify that reconnection requires a full HELLO exchange.

### 8.8 Golden Vector Conformance

- When golden vectors exist (HELLO, envelope, SAS), implementations MUST pass cross-implementation vector tests.
- A vector test failure MUST block release.

---

## Appendix A: Error Code Registry

| Code | Section | Trigger |
|------|---------|---------|
| `DUPLICATE_HELLO` | 1 | Second HELLO received after exchange complete |
| `ENVELOPE_REQUIRED` | 2 | Plaintext frame in envelope-required session |
| `ENVELOPE_UNNEGOTIATED` | 2 | Envelope received when capability not negotiated |
| `ENVELOPE_DECRYPT_FAIL` | 3 | Sealed payload fails decryption |
| `ENVELOPE_INVALID` | 3 | Decrypted payload fails parse/schema validation |
| `HELLO_PARSE_ERROR` | 3 | HELLO outer frame unparseable |
| `HELLO_DECRYPT_FAIL` | 3 | HELLO sealed payload fails decryption |
| `HELLO_SCHEMA_ERROR` | 3 | HELLO inner payload missing required fields or wrong types |
| `KEY_MISMATCH` | 3 | Identity key does not match pinned key (TOFU violation) |
| `INVALID_MESSAGE` | 3 | Inner message (post-envelope decrypt) fails parse |
| `UNKNOWN_MESSAGE_TYPE` | 3 | Inner message parses but contains unrecognized type |
| `INVALID_STATE` | 3 | Message received in unexpected session state |
| `LIMIT_EXCEEDED` | 3 | Message exceeds size cap or rate limit |
| `PROTOCOL_VIOLATION` | 3 | Catch-all for violations not covered by a specific code |

**SDK Conformance Harness Coverage (S1):**
Error codes `ENVELOPE_DECRYPT_FAIL` and `HELLO_DECRYPT_FAIL` are enforced at the Rust core SDK level via `BoltError::Encryption` (conformance tests in `rust/bolt-core/tests/conformance/error_code_mapping.rs`). `KEY_MISMATCH` is enforced via `KeyMismatchError`. The remaining 11 codes (`DUPLICATE_HELLO`, `ENVELOPE_REQUIRED`, `ENVELOPE_UNNEGOTIATED`, `ENVELOPE_INVALID`, `HELLO_PARSE_ERROR`, `HELLO_SCHEMA_ERROR`, `INVALID_MESSAGE`, `UNKNOWN_MESSAGE_TYPE`, `INVALID_STATE`, `LIMIT_EXCEEDED`, `PROTOCOL_VIOLATION`) are transport-level concerns enforced in TS `WebRTCService` (H2) and Rust daemon (INTEROP-2 through H5), not in the core SDK crate.

---

## Appendix B: Implementation Status

### H-Phase Delivery Record

| Phase | Description | Scope | Tag(s) | Commit(s) | Branch | Merged to Main |
|-------|-------------|-------|--------|-----------|--------|----------------|
| H0 | Protocol enforcement posture | bolt-ecosystem/docs/ | N/A (unversioned) | N/A (filesystem) | N/A | N/A |
| H1 | Signal server trust-boundary hardening | localbolt-v3 | `v3.0.59-signal-hardening`, `v3.0.62-h1-mainline-merge` | `ac5110c`, `7571d35` | `feature/h1-signal-hardening` | Yes |
| H2 | WebRTC enforcement compliance | bolt-core-sdk | `sdk-v0.5.0-h2-webrtc-enforcement`, `sdk-v0.5.3-h2-h3-mainline` | `b4ce544`, `3f66da9` | `feature/h2-webrtc-enforcement` | Yes |
| H3 | Cross-implementation golden vectors | bolt-core-sdk, bolt-daemon | `sdk-v0.5.1`, `sdk-v0.5.3-h2-h3-mainline`, `daemon-v0.2.5-h3-golden-vectors`, `daemon-v0.2.10-h3-h6-mainline` | `9d8617d`, `3f66da9` (SDK); `3751118`, `0b16392` (daemon) | `feature/h3-golden-vectors` | Yes |
| H3.1 | Hermetic vectors (daemon) | bolt-daemon | `daemon-v0.2.8-h3.1-vectors-hermetic`, `daemon-v0.2.10-h3-h6-mainline` | `e6c8851`, `0b16392` | `feature/h5-downgrade-validation` | Yes |
| H4 | Daemon panic surface elimination | bolt-daemon | `daemon-v0.2.6-h4-panic-elimination`, `daemon-v0.2.10-h3-h6-mainline` | `678c808`, `0b16392` | `feature/h5-downgrade-validation` | Yes |
| H5 | Daemon downgrade resistance + enforcement validation | bolt-daemon | `daemon-v0.2.7-h5-downgrade-validation`, `daemon-v0.2.10-h3-h6-mainline` | `257c4a4`, `0b16392` | `feature/h5-downgrade-validation` | Yes |
| H5-v3 | localbolt-v3 TOFU/SAS identity + pinning wiring | localbolt-v3 | `v3.0.61-h5v3-tofu-sas-pinning` | `532d391` | main | Yes |
| H6 | CI enforcement across repos | bolt-core-sdk, bolt-daemon, bolt-rendezvous, localbolt-v3 | Per-repo (see below) | Per-repo (see below) | Various | Yes |

**H6 per-repo evidence:**

| Repo | Tag | Commit |
|------|-----|--------|
| bolt-core-sdk | `sdk-v0.5.2-h6-ci-enforcement` | `476881a` |
| bolt-daemon | `daemon-v0.2.9-h6-ci-enforcement` | `398a63d` |
| bolt-rendezvous | `rendezvous-v0.2.1-h6-ci-enforcement` | `6f48ba7` |
| localbolt-v3 | `v3.0.60-h6-ci-enforcement` | `3b12f73` |

### Current Enforcement Posture

The following invariants are implemented and tested across the ecosystem:

| Invariant | Implementation | Test Evidence |
|-----------|---------------|---------------|
| Exactly-once HELLO | `WebRTCService` (TS), `web_hello.rs` (daemon) | H2: `webrtcservice-h2-enforcement.test.ts` (21 tests), daemon: `web_hello.rs` (20 tests) |
| Envelope-required binary enforcement | `WebRTCService` envelope mode (TS), `envelope.rs` (daemon) | H2: envelope-required rejection tests, daemon: `envelope.rs` (12 tests) |
| Fail-closed semantics | All protocol errors trigger disconnect | H2: fail-closed tests for every error code, daemon: error framing + disconnect |
| Error code registry | 14 error codes (Appendix A) | H2: error code emission tests per violation type |
| Downgrade resistance | No runtime flag can disable enforcement post-negotiation | H2: downgrade resistance test suite |
| Golden vector gate | SAS, HELLO-open, envelope-open vectors | H3: 3 vector files, TS (97 tests), Rust SDK (69 tests), daemon (267 tests with test-support) |

### Audit Items (All Complete)

All H-phase audit items completed and merged to main via merge train (2026-02-25).

| Item | Resolution | Evidence |
|------|-----------|----------|
| H4 — Daemon unwrap hardening | COMPLETE | `daemon-v0.2.6-h4-panic-elimination` (`678c808`), merged via `daemon-v0.2.10-h3-h6-mainline` |
| H5 — TOFU/SAS wiring in localbolt-v3 | COMPLETE | `v3.0.61-h5v3-tofu-sas-pinning` (`532d391`), on main |
| H6 — CI/coverage enforcement | COMPLETE | Per-repo H6 tags (see H-Phase Delivery Record) |

#### Deferred (Out of H-Series Scope)

- **I2**: Daemon/Web NaCl interop end-to-end test. Deferred until daemon matures past INTEROP-4.
- **I4**: Protocol-level envelope standardization across all transports. Deferred to bolt-protocol spec work.
- **Q4**: localbolt-app test suite. Build-only gate until app matures past scaffold.

### Release Readiness Status

| Dimension | Status | Detail |
|-----------|--------|--------|
| Security posture | HARDENED | H0–H6 define, implement, and enforce protocol rules. Exactly-once HELLO, envelope-required mode, fail-closed, downgrade resistance, TOFU/SAS pinning — all on main. |
| Stability posture | ENFORCED | CI gates wired across all repos. Golden vector drift check, clippy -D warnings, no-panic check, test-support feature gate — all on main. |
| Interop status | VERIFIED | H3 golden vectors prove cross-implementation parity (TS + Rust SDK + daemon). Vectors in CI gate. |
| Outstanding release blockers | NONE (for H-series scope) | All H-phase work merged. Deferred items (I2, I4, Q4) are out of H-series scope. |

---

## Appendix C: Adoption Status

> **Last Updated:** 2026-02-25 (post-merge-train)

Per-section enforcement status across implementations. "On main" means the implementation is merged to the repo's main branch and would be exercised by a production build from main.

| Section | Invariant | TS SDK (bolt-core-sdk) | Rust Daemon (bolt-daemon) | On Main (TS) | On Main (Daemon) |
|:---:|-----------|----------------------|--------------------------|:---:|:---:|
| §1 | Exactly-once HELLO | H2: `WebRTCService` | INTEROP-2: `web_hello.rs` HelloState | Yes | Yes |
| §2 | Envelope-required mode | H2: envelope mode | INTEROP-3: `envelope.rs` | Yes | Yes |
| §3 | Fail-closed | H2: per-error disconnect | INTEROP-3: error framing + disconnect | Yes | Yes |
| §4 | Downgrade resistance | H2: no runtime disable | INTEROP-3: no-downgrade gate | Yes | Yes |
| §5 | Legacy mode boundary | H2: capability-gated | INTEROP-3: capability-gated | Yes | Yes |
| §6 | Error frames | H2: 14 codes emitted | INTEROP-4: DcErrorMessage | Yes | Yes |
| §7 | Disconnect semantics | H2: full teardown | INTEROP-3: session discard | Yes | Yes |
| §8.8 | Golden vector conformance | H3: 97 TS + 69 Rust tests | H3: 267 tests (test-support) | Yes | Yes |

**Summary:** All enforcement invariants (§1–§8.8) are on main in both TS SDK and Rust daemon. TS SDK enforcement landed via `sdk-v0.5.3-h2-h3-mainline` (`3f66da9`). Daemon enforcement landed via INTEROP-2 through INTEROP-4 (§1–§7) and `daemon-v0.2.10-h3-h6-mainline` (`0b16392`) for golden vectors (§8.8).
