# Bolt Ecosystem Audit Tracker

> **Canonical Location:** `bolt-ecosystem/docs/AUDIT_TRACKER.md`
> This is the single authoritative audit tracker for all repos under the9ines/bolt-ecosystem.
> Relocated from `bolt-core-sdk/docs/AUDIT_TRACKER.md` on 2026-02-26 (DOC-GOV-2).

**Last updated:** 2026-02-28
**Scope:** All repos under the9ines/bolt-ecosystem

---

## SECURITY

| ID | Finding | Severity | Status | Evidence |
|----|---------|----------|--------|----------|
| S1 | TOFU identity pinning missing | HIGH | **DONE** | `bolt-core` identity primitives + `bolt-transport-web` pin store. Phase 7A: `sdk-v0.2.0-identity-primitives`, `transport-web-v0.2.0-hello-tofu-foundation`. 21 tests. |
| S2 | SAS verification not surfaced | HIGH | **DONE** | `bolt-core` canonical `computeSas()` + `bolt-transport-web` verification UI. Phase 7B: `transport-web-v0.3.0-sas-verification`. 15 tests + 3 golden vectors. |
| S3 | No replay protection / chunk dedup | HIGH | **DONE** | `transferId` (bytes16), per-transfer dedup, bounds checks, sender-identity binding. Phase 8A: `transport-web-v0.4.0-replay-protection`. 9 tests. Legacy path with `[REPLAY_UNGUARDED]` warning. |
| S4 | Pre-handshake message acceptance | MEDIUM | **DONE** | Fail-closed `INVALID_STATE` + disconnect for any non-HELLO message before `helloComplete`. Phase 8D: `transport-web-v0.4.2-strict-handshake-gating`. 6 tests. |
| S5 | Peer code modulo bias | LOW | **DONE** | Rejection sampling (`byte >= 248` discarded). Phase 8E: `sdk-v0.2.1-peer-code-bias-fix`. 3 tests. |
| S6 | Filename XSS via innerHTML | MEDIUM | **DONE** | `escapeHTML()` on all user-controlled strings. Phase 6B: `transport-web-v0.1.1-security-hardening`. 10 tests. |
| S7 | Ephemeral key reuse across sessions | HIGH | **DONE** | Keys generated per session in `connect()`/`handleOffer()`, zeroed in `disconnect()`. Phase 6B: `transport-web-v0.1.1-security-hardening`. 7 tests. |

---

## INTEROP

| ID | Finding | Severity | Status | Evidence |
|----|---------|----------|--------|----------|
| I1 | Rust/TS constants misaligned | MEDIUM | **DONE** | PEER_CODE_LENGTH 4->6, SAS_LENGTH 4->6, alphabet 36->31 chars. Phase 6A.1: `sdk-v0.1.1-constants-alignment`. Cross-language verification script. |
| I2 | Daemon/Web NaCl interop untested | LOW | **DONE** | H3 golden vectors prove crypto interop (12/12 cross-implementation: TS-sealed → Rust-opened). I5/I6 investigation further confirmed wire format alignment. Remaining gap: transport-level E2E (daemon ↔ web live transfer) not yet in CI. |
| I3 | Shadow SAS in transport-web | MEDIUM | **DONE** | Removed `getVerificationCode()`. Phase 6A.2: `sdk-v0.1.2-sas-canonical`. Enforcement script `verify-no-shadow-sas.sh`. |
| I4 | Protocol-level bolt-envelope | MEDIUM | **DEFERRED** | Profile Envelope v1 landed (Phase M1, `transport-web-v0.6.0`). Full protocol-level envelope standardization across all transports is a large cross-cutting effort deferred to bolt-protocol specification work. |
| I5 | Post-envelope error framing divergence | HIGH | **DONE** | Daemon `build_error_payload()` wraps errors in envelope when negotiated (session passed in). Web `sendErrorAndDisconnect()` envelope-aware (World B). Web accepts enveloped errors (Case B inbound). `daemon-v0.2.11-interop-error-framing` (`600fef4`), `transport-web-v0.6.2-interop-error-framing` (`e463e1a`). +4 daemon tests (271 total), +5 web tests (161 total). |
| P1 | Inbound error validation hardening | MEDIUM | **DONE** | Daemon `validate_inbound_error()` validates inbound `{type:"error"}` against `CANONICAL_ERROR_CODES` registry. Unknown/malformed codes → PROTOCOL_VIOLATION + disconnect. `daemon-v0.2.12-p1-inbound-error-validation` (`8c45819`). +5 daemon tests (276 total). |
| I6 | HELLO key material verification | MEDIUM | **CLOSED-NO-BUG** | Spec is authoritative. Both implementations match spec: X25519 + XSalsa20-Poly1305, 24-byte CSPRNG nonce, base64 of NaCl box payload per `seal_box_payload`/`open_box_payload`. H3 golden vectors pass 12/12 cross-implementation. No code change required. |

