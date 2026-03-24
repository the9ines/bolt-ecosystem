# Bolt Protocol — Enforcement Compliance Matrix

> **Status:** Normative
> **Stream:** PROTOCOL-HARDENING-1
> **Audited:** 2026-03-24
> **Scope:** Daemon (Rust) + Browser (TypeScript) — 8 protocol rules

This document maps protocol rules to actual enforcement in code, with test citations. It is the canonical reference for protocol compliance review.

---

## Compliance Summary

| # | Rule | Daemon | Browser | Tests | Status |
|---|------|--------|---------|-------|--------|
| 1 | HELLO exactly-once | `web_hello.rs` HelloState | `HandshakeManager.ts` helloProcessing | 6 | ENFORCED |
| 2 | Handshake gating | `ws_endpoint.rs` session state | `WsDataTransport.ts` pre_hello gate | 4 | ENFORCED |
| 3 | Capability negotiation | `web_hello.rs` SA17/N8 | `HandshakeManager.ts` SA17/N8 | 8 | ENFORCED |
| 4 | Error code validation | `envelope.rs` validate_inbound_error | `WsDataTransport.ts` isValidWireErrorCode | 8 | ENFORCED |
| 5 | Transfer replay protection | `ws_endpoint.rs` BTR replay guard | `TransferManager.ts` guardedTransfers | 9 | ENFORCED |
| 6 | Envelope version enforcement | `envelope.rs` version != 1 | `WsDataTransport.ts` version !== 1 | 2 | ENFORCED |
| 7 | SAS computation consistency | `ws_endpoint.rs` bolt_core::sas | `HandshakeManager.ts` computeSas | vectors | ENFORCED |
| 8 | Oversized capability array | `web_hello.rs` max 32 + 64B | `HandshakeManager.ts` max 32 + 64B | 5 | ENFORCED |

---

## Rule 1: HELLO Exactly-Once

**Spec:** Each peer MUST send exactly one HELLO per session. Duplicate HELLO = DUPLICATE_HELLO error + close.

| Side | File | Mechanism | Fail mode |
|------|------|-----------|-----------|
| Daemon | `web_hello.rs` | `HelloState::mark_completed()` — returns Err on second call | Error + session reject |
| Browser | `HandshakeManager.ts:68-76` | `helloProcessing` sync flag — set before any await | `[DUPLICATE_HELLO]` error + disconnect |

**Tests:** `hello_state_first_completion_succeeds`, `hello_state_duplicate_rejected` (daemon). `sa12-hello-reentrancy.test.ts` UNIT-1/2, ADVERSARIAL-3/4 (browser).

---

## Rule 2: Handshake Gating

**Spec:** Before mutual HELLO completion, accept only HELLO/ERROR/PING/PONG. All other messages → INVALID_STATE error + close.

| Side | File | Mechanism | Fail mode |
|------|------|-----------|-----------|
| Daemon | `ws_endpoint.rs` | Session-key → HELLO sequence enforced by `handle_connection` flow | Protocol error |
| Browser | `WsDataTransport.ts:357-361` | `sessionState === 'pre_hello'` gate before any message routing | `INVALID_STATE` error + disconnect |

**Tests:** `webrtcservice-handshake-gating.test.ts` (browser).

---

## Rule 3: Capability Negotiation Truthfulness

**Spec:** Capabilities are intersection of local + remote. Array max 32 entries. Per-capability max 64 UTF-8 bytes. `bolt.profile-envelope-v1` mandatory when identity is configured.

| Side | File | Checks | Fail mode |
|------|------|--------|-----------|
| Daemon | `web_hello.rs:191-204` | SA17 (array ≤32), N8 (cap ≤64B) | `HELLO_SCHEMA_ERROR` |
| Browser | `HandshakeManager.ts:118-169` | SA17, N8, envelope-v1 mandatory | `PROTOCOL_VIOLATION` + disconnect |

**Tests:** `sa17_capabilities_at_max_32_accepted`, `sa17_capabilities_exceeding_32_rejected`, `n8_capability_64_bytes_accepted`, `n8_capability_65_bytes_rejected` (daemon). `capabilities.test.ts` (browser).

---

## Rule 4: Error Code Validation

**Spec:** Inbound error `code` must be from the canonical wire error registry (26 codes). Unknown code → PROTOCOL_VIOLATION + close.

| Side | File | Registry | Fail mode |
|------|------|----------|-----------|
| Daemon | `envelope.rs:166-195` | `bolt_core::errors::WIRE_ERROR_CODES` | `PROTOCOL_VIOLATION` |
| Browser | `WsDataTransport.ts:392,434` | `isValidWireErrorCode()` from bolt_core | `PROTOCOL_VIOLATION` + disconnect |

