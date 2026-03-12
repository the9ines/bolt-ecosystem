# Bolt Ecosystem Audit Tracker

> **Canonical Location:** `bolt-ecosystem/docs/AUDIT_TRACKER.md`
> This is the single authoritative audit tracker for all repos under the9ines/bolt-ecosystem.
> Relocated from `bolt-core-sdk/docs/AUDIT_TRACKER.md` on 2026-02-26 (DOC-GOV-2).

**Last updated:** 2026-03-11 (CBTR-F1 FIXED — sdk-v0.5.40-cbtr-f1-receiver-pause)
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
| Q4 | localbolt-app test coverage | LOW | **DONE-VERIFIED** | 11 tests (2 test files), coverage thresholds enforced (90/90/80/90 lines/functions/branches/statements). `@vitest/coverage-v8` installed, `test:coverage` script added, CI wired to `npm run test:coverage`. Coverage baseline: 100% on tested files (identity.ts). Ratchet prevents regression. |
| Q5 | localbolt-v3 test pipeline | MEDIUM | **DONE** | 4 smoke tests (FAQ + app render). Phase TP: `v3.0.53-test-pipeline`. CI step before build. |
| Q6 | localbolt-v3 coverage thresholds | MEDIUM | **DONE** | `@vitest/coverage-v8`, thresholds 45/5/31/48%. Phase Q6: `v3.0.55-coverage-thresholds`. |
| Q7 | Disconnect/reconnect stale callback races causing incorrect UI/session state | MEDIUM | **DONE-VERIFIED** | C7 closed. Generation-guarded stale callback rejection wired in all three consumers. Canonical session state machine (5-phase, `@the9ines/localbolt-core`) with generation counter incremented on every `resetSession()`. Evidence: (1) rapid 7-cycle connect/reset proving generation monotonicity + state cleanliness (`session-hardening.test.ts`, `v3.0.74-c7-closure`), (2) late verification callback from session A rejected after reset into session B, (3) A→B→C session isolation with no state leakage, (4) stale accepted signal after cancel, (5) phase guards rejecting invalid transitions (5 tests), (6) transfer progress + verification state cleared on reset. Consumer wiring: localbolt 300 tests (generation guard race hardening suite), localbolt-app 11 tests (`tofu-integration.test.ts:161` stale callback guard). |
| Q8 | Verification policy mismatch between runtime behavior and tests/docs | MEDIUM | **DONE-VERIFIED** | C0 resolved: PM policy decision locked — `unverified` blocks file transfer. Codified in `v3.0.70-session-hardening-cpre2` (`cac5e4a`). Runtime behavior, test expectations, and documentation now consistent. |
| Q9 | App-layer behavior drift across localbolt-v3, localbolt, localbolt-app | MEDIUM | **DONE-VERIFIED** | C2–C5 resolved: all three consumers now depend on `@the9ines/localbolt-core@0.1.0`. Canonical extraction baseline: session state machine, verification state bus, transfer gating policy. Tags: `v3.0.71-localbolt-core-c2`, `localbolt-v1.0.21-c4-localbolt-core`, `localbolt-app-v1.2.4-c5-localbolt-core`. |
| Q10 | Missing app-layer drift guards (transport guarded, app layer not guarded) | MEDIUM | **DONE-VERIFIED** | C6 complete: CI-enforced core guard scripts (version-pin, single-install, drift) active in localbolt and localbolt-app. `upgrade-localbolt-core.sh` (check + write modes) added to both consumers. localbolt-v3 core drift guard added to CI (`packages/localbolt-web/src`). Workspace exemption documented (v3 is origin workspace — pin/single-install not applicable). Manual drift validation runbook in `docs/LOCALBOLT_CORE_DRIFT_RUNBOOK.md`. |
| Q11 | Mid-transfer disconnect → reconnect → new transfer stuck (RECON-XFER-1) | HIGH | **DONE-VERIFIED (evidence tail: RX-EVID-1)** | Phase A: root cause locked to localbolt-v3 consumer orchestration (RC-1: stale `serviceGeneration`, RC-2: one-shot service reuse). Fix: `createFreshRtcService()` factory + generation guards. SDK: 8 one-shot contract tests (`sdk-v0.5.35-recon-xfer1-phase-a-tests`). localbolt-v3: 16 regression tests (`v3.0.88-recon-xfer1-phase-a`). Phase B: localbolt (`localbolt-v1.0.35-recon-xfer1-phase-b`) and localbolt-app (`localbolt-app-v1.2.23-recon-xfer1-phase-b`) verified — no code changes needed. Both protected by shared `@the9ines/localbolt-core` generation guard pattern (19 + 21 security-session-integrity tests). localbolt-app Tauri IPC bridge lifecycle also clean (Mutex writer, reader thread lifecycle, no cached refs). AC-RX-01 through AC-RX-07 satisfied. AC-RX-08: automated gate PASS (WASM + fallback build/test parity); manual runtime evidence PENDING (see RX-EVID-1). |
| RX-EVID-1 | RECON-XFER-1 manual runtime evidence tail — WASM/fallback transfer verification | LOW | **OPEN** | Docs-only closeout. All code work closed (Phase A + B). Required evidence per consumer (localbolt, localbolt-app, localbolt-v3): (1) one WASM-mode runtime transfer, (2) one forced-fallback-mode runtime transfer, (3) pause/resume/cancel sanity after reconnect. No code changes expected — record results and close. |

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

Product repos on main are pinned to published SDK releases.

| Repo | bolt-core | transport-web (pinned) | transport-web (latest) | Tests | Build |
|------|-----------|------------------------|------------------------|-------|-------|
| localbolt | 0.5.0 | 0.6.2 | 0.6.2 | 300 | pass |
| localbolt-app | 0.5.0 | 0.6.2 | 0.6.2 | 11 | pass |
| localbolt-v3 | 0.5.0 | 0.6.2 | 0.6.2 | 59 | pass |

---

## D-STREAM (CI Stabilization + Package Auth Migration)

> **Codified:** 2026-03-05 (D-STREAM-1 codification)
> **Status:** Placeholder section — no concrete findings until D1 triage completes.
> **Rule:** D-stream placeholder entries do NOT increment total findings. Total remains 110 until D1 produces concrete new findings.

| ID | Finding | Severity | Status | Evidence |
|----|---------|----------|--------|----------|
| D1 | CI failure triage (placeholder — awaiting D1 execution) | TBD | NOT-STARTED | Collection window: last 20 failed CI runs or 14 days per in-scope repo |

> **Note:** D1 is a triage/discovery phase. Concrete findings will be registered with severity and evidence after D1 completes. Each concrete finding will increment the total at that time.

---

## S-STREAM-R1 (Security/Foundation Recovery) — R1-1 Dispositions Locked

> **Codified:** ecosystem-v0.1.65-s-stream-r1-codify (2026-03-06)
> **R1-1:** ecosystem-v0.1.67-s-stream-r1-r1.1-disposition (2026-03-06)
> **Status:** No new findings registered. SA1 Path C confirmed (closure stands). R1-2/R1-3 DONE-NO-ACTION.
> **Rule:** S-STREAM-R1 placeholder does NOT increment total findings. Total remains 110. R1-4 may register findings if evidence warrants.

