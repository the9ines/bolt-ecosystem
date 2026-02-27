# Canonical Security Audit — 2026-02-26

> **Status:** Frozen audit source. Not updated after initial import.
> **Canonical Tracker:** `docs/AUDIT_TRACKER.md` (SA-series section) tracks live status.
> **Raw Audit:** `AUDIT-2026-02-26.md` (workspace root)

---

## A) Audit Metadata

| Field | Value |
|-------|-------|
| Date | 2026-02-26 |
| Scope | bolt-core-sdk (Rust + TS), bolt-daemon, bolt-transport-web |
| Mode | READ-ONLY static analysis |
| Auditor | Claude Opus 4.6 (4 parallel audit agents) |
| Finding Count | 19 open (3 HIGH, 9 MEDIUM, 7 LOW) + 2 pre-fixed (F1, F2) |

---

## B) Findings Table (SA-series)

### ID Collision Avoidance

The raw audit labeled findings O1–O19. The ecosystem `AUDIT_TRACKER.md` already uses O1–O12
for PROTO-HARDEN-1 governance observations. To avoid collision, this audit uses the **SA-series**
(SA1–SA19), with a one-to-one mapping: SA*N* = O*N*.

`AUDIT_TRACKER.md` remains canonical for current status; this file is the frozen audit source + mapping.

### Findings

| SA_ID | OriginalID | Severity | Component | Title | Detail | Track | Phase Mapping | Closure Mode | Evidence Minimum |
|-------|-----------|----------|-----------|-------|--------|-------|---------------|--------------|------------------|
| SA1 | O1 | HIGH | bolt-daemon | HELLO key material mismatch | Daemon encrypts HELLO with identity keypairs (`web_hello.rs:191`); web uses ephemeral keypairs. Signaling `publicKey` maps to different key types. | PROTOCOL | TBD | OPEN | INTEROP + ADVERSARIAL |
| SA2 | O2 | HIGH | bolt-transport-web | Web client no inbound error code validation | `WebRTCService.ts:849-853` accepted any error code string without registry check. | PROTOCOL | PROTO-HARDEN-2A | DONE-VERIFIED | INTEROP + ADVERSARIAL |
| SA3 | O3 | HIGH | bolt-daemon | Daemon error code registry incomplete (8/22) | `envelope.rs:131-140` missing 14 codes the web legitimately sends; valid codes classified as PROTOCOL_VIOLATION. | PROTOCOL | PROTO-HARDEN-2A | DONE-VERIFIED | INTEROP + ADVERSARIAL |
| SA4 | O4 | MEDIUM | bolt-core-sdk (Rust) | KeyPair not zeroed on Drop | `crypto.rs:22-28` has no `Drop` impl, no `zeroize` crate. Secret key bytes persist in memory. | MEMORY | TBD | OPEN | UNIT + ADVERSARIAL |
| SA5 | O5 | MEDIUM | bolt-transport-web | PeerConnection leaked on handleOffer error | `WebRTCService.ts:195-198` catch block does not call `disconnect()`; PC left dangling with active ICE. | LIFECYCLE | TBD | OPEN | UNIT + ADVERSARIAL |
| SA6 | O6 | MEDIUM | bolt-transport-web | Signaling listener never unregistered | `WebRTCService.ts:165` registers callback; `SignalingProvider` has no `offSignal()`. Closure captures `this`, prevents GC. | LIFECYCLE | TBD | OPEN | UNIT + ADVERSARIAL |
| SA7 | O7 | MEDIUM | bolt-transport-web | remoteIdentityKey not zeroed on disconnect | `WebRTCService.ts:667` sets null without `fill(0)`. Inconsistent with secretKey zeroing. | MEMORY | TBD | OPEN | UNIT |
| SA8 | O8 | MEDIUM | bolt-daemon + bolt-transport-web | Post-envelope error framing divergence | Daemon sent plaintext errors post-handshake; web's ENVELOPE_REQUIRED guard rejected them. | PROTOCOL | I5 (interop-error-framing) | DONE-VERIFIED | INTEROP + ADVERSARIAL |
| SA9 | O9 | MEDIUM | bolt-transport-web | Silent drop in routeInnerMessage plaintext path | `WebRTCService.ts:882` `routeInnerMessage` silently drops non-file-chunk types in legacy path. Plaintext `type:'error'` now handled (PROTO-HARDEN-2A), but other unknown types still silently drop. | PROTOCOL | PROTO-HARDEN-2A (partial) | IN-PROGRESS | UNIT + ADVERSARIAL |
| SA10 | O10 | MEDIUM | bolt-transport-web | HELLO timeout silent legacy downgrade | `WebRTCService.ts:433-446` downgrades to unauthenticated mode after 5s without HELLO. No strict mode when `identityPublicKey` configured. | TRANSPORT | TBD | OPEN | UNIT + ADVERSARIAL |
| SA11 | O11 | MEDIUM | bolt-protocol | Identity-ephemeral key binding gap | Identity key inside HELLO not cryptographically bound to ephemeral key. SAS verification is the documented mitigation. | PROTOCOL | N/A (spec) | DONE-BY-DESIGN | N/A (documented in PROTOCOL.md §3, §15.2) |
| SA12 | O12 | MEDIUM | bolt-transport-web | Async race in processHello | `WebRTCService.ts:803` async processHello invoked without guard state; second HELLO can pass pre_hello check during await. | PROTOCOL | TBD | OPEN | UNIT + ADVERSARIAL |
| SA13 | O13 | LOW | bolt-transport-web | DC handlers not nulled before close | `WebRTCService.ts:629-632` calls `dc.close()` without nulling onmessage/onopen/onclose/onerror first. | LIFECYCLE | TBD | OPEN | UNIT |
| SA14 | O14 | LOW | bolt-transport-web | helloTimeout stale callback race | No session generation counter; rapid disconnect+connect allows stale timeout to fire into new session. | LIFECYCLE | TBD | OPEN | UNIT |
| SA15 | O15 | LOW | bolt-daemon | bolt.file-hash missing from daemon capabilities | `web_hello.rs:36` DAEMON_CAPABILITIES lacks `bolt.file-hash`; file integrity silently skipped. | TRANSPORT | TBD | OPEN | UNIT |
| SA16 | O16 | LOW | bolt-daemon | TLS stream skips set_read_timeout | `rendezvous.rs:171-175` silently skips read timeout for TLS streams; ws.read() may block indefinitely. | TRANSPORT | TBD | OPEN | UNIT |
| SA17 | O17 | LOW | bolt-core-sdk + bolt-daemon | Unbounded remote capabilities list | No max length enforced on remote capabilities array in HELLO. Peer can send arbitrarily long list. | TRANSPORT | TBD | OPEN | UNIT |
| SA18 | O18 | LOW | bolt-transport-web | decodeProfileEnvelopeV1 dead code with silent null | `WebRTCService.ts:1215-1226` returns null on decrypt failure instead of throwing. Not in critical path today. | GOVERNANCE | TBD | OPEN | UNIT |
| SA19 | O19 | LOW | bolt-transport-web | remotePublicKey not zeroed on disconnect | `WebRTCService.ts:642` sets null without `fill(0)`. Public key (lower sensitivity). | MEMORY | TBD | OPEN | UNIT |

