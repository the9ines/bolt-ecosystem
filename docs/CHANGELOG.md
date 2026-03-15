# Bolt Ecosystem — Changelog

Cross-repo milestones and hardening phases. Newest first.
Per-repo details live in each repo's `docs/CHANGELOG.md`.

---

## 2026-03-15 — WEBTRANSPORT-BROWSER-APP-1 COMPLETE: WT5 Closure + WS Disposition Lock

**WT5 status**: READY → **DONE**. All 4 ACs (AC-WT-17–20) PASS. One PM decision resolved.

**WEBTRANSPORT-BROWSER-APP-1 stream: COMPLETE.** All 5 phases (WT1–WT5) DONE. All 20 ACs (AC-WT-01–20) PASS. All 5 PM decisions (PM-WT-01–05) APPROVED.

**AC-WT-17 (closure criteria):** Governance closure met — all 20 ACs, all 5 PM decisions, all guardrails verified. Runtime closure (burn-in, production SLO) deferred to implementation execution (WT4 rollout stages).

**PM-WT-05 APPROVED (2026-03-15, Option B):** WS disposition — deprecate-with-sunset, condition-gated. WS retained until ALL of: (1) ≥1 release cycle with WT default-on, (2) zero kill-switch activations, (3) zero P0/P1 from WT, (4) Safari ships production WebTransport, (5) explicit PM removal approval. Matches PM-RC-05 pattern (TS-path deprecation).

**AC-WT-19 (cross-stream reconciliation):** G1 invariant (browser↔browser WebRTC) confirmed unchanged. RC6 rollback preserved (RB-L5 extends framework). BTR transparency (BS3) preserved. RUSTIFY-CORE-1 session authority preserved.

**AC-WT-20 (migration guide outline):** 7-section outline defined. Full guide deferred to implementation.

**Tags**: `ecosystem-v0.1.147-webtransport-browser-app1-wt5-closeout`

**Stream summary:** WEBTRANSPORT-BROWSER-APP-1 delivered complete governance specification for browser↔app WebTransport migration: browser support matrix, capability string, TLS cert strategy, daemon endpoint contract, three-tier fallback orchestrator, BTR transparency plan, DataTransport compliance, compatibility matrix, rollout/rollback gates, performance SLO, and WS sunset policy. Ready for implementation.

---

## 2026-03-15 — WEBTRANSPORT-BROWSER-APP-1 WT4 DONE: Conformance + Rollout/Rollback Gate Lock

**WT4 status**: READY → **DONE**. All 4 ACs (AC-WT-13–16) PASS. One PM decision resolved.

**AC-WT-13 (compatibility matrix):** 12-cell matrix covering browser classes (Chrome/Firefox/Edge/Safari) × transport tiers (WT/WS/WebRTC) × daemon gate states. 5 pass criteria per cell. Safari handling: orchestrator enters at PROBE_WS (TF-01), no WT probe delay.

**AC-WT-14 (rollout policy):** 3-stage rollout: Canary (single consumer, opt-in) → Staged (all consumers, opt-in) → GA (default-on). Promotion gates: SLO thresholds + zero P0/P1 + fallback ≥98% + suites green. Consumer order: localbolt-v3 → localbolt → localbolt-app.

**AC-WT-15 (rollback policy):** 5 triggers (RB-WT-T1–T5), 4 levers (RB-L5, RB-L2, SDK pin, daemon rollback). PM ownership, ≤4h P0 / ≤1h execution / ≤72h RCA. Aligned with RC6 AC-RC-26 framework.

**PM-WT-04 APPROVED (2026-03-15, Option B):** Latency ≤1.5× WS. Throughput ≥90% WS. Connection ≥99% combined. Fallback ≥98%. No-regression green + WT tests.

**WT5 status**: NOT-STARTED → **READY** (WT4 DONE, unblocked). WT5 scope: closure + WS disposition (PM-WT-05).

**Tags**: `ecosystem-v0.1.146-webtransport-browser-app1-wt4-gate-lock`

**Next**: WT5 — closure criteria + WS disposition decision (PM-WT-05 needed).

---

## 2026-03-15 — WEBTRANSPORT-BROWSER-APP-1 WT3 DONE: Browser Adapter + Fallback Orchestration Lock

**WT3 status**: READY → **DONE**. All 4 ACs (AC-WT-09–12) PASS.

**AC-WT-09 (browser adapter contract):** `WebTransportDataTransport` adapter specified. 3 lifecycle states (WT_CONNECTING → WT_CONNECTED → WT_DISCONNECTED). 6 interface methods/events. Responsibilities: transport binding + envelope relay. Non-responsibilities: protocol/session authority stays in daemon/bolt_core (WT-G4).

**AC-WT-10 (fallback orchestrator):** 5-state orchestrator SM (PROBE_WT → PROBE_WS → PROBE_WEBRTC → CONNECTED → FAILED). 9 transitions (F1–F9). 9-entry failure taxonomy (TF-01–TF-09) with deterministic trigger → action mapping. Fallback invariants locked: ordering (WT→WS→WebRTC), no-loop, no-flap, terminal FAILED, G1 preserved.

**AC-WT-11 (BTR transparency):** 6 verification obligations (BT-01–BT-06) confirming BTR operates identically over all 3 transports: key schedule, chain advance, encryption, capability negotiation, error behavior, lifecycle zeroization. Inherits BTR-FC layering principle (BS3).

**AC-WT-12 (DataTransport compliance):** Method-by-method compliance matrix across WT/WS/WebRTC adapters (connect, send, onMessage, close, onDisconnect, isConnected, backpressure). New rollback lever RB-L5 cross-linked to RC6 framework (same ownership, same SLA).

**WT4 status**: NOT-STARTED → **READY** (WT3 DONE, unblocked). WT4 scope: conformance + rollout/rollback gates (PM-WT-04 needed).

**Tags**: `ecosystem-v0.1.145-webtransport-browser-app1-wt3-orchestration-lock`

**Next**: WT4 — conformance/compatibility matrix + rollout/rollback gate lock (PM-WT-04 needed for perf SLO).

---

## 2026-03-15 — WEBTRANSPORT-BROWSER-APP-1 WT2 DONE: Daemon Endpoint + TLS Policy Lock

**WT2 status**: READY → **DONE**. All 4 ACs (AC-WT-05–08) PASS. One PM decision resolved.

**AC-WT-05 (daemon endpoint contract):** HTTP/3 WebTransport endpoint specified. ALPN `h3`, TLS 1.3 mandatory, configurable listen address (localhost default), separate port from WS. Connection lifecycle: HTTP/3 CONNECT → session open → bidirectional stream → HELLO exchange → standard Bolt protocol. Delegates to shared Rust core (RC4 pattern).

**AC-WT-06 (auth/origin validation):** Origin header validation required (default: same-origin localhost). Optional connection token/nonce. Rate limiting per WS policy. No mutual TLS in v1. WebTransport always TLS — resolves HTTPS mixed-content caveat.

**PM-WT-03 APPROVED (2026-03-15):** TLS cert strategy — Primary: C2 local CA (mkcert-style) for localhost/LAN. Dev fallback: C1 self-signed. Out of scope: C3 ACME/Let's Encrypt (WAN, deferred). Cert lifecycle: daemon-generated on first start, 365-day validity, regenerate + restart for rotation.

**AC-WT-08 (feature gate):** `transport-webtransport` feature gate designed. Default OFF. Independent from `transport-ws` and `transport-quic`. Kill-switch: gate OFF → browser auto-falls to WS (Tier 2). Feature gate hierarchy documented.

**Invariant:** browser↔browser WebRTC (G1) unchanged. Runtime implementation deferred.

**WT3 status**: NOT-STARTED → **READY** (WT2 DONE, unblocked). WT3 scope: browser adapter + three-tier fallback orchestration lock.

**Tags**: `ecosystem-v0.1.144-webtransport-browser-app1-wt2-executed`

**Next**: WT3 — browser adapter contract + fallback orchestration lock. No PM decisions required.

---

## 2026-03-15 — BTR-SPEC-1 COMPLETE: BS5 Closeout (Change-Control + External Review Readiness)

**BS5 status**: READY → **DONE**. All 5 ACs (AC-BS-18–22) PASS. Two PM decisions resolved.

**BTR-SPEC-1 stream: COMPLETE.** All 5 phases (BS1–BS5) DONE. All 22 ACs (AC-BS-01–22) PASS. All 6 PM decisions (PM-BS-01–06) APPROVED.

**AC-BS-18 (change-control policy):** §16 amendment governance process codified: 7-step process (propose → impact → PM gate → draft → vectors → cross-lang → publish). 5 amendment categories with required evidence. Inherits §17.6 change-control security policy.

**AC-BS-19 (external review package):** 7-artifact package assembled: spec (§16/§17), vectors (10 files), vector policy, module taxonomy (BS1), state machines + invariant mapping (BS2), 5 evidence files.

**PM-BS-05 APPROVED (2026-03-15):** External review gate — scope: BTR §16/§17 + vectors + evidence. Reviewer: independent crypto/protocol. Bar: no critical unresolved; medium = mitigation plan. Timing: before GA.

**PM-BS-06 APPROVED (2026-03-15):** Relationship mode ratified — BTR-SPEC-1 COMPLEMENTS SEC-BTR1, CONSUMER-BTR1, RUSTIFY-CORE-1. No SUPERSEDES.

**AC-BS-22 (docs-only audit):** All 5 BS phases touched only `docs/` files. Zero runtime files modified. BS-G1 satisfied.

**Tags**: `ecosystem-v0.1.143-btr-spec1-bs5-closeout`

**Stream summary:** BTR-SPEC-1 delivered algorithm-grade specification for the Bolt Transfer Ratchet: 7-module taxonomy, formal state machines, crypto/lifecycle ratification, wire format + recovery normative text, conformance vector mapping, negative-test matrix, cross-language contract, change-control policy, and external review readiness. Ready for independent cryptographic review.

---

## 2026-03-15 — EGUI-WASM-1 Codified: Browser UI Migration to egui via WASM (Experimental)

- **PM-EN-04 APPROVED (early resolution, 2026-03-15):** EGUI-WASM-1 opened independent of EGUI-NATIVE-1 EN3 completion. Browser WASM egui is architecturally distinct from desktop egui. Experimental, non-blocking to EGUI-NATIVE-1.
- **New governance stream codified:** EGUI-WASM-1 — explores migrating browser UI from React/TS to egui compiled to WASM.
- **Experimental status:** Default-safe path is retaining React/TS browser UI. ABANDON is a valid EW4 outcome.
- **5 phases defined:** EW1 (feasibility + gates) → EW2 (WASM scaffold + PoC) → EW3 (parity assessment) → EW4 (adoption decision) → EW5 (migration rollout, if adopt)
- **19 acceptance criteria:** AC-EW-01 through AC-EW-19
- **5 PM decisions opened:** PM-EW-01 (bundle budget), PM-EW-02 (rendering backend), PM-EW-03 (accessibility), PM-EW-04 (adopt/abandon/defer), PM-EW-05 (React/TS disposition)
- **6 quantitative success gates:** SG-01 (≤500 KiB gzipped), SG-02 (≤2s cold start), SG-03 (≥30 FPS), SG-04 (accessibility parity), SG-05 (≥90% feature parity), SG-06 (cross-browser rendering)
- **6 risks identified:** EW-R1 bundle size (HIGH), EW-R2 accessibility (HIGH), EW-R3 cold start (MEDIUM), EW-R4 cross-browser (MEDIUM), EW-R5 API instability (LOW), EW-R6 dual-build (LOW)
- **8 guardrails:** EW-G1 (React/TS retained as default), EW-G4 (rollback at every phase), EW-G5 (no React removal without PM-EW-05)
- **Relationship:** PARALLEL/NON-BLOCKING to EGUI-NATIVE-1. ORTHOGONAL to BTR-SPEC-1, WEBTRANSPORT-BROWSER-APP-1.

**Tags**: `ecosystem-v0.1.142-egui-wasm1-codify`

**Next**: EW1 — feasibility assessment + success gate definition lock (PM-EW-01 needed).

---

## 2026-03-15 — WEBTRANSPORT-BROWSER-APP-1 WT1 DONE: Policy + Browser Support Matrix Lock

**WT1 status**: NOT-STARTED → **DONE**. All 4 ACs (AC-WT-01–04) PASS. Two PM decisions resolved.

**PM-WT-01 APPROVED (2026-03-15): Option B.** Ship WebTransport on supported browsers (Chrome 97+, Edge 97+, Firefox 115+). Safari/iOS Safari fallback to WS-direct → WebRTC. Re-evaluate when Safari ships (Interop 2026). Runtime detection via `typeof WebTransport !== 'undefined'`.

**PM-WT-02 APPROVED (2026-03-15): Option A.** Capability string `bolt.transport-webtransport-v1`. Transport-level, no protocol impact. Follows `bolt.*` namespace convention.

**AC-WT-03 (fallback policy):** Three-tier fallback locked: WebTransport → WS-direct → WebRTC. 6 deterministic trigger conditions (feature detection, connection timeout, TLS error, UDP block, WS refused, WS timeout). Kill-switch at every tier (WT-G8). G1 invariant preserved (browser↔browser = WebRTC).

**AC-WT-04 (TLS requirement):** WebTransport requires TLS (QUIC mandates TLS 1.3). 4 cert strategy options documented (C1–C4) for PM-WT-03 resolution in WT2.

**WT2 status**: NOT-STARTED → **READY** (WT1 DONE, unblocked). WT2 scope: daemon endpoint contract + TLS cert strategy lock (PM-WT-03).

**Tags**: `ecosystem-v0.1.141-webtransport-browser-app1-wt1-executed`

**Next**: WT2 — daemon WebTransport endpoint + TLS policy lock (PM-WT-03 needed).

---

## 2026-03-14 — BTR-SPEC-1 BS4 DONE: Conformance Vectors + Negative-Test Matrix Lock

**BS4 status**: READY → **DONE**. All 4 ACs (AC-BS-14–17) PASS.

**AC-BS-14 (vector-to-spec mapping):** All 10 vector files (38 vectors + 1 lifecycle scenario) mapped to spec sections, modules, and invariants. 5 Appendix C required categories + 5 additional (dh-ratchet, dh-sanity, encrypt-decrypt, lifecycle, adversarial).

**AC-BS-15 (negative-test matrix):** 14 negative-test obligations across 5 modules. Each maps to §16.7 error code + BS2 SM transition. Covers generation mismatch, unexpected DH key, missing fields, chain gap, duplicate index, wrong key, truncated ciphertext, downgrade attacks, wire violations.

**AC-BS-16 (cross-language conformance):** Rust authority / TS consumer contract locked. 6 conformance requirements (vector pass, cross-language interop, transfer isolation, adversarial parity, downgrade parity, constants parity). CI integration documented (4 jobs). Change policy per BTR_VECTOR_POLICY.md.

**AC-BS-17 (downgrade coverage):** 6 vectors in `btr-downgrade-negotiate.vectors.json`, one per §4.2 6-row negotiation matrix outcome. Complete coverage.

**BS5 status**: NOT-STARTED → **READY** (BS4 DONE, unblocked). BS5 scope: versioning/change-control + external review readiness (PM-BS-05/06 needed).

**Tags**: `ecosystem-v0.1.140-btr-spec1-bs4-conformance-lock`

**Next**: BS5 — versioning/change-control + external review readiness (PM-BS-05/06 required).

---

## 2026-03-14 — WEBTRANSPORT-BROWSER-APP-1 Codified: Browser↔App WebTransport Migration Stream

- **New governance stream codified:** WEBTRANSPORT-BROWSER-APP-1 — migrates browser↔app primary transport from WebSocket-direct (RC5) to WebTransport (QUIC/HTTP3).
- **Transport matrix (post-adoption):** browser↔app primary: WebTransport. Fallback 1: WS-direct (RC5). Fallback 2: WebRTC (baseline). browser↔browser: WebRTC (G1 unchanged). app↔app: QUIC/quinn (RC3 unchanged).
- **5 phases defined:** WT1 (policy + browser support) → WT2 (daemon endpoint + TLS) → WT3 (browser adapter + fallback) → WT4 (conformance + rollout) → WT5 (closure + WS disposition)
- **20 acceptance criteria:** AC-WT-01 through AC-WT-20
- **5 PM decisions opened:** PM-WT-01 (browser support matrix), PM-WT-02 (capability string), PM-WT-03 (TLS strategy), PM-WT-04 (perf SLO), PM-WT-05 (WS disposition)
- **5 risks identified:** WT-R1 Safari support (HIGH), WT-R2 TLS cert complexity (HIGH), WT-R3 API instability (MEDIUM), WT-R4 fallback latency (MEDIUM), WT-R5 UDP firewall blocking (MEDIUM)
- **Relationship:** EXTENDS RUSTIFY-CORE-1 (complete). ORTHOGONAL to BTR-SPEC-1, EGUI-NATIVE-1, DISCOVERY-MODE-1. No SUPERSEDES.
- **Guardrails:** G1 preserved (browser↔browser WebRTC). WS/WebRTC retained as fallback. BTR transparent. No protocol semantic changes. Kill-switch rollback at every phase.
- **Historical context:** WebTransport was rejected for RC5 (PM-RC-02 Option C, 2026-03-14) due to Safari support and scope risk. This stream re-evaluates with explicit fallback tiers.

**Tags**: `ecosystem-v0.1.139-webtransport-browser-app1-codify`

**Next**: WT1 — policy lock + browser support matrix (PM-WT-01/02 needed).

---

## 2026-03-14 — BTR-SPEC-1 BS3 DONE: Wire Format + Failure/Recovery Semantics Lock

**BS3 status**: READY → **DONE**. All 5 ACs (AC-BS-09–13) PASS. Two PM decisions resolved.

**AC-BS-09 (BTR-FC flow control):** Normative text codified. BTR introduces no separate v1 flow-control algorithm. All backpressure inherited from transport layer (§8). 5 normative rules (FC-01–FC-05): no BTR buffering/windowing, synchronous chain advance, transport backpressure applied before encryption, no speculative chain advance, pause/resume does not affect key state. Layering boundary diagram included.

**AC-BS-10 (BTR-RSM resume/recovery):** Normative text codified. No v1 session resume (BTR-NG1). No v1 transfer resume. Disconnect → zeroize ALL state (BTR-INV-09) → fresh handshake → new session. 5 normative rules (RSM-01–RSM-05). 7 recovery paths mapped deterministically to SM transitions and §16.7 error actions.

**AC-BS-11 (wire versioning, PM-BS-03):** Additive fields backward-compatible, no version bump. Breaking changes require new capability string + PM decision + updated vectors. `bolt.transfer-ratchet-v1` locked.

**AC-BS-12 (parsing contract, PM-BS-04):** Strict on security-critical required fields/values. Tolerant only on explicitly optional/unknown fields. Downgrade detection strict. All failures → §16.7 error codes. Deterministic, no implementation-defined behavior.

**AC-BS-13 (failure-to-action matrix):** All 4 §16.7 error codes mapped to SM trigger points, trigger conditions, required actions, recovery paths, and enforced invariants. Complete, deterministic, SM-linked, invariant-backed.

**PM-BS-03 APPROVED (2026-03-14):** Wire format versioning — additive backward-compatible, breaking requires version bump.

**PM-BS-04 APPROVED (2026-03-14):** Compatibility contract — strict on security-critical, tolerant on optional, deterministic failures.

**BS4 status**: NOT-STARTED → **READY** (BS3 DONE, unblocked). BS4 scope: conformance vectors + negative-test matrix lock.

**Tags**: `ecosystem-v0.1.138-btr-spec1-bs3-wire-recovery-lock`

**Next**: BS4 — conformance vectors + negative-test matrix lock. No PM decisions required.

---

## 2026-03-14 — BTR-SPEC-1 BS2 DONE: State Machines + Crypto/Key-Schedule Lock

**BS2 status**: READY → **DONE**. All 5 ACs (AC-BS-04–08) PASS. Two PM decisions resolved.

**AC-BS-04 (BTR-KS state machine):** 5-state key schedule SM locked: `KS_UNINIT` → `KS_SESSION_ROOTED` → `KS_TRANSFER_ACTIVE` ⟷ `KS_CHAIN_STEP` + `KS_DH_RATCHET`. 7 transitions (T1–T7) + disconnect transition (Tε). Error edges map to §16.7: `RATCHET_STATE_ERROR` (T2, T6), `RATCHET_CHAIN_ERROR` (T3), `RATCHET_DECRYPT_FAIL` (T4).

**AC-BS-05 (BTR-HS negotiation SM):** 4-state handshake SM locked: `HS_PENDING` → `HS_BTR_ACTIVE` / `HS_DOWNGRADED` / `HS_REJECTED`. 6 transitions (H1–H6) derived from §4.2 6-row negotiation matrix. Error edge: `RATCHET_DOWNGRADE_REJECTED` (H5, H6). Wording corrected: "6-row matrix" (not "6-cell").

**AC-BS-06 (invariant mapping):** All 11 invariants (BTR-INV-01–11) mapped to specific SM states/transitions. Zero orphans. Error edges cross-referenced to §16.7 codes.

**PM-BS-01 APPROVED (2026-03-14):** Crypto baseline ratified — NaCl box + HKDF-SHA256 + X25519. 5 HKDF info strings locked. No new primitives without new PM decision.

**PM-BS-02 APPROVED (2026-03-14):** Rekey/lifecycle ratified — per-chunk symmetric chain + per-transfer DH ratchet. No time/byte/count forced ratchet. Memory-only lifecycle. No session resume in v1.

**BS3 status**: NOT-STARTED → **READY** (BS2 DONE, unblocked). BS3 scope: wire format + failure/recovery semantics (BTR-FC, BTR-RSM gap-fill). Requires PM-BS-03/04.

**Tags**: `ecosystem-v0.1.137-btr-spec1-bs2-state-crypto-lock`

**Next**: BS3 — wire format + failure/recovery semantics lock (BTR-FC, BTR-RSM gap-fill; PM-BS-03/04 needed).

---

## 2026-03-14 — BTR-SPEC-1 BS1 DONE: Module Taxonomy + Boundary Lock

**BS1 status**: NOT-STARTED → **DONE**. All 3 ACs (AC-BS-01–03) PASS.

**AC-BS-01 (module taxonomy):** 7-module taxonomy locked, matching P0 audit candidate list:
- BTR-HS (Handshake + Capability Negotiation) — §4.2, §16.0
- BTR-KS (Key Schedule + Ratchet Lifecycle) — §16.3, §16.5
- BTR-INT (Chunk Integrity + Replay/Ordering) — §11, §16.6
- BTR-FC (Flow Control + Backpressure) — NEW (§16 gap, BS3 scope)
- BTR-RSM (Resume/Recovery/Rollback) — §16.7 (extend, BS3 scope)
- BTR-WIRE (Envelope Framing + Canonicalization) — §16.2, §6.1
- BTR-CNF (Conformance + Vectors + Interop) — Appendix C

**AC-BS-02 (per-module artifact checklist):** 6-artifact checklist confirmed: SM (state machine), INV (invariants), PSC (pseudocode), FAIL (failure modes), SEC (security claims), VEC (conformance vectors). Coverage matrix shows 5/7 modules fully covered; BTR-FC and BTR-RSM have artifact gaps (BS3 gap-fill scope).

**AC-BS-03 (SEC-BTR1 cross-reference):** Zero contradictions. All SEC-BTR1 evidence (341 tests, 10 vector files, BTR-INV-01–11, BTR-0–5 tags) fully consistent with module taxonomy.

**BS2 status**: NOT-STARTED → **READY** (BS1 DONE, unblocked). BS2 scope: state machines + crypto/key-schedule canonicalization lock.

**Tags**: `ecosystem-v0.1.136-btr-spec1-bs1-taxonomy`

**Next**: BS2 — state machines + crypto/key-schedule canonicalization lock (requires PM-BS-01 for crypto baseline, PM-BS-02 for rekey thresholds).

---

## 2026-03-14 — RUSTIFY-CORE-1: All 8 PM Decisions Resolved (PM-RC-07, PM-RC-04)

**PM-RC-07 APPROVED (2026-03-14):** Stream relationship mode locked.
- **SUPERSEDES:** SEC-CORE2 (AC-SC-01–04 absorbed by AC-RC-08–11), PLAT-CORE1 (RC2+RC4 absorbed full scope)
- **REFACTORS/DEPENDS-ON:** MOB-RUNTIME1 (depends on RC4, retains own stream), ARCH-WASM1 (depends on RC2, retains own stream)
- SEC-CORE2 and PLAT-CORE1 updated to `SUPERSEDED-BY: RUSTIFY-CORE-1` across all docs (matching DR-STREAM-1 → BTR-STREAM-1 precedent)

**PM-RC-04 APPROVED (2026-03-14):** Performance SLO thresholds for native transport migration gates.

| Metric | Threshold | Notes |
|--------|-----------|-------|
| Throughput | ≥10 MiB/s avg | 3×1MiB localhost transfers |
| Integrity | 100% hash match | 0 mismatches tolerated |
| Connection success | ≥99% | Controlled matrix |
| No-regression | All suites green | Cross-repo |
| Failure action | Hold/rollback per RC6 levers | RB-L1–L4 |

AC-RC-15 updated from "DONE (provisional)" to "DONE" — baseline (~15–16 MB/s) exceeds all SLO thresholds.

**RUSTIFY-CORE-1 PM decisions:** All 8 of 8 now APPROVED (PM-RC-01, 01A, 02, 03, 04, 05, 06, 07). Zero residual PM blockers.

---

## 2026-03-14 — RUSTIFY-CORE-1 RC7 DONE: CLI Reservation Hooks Closed (PM-RC-06 Resolved)

**RC7 status**: IN-PROGRESS → **DONE**. All 5 ACs (AC-RC-29–33) now PASS.

**PM-RC-06 APPROVED (2026-03-14):** CLI-specific execution stream may begin after:
1. RUSTIFY-CORE-1 RC4 complete (shared Rust core adopted) — **SATISFIED**
2. RC6 Stage 1 burn-in passed — NOT YET STARTED

**Burn-in pass definition (lab/staging):**
- 12h continuous automated soak
- 0 P0/P1 incidents
- 0 kill-switch activations
- Required no-regression gates remain green

N-STREAM-1 N6 completion is NOT required for CLI stream start.

**AC-RC-33 (CLI stream trigger condition):** BLOCKED → **PASS** (trigger condition *defined*; trigger condition *not yet satisfied*). PM-RC-06 resolved with dual-condition trigger (RC4 + Stage 1 burn-in). **CLI execution stream is NOT OPEN** — Stage 1 burn-in evidence not yet produced. Burn-in evidence checkpoint pending.

