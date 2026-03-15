# WEBTRANSPORT-BROWSER-APP-1 WT1 — Verification Evidence

Captured: 2026-03-15
Operator: oberfelder (local workstation)
Context: AC-WT-01..04 closure for WT1 DONE status.

---

## 1. AC Summary

| AC | Status | Key Evidence |
|----|--------|-------------|
| AC-WT-01 | PASS | Browser matrix: Chrome 97+, Edge 97+, Firefox 115+ = Primary. Safari = Fallback (WS→WebRTC). PM-WT-01 Option B. |
| AC-WT-02 | PASS | Capability string: `bolt.transport-webtransport-v1`. PM-WT-02 Option A. |
| AC-WT-03 | PASS | Three-tier fallback: WebTransport → WS-direct → WebRTC. 6 trigger conditions. Kill-switch at every tier. |
| AC-WT-04 | PASS | TLS mandatory for WebTransport. 4 cert strategy options (C1–C4) documented for WT2. |

---

## 2. PM Decisions

### PM-WT-01 — Browser Support (APPROVED)

Option B: Ship on supported browsers. Safari fallback.

| Browser | Support | Tier |
|---------|---------|------|
| Chrome | 97+ | Primary |
| Edge | 97+ | Primary |
| Firefox | 115+ | Primary |
| Safari | NO | Fallback (WS→WebRTC) |
| iOS Safari | NO | Fallback (WS→WebRTC) |

### PM-WT-02 — Capability String (APPROVED)

Option A: `bolt.transport-webtransport-v1`

---

## 3. Fallback Policy

WebTransport → WS-direct → WebRTC (three-tier, deterministic triggers).

G1 invariant: browser↔browser = WebRTC (unchanged).

---

## 4. Files Changed

| File | Change |
|------|--------|
| `docs/GOVERNANCE_WORKSTREAMS.md` | WT1 AC status + 4 subsections; WT2 → READY; PM-WT-01/02 → APPROVED |
| `docs/FORWARD_BACKLOG.md` | Status + phase table + AC count + PM table |
| `docs/STATE.md` | Header + WT row |
| `docs/CHANGELOG.md` | New WT1 DONE entry |
| `docs/evidence/WT1_EVIDENCE.md` | This file (new) |
