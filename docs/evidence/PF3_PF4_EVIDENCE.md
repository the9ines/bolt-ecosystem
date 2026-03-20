# PF3/PF4 Evidence — Throughput Tuning + Chunking/Backpressure

**Stream:** LOCALBOLT-PERF-1
**Phase:** PF3 — Browser/browser throughput tuning, PF4 — Chunking/buffering/backpressure tuning
**Date:** 2026-03-20
**Type:** Engineering (tuning + measurement)

---

## AC-by-AC Status

### PF3 — Throughput Tuning

| AC | Criterion | Status |
|----|-----------|--------|
| AC-PF-07 | Identified throughput improvements implemented | **PASS** — Chunk size increased from 16KB to 64KB (4x fewer chunks). Backpressure threshold raised from 64KB to 256KB. Published as bolt-core@0.6.3, bolt-transport-web@0.7.6. |
| AC-PF-08 | Post-tuning throughput measured and compared to baseline | **PASS** — 9 runs across 3 file sizes on same test path as PF2 baseline. Sustained throughput improved from ~33 Mbps to ~47 Mbps on the tested path (+42% at 50 MiB). See before/after table below. |
| AC-PF-09 | No regression in transfer correctness (hash integrity, BTR parity) | **PASS** — All 9 measured transfers completed successfully on the tested path, and no correctness regressions were detected in the measured runs. Existing automated suites remain green: bolt-transport-web 375/375, bolt-core 232/232. |

### PF4 — Chunking/Buffering/Backpressure

| AC | Criterion | Status |
|----|-----------|--------|
| AC-PF-10 | Chunk size evaluated against DataChannel MTU and observed performance | **PASS** — 16KB→64KB evaluated and measured. 4x fewer chunks per transfer. Throughput improved 19–42% across file sizes on the tested path. |
| AC-PF-11 | Backpressure thresholds validated (DP-9 64KB) | **PASS** — PF2 baseline showed max buffered ~59KB with zero stalls, meaning the 64KB threshold was never saturated. Raised to 256KB to allow more data in flight. |
| AC-PF-12 | Buffer management optimized if bottleneck identified | **PASS** — maxInFlightBytes and transportMaxMessageSize raised from 64KB to 256KB. Combined with chunk size increase, sustained throughput ceiling rose from ~33 Mbps to ~47 Mbps on the tested path. |

---

## What Changed

| Parameter | Before (PF2) | After (PF3/PF4) | Rationale |
|-----------|-------------|-----------------|-----------|
| DEFAULT_CHUNK_SIZE | 16,384 (16 KB) | 65,536 (64 KB) | 4x fewer chunks = fewer SCTP messages, fewer encrypt/encode ops |
| bufferedAmountLowThreshold | 65,536 (64 KB) | 262,144 (256 KB) | PF2 showed threshold never saturated; allow more in-flight data |
| maxInFlightBytes | 65,536 (64 KB) | 262,144 (256 KB) | Match raised threshold |
| transportMaxMessageSize | 65,536 (64 KB) | 262,144 (256 KB) | Match raised threshold |

**Packages published:** bolt-core@0.6.3, bolt-transport-web@0.7.6
**SDK tag:** `sdk-v0.6.19-perf-chunk64k-bp256k` @ `db02a9c`
**Consumer tag:** `v3.0.100-pf3-pf4-perf-tuning` @ `4aadbc5`

---

## Test Environment

- Sender: Chrome on Mac Studio (macOS)
- Receiver: Safari/WebKit on iPhone 15 Pro (iOS)
- Network: Same LAN (Wi-Fi)
- Protocol authority: WASM (bolt-protocol-wasm)
- Packages: bolt-core@0.6.3, bolt-transport-web@0.7.6

This is the same tested product path as the PF2 baseline. No same-run cross-browser or cross-network comparison was collected.

---

## Tuned Measurement Results

### 1 MiB (3 runs)

| Run | Throughput (Mbps) |
|-----|-------------------|
| 1 | 36.0 |
| 2 | 34.4 |
| 3 | 45.1 |

**Mean:** 38.5 Mbps | **Range:** 34.4–45.1 Mbps

### 10 MiB (3 runs)

| Run | Throughput (Mbps) |
|-----|-------------------|
| 1 | 41.8 |
| 2 | 47.1 |
| 3 | 48.0 |

**Mean:** 45.6 Mbps | **Range:** 41.8–48.0 Mbps

### 50 MiB (3 runs)

| Run | Throughput (Mbps) |
|-----|-------------------|
| 1 | 47.0 |
| 2 | 45.7 |
| 3 | 47.6 |

**Mean:** 46.8 Mbps | **Range:** 45.7–47.6 Mbps

---

## Before/After Comparison

| File Size | PF2 Baseline (Mbps) | Tuned (Mbps) | Improvement | Baseline Range/Mean | Tuned Range/Mean |
|-----------|---------------------|-------------|-------------|--------------------|--------------------|
| 1 MiB | 30.5 | 38.5 | **+26%** | 26% (warm) | 28% |
| 10 MiB | 38.4 | 45.6 | **+19%** | 23% | 14% |
| 50 MiB | 33.0 | 46.8 | **+42%** | 20% | 4% |

**Sustained throughput ceiling improved from ~33 Mbps to ~47 Mbps on the tested path.**

The largest improvement is at 50 MiB (+42%), where the chunk count reduction has the greatest cumulative effect (3,200 chunks → 800 chunks). Reproducibility also improved substantially at 50 MiB (range/mean dropped from 20% to 4%).

---

## Reproducibility Assessment (30% rule)

| File Size | Mean | Range | Range/Mean | Pass? |
|-----------|------|-------|------------|-------|
| 1 MiB | 38.5 | 10.7 | 28% | PASS |
| 10 MiB | 45.6 | 6.2 | 14% | PASS |
| 50 MiB | 46.8 | 1.9 | 4% | PASS |

All file sizes pass the 30% reproducibility threshold.

---

## What This Data Proves

1. **Sustained throughput improved materially** on the tested path (Chrome Mac Studio → Safari iPhone 15 Pro, same-LAN Wi-Fi).
2. **Higher chunk size (64KB vs 16KB) and higher in-flight ceiling (256KB vs 64KB) improved the tested path** — fewer SCTP messages and more data in flight are measurably beneficial.
3. **Reproducibility improved**, especially at 50 MiB (4% range/mean vs 20% baseline).

## What This Data Does Not Prove

1. **No general claim across all browsers/devices.** Only Chrome→Safari on the tested hardware was measured.
2. **No proof on binary wire format (H2) or crypto-envelope optimization (H1).** These PF1 hypotheses were not targeted by this tuning pass.
3. **No transport comparison (H5).** Ordered vs unordered DataChannel not evaluated.
4. **No cross-network data.** LAN only.
5. **No isolated measurement of which change contributed more** (chunk size vs backpressure threshold). Both changed simultaneously.

---

## Tests

| Suite | Count | Status |
|-------|-------|--------|
| bolt-core | 232/232 | All pass |
| bolt-transport-web | 375/375 | All pass |
| localbolt-v3 | 141/143 | 2 pre-existing (FAQ jsdom) |
