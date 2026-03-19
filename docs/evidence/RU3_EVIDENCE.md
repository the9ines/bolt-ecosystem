# RU3 Evidence — Error / Failure / Retry UX

**Stream:** LOCALBOLT-RELIABILITY-UX-1
**Phase:** RU3 — Error/failure/retry UX
**Date:** 2026-03-19
**Tags:** `v3.0.96-ru3-error-ux`, `ecosystem-v0.1.182-localbolt-reliability-ux1-ru3-error-ux`

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-RU-06 | Error toasts include actionable context | **PASS** — `errorDetail` field added to TransferProgress. `classifyTransferError()` maps errors to user-meaningful reasons. Consumer toasts show classified reason. |
| AC-RU-07 | Retry count is contextualized | **PASS** — "Retries: 3/5" → "Auto-retrying (3/5) — normal on slower connections." |
| AC-RU-08 | Connection timeout produces a clear message, not a hang | **PASS** — Two distinct moments: "Still connecting..." after 10s (intermediate), "Connection Timed Out — the other device may be unreachable" on failure. |

---

## User-Visible Error/Failure/Retry Changes

| Scenario | Before | After |
|----------|--------|-------|
| **Encryption error** | "Transfer Error: The transfer was terminated due to an error" | "Transfer Error: Encryption error — please reconnect and try again" |
| **Integrity failure** | Same generic | "Transfer Error: File verification failed — data may be corrupted" |
| **Transfer timeout** | Same generic | "Transfer Error: Transfer timed out — connection may be too slow" |
| **Connection lost** | Same generic | "Transfer Error: Connection lost during transfer" |
| **Generic failure** | Same generic | "Transfer Error: Transfer failed — please try again" |
| **Connection timeout** | "Connection Failed: Unable to connect to peer" | "Connection Timed Out: The other device may be unreachable. Check that both devices are on the same network and try again." |
| **Slow connection (10s)** | Same "Establishing..." text | "Still connecting to [device]... This is taking longer than usual" |
| **Retry count** | "Retries: 3/5" (alarming) | "Auto-retrying (3/5) — normal on slower connections" |

---

## Tests

| Suite | Count | Status |
|-------|-------|--------|
| bolt-transport-web | 375/375 | All pass |
| localbolt-v3 | 141/143 | 2 pre-existing |