---

## C) Mapping Notes

### Why SA-series

`AUDIT_TRACKER.md` uses O1–O12 for PROTO-HARDEN-1 governance observations (codified in PROTOCOL.md §15).
The raw audit used O1–O19. To avoid ID collision, this audit imports findings as **SA1–SA19** (Security Audit).
The `OriginalID` column preserves traceability to the raw audit labels.

### Authority

- **AUDIT_TRACKER.md** remains canonical for current finding status (live updates).
- **This file** is the frozen audit source + mapping. It is not updated after initial import.
- Agents reference `AUDIT_TRACKER.md` SA-series entries, not raw audit transcripts.

---

## D) Evidence Ladder Reference

| Severity | Minimum for DONE-VERIFIED |
|----------|---------------------------|
| HIGH | INTEROP + at least one ADVERSARIAL test |
| MEDIUM | UNIT + at least one ADVERSARIAL or INTEROP |
| LOW | UNIT or documented rationale (DONE-BY-DESIGN) |

Evidence types:
- **UNIT**: unit/integration tests within a single implementation
- **INTEROP**: cross-implementation evidence (golden vectors, Rust-TS parity)
- **ADVERSARIAL**: negative-input or hostile-condition tests proving fail-closed (malformed frames, unknown codes, invalid schemas, replay inputs, timeout triggers, forced disconnect races)

---

## E) Summary

| Severity | Count | Resolved | Open |
|----------|-------|----------|------|
| HIGH | 3 | 2 (SA2, SA3) | 1 (SA1) |
| MEDIUM | 9 | 3 (SA8, SA9-partial, SA11) | 6 (SA4–SA7, SA10, SA12) |
| LOW | 7 | 0 | 7 (SA13–SA19) |
| **Total** | **19** | **5** | **14** |