**Tests:** `inbound-error-validation.test.ts` — 8 cases covering missing code, non-string code, unknown code, empty code, non-string message.

---

## Rule 5: Transfer Replay Protection

**Spec:** Duplicate (transfer_id, chunk_index) rejected. Out-of-range chunk_index rejected.

| Side | File | Mechanism | Fail mode |
|------|------|-----------|-----------|
| Daemon | `ws_endpoint.rs` | BTR replay guard: (transfer_id, generation, chain_index) triple check + `BtrTransferContext::open_chunk` chain_index monotonicity | Error, chunk skipped |
| Browser | `TransferManager.ts` | `guardedTransfers` Map with `receivedSet: Set<number>` | `[REPLAY_DUP]` / `[REPLAY_OOB]` warning, chunk ignored |

**Tests:** `replay-protection.test.ts` — 9 cases. Daemon BTR: `btr_decrypt_chunk_wrong_chain_index_fails`, `btr_conformance_cross_transfer_key_isolation`.

---

## Rule 6: Envelope Version Enforcement

**Spec:** `version != 1` → ENVELOPE_INVALID error + close.

| Side | File | Check | Fail mode |
|------|------|-------|-----------|
| Daemon | `envelope.rs:321-328` | `envelope.version != 1` | `EnvelopeError::Invalid` |
| Browser | `WsDataTransport.ts:370-373` | `msg.version !== 1` | `ENVELOPE_INVALID` + disconnect |

**Tests:** `decode_rejects_wrong_version` (daemon). `profile-envelope-v1.test.ts` (browser).

---

## Rule 7: SAS Computation Consistency

**Spec:** SAS = SHA-256(sort32(identity_a, identity_b) || sort32(ephemeral_a, ephemeral_b)), first 6 hex chars uppercase. Commutative.

| Side | File | Function | Inputs |
|------|------|----------|--------|
| Daemon | `ws_endpoint.rs:631-638` | `bolt_core::sas::compute_sas` | identity_pk, remote_identity_pk, session_pk, remote_session_pk |
| Browser | `HandshakeManager.ts:201-210` | `computeSas` from @the9ines/bolt-core | Same 4-tuple |

**Consistency:** Both use the canonical `bolt_core` implementation (Rust native or WASM/TS fallback). Algorithm is commutative by construction (sort32 on both key pairs).

**Tests:** `bolt_core::sas` module tests + `hello-open-vectors.test.ts`.

---

## Rule 8: Oversized Capability Array Rejection

**Spec:** Capability array > 32 entries → HELLO_SCHEMA_ERROR. Individual capability > 64 UTF-8 bytes → PROTOCOL_VIOLATION.

| Side | File | Bounds | Fail mode |
|------|------|--------|-----------|
| Daemon | `web_hello.rs:191-204` | len > 32, per-cap > 64B | `HelloError::SchemaError` |
| Browser | `HandshakeManager.ts:118-133` | len > 32, `TextEncoder.encode(cap).length > 64` | `PROTOCOL_VIOLATION` + disconnect |

**Tests:** 5 daemon tests (SA17 + N8). Browser implicit in HELLO processing tests.

---

## Cross-Implementation Consistency

| Mechanism | Shared via | Divergence risk |
|-----------|-----------|-----------------|
| SAS computation | `bolt_core` (Rust + WASM) | None — same code |
| Error code registry | `bolt_core` (Rust + TS) | Low — canonical list |
| Capability negotiation | `bolt_core::session::negotiate_capabilities` | None — same algorithm |
| Envelope encode/decode | Separate implementations, same spec | Low — tested with round-trips |
| BTR key schedule | `bolt_btr` (Rust) / `BtrTransferAdapter` (TS) | **Medium — separate implementations, golden vectors exist but cross-consumption not yet automated** |

---

## Known Gap

**BTR cross-implementation conformance:** The Rust `bolt-btr` crate and TypeScript `BtrTransferAdapter` implement the same BTR algorithm independently. Golden vector files exist in `bolt-core/test-vectors/btr/` (10 vector files generated by Rust). TypeScript consumption of these vectors is not yet automated. Live validation (DAEMON-BTR-1) proved interop works in practice, but byte-level conformance tests would make this reviewable.

---

## Audit Metadata

- **Auditor:** Claude (automated code review)
- **Date:** 2026-03-24
- **Repos audited:** bolt-daemon, bolt-core-sdk (Rust + TypeScript)
- **Method:** Grep + read of enforcement code paths, test file review
- **Confidence:** HIGH for rules 1-8. MEDIUM for BTR cross-impl (proven by live transfer but not by automated vector test).