---

## QUALITY

| ID | Finding | Severity | Status | Evidence |
|----|---------|----------|--------|----------|
| Q1 | bolt-core test coverage baseline | MEDIUM | **DONE** | 76 tests across 7 files. Golden vectors, export snapshot guard, rejection sampling, identity, SAS, hash, crypto. |
| Q2 | bolt-transport-web test coverage | MEDIUM | **DONE** | 117 tests across 11 files. Hello, TOFU, SAS, replay, handshake gating, lifecycle, capabilities, file-hash, envelope, security. |
| Q3 | localbolt test coverage | MEDIUM | **DONE** | 272 tests across 13 files. Coverage thresholds enforced (80/70/80). |
| Q4 | localbolt-app test coverage | LOW | **DEFERRED** | No test suite. Build-only gate. Will be addressed when app matures past scaffold. |
| Q5 | localbolt-v3 test pipeline | MEDIUM | **DONE** | 4 smoke tests (FAQ + app render). Phase TP: `v3.0.53-test-pipeline`. CI step before build. |
| Q6 | localbolt-v3 coverage thresholds | MEDIUM | **DONE** | `@vitest/coverage-v8`, thresholds 45/5/31/48%. Phase Q6: `v3.0.55-coverage-thresholds`. |

---

## ARCHITECTURE

| ID | Finding | Severity | Status | Evidence |
|----|---------|----------|--------|----------|
| A1 | Dead exports in bolt-core public API | LOW | **DONE** | 7 unused constants removed (28->21 exports). Version 0.3.0->0.4.0. All consumers adopted. Phase A1: `sdk-v0.4.0-dead-exports-cleanup`. Consumers: localbolt `91a0f29`, localbolt-app `90584bf`, localbolt-v3 `14927d7`. |
| A2 | Signaling type duplication across repos | MEDIUM | **DONE** | `bolt-rendezvous-protocol` shared crate extracted. bolt-rendezvous and bolt-daemon both consume canonical types. |
| A3 | localbolt-v3 unmanaged signaling subtree | LOW | **DONE** | ADR-0001 documents native workspace crate decision + drift control policy. Phase A3: `v3.0.56-signaling-adr`. Not a subtree by design. |

---

## MEDIUM-TERM FEATURES (delivered)

| ID | Feature | Status | Evidence |
|----|---------|--------|----------|
| M1 | Profile Envelope v1 | **DONE** | `bolt.envelope` capability, versioned metadata wrapping, mixed-peer backward compat. `sdk-v0.3.0-profile-envelope-v1`, `transport-web-v0.6.0`. 14 tests. |
| M2 | File integrity hash wiring | **DONE** | `bolt.file-hash` capability, SHA-256 sender+receiver, fail-closed on mismatch. `sdk-v0.2.2-file-hash-wiring`, `transport-web-v0.5.0`. 16 tests. |
| M3 | SDK publish + consumer adoption | **DONE** | `@the9ines/bolt-core@0.4.0` and `@the9ines/bolt-transport-web@0.6.0` on GitHub Packages. All 3 consumers pinned on main. |

