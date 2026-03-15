# RUSTIFY-CORE-1 RC6 — Verification Evidence

Captured: 2026-03-14
Operator: oberfelder (local workstation)
Context: AC-RC-25..28 closure verification for RC6 DONE status.

---

## 1. PM Decisions Resolved

### PM-RC-03 — Rollout Order (APPROVED 2026-03-14)

**Decision:** App-first, browser↔app second.

| Stage | Endpoint Pair | Transport (Primary) | Transport (Fallback/Rollback) |
|-------|--------------|--------------------|-----------------------------|
| Stage 1 | app↔app | QUIC (quinn) | DataChannel via kill-switch (feature gate `transport-quic` off) |
| Stage 2 | browser↔app | WebSocket-direct | WebRTC (automatic fallback on WS failure) |

- browser↔browser remains WebRTC invariant (G1 — never changes)
- Promotion gate: burn-in with zero P0/P1 regressions (PM sets duration, recommended ≥72h)

### PM-RC-05 — Legacy TS-Path Deprecation (APPROVED 2026-03-14)

**Decision:** Deprecate-but-retain with condition-gated sunset.

| Phase | State | Description |
|-------|-------|-------------|
| Active (current) | TS paths are primary | Status quo through RC5 |
| Deprecated | TS paths retained as fallback | Kill-switch (RC-G7) active. No code removal. |
| Sunset | TS paths removed | Requires ALL of: (a) one full release cycle, (b) zero kill-switch activations, (c) zero P0/P1 regressions, (d) explicit PM sunset approval |

---

## 2. AC Summary

| AC | Status | Key Evidence |
|----|--------|-------------|
| AC-RC-25 | PASS | Two-stage rollout policy codified in GOVERNANCE_WORKSTREAMS.md § RC6. TLS/WAN production policy documented (policy-only). TS-path deprecation policy codified. |
| AC-RC-26 | PASS | Rollback triggers (RB-T1–T5), levers (RB-L1–L4), ownership (PM), SLA (≤4h/≤1h/≤72h) codified in GOVERNANCE_WORKSTREAMS.md § RC6. |
| AC-RC-27 | PASS | 7-cell compatibility matrix codified with pass criteria. Verified cells cross-reference RC3/RC5 evidence. Deferred cells (WAN) documented with rationale. |
| AC-RC-28 | PASS | No-regression baselines from RC5: 362 daemon (ws), 353 daemon (no ws), 364 browser — all zero failures. Cross-linked as sub-evidence under AC-RC-25/26/27 at every stage gate. |

---

## 3. Rollout Policy Summary

**Two stages, sequential, with burn-in promotion gates:**

1. **Stage 1 — app↔app QUIC:** Entry after RC6 policy closure + implementation readiness. Exit via burn-in (≥72h recommended, PM-set duration, zero P0/P1 regressions).
2. **Stage 2 — browser↔app WS-direct:** Entry after Stage 1 promotion + TLS cert strategy resolved (if WAN required). Exit: full rollout complete, all compatibility matrix cells verified.

**Invariant:** browser↔browser = WebRTC (G1, never staged, never changes).

---

## 4. Rollback Policy Summary

**Triggers:**
- RB-T1: Transfer failure rate >5% above baseline (P0)
- RB-T2: BTR integrity failure (P0)
- RB-T3: Connection failure rate >10% above baseline (P1)
- RB-T4: PM-directed kill-switch activation (P0/P1)
- RB-T5: Test suite regression (blocking, automatic)

**Levers:**
- RB-L1: Feature-gate `transport-quic` off (app↔app → DataChannel)
- RB-L2: WS kill-switch / force WebRTC-only (browser↔app → WebRTC)
- RB-L3: SDK version rollback (per-consumer)
- RB-L4: Full daemon version rollback (previous tag)

**Ownership:** PM decides, Engineering executes.
**SLA:** ≤4h P0 decision, ≤24h P1 decision, ≤1h execution, ≤72h RCA.

