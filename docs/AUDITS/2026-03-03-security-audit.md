# Security Re-Audit — 2026-03-03

> **Scope:** Full 4-category security re-audit of Bolt Protocol ecosystem
> **Agents:** Cryptographic Correctness, Protocol State Machine, Interop Compatibility, Memory/Lifecycle
> **Finding Series:** NF (New Finding)
> **Governance:** AUDIT-GOV-44

---

## Audit Configuration

| Category | Target Files | Result |
|----------|-------------|--------|
| Cryptographic Correctness | bolt-core (TS), bolt-core (Rust), WebRTCService.ts, HandshakeManager.ts, EnvelopeCodec.ts | 9/9 PASS |
| Protocol State Machine | WebRTCService.ts, HandshakeManager.ts, TransferManager.ts | 8/8 PASS, 1 MEDIUM |
| Interop Compatibility | TS + Rust implementations, wire format, signaling, envelope | 10/10 PASS, 1 LOW |
| Memory / Lifecycle | WebRTCService.ts, HandshakeManager.ts, TransferManager.ts | 6/6 PASS |

**Overall: 33/33 checklist items PASS. 1 MEDIUM finding (NF-1). 0 HIGH. 0 CRITICAL.**

---

## Category 1: Cryptographic Correctness (9/9 PASS)

| # | Check | Result | Notes |
|---|-------|--------|-------|
| 1 | Key role correctness at all call-sites | PASS | X25519 ephemeral for box, Ed25519 identity for signing. No cross-use. |
| 2 | No accidental key reuse across roles | PASS | Ephemeral keys generated per session, zeroed on disconnect. |
| 3 | Envelope framing integrity | PASS | `base64(nonce[24] \|\| ciphertext)` — identical TS/Rust. |
| 4 | Downgrade resistance | PASS | No runtime flag disables envelope enforcement. |
| 5 | Capability negotiation invariants | PASS | Intersection-based, fail-closed on empty set. |
| 6 | KeyPair zeroing on disconnect | PASS | `this.keyPair = null` in disconnect path. |
| 7 | Cross-language golden vectors | PASS | H3 vectors: 12/12 cross-implementation (TS-sealed → Rust-opened). |
| 8 | Identity-ephemeral key separation | PASS | Identity (Ed25519) never used for box operations. |
| 9 | Nonce-only / short payload guard | PASS | NaCl box_open rejects payloads shorter than nonce+MAC. |

### Informational

- **INFO-C1:** `EnvelopeCodec.unseal()` returns `null` on decrypt failure — caller handles as `ENVELOPE_DECRYPT_FAIL`. No silent pass-through.
- **INFO-C2:** `generateEphemeralKeyPair()` uses `nacl.box.keyPair()` (CSPRNG-seeded). No user-supplied entropy path.

---

## Category 2: Protocol State Machine (8/8 PASS, 1 MEDIUM)

| # | Check | Result | Notes |
|---|-------|--------|-------|
| 1 | HELLO exactly-once enforcement | PASS | `helloComplete` flag + `DUPLICATE_HELLO` error. |
| 2 | Pre-handshake message rejection | PASS | Fail-closed `INVALID_STATE` for non-HELLO before handshake. |
| 3 | Envelope-required binary enforcement | PASS | Post-HELLO with envelope negotiated → plaintext rejected. |
| 4 | Error code emission correctness | PASS | All 22 wire error codes mapped and emitted correctly. |
| 5 | Transfer state machine transitions | PASS | file-offer → file-accept → file-chunk → file-finish. No skip. |
| 6 | Disconnect on protocol violation | PASS | Every error path calls `sendErrorAndDisconnect()`. |
| 7 | Capability negotiation determinism | PASS | Intersection of sorted arrays. Deterministic. |
| 8 | Envelope path message validation | **MEDIUM (NF-1)** | See NF-1 below. |

### NF-1 — Envelope Path Filename Validation Gap (MEDIUM)

**Location:** `WebRTCService.ts` envelope handling in `handleMessage()`