---

## ADOPTION STATUS

Product repos on main are pinned to published SDK releases. Interop fix (transport-web 0.6.2) landed but not yet rolled to consumers — adoption pending.

| Repo | bolt-core | transport-web (pinned) | transport-web (latest) | Tests | Build |
|------|-----------|------------------------|------------------------|-------|-------|
| localbolt | 0.4.0 | 0.6.0 | 0.6.2 (pending) | 272/272 | pass |
| localbolt-app | 0.4.0 | 0.6.0 | 0.6.2 (pending) | N/A | pass |
| localbolt-v3 | 0.4.0 | 0.6.0 | 0.6.2 (pending) | 4/4 | pass |

---

## SUMMARY

- **Total findings:** 60 (41 prior + 19 SA-series)
- **DONE / DONE-VERIFIED:** 33
- **CODIFIED:** 12 (O1–O12, PROTO-HARDEN-1 — spec-level, implementation audit pending)
- **CLOSED-NO-BUG:** 1 (I6)
- **DONE-BY-DESIGN:** 1 (SA11)
- **IN-PROGRESS:** 0
- **DEFERRED:** 2 (I4, Q4)
- **OPEN (SA-series):** 11 (SA1, SA4–SA6, SA10, SA13–SA18)
- **Residual risk:** See `bolt-core-sdk/docs/SECURITY_POSTURE.md` and SA-series below

---

## PROTOCOL HARDENING OBSERVATIONS (PROTO-HARDEN-1)

Observations identified during PROTO-HARDEN-1 governance phase. Each maps to
a numbered invariant in PROTOCOL.md §15. Implementation audit is pending —
these are spec-level codifications, not runtime fixes.

| ID | Observation | Invariant | Severity | Status | Resolution |
|----|------------|-----------|----------|--------|------------|
| O1 | HELLO keying model (ephemeral-first vs identity-first) not explicitly defined | PROTO-HARDEN-01 | MEDIUM | **CODIFIED** | §15.1 formalizes ephemeral-first model |
| O2 | No explicit requirement that identity_key must be inside an envelope-authenticated payload | PROTO-HARDEN-01 | MEDIUM | **CODIFIED** | §15.2 Mechanism 1: envelope MAC authenticates identity_key |
| O3 | SAS computation inputs not explicitly bound to the specific HELLO/envelope that carried them | PROTO-HARDEN-02 | MEDIUM | **CODIFIED** | §15.2 Mechanism 2: SAS must use exact keys from the session |
| O4 | Error registry split across PROTOCOL.md §10 (11 codes) and PROTOCOL_ENFORCEMENT.md Appendix A (14 codes) | PROTO-HARDEN-03, 04 | LOW | **SPEC-UNIFIED** | PROTO-HARDEN-1R1: §10 now contains unified 22-code registry (11 PROTOCOL + 11 ENFORCEMENT). Appendix A is non-normative back-reference. `v0.1.3-spec` (`6a6de3f`). |
| O5 | No explicit requirement for error code parity between Rust and TypeScript implementations | PROTO-HARDEN-05 | MEDIUM | **CODIFIED** | §15.3 requires identical error code strings for identical violations |
| O6 | Post-handshake plaintext ERROR messages permitted by PROTOCOL_ENFORCEMENT.md §6 | PROTO-HARDEN-06, 07 | MEDIUM | **CODIFIED** | §15.4 restricts plaintext errors to terminal disconnect frames only |
| O7 | No explicit prohibition of plaintext ERROR during normal envelope-required operation | PROTO-HARDEN-07 | MEDIUM | **CODIFIED** | §15.4 PROTO-HARDEN-07: plaintext error exception is disconnect-only |
| O8 | HELLO state machine not formally defined (exactly-once scattered across §3, §13) | PROTO-HARDEN-08, 09 | MEDIUM | **CODIFIED** | §15.5 defines explicit four-state machine |
| O9 | No explicit reentrancy guard for concurrent HELLO processing | PROTO-HARDEN-11 | MEDIUM | **CODIFIED** | §15.5 PROTO-HARDEN-11: HELLO processing must be serialized |
| O10 | No explicit "handshake complete" predicate definition | PROTO-HARDEN-09 | LOW | **CODIFIED** | §15.5 PROTO-HARDEN-09: transition to HANDSHAKE_COMPLETE is exactly-once |
| O11 | Capability negotiation mutability not explicitly prohibited after handshake | PROTO-HARDEN-12 | MEDIUM | **CODIFIED** | §15.5 PROTO-HARDEN-12: capabilities immutable after HANDSHAKE_COMPLETE |
| O12 | HELLO send atomicity not specified (could a peer send partial HELLO then another) | PROTO-HARDEN-08 | LOW | **CODIFIED** | §15.5 PROTO-HARDEN-08: HELLO_SENT transition is atomic |