| ID | Finding | Severity | Status | Evidence |
|----|---------|----------|--------|----------|
| (reserved) | R1-F series — available for R1-4 if needed | TBD | NOT-STARTED | No findings registered in R1-0/R1-1. R1-4 may register if evidence warrants. |

> **SA1 disposition (R1-1, Path C):** SA1 DONE-VERIFIED status confirmed. R1-0 evidence shows daemon key-role separation is complete (identity persistent/TOFU-only, ephemeral per-session/crypto-only, 22 tests, zero ambiguous usage). No new finding registered (Path A not needed). No SA1 reopen (Path B not needed). Decision recorded in `GOVERNANCE_WORKSTREAMS.md` §R1-1 Disposition Decisions.

---

## SUMMARY

- **Total findings:** 112 (41 prior + 19 SA-series + 11 N-series + 25 AC-series + 9 DP-series + 1 NF-series + 5 Q-series + 1 RX-EVID)
- **DONE / DONE-VERIFIED:** 91 (+Q11 RECON-XFER-1)
- **CODIFIED:** 12 (O1–O12, PROTO-HARDEN-1 — spec-level, implementation audit pending)
- **CLOSED-NO-BUG:** 1 (I6)
- **DONE-BY-DESIGN:** 6 (SA11, SA15, N9, AC-23, AC-24, AC-25)
- **IN-PROGRESS:** 0
- **DEFERRED:** 1 (I4)
- **OPEN:** 1 (RX-EVID-1 — manual runtime evidence tail, LOW, docs-only)
- **Residual risk:** See `bolt-core-sdk/docs/SECURITY_POSTURE.md`.

> **OPEN (global)** = all findings across all series with Status = OPEN.
> Does not include IN-PROGRESS, PARTIAL, DEFERRED, CODIFIED, CLOSED-NO-BUG, or DONE-BY-DESIGN.

Arithmetic reconciled in ecosystem-v0.1.19-audit-gov-16 — 25 AC-series findings registered. OPEN = 22 (AC-1 through AC-22). DONE-BY-DESIGN = 6 (+3 AC-series).

Arithmetic reconciled in ecosystem-v0.1.20-audit-gov-17 — AC-1 and AC-2 promoted to DONE-VERIFIED. DONE/DONE-VERIFIED 53 → 55. OPEN 22 → 20. Total findings remain 96.

Arithmetic reconciled in ecosystem-v0.1.21-audit-gov-18 — AC-3 promoted to DONE-VERIFIED. DONE/DONE-VERIFIED 55 → 56. OPEN 20 → 19. Total findings remain 96.

Arithmetic reconciled in ecosystem-v0.1.22-audit-gov-19 — AC-14 promoted to DONE-VERIFIED. DONE/DONE-VERIFIED 56 → 57. OPEN 19 → 18. Total findings remain 96.

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
| SA1 | Daemon conflates identity and ephemeral into single per-connection keypair; same key used for signaling `publicKey` and HELLO `identityPublicKey`, leaking identity role via signaling and making TOFU pinning meaningless; violates PROTOCOL.md §15.1 separation and `identity.rs` constraint (`rendezvous.rs:579`, `web_hello.rs:187`) | PROTOCOL | **DONE-VERIFIED** | DAEMON-IDENTITY-SEPARATION-1 | Phase A — `daemon-v0.2.14-daemon-identity-persist-1` (`6625e23`). Phase B — `daemon-v0.2.15-daemon-identity-separation-1` (`255ff5d`). Ephemeral vs persistent role separation verified by 12 separation tests. |
| SA2 | Web client accepted any inbound error code without registry validation (`WebRTCService.ts:849-853`) | PROTOCOL | **DONE-VERIFIED** | PROTO-HARDEN-2A | `sdk-v0.5.7-proto-harden-2a` (`5759164`). `WIRE_ERROR_CODES` 22-entry registry + `isValidWireErrorCode()` guard. Inbound validation rejects unknown/malformed codes. 11 new transport-web tests (7 enveloped + 2 plaintext + 2 outbound guard). ADVERSARIAL: unknown code, missing code, non-string code, empty code, non-string message all tested. |
| SA3 | Daemon `CANONICAL_ERROR_CODES` had 8/22 codes; 14 valid codes rejected as PROTOCOL_VIOLATION (`envelope.rs:131-140`) | PROTOCOL | **DONE-VERIFIED** | PROTO-HARDEN-2A | `daemon-v0.2.13-proto-harden-2a` (`f88a78b`). Expanded to 22 entries matching PROTOCOL.md §10. +8 daemon tests including per-code acceptance for all 22. INTEROP: both registries now identical. ADVERSARIAL: unknown code rejection preserved. |

### MEDIUM Severity