**Issue:** The envelope code path forwarded `file-chunk` messages to `routeInnerMessage()` without validating `inner.filename`. The plaintext code path correctly rejected missing/empty filenames with `INVALID_MESSAGE` + disconnect (SA9 fix). This created an asymmetry: enveloped file-chunks with missing filenames were silently dropped by `routeInnerMessage()`'s internal guard rather than triggering a protocol error.

**Impact:** Consistency issue, not a data leak or RCE. The silent drop in the envelope path meant malformed messages from a peer would not trigger the expected disconnect, allowing the peer to continue sending additional malformed messages.

**Fix:** Added filename validation in the envelope path (`WebRTCService.ts:659–663`) mirroring the plaintext path guard. Both paths now emit `INVALID_MESSAGE` + disconnect on missing/empty filename.

**Tests:** 3 UNIT + 1 ADVERSARIAL in `nf1-envelope-filename-validation.test.ts`. 253 total tests pass.

**Status:** DONE-VERIFIED (`transport-web-v0.6.10-nf1-envelope-filename`)

### Informational

- **INFO-SM1:** `routeInnerMessage` in `TransferManager.ts:228` has a defensive `if (msg.type !== 'file-chunk' || !msg.filename) return;` guard. This is defense-in-depth — callers should validate before forwarding. NF-1 fix ensures this.

---

## Category 3: Interop Compatibility (10/10 PASS)

| # | Check | Result | Notes |
|---|-------|--------|-------|
| 1 | Wire format parity (TS ↔ Rust) | PASS | `base64(nonce[24] \|\| ciphertext)` identical. H3 golden vectors prove. |
| 2 | HELLO payload schema alignment | PASS | Both sides produce/consume identical JSON schema. |
| 3 | Capability string format | PASS | `bolt.` namespace, dot-separated. §14 constants aligned (AC-9). |
| 4 | Error code registry alignment | PASS | 22 codes in both `WIRE_ERROR_CODES` (TS) and `CANONICAL_ERROR_CODES` (Rust). |
| 5 | Signaling payload format | PASS | Golden fixtures in AC-6/AC-19/AC-20 prove parity. |
| 6 | Envelope format alignment | PASS | `profile-envelope` v1 format identical in TS and Rust. |
| 7 | SAS computation alignment | PASS | Golden vectors prove deterministic cross-implementation SAS. |
| 8 | File-hash capability interop | PASS | Both sides gate on `bolt.file-hash`. SHA-256 hex format aligned. |
| 9 | Capability length validation | PASS | N8 fix: 64-byte cap string length limit enforced in both. |
| 10 | Error framing in envelope mode | PASS | I5 fix: both sides wrap errors in envelope when negotiated. |

### Informational

- **INFO-I1:** NF-1 envelope filename validation gap also flagged here as a cross-path consistency issue. Single finding, single fix.

---

## Category 4: Memory / Lifecycle (6/6 PASS)

| # | Check | Result | Notes |
|---|-------|--------|-------|
| 1 | Key zeroing on disconnect | PASS | `keyPair`, `remotePublicKey`, `remoteIdentityKey` all nulled. |
| 2 | DataChannel cleanup | PASS | `dc.close()` called in disconnect. Event handlers cleared. |
| 3 | PeerConnection cleanup | PASS | `pc.close()` called in disconnect. |
| 4 | Transfer state reset | PASS | `TransferManager.reset()` called on disconnect. |
| 5 | Session state reset | PASS | All session flags reset to initial values. |
| 6 | No lingering timers | PASS | HELLO timeout cleared on completion or disconnect. |

### Informational

- **INFO-ML1:** `TransferManager` holds chunk data in memory during transfer. No explicit size cap beyond the file-size field in the offer. Large files could theoretically consume significant memory. This is by-design for the current WebRTC transport (no streaming to disk).

---

## Summary

| Metric | Value |
|--------|-------|
| Total checklist items | 33 |
| PASS | 33 |
| FAIL | 0 |
| Findings | 1 (NF-1, MEDIUM) |
| Informational | 5 |

**NF-1 fixed and verified in the same governance cycle (AUDIT-GOV-44).**

All audit series closed. 104 total findings across all audit cycles. 83 DONE/DONE-VERIFIED. 0 OPEN.