**Summary:** 12 observations, all CODIFIED in PROTOCOL.md §15. Implementation audit to verify
conformance is the next phase (not in PROTO-HARDEN-1 scope).

---

## PROTOCOL HARDENING (H-phases)

| ID | Phase | Description | Status | Evidence |
|----|-------|-------------|--------|----------|
| H0 | Protocol enforcement posture | Normative enforcement doc: exactly-once HELLO, envelope-required, fail-closed, error registry, downgrade resistance | **DONE** | `bolt-ecosystem/docs/PROTOCOL_ENFORCEMENT.md`. Informational only (ecosystem root is not a git repo). |
| H1 | Signal server hardening | Trust-boundary hardening in localbolt-v3 signal server | **IMPLEMENTED** | `v3.0.59-signal-hardening` (`ac5110c`). On `feature/h1-signal-hardening`, **not merged to main**. |
| H2 | WebRTC enforcement compliance | Exactly-once HELLO, envelope-required, fail-closed in WebRTCService | **MERGED** | Originally `sdk-v0.5.0-h2-webrtc-enforcement` (`b4ce544`). 21 enforcement tests. Merged to main via subsequent phases. |
| H3 | Cross-implementation golden vectors | SAS, HELLO-open, envelope-open deterministic vectors across TS, Rust SDK, daemon | **MERGED (daemon)** | Daemon: `daemon-v0.2.5-h3-golden-vectors` (`3751118`), merged to main via `0b16392`. SDK TS vectors: on feature branch, not yet on main. |
| H4 | Daemon unwrap hardening | Error code enforcement in daemon decode paths | NOT STARTED | — |
| H5 | TOFU/SAS wiring in localbolt-v3 | Wire TOFU + SAS into product UI | NOT STARTED | — |
| H6 | CI/coverage enforcement | Golden vector and enforcement tests as CI gates | NOT STARTED | — |

---

## SECURITY AUDIT — 2026-02-26 (SA-series)

Findings from the 2026-02-26 read-only security audit of bolt-core-sdk (Rust + TS),
bolt-daemon, and bolt-transport-web. Imported as SA-series to avoid collision with
O1–O12 (PROTO-HARDEN-1 observations above).

**Canonical audit source:** [`docs/AUDITS/2026-02-26-security-audit.md`](AUDITS/2026-02-26-security-audit.md)
**Execution bindings:** [`docs/AUDITS/2026-02-26-execution-bindings.md`](AUDITS/2026-02-26-execution-bindings.md) (AUDIT-GOV-2 — per-finding contracts)

### Tracks

- PROTOCOL: wire semantics, handshake, capability semantics
- LIFECYCLE: resource teardown, listeners, object lifetime, disconnect correctness
- MEMORY: zeroization, secret lifetime, key handling
- TRANSPORT: timeouts, bounds, backpressure, framing transport behaviors
- GOVERNANCE: docs, conformance, tag discipline, process controls

### Evidence Ladder

