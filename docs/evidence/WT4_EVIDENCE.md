# WEBTRANSPORT-BROWSER-APP-1 WT4 — Verification Evidence

Captured: 2026-03-15
Operator: oberfelder (local workstation)
Context: AC-WT-13..16 closure for WT4 DONE status.

---

## 1. AC Summary

| AC | Status | Key Evidence |
|----|--------|-------------|
| AC-WT-13 | PASS | 12-cell compatibility matrix. Browser classes × tiers × gate states. 5 pass criteria. Safari fallback explicit. |
| AC-WT-14 | PASS | 3-stage rollout (canary → staged → GA). Promotion gates with SLO + burn-in. Consumer order defined. |
| AC-WT-15 | PASS | 5 triggers (RB-WT-T1–T5), 4 levers. PM ownership. SLA aligned with RC6 (≤4h/≤1h/≤72h). |
| AC-WT-16 | PASS | PM-WT-04 APPROVED (Option B): latency ≤1.5×, throughput ≥90%, connection ≥99%, fallback ≥98%, suites green. |

---

## 2. Compatibility Matrix Summary

12 cells: Chrome WT/WS/WebRTC, Firefox WT/WS/WebRTC, Edge WT, Safari WS/WebRTC (no WT), daemon-gate-off WS/WebRTC, all-off FAILED.

Pass criteria: connection, HELLO, BTR, transfer, fallback activation.

---

## 3. Rollout Stages

| Stage | Scope | Gate |
|-------|-------|------|
| Canary | Single consumer, opt-in | SLO + zero P0/P1 + fallback ≥98% |
| Staged | All consumers, opt-in | Sustained SLO |
| GA | Default-on | PM approval + continuous compliance |

---

## 4. Rollback Summary

Triggers: connection <99%, transfer >5% above baseline, fallback <98%, latency >1.5×, test regression.
Levers: RB-L5 (WT gate off), RB-L2 (WS off), SDK pin, daemon rollback.
SLA: ≤4h P0 decision, ≤1h execution, ≤72h RCA.

---

## 5. PM-WT-04 Thresholds

| Metric | Threshold |
|--------|-----------|
| Setup latency | ≤1.5× WS |
| Throughput | ≥90% WS |
| Connection | ≥99% combined |
| Fallback | ≥98% recovery |
| No-regression | All suites + WT tests green |

---

## 6. Invariants Preserved

- G1: browser↔browser = WebRTC (unchanged)
- Runtime implementation deferred
- Docs-only changes

---

## 7. Files Changed

| File | Change |
|------|--------|
| `docs/GOVERNANCE_WORKSTREAMS.md` | WT4 AC status + 4 subsections; WT5 → READY; PM-WT-04 → APPROVED |
| `docs/FORWARD_BACKLOG.md` | Status + phase table + AC count + PM table |
| `docs/STATE.md` | Header + WT row |
| `docs/CHANGELOG.md` | New WT4 DONE entry |
| `docs/evidence/WT4_EVIDENCE.md` | This file (new) |