| SA_ID | Summary | Track | Status | Phase | Evidence |
|-------|---------|-------|--------|-------|----------|
| SA4 | Rust `KeyPair` has no `Drop`/`zeroize`; secret key persists in memory (`crypto.rs:22-28`) | MEMORY | **DONE-VERIFIED** | MEMORY-HARDEN-1B | `sdk-v0.5.10-memory-harden-1b` (`781997d`). `impl Drop for KeyPair` with `write_volatile` per byte of `secret_key` + `compiler_fence(SeqCst)`. Tests: `keypair_drop_zeroizes_secret` (heap-drop proof via `read_volatile`), `keypair_drop_zeros_safe`. Note: daemon has one `clone()` site extending secret lifetime; out-of-scope optimization, not a blocker. |
| SA5 | `PeerConnection` leaked on `handleOffer` error; `disconnect()` not called (`WebRTCService.ts:195-198`) | LIFECYCLE | **DONE-VERIFIED** | LIFECYCLE-HARDEN-1 | `sdk-v0.5.11-lifecycle-harden-1` (`1962891`). `handleSignal()` catch block calls `disconnect()` before `onError()`. `createPeerConnection()` nulls `this.pc` after closing old connection. 3 tests (1 UNIT: disconnect-before-onError ordering, 1 UNIT: idempotent double-call, 1 ADVERSARIAL: throw-with-no-pc). |
| SA6 | Signaling listener never unregistered; no `offSignal()` in `SignalingProvider` (`WebRTCService.ts:165`) | LIFECYCLE | **DONE-VERIFIED** | LIFECYCLE-HARDEN-1 | `sdk-v0.5.11-lifecycle-harden-1` (`1962891`). `SignalingProvider.onSignal()` returns unsubscribe function. WebSocketSignaling + DualSignaling return closures splicing callback from array (idempotent). WebRTCService stores handle, invokes early in `disconnect()`. 5 tests (1 UNIT: unsubscribe invoked, 1 UNIT: post-disconnect emission blocked, 1 ADVERSARIAL: reconnect dedup, 2 signaling unit). |
| SA7 | `remoteIdentityKey` set to null without `fill(0)` on disconnect (`WebRTCService.ts:667`) | MEMORY | **DONE-VERIFIED** | MEMORY-HARDEN-1A | `sdk-v0.5.9-memory-harden-1a` (`5821e65`). `remoteIdentityKey.fill(0)` before null assignment in `disconnect()`. Guard: `instanceof Uint8Array`. 6 tests in `sa7-sa19-key-zeroization.test.ts`. |
| SA8 | Daemon sent plaintext errors post-handshake; web's ENVELOPE_REQUIRED guard rejected them | PROTOCOL | **DONE-VERIFIED** | I5 (interop-error-framing) | `daemon-v0.2.11-interop-error-framing` (`600fef4`): `build_error_payload()` wraps in envelope when negotiated. `transport-web-v0.6.2-interop-error-framing` (`e463e1a`): web sends + accepts enveloped errors. +4 daemon tests, +5 web tests. INTEROP: both sides envelope-aware. ADVERSARIAL: plaintext-in-envelope-mode rejected. |
| SA9 | `routeInnerMessage` silently drops non-file-chunk types in legacy plaintext path (`WebRTCService.ts:882`) | PROTOCOL | **DONE-VERIFIED** | PROTO-CORRECTNESS-2 | PROTO-HARDEN-2A added plaintext `type:'error'` handler/validation groundwork. PROTO-CORRECTNESS-2 (`sdk-v0.5.8-proto-correctness-2`, `01e76e4`) completed the fix: unknown/missing/empty type → `UNKNOWN_MESSAGE_TYPE` + disconnect; malformed file-chunk (missing/empty filename) → `INVALID_MESSAGE` + disconnect. Enforcement at legacy plaintext call site before `routeInnerMessage`. 3 UNIT + 3 ADVERSARIAL tests in `sa9-legacy-plaintext-drops.test.ts`. |
| SA10 | HELLO timeout silently downgrades to unauthenticated legacy mode after 5s (`WebRTCService.ts:433-446`) | TRANSPORT | **DONE-VERIFIED** | TRANSPORT-HARDEN-2 | `sdk-v0.5.12-transport-harden-2` (`ad8cd3c`). HELLO timeout fails closed: disconnect + `onError` callback; no legacy downgrade when identity configured. `WebRTCService.ts` modification. 3 tests in `sa10-hello-timeout-downgrade.test.ts`. ADVERSARIAL: timeout with identity → disconnect, no silent fallback. Final transport-web: 199 tests. |
| SA11 | Identity key not cryptographically bound to ephemeral key in HELLO | PROTOCOL | **DONE-BY-DESIGN** | N/A (spec) | PROTOCOL.md §3 defines SAS computation binding identity + ephemeral keys via `SHA-256(sort32(identity_A, identity_B) \|\| sort32(ephemeral_A, ephemeral_B))`. §15.2 documents this as the v1 mitigation. v2 may add transcript hash binding. Accepted design. |
| SA12 | Async race: `processHello()` invoked without synchronous guard; concurrent execution possible (`WebRTCService.ts:803`) | PROTOCOL | **DONE-VERIFIED** | PROTO-CORRECTNESS-2 | `sdk-v0.5.8-proto-correctness-2` (`01e76e4`). Synchronous `helloProcessing` guard set before first `await` in `processHello()`. Concurrent entry rejected with `DUPLICATE_HELLO` + disconnect. Guard reset in `disconnect()` for clean new-session semantics. 2 UNIT + 2 ADVERSARIAL tests in `sa12-hello-reentrancy.test.ts`. |

### LOW Severity

| SA_ID | Summary | Track | Status | Phase | Evidence |
|-------|---------|-------|--------|-------|----------|
| SA13 | DC handlers not nulled before `dc.close()` (`WebRTCService.ts:629-632`) | LIFECYCLE | **DONE-VERIFIED** | SA-LOW-SWEEP-1 | `transport-web-v0.6.4-low-sa-sweep-1`. DC event handlers (`onopen`, `onclose`, `onerror`, `onmessage`) nulled before `dc.close()`. 1 UNIT test. |
| SA14 | `helloTimeout` stale callback race; no session generation counter | LIFECYCLE | **DONE-VERIFIED** | SA-LOW-SWEEP-1 | `transport-web-v0.6.4-low-sa-sweep-1`. Session generation counter incremented on connect/disconnect; stale timeout callbacks rejected. 1 UNIT test. |
| SA15 | `bolt.file-hash` missing from `DAEMON_CAPABILITIES` (`web_hello.rs:36`) | TRANSPORT | **DONE-BY-DESIGN** | SA-LOW-SWEEP-1 | Daemon does not implement file transfer; advertising `bolt.file-hash` would be misleading. Capability will be added when daemon gains transfer support. Documented rationale. |
| SA16 | TLS stream silently skips `set_read_timeout` (`rendezvous.rs:171-175`) | TRANSPORT | **DONE-VERIFIED** | SA-LOW-SWEEP-1 | `daemon-v0.2.16-low-sa-sweep-1`. TLS streams now receive `set_read_timeout` with same duration as plaintext. 1 UNIT test. |
| SA17 | No max length enforced on remote capabilities array in HELLO | TRANSPORT | **DONE-VERIFIED** | SA-LOW-SWEEP-1 | `daemon-v0.2.16-low-sa-sweep-1`. `MAX_CAPABILITIES_COUNT` (32) enforced during HELLO parsing; oversized arrays rejected with `INVALID_HELLO`. 1 UNIT test. |
| SA18 | `decodeProfileEnvelopeV1()` dead code returns null instead of throwing (`WebRTCService.ts:1215-1226`) | GOVERNANCE | **DONE-VERIFIED** | SA-LOW-SWEEP-1 | `transport-web-v0.6.4-low-sa-sweep-1`. Dead code null-return replaced with throw. 1 UNIT test. |
| SA19 | `remotePublicKey` set to null without `fill(0)` on disconnect (`WebRTCService.ts:642`) | MEMORY | **DONE-VERIFIED** | MEMORY-HARDEN-1A | `sdk-v0.5.9-memory-harden-1a` (`5821e65`). `remotePublicKey.fill(0)` before null assignment in `disconnect()`. Guard: `instanceof Uint8Array`. 6 tests in `sa7-sa19-key-zeroization.test.ts`. |

### SA-series Summary

| Severity | Total | Resolved | Open |
|----------|-------|----------|------|
| HIGH | 3 | 3 (SA1, SA2, SA3) | 0 |
| MEDIUM | 9 | 9 (SA4–SA6, SA7, SA8, SA9, SA10, SA11 by-design, SA12) | 0 |
| LOW | 7 | 7 (SA13, SA14, SA15 by-design, SA16, SA17, SA18, SA19) | 0 |
| **Total** | **19** | **19** | **0** |

---

## SECURITY AUDIT — 2026-02-28 (N-series)

Findings from the 2026-02-28 read-only security audit of bolt-core-sdk (Rust + TS),
bolt-daemon, and bolt-transport-web. Registered as N-series to avoid collision with
SA-series (2026-02-26) and O-series (PROTO-HARDEN-1).

**Canonical audit source:** [`docs/AUDITS/2026-02-28-security-audit.md`](AUDITS/2026-02-28-security-audit.md)

### Tracks

- PROTOCOL: wire semantics, handshake, capability semantics
- LIFECYCLE: resource teardown, listeners, object lifetime, disconnect correctness
- MEMORY: zeroization, secret lifetime, key handling
- TRANSPORT: timeouts, bounds, backpressure, framing transport behaviors
- GOVERNANCE: docs, conformance, tag discipline, process controls

### HIGH Severity

| N_ID | Summary | Track | Status | Phase | Evidence |
|------|---------|-------|--------|-------|----------|
| N1 | `onbufferedamountlow` not nulled in `disconnect()` — backpressure await may suspend permanently. Related to SA13 handler-null fix; missed `onbufferedamountlow` in same block. Component: `WebRTCService.ts` | LIFECYCLE | **DONE-VERIFIED** | TRANSPORT-HARDEN-3 | `transport-web-v0.6.5-transport-harden-3` (`459d682`). |