---

## 5. Compatibility Matrix Summary

| Pair | Primary | Fallback | BTR | RC6 Status |
|------|---------|----------|-----|------------|
| browser↔browser | WebRTC DC | N/A | YES | Verified (baseline) |
| app↔app (LAN) | QUIC | DataChannel | YES | Verified (RC3) |
| app↔app (WAN) | QUIC | DataChannel | YES | Deferred |
| browser→app (LAN) | WS-direct | WebRTC | YES | Verified (RC5) |
| app→browser (LAN) | WS-direct | WebRTC | YES | Verified (RC5) |
| browser↔app (WAN) | wss:// | WebRTC | YES | Deferred (TLS) |
| legacy↔new SDK | WebRTC/DC | N/A | Fail-open | Verified (BTR-5) |

---

## 6. TLS/WAN Production Policy (Document-Only)

| Environment | Protocol | Certificate Strategy |
|-------------|----------|---------------------|
| localhost | ws:// | None needed |
| LAN | ws:// acceptable | Risk accepted (LAN-only) |
| WAN | wss:// REQUIRED | Self-signed test / CA-signed production |
| HTTPS mixed-content | Blocked by browsers | Must use wss:// |

RC6 scope: policy-only. No TLS runtime implementation.

---

## 7. No-Regression Gate (AC-RC-28)

**Baseline test counts at RC5 closure:**
- Daemon (with `transport-ws`): 362 passed, 0 failed
- Daemon (without `transport-ws`): 353 passed, 0 failed
- Browser (vitest): 364 passed, 0 failed

**Gate application:** Cross-linked as mandatory sub-evidence at:
- Stage 1 → Stage 2 promotion gate (AC-RC-25)
- Rollback lever post-activation verification (AC-RC-26)
- Each compatibility matrix cell verification (AC-RC-27)

---

## 8. Cross-Doc Consistency Verification

| Document | RC6 Status | PM-RC-03 | PM-RC-05 | AC-RC-25–28 |
|----------|-----------|----------|----------|-------------|
| GOVERNANCE_WORKSTREAMS.md | DONE | APPROVED | APPROVED | All PASS |
| FORWARD_BACKLOG.md | RC6 DONE in status line | APPROVED in PM table | APPROVED in PM table | Referenced in status |
| STATE.md | Updated in header + RUSTIFY-CORE-1 row | Referenced | Referenced | AC-RC-01–28 PASS |
| CHANGELOG.md | New entry (newest first) | APPROVED with details | APPROVED with details | All 4 ACs detailed |

---

## 9. Files Changed

| File | Change |
|------|--------|
| `docs/GOVERNANCE_WORKSTREAMS.md` | RC6 phase status → DONE; AC-RC-25–28 status + full policy text; PM-RC-03/05 → APPROVED; RC-R3 mitigation updated |
| `docs/FORWARD_BACKLOG.md` | RUSTIFY-CORE-1 status line + PM decisions + AC count updated; PM table PM-RC-03/05 → APPROVED; header updated |
| `docs/STATE.md` | Header updated; RUSTIFY-CORE-1 row updated with RC6 DONE |
| `docs/CHANGELOG.md` | New RC6 DONE entry (newest first) |
| `docs/evidence/RC6_EVIDENCE.md` | New file — this evidence archive |

---

## 10. Governance Notes

- RC6 is a policy/documentation phase — no runtime code changes.
- AC-RC-28 retained per PM instruction and reconciled as cross-linked sub-evidence under AC-RC-25/26/27.
- WAN compatibility cells (app↔app WAN, browser↔app WAN) deferred to post-RC6 implementation phases.
- TLS runtime implementation deferred — RC6 codifies policy only.
- Remaining RUSTIFY-CORE-1 PM decisions: PM-RC-04 (performance SLO), PM-RC-06 (CLI trigger), PM-RC-07 (stream relationships).
- RC7 (CLI reservation) is NOT-STARTED and parallel — not gated by RC6.