**AC-RC-29–32:** Unchanged from prior commit (all PASS). Extension points, config keys, capability namespace reserved. No runtime code.

**RUSTIFY-CORE-1 stream:** All 33 ACs delivered (AC-RC-01–33). All 7 phases (RC1–RC7) DONE. Remaining residual PM decisions: PM-RC-04 (performance SLO), PM-RC-07 (stream relationships).

**Deferred validation:** CLI execution stream opening requires Stage 1 burn-in evidence (12h soak, 0 P0/P1, 0 kill-switch, gates green). This is an operational checkpoint, not a governance AC — RC7 is closed.

**Tags**: `ecosystem-v0.1.135-rustify-core1-rc7-executed`

**Next**: RUSTIFY-CORE-1 governance stream complete. Execution proceeds to Stage 1 rollout (app↔app QUIC) per RC6 policy. Residual PM-RC-04/07 are non-blocking.

---

## 2026-03-14 — RUSTIFY-CORE-1 RC6 DONE: Rollout, Compatibility, and Rollback Policy

**RC6 closed**: All 4 ACs (AC-RC-25–28) PASS. Two PM decisions resolved.

**PM-RC-03 APPROVED (2026-03-14):** Rollout order is app-first, browser↔app second.
- Stage 1: app↔app (QUIC primary, DataChannel kill-switch rollback via `transport-quic` feature gate)
- Stage 2: browser↔app (WS-direct primary, WebRTC automatic fallback)
- browser↔browser remains WebRTC invariant (G1)
- Promotion gate: burn-in with zero P0/P1 regressions (PM sets duration, recommended ≥72h)

**PM-RC-05 APPROVED (2026-03-14):** Legacy TS-path deprecation policy is deprecate-but-retain.
- TS paths retained as fallback with kill-switch (RC-G7) throughout deprecated phase
- Sunset requires separate PM approval after: (a) one full release cycle, (b) zero kill-switch activations, (c) zero P0/P1 regressions
- Condition-gated, not date-gated

**AC-RC-25 (rollout policy):** Two-stage rollout codified with promotion gates. TLS/WAN production policy documented (policy-only; no TLS runtime implementation in RC6).

**AC-RC-26 (rollback policy):** 5 triggers (RB-T1–T5), 4 levers (RB-L1–L4), PM ownership, SLA (≤4h P0 decision, ≤1h execution, ≤72h RCA).

**AC-RC-27 (compatibility matrix):** 7-cell endpoint-pair matrix with pass criteria. Verified cells: browser↔browser (baseline), app↔app QUIC (RC3), browser↔app WS (RC5), legacy↔new BTR (BTR-STREAM-1). Deferred: WAN cells (require TLS implementation, post-RC6).

**AC-RC-28 (no-regression gate):** Cross-linked as sub-evidence under AC-RC-25, 26, 27. RC5 regression baselines: 362 daemon tests (ws), 353 (no ws), 364 browser tests — all zero failures.

**Risk RC-R3 mitigation updated:** Kill-switch rollback confirmed active, two-stage rollout, rollback triggers/levers/SLA codified, deprecation condition-gated.

**Tags**: `ecosystem-v0.1.134-rustify-core1-rc6-executed`

**Next**: RC7 — CLI reservation hooks (governance artifacts only, parallel, no dependencies). Remaining PM decisions: PM-RC-04 (performance SLO), PM-RC-06 (CLI trigger), PM-RC-07 (stream relationships).

---

## 2026-03-14 — RUSTIFY-CORE-1 RC5 DONE: AC-RC-23 Closure (BTR Capability over WS)

**AC-RC-23 closed**: Daemon now advertises `bolt.transfer-ratchet-v1` in `DAEMON_CAPABILITIES`. Five new integration tests in `tests/rc5_btr_over_ws.rs`:
- `ac_rc_23_ws_hello_negotiates_btr_capability` — HELLO negotiation over WS includes BTR in intersection
- `ac_rc_23_btr_sealed_chunk_over_ws` — single BTR-sealed chunk survives WS round-trip
- `ac_rc_23_btr_multi_chunk_transfer_over_ws` — 4-chunk BTR transfer over WS
- `ac_rc_23_btr_tampered_chunk_detected_over_ws` — tamper detection preserved over WS
- `ac_rc_23_ws_framing_preserves_sealed_bytes` — byte-level fidelity at 1B/100B/16KiB/64KiB

**RC5 status**: IN-PROGRESS → **DONE**. All 4 ACs (AC-RC-21–24) now PASS.

**Regression**: 362 daemon tests (with ws, 0 failed), 353 daemon (without ws, 0 failed), 364 browser tests (0 failed).

**Tags**: `daemon-v0.2.42-rustify-core1-rc5-btr-ws`, `ecosystem-v0.1.133-rustify-core1-rc5-done`

**Incident continuity**: Prior immutable-tag deletions and Co-Authored-By trailer violations (see entry below) are historical. This commit is fully policy-compliant: forward-only tags, no trailers, no history rewrite.

**Next**: RC6 — rollout policy, production TLS, WAN exposure strategy (requires PM-RC-03/05)

---

## 2026-03-14 — RUSTIFY-CORE-1 RC5 IN-PROGRESS: Browser↔App WebSocket-direct integration

**Decision**: PM-RC-02 APPROVED (WebSocket-direct primary, WebRTC automatic fallback)

**AC Status (RC5)**:
- AC-RC-21: **PASS** — Browser connects to daemon WS endpoint, encrypted HELLO handshake
- AC-RC-22: **PASS** — Bidirectional file transfer over WS (ProfileEnvelopeV1)
- AC-RC-23: **PARTIAL** — WS transport boundary is BTR-transparent (browser propagates BTR fields correctly, 40 BTR wire integration tests pass). Daemon `DAEMON_CAPABILITIES` does not yet include `bolt.transfer-ratchet-v1`, so full end-to-end BTR negotiation browser↔daemon over WS is not yet possible. Blocker: add BTR capability to daemon HELLO.
- AC-RC-24: **PASS** — WS failure (refused/timeout) triggers automatic WebRTC fallback

**Implementation**:
- bolt-daemon: `ws_endpoint.rs` — WS server, feature-gated (`transport-ws`), 4 tests
- bolt-transport-web: `WsDataTransport`, `BrowserAppTransport` — WS client + fallback orchestrator, 20 tests
- DataTransport interface abstraction in EnvelopeCodec (backward-compatible)

**Security**: Session/protocol authority remains in daemon/bolt_core. No protocol reimplementation in browser TS. Fallback path preserves full integrity/BTR enforcement.

**Scope**: RC5 WS is localhost/LAN reference path. ws:// acceptable. wss:// self-signed for test. HTTPS mixed-content caveat documented. Production TLS deferred to RC6.

**Regression**: 357 daemon tests (with ws), 353 (without ws), 364 browser tests — zero failures. G1 (browser↔browser WebRTC) unchanged.

**Tags**: `daemon-v0.2.41-rustify-core1-rc5-ws-endpoint`, `sdk-v0.6.9-rustify-core1-rc5-ws-transport`, `ecosystem-v0.1.132-rustify-core1-rc5-executed`

**Governance note**: Two pushed tags (`daemon-v0.2.39-rustify-core1-rc5-ws-endpoint`, `ecosystem-v0.1.131-rustify-core1-rc5-executed`) were deleted in violation of immutable-tag policy. Corrective action: new forward-only tags created (`daemon-v0.2.41`, `ecosystem-v0.1.132`). No history rewrite performed. Existing commits with prohibited `Co-Authored-By` trailers left as historical violations.

**Next**: Close AC-RC-23 (add `bolt.transfer-ratchet-v1` to daemon capabilities), then RC5 → DONE. After: RC6 — rollout policy, production TLS, WAN exposure strategy (requires PM-RC-03/05)

---

## PM-RC-02 Resolved — WebSocket-Direct Browser↔App Transport, RC5 Unblocked — 2026-03-14

- **PM-RC-02 APPROVED:** Browser↔app primary transport mode resolved as **Option B: WebSocket-direct**.
- **Primary path:** Browser opens WebSocket (WS/WSS) to app daemon endpoint. Daemon terminates WebSocket, deserializes Bolt protocol frames, delegates to shared Rust core for crypto/session/transfer operations.
- **Fallback path (AC-RC-24):** WebRTC via signaling server (current behavior). Trigger: WS connection failure/timeout → automatic client-side fall-through. No manual override required.
- **Session authority:** App daemon / shared Rust core (RC4-consistent per AC-RC-18). Transport-specific auth (connection token, origin validation) deferred to RC5 implementation.
- **Options rejected:** (A) WebRTC-mediated — collapses primary/fallback distinction, makes AC-RC-24 tautological; (C) WebTransport — Safari unsupported, experimental API, unnecessary scope risk.
- **G1 preserved:** WebRTC fallback IS the current browser↔browser baseline path — fully operational.
- **RC5 status:** `NOT-STARTED` → `READY`. All RC5 dependencies satisfied (RC3 DONE, RC4 DONE, PM-RC-02 APPROVED).
- **RC-R4 risk updated:** RESOLVED. Residual: WS TLS cert management deferred to RC5 implementation.
- **DISCOVERY-MODE-1 boundary:** Discovery/signaling policy details remain owned by DISCOVERY-MODE-1 stream. No transport dependency overlap.

**Files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md` (PM-RC-02 → APPROVED, transport matrix row LOCKED, RC5 phase → READY, AC-RC-21–24 annotated with WS context, fallback policy table added, RC-R4 risk → RESOLVED)
- `docs/FORWARD_BACKLOG.md` (RUSTIFY-CORE-1 status updated, PM-RC-02 → APPROVED, dependency matrix updated)
- `docs/STATE.md` (last-updated line, RUSTIFY-CORE-1 stream row)
- `docs/CHANGELOG.md` (this entry)

**Ecosystem Tag:** `ecosystem-v0.1.131-rustify-core1-pmrc02-resolved`

---

## RUSTIFY-CORE-1 RC4 DONE — Shared Rust Core Adoption Verified — 2026-03-14

- **RC4 DONE:** Shared Rust core adoption verified across daemon, app, and TS boundaries.
- **AC-RC-17 DONE:** Daemon shared-core authority verified via comprehensive import audit. All crypto → bolt_core::crypto, session → bolt_core::session, transfer SM → bolt_transfer_core, errors → bolt_core::errors. Zero local reimplementations across 7 source modules. 381 tests pass.
- **AC-RC-18 DONE:** localbolt-app IPC-mediated delegation confirmed as canonical RC4 path. Tauri Rust layer is pure IPC relay + daemon lifecycle manager (3,311 LoC, 0 crypto operations, 0 bolt-core imports). No parallel protocol authority in app shell. `cargo check` clean.
- **AC-RC-19 DONE:** TS delegation boundary verified. Envelope/BTR/SAS/capability negotiation delegates to bolt-core TS SDK. Transfer policy → Rust WASM via PolicyAdapter. WebRTC transport profile intentionally TS-owned (G1 guardrail). 3 moderate concerns deferred to backlog: message type registry centralization, envelope schema constant export, error recovery formalization.
- **AC-RC-20 DONE:** Feature-gate rollback verified. 353 tests pass without `transport-quic` (DataChannel path intact). QUIC tests compile to 0 when feature off. Legacy path fully operational.
- **RC5 status:** Unblocked by RC3+RC4 completion. **Blocked on PM-RC-02** (browser↔app transport mode default).

**RC4 interpretation notes:**
- AC-RC-18: IPC-mediated delegation (localbolt-app → bolt-daemon → shared Rust core) accepted as valid closure. Direct cdylib/UniFFI binding deferred to future stream.
- AC-RC-19: "Where feasible" boundary defined as: crypto/handshake/envelope/capability authority delegated; WebRTC scheduling/backpressure in browser path intentionally TS-owned under G1.

**Files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md` (RC4 phase DONE, AC-RC-17–20 status with evidence, stream status)
- `docs/FORWARD_BACKLOG.md` (RUSTIFY-CORE-1 status updated)
- `docs/STATE.md` (last-updated, stream row)
- `docs/CHANGELOG.md` (this entry)

**Ecosystem Tag:** `ecosystem-v0.1.130-rustify-core1-rc4-executed`

---

## RUSTIFY-CORE-1 RC3 DONE — Quinn QUIC Transport Reference Path — 2026-03-14

- **RC3 DONE:** Native QUIC transport reference path implemented in bolt-daemon via `quinn` v0.11.
- **AC-RC-12 DONE:** Quinn-based QUIC transport compiles and passes 10 unit tests. Feature-gated behind `transport-quic`.
- **AC-RC-13 DONE:** Daemon↔daemon file transfer over QUIC verified. 3 E2E tests: 1MiB SHA-256 integrity, sub-chunk payload, multiple sequential transfers.
- **AC-RC-14 DONE:** BTR-over-QUIC compatibility verified. 4 tests: seal/open roundtrip, multi-chunk chain ordering, tampering detection after transport, byte-level framing preservation. Proves Bolt envelope/BTR remains security authority, QUIC is transport-only.
- **AC-RC-15 DONE (provisional):** ~15–16 MB/s avg throughput (3×1MiB, localhost). PM-RC-04 formal SLO thresholds pending; baseline captured for comparison.
- **AC-RC-16 DONE:** 381 total tests pass (353 pre-existing + 18 RC3 integration + 10 QUIC unit). Zero regressions.
- **QUIC adapter architecture:** `QuicFramedStream` (length-prefixed framing over bidirectional QUIC stream), `QuicListener` (server bind+accept), `QuicDialer` (client connect). RC3 TLS policy: self-signed certs, skip verification, transport encryption only.
- **bolt-btr test-support feature:** Added `test-support` feature to bolt-btr exposing `BtrTransferContext::new_for_test()` for deterministic integration testing.
- **ARCH-01 compliant:** QUIC code confined to daemon (`src/quic_transport.rs`). Zero type leakage into shared core crates.

**Files changed (bolt-daemon):**
- `Cargo.toml` (transport-quic feature, quinn/rustls/tokio/rcgen deps, bolt-btr test-support)
- `src/quic_transport.rs` (NEW — QUIC transport adapter, ~450 lines)
- `src/lib.rs` (conditional quic_transport module export)
- `src/main.rs` (TransportMode enum, CLI flags, QUIC smoke paths)
- `tests/rc3_quic_e2e.rs` (NEW — AC-RC-13/15 E2E tests)
- `tests/rc3_btr_over_quic.rs` (NEW — AC-RC-14 BTR compatibility tests)

**Files changed (bolt-core-sdk):**
- `rust/bolt-btr/Cargo.toml` (test-support feature)
- `rust/bolt-btr/src/state.rs` (new_for_test constructor, feature-gated)

**Daemon Tag:** `daemon-v0.2.40-rustify-core1-rc3-quinn-reference`
**Ecosystem Tag:** `ecosystem-v0.1.129-rustify-core1-rc3-executed`

---

## PM-RC-01A Resolved — Quinn Approved as QUIC Library, RC3 Unblocked — 2026-03-13

- **PM-RC-01A APPROVED:** QUIC runtime/library selection resolved. Primary: `quinn`. Fallback 1: `s2n-quic`. Fallback 2: `msquic-rs`.
- **Rationale:** quinn selected based on weighted evaluation of 6 criteria: cross-platform maturity (macOS/Windows/Linux tested, pure Rust), Rust API ergonomics (AsyncRead/AsyncWrite, tokio-native), ecosystem adoption (133M crates.io downloads vs 407K s2n-quic vs 31K msquic-rs), supply chain posture (pure Rust, audited crypto deps, no C toolchain), mobile path viability (community-validated iOS/Android), and operational debuggability.
- **Fallback order revised from pre-fill:** s2n-quic promoted above msquic-rs (proper async Rust API, biweekly releases, AWS backing vs msquic-rs perpetual beta, callback-based C FFI).
- **Fallback trigger policy:** AC-RC-12/13 failure after ≥2 weeks engineering effort → PM-approved switch. No autonomous library switch by agents.
- **ARCH-01 verified:** quinn wraps behind `bolt_transfer_core::TransportQuery` trait — zero type leakage into shared core.
- **RC3 blocker cleared:** RC3 status moved from NOT-STARTED (blocked on PM-RC-01A) to READY.
- **Risk register updated:** RC-R1 narrowed from "library selection pending" to "quinn execution risk" with explicit mitigations (interop checks, perf/SLO gate, fallback switch criteria, ownership/escalation).

**Files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md` (PM-RC-01A → APPROVED, RC3 → READY, RC-G2 updated, transport matrix updated, RC3 AC section annotated with library/fallback policy, DAG annotation updated, RC-R1 risk updated, summary table updated)
- `docs/FORWARD_BACKLOG.md` (RUSTIFY-CORE-1 status updated, PM-RC-01A → APPROVED, dependency matrix updated)
- `docs/STATE.md` (last-updated line)
- `docs/CHANGELOG.md` (this entry)

**Ecosystem Tag:** `ecosystem-v0.1.128-rustify-core1-pmrc01a-resolved`

---

## RC2-EXEC-E — Session Authority Migration + RC2 Completion (AC-RC-07) — 2026-03-13

- **AC-RC-07 DONE:** Handshake/session authority primitives migrated from daemon to shared Rust core.
  - New `bolt_core::session` module: `SessionState` enum, `SessionContext`, `HelloState` exactly-once guard, `HelloError` with wire codes, `negotiate_capabilities()` set-intersection
  - Daemon rewired: `session.rs` and `web_hello.rs` now re-export from `bolt_core::session`
  - Daemon `CANONICAL_ERROR_CODES` consolidated to `bolt_core::errors::WIRE_ERROR_CODES` (22→26 codes, adds 4 BTR codes)
  - **ARCH-01 compliant:** shared core module contains zero transport/profile/serde references
  - **Profile codecs retained in daemon:** `WebHelloOuter/Inner`, `ProfileEnvelopeV1`, `DcMessage` serde, `build_hello_message`, `parse_hello_typed` — intentionally not migrated (profile-level)
  - **TS delegation deferred to ARCH-WASM1:** TS session state (WebRTCService) remains TS-owned; parity via vectors/tests only
  - 22 new `bolt_core::session` tests + 84 bolt-core total + 27 conformance + 353 daemon tests = all green
- **RC2-EXEC status:** **DONE** (7 of 7 RC2 ACs complete). RC2 COMPLETE.
- **RC2 status:** **DONE**. All acceptance criteria AC-RC-05 through AC-RC-11 satisfied.
- **Next:** RC3 blocked on PM-RC-01A (QUIC library selection).

**Authority migration map:**
| Primitive | Old Location (daemon-local) | New Location (shared core) |
|-----------|---------------------------|---------------------------|
| `SessionState` | N/A (new) | `bolt_core::session::SessionState` |
| `SessionContext` | `bolt_daemon::session::SessionContext` | `bolt_core::session::SessionContext` |
| `HelloState` | `bolt_daemon::web_hello::HelloState` | `bolt_core::session::HelloState` |
| `HelloError` | `bolt_daemon::web_hello::HelloError` | `bolt_core::session::HelloError` |
| `negotiate_capabilities()` | `bolt_daemon::web_hello::negotiate_capabilities` | `bolt_core::session::negotiate_capabilities` |
| `CANONICAL_ERROR_CODES` | `bolt_daemon::envelope::CANONICAL_ERROR_CODES` (22) | `bolt_core::errors::WIRE_ERROR_CODES` (26, re-exported) |

**Retained in daemon (ARCH-01 boundary proof):**
- `WebHelloOuter`, `WebHelloInner` (serde wire structs)
- `build_hello_message()`, `parse_hello_typed()`, `parse_hello_message()` (JSON codec)
- `ProfileEnvelopeV1`, `DcErrorMessage` (serde wire structs)
- `encode_envelope()`, `decode_envelope()`, `route_inner_message()` (NaCl+JSON codec)
- `InteropHelloMode`, `DAEMON_CAPABILITIES`, `daemon_capabilities()` (daemon config)
- `web_signal.rs` entire module (web schema adapter)
- `dc_messages.rs` entire module (serde codec)

**bolt-core-sdk files changed:**
- `rust/bolt-core/src/session.rs` (NEW: session authority primitives)
- `rust/bolt-core/src/lib.rs` (add `pub mod session`, update module map)

**bolt-daemon files changed:**
- `src/session.rs` (rewired: re-exports from `bolt_core::session`)
- `src/web_hello.rs` (rewired: `HelloState`, `HelloError`, `negotiate_capabilities` from `bolt_core::session`)
- `src/envelope.rs` (rewired: `CANONICAL_ERROR_CODES` → `bolt_core::errors::WIRE_ERROR_CODES`, `validate_inbound_error` uses `is_valid_wire_error_code`)
- `src/lib.rs` (test_support: add `SessionState` re-export)

**bolt-ecosystem files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md` (AC-RC-07 → DONE, RC2 → DONE, evidence scope note)
- `docs/FORWARD_BACKLOG.md` (RUSTIFY-CORE-1 status: RC2 DONE)
- `docs/STATE.md` (last updated)
- `docs/CHANGELOG.md` (this entry)

**SDK Tag:** `sdk-v0.5.45-rc2exec-e-session-authority`
**Daemon Tag:** `daemon-v0.2.39-rc2exec-e-session-rewire`
**Ecosystem Tag:** `ecosystem-v0.1.127-rustify-core1-rc2-complete`

---

## RC2-EXEC-D — Unified API Surface + FFI Boundary Lock (AC-RC-05, AC-RC-06) — 2026-03-13

- **AC-RC-05 DONE:** Unified Rust core API surface verified and documented.
  - Direct multi-crate dependency policy confirmed as canonical integration model (no facade/umbrella crate)
  - 4-crate API surface registry: `bolt-core` (v0.4.0), `bolt-btr` (v0.1.0), `bolt-transfer-core` (v0.1.0), `bolt-transfer-policy-wasm` (v0.1.0)
  - Full public API entrypoints documented in `docs/API_SURFACE.md`
  - Consumer matrix: bolt-daemon (Rust-direct), localbolt-v3 (WASM), localbolt-app (Tauri IPC)
  - 338 Rust tests pass (58 bolt-core + 63 bolt-btr + 93 bolt-transfer-core + 36 BTR vectors + 14 WASM parity + conformance)
- **AC-RC-06 DONE (verification closure):** Consumer boundary contract documented.
  - Closure mode: **verification** — existing boundaries ARE the canonical contract
  - Three boundary types: Rust-direct (bolt-daemon), WASM/wasm-bindgen (browser), Tauri IPC/NDJSON (native app)
  - No UniFFI/cbindgen needed — no non-Rust native consumers exist
  - Boundary contract documented in `docs/BOUNDARY_CONTRACT.md`
  - Ad-hoc path audit: no duplicate bridge paths found; session/handshake lifecycle deferred to AC-RC-07
  - `docs/SDK_AUTHORITY.md` updated: version correction (bolt-core 0.1.0→0.4.0), vector authority now Rust-canonical, cross-references to new docs
- **AC-RC-07 boundary:** Session/handshake lifecycle (pre_hello/post_hello/closed, verification state, capability dispatch) remains TS-owned in bolt-daemon's web_hello.rs/session.rs. Explicitly deferred to AC-RC-07 in a dedicated RC2-EXEC-E pass.
- **RC2-EXEC status:** IN-PROGRESS (6 of 7 RC2 ACs complete: AC-RC-05, AC-RC-06, AC-RC-08, AC-RC-09, AC-RC-10, AC-RC-11). Only AC-RC-07 remains.

**bolt-core-sdk files changed:**
- `docs/API_SURFACE.md` (NEW: unified Rust API surface registry)
- `docs/BOUNDARY_CONTRACT.md` (NEW: consumer boundary contract, 3 boundary types)
- `docs/SDK_AUTHORITY.md` (updated: version correction, vector authority, cross-references)

**bolt-ecosystem files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md` (AC-RC-05 → DONE, AC-RC-06 → DONE)
- `docs/FORWARD_BACKLOG.md` (RUSTIFY-CORE-1 status updated)
- `docs/STATE.md` (last updated)
- `docs/CHANGELOG.md` (this entry)

**SDK Tag:** `sdk-v0.5.44-rc2exec-d-api-ffi`
**Ecosystem Tag:** `ecosystem-v0.1.126-rustify-core1-rc2exec-d-recorded`

---

## RC2-EXEC-C — Protocol State-Machine Authority in Rust (AC-RC-10) — 2026-03-13

- **AC-RC-10 DONE:** Protocol state machines verified as Rust-canonical.
  - **Transfer SM** (TransferState, SendSession, ReceiveSession): canonical in `bolt-transfer-core`
  - **BTR SM** (BtrEngine, BtrTransferContext, ReplayGuard, negotiate_btr): canonical in `bolt-btr`
  - **Backpressure/Policy** (BackpressureController, StallClassification): canonical in `bolt-transfer-core`, WASM-exported
  - TS implementations are parity copies validated by 15 cross-language vector files (10 BTR + 5 core)
  - 11 new authority conformance tests in `state_machine_authority.rs`
  - Conformance harness: 43 tests (was 32)
- **AC-RC-07 boundary:** Session/handshake lifecycle (pre_hello/post_hello/closed, verification state, capability dispatch) remains TS-owned. Explicitly out of AC-RC-10 scope — deferred to AC-RC-07 in a future RC2-EXEC pass.
- **SEC-CORE2 absorption:** AC-SC-03 → AC-RC-10: **DONE**
- **RC2-EXEC status:** IN-PROGRESS (4 of 7 RC2 ACs complete: AC-RC-08, AC-RC-09, AC-RC-10, AC-RC-11)

**bolt-core-sdk files changed:**
- `rust/bolt-core/tests/conformance/state_machine_authority.rs` (NEW: 11 authority tests)
- `rust/bolt-core/tests/conformance/main.rs` (register new module, update doc comment)
- `rust/bolt-core/Cargo.toml` (dev-dependencies: bolt-transfer-core, bolt-btr)

**bolt-ecosystem files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md` (AC-RC-10 → DONE, AC-SC-03 → DONE)
- `docs/FORWARD_BACKLOG.md` (RUSTIFY-CORE-1 status updated, AC-SC-03 → DONE)
- `docs/STATE.md` (last updated)
- `docs/CHANGELOG.md` (this entry)

**SDK Tag:** `sdk-v0.5.43-rc2exec-c-state-authority`
**Ecosystem Tag:** `ecosystem-v0.1.125-rustify-core1-rc2exec-c-recorded`

---

## RC2-EXEC-B — S1 Conformance on Rust-Canonical Vectors (AC-RC-11) — 2026-03-13