### MEDIUM Severity

| N_ID | Summary | Track | Status | Phase | Evidence |
|------|---------|-------|--------|-------|----------|
| N2 | `helloProcessing` never reset after success/error — reconnect blocked | LIFECYCLE | **DONE-VERIFIED** | TRANSPORT-HARDEN-5 | `transport-web-v0.6.7-transport-harden-5` (`677926e`). |
| N3 | `SignalingProvider.onSignal` return type allows void — listener may be unregisterable | LIFECYCLE | **DONE-VERIFIED** | TYPE-SURFACE-HARDEN-1 | `sdk-v0.5.13-type-surface-harden-1` (`5dc2d12`). Tightens `SignalingProvider.onSignal` return type to `() => void`, resolving the unregisterable-listener contract issue. |
| N4 | `KeyPair` derives `Clone` — secret key silently duplicable | MEMORY | **DONE-VERIFIED** | MEMORY-HARDEN-2 | `sdk-v0.5.14-memory-harden-2` (`903b63f`): removed `#[derive(Clone)]` from KeyPair. `daemon-v0.2.17-memory-harden-2` (`3155793`): refactored 2 production + 7 test clone sites to ownership-move via `.take()`. |
| N5 | Envelope-v1 not enforced unilaterally — downgrade possible | PROTOCOL | **DONE-VERIFIED** | TRANSPORT-HARDEN-4 | `transport-web-v0.6.6-transport-harden-4` (`6748a0a`). |
| N6 | Daemon answerer pre-HELLO failure exits silently without typed error | PROTOCOL | **DONE-VERIFIED** | PROTOCOL-HARDEN-4 | `daemon-v0.2.18-protocol-harden-4` (`0b9933f`). `parse_hello_message` replaced with `parse_hello_typed`; typed plaintext error sent via `build_error_payload(e.code(), ...)` before disconnect. No wire changes. |
| N7 | Answerer does not wire `HelloState` into DC HELLO path — exactly-once structural only | PROTOCOL | **DONE-VERIFIED** | PROTOCOL-HARDEN-4 | `daemon-v0.2.18-protocol-harden-4` (`0b9933f`). Explicit `HelloState::new()` + `mark_completed()` guard wired into answerer DC HELLO path. Struct/API unchanged. |

### LOW Severity

| N_ID | Summary | Track | Status | Phase | Evidence |
|------|---------|-------|--------|-------|----------|
| N8 | No per-capability string length bound | TRANSPORT | **DONE-VERIFIED** | LOW-N8 | `daemon-v0.2.19-low-n8` (`8683cbc`): 64-byte per-capability string length bound enforced in daemon HELLO parsing. `transport-web-v0.6.9-n8-caplen-1` (`ded0a40`): matching 64-byte bound enforced in web HELLO parsing. Both implementations reject oversized capability strings. |
| N9 | No cross-language golden vector test (TS seal → Rust open) | GOVERNANCE | **DONE-BY-DESIGN** | N/A | Existing H3 golden vectors already prove TS seal → Rust open (daemon + SDK vector suites, 12/12 cross-implementation). Auditor closed N9 based on existing evidence without requiring reverse-direction vectors. No runtime change required. |
| N10 | Completion `setTimeout` not cancellable by `disconnect()` | LIFECYCLE | **DONE-VERIFIED** | LOW-N10 | `transport-web-v0.6.8-low-n10` (`7f0bbaa`): completion `setTimeout` handle stored and cleared in `disconnect()`. Prevents stale callback execution after teardown. |
| N11 | TS `openBoxPayload` missing explicit length guard before nonce slice | TRANSPORT | **DONE-VERIFIED** | LOW-N11 | `sdk-v0.5.15-low-n11` (`2a64e16`): explicit minimum-length guard added before nonce slice in `openBoxPayload()`. Undersized payloads rejected with clear error before crypto operation. |

### N-series Summary

| Severity | Total | Resolved | Open |
|----------|-------|----------|------|
| HIGH | 1 | 1 (N1) | 0 |
| MEDIUM | 6 | 6 (N2, N3, N4, N5, N6, N7) | 0 |
| LOW | 4 | 4 (N8 verified, N9 by-design, N10 verified, N11 verified) | 0 |
| **Total** | **11** | **11** | **0** |

---

## 2026-03 FULL ECOSYSTEM AUDIT (AC-Series)

Findings from the 2026-03-01 full ecosystem audit covering all 9 repositories.
Five parallel audits: spec-implementation conformance, dependency graph & trust boundary,
crypto & security primitive review, test coverage gap analysis, wire format & interop readiness.

**Canonical audit source:** [`docs/AUDITS/2026-03-01-full-ecosystem-audit.md`](AUDITS/2026-03-01-full-ecosystem-audit.md)

### Tracks

- PROTOCOL: wire semantics, handshake, capability semantics
- INTEROP: cross-implementation compatibility
- TRANSPORT: timeouts, bounds, backpressure, framing transport behaviors
- LIFECYCLE: resource teardown, listeners, object lifetime, disconnect correctness
- MEMORY: zeroization, secret lifetime, key handling
- GOVERNANCE: docs, conformance, tag discipline, process controls, CI gates

### HIGH Severity

| AC_ID | Summary | Track | Status | Phase | Evidence |
|-------|---------|-------|--------|-------|----------|
| AC-1 | localbolt-app has zero web frontend tests and no CI test gate enforcing npm test | GOVERNANCE | **DONE-VERIFIED** | CI-HARDEN-1 | `localbolt-app-v1.2.2-ci-harden-1` (`3f07f35`) |
| AC-2 | bolt-core-sdk CI does not require Rust tests or transport-web tests as mandatory checks | GOVERNANCE | **DONE-VERIFIED** | CI-GATE-1 | `sdk-v0.5.16-ci-gate-1` (`1694aa6`) |
| AC-3 | localbolt subtrees structurally diverged from canonical bolt-rendezvous | GOVERNANCE | **DONE-VERIFIED** | AC-3-SUBTREE-REFRESH | `rendezvous-v0.2.4-subtree-safe-2` (feature-gate removal), `localbolt-v1.0.18-subtree-refresh-1` (`e9207db`), `localbolt-app-v1.2.3-subtree-refresh-1` (`1d71e66`). Deterministic interop CI: `rendezvous-v0.2.5-interop-crate-1`. Dead code cleanup: `rendezvous-v0.2.6-clean-1` (`632544b`). |
| AC-4 | localbolt-v3 coverage thresholds defined but not enforced in CI | GOVERNANCE | **DONE-VERIFIED** | v3.0.64-ac4-coverage-enforced | `v3.0.64-ac4-coverage-enforced` (`a5d0237`). CI now runs `vitest run --coverage`; thresholds enforced (fail on breach). jsdom polyfill for v8 instrumentation fix. PASS→FAIL→PASS proof performed. |
| AC-5 | 4 of 12 §15 handshake invariants lack automated regression tests | PROTOCOL | **DONE-VERIFIED** | sdk-v0.5.20-protocol-converge-2 | REDUCED in `sdk-v0.5.17-protocol-converge-1` (`16cfa92`): +6 explicit PROTO-HARDEN regression tests. CLOSED in `sdk-v0.5.20-protocol-converge-2` (`28c3baf`): mislabeled PROTO-HARDEN-08→10 corrected, real PROTO-HARDEN-08 send-side atomicity test added, header updated. 12/12 invariants covered (11 explicit + 1 DONE-BY-DESIGN). |
| AC-6 | No cross-implementation interop test (TS client ↔ Rust signaling server) | INTEROP | **DONE-VERIFIED** | INTEROP-CONVERGENCE-1 | `sdk-v0.5.18-interop-converge-1` (`97352af`). 7 signaling golden vectors (Rust shape ↔ TS encode/decode deep-equal parity). 24 tests. |
| AC-7 | verify-constants.sh CI guard references outdated path and is inert | GOVERNANCE | **DONE-VERIFIED** | GOVERNANCE-SWEEP-1 | `sdk-v0.5.19-governance-sweep-1` (`9db3abd`). `lib.rs` → `constants.rs` path fix in verify script. CI wired in `ci-gate.yml` bolt-core-ts job with `working-directory: .`. Validated: PASS (stale path) → FAIL (script catches) → PASS (fix applied). |
| AC-8 | Rust SDK lacks canonical wire error code registry matching TS | PROTOCOL | **DONE-VERIFIED** | PROTOCOL-CONVERGENCE-1 | `sdk-v0.5.17-protocol-converge-1` (`16cfa92`) — Rust `WIRE_ERROR_CODES` (22) + `is_valid_wire_error_code()` + conformance parity tests. |
| AC-9 | Five §14 protocol constants missing from core SDK constants files | PROTOCOL | **DONE-VERIFIED** | PROTOCOL-CONVERGENCE-1 | `sdk-v0.5.17-protocol-converge-1` (`16cfa92`) — 13/13 §14 constants present in Rust + TS; parity tests added. |