| Severity | Minimum for DONE-VERIFIED |
|----------|---------------------------|
| HIGH | INTEROP + at least one ADVERSARIAL test |
| MEDIUM | UNIT + at least one ADVERSARIAL or INTEROP |
| LOW | UNIT or documented rationale (DONE-BY-DESIGN) |

### HIGH Severity

| SA_ID | Summary | Track | Status | Phase | Evidence |
|-------|---------|-------|--------|-------|----------|
| SA1 | Daemon conflates identity and ephemeral into single per-connection keypair; same key used for signaling `publicKey` and HELLO `identityPublicKey`, leaking identity role via signaling and making TOFU pinning meaningless; violates PROTOCOL.md §15.1 separation and `identity.rs` constraint (`rendezvous.rs:579`, `web_hello.rs:187`) | PROTOCOL | **OPEN** | TBD | — |
| SA2 | Web client accepted any inbound error code without registry validation (`WebRTCService.ts:849-853`) | PROTOCOL | **DONE-VERIFIED** | PROTO-HARDEN-2A | `sdk-v0.5.7-proto-harden-2a` (`5759164`). `WIRE_ERROR_CODES` 22-entry registry + `isValidWireErrorCode()` guard. Inbound validation rejects unknown/malformed codes. 11 new transport-web tests (7 enveloped + 2 plaintext + 2 outbound guard). ADVERSARIAL: unknown code, missing code, non-string code, empty code, non-string message all tested. |
| SA3 | Daemon `CANONICAL_ERROR_CODES` had 8/22 codes; 14 valid codes rejected as PROTOCOL_VIOLATION (`envelope.rs:131-140`) | PROTOCOL | **DONE-VERIFIED** | PROTO-HARDEN-2A | `daemon-v0.2.13-proto-harden-2a` (`f88a78b`). Expanded to 22 entries matching PROTOCOL.md §10. +8 daemon tests including per-code acceptance for all 22. INTEROP: both registries now identical. ADVERSARIAL: unknown code rejection preserved. |

### MEDIUM Severity

