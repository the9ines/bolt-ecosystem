# EN3 Docs Consistency Correction

Date: 2026-03-15
Context: Reconcile governance docs with actual EN3e delivered state.

---

## Before/After Status Table

| Item | Before (stale) | After (corrected) |
|------|---------------|-------------------|
| GOVERNANCE stream header | `sdk-v0.6.11`, AC-EN-11/12/15 PARTIAL | `sdk-v0.6.14`, AC-EN-10/12/13/14/15 PASS, AC-EN-11 PARTIAL |
| GOVERNANCE EN3 phase row | AC-EN-11 PARTIAL, AC-EN-12 PARTIAL, AC-EN-15 PARTIAL | AC-EN-12 PASS (SAS via IPC), AC-EN-15 PASS (errors surfaced), AC-EN-11 PARTIAL |
| GOVERNANCE summary table | AC-EN-11/12/15 PARTIAL (daemon IPC) | AC-EN-11 PARTIAL (daemon transfer emit points) |
| FORWARD_BACKLOG header | "feature parity wired, placeholders removed" | "IPC client + SAS verified" |
| FORWARD_BACKLOG status | `sdk-v0.6.11`, AC-EN-11/12/15 PARTIAL | `sdk-v0.6.14`, AC-EN-11 PARTIAL only |
| FORWARD_BACKLOG phase table | AC-EN-11/12/15 PARTIAL | AC-EN-11 PARTIAL only |
| FORWARD_BACKLOG AC count | "12 of 24 addressed, 3 partial" | "14 of 24 addressed, 1 partial" |
| STATE.md row | `sdk-v0.6.11`, AC-EN-11/12/15 PARTIAL | `sdk-v0.6.14`, AC-EN-11 PARTIAL only |

---

## Corrections Applied

1. **AC-EN-12 (verify/SAS):** Updated from PARTIAL to PASS. Evidence: EN3e verified real SAS code (399939) via `session.sas` IPC event. Both sides compute matching SAS.

2. **AC-EN-15 (error display):** Updated from PARTIAL to PASS. Evidence: EN3d/EN3e verified IPC connect failure, daemon exit detection, 30s timeout, cancel/retry, prerequisite error surfacing.

3. **SDK tag reference:** Updated from `sdk-v0.6.11` to `sdk-v0.6.14` (latest EN3e tag).

4. **Blocker language:** Narrowed from "daemon IPC wiring required" to "daemon transfer IPC emit points pending" (specific to AC-EN-11 only).

---

## Current Truth (all docs now consistent)

| AC | Status | Basis |
|----|--------|-------|
| AC-EN-10 | PASS | Real peer code + Host/Join + rendezvous |
| AC-EN-11 | PARTIAL | Transfer IPC types ready; daemon B3 emit points pending |
| AC-EN-12 | PASS | SAS via session.sas IPC event (EN3e) |
| AC-EN-13 | PASS | 353 daemon + 14 bolt-ui tests pass |
| AC-EN-14 | PASS | bolt-core only, zero transport deps |
| AC-EN-15 | PASS | IPC failure/timeout/cancel surfaced (EN3d/EN3e) |

EN3 status: IN-PROGRESS. Single blocker: AC-EN-11.