### MEDIUM Severity

| AC_ID | Summary | Track | Status | Phase | Evidence |
|-------|---------|-------|--------|-------|----------|
| AC-10 | Six stale TODO rows remain in CONFORMANCE.md | GOVERNANCE | **DONE-VERIFIED** | CONSISTENCY-SWEEP-1 | `v0.1.5-spec-consistency-1` (`d795dd5`). 6 TODO rows updated to IMPLEMENTED with concrete test evidence paths. §11, §15.1, §15.2, §15.4, §15.5 (PROTOCOL.md) and §9 (LOCALBOLT_PROFILE.md). |
| AC-11 | Daemon pins bolt-rendezvous-protocol at stale v0.1.0 | PROTOCOL | **DONE-VERIFIED** | CONSISTENCY-SWEEP-1 | `daemon-v0.2.20-dep-refresh-1` (`99de9aa`). Cargo.toml tag bumped from `rendezvous-protocol-v0.1.0` to `rendezvous-v0.2.6-clean-1`. Crate source identical (zero diff); pin now resolves to canonical stable commit. 319 tests pass. |
| AC-12 | ARCHITECTURE.md missing documentation of cargo git dependency | GOVERNANCE | **DONE-VERIFIED** | CONSISTENCY-SWEEP-1 | `ecosystem-v0.1.27-arch-consistency-1` (`fdb5545`). Added "Cargo Git Dependency Pattern" section to ARCHITECTURE.md §6 with rationale, consumer table, mandatory tag pinning rule, example, and update procedure. Bundling matrix corrected for localbolt-v3. |
| AC-13 | Three shadow tests test copied logic rather than SDK imports | GOVERNANCE | **DONE-VERIFIED** | HARDEN-SWEEP-2A | `sdk-v0.5.21-ac13-export-surface-1` (SDK export surface expanded, export-only). `localbolt-v1.0.20-ac13-shadow-test-fix-1` (shadow tests replaced with canonical SDK imports). Zero shadow crypto/store/util logic remains. Net -79 lines of duplicated code. 272 localbolt tests pass. |
| AC-14 | localbolt subtrees may be behind canonical bolt-rendezvous (staleness risk) | GOVERNANCE | **DONE-VERIFIED** | SUBTREE-DRIFT-GUARD-1 | localbolt-v1.0.19-drift-guard-1 (6a4a006). Subtree refreshed to rendezvous-v0.2.6-clean-1. Drift prevention (one-directional tracked-file hash guard). Staleness detection remains future enhancement. |
| AC-15 | find_peer allows cross-room relay lookup | TRANSPORT | **DONE-VERIFIED** | HARDEN-SWEEP-2A | `rendezvous-v0.2.7-hardening-1` (`6ae3f77`). `find_peer` requires `caller_room` parameter; cross-room resolution structurally impossible. Signal relay passes `client_ip` as caller room. Regression test added. 51 tests pass. |
| AC-16 | X-Forwarded-For trusted without proxy allowlist | TRANSPORT | **DONE-VERIFIED** | HARDEN-SWEEP-2A | `rendezvous-v0.2.7-hardening-1` (`6ae3f77`). XFF header trusted only when connecting socket is in `trusted_proxies` allowlist. Default fail-closed (empty list = header always ignored). `with_trusted_proxies()` builder + `TRUSTED_PROXIES` env var. 51 tests pass. |

### LOW Severity

| AC_ID | Summary | Track | Status | Phase | Evidence |
|-------|---------|-------|--------|-------|----------|
| AC-17 | 56% of transport-web exports unused | GOVERNANCE | **DONE-VERIFIED** | HARDEN-SWEEP-2A | Initial reduction: `sdk-v0.5.19-governance-sweep-1` (`9db3abd`), 4 VALUE exports removed. Final consumer matrix audit (HARDEN-SWEEP-2A): 33/33 remaining VALUE exports confirmed in use across localbolt, localbolt-app, localbolt-v3, and SDK CI. No further safe reductions possible. Exhausted. |
| AC-18 | crypto-utils.ts in localbolt is dead code | GOVERNANCE | **DONE-VERIFIED** | GOVERNANCE-SWEEP-1 | `sdk-v0.5.19-governance-sweep-1` (`9db3abd`). Dead `crypto-utils` barrel deleted. Zero internal imports confirmed. Zero consumer imports confirmed. |
| AC-19 | TS ServerMessage union missing error variant typing | INTEROP | **DONE-VERIFIED** | INTEROP-CONVERGENCE-1 | `sdk-v0.5.18-interop-converge-1` (`97352af`). `ServerErrorMessage` type added to union. Runtime `case "error"` handler. 4 handler tests. |
| AC-20 | No golden vectors for signaling messages | INTEROP | **DONE-VERIFIED** | INTEROP-CONVERGENCE-1 | `sdk-v0.5.18-interop-converge-1` (`97352af`). 7 JSON fixtures sourced from `rendezvous-v0.2.6-clean-1` canonical Rust `json!()` shapes. Deep-equal parity + roundtrip tests. |
| AC-21 | §10 spec references bolt.envelope but implementation uses bolt.profile-envelope-v1 | PROTOCOL | **DONE-VERIFIED** | PROTOCOL-CONVERGENCE-1 | `v0.1.4-spec` (`ede90be`) — PROTOCOL.md line 579: `bolt.envelope` → `bolt.profile-envelope-v1`. |
| AC-22 | No concurrent WebSocket connection limit on signal server | TRANSPORT | **DONE-VERIFIED** | HARDEN-SWEEP-2A | `rendezvous-v0.2.8-ac22-ws-conn-limit-1` (`bb59440`). Default limit 256 (`DEFAULT_MAX_WS_CONNECTIONS`). Config: `with_max_connections()` builder + `MAX_WS_CONNECTIONS` env var. AtomicUsize + CAS pre-check + RAII `ConnectionGuard` drop guard. TCP stream dropped before WS upgrade on rejection. 4 deterministic tests added. 55 total tests pass. No protocol/wire/crypto changes. |

