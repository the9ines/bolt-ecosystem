# WEBTRANSPORT-BROWSER-APP-1 — Codification Evidence

Captured: 2026-03-14
Operator: oberfelder (local workstation)
Context: Stream codification for browser↔app WebTransport migration.

---

## 1. Stream Summary

| Property | Value |
|----------|-------|
| Stream ID | WEBTRANSPORT-BROWSER-APP-1 |
| Priority | NEXT |
| Repos | bolt-daemon, bolt-core-sdk, bolt-ecosystem |
| Phases | 5 (WT1–WT5) |
| ACs | 20 (AC-WT-01–20) |
| PM Decisions | 5 (PM-WT-01–05) |
| Risks | 5 (WT-R1–R5) |
| Guardrails | 8 (WT-G1–G8) |
| Relationship | EXTENDS RUSTIFY-CORE-1 (complete) |
| Status | CODIFIED (WT1 unblocked) |

---

## 2. Transport Matrix (Post-Adoption)

| Endpoint Pair | Primary | Fallback 1 | Fallback 2 |
|--------------|---------|------------|------------|
| browser↔app | WebTransport | WS-direct (RC5) | WebRTC (baseline) |
| browser↔browser | WebRTC (G1) | — | — |
| app↔app | QUIC/quinn (RC3) | DataChannel | — |

---

## 3. Phase Table

| Phase | Description | Status |
|-------|-------------|--------|
| WT1 | Policy + browser support matrix | NOT-STARTED |
| WT2 | Daemon endpoint + TLS policy | NOT-STARTED |
| WT3 | Browser adapter + fallback orchestration | NOT-STARTED |
| WT4 | Conformance + rollout/rollback | NOT-STARTED |
| WT5 | Closure + WS disposition | NOT-STARTED |

---

## 4. Acceptance Criteria

| AC | Description | Phase |
|----|-------------|-------|
| AC-WT-01 | Browser support matrix finalized | WT1 |
| AC-WT-02 | Capability string defined | WT1 |
| AC-WT-03 | Three-tier fallback policy codified | WT1 |
| AC-WT-04 | TLS requirement + cert strategy options | WT1 |
| AC-WT-05 | Daemon endpoint contract | WT2 |
| AC-WT-06 | Auth/origin validation policy | WT2 |
| AC-WT-07 | TLS cert provisioning locked | WT2 |
| AC-WT-08 | Feature-gated endpoint | WT2 |
| AC-WT-09 | Browser adapter contract | WT3 |
| AC-WT-10 | Fallback orchestrator contract | WT3 |
| AC-WT-11 | BTR transparency verified | WT3 |
| AC-WT-12 | DataTransport interface compatibility | WT3 |
| AC-WT-13 | Compatibility matrix verified | WT4 |
| AC-WT-14 | Rollout policy codified | WT4 |
| AC-WT-15 | Rollback levers documented | WT4 |
| AC-WT-16 | Performance SLO thresholds | WT4 |
| AC-WT-17 | Closure criteria met | WT5 |
| AC-WT-18 | WS disposition decided | WT5 |
| AC-WT-19 | WebRTC fallback role confirmed | WT5 |
| AC-WT-20 | Migration documentation published | WT5 |

---

## 5. PM Decisions

| ID | Decision | Phase | Status |
|----|----------|-------|--------|
| PM-WT-01 | Browser support matrix (Safari) | WT1 | PENDING |
| PM-WT-02 | Capability string naming | WT1 | PENDING |
| PM-WT-03 | TLS cert provisioning strategy | WT2 | PENDING |
| PM-WT-04 | Performance SLO thresholds | WT4 | PENDING |
| PM-WT-05 | WS disposition post-adoption | WT5 | PENDING |

---

## 6. Risk Register

| ID | Risk | Severity |
|----|------|----------|
| WT-R1 | Safari WebTransport support | HIGH |
| WT-R2 | TLS cert management complexity | HIGH |
| WT-R3 | WebTransport API instability | MEDIUM |
| WT-R4 | Three-tier fallback latency | MEDIUM |
| WT-R5 | UDP firewall blocking | MEDIUM |

---

## 7. Historical Context

WebTransport was rejected for RUSTIFY-CORE-1 RC5 as PM-RC-02 Option C (2026-03-14): "Safari unsupported, experimental API, unnecessary scope risk." This stream re-evaluates with WS and WebRTC as explicit fallback tiers, ensuring no browser is left without a working transport path.

---

## 8. Guardrail Summary

| ID | Guardrail |
|----|-----------|
| WT-G1 | browser↔browser retains WebRTC (G1 invariant) |
| WT-G2 | WS-direct retained as fallback |
| WT-G3 | WebRTC retained as fallback |
| WT-G4 | Session/protocol authority in daemon/shared core |
| WT-G5 | No protocol semantic changes |
| WT-G6 | Daemon must serve TLS for WebTransport |
| WT-G7 | Browser support gating required |
| WT-G8 | Kill-switch rollback at every phase |

---

## 9. Files Changed

| File | Change |
|------|--------|
| `docs/GOVERNANCE_WORKSTREAMS.md` | New WEBTRANSPORT-BROWSER-APP-1 stream section + tag naming + summary table |
| `docs/FORWARD_BACKLOG.md` | New Item 17 + priority matrix + routing table + PM decisions |
| `docs/STATE.md` | Header + new stream row in backlog table |
| `docs/CHANGELOG.md` | New codification entry |
| `docs/evidence/WEBTRANSPORT1_CODIFY_EVIDENCE.md` | This evidence archive (new) |

---

## 10. Existing RC5/RC6 Impact

Zero. No existing completed RC tags or statuses modified. WEBTRANSPORT-BROWSER-APP-1 EXTENDS RUSTIFY-CORE-1; it does not alter it.
