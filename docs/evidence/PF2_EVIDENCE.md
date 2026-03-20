# PF2 Evidence — Instrumentation + Baseline Measurement Harness

**Stream:** LOCALBOLT-PERF-1
**Phase:** PF2 — Instrumentation + measurement harness
**Date:** 2026-03-20
**Tags:** `v3.0.99-pf2-transfer-metrics`, `ecosystem-v0.1.188-localbolt-perf1-pf2-instrumentation`
**Type:** Engineering (instrumentation + measurement)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-PF-04 | S2B transfer metrics enabled and collecting in dev/test | **PASS** — `setTransferMetricsEnabled(true)` called at startup in localbolt-v3. Function exported from bolt-transport-web. `[TRANSFER_METRICS]` JSON logged on every transfer completion. |
| AC-PF-05 | Per-phase timing instrumentation sufficient for bottleneck assessment | **PASS** — Existing S2B summary provides: total time, time-to-first-chunk, median/p95 chunk interval, max buffered amount, stall count/duration, effective throughput (Mbps). Sufficient to identify which PF1 hypotheses are binding constraints. |
| AC-PF-06 | Measurement harness produces reproducible baseline results | **IN-PROGRESS** — Harness is deployed and logging. Actual LAN baseline measurement runs have not been executed yet. This requires two physical devices on the same network transferring test files and capturing console output. |

---

## Instrumentation Summary

**What was done:**
- Exported `setTransferMetricsEnabled` from `@the9ines/bolt-transport-web` (1 line)
- Enabled metrics in localbolt-v3 `main.ts` (1 line)
- No new framework — reuses existing S2B infrastructure exactly

**What is now logged per transfer:**

```json
{
  "transferId": "a1b2c3...",
  "fileSizeBytes": 10485760,
  "chunksTotal": 640,
  "totalTimeMs": 3200,
  "timeToFirstChunkMs": 12,
  "timeToFirstProgressMs": 45,
  "medianChunkIntervalMs": 4,
  "p95ChunkIntervalMs": 18,
  "maxBufferedAmount": 131072,
  "stallCount": 0,
  "totalStallTimeMs": 0,
  "effectiveThroughputMbps": 26.2,
  "tailWindowSize": 500
}
```

---

## Baseline Measurement Plan (for AC-PF-06 completion)

| File Size | Browser Pair | Runs | Purpose |
|-----------|-------------|------|---------|
| 1 MiB | Chrome → Chrome | 3 | Startup overhead |
| 10 MiB | Chrome → Chrome | 3 | Sustained throughput |
| 50 MiB | Chrome → Chrome | 3 | Throughput ceiling |
| 10 MiB | Chrome → Firefox | 3 | Browser variance |

**Reproducibility rule:** 3 runs per scenario. Report mean ± range. Range >30% of mean requires investigation.

**Execution status:** Instrumentation deployed. Measurement runs pending on physical same-LAN devices.

---

## Tests

| Suite | Count | Status |
|-------|-------|--------|
| bolt-transport-web | 375/375 | All pass |
| localbolt-v3 | 141/143 | 2 pre-existing |