### DONE-BY-DESIGN

| AC_ID | Summary | Track | Status | Phase | Evidence |
|-------|---------|-------|--------|-------|----------|
| AC-23 | Peer code validation asymmetry intentional (TS stricter) | INTEROP | **DONE-BY-DESIGN** | N/A | See 2026-03-01-full-ecosystem-audit.md |
| AC-24 | SAS logged to console during verification flow (acceptable UX tradeoff) | LIFECYCLE | **DONE-BY-DESIGN** | N/A | See 2026-03-01-full-ecosystem-audit.md |
| AC-25 | Identity secret stored in IndexedDB (browser boundary accepted) | MEMORY | **DONE-BY-DESIGN** | N/A | See 2026-03-01-full-ecosystem-audit.md |

---

## DEPLOYMENT (DP-Series)

Findings discovered during Fly.io deployment of bolt-rendezvous signal server (2026-03-03).

| DP_ID | Summary | Track | Status | Phase | Evidence |
|-------|---------|-------|--------|-------|----------|
| DP-1 | Dockerfile pins Rust 1.84; `getrandom 0.4.1` requires edition2024 (Rust 1.85+), blocking container build | TRANSPORT | **DONE-VERIFIED** | DP-1 | `rendezvous-v0.2.9-dp1-rust-bump` (`449796a`). Builder image bumped to `rust:1.85-slim-bookworm`. Fly.io build succeeds. 55 tests pass. |
| DP-2 | Signal server rejects all non-WebSocket HTTP requests; Fly.io proxy health checks return 502, marking server offline | TRANSPORT | **DONE-VERIFIED** | DP-2 | `rendezvous-v0.2.10-dp2-health-check` (`06a0f42`). TCP peek before WS handshake; non-upgrade requests get HTTP 200 OK. Fly proxy health checks pass. 55 tests pass. Deployed to 3 regions (dfw, nrt, ams). |
| DP-3 | Phantom device entries: 3 compounding bugs cause 2 real devices to appear as 5+. (a) `generateSecurePeerCode()` creates new random code on every page load — no persistence (`peer-connection.ts:307`). (b) Server rejects re-registration of same peer code instead of replacing stale connection (`room.rs:71`). (c) `handlePeersList` clears internal peer map on reconnect but never fires `peerLostCallback` for removed entries — stale peers accumulate in UI (`WebSocketSignaling.ts:281-289`). | TRANSPORT | **DONE-VERIFIED** | DP-3a/3b/3c | (a) `rendezvous-v0.2.11-dp3a-stale-peer-replace` (`f00ed7c`): server replaces stale peer on re-registration instead of rejecting. 54 tests. (b) `v3.0.65-dp3b-dp4-phantom-transfer` (`08382f1`): peer code persisted in sessionStorage across page refreshes. (c) `sdk-v0.5.23-dp3c-stale-peer-cleanup` (`5496030`): `handlePeersList` emits `peerLost` for stale entries before clearing map. |
| DP-4 | One-way file transfer: TOFU verification gate blocks file upload for `unverified` peers (`transfer.ts:43`). On first contact both sides are `unverified`. `markPeerVerified()` only updates local state — no mutual verification signal sent to remote (`HandshakeManager.ts:221-229`). Result: only the side that clicked "Verify" can send files; the other side's upload UI remains hidden. | TRANSPORT | **DONE-VERIFIED** | DP-4 | `v3.0.65-dp3b-dp4-phantom-transfer` (`08382f1`): removed verification-based gate on file upload. All three TOFU states (verified, unverified, legacy) have working E2E encryption — SAS verification is an optional MITM confirmation, not a prerequisite for secure transfer. |
| DP-5 | Server race condition: stale peer replacement in `add_peer` (DP-3a) drops the old sender, which causes the old connection's cleanup task (`server.rs:513`) to call `remove_peer(&client_ip, &peer_code)` — removing the NEW replacement connection. `remove_peer` matches only on `peer_code` with no session/generation guard, so the old connection's teardown deletes the new connection from the room. Result: replaced peer disappears from room; other devices lose visibility of it. | TRANSPORT | **DONE-VERIFIED** | DP-5 | `rendezvous-v0.2.12-dp5-session-guard` (`aa8bed0`): monotonic `session_id` on PeerInfo; `remove_peer` requires matching session_id, preventing stale cleanup from removing replacement. 55 tests (+1 DP-5 regression). Deployed to Fly.io (3 regions). |
| DP-6 | Responder cannot send files after receiving: file-upload module's store subscription for receive progress sets local `progress` variable but never clears it when the store resets `transferProgress` to null. The subscriber condition `if (transferProgress && transferProgress !== progress)` is falsy when `transferProgress` is null, so `progress` stays as the completed receive object. Since `sendBtn.disabled = !!progress`, the "Start Transfer" button is permanently disabled on the responder after the first receive. Root cause: `file-upload.ts:160-166` — store subscription missing null-clearing branch. Affected repo: bolt-core-sdk (`@the9ines/bolt-transport-web`). | SDK | **DONE-VERIFIED** | DP-6 | SDK fix: `sdk-v0.5.24-dp6-responder-send-fix` (`3c71407`). Added `else if (!transferProgress && progress)` null-clearing branch to store subscription. Published `@the9ines/bolt-transport-web@0.6.1`. Consumer adoption: `v3.0.66-dp6-transport-web-bump` (`8f98716`). |
| DP-7 | Build failure after transport-web 0.6.1 bump: `isValidWireErrorCode` imported from `@the9ines/bolt-core` by `WebRTCService.js`, but bolt-core 0.4.0 was published before SA2/AC-8 added the wire error code registry. Rollup build fails with `"isValidWireErrorCode" is not exported`. Netlify deploy blocked; WebRTC connections cannot establish because the app never loads. Root cause: bolt-core 0.4.0 was never republished after `WIRE_ERROR_CODES` and `isValidWireErrorCode` were added to source. transport-web 0.6.1 was built against the local `file:../bolt-core` dev dependency (which has it) but consumers use the published 0.4.0 (which doesn't). | GOVERNANCE | **DONE-VERIFIED** | DP-7 | Published `@the9ines/bolt-core@0.5.0` (`sdk-v0.5.25-bolt-core-050`, `c776118`). Consumer adoption: `v3.0.67-dp7-bolt-core-050` (`6bb21b3`). Build passes. |
| DP-8 | Netlify deployment stale: DP-6 and DP-7 fixes never reached production. `.npmrc` with `@the9ines:registry=https://npm.pkg.github.com` exists only at workspace root (`localbolt-v3/.npmrc`). Netlify config sets `base = "packages/localbolt-web"` — `npm install` runs from there, never finds root `.npmrc`. GitHub Packages requires authentication even for public packages; no auth token configured in Netlify env. Result: `npm install` fails to resolve `@the9ines/bolt-transport-web@0.6.1` and `@the9ines/bolt-core@0.5.0`, build fails, Netlify serves last successful deploy (pre-DP-6, transport-web 0.6.0). Confirmed by comparing deployed bundle hash (`index-skJDUk04.js`, 119KB, missing `DUPLICATE_HELLO`) vs local build (`index-4l3M1tOP.js`, 132KB, has `DUPLICATE_HELLO`). | GOVERNANCE | **DONE-VERIFIED** | DP-8 | Added `.npmrc` with `${NPM_TOKEN}` auth to `packages/localbolt-web/`. User must set `NPM_TOKEN` env var in Netlify dashboard. `v3.0.68-dp8-netlify-npmrc`. |
| DP-9 | Responder sendFile hangs indefinitely: `TransferManager.sendFile()` backpressure mechanism uses `dc.onbufferedamountlow` property assignment (not `addEventListener`) with `bufferedAmountLowThreshold` defaulting to 0. On the responder's received data channel, `bufferedAmount` starts at 0 and the threshold is 0, so the condition `bufferedAmount > bufferedAmountLowThreshold` (0 > 0) is false on first chunk — but after the first `dc.send()` increases `bufferedAmount`, the backpressure wait fires with threshold 0, meaning `onbufferedamountlow` may never fire reliably since the buffer must drain to exactly 0. Additionally, no timeout/fallback exists — if the event never fires, the transfer hangs forever. User diagnostic confirmed: `sendFile` called with perfect state (helloComplete=true, dc open, keys present), `[TRANSFER] Sending...` logged, but zero progress, zero completion, zero error. Multiple concurrent clicks compound the issue as `onbufferedamountlow` property overwrites previous handlers. Root cause: `TransferManager.ts:165-181` (backpressure await) + `WebRTCService.ts:367-378` (setupDataChannel never sets `bufferedAmountLowThreshold`). Affected repo: bolt-core-sdk (`@the9ines/bolt-transport-web`). | TRANSPORT | **DONE-VERIFIED** | DP-9 | SDK fix: `sdk-v0.5.27-dp9-backpressure-fix` (`1be76c1`). (1) `bufferedAmountLowThreshold = 65536` (64KB) set in `setupDataChannel()`. (2) 5s timeout fallback on backpressure await. (3) `sendInProgress` guard prevents concurrent `sendFile` calls. Published `@the9ines/bolt-transport-web@0.6.2`. Consumer adoption: `v3.0.69-dp9-backpressure-fix` (`48617f0`). 253 SDK tests pass. 26 localbolt-v3 tests pass. Deployed to production. |

### DP-series Summary

| Severity | Total | Open | Resolved |
|----------|-------|------|----------|
| MEDIUM | 9 | 0 | 9 |
| **Total** | **9** | **0** | **9** |

---

### AC-series Summary

| Severity | Total | Open | Resolved |
|----------|-------|------|----------|
| HIGH | 9 | 0 | 9 |
| MEDIUM | 7 | 0 | 7 |
| LOW | 6 | 0 | 6 |
| DONE-BY-DESIGN | 3 | — | 3 (AC-23, AC-24, AC-25) |
| **Total** | **25** | **0** | **25** |

Arithmetic reconciled in ecosystem-v0.1.21-audit-gov-18 —
AC-3 promoted to DONE-VERIFIED.
OPEN = 19. Total = 96.

Arithmetic reconciled in ecosystem-v0.1.22-audit-gov-19 —
AC-14 promoted to DONE-VERIFIED.
OPEN = 18. Total = 96.

Arithmetic reconciled in ecosystem-v0.1.23-audit-gov-20 —
Closed: AC-21, AC-8, AC-9. AC-5 reduced (remains OPEN).
OPEN = 15. DONE/DONE-VERIFIED = 60. Total = 96.

Arithmetic reconciled in ecosystem-v0.1.24-audit-gov-21 —
Closed: AC-6, AC-19, AC-20 (INTEROP-CONVERGENCE-1).
OPEN = 12. DONE/DONE-VERIFIED = 63. Total = 96.

Arithmetic reconciled in ecosystem-v0.1.25-audit-gov-22 —
Closed: AC-7, AC-18. AC-17 reduced (remains OPEN).
OPEN = 10. DONE/DONE-VERIFIED = 65. Total = 96.

Arithmetic reconciled in ecosystem-v0.1.26-audit-gov-23 —
Closed: AC-4, AC-5.
OPEN = 8. DONE/DONE-VERIFIED = 67. Total = 96.

Arithmetic reconciled in ecosystem-v0.1.28-audit-gov-24 —
Closed: AC-10, AC-11, AC-12.
OPEN = 5. DONE/DONE-VERIFIED = 70. Total = 96.

Arithmetic reconciled in ecosystem-v0.1.29-audit-gov-25 —
Closed: AC-13, AC-15, AC-16, AC-17, AC-22.
OPEN = 0. DONE/DONE-VERIFIED = 75. Total = 96.

Arithmetic reconciled in ecosystem-v0.1.40-audit-gov-34 —
Registered: DP-3, DP-4 (4 DP-series total).
DONE/DONE-VERIFIED = 77. OPEN = 2. Total = 100.

Arithmetic reconciled in ecosystem-v0.1.41-audit-gov-35 —
Closed: DP-3, DP-4.
DONE/DONE-VERIFIED = 79. OPEN = 0. Total = 100.

Arithmetic reconciled in ecosystem-v0.1.43-audit-gov-37 —
Registered + closed: DP-5 (session guard race condition).
DONE/DONE-VERIFIED = 80. OPEN = 0. Total = 101.

Arithmetic reconciled in ecosystem-v0.1.44-audit-gov-38 —
Registered: DP-6 (responder send button disabled after receive).
DONE/DONE-VERIFIED = 80. OPEN = 1. Total = 102.

Arithmetic reconciled in ecosystem-v0.1.45-audit-gov-39 —
Closed: DP-6 (responder send fix, SDK 0.6.1 published, localbolt-v3 adopted).
DONE/DONE-VERIFIED = 81. OPEN = 0. Total = 102.

Arithmetic reconciled in ecosystem-v0.1.46-audit-gov-40 —
Registered + closed: DP-7 (bolt-core 0.5.0 publish, wire error code registry).
DONE/DONE-VERIFIED = 82. OPEN = 0. Total = 103.

---

## SECURITY RE-AUDIT — 2026-03-03 (NF-series)

Findings from the 2026-03-03 read-only security re-audit (4 parallel agents:
cryptographic correctness, protocol state machine, interop compatibility,
memory/lifecycle). Registered as NF-series.

**Canonical audit source:** [`docs/AUDITS/2026-03-03-security-audit.md`](AUDITS/2026-03-03-security-audit.md)

### MEDIUM Severity

| NF_ID | Summary | Track | Status | Phase | Evidence |
|-------|---------|-------|--------|-------|----------|
| NF-1 | Envelope path in `handleMessage` forwards `file-chunk` to `routeInnerMessage` without validating `inner.filename`; plaintext path correctly rejects missing filename with `INVALID_MESSAGE` + disconnect (`WebRTCService.ts:659`) | PROTOCOL | **DONE-VERIFIED** | NF1-ENVELOPE-FILENAME | `transport-web-v0.6.10-nf1-envelope-filename`. Filename validation added to envelope path mirroring plaintext path. 3 UNIT + 1 ADVERSARIAL tests in `nf1-envelope-filename-validation.test.ts`. 253 total tests pass. |

### NF-series Summary

| Severity | Total | Resolved | Open |
|----------|-------|----------|------|
| MEDIUM | 1 | 1 | 0 |
| **Total** | **1** | **1** | **0** |

Arithmetic reconciled in ecosystem-v0.1.50-audit-gov-44 —
Registered + closed: NF-1 (envelope filename validation gap).
DONE/DONE-VERIFIED = 83. OPEN = 0. Total = 104.

Arithmetic reconciled in ecosystem-v0.1.51-audit-gov-45 —
Registered + closed: DP-8 (Netlify deployment stale, .npmrc missing from workspace).
DONE/DONE-VERIFIED = 84. OPEN = 0. Total = 105.

Arithmetic reconciled in ecosystem-v0.1.52-audit-gov-46 —
Registered: DP-9 (responder sendFile backpressure hang).
DONE/DONE-VERIFIED = 84. OPEN = 1. Total = 106.

Arithmetic reconciled in ecosystem-v0.1.53-audit-gov-47 —
Closed: DP-9 (backpressure fix, SDK 0.6.2 published, localbolt-v3 adopted + deployed).
DONE/DONE-VERIFIED = 85. OPEN = 0. Total = 106.

Arithmetic reconciled in ecosystem-v0.1.55-audit-gov-49 —
Registered: Q7, Q8, Q9, Q10 (app-layer convergence + session UX findings, Workstream C scope).
DONE/DONE-VERIFIED = 85. OPEN = 4. Total = 110.

Arithmetic reconciled in ecosystem-v0.1.97-recon-xfer1-phase-b —
Registered + closed: Q11 (RECON-XFER-1 mid-transfer disconnect → reconnect stuck).
DONE/DONE-VERIFIED = 91. OPEN = 0. Total = 111.

Arithmetic reconciled in ecosystem-v0.1.98-recon-xfer1-evidence-tail —
Registered: RX-EVID-1 (manual runtime evidence tail, LOW). Q11 status corrected to
DONE-VERIFIED with evidence tail note. AC-RX-08 wording corrected.
DONE/DONE-VERIFIED = 91. OPEN = 1. Total = 112.

Arithmetic reconciled in ecosystem-v0.1.99-sec-dr1-p0-codify —
DR-F series reserved (DR-F1–DR-F99) for DR-STREAM-1 findings. No new findings registered.
DONE/DONE-VERIFIED = 91. OPEN = 1. Total = 112. (unchanged — reservation only)

Arithmetic reconciled in ecosystem-v0.1.100-sec-btr1-replaces-dr —
DR-F series FROZEN (DR-STREAM-1 superseded by BTR-STREAM-1). BTR-F series reserved
(BTR-F1–BTR-F99). No new findings registered.
DONE/DONE-VERIFIED = 91. OPEN = 1. Total = 112. (unchanged — reservation only)

---

## N-STREAM-1 — Native App + Daemon Bundling

> **Finding series reservation:** `N1-F*`
> **Codified:** ecosystem-v0.1.72-n-stream-1-codify (2026-03-07)
> **Status:** No findings registered. Series reserved for findings discovered during N-STREAM-1 phase execution.

No execution findings in this pass. Findings will be registered here with `N1-F<N>` IDs when evidence is confirmed during phase execution.

---

## DR-STREAM-1 — Double Ratchet Pre-ByteBolt Security Gate [SUPERSEDED]

> **Finding series reservation:** `DR-F*` — **FROZEN** (stream superseded by BTR-STREAM-1)
> **Codified:** ecosystem-v0.1.99-sec-dr1-p0-codify (2026-03-09)
> **Superseded:** ecosystem-v0.1.100-sec-btr1-replaces-dr (2026-03-09)
> **Status:** SUPERSEDED-BY: BTR-STREAM-1. No phases executed. No findings registered. Series frozen.

DR-F series (DR-F1–DR-F99) frozen. No new findings will be registered under this series. Superseded by BTR-F series.

---

## BTR-STREAM-1 — Bolt Transfer Ratchet Pre-ByteBolt Security Gate

> **Finding series reservation:** `BTR-F*`
> **Codified:** ecosystem-v0.1.100-sec-btr1-replaces-dr (2026-03-09)
> **Status:** P0 complete (replacement architecture codified). No code changes.
> **Full specification:** `docs/GOVERNANCE_WORKSTREAMS.md` § BTR-STREAM-1
> **Replaces:** DR-STREAM-1 (SEC-DR1) — per PM-BTR-01 through PM-BTR-04

**Audit ID reservation:** `BTR-F1` through `BTR-F99` reserved for findings discovered during BTR-STREAM-1 phase execution (BTR-0 through BTR-5). IDs are non-colliding with all existing series (S, N, AC, DP, NF, RX, Q, N1-F, DR-F).

No execution findings in this pass. Findings will be registered here with `BTR-F<N>` IDs when evidence is confirmed during phase execution.

---

## CONSUMER-BTR-1 — Consumer App BTR Rollout

> **Finding series reservation:** `CBTR-F*`
> **Codified:** ecosystem-v0.1.108-consumer-btr1-codify (2026-03-11)
> **Status:** IN-PROGRESS. CBTR-1 P1 done. CBTR-F1 FIXED (`sdk-v0.5.40-cbtr-f1-receiver-pause`, `c164fc1`).
> **Full specification:** `docs/GOVERNANCE_WORKSTREAMS.md` § CONSUMER-BTR-1
> **Depends on:** BTR-STREAM-1 (COMPLETE)

**Audit ID reservation:** `CBTR-F1` through `CBTR-F99` reserved for findings discovered during CONSUMER-BTR-1 phase execution (CBTR-1 through CBTR-3). IDs are non-colliding with all existing series (S, I, Q, A, M, N, AC, DP, NF, RX, DR-F, BTR-F).

| ID | Finding | Severity | Classification | Status | Evidence |
|----|---------|----------|----------------|--------|----------|
| CBTR-F1 | Receiver cannot pause/resume transfer — `pauseTransfer()` and `resumeTransfer()` used sender-only `getSendTransferIds()` lookup. | MEDIUM | Pre-existing transport control asymmetry, surfaced during CBTR-1 burn-in. Not a BTR regression. | **FIXED** | `sdk-v0.5.40-cbtr-f1-receiver-pause` (`c164fc1`). Added `isReceiver` param to pause/resume, mirroring cancel dual-lookup. 6 new tests, 344 TS + 266 Rust pass. |

**Execution handoff (CBTR-PAUSE-1 fix run):**
- **Code touch area:** `bolt-core-sdk/ts/bolt-transport-web/src/services/webrtc/TransferManager.ts` — add `isReceiver` parameter to `pauseTransfer()` and `resumeTransfer()`, mirror `cancelTransfer()` dual-lookup pattern.
- **Tests:** `bolt-core-sdk/ts/bolt-transport-web/src/__tests__/` — receiver pause sends canonical `pause`, receiver resume sends canonical `resume`, sender behavior unchanged, regression suite green.
- **Blocker:** Blocks CBTR-2/3 advancement. CBTR-1 burn-in continues (sender pause works, BTR protocol unaffected).
