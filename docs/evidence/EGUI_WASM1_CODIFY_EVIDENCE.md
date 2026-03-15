# EGUI-WASM-1 — Codification Evidence

Captured: 2026-03-15
Operator: oberfelder (local workstation)
Context: Stream codification for browser UI egui WASM migration (experimental).

---

## 1. PM-EN-04 Early Resolution

**PM-EN-04 APPROVED (2026-03-15, early resolution)**

Original gate: "Whether to open EGUI-WASM-1 after EN3 results" (blocked on EGUI-NATIVE-1 EN3).

Early resolution rationale: Browser WASM egui is architecturally distinct from desktop egui (WebGL/WebGPU canvas vs native GPU backends). Independent constraints (bundle size, startup, accessibility) do not depend on desktop parity results.

Constraints applied:
- Experimental stream — ABANDON is a valid outcome
- Non-blocking to EGUI-NATIVE-1
- React/TS browser UI retained as default-safe production path
- Rollback to React/TS required at every phase

---

## 2. Stream Summary

| Property | Value |
|----------|-------|
| Stream ID | EGUI-WASM-1 |
| Priority | LATER (experimental) |
| Phases | 5 (EW1–EW5) |
| ACs | 19 (AC-EW-01–19) |
| PM Decisions | 5 (PM-EW-01–05) |
| Risks | 6 (EW-R1–R6, two HIGH) |
| Guardrails | 8 (EW-G1–G8) |
| Success Gates | 6 (SG-01–SG-06, quantitative) |
| Status | CODIFIED (EW1 unblocked) |

---

## 3. Success Gates

| Gate | Threshold |
|------|-----------|
| SG-01 Bundle size | ≤500 KiB gzipped |
| SG-02 Cold start | ≤2s median hardware |
| SG-03 Frame rate | ≥30 FPS |
| SG-04 Accessibility | WAI-ARIA equivalent |
| SG-05 Feature parity | ≥90% workflows |
| SG-06 Cross-browser | Chrome + Firefox + Edge |

All 6 must PASS for EW4 ADOPT recommendation.

---

## 4. EGUI-NATIVE-1 Impact

- PM-EN-04 status: PENDING → APPROVED (early)
- EN-NG1 note updated: "EGUI-WASM-1 scope (codified, PM-EN-04 approved early)"
- Deferred stream table: EGUI-WASM-1 row struck through, linked to codified section
- EGUI-NATIVE-1 phases/ACs: UNCHANGED
- Non-blocking: EGUI-WASM-1 runs independently of EN1–EN5

---

## 5. Files Changed

| File | Change |
|------|--------|
| `docs/GOVERNANCE_WORKSTREAMS.md` | PM-EN-04 → APPROVED; deferred table updated; new EGUI-WASM-1 section; tag naming + summary table |
| `docs/FORWARD_BACKLOG.md` | New Item 18; routing + PM tables; priority matrix |
| `docs/STATE.md` | Header + new row + EGUI-NATIVE-1 PM-EN-04 note |
| `docs/CHANGELOG.md` | New codification entry |
| `docs/evidence/EGUI_WASM1_CODIFY_EVIDENCE.md` | This file (new) |