| SA_ID | Summary | Track | Status | Phase | Evidence |
|-------|---------|-------|--------|-------|----------|
| SA4 | Rust `KeyPair` has no `Drop`/`zeroize`; secret key persists in memory (`crypto.rs:22-28`) | MEMORY | **OPEN** | TBD | — |
| SA5 | `PeerConnection` leaked on `handleOffer` error; `disconnect()` not called (`WebRTCService.ts:195-198`) | LIFECYCLE | **OPEN** | TBD | — |
| SA6 | Signaling listener never unregistered; no `offSignal()` in `SignalingProvider` (`WebRTCService.ts:165`) | LIFECYCLE | **OPEN** | TBD | — |
| SA7 | `remoteIdentityKey` set to null without `fill(0)` on disconnect (`WebRTCService.ts:667`) | MEMORY | **DONE-VERIFIED** | MEMORY-HARDEN-1A | `sdk-v0.5.9-memory-harden-1a` (`5821e65`). `remoteIdentityKey.fill(0)` before null assignment in `disconnect()`. Guard: `instanceof Uint8Array`. 6 tests in `sa7-sa19-key-zeroization.test.ts`. |
| SA8 | Daemon sent plaintext errors post-handshake; web's ENVELOPE_REQUIRED guard rejected them | PROTOCOL | **DONE-VERIFIED** | I5 (interop-error-framing) | `daemon-v0.2.11-interop-error-framing` (`600fef4`): `build_error_payload()` wraps in envelope when negotiated. `transport-web-v0.6.2-interop-error-framing` (`e463e1a`): web sends + accepts enveloped errors. +4 daemon tests, +5 web tests. INTEROP: both sides envelope-aware. ADVERSARIAL: plaintext-in-envelope-mode rejected. |
| SA9 | `routeInnerMessage` silently drops non-file-chunk types in legacy plaintext path (`WebRTCService.ts:882`) | PROTOCOL | **DONE-VERIFIED** | PROTO-CORRECTNESS-2 | PROTO-HARDEN-2A added plaintext `type:'error'` handler/validation groundwork. PROTO-CORRECTNESS-2 (`sdk-v0.5.8-proto-correctness-2`, `01e76e4`) completed the fix: unknown/missing/empty type → `UNKNOWN_MESSAGE_TYPE` + disconnect; malformed file-chunk (missing/empty filename) → `INVALID_MESSAGE` + disconnect. Enforcement at legacy plaintext call site before `routeInnerMessage`. 3 UNIT + 3 ADVERSARIAL tests in `sa9-legacy-plaintext-drops.test.ts`. |
| SA10 | HELLO timeout silently downgrades to unauthenticated legacy mode after 5s (`WebRTCService.ts:433-446`) | TRANSPORT | **OPEN** | TBD | — |
| SA11 | Identity key not cryptographically bound to ephemeral key in HELLO | PROTOCOL | **DONE-BY-DESIGN** | N/A (spec) | PROTOCOL.md §3 defines SAS computation binding identity + ephemeral keys via `SHA-256(sort32(identity_A, identity_B) \|\| sort32(ephemeral_A, ephemeral_B))`. §15.2 documents this as the v1 mitigation. v2 may add transcript hash binding. Accepted design. |
| SA12 | Async race: `processHello()` invoked without synchronous guard; concurrent execution possible (`WebRTCService.ts:803`) | PROTOCOL | **DONE-VERIFIED** | PROTO-CORRECTNESS-2 | `sdk-v0.5.8-proto-correctness-2` (`01e76e4`). Synchronous `helloProcessing` guard set before first `await` in `processHello()`. Concurrent entry rejected with `DUPLICATE_HELLO` + disconnect. Guard reset in `disconnect()` for clean new-session semantics. 2 UNIT + 2 ADVERSARIAL tests in `sa12-hello-reentrancy.test.ts`. |

### LOW Severity

| SA_ID | Summary | Track | Status | Phase | Evidence |
|-------|---------|-------|--------|-------|----------|
| SA13 | DC handlers not nulled before `dc.close()` (`WebRTCService.ts:629-632`) | LIFECYCLE | **OPEN** | TBD | — |
| SA14 | `helloTimeout` stale callback race; no session generation counter | LIFECYCLE | **OPEN** | TBD | — |
| SA15 | `bolt.file-hash` missing from `DAEMON_CAPABILITIES` (`web_hello.rs:36`) | TRANSPORT | **OPEN** | TBD | — |
| SA16 | TLS stream silently skips `set_read_timeout` (`rendezvous.rs:171-175`) | TRANSPORT | **OPEN** | TBD | — |
| SA17 | No max length enforced on remote capabilities array in HELLO | TRANSPORT | **OPEN** | TBD | — |
| SA18 | `decodeProfileEnvelopeV1()` dead code returns null instead of throwing (`WebRTCService.ts:1215-1226`) | GOVERNANCE | **OPEN** | TBD | — |
| SA19 | `remotePublicKey` set to null without `fill(0)` on disconnect (`WebRTCService.ts:642`) | MEMORY | **DONE-VERIFIED** | MEMORY-HARDEN-1A | `sdk-v0.5.9-memory-harden-1a` (`5821e65`). `remotePublicKey.fill(0)` before null assignment in `disconnect()`. Guard: `instanceof Uint8Array`. 6 tests in `sa7-sa19-key-zeroization.test.ts`. |

### SA-series Summary

| Severity | Total | Resolved | Open |
|----------|-------|----------|------|
| HIGH | 3 | 2 (SA2, SA3) | 1 (SA1) |
| MEDIUM | 9 | 5 (SA7, SA8, SA9, SA11 by-design, SA12) | 4 (SA4–SA6, SA10) |
| LOW | 7 | 1 (SA19) | 6 (SA13–SA18) |
| **Total** | **19** | **8** | **11** |