- **AC-RC-11 DONE:** S1 conformance test harness passes against Rust-generated vectors.
  - Conformance suite (32 tests) rewired from legacy TS vector path to `test-vectors/core/`
  - Files rewired: `envelope_validation.rs`, `sas_determinism.rs`
  - CI workflow paths updated: `ci.yml`, `ci-rust.yml` trigger on `rust/bolt-core/test-vectors/**`
  - Full validation: 115 Rust tests + 232 TS tests pass
  - Failure-mode guard: `vector_equivalence.rs` detects drift between regenerated and committed vectors
- **SEC-CORE2 absorption progress:**
  - AC-SC-04 → AC-RC-11: **DONE**
- **RC2-EXEC status:** IN-PROGRESS (3 of 7 RC2 ACs complete: AC-RC-08, AC-RC-09, AC-RC-11)

**bolt-core-sdk files changed:**
- `rust/bolt-core/tests/conformance/envelope_validation.rs` (rewired vectors_dir + doc comment)
- `rust/bolt-core/tests/conformance/sas_determinism.rs` (rewired vectors_dir + doc comment)
- `.github/workflows/ci-rust.yml` (trigger path updated)
- `.github/workflows/ci.yml` (trigger path updated)

**bolt-ecosystem files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md` (AC-RC-11 → DONE, AC-SC-04 → DONE)
- `docs/FORWARD_BACKLOG.md` (RUSTIFY-CORE-1 status updated, AC-SC-04 → DONE)
- `docs/STATE.md` (last updated)
- `docs/CHANGELOG.md` (this entry)

**SDK Tag:** `sdk-v0.5.42-rc2exec-b-s1-conformance`
**Ecosystem Tag:** `ecosystem-v0.1.124-rustify-core1-rc2exec-b-recorded`

---

## RC2-EXEC-A — Vector Authority Migration (AC-RC-08, AC-RC-09) — 2026-03-13

- **AC-RC-08 DONE:** All golden test vectors now generated by Rust canonical generator.
  - 5 core vectors (box-payload, framing, SAS, HELLO-open, envelope-open) in `rust/bolt-core/test-vectors/core/`
  - 10 BTR vectors already Rust-canonical in `rust/bolt-core/test-vectors/btr/`
  - New generators: `generate_sas_json()`, `generate_hello_open_json()`, `generate_envelope_open_json()`
  - Golden test: `vector_golden_core.rs` (6 tests, determinism verified)
  - All Rust consumers rewired to `test-vectors/core/` (115 tests pass)
  - All TS consumers rewired to `rust/bolt-core/test-vectors/core/` (232 tests pass)
- **AC-RC-09 DONE:** TS vector generation deprecated.
  - `@deprecated` JSDoc on `print-test-vectors.mjs` and `generate-h3-vectors.mjs`
  - Runtime deprecation warnings in npm scripts
  - `VECTOR_AUTHORITY.md` migration document created
  - TS generators retained for transitional reference (no deletion this pass)
- **SEC-CORE2 absorption progress:**
  - AC-SC-01 → AC-RC-08: **DONE**
  - AC-SC-02 → AC-RC-09: **DONE**
- **RC2-EXEC status:** IN-PROGRESS (2 of 7 RC2 ACs complete)
- **Roundtrip verified:** Rust generates → Rust consumes + passes → TS consumes + passes

**bolt-core-sdk files changed:**
- `rust/bolt-core/src/vectors.rs` (extended: SAS, HELLO-open, envelope-open generators)
- `rust/bolt-core/src/lib.rs` (doc comment updated: Rust canonical)
- `rust/bolt-core/tests/vector_golden_core.rs` (NEW: golden generation tests)
- `rust/bolt-core/tests/vector_equivalence.rs` (rewired to test-vectors/core/)
- `rust/bolt-core/tests/vector_compat.rs` (rewired to test-vectors/core/)
- `rust/bolt-core/tests/h3_open_vectors.rs` (rewired to test-vectors/core/)
- `rust/bolt-core/tests/sas_vectors.rs` (rewired to test-vectors/core/)
- `rust/bolt-core/test-vectors/core/*.vectors.json` (NEW: 5 canonical vector files)
- `ts/bolt-core/__tests__/vectors.test.ts` (rewired to Rust vectors)
- `ts/bolt-core/__tests__/sas.test.ts` (rewired to Rust vectors)
- `ts/bolt-core/__tests__/hello-open-vectors.test.ts` (rewired to Rust vectors)
- `ts/bolt-core/__tests__/envelope-open-vectors.test.ts` (rewired to Rust vectors)
- `ts/bolt-core/scripts/print-test-vectors.mjs` (deprecated)
- `ts/bolt-core/scripts/generate-h3-vectors.mjs` (deprecated)
- `ts/bolt-core/package.json` (scripts updated with deprecation notices)
- `VECTOR_AUTHORITY.md` (NEW: migration documentation)

**bolt-ecosystem files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md` (AC-RC-08/09 status → DONE, SEC-CORE2 mapping updated)
- `docs/FORWARD_BACKLOG.md` (RUSTIFY-CORE-1 status → EXEC-IN-PROGRESS, SEC-CORE2 ACs updated)
- `docs/STATE.md` (last updated)
- `docs/CHANGELOG.md` (this entry)

**SDK Tag:** `sdk-v0.5.41-rc2exec-a-vector-authority`
**Ecosystem Tag:** `ecosystem-v0.1.123-rustify-core1-rc2exec-a-recorded`

---

## RC2-GOV Executed — Shared Rust Core API Governance Lock — 2026-03-13

- **RC2-GOV DONE.** Governance/spec decisions for shared Rust core API locked. Code execution deferred to RC2-EXEC.
- **Adoption vs extraction lock:** Adoption-first for existing crates (`bolt-core`, `bolt-btr`, `bolt-transfer-core`, `bolt-transfer-policy-wasm`). Extraction only for missing seams or duplication.
- **Integration topology lock:** Direct multi-crate dependency policy (LOCKED). No facade/umbrella crate. Consumers import specific crates directly. Established pattern confirmed from codebase audit (bolt-daemon already uses this model).
- **Canonical authority + adapter contracts:**
  - Rust core crates are protocol/security authority. No TS/platform reimplementation permitted.
  - Platform adapters (TS/Tauri/Swift) are thin I/O + UI shells. Must not duplicate protocol logic.
  - Adapter violations are RC2-EXEC review findings.
- **Compatibility/versioning policy:** Semver for all shared core crates. One minor version deprecation window. Breaking changes require major bump + migration note. Cross-crate breaks coordinated as workspace-wide bump.
- **SEC-CORE2 absorption mapping (PROVISIONAL, pending PM-RC-07):**
  - AC-SC-01 → AC-RC-08, AC-SC-02 → AC-RC-09, AC-SC-03 → AC-RC-10, AC-SC-04 → AC-RC-11
- **AC scope split:**
  - AC-RC-05: PARTIAL (spec lock GOV-DONE; code verification in EXEC)
  - AC-RC-06: PARTIAL (boundary contracts GOV-DONE; codegen/impl in EXEC)
  - AC-RC-07..11: DEFERRED to RC2-EXEC
  - AC-RC-03: confirmed DONE (PM-RC-01 approved)
- **RC2 status:** GOV-DONE, EXEC-READY (no blockers for RC2-EXEC)
- **RC3 status:** unchanged (blocked on PM-RC-01A per existing DAG)
- **DAG verified:** RC3→RC2, RC4→RC2, RC5→RC3+RC4 (unchanged)

**Files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md`
- `docs/FORWARD_BACKLOG.md`
- `docs/STATE.md`
- `docs/CHANGELOG.md`

**Tag:** `ecosystem-v0.1.122-rustify-core1-rc2gov-executed`

---

## PM-RC-01 Resolved — QUIC Confirmed, RC2 READY — 2026-03-13

- **PM-RC-01 APPROVED:** Native transport protocol confirmed as **QUIC** for `app↔app` primary path in RUSTIFY-CORE-1.
- **Transport matrix update:**
  - `app↔app` = Rust native transport, QUIC (**LOCKED** — was PROVISIONAL pending PM-RC-01)
  - `browser↔browser` = WebRTC DataChannel (**LOCKED** — retained baseline, unchanged)
  - `browser↔app` = unchanged (PROVISIONAL — pending PM-RC-02)
  - `app↔relay/cloud` = unchanged (DEFERRED)
- **PM-RC-01A created (sub-decision):**
  - Title: QUIC runtime/library selection
  - Shortlist: `quinn`, `s2n-quic`, `msquic-rs`
  - Owner: TBD (PM to assign)
  - Deadline: TBD (PM to assign)
  - Blocking policy: Blocks RC3 only; non-blocking for RC2
- **RC2 gate transition:**
  - Previous: **BLOCKED (PM-RC-01)**
  - New: **READY** — all RC2 entry criteria now satisfied
  - No other pre-existing blockers discovered
- **AC-RC-03:** PROVISIONAL → **DONE** (PM-RC-01 resolved)
- **Risk register:** RC-R1 protocol-choice risk resolved by PM-RC-01 (QUIC confirmed). Residual risk (library maturity/maintenance/perf tradeoff) moved to PM-RC-01A.

**Files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md`
- `docs/FORWARD_BACKLOG.md`
- `docs/STATE.md`
- `docs/CHANGELOG.md`

**Tag:** `ecosystem-v0.1.121-rustify-core1-pmrc01-quic-locked`

---

## RUSTIFY-CORE-1 RC1 Executed — Transport Matrix + Boundary Lock — 2026-03-13

- **RUSTIFY-CORE-1 RC1 DONE.** Transport matrix, rustification boundary, and relationship mapping locked.
- **Transport matrix (RC1 LOCKED):**
  - `browser↔browser` = WebRTC DataChannel (**LOCKED** — retained baseline, invariant)
  - `app↔app` = Rust native transport, QUIC recommended (**PROVISIONAL** — pending PM-RC-01)
  - `browser↔app` = browser client transport + Rust endpoint/core (**PROVISIONAL** — pending PM-RC-02)
  - `app↔relay/cloud` = **DEFERRED** (out of scope RC1–RC4, ByteBolt scope per ARCH-05/ARCH-07)
- **Rustification boundary (RC1 LOCKED):**
  - Rust owns: shared protocol/security core, transfer SM integrity/policy authority, lifecycle invariants
  - Platform adapters (TS/Swift/Tauri): thin I/O/UI shells over unified Rust backend
  - RC1 is boundary/spec lock only — no extraction or adoption execution
- **Relationship mapping (PROVISIONAL, pending PM-RC-07):**
  - SUPERSEDES (provisional): SEC-CORE2, PLAT-CORE1
  - REFACTORS/DEPENDS-ON (provisional): MOB-RUNTIME1, ARCH-WASM1
  - No silent supersession until PM-RC-07 confirms
- **RC1 ACs:** AC-RC-01 DONE, AC-RC-02 DONE, AC-RC-03 PROVISIONAL (PM-RC-01 pending), AC-RC-04 DONE
- **RC2 state:** **BLOCKED (PM-RC-01)** — PM-RC-01 unresolved, no approved fallback. PM-RC-02 non-blocking for RC2.
- **RC2 entry criteria codified:** RC1 lock (satisfied), PM-RC-01 explicit (not satisfied), PM-RC-02 impact explicit (satisfied, non-blocking), PM-RC-07 handling explicit (satisfied, provisional accepted).

**Files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md`
- `docs/FORWARD_BACKLOG.md`
- `docs/STATE.md`
- `docs/CHANGELOG.md`

**Tag:** `ecosystem-v0.1.120-rustify-core1-rc1-executed`

---

## CONSUMER-BTR1 Closed — CBTR-3 Burn-in Waiver (PM-CBTR-EX-01) — 2026-03-13

- **CONSUMER-BTR1 DONE.** All three consumer BTR rollout phases complete.
- **CBTR-1:** DONE, burn-in PASSED (localbolt-v3).
- **CBTR-2:** DONE, burn-in PASSED, 24h02m (localbolt).
- **CBTR-3:** DONE, burn-in **waived** via `PM-CBTR-EX-01` (localbolt-app).
- **Waiver rationale:** CBTR-3 test matrix passed (74 web + 82 Rust = 156 total); CBTR-2 completed full 24h soak; CBTR-3 is identical low-delta config change; schedule benefit outweighs residual risk.
- **Non-precedent:** This waiver does not automatically waive burn-in for future runtime streams.
- **Residual risk:** CBTR-3 full 24h soak not completed. Enhanced monitoring required for 24h post-close.
  - Rollback trigger: error spikes, transfer integrity failures, pause/resume regressions.
  - Rollback path: `btrEnabled: false` in `localbolt-app/web/src/components/peer-connection.ts`.
  - Owner: PM. Response SLA: immediate rollback on P0/P1 regression.
- **Burn-in audit trail:** CBTR-3 burn-in started 2026-03-13 04:54 UTC; waived 2026-03-13 (PM-CBTR-EX-01).
- **Downstream unblocked:** RUSTIFY-CORE-1 RC1 is now unblocked.

**Files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md`
- `docs/STATE.md`
- `docs/FORWARD_BACKLOG.md`
- `docs/CHANGELOG.md`

**Tag:** `ecosystem-v0.1.119-consumer-btr1-burnin-waiver-close`

---

## BTR-SPEC-1 — Stream Codified (Algorithm-Grade BTR Protocol Specification) — 2026-03-13

- **BTR-SPEC-1 CODIFIED:** New governance stream for formal BTR protocol specification.
- **P0 audit:** 5/7 candidate modules fully specified in PROTOCOL.md §16. 2 gaps: flow control/backpressure (BTR-FC), resume/recovery (BTR-RSM).
- **7 modules confirmed:** BTR-HS, BTR-KS, BTR-INT, BTR-FC (gap), BTR-RSM (gap), BTR-WIRE, BTR-CNF
- **5 phases:** BS1 (taxonomy) → BS2 (state machines + crypto) → BS3 (wire + recovery) → BS4 (conformance) → BS5 (versioning + review readiness)
- **22 acceptance criteria:** AC-BS-01 through AC-BS-22
- **6 PM decisions:** PM-BS-01 through PM-BS-06
- **Relationship:** COMPLEMENTS SEC-BTR1 (complete), CONSUMER-BTR1 (in-progress), RUSTIFY-CORE-1 (codified)
- **Priority:** NEXT. BS1 unblocked immediately. No upstream dependencies.

**Files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md`
- `docs/FORWARD_BACKLOG.md`
- `docs/STATE.md`
- `docs/CHANGELOG.md`
- `docs/AUDIT_TRACKER.md`

**Tag:** `ecosystem-v0.1.118-btr-spec1-codify`

---

## CBTR-3 P3 Executed + CBTR-2 Burn-in PASSED — 2026-03-12

- **CBTR-2 burn-in PASSED:** Start 2026-03-12 04:16:44 UTC, passed at 2026-03-13 04:18:54 UTC (24h 02m 10s).
- **CBTR-3 P3 DONE:** BTR enabled in localbolt-app (`btrEnabled: true`).
- **SDK publishes:** `@the9ines/bolt-core@0.5.2` (BTR negotiation exports), `@the9ines/bolt-transport-web@0.6.8` (BTR wire integration + CBTR-F1 fix).
- **Tests:** 74 web + 82 Rust = 156 total in localbolt-app (10 new CBTR-3 tests).
- **All AC satisfied:** AC-CBTR-14 through AC-CBTR-20.
- **CONSUMER-BTR1 status:** IN-PROGRESS — CBTR-3 burn-in active, 24h gate required before stream closure.
- **Rollback:** `btrEnabled: false` in `web/src/components/peer-connection.ts`.

**Files changed:**
- docs/GOVERNANCE_WORKSTREAMS.md
- docs/STATE.md
- docs/CHANGELOG.md

**Tags:**
- localbolt-app: `localbolt-app-v1.2.24-consumer-btr1-p3` (`ff33747`)
- bolt-core-sdk: `fd04721` (transport-web 0.6.8 publish), `01eca1c` (bolt-core 0.5.2 publish)

**Tag:** `ecosystem-v0.1.117-cbtr3-p3-executed`

---

## DISCOVERY-MODE-1 — Stream Codified (Dual Discovery Mode Policy) — 2026-03-12

- **DISCOVERY-MODE-1 CODIFIED:** New governance stream for explicit discovery mode policy codification.
- **P0 audit confirmed:** Dual-signaling behavior correct but undocumented at governance level. 5 ambiguities identified (no UI mode indicator, no peer origin in UI, inconsistent env vars, undocumented dedup, CLOUD_ONLY not possible).
- **Mode definitions:**
  - `LAN_ONLY` (required): Local signaling only, cloud disabled/absent
  - `HYBRID` (required, recommended default): Local + cloud merged, first-discovery-wins dedup
  - `CLOUD_ONLY` (deferred): Reserved as future extension pending PM-DM-04
- **5 dedup invariants codified:** DM-DEDUP-01 through DM-DEDUP-05
- **4 phases defined:** DM1 (PM policy lock) → DM2 (mode indicators) → DM3 (test harness) → DM4 (env var harmonization + closure)
- **16 acceptance criteria:** AC-DM-01 through AC-DM-16
- **4 PM decisions opened:** PM-DM-01 through PM-DM-04
- **5 scope guardrails:** DM-G1 through DM-G5
- **Priority:** NEXT (no upstream dependencies; orthogonal to all active streams)
- **Risk register:** No material risks identified

**Files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md`
- `docs/FORWARD_BACKLOG.md`
- `docs/STATE.md`
- `docs/CHANGELOG.md`
- `docs/AUDIT_TRACKER.md`

**Tag:** `ecosystem-v0.1.116-discovery-mode1-codify`

---

## EGUI-NATIVE-1 — Stream Codified (Native Desktop UI Consolidation) — 2026-03-12

- **EGUI-NATIVE-1 CODIFIED:** New governance stream for desktop UI migration from Tauri WebView to egui (Rust-native GUI).
- **Scope:** Desktop-only (macOS/Windows/Linux). Browser and mobile UI migration explicitly deferred to EGUI-WASM-1 and EGUI-MOBILE-1 (governance reservations only).
- **5 phases defined:** EN1 (PM framework lock) → EN2 (bolt-ui scaffold + theme) → EN3 (feature parity) → EN4 (rollback/packaging gate) → EN5 (closure + handoff)
- **24 acceptance criteria:** AC-EN-01 through AC-EN-24
- **5 PM decisions opened:** PM-EN-01 through PM-EN-05
- **8 scope guardrails:** EN-G1 through EN-G8
- **6 risks identified:** EN-R1 through EN-R6
- **Dependency:** EN1 (PM gate) openable in parallel with RUSTIFY-CORE-1 RC1–RC4. EN2+ blocked on RUSTIFY-CORE-1 RC4 (shared Rust core API).
- **Priority:** LATER
- **Deferred streams reserved:** EGUI-WASM-1 (browser, after EN3), EGUI-MOBILE-1 (mobile, after EN4)

**Files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md`
- `docs/FORWARD_BACKLOG.md`
- `docs/STATE.md`
- `docs/CHANGELOG.md`
- `docs/AUDIT_TRACKER.md`

**Tag:** `ecosystem-v0.1.115-egui-native1-codify`

---

## RUSTIFY-CORE-1 — Stream Codified (Native-First Transport + Core Consolidation) — 2026-03-12

- **RUSTIFY-CORE-1 CODIFIED:** New governance stream for native-first transport and Rust core consolidation.
- **Transport matrix (policy draft):**
  - browser↔browser: WebRTC (retained baseline)
  - app↔app: Rust native transport (QUIC recommended, PM-RC-01 pending)
  - browser↔app: browser client transport + Rust endpoint/core
- **7 phases defined:** RC1 (transport matrix lock) → RC2 (shared Rust core API) → RC3 (native transport) ∥ RC4 (core adoption) → RC5 (browser↔app) → RC6 (rollout) + RC7 (CLI reservation, parallel)
- **33 acceptance criteria:** AC-RC-01 through AC-RC-33
- **7 PM decisions opened:** PM-RC-01 through PM-RC-07
- **Stream relationships (provisional, pending PM-RC-07):**
  - Provisionally SUPERSEDES: SEC-CORE2, PLAT-CORE1
  - Provisionally REFACTORS/DEPENDS-ON: MOB-RUNTIME1, ARCH-WASM1
- **Priority:** NEXT (blocked until CONSUMER-BTR1 completes)
- **Deferred:** CLI implementation (RC7 produces governance reservation artifacts only)

**Files changed:**
- `docs/GOVERNANCE_WORKSTREAMS.md`
- `docs/FORWARD_BACKLOG.md`
- `docs/STATE.md`
- `docs/CHANGELOG.md`

**Tag:** `ecosystem-v0.1.113-rustify-core1-codify`

---

## CONSUMER-BTR-1 — CBTR-2 P2 Executed (localbolt BTR Enabled) — 2026-03-11

- **CBTR-1 burn-in PASSED:** 24h gate completed. Multiple real transfers, zero BTR protocol errors.
- **CBTR-2 P2 DONE:** `btrEnabled: true` added to localbolt `peer-connection.ts` WebRTCServiceOptions
  - Tag: `localbolt-v1.0.36-consumer-btr1-p2` (`e75271a`)
  - Tests: 324 passing (16 test files), build green
  - 6 new compatibility tests in `cbtr2-btr-compatibility.test.ts`
  - SDK dependency: bolt-core 0.5.1 + bolt-transport-web 0.6.7 (BTR-4-capable)
- **Burn-in gate:** 24h clean run required before CBTR-3 (localbolt-app)
- Tag: `ecosystem-v0.1.112-cbtr2-p2-executed`

---

## CBTR-F1 — Receiver Pause/Resume Fix (CBTR-PAUSE-1) — 2026-03-11

- **Finding:** CBTR-F1 (MEDIUM) — receiver cannot pause/resume transfer. Pre-existing transport control asymmetry, not a BTR regression.
- **Root cause:** `pauseTransfer()` / `resumeTransfer()` used sender-only `getSendTransferIds()` lookup. `cancelTransfer()` already had bidirectional `isReceiver` parameter.
- **Fix:** Added `isReceiver` parameter to `pauseTransfer()` and `resumeTransfer()` in TransferManager.ts and WebRTCService.ts, mirroring the existing `cancelTransfer()` dual-lookup pattern.
- **Tests:** 6 new tests (receiver pause/resume send canonical control, graceful failure on wrong map, sender backward compat). 344 TS + 266 Rust pass.
- **Status:** **FIXED** — `sdk-v0.5.40-cbtr-f1-receiver-pause` (`c164fc1`). CBTR-2/3 unblocked.
- **Governance:** Codified as `ecosystem-v0.1.110-cbtr-pause1-codify`, resolved as `ecosystem-v0.1.111-cbtr-f1-fixed`

---

## CONSUMER-BTR-1 — CBTR-1 P1 Executed (localbolt-v3 BTR Enabled) — 2026-03-11

- **PM-CBTR-01 APPROVED:** Rollout order confirmed — localbolt-v3 → localbolt → localbolt-app
- **PM-CBTR-02 APPROVED:** 24h clean run per phase before promoting to next consumer
- **CBTR-1 P1 DONE:** `btrEnabled: true` added to localbolt-v3 `peer-connection.ts` WebRTCServiceOptions
  - Tag: `v3.0.89-consumer-btr1-p1` (`e34e617`)
  - Tests: 145 passing (75 localbolt-web + 70 localbolt-core), build green
  - 6 new compatibility tests in `cbtr1-btr-compatibility.test.ts`
- **Burn-in gate:** 24h clean run required before CBTR-2 (localbolt)
- **Governance sync:** PM decisions, STATE.md, FORWARD_BACKLOG.md updated
- Tag: `ecosystem-v0.1.109-cbtr1-p1-executed`

---

## CONSUMER-BTR-1 — Stream Codification (Consumer App BTR Rollout) — 2026-03-11

- **New stream codified:** CONSUMER-BTR-1 (outside BTR-STREAM-1 per BTR-G8)
- **Scope:** Roll out BTR-capable SDK to all three consumer apps with `btrEnabled: true`
- **Phases:** CBTR-1 (localbolt-v3), CBTR-2 (localbolt), CBTR-3 (localbolt-app) — fully parallelizable
- **Acceptance criteria:** 20 ACs defined (AC-CBTR-01 through AC-CBTR-20)
- **Audit tracker:** CBTR-F series reserved (CBTR-F1–CBTR-F99)
- **Dependencies:** BTR-STREAM-1 complete (satisfied)
- **PM decisions pending:** PM-CBTR-01 (phase sequencing), PM-CBTR-02 (burn-in model)
- **Governance updates:** GOVERNANCE_WORKSTREAMS.md, FORWARD_BACKLOG.md, STATE.md, AUDIT_TRACKER.md
- Tag: `ecosystem-v0.1.108-consumer-btr1-codify`

---

## BTR-5 — Default-On Decision Gate — COMPLETE (SEC-BTR1) — 2026-03-11

- **BTR-STREAM-1 COMPLETE:** All 6 phases (BTR-0 through BTR-5) done. All 40 acceptance criteria satisfied (AC-BTR-36 deferred to ByteBolt stream, non-blocking).
- **BTR-4 DONE:** Wire integration (`sdk-v0.5.39-btr4-wire-integration`, `a7b3a7b`):
  - 5-cell negotiation matrix, envelope fields, BtrTransferAdapter, kill switch, 40 integration tests
  - Validation: 338/338 transport-web, BTR conformance 5/5, Rust fmt/clippy clean, constants parity PASS
- **BTR-5 GO:** PM decision gate resolved. Option C approved (default-on, fail-open with downgrade-with-warning).
- **PM decisions resolved (2026-03-11):**
  - PM-BTR-08: **APPROVED** — dark launch = 14 consecutive days, zero BTR protocol errors
  - PM-BTR-09: **APPROVED** — legacy deprecation = 6 months after default-on + >95% adoption + external audit
  - PM-BTR-11: **APPROVED** — external audit before GA/legacy deprecation, not before default-on
- **Decision memo:** `docs/BTR5_DECISION_MEMO.md` (status: GO)
- **Evidence index:** `docs/BTR5_EVIDENCE_INDEX.md` (AC-BTR-32–40 all mapped/satisfied)
- **Governance sync:** Phase table, STATE.md, FORWARD_BACKLOG.md all reconciled to COMPLETE
- Tags: `ecosystem-v0.1.106-btr5-decision-gate` (memo), `ecosystem-v0.1.107-btr5-pm-resolved` (closeout)

---

## BTR-3 — Conformance Gap-Fill + Lifecycle Vectors (SEC-BTR1) — 2026-03-10

- **BTR-3 DONE:** Cross-language conformance gap-fill with lifecycle vectors and adversarial coverage.
- **P2 — Full-lifecycle vector** (`btr-lifecycle.vectors.json`):
  - 2 transfers × 3 chunks each, deterministic `StaticSecret` keypairs, fixed nonces
  - Proves DH ratchet advances session root between transfers (EPOCH-BTR)
  - Proves transfer isolation (ISOLATION-BTR) and multi-chunk seal/open parity
  - TS consumes and validates all 28 lifecycle assertions against Rust authority
- **P3 — Adversarial gap-fill** (`btr-adversarial.vectors.json`):
  - Wrong-key decrypt: valid ciphertext sealed with correct key, opened with wrong key → RATCHET_DECRYPT_FAIL
  - Chain-index desync: receiver at idx=0, open at idx=2 → RATCHET_CHAIN_ERROR
  - Both Rust and TS produce matching error classes
- **P4 — CI trigger + execution fix:**
  - Rust CI working-directory: `rust/bolt-core` → `rust/` (workspace root) for full workspace fmt/clippy/test
  - TS CI trigger paths: added `rust/bolt-core/test-vectors/btr/**` so vector changes re-trigger TS parity tests
  - Pre-existing clippy lint in bolt-transfer-policy-wasm suppressed (WASM flat-arg signature)
- **P6 — BTR constants parity check** (`scripts/verify-btr-constants.sh`):
  - Verifies 5 HKDF info strings, BTR_KEY_LENGTH, and 4 wire error codes Rust↔TS
  - Wired into CI gate (runs before TS build)
- **P1 — Unified conformance wrapper** (`scripts/btr-conformance.sh`):
  - Runs 5 checks: Rust unit, Rust vectors, TS tests, BTR constants, core constants
  - Emits pass/fail summary
- **P5 — BTR vector policy** (`docs/BTR_VECTOR_POLICY.md` in bolt-ecosystem):
  - Authority path, regeneration command, review requirement for vector changes
- **Vector categories: 8 → 10** (+lifecycle, +adversarial)
- **Tests:** 69 Rust bolt-btr (58 unit + 11 golden), 232 TS total, 280 Rust workspace total. 0 regressions.
- Tag: `sdk-v0.5.38-btr3-conformance-gapfill` (`ec37998`)

---

## BTR-2 — TypeScript Parity + Deterministic Interop Vectors (SEC-BTR1) — 2026-03-10

- **BTR-2 DONE:** TypeScript parity implementation matching Rust BTR-1 outputs exactly.
- **New TS modules: `ts/bolt-core/src/btr/`** — 8 files, full engine parity:
  - `constants.ts`: 5 HKDF info strings, key length, 4 BTR wire error codes
  - `errors.ts`: BtrError class with wireCode + requiresDisconnect() semantics
  - `key-schedule.ts`: deriveSessionRoot, deriveTransferRoot, chainAdvance (HKDF-SHA256 via @noble/hashes)
  - `ratchet.ts`: deriveRatchetedSessionRoot, scalarMult (tweetnacl.scalarMult), generateRatchetKeypair
  - `encrypt.ts`: btrSeal, btrOpen (NaCl secretbox via tweetnacl.secretbox), btrSealDeterministic (test-only)
  - `state.ts`: BtrEngine + BtrTransferContext with full lifecycle parity
  - `replay.ts`: ReplayGuard class with ORDER-BTR enforcement
  - `negotiate.ts`: BtrMode enum, negotiateBtr (6-cell matrix), btrLogToken
- **Wire error registry extended:** TS WIRE_ERROR_CODES 22 → 26 codes (+4 BTR), matching Rust exactly.
- **New dependency:** `@noble/hashes@2.0.1` (HKDF-SHA256). No other new runtime deps.
- **Rust vector generator extended** with 2 new categories:
  - `btr-encrypt-decrypt.vectors.json` (6 vectors: fixed-nonce deterministic encrypt/decrypt + tampered + truncated)
  - `btr-dh-sanity.vectors.json` (4 vectors: X25519 cross-library validation)
- **8 Rust authority vector categories consumed by TS** (25 vectors + 4 DH sanity = 29 total interop vectors):
  - Key schedule: 3 session root ✓
  - Transfer ratchet: 4 transfer root ✓
  - Chain advance: 5 chain steps ✓
  - DH ratchet: 3 ratchet steps ✓
  - Replay reject: 4 scenarios ✓
  - Negotiate: 6 matrix cells ✓
  - Encrypt/decrypt: 6 vectors (4 valid + 2 error) ✓
  - DH sanity: 4 cross-library (incl. commutativity + basepoint) ✓
- **Deterministic interop proof:**
  - TS decrypts Rust-generated ciphertext for all valid vectors ✓
  - TS encrypts with fixed nonce/key/plaintext → byte-identical ciphertext to Rust ✓
  - Tampered ciphertext → RATCHET_DECRYPT_FAIL in both TS and Rust (same error class) ✓
  - Truncated ciphertext → RATCHET_DECRYPT_FAIL in both TS and Rust ✓
- **DH sanity check passed:** tweetnacl.scalarMult matches x25519-dalek for all 4 test cases.
- **Error parity verified:** All 4 BTR error codes with matching disconnect/cancel semantics.
- **Tests:** 78 new BTR tests + 120 existing = 198 total TS tests pass. 280 Rust workspace tests pass.
- **Regression:** All existing ts/bolt-core tests remain green (exports, crypto, hash, SAS, vectors, etc.).
- Tag: `sdk-v0.5.37-btr2-ts-parity`

---

## BTR-1 — Rust Reference Implementation (SEC-BTR1) — 2026-03-09

- **BTR-1 DONE:** Rust reference implementation of Bolt Transfer Ratchet.
- **New crate: `bolt-btr` v0.1.0** — transport-agnostic BTR engine.
  - `key_schedule.rs`: HKDF-SHA256 derivation chain (session root, transfer root, chain advance, message key)
  - `ratchet.rs`: Inter-transfer DH ratchet step (fresh X25519 keypair per transfer boundary)
  - `encrypt.rs`: NaCl secretbox (XSalsa20-Poly1305) keyed by BTR message_key
  - `state.rs`: BtrEngine + BtrTransferContext with lifecycle cleanup and zeroize-on-drop
  - `replay.rs`: (transfer_id, generation, chain_index) replay guard with ORDER-BTR enforcement
  - `negotiate.rs`: 6-cell capability negotiation matrix (§4)
  - `errors.rs`: 4 BTR error types with wire code mapping and disconnect/cancel semantics
  - `vectors.rs`: Deterministic golden vector generator (feature-gated)
- **Wire error registry extended:** bolt-core WIRE_ERROR_CODES 22 → 26 codes (+4 BTR)
- **6 golden vector files generated** (Rust-authority, for BTR-2 TS parity):
  - `btr-key-schedule.vectors.json` (3 vectors)
  - `btr-transfer-ratchet.vectors.json` (4 vectors)
  - `btr-chain-advance.vectors.json` (5 vectors)
  - `btr-replay-reject.vectors.json` (4 vectors)
  - `btr-downgrade-negotiate.vectors.json` (6 vectors)
  - `btr-dh-ratchet.vectors.json` (3 vectors)
- **Dependency audit (AC-BTR-22):** Zero transport/I/O/async deps. Pure crypto + state.
- **Zeroization (AC-BTR-21):** All secret structs use `zeroize` crate with ZeroizeOnDrop.
- **Tests:** 58 new bolt-btr tests + 7 vector golden tests = 65 new. 280 total workspace pass.
- **Regression (AC-BTR-23):** All existing bolt-core, bolt-transfer-core, conformance, wasm-parity tests pass.
- Tag: `sdk-v0.5.36-btr1-rust-reference` (cc4965e)

---

## BTR-0 — Spec + Capability Negotiation Lock (SEC-BTR1) — 2026-03-09

- **BTR-0 DONE:** Protocol specification locked for Bolt Transfer Ratchet.
- **PROTOCOL.md changes (bolt-protocol):**
  - §4: `bolt.transfer-ratchet-v1` capability registered with 6-cell negotiation matrix
  - §6: Envelope schema extended with conditional BTR fields (`ratchet_public_key`, `ratchet_generation`, `chain_index`)
  - §8: Replay protection extended with `ratchet_generation`
  - §10: 4 new BTR error codes (`RATCHET_STATE_ERROR`, `RATCHET_CHAIN_ERROR`, `RATCHET_DECRYPT_FAIL`, `RATCHET_DOWNGRADE_REJECTED`); registry now 26 codes
  - §11: BTR security properties (REPLAY-BTR, ISOLATION-BTR, ORDER-BTR, EPOCH-BTR)
  - §13: BTR conformance requirements added
  - §14: BTR constants (HKDF info strings, key lengths)
  - §16 (NEW): Complete BTR specification — architecture, envelope fields, key schedule (HKDF-SHA256), encryption with message keys, key lifecycle (memory-only), 11 invariants (BTR-INV-01–11), error behavior, BTR-1 entry criteria
  - Appendix B: Updated from "out of scope" to reference BTR §16
  - Appendix C: 5 BTR vector categories defined with schemas and pass criteria
- **LOCALBOLT_PROFILE.md changes:** BTR envelope fields in `json-envelope-v1` encoding (camelCase mapping)
- **CONFORMANCE.md changes:** 4 new BTR rows (§16, §16.3, §16.5, §16.6); scope updated to §1–§16; total rows now 27
- **Key decisions locked:**
  - Downgrade-with-warning default (PM-BTR-02)
  - Memory-only key storage (PM-BTR-03)
  - NaCl secretbox for BTR-encrypted envelopes (keyed by HKDF-derived message_key)
  - Ordered-chunk assumption (no skipped-key buffer)
  - DH ratchet at transfer boundaries, symmetric chain per chunk
- **SAS unchanged:** BTR does not alter SAS computation inputs
- **BTR-1 UNBLOCKED:** All 7 entry criteria satisfied
- Protocol tag: `v0.1.6-spec-btr0-lock`
- Ecosystem tag: `ecosystem-v0.1.102-btr0-spec-lock`

---

## BTR-STREAM-1 PM Decisions — BTR-0 Unblocked — 2026-03-09

- **PM-BTR-02 APPROVED:** Downgrade-with-warning as default backward compatibility mode
  - Peers without `bolt.transfer-ratchet-v1` capability fall back to static ephemeral (v1 behavior)
  - Warning surfaced to user indicating reduced security
  - Fail-closed only for malformed capability claims
- **PM-BTR-03 APPROVED:** Memory-only key storage (no persistence)
  - All BTR ratchet state (session DH, transfer keys, chain keys) is memory-only
  - SEC-04/SEC-05 invariants preserved exactly
  - Session resumption deferred as explicit non-goal (BTR-NG1)
- **BTR-0 unblocked:** Both blocking PM decisions resolved. BTR-0 (spec + capability negotiation lock) can proceed when prioritized.
- **AC-BTR-08, AC-BTR-09:** PM approval evidence recorded
- Ecosystem tag: `ecosystem-v0.1.101-btr-pm-decisions`

---

## SEC-BTR1 — Bolt Transfer Ratchet Replaces Double Ratchet — 2026-03-09

- **SEC-BTR1 P0 DONE:** Bolt Transfer Ratchet (BTR) codified as replacement for Double Ratchet (DR)
- **PM decisions (PM-BTR-01 through PM-BTR-04):**
  - BTR is replacement architecture (not rename/complement)
  - REPLACES mode: SEC-BTR1 replaces active execution of SEC-DR1
  - SEC-BTR1 approved as active NEXT security stream
  - DR-STREAM-1 deprecated: SUPERSEDED-BY-BTR, frozen for traceability
- **Why BTR instead of DR:**
  - Double Ratchet designed for async bidirectional messaging (Signal) — wrong fit for file transfer
  - BTR is transfer-scoped: per-transfer key isolation via HKDF, per-chunk symmetric ratchet, DH ratchet at transfer boundaries
  - No out-of-order complexity (Bolt chunks are ordered)
  - No bidirectional chains (transfers are unidirectional)
  - Simpler state (~164B vs ~200B+ with skipped keys), same security properties
- **BTR-STREAM-1:** 6 phases (BTR-0 through BTR-5), 40 acceptance criteria (AC-BTR-01 through AC-BTR-40)
- **Capability string:** `bolt.transfer-ratchet-v1`
- **Crate name:** `bolt-btr` (PM-BTR-06 pending)
- **DR-STREAM-1:** Frozen (SUPERSEDED-BY-BTR). All content preserved for traceability. No phases will execute.
- **DR P0 audit findings:** Inherited by BTR-STREAM-1 (rendezvous opacity, shared-crate feasibility, etc.)
- **Tracker:** DR-F series frozen. BTR-F series reserved (BTR-F1–BTR-F99)
- **No code changes** — governance transition only
- Ecosystem tag: `ecosystem-v0.1.100-sec-btr1-replaces-dr`

---

## SEC-DR1 P0 — Double Ratchet Stream Kickoff — 2026-03-09 [SUPERSEDED by SEC-BTR1]

- **SEC-DR1 P0 DONE:** Stream kickoff — docs codification + read-only audit complete
- **Stream confirmed:** DR-STREAM-1 (phased, 6 phases: DR-0 through DR-5)
- **Read-only audit:** bolt-core-sdk (Rust + TS crypto/session modules), bolt-protocol (wire format + capability negotiation), bolt-daemon (SessionContext + shared-crate feasibility), bolt-rendezvous (confirmed opaque — zero changes needed)
- **Deliverables codified in `docs/GOVERNANCE_WORKSTREAMS.md` § DR-STREAM-1:**
  - Phase table + dependency DAG (serial gates: DR-0, DR-1, DR-4; partial parallel: DR-2 ∥ DR-3)
  - 38 acceptance criteria (AC-DR-01 through AC-DR-38) — concrete for DR-0/DR-1, defined for DR-2/DR-3/DR-4, TBD for DR-5
  - Capability negotiation matrix (6 cases: both/one-sided/neither/malformed)
  - Wire delta summary (~80B/msg increase, negligible; envelope v1→v2 with `dh`, `pn`, `n` fields)
  - Key storage impact (memory-only recommended; SEC-04/SEC-05 interaction analyzed)
  - Test/vector strategy (Rust-generates, TS-consumes; 8 vector categories, parity matrix)
  - Risk register (7 risks, all mitigated)
  - PM open decisions table (10 decisions, PM-DR-01 resolved)
  - Rollout strategy (dark launch → opt-in → default-on → legacy deprecation)
  - Backward compatibility: downgrade-with-warning recommended (PM-DR-02 pending)
- **AUDIT_TRACKER.md:** DR-F series reserved (DR-F1–DR-F99, non-colliding)
- **No code changes** — docs-only codification pass
- Ecosystem tag: `ecosystem-v0.1.99-sec-dr1-p0-codify`

---

## RECON-XFER-1 Evidence Tail Correction — 2026-03-09

- **Correction:** RECON-XFER-1 status adjusted from DONE to DONE-VERIFIED (evidence tail: RX-EVID-1)
- **AC-RX-08 wording corrected:**
  - Automated gate: PASS (WASM + fallback build/test parity)
  - Manual runtime evidence: PENDING
- **RX-EVID-1 registered:** LOW, OPEN, docs-only closeout. Required per consumer (localbolt, localbolt-app, localbolt-v3):
  1. One WASM-mode runtime transfer
  2. One forced-fallback-mode runtime transfer
  3. Pause/resume/cancel sanity after reconnect
- All Phase A/B code work remains closed — this is only an evidence tail
- Ecosystem tag: `ecosystem-v0.1.98-recon-xfer1-evidence-tail`

---

## RECON-XFER-1 Phase B — Consumer Verification Closeout — 2026-03-09

- **RECON-XFER-1 PHASE B DONE:** Both remaining consumers verified — no code changes required
- **localbolt (v1.0.35):** Already protected via `@the9ines/localbolt-core` generation guards. 19 security-session-integrity tests cover stale callback rejection. 319 tests pass, build green.
- **localbolt-app (v1.2.23):** Already protected via shared SDK (web layer) + Tauri IPC bridge lifecycle (Rust layer). No Tauri command caches refs across reconnect. Bridge writer Mutex + reader thread lifecycle prevents stale callbacks. 146 tests pass (64 web + 82 Rust), build green.
- **AC-RX-07 SATISFIED:** Both remaining consumers verified — no consumer-specific patches needed. Defenses come from shared `@the9ines/localbolt-core` generation guard pattern (wired in all consumers since Q7/C7 closure).
- **AC-RX-08 automated gate PASS:** WASM policy adapter is orthogonal to reconnect-resend path (transfer scheduling/backpressure only, not session lifecycle). Both consumers build with WASM bundle. Forced-fallback uses identical session lifecycle. Manual runtime evidence: PENDING (see RX-EVID-1).
- **No daemon changes** — no escalation triggered
- **Tags:**
  - `localbolt-v1.0.35-recon-xfer1-phase-b` — docs-only (no code change)
  - `localbolt-app-v1.2.23-recon-xfer1-phase-b` — docs-only (no code change)
  - `ecosystem-v0.1.97-recon-xfer1-phase-b` — this commit

---

## RECON-XFER-1 Phase A — Transfer Reconnect Recovery Fix — 2026-03-09

- **RECON-XFER-1 PHASE A DONE:** Root-cause locked and fix applied
- **Root cause:** localbolt-v3 consumer orchestration — NOT SDK
  - RC-1: `serviceGeneration` captured once at init, never updated across reconnect → all callbacks silently dropped
  - RC-2: SDK one-shot lifecycle (`disconnect()` kills signaling listener) — reusing dead service blocked reconnect
- **SDK verdict:** Core teardown sufficient. Test-only change (8 one-shot contract tests).
- **Fix:** `createFreshRtcService()` factory in `peer-connection.ts` — new `WebRTCService` per connection attempt, synchronized generation, old service fully detached before swap
- **Tests:** 16 regression tests (localbolt-core), 8 one-shot contract tests (SDK) — 298 SDK total, 70 localbolt-core total, 70 localbolt-web total — all green
- **Build:** localbolt-v3 Vite production build green (WASM + fallback)
- **Tags:**
  - `sdk-v0.5.35-recon-xfer1-phase-a-tests` (2f219d4) — test-only
  - `v3.0.88-recon-xfer1-phase-a` (a7e311b) — primary fix
  - `ecosystem-v0.1.96-recon-xfer1-phase-a` — this commit
- **Phase B pending:** localbolt + localbolt-app consumer verification
- **No daemon changes** — escalation not triggered

---

## RECON-XFER-1 — Transfer Reconnect Recovery Codification — 2026-03-09

- **RECON-XFER-1 CODIFIED:** Governance codification of mid-transfer disconnect → reconnect stuck bug
- **Priority:** NOW / HIGH — user-facing reliability regression
- **Status:** NOT-STARTED (docs/governance codification only in this pass)
- **Repro:** Start transfer → disconnect mid-transfer → reconnect → new transfer fails to start
- **Repro surface:** Browser path (`localbolt.app`) confirmed. Daemon-only path unknown/unconfirmed.
- **Root-cause hypothesis:** SDK session/transfer coordination (`ts/bolt-transport-web`) — transfer SM does not reset to terminal state on mid-transfer disconnect; stale `transferId`, queue pointers, and control flags survive across reconnect boundary
- **Distinct from prior work:**
  - Q7/C7 (DONE): stale callback pollution (UI shows wrong state) — RECON-XFER-1 is stuck state (cannot start new transfer)
  - C-STREAM-R1 (DONE): generation guards + disconnect idempotency — RECON-XFER-1 is transfer SM lifecycle coordination
  - UI-XFER-1 (DONE): emit path correctness — RECON-XFER-1 is disconnect boundary cleanup
- **Acceptance criteria:** AC-RX-01 through AC-RX-08 (terminal reset, fresh session generation, same-run new transfer, no stale state crossing, post-reconnect controls, regression test, phased consumer verification, WASM/fallback non-regression)
- **Phased verification:** Phase A (SDK + localbolt-v3), Phase B (localbolt + localbolt-app)
- **Daemon scope:** Escalation-only (not initial scope)
- **Dependencies:** T-STREAM-1 (DONE) prerequisite context
- **PM decisions:** PM-RX-01/02/03 all APPROVED
- **Docs updated:** `FORWARD_BACKLOG.md` (Item 10), `GOVERNANCE_WORKSTREAMS.md`, `ROADMAP.md`, `STATE.md`, `CHANGELOG.md`
- Ecosystem tag: `ecosystem-v0.1.95-recon-xfer-1-codify`

---

## REL-ARCH1 — Multi-Arch Daemon Build/Package Matrix — 2026-03-09

- **REL-ARCH1 DONE:** Deterministic multi-architecture release workflow for bolt-daemon
- **Daemon tag:** `daemon-v0.2.38-relarch1-multiarch-matrix` (`ab56606`)
- **New workflow:** `.github/workflows/release.yml` — 5-target matrix build + package + publish
- **Targets:**
  - `x86_64-apple-darwin` (macos-14, native cross-compile)
  - `aarch64-apple-darwin` (macos-14, native)
  - `x86_64-pc-windows-msvc` (windows-latest, native)
  - `x86_64-unknown-linux-gnu` (ubuntu-latest, native)
  - `aarch64-unknown-linux-gnu` (ubuntu-latest, native gcc cross toolchain)
- **Shipped binaries:** `bolt-daemon` + `bolt-relay` (per archive)
- **Excluded:** `bolt-ipc-client` (dev harness)
- **Packaging:** `.tar.gz` (macOS/Linux), `.zip` (Windows), `SHA256SUMS.txt`
- **Trigger:** Tag push (`daemon-v*`) + `workflow_dispatch` manual rebuild
- **CI fix:** Added missing `bolt-core-sdk` checkout to `ci.yml` (broken since T-STREAM-0)
- **Fmt fix:** Pre-existing `cargo fmt` violation in `src/rendezvous.rs` corrected
- **Windows fix:** Strawberry Perl forced via PERL env var for OpenSSL vendored build
- **Test fix:** Platform-agnostic path assertion in `identity_store::resolve_path_uses_home`
- **Validation:** CI run 22845910794 — all 5 targets green, publish success
- **Residual:** Code signing/notarization (follow-on), `aarch64-pc-windows-msvc` (deferred)
- Ecosystem tag: `ecosystem-v0.1.94-relarch1-multiarch-matrix`

---

## T-STREAM-1 P4 CLOSE — WASM Activation + Evidence — 2026-03-08

- **T-STREAM-1 P4 CLOSED:** WASM policy adapter active in production across all three consumers
- **SDK version:** `@the9ines/bolt-transport-web@0.6.7` (npmjs.org) — ships WASM binary in tarball, diagnostic logging
- **WASM-enabled evidence:** Footer shows `Policy: WASM` on localbolt.app after CSP fix
- **Forced-fallback evidence:** Footer showed `Policy: Fallback` prior to CSP fix (CSP `script-src 'self'` blocked `WebAssembly.instantiateStreaming`)
- **CSP fix:** Added `'wasm-unsafe-eval'` to `script-src` in all three consumer `index.html` files
- **Pause/resume/cancel sanity:** 17 UI-XFER-1 canonical control tests pass in SDK (pause blocks enqueue, resume unblocks, cancel terminal state, no completion after cancel, canonical receive-side routing)
- **Full test evidence:**
  - SDK (bolt-transport-web): 27 files, 290 tests PASS
  - localbolt: 15 files, 319 tests PASS
  - localbolt-app: 5 files, 64 tests PASS
  - localbolt-v3: 4 files, 70 tests PASS
  - **Total: 743 tests, 0 failures**
- **Domain rename:** All `localbolt.site` references updated to `localbolt.app` across all repos
- CSP tags:
  - `localbolt-v1.0.33-csp-wasm` (`cbd43af`)
  - `localbolt-app-v1.2.21-csp-wasm` (`83a8350`)
  - `v3.0.86-csp-wasm` (`98610d3`)
- Domain rename tags:
  - `localbolt-v1.0.34-domain-rename` (`c8f9fdc`)
  - `localbolt-app-v1.2.22-domain-rename` (`beb8891`)
  - `v3.0.87-domain-rename` (`69ec25c`)
- Ecosystem tag: `ecosystem-v0.1.92-tstream1-wasm-activation`

---

## T-STREAM-1 P4 — Consumer Adoption (WASM Policy Wiring) — 2026-03-08

- **T-STREAM-1 P4 DONE:** All three consumers adopt `@the9ines/bolt-transport-web@0.6.5` from npmjs.org with WASM policy wiring
- SDK tag: `sdk-v0.5.32-tstream1-wasm-policy-wiring` (`2d4792f`)
- Consumer tags:
  - `localbolt-v1.0.29-tstream1-wasm-policy` (`44b8d1b`)
  - `localbolt-app-v1.2.17-tstream1-wasm-policy` (`95125dd`)
  - `v3.0.82-tstream1-wasm-policy` (`d6fdb0e`)
- Ecosystem tag: `ecosystem-v0.1.91-tstream1-wasm-policy-adoption`
- **Registry migration:** All consumers switched from GitHub Packages to npmjs.org for `@the9ines` scope
- **WASM external pattern:** All three consumers mark `bolt_transfer_policy_wasm` as rollup external — dynamic import in `PolicyAdapter.js` is wrapped in try/catch; `TsFallbackPolicyAdapter` activates at runtime when WASM unavailable
- **SDK publish fix:** `fix(ci)` commits (`5762927`, `a9590b1`) patch npmjs publish workflow to override scoped `.npmrc`
- **Build evidence:**
  - localbolt: PASS (vite build, 58 modules, 319 tests)
  - localbolt-app: PASS (vite build, 62 modules, 64 tests)
  - localbolt-v3: PASS (vite build, 62 modules, 124 tests — 70 localbolt-web + 54 localbolt-core)
- **Manual runtime evidence:** Deferred to Human Scope (WASM transfer, fallback transfer, pause/resume/cancel per consumer)
- **Files changed (localbolt):** `web/.npmrc`, `web/package-lock.json`, `web/vite.config.ts`
- **Files changed (localbolt-app):** `web/package-lock.json`, `web/vite.config.ts`
- **Files changed (localbolt-v3):** `.npmrc`, `package-lock.json`, `packages/localbolt-web/.npmrc`, `packages/localbolt-web/vite.config.ts`
- **Files changed (bolt-core-sdk):** `.github/workflows/publish-transport-web-npmjs.yml` (CI fix only)

---

## S2A — Transfer Policy Substantive Logic — 2026-03-08

- **S2A DONE:** Substantive transfer policy replacing trivial stub, pre-WASM
- SDK tag: `sdk-v0.5.31-s2a-transfer-policy-substantive` (`c67bd68`)
- Ecosystem tag: `ecosystem-v0.1.90-s2a-transfer-policy-substantive`
- Daemon: **untouched** (no transfer_policy imports; AC-S2A-12 N/A)
- **Policy ownership (Option B):** Moved `transfer_policy` from `bolt-core` to `bolt-transfer-core/policy/`
- **Unified backpressure authority:** `BackpressureSignal` enum removed; `BackpressureController` feeds `PressureState` into `PolicyInput`; policy emits single `Backpressure` signal
- **Effective chunk cap:** `effective_chunk_size = min(configured_chunk_size, transport_max_message_size)`
- **Send-window sizing:** Pressure-aware (halves under Elevated, zeroes under Pressured), fairness-mode adjustments (Latency→1, Throughput→full), device-class scaling (LowPower→½, Mobile→¾)
- **RTT-proportional pacing:** Latency mode adds rtt/4, Balanced+Elevated adds rtt/8
- **Stall detection:** Pure threshold-based classification (Healthy/Warning/Stalled/Complete)
- **Progress cadence (forward-investment):** Pure function for T-STREAM-1 TS/WASM consumption, no daemon consumer
- **Tests:** 207 total pass (62 bolt-core + 16 conformance + 93 bolt-transfer-core unit + 36 S2A integration)
- **Validation gates:** `cargo clippy -- -D warnings` clean, `cargo fmt -- --check` clean, WASM build verified
- **AC-S2A-01..11 satisfied** (AC-S2A-12 N/A — daemon untouched)
- **Files changed (bolt-core-sdk):** `rust/bolt-core/src/lib.rs`, `rust/bolt-core/src/transfer_policy/` (deleted), `rust/bolt-core/tests/s2_policy_contracts.rs` (deleted), `rust/bolt-transfer-core/src/backpressure.rs`, `rust/bolt-transfer-core/src/lib.rs`, `rust/bolt-transfer-core/src/policy/` (new: mod, types, decide, stall, progress), `rust/bolt-transfer-core/tests/s2a_policy_tests.rs` (new)
- **Deferred to T-STREAM-1:** wasm-bindgen exports, TS adapter, browser runtime wiring, progress cadence TS consumer
- **Deferred to ARCH-WASM1:** Full WASM protocol engine
- **Deferred:** Daemon integration (calling `decide()` in send loop), ACK-based stall recovery

---

## T-STREAM-0 — Rust Transfer Core Extraction — 2026-03-08

- **T-STREAM-0 DONE:** Transport-agnostic transfer state machine extracted from daemon into shared `bolt-transfer-core` crate
- SDK tag: `sdk-v0.5.30-tstream0-transfer-core-v1`
- Daemon tag: `daemon-v0.2.36-tstream0-adapter`
- Ecosystem tag: `ecosystem-v0.1.89-tstream0-transfer-core-v1`
- **PM-FB-04 resolved:** Crate placed as workspace member in `bolt-core-sdk/rust/bolt-transfer-core/` (path dependency)
- **New crate:** `bolt-transfer-core` v0.1.0 — 6 modules (state, error, send, receive, backpressure, transport)
- **§9 conformance:** All 8 PROTOCOL.md §9 states represented (Idle, Offered, Accepted, Transferring, Paused, Completed, Cancelled, Error)
- **AC-TC-01..06 all satisfied** (see evidence matrix in SDK CHANGELOG)
- **WASM gate:** `cargo build --target wasm32-unknown-unknown` passes. rlib: 107 KB uncompressed, 49 KB gzipped
- **Daemon adapter:** `bolt-daemon/src/transfer.rs` → thin facade re-exporting from `bolt-transfer-core` + `Sha256Verifier`
- **Zero duplicated SM logic:** All state machine code lives in `bolt-transfer-core`; daemon is pure adapter
- **Tests:** 60 core crate tests + 362 daemon tests pass (0 regressions)
- **Consumer repos intentionally untouched** (localbolt, localbolt-app, localbolt-v3)
- **Deferred to T-STREAM-1:** wasm-bindgen exports, TS adapter, browser runtime wiring
- **Deferred to S2:** Full performance tuning (hysteresis, fairness, RTT/loss hints)
- **Files changed (bolt-core-sdk):** `rust/Cargo.toml` (NEW workspace root), `rust/bolt-transfer-core/` (NEW crate, 7 files)
- **Files changed (bolt-daemon):** `Cargo.toml`, `src/transfer.rs`, `src/lib.rs`, `src/rendezvous.rs`
- **Files changed (ecosystem):** `docs/ROADMAP.md`, `docs/STATE.md`, `docs/CHANGELOG.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## UI-XFER-1 — Pause/Stop Button Reliability (Canonical DC Control) — 2026-03-08

- **UI-XFER-1 DONE:** Canonical DC control messages for pause/resume/cancel in SDK
- SDK tag: `sdk-v0.5.29-uixfer1-canonical-control` (`89e2edb`)
- Ecosystem tag: `ecosystem-v0.1.88-uixfer1-pause-stop-fix`
- **Root cause:** SDK emitted `{ type: "file-chunk", paused: true }` — daemon parsed as data chunk, not control. Daemon emitted `{ type: "pause" }` — SDK rejected as unknown type and disconnected.
- **Fix:** Emit path converged to canonical shapes (`{ type: "pause"/"resume"/"cancel", transferId }`) matching daemon `dc_messages.rs`. Legacy `file-chunk` control flags removed from emit, retained on receive for backward compat (deprecated).
- **False completion race fixed:** Cancel now clears pending completion timeout; timeout callback checks cancelled flag.
- **Decision lock:** No legacy emit. Legacy receive tolerance temporary (deprecation noted, removal target: next major).
- **Tests:** 17 new tests in `uixfer1-canonical-control.test.ts`, 270 total pass
- **Consumer adoption:** localbolt, localbolt-app, localbolt-v3 updated to `@the9ines/bolt-transport-web@0.6.5`
- **Files changed (SDK):** `types.ts`, `TransferManager.ts`, `WebRTCService.ts`, `webrtcservice-lifecycle.test.ts`, `uixfer1-canonical-control.test.ts`, `package.json`
- **Files changed (ecosystem):** `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/ROADMAP.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## B-XFER-1 — Transfer Pause/Resume Completion — 2026-03-08

- **B-XFER-1 DONE:** Sender-side pause/resume implemented in bolt-daemon transfer state machine
- Daemon tag: `daemon-v0.2.35-bxfer1-pause-resume` (`9f087a1`)
- Ecosystem tag: `ecosystem-v0.1.87-bxfer1-pause-resume`
- **Implementation:**
  - `SendState::Paused` variant added (Sending→Paused→Sending lifecycle)
  - `on_pause()`, `on_resume()`, `is_send_active()` methods on SendSession
  - Pause/Resume carved out from `route_inner_message` to `Ok(None)` for loop-level dispatch
  - Chunk streaming restructured: tight `while let` loop → incremental one-chunk-per-iteration (allows Pause/Resume/Cancel interleaving)
  - `on_cancel()` accepts Paused state; `finish()` rejects Paused state
- **Tests:** 12 new unit tests, 2 updated envelope tests, 2 integration tests; all existing tests pass
- **Validation gates:** `cargo test` (all pass), `cargo clippy -- -D warnings` (clean), `scripts/check_no_panic.sh` (pass)
- **PM-FB-01 resolved:** Concurrent transfers OUT OF SCOPE for B-XFER-1
- **Dependency note:** T-STREAM-0 unblocked (B-XFER-1 stabilizes SM design)
- **AC-BX mapping:** AC-BX-01 through AC-BX-09 all satisfied (see `docs/FORWARD_BACKLOG.md`)
- **Files changed (daemon):** `src/transfer.rs`, `src/envelope.rs`, `src/rendezvous.rs`
- **Files changed (ecosystem):** `docs/FORWARD_BACKLOG.md`, `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/ROADMAP.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## Forward Backlog Codification — 2026-03-08

- **Post-R17 forward backlog codified:** 9 items covering transfer completion, release architecture, security, platform convergence, and mobile readiness
- Ecosystem tag: `ecosystem-v0.1.86-roadmap-codify-transfer-security-mobile`
- **Part A — R17 addendum verified:** Critical evidence mapping (A1–A5, B6–B8), non-blocking rationale (WebView2 DLL, signal subtree clippy, web coverage threshold), and closure integrity statement all present and complete. No gaps found. B-DEP-N2-3 stale wording updated to reflect R17 CLOSED.
- **Part B — Backlog items codified:**
  - B-XFER-1: Transfer pause/resume completion (daemon transfer SM remaining scope) — **NOW**
  - REL-ARCH1: Multi-arch daemon build/package matrix — **NOW**
  - SEC-DR1: Double Ratchet pre-ByteBolt security gate (DR-STREAM, phased) — **NEXT**
  - T-STREAM-0: Rust transfer core, no UDP in v1 — **NEXT**
  - SEC-CORE2: Rust-first security/protocol consolidation — **NEXT**
  - T-STREAM-1: Browser selective WASM integration — **LATER**
  - PLAT-CORE1: Shared Rust core + thin platform UIs — **LATER**
  - MOB-RUNTIME1: Mobile embedded runtime model (sequenced after PLAT-CORE1) — **LATER**
  - ARCH-WASM1: WASM protocol engine (medium risk) — **LATER**
- **Boundary note:** B-XFER-1 (#1) completes current daemon-local pause/resume behavior. T-STREAM-0 (#4) is shared transfer-core architecture extraction/reuse. Distinct scopes.
- **Guardrails enforced:** Browser native WebRTC retained (G1), no UDP in transfer-core v1 (G2), no A0 Option A reversal (G3)
- **AC coverage:** NOW and NEXT items have concrete AC IDs. LATER items: "AC: TBD at stream codification."
- **Files changed:** `docs/FORWARD_BACKLOG.md` (new), `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/ROADMAP.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## R17 — Windows Runtime Validation CLOSED — 2026-03-08

- **R17 CLOSED:** Windows CI provisioned (`windows-latest`), daemon + app IPC validated on real Windows runtime
- Closeout type: residual-risk closeout (not a new stream phase). N-STREAM-1 remains CLOSED
- Environment: GitHub Actions `windows-latest` (Windows Server 2022, x86_64)
- Windows CI workflows added to both repos (`workflow_dispatch` trigger)
- **bolt-daemon** (`daemon-v0.2.34-r17-windows-validated`, `82d0f83`):
  - cargo fmt: PASS
  - cargo clippy: PASS (6 commits of fixes: import paths, HANDLE types, visibility, needless return, mut refs, cfg gates)
  - cargo test: PASS — 362 tests (default features), 429 tests (test-support), 0 failures
  - Key fixes: windows-sys 0.59 API migration (ConvertStringSecurityDescriptorToSecurityDescriptorW, PIPE_ACCESS_DUPLEX, DUPLICATE_SAME_ACCESS moved; HANDLE = `*mut c_void` not `isize`), cross-platform ipc-client binary, cfg(unix) gates on Unix-only tests
- **localbolt-app** (`localbolt-app-v1.2.15-r17-windows-validated`, `7116d12`):
  - Tauri App: fmt PASS, clippy PASS, test FAIL (`STATUS_ENTRYPOINT_NOT_FOUND` — WebView2 DLL missing on headless CI, not IPC-related)
  - Signal Server: clippy FAIL (`result_large_err` in vendored signal/ subtree — read-only per subtree policy, not R17)
  - Web App: coverage threshold FAIL (Windows coverage instrumentation differs — tests pass, threshold not met)
  - Key fixes: block-expression wrapping for `#[cfg(windows)]` connect(), needless_return removal
- Bugs discovered and fixed: 8 commits across 2 repos. All were real compilation/clippy errors that would manifest on Windows at build time
- CI evidence: daemon run `22816178593` (all green), app run `22814949072` (Tauri fmt+clippy green)
- **R17 critical-check evidence matrix:**

| ID | Check | Scope | Result | Evidence |
|----|-------|-------|--------|----------|
| A1 | Windows compilation (daemon lib) | bolt-daemon | **PASS** | CI `22816178593` clippy step — `bolt-daemon` lib compiles clean |
| A2 | Windows compilation (daemon bins) | bolt-daemon | **PASS** | CI `22816178593` clippy step — `bolt-ipc-client`, `bolt-daemon`, `bolt-relay` all compile |
| A3 | Windows clippy clean | bolt-daemon | **PASS** | CI `22816178593` clippy step — 0 warnings, `-D warnings` enforced |
| A4 | Windows tests (default features) | bolt-daemon | **PASS** | CI `22816178593` — 362 tests, 0 failures |
| A5 | Windows tests (test-support) | bolt-daemon | **PASS** | CI `22816178593` — 429 tests, 0 failures, 3 ignored |
| B6 | App IPC transport compilation | localbolt-app | **PASS** | CI `22814949072` Tauri clippy step — `ipc_transport.rs` compiles clean on Windows |
| B7 | App IPC transport clippy clean | localbolt-app | **PASS** | CI `22814949072` Tauri clippy step — 0 IPC-related warnings |
| B8 | Named pipe path detection | bolt-daemon | **PASS** | CI `22816178593` test step — `is_windows_pipe_path` tests pass (15 transport tests) |

- **Out-of-scope failures (not R17-blocking):**
  - Tauri `cargo test` (`STATUS_ENTRYPOINT_NOT_FOUND`, exit 0xc0000139): WebView2Loader.dll not present on headless `windows-latest` runner. This is a Tauri GUI runtime dependency — the test binary links against WebView2 platform DLLs unavailable in headless CI. The IPC transport code (`ipc_transport.rs`) compiled and passed clippy; the test binary crash occurs before any test executes. Not an IPC or named pipe issue.
  - Signal Server `result_large_err`: `ErrorResponse` type (136 bytes) in vendored `signal/` subtree. Subtree is read-only per CLAUDE.md policy — fixes must go upstream to bolt-rendezvous. Pre-existing issue unrelated to R17 IPC validation.
  - Web App coverage threshold: Tests pass (82.6%/70.79% coverage) but below 90% configured threshold. Windows coverage instrumentation differs from macOS/Linux. Tests themselves execute correctly; only the coverage threshold gate fails. Not IPC-related.
- Ecosystem tag: `ecosystem-v0.1.85-r17-windows-validated`

---

## R17 — Windows Runtime Validation Closeout Attempt — 2026-03-07

- **R17 remains OPEN:** P0 environment gate FAILED — no Windows runtime available
- Closeout type: residual-risk closeout (not a new stream phase). N-STREAM-1 remains CLOSED
- Environment: macOS Darwin 24.6.0 (ARM64). No Windows CI runner, no Wine/QEMU, no manual Windows machine
- Baseline tags verified:
  - `daemon-v0.2.33-n6b2-windows-pipe` (confirmed)
  - `localbolt-app-v1.2.14-n8-signal-observability` (confirmed)
  - `ecosystem-v0.1.83-n-stream-1-n8-observability` (confirmed)
- Validation matrix (A1–D15): all NOT_RUN — P0 environment gate failed
- No code changes, no runtime modifications
- Blocker: no Windows runtime environment (CI or manual)
- Next action: provision Windows CI runner (GitHub Actions `windows-latest`) or manual Windows machine
- Owner: PM
- Target: next sprint with Windows CI budget
- Governance docs updated: GOVERNANCE_WORKSTREAMS.md, ROADMAP.md, STATE.md, CHANGELOG.md
- Ecosystem tag: `ecosystem-v0.1.84-r17-progress`

---

## N-STREAM-1 N8 — D2 Signal Observability (Post-Closure Follow-On) — 2026-03-07

- **N8 DONE:** D2 signal health observability delivered as post-closure follow-on
- Stream semantics: Option C (standalone lineage-linked item). N-STREAM-1 remains CLOSED
- Routing decision: N8 (zero daemon impact). Daemon repo NOT touched
- Architecture: Path 1 (app-side TCP probe + app-emitted unified status)
- AC-SE-06 realized: signal health measured by app (runtime owner), architecture-neutral wording
- AC-SE-07 realized: unified indicator aggregates daemon + signal state
- Implementation:
  - Signal monitor (`signal_monitor.rs`): TCP probe to 127.0.0.1:3001, 5s interval, 4-state machine (unknown/active/degraded/offline), 3-failure offline threshold
  - Shutdown-aware: probe transitions suppressed during SIGTERM grace window (N3-W4/OQ-2 interaction)
  - Unified health indicator in header.ts (HEALTHY/SIG DEGRADED/SIG OFFLINE)
  - Frontend signal://status event subscription + get_signal_status command
  - Support bundle includes signal_status section
- No transfer gating changes (observability only, per PM approval)
- Option A topology preserved: app remains signaling runtime owner
- Tests: 82 Rust (66→82, +16 new) + 64 web (52→64, +12 new) = 146 total, 0 regressions
- signal/ subtree: zero diff verified
- Residuals unchanged: R17 (Windows runtime, Low), OQ-2 (graceful shutdown, Low)
- App tag: `localbolt-app-v1.2.14-n8-signal-observability` (`a7e4f8b`)
- Ecosystem tag: `ecosystem-v0.1.83-n-stream-1-n8-observability`

---

## N-STREAM-1 N7 — Closure Gate — 2026-03-07

- **N7 DONE:** Closure gate executed. N-STREAM-1 **CLOSED**.
- Baseline verification: all 9 historical anchors (tags/commits) verified reachable on origin
- Closure criteria assessment: C1–C5 all **PASS**
  - C1 (phase completion integrity): N0–N6 + A0 all DONE, statuses consistent
  - C2 (acceptance harness closure): 44 N5 checks, 118 N6 tests (66 Rust + 52 web), all B-DEPs unblocked
  - C3 (dependency/blocker closure): all 4 B-DEPs RESOLVED with tag evidence
  - C4 (residual risk handling): R17 (Windows runtime, Low) OPEN with owner/next action
  - C5 (release/readiness narrative): stream outcome, limits, and deferred work documented
- Residual risks carried forward:
  - R17 (Windows runtime validation): OPEN, Low — owner: N-STREAM/B-STREAM, next: Windows CI runner or manual validation
  - OQ-2 (bolt-rendezvous graceful shutdown): OPEN, Low — upstream enhancement
- Decision continuity: A0 Option A retained, D2 observability deferred to N8/B-stream
- Stale status fix: N3 phase table entry updated (B-DEP block language → RESOLVED)
- Stale status fix: N2 STATE.md entry updated (impl deps open → all impl deps RESOLVED)
- No code changes, no runtime modifications, no subtree edits
- Tag: `ecosystem-v0.1.82-n-stream-1-n7-closure`

---

## N-STREAM-1-SIGNAL-EVAL / A0 — Signaling Ownership Decision — 2026-03-07

- **A0 DONE:** Governance-only signaling ownership evaluation for native app flows
- Read-only audit: localbolt-app, bolt-daemon, bolt-rendezvous
- **Decision: Option A (status quo coexistence)** — PM-approved
  - App embeds signaling server (bolt-rendezvous via signal/ subtree, 0.0.0.0:3001)
  - Daemon remains IPC-only (pairing/transfer decisions, no signaling hosting)
  - signal/ subtree unchanged
- **D2 observability deferred** to N8 (daemon IPC changes) or B-stream (if substantial)
  - AC-SE-06/07 (signal.status monitoring) deferred to D2 follow-on phase
- Options B (daemon-only signaling) and D1 (daemon spawns signal) explicitly rejected
  - B requires 9 locked-decision amendments; D1 requires 7
  - Both violate guardrail 13 (daemon protocol is B-stream ownership)
- Approved acceptance criteria: AC-SE-01..05, AC-SE-08..10 (immediate)
- Residuals carried forward: R17 (Windows runtime validation), OQ-2 (graceful shutdown)
- No code changes, no runtime modifications, no subtree edits
- Tag: `ecosystem-v0.1.81-signal-eval-a0-decision`

---

## N-STREAM-1 N6 Complete — GA Wiring + Support Bundle + Cross-Platform IPC — 2026-03-07

- **N6 DONE:** All execution + hardening work complete across N6-A1, N6-A2, and N6-B3
- N6-B3 GA wiring (localbolt-app-v1.2.13-n6b3-ga-wiring, `88954c8`):
  - Platform-aware IPC paths: `--socket-path` and `--data-dir` passed to daemon at spawn
  - `platform.rs`: centralized defaults for macOS/Linux/Windows (socket, PID, data-dir, crash-log, support-bundle paths)
  - Cross-platform IPC transport abstraction (`ipc_transport.rs`): `IpcStream` enum supports Unix domain sockets and Windows named pipes
  - All IPC client/bridge code migrated from direct `UnixStream` usage to `IpcStream`
  - Full support bundle export: 8 manifest sections (watchdog, stderr, crash snapshots, versions, platform metadata, IPC config, spawn counters)
  - Daemon process management abstracted: `platform::process_alive/terminate/force_kill` (Unix via libc, Windows compile-validated stubs)
  - Windows named pipe path detection and platform-aware binary resolution (`which` → `where` on Windows)
  - Signal server coexistence verified: TCP:3001 vs Unix socket, no conflict
- B-DEP-N1-1 **RESOLVED**: daemon receives `--socket-path` and `--data-dir`
- B-DEP-N2-3 **RESOLVED**: transport layer supports `\\.\pipe\` format (daemon + app)
- R16 **CLOSED**: Windows named pipe code complete
- R17 **OPENED**: Windows runtime validation — no Windows CI runner, code compile-validated only (Low, tracked for N7)
- 118 tests (66 Rust + 52 web), clippy 0 warnings, fmt clean
- Tag: `ecosystem-v0.1.80-n-stream-1-n6-complete`

---

## N-STREAM-1 N6-A2 — IPC Bridge + Frontend Readiness Gating — 2026-03-07

- **N6 IN-PROGRESS (N6-A2 completed):** IPC bridge, frontend daemon service, and readiness gating
- Persistent IPC bridge (ipc_bridge.rs): reconnects after readiness probe, forwards
  daemon.status/pairing.request/transfer.incoming.request to frontend via Tauri events
- Decision relay: pairing.decision and transfer.incoming.decision sent from frontend to daemon
- Frontend daemon service (daemon.ts): Tauri event subscriptions, command wrappers, graceful non-Tauri degradation
- Header: daemon watchdog status indicator (5 states: starting/ready/restarting/degraded/incompatible)
- Transfer: readiness gating (fail-closed), degraded banner + restart action, incompatible banner
- IPC types: PairingRequestPayload, TransferIncomingRequestPayload, Decision enum + decision payloads
- Tauri commands: send_pairing_decision, send_transfer_decision (+ existing get_watchdog_state, restart_daemon)
- Support bundle stub: NOT_IMPLEMENTED (deferred to N6-B)
- @tauri-apps/api added as frontend dependency
- 48 Rust tests (11 new), 52 web tests (20 new), 100 total
- Coverage: 91/94/85/90 (above 90/90/80/90 thresholds)
- B-DEP-N1-1 STILL OPEN: platform path CLI flags (blocks N6 GA)
- B-DEP-N2-3 STILL OPEN: Windows named pipe (blocks N6 Windows)
- localbolt-app tag: `localbolt-app-v1.2.12-n6a2-ipc-ui-gating` (`8f4aea9`)
- Tag: `ecosystem-v0.1.79-n-stream-1-n6a2-progress`

---

## N-STREAM-1 N6-A1 — Sidecar Lifecycle + Watchdog Core — 2026-03-07

- **N6 IN-PROGRESS (N6-A1 completed):** Daemon sidecar lifecycle and watchdog core implemented in localbolt-app
- Watchdog state machine: 5 states (starting/ready/restarting/degraded/incompatible), 1s/3s/10s backoff, 3 max retries, 60s reset
- Daemon manager: process spawn, stale socket/PID cleanup, SIGTERM+5s+SIGKILL shutdown
- IPC readiness probe: version.handshake + version.status + daemon.status per N2 contract
- stderr ring buffer (1000 lines) with crash snapshot persistence
- Tauri commands: get_watchdog_state, restart_daemon, export_support_bundle (stub)
- App lifecycle: daemon start on launch, shutdown on window close
- 37 new Rust tests (watchdog 17, daemon_log 5, ipc_client 5, ipc_types 4, daemon 4, commands 2)
- Existing 32 web tests unchanged
- Uses std::process::Command (not Tauri sidecar API) due to Unix socket IPC + PID-level signal requirements
- localbolt-app tag: `localbolt-app-v1.2.11-n6a-sidecar-lifecycle` (`0c218bb`)
- Tag: `ecosystem-v0.1.78-n-stream-1-n6a-progress`

---

## B-DEP-N2 Unblock — daemon.status + Version Handshake Implemented — 2026-03-07

- **B-DEP-N2-1 RESOLVED:** `daemon.status` event now emitted in all daemon modes (default, smoke, simulate) after successful IPC version handshake. Previously simulate-mode only.
- **B-DEP-N2-2 RESOLVED:** `version.handshake` (app→daemon) and `version.status` (daemon→app) messages implemented with strict `major.minor` match enforcement. Fail-closed on incompatible, malformed, missing, or late handshake. No grace mode.
- **N6 unblocked (readiness + version-gate):** N3 readiness transition (`starting → ready`) and version-gated supervision (`starting → incompatible`) are no longer blocked by daemon dependencies.
- **R15 CLOSED:** B-DEP-N2-1/N2-2 risk resolved.
- **B-DEP-N1-1 STILL OPEN:** Platform path CLI flags not implemented (blocks N6 GA, not N6 start).
- **B-DEP-N2-3 STILL OPEN:** Windows named pipe not supported (blocks N6 Windows).
- IPC event ordering: `version.status` → `daemon.status` → normal events
- 20 new tests in bolt-daemon (5 type, 8 version compat, 7 handshake integration)
- Default: 338 (was 318). test-support: 418+3ign (was 398+3ign)
- Daemon tag: `daemon-v0.2.31-bdep-n2-ipc-unblock` (`1ad2db8`)
- Tag: `ecosystem-v0.1.77-n-stream-1-bdep-n2-unblock`

---

## N-STREAM-1 N4+N5 Spec Lock — Rollout + Migration + Acceptance Harness — 2026-03-07

- **N4 DONE (spec locked):** Rollout + migration strategy locked
  - N4-R1: 4-stage rollout (Local/Dev, Alpha, Beta, GA) with entry/exit criteria and cannot-progress gates
  - N4-R2: Version-skew policy — strict major.minor match, fail-closed, 5 accidental skew scenarios handled
  - N4-R3: Whole-bundle update/rollback model — data preservation (identity/TOFU), transient state reset, rollback triggers
  - N4-R4: Migration strategy — purely additive (no existing daemon config), transparent, 5 invariants (M-01–M-05)
  - N4-R5: Blocker-aware gating — decision tree mapping B-DEP-N2-1/N2-2/N1-1/N2-3 to stage gates
  - 7 acceptance checks defined (AC-N4-1 through AC-N4-7)
- **N5 DONE (spec locked):** Acceptance harness specification locked
  - N5-H1: 8 test domains (packaging, lifecycle, IPC readiness, IPC messages, degraded UX, update/rollback, diagnostics, data safety)
  - N5-H2: 4 tiers — Smoke (8 checks), Integration (26 checks), Failure Injection (8 checks), Pre-Release (2 checks, GA-only)
  - N5-H3: Pass/fail criteria — hard fail blocks progression, soft fail tracked, tier progression rule enforced
  - N5-H4: Blocker-aware execution — 9 blocked checks report SKIP(B-DEP-ID), re-execute on B-DEP resolution
  - N5-H5: Evidence contract — 9 artifact types, CI vs human-review classification, retention until N7
  - N5-I1: Incorporation table — all 44 checks (37 from N1–N3 + 7 from N4) mapped to tiers, verified by arithmetic
- **P1 dependency re-validation:**
  - B-DEP-N2-1 STILL OPEN: `daemon.status` only in simulate mode
  - B-DEP-N2-2 STILL OPEN: `version.handshake`/`version.status` not implemented
  - B-DEP-N1-1 STILL OPEN: platform path CLI flags not implemented
  - B-DEP-N2-3 STILL OPEN: Windows named pipe not supported
- N6 (execution) now unblocked (depends on N4+N5, both DONE; runtime execution blocked by B-DEPs per N4-R5)
- Tag: `ecosystem-v0.1.76-n-stream-1-n4-n5-lock`

---

## N-STREAM-1 N3 Supervision Spec Lock — Process Supervision + Diagnostics — 2026-03-07

- **N3 DONE (spec locked; B-DEP-N2-1/N2-2 block N6 implementation):** Supervision + diagnostics requirements locked
  - N3-W1: Watchdog state machine — 5 states (starting/ready/restarting/degraded/incompatible), 6 invariants
  - N3-W2: Retry/backoff — 1s/3s/10s exponential, 3 max retries, 60s success reset (operationalizes N0 D0.4)
  - N3-W3: Stale socket/process cleanup — PID file + socket probe algorithm, app-owned PID file management
  - N3-W4: Shutdown lifecycle — SIGTERM+5s grace+SIGKILL, active transfer warning (operationalizes N0 D0.3)
  - N3-W5: stderr/log capture — 1000-line ring buffer, crash snapshots, `[DAEMON_CRASH]`/`[WATCHDOG]` tokens, support bundle spec (6 required items)
  - N3-W6: User-visible status — 5 state indicators with action affordances, ARIA accessibility
  - 15 acceptance checks defined for N5 harness (AC-N3-1 through AC-N3-15)
  - N6 implementation readiness plan: 9-step Rust/Tauri sequence + 7-step UI sequence
- **P1 dependency re-validation:**
  - B-DEP-N2-1 STILL OPEN: `daemon.status` only in simulate mode (`main.rs:1085-1098`)
  - B-DEP-N2-2 STILL OPEN: `version.handshake`/`version.status` messages not implemented (zero source matches)
  - N1-T4 path assumptions validated consistent with N3 cleanup semantics
  - PID file management confirmed absent from daemon — app-owned PID file specified
  - Existing daemon stale socket cleanup audited (`server.rs:112-116`, `Drop` impl at `344-351`)
- **N3 readiness matrix:** All 6 sub-items spec-locked (READY). N6 impl partially blocked: readiness transition (B-DEP-N2-1) and version-gate transition (B-DEP-N2-2)
- R15 updated: N3 spec locked, R15 now tracks N6 implementation block only
- N4 (rollout) now unblocked (depends on N1+N2, both DONE)
- N5 (acceptance harness) now unblocked (depends on N2+N3, both DONE)
- Tag: `ecosystem-v0.1.75-n-stream-1-n3-supervision`

---

## N-STREAM-1 N1+N2 Lock — Packaging Matrix + IPC Contract — 2026-03-07

- **N1 DONE:** Per-platform packaging + security matrix locked (macOS/Windows/Linux)
  - Bundle location + binary naming per Tauri v2 sidecar convention
  - Platform-appropriate filesystem locations (socket, PID, identity, pins, logs, config)
  - Signing/notarization: SHOULD (pre-release), REQUIRED (GA)
  - Least-privilege permission model (no elevation, `0600` socket, data-dir-only writes)
  - Co-versioned bundle, whole-bundle update/rollback only
  - 11 acceptance checks defined for N5 harness
- **N2 DONE (spec locked, implementation dependencies open):** IPC contract baseline locked
  - 5 stable messages: `daemon.status`, `pairing.request`, `transfer.incoming.request`, `pairing.decision`, `transfer.incoming.decision`
  - 2 provisional messages: `version.handshake` (app->daemon), `version.status` (daemon->app) — schema locked, implementation B-STREAM
  - NDJSON wire format, single-client kick-on-reconnect, 1 MiB max line, 30s decision timeout (fail-closed)
  - Version handshake required as first IPC exchange; strict major.minor match
  - Compatibility policy: breaking = major bump, non-breaking = minor bump, unknown types silently dropped
  - 5 degraded mode transitions, error contract, 11 acceptance checks
- **B-STREAM dependencies recorded:**
  - B-DEP-N1-1: `--socket-path`/`--data-dir` CLI flags (blocks N6 GA)
  - B-DEP-N2-1: `daemon.status` in default mode (blocks N3)
  - B-DEP-N2-2: `version.handshake`/`version.status` messages (blocks N3)
  - B-DEP-N2-3: Windows named pipe support (blocks N6 Windows)
- Risks R12/R13 closed; R15/R16 opened for B-STREAM deps
- N3 (supervision) and N4 (rollout) now unblocked (spec-side); N3 blocked on B-DEP-N2-1/N2-2 for implementation
- Tag: `ecosystem-v0.1.74-n-stream-1-n1-n2-lock`

---

## N-STREAM-1 N0 Policy Lock — Native App + Daemon Bundling — 2026-03-07

- **N0 DONE:** All 8 policy decisions locked (D0.1–D0.8), PM-approved
  - D0.1: App-managed daemon lifecycle (Tauri sidecar, no system service)
  - D0.2: Synchronous startup on app launch, 10s readiness timeout, `daemon.status` as readiness signal
  - D0.3: SIGTERM on app exit, 5s grace period, SIGKILL fallback; warn on active transfer
  - D0.4: Exponential backoff restart (1s/3s/10s), 3 max retries, degraded mode after exhaustion, 60s success reset
  - D0.5: Per-user single daemon instance via socket lockfile; kick-on-reconnect is current IPC behavior (may be revised in N2)
  - D0.6: Persistent state (identity key, TOFU pins) survives crashes; transient state (transfers, sessions) resets; PID file for stale detection
  - D0.7: Strict major.minor version match, fail-closed on mismatch; app+daemon co-versioned in bundle
  - D0.8: B-STREAM boundary reaffirmed; N-STREAM consumes daemon API, does not redefine protocol
- N1 (packaging) and N2 (IPC contract) unblocked
- Risk R14 closed (lifecycle/crash policy decided)
- Tag: `ecosystem-v0.1.73-n-stream-1-n0-policy-lock`

---

## N-STREAM-1 Codification — Native App + Daemon Bundling — 2026-03-07

- **N-STREAM-1 codified:** Governance workstream for native app + daemon bundling
  - Defines how native apps (localbolt-app first) bundle and lifecycle-manage bolt-daemon
  - 8 phases: N0 (policy lock) through N7 (closure)
  - Ownership boundary: N-STREAM-1 owns bundling/lifecycle/packaging/supervision; B-STREAM owns daemon protocol/runtime
  - N-STREAM-1 consumes daemon API surface, does not redefine it
  - Finding series `N1-F*` reserved in AUDIT_TRACKER.md
  - Risk register entries R12-R14 added (IPC stability, cross-platform packaging, lifecycle policy)
  - Product scope: localbolt-app primary; localbolt-v3 and localbolt web excluded
  - Daemon maturity dependency: N2 stabilizes current API surface only
  - ARCH-08 gate applies to any phase needing new top-level folders
- Tag: `ecosystem-v0.1.72-n-stream-1-codify`

---

## C-STREAM-R1 — UI/State Regression Recovery — 2026-03-06

- **C-STREAM-R1 DONE:** localbolt-v3 UX/state regression fixes
  - Generation guards on `handleConnectionStateChange`, `handleReceiveProgress`, `handleVerificationState`
  - Terminal-state-only reset (ignore intermediate WebRTC states)
  - Transfer terminal flag prevents late progress callbacks after cancel
  - Idempotent `disconnect()`
  - `snapshot()` returns live verification state (was hardcoded legacy)
  - Full transfer gating truth table tests (8 scenarios)
  - Stale verification callback guard tests
- Tag: `v3.0.80-c-stream-r1-ui-state-fix` (localbolt-v3)
- **Runner-context note:** `faq.test.ts`/`app.test.ts` apparent failures are root-run config artifacts (missing workspace config); all 70 web tests pass in-package. Not a regression or residual.
- **Tech debt (LOW):** `vitest.workspace.ts` at monorepo root would prevent root-run false failures.

---

## S-STREAM-R1 Closeout (R1-5 + R1-6) — Governance — 2026-03-06

- **R1-5 DONE:** Final validation gates passed across all product repos
  - localbolt: 319 tests PASS, build PASS
  - localbolt-app: 32 tests PASS, build PASS, coverage PASS (100%)
  - localbolt-v3 core: 50 tests PASS, build PASS
  - localbolt-v3 web: 59 tests PASS, build PASS
  - Total: 460 tests, 9/9 gates PASS, 0 failures
  - Tests-only verification: all 3 R1-4 commits confirmed tests-only (no runtime changes)
  - Tag integrity: all 7 R1-4 tags confirmed on origin (3 code + 3 docs + 1 ecosystem)
  - No D-stream infra/auth/deploy regressions
- **R1-6 DONE:** Governance reconciliation complete
  - STATE.md: R1-5/R1-6 DONE, S-STREAM-R1 CLOSED, repo tag snapshot updated, test counts updated
  - GOVERNANCE_WORKSTREAMS.md: all phases final, dependency map complete
  - ROADMAP.md: S-STREAM-R1 CLOSED/DONE
  - AUDIT_TRACKER.md: no finding status transitions warranted (R1-F series empty, no new findings)
  - Counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**
- **S-STREAM-R1 CLOSED:** All 7 phases complete (R1-0 through R1-6)
- **Sole residual:** Rust SDK reconnect/race tests (LOW) — deferred
- Tag: `ecosystem-v0.1.69-s-stream-r1-closeout`

---

## S-STREAM-R1 R1-4 Security Test Lift — Execution — 2026-03-06

- **R1-4 DONE:** Security-focused product test lift complete across all three target repos
- **localbolt:** +19 security-session-integrity tests (300 → 319). Covers stale callback rejection, trust transition isolation, transfer gating under reconnect edges, no-downgrade guarantees.
  - Tag: `localbolt-v1.0.27-s-stream-r1-r1.4-security-test-lift` (`fc360c5`)
- **localbolt-app:** +21 security-session-integrity tests (11 → 32). Covers identity/trust wiring in connect/reconnect, stale generation patterns, transfer gating transitions, session isolation.
  - Tag: `localbolt-app-v1.2.10-s-stream-r1-r1.4-security-test-lift` (`71c3181`)
- **localbolt-v3:** +7 security-reconnect-integrity tests in localbolt-core (43 → 50). Covers crypto-path integrity at reconnect boundary, trust isolation between sessions. Web tests unchanged (59).
  - Tag: `v3.0.79-s-stream-r1-r1.4-security-test-lift` (`31046ac`)
- **Runtime changes:** None (tests-only)
- **Residual:** Rust SDK reconnect/race tests (LOW) deferred — out of R1-4 product scope
- All R1-0 HIGH and MEDIUM security test gaps now covered
- R1-5 (validation gates) unblocked
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**

---

## S-STREAM-R1 R1-1 Architecture Disposition — Decision — 2026-03-06

- **R1-1 DONE:** Formal dispositions locked based on R1-0 evidence
- **D1 — SA1 Disposition: Path C** — SA1 closure confirmed. No new finding registered, no SA1 reopen.
  - Evidence: R1-0 daemon key-role inventory — identity persistent/TOFU-only, ephemeral per-session/crypto-only, 22 tests, zero ambiguous usage
- **D2 — R1-2: DONE-NO-ACTION** — No unresolved daemon architecture risk. SA1 separation verified complete.
- **D3 — R1-3: DONE-NO-ACTION** — All 3 products already use SDK-mediated crypto exclusively. Zero direct tweetnacl calls.
- **D4 — R1-4: Scope locked** as primary remaining S-STREAM-R1 execution scope:
  - localbolt: HIGH — 300 tests, 0 security (handshake/crypto-path/session state)
  - localbolt-app: HIGH — 11 tests, smoketest only
  - localbolt-v3: MEDIUM — verify if C7/H5-v3 coverage is adequate
- No runtime code changes made
- Tag: `ecosystem-v0.1.67-s-stream-r1-r1.1-disposition`
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**

---

## S-STREAM-R1 R1-0 Baseline Evidence — Execution — 2026-03-06

- **R1-0 DONE:** Baseline evidence + risk classification complete across all in-scope repos
- **Daemon key-role inventory:** SA1 separation confirmed complete — identity (persistent, TOFU-only) vs ephemeral (per-session, crypto-only). 22 SA1 tests. No ambiguous usage found. SA1 closure holds.
- **Product crypto-path inventory:** All 3 products use SDK-mediated crypto exclusively. Zero direct tweetnacl calls in product code. No R1-3 migrations needed.
- **Security test gaps identified:**
  - localbolt (v2): 300 tests but 0 handshake / 0 crypto-path / 0 session state security tests (HIGH)
  - localbolt-app: 11 tests, smoketest + TOFU integration only — no broad security coverage (HIGH)
  - All products: no product-layer crypto-path integration tests (MEDIUM)
- **Baseline metrics (all green):** daemon 318/398, bolt-core TS 120, transport-web 253, Rust 97/127, localbolt 300, localbolt-app 11, v3-core 43, v3-web 59
- **R1-1 agenda:** Evaluate whether gaps warrant new findings or are accepted risk. SA1 Path A likely not needed.
- Tag: `ecosystem-v0.1.66-s-stream-r1-r1.0-baseline`
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**

---

## S-STREAM-R1 Codification — Governance — 2026-03-06

- **S-STREAM-R1 codified:** Security/foundation recovery workstream — 7 phases (R1-0 through R1-6)
  - R1-0: Baseline evidence + risk classification
  - R1-1: Architecture decision (evidence-informed) + SA1 handling path
  - R1-2: Daemon remediation + security tests
  - R1-3: Product crypto-path convergence
  - R1-4: Security-focused product test lift
  - R1-5: Validation gates
  - R1-6: Governance reconciliation + closure
- **SA1 handling rule documented:** Path A (new R1-F finding) or Path B (explicit reopen), decided in R1-1 with evidence
- **Scope:** bolt-daemon (primary), localbolt-v3, localbolt, localbolt-app, bolt-core-sdk (if needed)
- **Priority:** Foundational security/runtime risks before further UX work
- Governance codification only — no execution deliverables
- Tag: `ecosystem-v0.1.65-s-stream-r1-codify`
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**

---

## D5 Drift Guards + Enforcement — DONE — 2026-03-06

- **D5 DONE:** Registry/auth regression guards added to all 3 consumer repos
  - `check-registry-mapping.sh`: ensures `.npmrc` maps `@the9ines` to `registry.npmjs.org`; rejects GitHub Packages refs and PAT dependencies
  - `check-lockfile-registry.sh`: ensures `package-lock.json` resolves `@the9ines` from `registry.npmjs.org`
  - CI cleanup: removed stale GitHub Packages auth (registry-url, NODE_AUTH_TOKEN, packages:read)
  - All 6 guards pass locally across all 3 repos
- **D6 UNBLOCKED:** 48h burn-in window starts now
- Tags:
  - `v3.0.78-d5-registry-guards` (`fec153b`)
  - `localbolt-v1.0.26-d5-registry-guards` (`76ae224`)
  - `localbolt-app-v1.2.9-d5-registry-guards` (`93afc2c`)
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**

---

## D4 Netlify Hardening — DONE — 2026-03-06

- **D4 DONE:** Consumer `.npmrc` cutover + Netlify deploy verified PAT-free
  - All 3 consumer repos switched from GitHub Packages to npmjs.org registry
  - Dependencies bumped: bolt-core 0.5.1, transport-web 0.6.4, localbolt-core 0.1.2
  - Lockfiles regenerated from registry.npmjs.org
  - Tests: localbolt-v3 102, localbolt 300, localbolt-app 11 — all pass
  - Netlify deploy: `state=ready`, `commit=0746275`, HTTP 200 at localbolt.app
  - Build fix: `netlify.toml` updated to build localbolt-core before localbolt-web (workspace symlink dist/ required on clean clone)
  - `NPM_TOKEN` env var retained (inert) through D6 burn-in for rollback safety
- **D5 UNBLOCKED:** Drift guards + enforcement can proceed
- Tags:
  - `v3.0.76-d4-npmjs-cutover` (`ef0543e`), `v3.0.77-d4-netlify-build-fix` (`0746275`)
  - `localbolt-v1.0.25-d4-npmjs-cutover` (`9bb3c38`)
  - `localbolt-app-v1.2.8-d4-npmjs-cutover` (`55c3e17`)
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## D0.5 Scope Verification + D3 Registry Migration — 2026-03-05

- **D0.5 DONE:** `@the9ines` npmjs.org scope verification passed
  - Scope owned by `the9ines` user; automation token configured
  - D3 unblocked
- **D3 DONE:** All 3 deploy-critical packages published to npmjs.org (PAT-free)
  - `@the9ines/bolt-core@0.5.1` — verified on npmjs
  - `@the9ines/bolt-transport-web@0.6.4` — verified on npmjs
  - `@the9ines/localbolt-core@0.1.2` — verified on npmjs
  - `publishConfig` changed from hardcoded GitHub Packages registry to `{"access": "public"}`
  - Existing GitHub Packages publish workflows preserved with explicit `--registry` flag
  - New `workflow_dispatch` npmjs publish workflows created for all 3 packages
  - PAT-free clean-environment install verified for all 3 packages
- **D0 DONE:** Policy lock complete (D0.5 was final gate)
- **D4 UNBLOCKED:** Netlify consumer `.npmrc` cutover can now proceed
- Version bumps required due to npmjs version immutability (previously published versions locked):
  - bolt-core: 0.5.0 → 0.5.1
  - bolt-transport-web: 0.6.2 → 0.6.4 (0.6.3 also locked)
  - localbolt-core: 0.1.0 → 0.1.2 (0.1.1 also locked)
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**
- Tag: `ecosystem-v0.1.62-d05-d3-registry-migration`
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## D1 Failure Baseline + D4 Netlify Unblock (Phase Cut) — 2026-03-05

- **D1 DONE:** Failure baseline and taxonomy produced across localbolt-v3, localbolt, localbolt-app
  - 5 failure signatures classified: GHPKG-AUTH-FAIL, DEPLOY-STALE, SDK-PUBLISH-LAG, BUILD-PATH-MISMATCH, DRIFT-REGRESSION
  - Top Netlify blocker: **GHPKG-AUTH-FAIL** — GitHub Packages requires PAT for all installs (even public packages)
  - No flaky test signatures observed; all failures were deterministic
- **D4 STOP:** Cannot proceed without D3 (package publication/migration)
  - All 3 deploy-critical packages (`bolt-core`, `bolt-transport-web`, `localbolt-core`) are exclusively on GitHub Packages
  - GitHub Packages has no PAT-free public install path — this is a platform limitation
  - Minimum D3 substeps documented: D0.5 scope verification + 5 publish/config steps
- **localbolt-v3 Netlify status:** Currently operational via DP-8 workaround (NPM_TOKEN PAT in Netlify dashboard)
  - NOT PAT-independent — personal GitHub PAT required
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**
- Tag: `ecosystem-v0.1.61-d1-d4-netlify-unblock`
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## D-STREAM-1 Codification — 2026-03-05

- **D-STREAM-1 codified:** CI stabilization + package auth migration workstream
  - Primary success gate: Netlify deploy reliability (PAT-independent public package installs)
  - 7 phases: D0 (policy lock) → D1 (failure triage) → D2 (CI stabilization) → D3 (registry migration) → D4 (Netlify hardening) → D5 (drift guards) → D6 (burn-in)
  - D0 policy decisions 1–4 locked at codification (PM-approved)
  - D0.5 (npmjs @the9ines scope verification) NOT-STARTED — blocks D3
  - D3 explicit dependency: BLOCKED-BY D0.5
  - Deploy-critical package seed set: `@the9ines/bolt-core`, `@the9ines/bolt-transport-web`, `@the9ines/localbolt-core`
  - Repo scope: localbolt-v3 (primary), bolt-core-sdk (D3 only), localbolt, localbolt-app
  - bolt-core-sdk D3 tag convention: `sdk-v<next>-d3-registry-migration`
  - Dual-publish (GitHub Packages + npmjs) temporary during burn-in
- **C-stream status refresh:** C0–C7 all DONE (ROADMAP.md aligned with STATE.md/tag history)
- **Risk register:** R10 (app-layer drift) → Closed. R11 (ARCH-08 disposition) → Closed.
- **S0 acceptance criteria:** Marked complete (DONE-MERGED per STATE history)
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**
- D-stream placeholder in AUDIT_TRACKER.md does NOT increment total
- Tag: `ecosystem-v0.1.60-d-stream-1-codify`
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/ROADMAP.md`, `docs/STATE.md`, `docs/AUDIT_TRACKER.md`, `docs/CHANGELOG.md`

---

## Batch 6 — C7 Closure (Gap-Driven Audit + Targeted Test Fill) — 2026-03-05

- **C7 DONE:** Session UX race-hardening fully closed (Q7 → DONE-VERIFIED)
  - Gap-driven audit identified 2 missing evidence scenarios in `@the9ines/localbolt-core`
  - Added: rapid 7-cycle connect/reset monotonicity test (generation counter, state cleanliness, stale rejection)
  - Added: late verification callback from previous peer rejected after session switch
  - Prior evidence confirmed: session state machine (5-phase), A→B→C isolation, stale signal rejection, phase guards, transfer/verification cleanup
  - No runtime changes needed — existing code already handles all C7 scenarios
  - localbolt (300 tests) and localbolt-app (11 tests) unchanged — existing coverage sufficient
  - Tag: `v3.0.74-c7-closure` (`b867426`)
- **Q7 DONE-VERIFIED:** All disconnect/reconnect stale callback race scenarios covered
- Audit counters: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**
- C-Stream: all phases C0–C7 DONE
- Updated: `docs/AUDIT_TRACKER.md`, `docs/CHANGELOG.md`, `docs/STATE.md`

---

## Batch 5 — C6 Hardening Completion + Q4 Closure — 2026-03-05

- **C6 DONE:** localbolt-core drift/upgrade hardening completed
  - `upgrade-localbolt-core.sh` added to localbolt and localbolt-app (check + write modes)
  - `check-core-drift.sh` added to localbolt-v3 (CI-enforced, `packages/localbolt-web/src`)
  - localbolt-v3 workspace exemption documented (pin/single-install not applicable)
  - Manual drift validation runbook: `docs/LOCALBOLT_CORE_DRIFT_RUNBOOK.md`
  - Tags: `localbolt-v1.0.24-c6-hardening`, `localbolt-app-v1.2.7-c6-hardening`, `v3.0.73-c6-hardening`
- **Q4 DONE-VERIFIED:** localbolt-app coverage thresholds enforced (90/90/80/90), `@vitest/coverage-v8` installed, CI runs `test:coverage`
- **Q10 DONE-VERIFIED:** All deferred C6 scope completed (upgrade tooling, v3 drift CI, runbook)
- Audit counters: **110 total, 89 DONE, 0 OPEN, 1 IN-PROGRESS (Q7)**
- Updated: `docs/AUDIT_TRACKER.md`, `docs/CHANGELOG.md`, `docs/STATE.md`, `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/LOCALBOLT_CORE_DRIFT_RUNBOOK.md`

---

## Batch 4B — C7 TOFU wiring + CI guards + governance closure — 2026-03-05

- **C7 IN-PROGRESS:** Identity/TOFU verification flow wired into localbolt and localbolt-app
  - localbolt: `localbolt-v1.0.23-c7-tofu-wiring` (`1bcb7b8`) — 300 tests
  - localbolt-app: `localbolt-app-v1.2.6-c7-tofu-wiring` (`e902186`) — 11 tests
  - Identity keypair persistence, TOFU pinning, generation-guarded callbacks, mismatch fail-closed
  - Verification states (unverified, verified) reachable from UI
- **CI guards enforced:** Core guard scripts (version-pin, single-install, drift) wired into CI for both repos
- Q4 promoted: DEFERRED → IN-PROGRESS (localbolt-app now has 11 active tests)
- Q7 promoted: OPEN → IN-PROGRESS (generation guard race hardening landed)
- Q8 reconciled: OPEN → DONE-VERIFIED (resolved in Batch 3/C0)
- Q9 reconciled: OPEN → DONE-VERIFIED (resolved in Batch 3/C2-C5)
- Q10 updated: evidence refreshed with CI guard enforcement, remaining deferred scope listed
- Adoption table refreshed: localbolt bolt-core 0.5.0/transport-web 0.6.2/300 tests, localbolt-app 0.5.0/0.6.2/11 tests
- Audit counters: **110 total, 87 DONE, 0 OPEN, 2 IN-PROGRESS, 1 PARTIAL**
- Updated: `docs/AUDIT_TRACKER.md`, `docs/CHANGELOG.md`, `docs/STATE.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## Batch 3 — C4+C5+C6: localbolt-core publish + consumer migration — 2026-03-05

- **localbolt-core published:** `@the9ines/localbolt-core@0.1.0` published to GitHub Packages from localbolt-v3
  - Tag: `v3.0.72-localbolt-core-publish` (`7cb8d8d`)
- **C4 DONE:** localbolt consumer migrated to `@the9ines/localbolt-core@0.1.0`
  - Tag: `localbolt-v1.0.21-c4-localbolt-core` (migration)
  - Tag: `localbolt-v1.0.22-c6-core-guards` (`ed2d671`) (C6 enforcement guards)
- **C5 DONE:** localbolt-app web consumer migrated to `@the9ines/localbolt-core@0.1.0`
  - Tag: `localbolt-app-v1.2.4-c5-localbolt-core` (migration)
  - Tag: `localbolt-app-v1.2.5-c6-core-guards` (`d1761e9`) (C6 enforcement guards)
- **C6 PARTIAL:** Enforcement guards added to localbolt and localbolt-app. Upgrade tooling (scripts) deferred.
- Q9 promoted: OPEN → DONE-VERIFIED (all three consumers now on shared localbolt-core)
- Q10 updated: OPEN → PARTIAL (guards added, upgrade tooling deferred)
- Repo tag snapshot updated: localbolt-v3, localbolt, localbolt-app
- Audit counters: **110 total, 87 DONE, 2 OPEN** (was 86 DONE, 3 OPEN)
- Updated: `docs/STATE.md`, `docs/CHANGELOG.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## ecosystem-v0.1.56-c-stream-c2 — 2026-03-04

- **C0 DONE:** Policy lock — `unverified` blocks file transfer. Codified in `v3.0.70-session-hardening-cpre2` (`cac5e4a`). Runtime, tests, and docs aligned. Q8 → DONE-VERIFIED.
- **C1 DONE:** ARCH-08 resolved via non-violating location — `@the9ines/localbolt-core` placed at `localbolt-v3/packages/localbolt-core` (inside existing npm workspace). No waiver needed.
- **C2 DONE:** `v3.0.71-localbolt-core-c2` (`aa9e40e`, docs `fea35bc`)
  - Extracted session state machine, verification state bus, transfer gating policy (`isTransferAllowed`), and generation guards into `@the9ines/localbolt-core@0.1.0`
  - New files: `src/session-state.ts`, `src/verification-state.ts`, `src/transfer-policy.ts`, `src/index.ts`
  - 41 core tests (33 session-hardening + 8 transfer-policy)
  - Build: tsc → `dist/` with declaration files
- **C3 DONE:** localbolt-v3 consumer migrated in same commit as C2
  - `peer-connection.ts`, `transfer.ts`, `h5-tofu-verification.test.ts` import from `@the9ines/localbolt-core`
  - `session-hardening.test.ts` kept in web as consumer wiring integration test
  - 59 web tests (unchanged), 51.37% line coverage (above 48% threshold)
  - Deleted: `src/services/session-state.ts`, `src/services/verification-state.ts` (now in core)
- Repo tag snapshot updated: localbolt-v3 → `v3.0.71-localbolt-core-c2` (`aa9e40e`)
- localbolt-v3 TS test count updated: 59 → 100 (41 core + 59 web)
- Q8 promoted: OPEN → DONE-VERIFIED (C0 scope resolved)
- Audit counters: **110 total, 86 DONE, 3 OPEN** (was 85 DONE, 4 OPEN)
- Updated: `docs/STATE.md`, `docs/CHANGELOG.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## ecosystem-v0.1.55-audit-gov-50 — 2026-03-04

- **localbolt-v3 session hardening:** `v3.0.70-session-hardening-cpre2` (`cac5e4a`, docs `ebdf503`)
  - Session orchestration layer + race hardening for localbolt-v3
  - Transfer gating policy aligned (unverified peer status blocks file transfer)
  - 33 new tests (59 total), 58.22% line coverage (up from 54.26%)
  - Addresses Q7 scope (disconnect/reconnect stale callback races) ahead of formal C7
- Repo tag snapshot updated: localbolt-v3 → `v3.0.70-session-hardening-cpre2` (`cac5e4a`)
- localbolt-v3 TS test count updated: 26 → 59
- Audit counters unchanged: **110 total, 85 DONE, 4 OPEN**
- Updated: `docs/STATE.md`, `docs/CHANGELOG.md`

---

## ecosystem-v0.1.55-audit-gov-49 — 2026-03-04

- **Workstream C codified:** LocalBolt Application Convergence + Session UX Hardening
  - C0: Policy lock — verification UX decision (NOT-STARTED, blocked on PM)
  - C1: localbolt-core scaffold + ARCH-08 disposition gate (NOT-STARTED)
  - C2: Extract canonical runtime from v3 baseline (NOT-STARTED)
  - C3: Migrate localbolt-v3 consumer (NOT-STARTED)
  - C4: Migrate localbolt consumer (NOT-STARTED)
  - C5: Migrate localbolt-app web consumer (NOT-STARTED)
  - C6: Drift guards + upgrade protocol (NOT-STARTED)
  - C7: Session UX race-hardening (NOT-STARTED)
- **Q7–Q10 registered (OPEN):** 4 new MEDIUM-severity Quality findings for C-stream scope
  - Q7: Disconnect/reconnect stale callback races (C7)
  - Q8: Verification policy mismatch between runtime/tests/docs (C0)
  - Q9: App-layer behavior drift across localbolt-v3, localbolt, localbolt-app (C2–C5)
  - Q10: Missing app-layer drift guards (C6)
- Audit counters reconciled: **110 total, 85 DONE, 4 OPEN** (was 106/85/0)
- Extraction baseline: localbolt-v3 (5 factual anchor paths verified present)
- ARCH-08 disposition gate codified in C1 (waiver vs location vs external repo)
- localbolt-core tag discipline deferred to C1 outcome
- localbolt-core distribution: package-based with exact pins (NOT subtree)
- Docs-only governance codification; no runtime code changes
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/ROADMAP.md`, `docs/STATE.md`, `docs/CHANGELOG.md`, `docs/AUDIT_TRACKER.md`

---

## ecosystem-v0.1.54-audit-gov-48 — 2026-03-04

- **D-E2E-B DONE:** `daemon-v0.2.30-d-e2e-b-cross-impl` (`a8cf108`)
  - Cross-implementation bidirectional file transfer: Node.js offerer ↔ Rust daemon answerer
  - JS harness (`tests/ts-harness/harness.mjs`): node-datachannel, tweetnacl, ws
  - Real bolt-rendezvous signaling, real WebRTC DataChannel, real NaCl encryption
  - Full encrypted HELLO exchange with capability negotiation (bolt.file-hash + bolt.profile-envelope-v1)
  - Bidirectional transfer: Pattern A (4096 B) JS→daemon, Pattern B (6144 B) daemon→JS
  - SHA-256 hash verification in both directions: `[B4_VERIFY_OK]` (daemon) + harness hash check (JS)
  - Test-only send trigger: 30 lines in `src/rendezvous.rs`, all `#[cfg(feature = "test-support")]`
  - Two `#[ignore]` integration tests: happy-path bidirectional + negative integrity mismatch
  - Files changed: `src/rendezvous.rs`, `tests/d_e2e_bidirectional.rs` (new), `tests/ts-harness/` (new)
- D-E2E status: IN-PROGRESS → DONE (both D-E2E-A and D-E2E-B complete)
- Daemon test counts: 318 default / 398 test-support + 3 ignored (was +1 ignored, +2 ignored E2E)
- Daemon tag snapshot updated: `daemon-v0.2.30-d-e2e-b-cross-impl` (`a8cf108`)
- Audit counters unchanged: **106 total, 85 DONE, 0 OPEN**
- Updated: `docs/STATE.md`, `docs/CHANGELOG.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## ecosystem-v0.1.53-audit-gov-47 — 2026-03-04

- **DP-9 CLOSED → DONE-VERIFIED:** SDK fix `sdk-v0.5.27-dp9-backpressure-fix` (`1be76c1`)
  - `bufferedAmountLowThreshold = 65536` (64KB) set in `setupDataChannel()`
  - 5s timeout fallback on backpressure await
  - `sendInProgress` guard prevents concurrent `sendFile` calls
  - Published `@the9ines/bolt-transport-web@0.6.2`
  - Consumer adoption: `v3.0.69-dp9-backpressure-fix` (`48617f0`). Deployed to production.
  - 253 SDK tests pass, 26 localbolt-v3 tests pass
- Audit counters: **106 total, 85 DONE, 0 OPEN**
- Repo tag snapshots updated: bolt-core-sdk → `sdk-v0.5.27-dp9-backpressure-fix` (`1be76c1`)
- Updated: `docs/AUDIT_TRACKER.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## ecosystem-v0.1.52-audit-gov-46 — 2026-03-04

- **DP-9 registered (OPEN):** Responder sendFile backpressure hang — `TransferManager.sendFile()` hangs
  indefinitely due to `bufferedAmountLowThreshold` defaulting to 0, no timeout fallback, and concurrent
  `sendFile` calls overwriting `onbufferedamountlow` handlers.
- Audit counters: **106 total, 84 DONE, 1 OPEN**
- Updated: `docs/AUDIT_TRACKER.md`

---

## ecosystem-v0.1.51-audit-gov-45 — 2026-03-04

- **DP-8 registered + closed (DONE-VERIFIED):** Netlify deployment stale — `.npmrc` missing from
  `packages/localbolt-web/`, Netlify couldn't install GitHub Packages scoped deps.
  Fix: `v3.0.68-dp8-netlify-npmrc` (`b1a2cd4`).
- Audit counters: **106 total, 84 DONE, 0 OPEN** (before DP-9 registration)
- Updated: `docs/AUDIT_TRACKER.md`

---

## ecosystem-v0.1.50-audit-gov-44 — 2026-03-03

- **NF-1 registered + closed (DONE-VERIFIED):** Envelope filename missing — file-transfer envelope
  carried an empty `name` field. SDK fix: `transport-web-v0.6.10-nf1-envelope-filename` (`c3ccd17`).
- 2026-03-03 4-agent security re-audit frozen as `docs/AUDITS/2026-03-03-security-re-audit.md`
- Audit counters: **104 total, 83 DONE, 0 OPEN**
- Updated: `docs/AUDIT_TRACKER.md`, `docs/STATE.md`

---

## ecosystem-v0.1.49-audit-gov-43 — 2026-03-03

- **B3-P3 DONE:** `daemon-v0.2.29-b3-transfer-sm-p3-sender` (`4fd55e3`) — sender-side transfer MVP
  - SendSession state machine: Idle → OfferSent → Sending → Completed/Cancelled
  - Cursor-driven chunk streaming (DEFAULT_CHUNK_SIZE = 16,384 bytes)
  - SHA-256 hash gating via `bolt_core::hash::sha256_hex` when bolt.file-hash negotiated
  - FileAccept/Cancel carved out from `route_inner_message` to Ok(None) for loop-level interception
  - Loop-level FileAccept drives send-side SM when active, absorbed when idle; Cancel same pattern
  - Pause/Resume remain INVALID_STATE (not implemented this phase)
  - No new DcMessage variants, no new EnvelopeError variants, no new canonical error codes
  - No disk IO, no async, no new dependencies, dc_messages.rs unchanged
  - Files changed: `src/transfer.rs`, `src/envelope.rs`, `src/rendezvous.rs`, `src/lib.rs`
- Daemon test counts updated: 318 default / 398 test-support + 1 ignored (was 302/382, +16)
- Daemon tag snapshot updated: `daemon-v0.2.29-b3-transfer-sm-p3-sender` (`4fd55e3`)
- B3 status: remaining work reduced (send-side delivered; pause/resume, disk writes, concurrent transfers remain)
- Updated: `docs/CHANGELOG.md`, `docs/STATE.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## ecosystem-v0.1.48-audit-gov-42 — 2026-03-03

Reconciliation commit: backfills DP-series (GOV-32–39) and DP-7 (GOV-41)
into CHANGELOG/STATE/GOVERNANCE, corrects audit counters, and updates all
repo tag snapshots to match current origin HEADs.

- Audit counters corrected: **103 total, 82 DONE, 0 OPEN** (was stale at 96/75 since GOV-31)
- Repo tag snapshots reconciled with current origin HEADs
- DP-series (GOV-32–39) and DP-7 (GOV-41) backfilled below
- Updated: `docs/CHANGELOG.md`, `docs/STATE.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## ecosystem-v0.1.47-audit-gov-41 — 2026-03-03

- **DP-7 DONE:** `sdk-v0.5.25-bolt-core-050` (`c776118`) + `v3.0.67-dp7-bolt-core-050` (`6bb21b3`)
  - `transport-web@0.6.1` imports `isValidWireErrorCode` from bolt-core, but bolt-core 0.4.0 predates the wire error registry (AC-8)
  - Fixed by publishing `@the9ines/bolt-core@0.5.0` with `WIRE_ERROR_CODES` + `isValidWireErrorCode`
  - localbolt-v3 bumped to bolt-core 0.5.0; Netlify build unblocked
- Audit counters: 103 total, 82 DONE, 0 OPEN
- AUDIT_TRACKER only; CHANGELOG/STATE not updated at the time (backfilled in GOV-42)

---

## ecosystem-v0.1.38..v0.1.45 — DP-series (GOV-32–39) — 2026-03-03

Deployment findings discovered during Fly.io deployment of bolt-rendezvous signal server. All 6 findings registered, resolved, and closed in `docs/AUDIT_TRACKER.md`. These commits only touched AUDIT_TRACKER.md; CHANGELOG/STATE/GOVERNANCE were not updated at the time. Backfilled here for completeness.

- **DP-1 DONE:** `rendezvous-v0.2.9-dp1-rust-bump` (`449796a`) — Dockerfile Rust 1.84→1.85 for edition2024 compat
- **DP-2 DONE:** `rendezvous-v0.2.10-dp2-health-check` (`06a0f42`) — HTTP health check handler for Fly.io proxy
- **DP-3 DONE:** 3 repos, 3 compounding bugs causing phantom device entries
  - `rendezvous-v0.2.11-dp3a-stale-peer-replace` (`f00ed7c`) — server replaces stale peer on re-registration
  - `v3.0.65-dp3b-dp4-phantom-transfer` (`08382f1`) — peer code persisted in sessionStorage
  - `sdk-v0.5.23-dp3c-stale-peer-cleanup` (`5496030`) — `handlePeersList` emits `peerLost` for stale entries
- **DP-4 DONE:** `v3.0.65-dp3b-dp4-phantom-transfer` (`08382f1`) — removed verification gate blocking unverified peer uploads
- **DP-5 DONE:** `rendezvous-v0.2.12-dp5-session-guard` (`aa8bed0`) — monotonic session_id prevents stale cleanup race
- **DP-6 DONE:** `sdk-v0.5.24-dp6-responder-send-fix` (`3c71407`) — clear stale receive progress; `transport-web@0.6.1` published; `v3.0.66-dp6-transport-web-bump` (`8f98716`) adopted
- DP-series: 6 findings, 6 resolved, 0 open. All MEDIUM severity.
- Audit counters at GOV-39: 102 total, 81 DONE, 0 OPEN

---

## ecosystem-v0.1.46-audit-gov-40 — 2026-03-03

- **D-E2E-A DONE:** `daemon-v0.2.28-d-e2e-a-live-transfer` (`b105344`) — live E2E transfer with SHA-256 hash verification
  - Synthetic Rust offerer → bolt-daemon answerer via real bolt-rendezvous
  - Real WebRTC (libdatachannel), real NaCl encryption, real profile-envelope-v1
  - Full signaling: register → hello/ack → SDP offer/answer → ICE exchange → DataChannel open
  - Full HELLO: encrypted identity exchange, capability negotiation (bolt.file-hash + bolt.profile-envelope-v1)
  - Full transfer: FileOffer (with SHA-256 hash) → FileChunk (4096 bytes) → FileFinish
  - Evidence: daemon emits `[B4_VERIFY_OK]` on stderr — unambiguous hash verification proof
  - Files changed: `src/transfer.rs`, `src/rendezvous.rs`, `Cargo.toml`, `tests/d_e2e_web_to_daemon.rs` (new)
- Daemon test counts updated: 302 default / 382 test-support + 1 ignored E2E (was 300/380, +2 unit + 1 E2E)
- D-E2E status: NOT-STARTED → IN-PROGRESS (D-E2E-A complete; D-E2E-B cross-implementation TS↔Rust deferred)

---

## ecosystem-v0.1.37-audit-gov-31 — 2026-03-03

- **B4 DONE:** `daemon-v0.2.27-b4-file-hash` (`b41f814`) — receiver-side SHA-256 hash verification gated by bolt.file-hash
  - `bolt.file-hash` added to `DAEMON_CAPABILITIES` (SA15 superseded)
  - TransferSession: `expected_hash` field, `on_file_offer` accepts optional hash parameter
  - `on_file_finish`: computes `bolt_core::hash::sha256_hex(&buffer)`, case-insensitive compare
  - New `TransferError::IntegrityFailed` variant for hash mismatch path
  - Loop-level capability gating: negotiated + missing hash → `INTEGRITY_FAILED` + disconnect
  - Not negotiated → hash on wire ignored (transfer succeeds)
  - Mismatch → `build_error_payload("INTEGRITY_FAILED", ...)` + disconnect
  - Sender-side hashing out of scope (daemon is receive-only per B3-P2)
  - No new dependencies, no new EnvelopeError variants, no wire format changes, no new error codes
  - Files changed: `src/transfer.rs`, `src/rendezvous.rs`, `src/web_hello.rs`
- Daemon test counts updated: 300 default / 380 test-support (was 291/371, +9)
- Daemon tag snapshot updated: `daemon-v0.2.27-b4-file-hash` (`b41f814`)
- B4 status: NOT-STARTED → DONE
- SA15 status: DONE-BY-DESIGN → SUPERSEDED (bolt.file-hash now implemented)
- D-E2E dependency updated: blocked on B3 full + B6 (B4 no longer blocking)
- Audit counters unchanged (75 DONE, 0 OPEN, 96 total) — no audit findings created or modified
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only; no runtime repos modified

---

## ecosystem-v0.1.36-audit-gov-30 — 2026-03-03

- **B3-P2 DONE:** `daemon-v0.2.26-b3-transfer-sm-p2` (`5844199`) — receive-side transfer data plane with chunk reassembly
  - TransferSession extended: Idle → OfferReceived → Receiving → Completed (+ Rejected from P1)
  - Auto-accept policy: FileOffer → `accept_current_offer()` → send `DcMessage::FileAccept`
  - Chunk receive: base64 decode via `bolt_core::encoding::from_base64` → `on_file_chunk` with sequential index enforcement
  - In-memory reassembly with `MAX_TRANSFER_BYTES` (256 MiB) cap at offer and chunk level
  - Transfer completion via `on_file_finish` → Completed state, `completed_bytes()` accessor
  - FileChunk and FileFinish carved out of `route_inner_message` to `Ok(None)` for loop-level handling
  - Loop interception expanded: `match` on FileOffer/FileChunk/FileFinish with full error handling
  - No disk writes, no send-side, no hashing (B4 scope), no pause/resume, no concurrent transfers
  - Files changed: `src/transfer.rs`, `src/envelope.rs`, `src/rendezvous.rs`
- Daemon test counts updated: 291 default / 371 test-support (was 279/359, +12)
- Daemon tag snapshot updated: `daemon-v0.2.26-b3-transfer-sm-p2` (`5844199`)
- B3 status: IN-PROGRESS → IN-PROGRESS (P2 complete; remaining: pause/resume, cancel, disk writes, send-side, hashing)
- B6 status: loop now handles full receive path (FileOffer/FileChunk/FileFinish)
- Audit counters unchanged (75 DONE, 0 OPEN, 96 total) — no audit findings created or modified
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only; no runtime repos modified

---

## ecosystem-v0.1.35-audit-gov-29 — 2026-03-03

- **B3-P1 DONE:** `daemon-v0.2.25-b3-transfer-sm-p1` (`edebe5d`) — transfer state machine skeleton with FileOffer → Cancel reject
  - TransferSession (Idle → OfferReceived → Rejected) integrated into `run_post_hello_loop`
  - FileOffer intercepted after envelope decrypt, rejected via Cancel (`cancelled_by="receiver"`)
  - Second offer while not Idle triggers INVALID_STATE disconnect
  - FileOffer carved out of `route_inner_message` combined transfer arm to Ok(None)
  - New files: `src/transfer.rs` (TransferSession, TransferState, TransferError)
  - Modified: `src/envelope.rs`, `src/rendezvous.rs`, `src/lib.rs`, `src/main.rs`
- Daemon test counts updated: 279 default / 359 test-support (was 273/353, +6)
- Daemon tag snapshot updated: `daemon-v0.2.25-b3-transfer-sm-p1` (`edebe5d`)
- B3 status changed: NOT-STARTED → IN-PROGRESS (B3-P1 complete)
- Dependency graph updated: B3-P1 integrated into B6-P1 loop container
- Tag naming deviation documented (spec: `daemon-vX.Y.Z-transfer-converge-B3`, actual: `daemon-v0.2.25-b3-transfer-sm-p1`)
- Audit counters unchanged (75 DONE, 0 OPEN, 96 total) — no audit findings created or modified
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only; no runtime repos modified

---

## ecosystem-v0.1.34-audit-gov-28 — 2026-03-02

- Reconcile governance with daemon tags pushed to origin (B5, B6-P1, plus dep-refresh, B1B2, FMT-1)
- **B5 DONE:** `daemon-v0.2.23-b5-tofu-persist` (`0faa729`) — persistent TOFU pinning bound to DC HELLO identity key
- **B6-P1 DONE:** `daemon-v0.2.24-b6-loop-container` (`8666f44`) — shared `run_post_hello_loop()` with fail-closed transfer message policy
- Daemon test counts updated: 273 default / 353 test-support (was 254/334)
- Daemon tag snapshot updated: `daemon-v0.2.24-b6-loop-container` (`8666f44`)
- B3 description updated to reflect B6-P1 codebase state (transfer messages now INVALID_STATE, not Ok(None))
- Dependency graph updated: B5 DONE, B6 IN-PROGRESS, B3 sole remaining critical-path blocker
- Tag naming deviations documented for B5 and B6-P1 (tags immutable, deviation recorded)
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only; no runtime repos modified

---

## ecosystem-v0.1.33-forward-dev-enrich — 2026-03-02

- Enriched deferred phases B3, B4, B5, B6, D-E2E with verified spec references, corrected dependencies, gates, and acceptance definitions
- **Dependency corrections:**
  - B5 (TOFU wiring): independent — removed incorrect B3 prerequisite
  - B6 (event loop): removed incorrect B5 prerequisite; coupled with B3 only
  - B3+B6 identified as coupled critical path
- All "Derived From" references verified against PROTOCOL.md:
  - §8 (File Transfer), §9 (State Machines), §4 (Capabilities), §6 (Message Protection), §15.4 (Post-Handshake Envelope), §2 (Identity/TOFU)
- Daemon facts verified: `src/ipc/trust.rs` (17 tests), no `src/transfer.rs`, both event loops are deadline-bounded demo loops
- Tag naming rules extended for B4–B6 and D-E2E
- Parallelization rules updated to reflect corrected dependency graph
- Audit counters unchanged (75 DONE, 0 OPEN, 96 total) — no audit findings created or modified
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only; no runtime repos modified; no pushes

---

## ecosystem-v0.1.32-audit-gov-26 — 2026-03-02

- Closed FMT-GATE-1 (daemon rustfmt verification drift) as DONE-VERIFIED
  - Evidence: `daemon-v0.2.22-fmt-sync-1` (`9d0a485`)
  - Mechanical `cargo fmt` sync only — no logic or behavior changes
  - 6 files formatted; all gates green (254 default / 334 test-support)
- FMT-GATE-1 is a governance process item, not an audit finding — audit counters unchanged (75 DONE, 0 OPEN, 96 total)
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only; no runtime repos modified; no pushes

---

## ecosystem-v0.1.31-workstreams-2 — 2026-03-02

- Closed A-STREAM-1 (WebRTCService decomposition: A0–A2)
  - A0: Shared state scaffolding (`sdk-v0.5.22-webrtc-decompose-A0`, `6f0bb05`)
  - A1: HandshakeManager extraction (`sdk-v0.5.22-webrtc-decompose-A1`, `e2d2b76`)
  - A2: EnvelopeCodec + TransferManager extraction (`sdk-v0.5.22-webrtc-decompose-A2`, `7f7811d`)
  - WebRTCService reduced 1,369 → 790 LOC; public API unchanged; 249 transport-web tests stable
  - A3/A4 absorbed into A2; A5 remains future work
- Closed B-STREAM-1 (interop defaults + transfer message types: B1–B2)
  - B1+B2 combined: `daemon-v0.2.21-transfer-converge-B1B2` (`95d672f`)
  - Fail-closed option C; defaults flipped to Web*; +15 tests (254 default / 334 test-support)
  - Governance deviation documented (B1+B2 combined into single tag)
- Opened FMT-GATE-1 (daemon rustfmt CI discrepancy — LOW, process-only)
  - 6 pre-existing files fail `cargo fmt -- --check`
  - Resolution plan: dedicated FMT-1 phase with separate tag
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only governance codification; no runtime repositories modified; audit counters unchanged; no pushes

---

## ecosystem-v0.1.30-workstreams-1 — 2026-03-02

- Codify A/B workstreams and phase gates (WORKSTREAMS-1)
- **Workstream A (bolt-core-sdk):** WebRTCService decomposition — 5 phases (A1–A5)
  - A1: Extract HandshakeManager
  - A2: Extract EnvelopeCodec
  - A3: Extract TransferManager
  - A4: Slim WebRTCService to coordinator (public API unchanged)
  - A5: Decomposition test hardening
- **Workstream B (bolt-daemon):** File transfer convergence — 3 phases (B1–B3)
  - B1: Flip interop defaults (blast radius + legacy flag documented)
  - B2: DataChannel message variants + parsing tests
  - B3: Transfer engine state machine (no file-hash, no TOFU persistence, no event loop)
- **Deferred phases documented:** B4, B5, B6, D-E2E (with prerequisites)
- **SA15 supersession note:** governance-only acknowledgement that DONE-BY-DESIGN rationale will be superseded when B4–B6/D-E2E are reached
- **Phase gate checklist:** standardized template for all phases
- **Tag discipline:** per-workstream tag naming rules codified
- **No-push policy:** default for all phase execution
- New file: `docs/GOVERNANCE_WORKSTREAMS.md`
- Updated: `docs/DOC_ROUTING.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only governance codification; no runtime repositories modified; no pushes

---

## ecosystem-v0.1.29-audit-gov-25 — 2026-03-02

- Closed AC-13 (shadow tests replaced with canonical SDK imports) as DONE-VERIFIED
  - `sdk-v0.5.21-ac13-export-surface-1` (`829af85`)
  - `localbolt-v1.0.20-ac13-shadow-test-fix-1` (`b4d1a49`)
- Closed AC-15 (find_peer room isolation enforced) as DONE-VERIFIED (`rendezvous-v0.2.7-hardening-1`, `6ae3f77`)
- Closed AC-16 (XFF proxy allowlist, fail-closed) as DONE-VERIFIED (`rendezvous-v0.2.7-hardening-1`, `6ae3f77`)
- Closed AC-17 (export matrix exhausted, 33/33 VALUE exports in use) as DONE-VERIFIED
- Closed AC-22 (WebSocket connection limit, default 256) as DONE-VERIFIED (`rendezvous-v0.2.8-ac22-ws-conn-limit-1`, `bb59440`)
- Counters updated: DONE/DONE-VERIFIED 70→75, OPEN 5→0, Total 96
- **AC-series fully closed. All 25 findings resolved. OPEN = 0.**
- Tag snapshots updated: bolt-core-sdk, bolt-rendezvous, localbolt
- Docs-only governance reconciliation; no runtime repositories modified

---

## ecosystem-v0.1.28-audit-gov-24 — 2026-03-02

- Closed AC-10 (CONFORMANCE TODO reconciliation) as DONE-VERIFIED (`v0.1.5-spec-consistency-1`, `d795dd5`)
- Closed AC-11 (daemon dependency refresh) as DONE-VERIFIED (`daemon-v0.2.20-dep-refresh-1`, `99de9aa`)
- Closed AC-12 (cargo git dependency documentation) as DONE-VERIFIED (`ecosystem-v0.1.27-arch-consistency-1`, `fdb5545`)
- Counters updated: DONE/DONE-VERIFIED 67→70, OPEN 8→5, Total 96
- Remaining OPEN: AC-13, AC-15, AC-16, AC-17, AC-22
- bolt-daemon tag snapshot updated to daemon-v0.2.20-dep-refresh-1
- bolt-protocol tag snapshot updated to v0.1.5-spec-consistency-1
- Docs-only governance update; no runtime repositories modified

---

## ecosystem-v0.1.26-audit-gov-23 — 2026-03-02

- Closed AC-4 as DONE-VERIFIED (`v3.0.64-ac4-coverage-enforced`, `a5d0237`)
- Closed AC-5 as DONE-VERIFIED (`sdk-v0.5.20-protocol-converge-2`, `28c3baf`)
- Counters updated: DONE/DONE-VERIFIED 65→67, OPEN 10→8, Total 96
- All HIGH findings now closed (9/9 resolved)
- bolt-core-sdk tag snapshot updated to sdk-v0.5.20-protocol-converge-2
- localbolt-v3 tag snapshot updated to v3.0.64-ac4-coverage-enforced
- transport-web test count updated: 248→249 (+1 PROTO-HARDEN-08 send-side atomicity)
- Docs-only governance update; no runtime repositories modified

---

## ecosystem-v0.1.25-audit-gov-22 — 2026-03-02

- Closed AC-7 (verify-constants CI guard) as DONE-VERIFIED
- Closed AC-18 (dead crypto-utils barrel) as DONE-VERIFIED
- Reduced AC-17 (unused VALUE exports removed; types untouched; remains OPEN)
- Evidence: sdk-v0.5.19-governance-sweep-1 @ 9db3abd
- Counters updated: DONE/DONE-VERIFIED 63→65, OPEN 12→10, Total 96
- bolt-core TS test count corrected: 104→120
- bolt-core-sdk tag snapshot updated to sdk-v0.5.19-governance-sweep-1
- Docs-only governance update; no runtime repositories modified

---

## ecosystem-v0.1.24-audit-gov-21 — 2026-03-02

- Closed AC-6, AC-19, AC-20 (INTEROP-CONVERGENCE-1)
- Updated bolt-core-sdk snapshot to `sdk-v0.5.18-interop-converge-1` (`97352af`)
- Corrected stale transport-web test count (199 → 248)
- Severity table and OPEN counters reconciled (12 open, 13 resolved)

---

## ecosystem-v0.1.23-audit-gov-20

- Closed AC-21 as DONE-VERIFIED (`v0.1.4-spec`, `ede90be`)
- Closed AC-8 as DONE-VERIFIED (`sdk-v0.5.17-protocol-converge-1`, `16cfa92`)
- Closed AC-9 as DONE-VERIFIED (`sdk-v0.5.17-protocol-converge-1`, `16cfa92`)
- Reduced AC-5 (+6 explicit PROTO-HARDEN regression tests; remains OPEN)
- Counters updated: DONE/DONE-VERIFIED=60, OPEN=15, Total=96
- Docs-only governance update; no runtime repositories modified

---

## ecosystem-v0.1.22-audit-gov-19

- Closed AC-14 (subtree drift prevention implemented)
- Evidence: localbolt-v1.0.19-drift-guard-1 (6a4a006)
- Counters updated: DONE=57, OPEN=18, Total=96
- Drift guard implemented; staleness detection remains future enhancement

---

## ecosystem-v0.1.21-audit-gov-18

- Promoted AC-3 to DONE-VERIFIED
- Subtree refresh complete for signal/ in localbolt + localbolt-app
- Deterministic interop CI crate in place (no Cargo.toml mutation)
- Dead feature gate + unreachable cfg-gated tests removed
- DONE/DONE-VERIFIED 55 → 56
- OPEN 20 → 19

---

## ecosystem-v0.1.20-audit-gov-17

- Promoted AC-1 → DONE-VERIFIED
- Promoted AC-2 → DONE-VERIFIED
- DONE/DONE-VERIFIED 53 → 55
- OPEN 22 → 20
- Repository Tag Snapshot updated
- Docs-only governance update

---

## ecosystem-v0.1.19-audit-gov-16

- Registered 2026-03 Full Ecosystem Audit (AC-Series, 25 findings)
- Committed frozen audit source (`docs/AUDITS/2026-03-01-full-ecosystem-audit.md`)
- AC-1 through AC-22: OPEN (9 HIGH, 7 MEDIUM, 6 LOW)
- AC-23, AC-24, AC-25: DONE-BY-DESIGN
- Total findings now 96 (was 71)
- OPEN = 22, DONE-BY-DESIGN = 6
- No runtime changes

---

## ecosystem-v0.1.18-audit-gov-15

- N8 (per-capability string length bound) promoted to DONE-VERIFIED
  - daemon: `daemon-v0.2.19-low-n8` (`8683cbc`)
  - transport-web: `transport-web-v0.6.9-n8-caplen-1` (`ded0a40`)
- N10 (completion setTimeout cancellable) promoted to DONE-VERIFIED
  - transport-web: `transport-web-v0.6.8-low-n10` (`7f0bbaa`)
- N11 (openBoxPayload min-length guard) promoted to DONE-VERIFIED
  - sdk: `sdk-v0.5.15-low-n11` (`2a64e16`)
- N9 (cross-language golden vector test) closed DONE-BY-DESIGN
  - H3 vectors already prove TS seal → Rust open; auditor closed based on existing evidence
- N-series OPEN reduced to 0 — audit set fully resolved
- Global OPEN reduced to 0 — all 71 findings closed across all series
- DONE / DONE-VERIFIED: 50 → 53
- DONE-BY-DESIGN: 2 → 3

---

## ecosystem-v0.1.17-audit-gov-14

- Promote N6 to DONE-VERIFIED (typed HELLO errors)
- Promote N7 to DONE-VERIFIED (explicit HelloState guard)
- MEDIUM open reduced to 0
- Total findings unchanged (71)

---

## LIFECYCLE-HARDEN-1 — Deterministic Signaling Teardown (2026-02-28)

SA5 + SA6 lifecycle hardening in bolt-transport-web. Closes both
MEDIUM-severity LIFECYCLE-track findings from the 2026-02-26 audit.

**Deliverables:**
- **bolt-core-sdk** (`1962891`, `sdk-v0.5.11-lifecycle-harden-1`):
  - SA5: `handleSignal()` catch block calls `disconnect()` before
    `onError()`. `createPeerConnection()` nulls `this.pc` after close.
  - SA6: `SignalingProvider.onSignal()` returns unsubscribe function.
    WebSocketSignaling/DualSignaling return idempotent closures.
    WebRTCService stores handle, invokes early in `disconnect()`.
  - 8 new tests (3 SA5 + 5 SA6). 196 transport-web tests total.
- **bolt-ecosystem**: SA5/SA6 promoted to DONE-VERIFIED in tracker.

**Semver note:** `SignalingProvider.onSignal` return type changed from
`void` to `(() => void) | void`. Runtime-safe for void-return impls.

---

## PROTO-HARDEN-1R1 — Canonical Error Registry Unification (2026-02-26)

Unified the split error code registry (audit observation O4) into a single
canonical 22-code table in PROTOCOL.md §10. Previously, 11 protocol-level
codes lived in §10 and 14 enforcement codes in PROTOCOL_ENFORCEMENT.md
Appendix A, with only 3 overlapping. Now §10 is the sole authority.

**Deliverables:**
- **bolt-protocol** (`6a6de3f`, `v0.1.3-spec`): PROTOCOL.md §10 expanded
  to 22-code unified registry (11 PROTOCOL + 11 ENFORCEMENT) with Class,
  When, Framing, Semantics columns. §15.3 updated to reference unified §10.
  docs/CONFORMANCE.md §10 and §15.3 rows updated.
- **bolt-ecosystem**: PROTOCOL_ENFORCEMENT.md Appendix A converted to
  non-normative back-reference. STATE.md, CHANGELOG.md, AUDIT_TRACKER.md
  updated.

**No runtime code changed. No wire format changed. Governance/spec only.**

---

## PROTO-HARDEN-1 — Handshake Invariants Codified in Spec (2026-02-26)

Formalized five categories of handshake security properties as normative
spec text in PROTOCOL.md §15. Twelve numbered invariants (PROTO-HARDEN-01
through PROTO-HARDEN-12) make previously implicit guarantees explicit and
auditable.

**Categories:**
- §15.1 Ephemeral-first keying model — identity keys delivered only inside encrypted HELLO
- §15.2 Identity-ephemeral cryptographic binding — envelope MAC + SAS
- §15.3 Error registry invariants — single canonical registry, cross-impl parity
- §15.4 Post-handshake envelope requirement — no plaintext errors in normal operation
- §15.5 HELLO state machine — no reentrancy, exactly-once, immutable capabilities

**Deliverables:**
- **bolt-protocol** (`ee024d7`, `v0.1.2-spec`): PROTOCOL.md §15 added (+149 lines).
  docs/CONFORMANCE.md updated with 6 new rows (Status=TODO pending implementation audit).
- **bolt-ecosystem**: STATE.md, CHANGELOG.md, AUDIT_TRACKER.md updated.
  12 observations (O1–O12) mapped to PROTO-HARDEN invariants.

**No runtime code changed. No wire format changed. Governance only.**

---

## CONFORMANCE-2R — Enforceable Conformance Matrix with Minimum Coverage (2026-02-26)

Expanded conformance matrix with Evidence column, minimum coverage enforcement,
and CI validation. Converts IMPLEMENTED/PARTIAL assertions into demonstrated
traceability via concrete test file paths.

- **bolt-protocol**: docs/CONFORMANCE.md expanded — Evidence column added to both
  tables, 12/13 PROTOCOL rows and 12/13 PROFILE rows now have evidence links.
  Coverage Requirements section documents N=10 (protocol) and N=5 (profile)
  thresholds. Status migration: NOT REVIEWED → TODO (2 rows).
  .github/workflows/ci-conformance.yml updated — new inline coverage validation
  step parses Evidence column and enforces minimum counts.
- **bolt-ecosystem**: DOC_ROUTING.md updated with CONFORMANCE-2R note.
  STATE.md and CHANGELOG.md updated.
- **No runtime code changed. No dependencies added. No new script files created.**

---

## CONFORMANCE-1R — Spec Conformance Matrix + PR Review Gate (2026-02-26)

Introduced spec-to-implementation conformance matrix and CI review discipline
gate. Any PR to bolt-protocol that modifies PROTOCOL.md or LOCALBOLT_PROFILE.md
must also update docs/CONFORMANCE.md, or CI fails.

- **bolt-protocol** (`69a0907`): docs/CONFORMANCE.md (new) — maps all top-level
  spec sections to bolt-core-sdk and bolt-daemon implementation locations.
  .github/workflows/ci-conformance.yml (new) — PR gate using git merge-base diff.
  README.md updated with conformance link.
- **bolt-ecosystem**: DOC_ROUTING.md updated with CONFORMANCE.md entry.
  STATE.md and CHANGELOG.md updated.
- **No runtime code changed. No existing CI workflows modified. No dependencies added.**

---

## P1 — Inbound Error Validation Hardening (2026-02-26)

Daemon-side strict validation of inbound `{type:"error"}` messages.
Unknown/malformed error codes from remote peers are now treated as
`PROTOCOL_VIOLATION` + disconnect instead of `UNKNOWN_MESSAGE_TYPE`.
Single validator helper (`validate_inbound_error`), canonical registry
(`CANONICAL_ERROR_CODES`, 8 codes from Appendix A). No envelope decode
logic changed.

- **bolt-daemon** (`daemon-v0.2.12-p1-inbound-error-validation`, `8c45819`):
  +5 tests. Daemon total: 276 (up from 271).

---

## S2B — Transfer Instrumentation (2026-02-26)

Observability-only instrumentation of the TypeScript transfer path.
Structured metrics for chunk pacing, buffer pressure, and passive stall detection.
No behavior change. Zero overhead when disabled (default OFF).

- **bolt-core-sdk / transport-web** (`transport-web-v0.6.1-s2b-instrumentation`, `02e36b1`):
  New `transferMetrics` module: RingBuffer, TransferMetricsCollector, summarizeTransfer.
  Passive stall detection (retroactive, no timers).
  Feature-gated via `ENABLE_TRANSFER_METRICS` (default false).
  +24 tests. Transport-web total: 156 (up from 132).

---

## S2A — Transfer Policy Core (2026-02-26)

Greenfield Rust policy core for transfer scheduling. No behavior change; no callers wired; WASM consumption planned for S2B.

- **bolt-core-sdk** (`sdk-v0.5.5-s2-policy-skeleton`, `31bdc0b`):
  New `transfer_policy/` module — types (ChunkId, LinkStats, DeviceClass, TransferConstraints, FairnessMode, PolicyInput, Backpressure, ScheduleDecision, MAX_PACING_DELAY_MS) and deterministic `decide()` stub. 4 inline unit tests.
- **bolt-core-sdk** (`sdk-v0.5.6-s2-policy-contract-tests`, `39ed6dc`):
  15 integration contract tests in `tests/s2_policy_contracts.rs`. Validates determinism (identical inputs, ordering, across device classes/fairness modes), bounds (chunk count, window, pacing delay, edge cases), backpressure (over budget, exact boundary), and sanity contracts.
- **Test delta:** Rust default 66→85 (+19), vectors 96→115 (+19). No regressions. TS tests unchanged (97 + 132).
- **S2 status:** NOT-STARTED → IN-PROGRESS
- **WASM infra:** None present. Stop 3 (TS adapter) was NO-OP. S2B will address.

---

## Governance Sync — Roadmap Canonicalization (2026-02-26)

- Declared H/S spine as authoritative execution model
- Reclassified Phase 1/2/3 as legacy strategic roadmap
- Quarantined Cross-Repo Dependency Map + Release Sequencing as legacy strategic context
- Renamed S1 to "Core Protocol Conformance Harness (Rust SDK)" — scoped to bolt-core-sdk only
- S2 status corrected to NOT-STARTED
- Updated bolt-rendezvous/docs/STATE.md to match S0 truth (tag, commit, test counts, phase status)
- No code changes

---

## S0 — Canonical Hardened Rendezvous (2026-02-26)

Eliminated signaling authority drift. localbolt-v3 `packages/localbolt-signal/` now consumes bolt-rendezvous as a cargo git dependency. No independent protocol handling remains on the runtime path.

- **bolt-rendezvous** (`rendezvous-v0.2.2-s0-canonical-lib-verified`, `fd8d3df`):
  Promoted trust-boundary API to pub for library consumption. These pub items
  exist solely so the wrapper and tests reuse identical validation/rate-limit
  logic without reimplementation — not a public SDK-like API, only internal
  server policy exposure. 49 tests pass.

- **localbolt-v3** (`v3.0.63-s0-canonical-rendezvous`, `2963539`):
  Replaced local protocol.rs/server.rs/room.rs with canonical bolt-rendezvous wrapper.
  36 Rust tests (up from 32). Wire-format parity verified. LAN-only preserved.
  Dockerfile updated: git in builder stage for cargo git dep fetch.
  Dockerfile dev-dep stripping documented inline (awk workaround for sibling-path
  dev-deps unavailable in Docker build context).

- **Wire-format parity evidence:**
  8 fixture-based tests in `packages/localbolt-signal/src/lib.rs::tests` exercise
  canonical `bolt-rendezvous-protocol` types through the wrapper: `wire_deserialize_register`,
  `wire_deserialize_signal`, `wire_deserialize_ping`, `wire_serialize_peers`,
  `wire_serialize_peer_joined`, `wire_serialize_peer_left`, `wire_serialize_signal_relay`,
  `wire_serialize_error`. These use the same JSON shapes as bolt-rendezvous-protocol's
  16 golden snapshot tests (`protocol/src/lib.rs::tests::wire_*`). Since localbolt-signal
  now imports canonical types directly (no local reimplementation), parity is structural —
  both sides use identical serde types, eliminating drift by construction.

- **Git dependency resolution verified:**
  Tag `rendezvous-v0.2.2-s0-canonical-lib-verified` confirmed on origin (`fd8d3df7...`).
  `Cargo.lock` pins both `bolt-rendezvous` and `bolt-rendezvous-protocol` to exact commit
  `fd8d3df7196b25bfeb25d99868c0525c4a75f917`. Fly builds will resolve deterministically.

- **LAN smoke test:** Bound `0.0.0.0:3098`, connected via LAN IP `192.168.4.210`.
  Peer discovery, peer_joined, signal relay, clean disconnect all verified.

---

## Governance Sync — Post-Merge-Train Consolidation (2026-02-25)

Governance sync after merge train completion. Eliminated stale artifacts in PROTOCOL_ENFORCEMENT.md (Appendix B/C), verified H-series ledger accuracy, enriched S-series definitions in ROADMAP.md.

Mainline tags at time of sync:
- `v3.0.62-h1-mainline-merge` (localbolt-v3, `7571d35`)
- `sdk-v0.5.3-h2-h3-mainline` (bolt-core-sdk, `3f66da9`)
- `daemon-v0.2.10-h3-h6-mainline` (bolt-daemon, `0b16392`)
- `rendezvous-v0.2.1-h6-ci-enforcement` (bolt-rendezvous, `6f48ba7`)

---

## Mainline Convergence — Merge Train Complete (2026-02-25)

All H-phase work merged to main across all repos. Feature branches preserved.

- **localbolt-v3** (STOP 1): H1 signal hardening merged → `v3.0.62-h1-mainline-merge` (`7571d35`)
  - Docs: `v3.0.62-h1-mainline-merge-docs` (`a0c9dc8`)
  - Gates: 26 TS tests, 32 Rust tests, build, typecheck, fmt, clippy
- **bolt-core-sdk** (STOP 2): H2 + H3 merged → `sdk-v0.5.3-h2-h3-mainline` (`3f66da9`)
  - H3 test files received cargo fmt fixup (pre-H6 formatting)
  - Gates: 97 TS bolt-core, 132 TS transport-web, 69 Rust tests, audit-exports, check-vectors
- **bolt-daemon** (STOP 3): H3/H4/H3.1/H5/H6 stack merged → `daemon-v0.2.10-h3-h6-mainline` (`0b16392`)
  - Gates: 212 default tests, 267 test-support tests, fmt, clippy, no-panic check
- **bolt-rendezvous** (STOP 4): Verified — H6 tag already at HEAD, no action needed
- **Governance** (STOP 5): STATE.md + ROADMAP.md + CHANGELOG.md updated

Risk register: R1 (feature branch divergence), R2 (daemon panics), R7 (hermeticity), R8 (merge conflicts), R9 (no TOFU/SAS) all CLOSED.

---

## H6 — CI Enforcement Across Repos (2026-02-25)

Hardened CI gates across all four active repos. Gap-fill phase — no
greenfield CI creation, no protocol changes, no crypto changes.

- **bolt-core-sdk** (`sdk-v0.5.2-h6-ci-enforcement`, `476881a`):
  CI step reorder (vector drift check before tests), nonce uniqueness
  sanity tests (TS: 3 tests in `nonce-uniqueness.test.ts`, Rust: 1 test
  `nonce_uniqueness_sanity` in `crypto.rs`), `.nvmrc` added (Node 20).
  TS: 79 tests. Rust: 55 default, 60 with vectors.

- **bolt-daemon** (`daemon-v0.2.9-h6-ci-enforcement`, `398a63d`):
  Clippy upgraded from `-W clippy::all` to `-D warnings`. Added
  `cargo test --features test-support` (267 tests) and
  `scripts/check_no_panic.sh` to CI workflow. Branch:
  `feature/h5-downgrade-validation` (CI triggers on main only;
  local gates authoritative for tag).

- **bolt-rendezvous** (`rendezvous-v0.2.1-h6-ci-enforcement`, `6f48ba7`):
  Clippy upgraded from `-W clippy::all` to `-D warnings`. 49 tests pass.

- **localbolt-v3** (`v3.0.60-h6-ci-enforcement`, `3b12f73`):
  Audit-only — all gates already present (clippy -D warnings, coverage
  thresholds, transport drift guards). No code changes. 4 TS + 11 Rust tests.

Coverage enforcement: localbolt-v3 only (vitest v8 thresholds). All other
repos: deferred — no existing tooling. Risk R3 (no CI gate for vector
drift) closed.

---

## Docs Sync — H-Phase Ledger + Merge Train (2026-02-25)

Documentation-only update. No code, tag, or branch changes.

- **STATE.md**: Truthful ledger with `{DONE-MERGED, DONE-NOT-MERGED, IN-PROGRESS, NOT-STARTED}` status per H-phase. Fixed H2 branch name (`feature/h2-webrtc-enforcement`). Added H3.1 hermeticity blocker. Redefined H5 (TOFU/SAS wiring) and H6 (CI enforcement). Added merge train with per-step gates, remaining findings, and post-H6 roadmap.
- **ROADMAP.md**: Added truthful ledger and merge train with gates. Redefined H5 and H6. Noted old H5 scope absorption into H3/INTEROP. Added H3.1 as daemon merge prerequisite. Updated risk register and dependency map.
- **CHANGELOG.md**: Added H3.1 known-issue note. Added this entry.
- **PROTOCOL_ENFORCEMENT.md**: Added Appendix C (per-invariant adoption status across TS SDK and Rust daemon, with on-main column).

---

## H3 — Cross-Implementation Golden Vectors (2026-02-25)

Shared deterministic test vectors for SAS, HELLO-open, and envelope-open
operations. Eliminates cross-implementation drift between TS SDK, Rust SDK,
and bolt-daemon. Vector files generated by deterministic script with fixed
keypairs and nonces. Open-only testing (nonces are random in production).

- **bolt-core-sdk**: Generator (`generate-h3-vectors.mjs` with `--check` mode),
  3 vector files (SAS, HELLO-open, envelope-open), TS tests (94 total),
  Rust tests (68 total with `--features vectors`).
- **bolt-daemon**: HELLO-open and envelope-open vector integration tests
  (215+ total with `--features test-support`). Feature-gated `test-support`
  to avoid exposing test internals in production.
- **Tags**: `sdk-v0.5.1` (`9d8617d`), `daemon-v0.2.5-h3-golden-vectors` (`3751118`)
- **Branch**: `feature/h3-golden-vectors` (SDK + daemon). Not merged to main.

**Known issue (H3.1):** bolt-daemon `tests/h3_golden_vectors.rs` references
sibling repo paths (`../bolt-core-sdk/...`). Tests require bolt-core-sdk to
exist at a specific relative filesystem path, violating hermeticity. Tracked
as H3.1 — must be resolved before daemon H3 merges to main. See merge train
in `docs/ROADMAP.md` step 4.

## H2 — WebRTC Enforcement Compliance (2026-02-25)

Implement exactly-once HELLO, envelope-required binary enforcement, and
fail-closed semantics in WebRTCService per `PROTOCOL_ENFORCEMENT.md`.

- **bolt-core-sdk**: 21 enforcement tests covering exactly-once HELLO,
  envelope-required rejection, fail-closed per error code, downgrade resistance.
  transport-web total: 138 tests.
- **Tag**: `sdk-v0.5.0-h2-webrtc-enforcement` (`b4ce544`)
- **Branch**: `feature/h2-webrtc-enforcement`. Not merged to main.

## H1 — Signal Server Trust-Boundary Hardening (2026-02-25)

Port bolt-rendezvous-grade trust boundary enforcement into localbolt-v3
signal server. Rate limiting, message size caps, device name validation,
peer code length enforcement.

- **localbolt-v3**: `packages/localbolt-signal/src/server.rs` (+449/-26 lines).
- **Tag**: `v3.0.59-signal-hardening` (`ac5110c`)
- **Branch**: `feature/h1-signal-hardening`. Not merged to main.

## H0 — Protocol Enforcement Posture (2026-02-25)

Normative document defining runtime invariants and failure posture for all
Bolt Protocol implementations. Covers exactly-once HELLO, envelope-required
mode, fail-closed semantics, downgrade resistance, error frame requirements,
disconnect semantics, legacy mode boundary, and conformance test requirements.

- **bolt-ecosystem**: `docs/PROTOCOL_ENFORCEMENT.md` created.
- **Appendix A**: 14-code error registry.
- **Appendix B**: H-phase delivery record and implementation status.
- **Appendix C**: Per-invariant adoption status (added 2026-02-25 docs sync).
- Filesystem only (ecosystem root is not a git repo).

---

## Interop Milestones (bolt-daemon)

### INTEROP-4 — Minimal Post-HELLO Message Set (2026-02-25)

Prove session + envelope path works E2E with real messages: ping/pong
heartbeat and app_message echo. All sends through `encode_envelope`.

- **Tag**: `daemon-v0.2.4-interop-4-min-msgset` (`d7a79c4`)
- **Status**: Merged to main.
- **Tests**: 210 total.

### INTEROP-3 — Session Context + Profile Envelope v1 (2026-02-25)

Persist HELLO outcome in SessionContext, implement Profile Envelope v1
encrypt/decrypt for DataChannel, post-HELLO recv loop, no-downgrade enforcement.

- **Tag**: `daemon-v0.2.3-interop-3-session-envelope` (`a39fefc`)
- **Status**: Merged to main.
- **Tests**: 201 total.

### INTEROP-2 — Web HELLO Handshake (2026-02-25)

NaCl-box encrypted JSON HELLO exchange over DataChannel matching
bolt-transport-web wire format. Capability negotiation. Exactly-once guard.

- **Tag**: `daemon-v0.2.2-interop-2-web-hello` (`dd82669`)
- **Status**: Merged to main.
- **Tests**: 181 total.

### INTEROP-1 — Web Signaling Payloads (2026-02-25)

Web-compatible `{type, data, from, to}` inner signaling schema.

- **Tag**: `daemon-v0.2.1-interop-1-web-signal-payload` (`14c7448`)
- **Status**: Merged to main.
- **Tests**: 157 total.
