# PF6 Evidence — Validation + Stream Closure

**Stream:** LOCALBOLT-PERF-1
**Phase:** PF6 — Validation + closure
**Date:** 2026-03-20
**Type:** PM gate (validation of PF1–PF5 evidence, stream closure)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-PF-15 | Before/after throughput comparison recorded with evidence | **PASS** — 18 measured runs (9 baseline + 9 tuned) across 3 file sizes on the tested path. Baseline: ~33–38 Mbps. Tuned: ~47 Mbps. Full data in `PF2_EVIDENCE.md` and `PF3_PF4_EVIDENCE.md`. |
| AC-PF-16 | No regression in existing test suites | **PASS** — bolt-core 232/232, bolt-transport-web 375/375, localbolt-v3 141/143 (2 pre-existing FAQ jsdom failures, unrelated to this stream). No test regressions introduced by any phase. |
| AC-PF-17 | Stream closure criteria met | **PASS** — All required stream closure criteria are satisfied. All serial-gate phases complete (PF1→PF2→PF3/PF4→PF6). PF5 executed as ceiling assessment; AC-PF-14 was conditional and recorded as N/A because no alternative browser↔browser transport existed to compare. |

---

## Tested Path

All measurements in this stream used the same tested product path:

- Sender: Chrome on Mac Studio (macOS)
- Receiver: Safari/WebKit on iPhone 15 Pro (iOS)
- Network: Same LAN (Wi-Fi)
- Protocol authority: WASM (bolt-protocol-wasm)

No cross-browser, cross-network, or alternative transport data was collected.

---

## Before/After Summary

| File Size | PF2 Baseline (Mbps) | PF3/PF4 Tuned (Mbps) | Improvement |
|-----------|---------------------|----------------------|-------------|
| 1 MiB | 30.5 | 38.5 | +26% |
| 10 MiB | 38.4 | 45.6 | +19% |
| 50 MiB | 33.0 | 46.8 | +42% |

**Baseline steady-state:** ~33–38 Mbps on the tested path.
**Tuned steady-state:** ~47 Mbps on the tested path.

### What Changed

| Parameter | Before | After |
|-----------|--------|-------|
| DEFAULT_CHUNK_SIZE | 16 KB | 64 KB |
| bufferedAmountLowThreshold | 64 KB | 256 KB |
| maxInFlightBytes | 64 KB | 256 KB |
| transportMaxMessageSize | 64 KB | 256 KB |

### Reproducibility

All runs passed the 30% range/mean reproducibility threshold. The tuned 50 MiB configuration showed notably tight clustering (4% range/mean vs 20% at baseline).

---

## Phase-by-Phase Validation

| Phase | Evidence Doc | Key Deliverable |
|-------|-------------|-----------------|
| PF1 | `PF1_EVIDENCE.md` | 6 bottleneck hypotheses, per-chunk pipeline model, measurement plan. All labeled as unverified pending measurement. |
| PF2 | `PF2_EVIDENCE.md` | Baseline: ~33–38 Mbps sustained. 9 runs, 3 file sizes. S2B metrics instrumentation deployed and collecting. |
| PF3 | `PF3_PF4_EVIDENCE.md` | Tuning implemented and measured. ~47 Mbps sustained (+42% at 50 MiB). |
| PF4 | `PF3_PF4_EVIDENCE.md` | 64KB chunks, 256KB threshold. Evaluated against PF2 data showing prior threshold never saturated. |
| PF5 | `PF5_EVIDENCE.md` | Measured convergence suggests a plausible practical ceiling on the tested route. Remaining credible headroom in protocol-level changes. No alternative transport comparison (N/A). |

---

## Regression Summary

| Suite | Count | Status | Notes |
|-------|-------|--------|-------|
| bolt-core | 232/232 | All pass | Constant assertion updated for 64KB chunk size |
| bolt-transport-web | 375/375 | All pass | No regressions from tuning changes |
| localbolt-v3 | 141/143 | 2 pre-existing | FAQ jsdom failures, unrelated to this stream |

No test regressions were introduced by any LOCALBOLT-PERF-1 phase.

---

## What This Stream Proved

1. The real shipped browser↔browser product path was measured with reproducible instrumentation.
2. Targeted parameter tuning (chunk size, backpressure threshold) materially improved sustained throughput from ~33–38 Mbps to ~47 Mbps on the tested path.
3. The largest improvement was at 50 MiB (+42%), where reduced chunk count had the greatest cumulative effect.
4. Convergence analysis suggests the tuned path is approaching a plausible practical ceiling on the tested route for parameter-level tuning.

## What This Stream Did Not Prove

1. No universal browser or network performance conclusion. Results are specific to Chrome Mac Studio → Safari/WebKit iPhone 15 Pro, same-LAN Wi-Fi.
2. No alternative transport comparison. No browser↔browser WebTransport or other transport implementation exists to compare against.
3. PF1 hypotheses H1 (double encryption overhead) and H2 (binary wire format) were not targeted. Credible headroom remains in protocol-level changes that would require dedicated implementation streams.

---

## Stream Closure

**LOCALBOLT-PERF-1 CLOSED.**

Measured the real shipped browser↔browser product path, established a reproducible baseline (~33–38 Mbps), implemented targeted tuning (64KB chunks, 256KB backpressure threshold), and measured a sustained improvement to ~47 Mbps (+42% at 50 MiB) on the tested path. Convergence analysis suggests this represents a plausible practical ceiling on the tested route for parameter-level tuning. Remaining credible headroom exists in protocol-level changes (double encryption, binary wire format) that would require dedicated implementation streams.

---

## PM Decisions (Final State)

| ID | Decision | Status |
|----|----------|--------|
| PM-PF-01 | Whether PF5 comparative transport executes | **Executed as ceiling assessment.** Transport comparison component N/A — no alternative transport available. |
| PM-PF-02 | Throughput improvement target after baseline | **Addressed implicitly.** No explicit numeric target set; stream measured and improved the path, then assessed the ceiling. |

---

## Published Packages (Stream Total)

| Package | Baseline Version | Final Version |
|---------|-----------------|---------------|
| @the9ines/bolt-core | 0.6.2 | 0.6.3 |
| @the9ines/bolt-transport-web | 0.7.5 | 0.7.6 |

---

## Tags (Stream Total)

| Tag | Repo | Phase |
|-----|------|-------|
| `ecosystem-v0.1.186-localbolt-perf1-codify` | bolt-ecosystem | Stream codification |
| `ecosystem-v0.1.187-localbolt-perf1-pf1-audit` | bolt-ecosystem | PF1 |
| `ecosystem-v0.1.188-localbolt-perf1-pf2-instrumentation` | bolt-ecosystem | PF2 instrumentation |
| `ecosystem-v0.1.189-localbolt-perf1-pf2-baseline` | bolt-ecosystem | PF2 baseline |
| `ecosystem-v0.1.190-pf2-evidence-fix` | bolt-ecosystem | PF2 evidence correction |
| `ecosystem-v0.1.191-localbolt-perf1-pf3-pf4-tuned` | bolt-ecosystem | PF3/PF4 |
| `ecosystem-v0.1.192-localbolt-perf1-pf5-ceiling` | bolt-ecosystem | PF5 |
| `v3.0.99-pf2-transfer-metrics` | localbolt-v3 | PF2 |
| `v3.0.100-pf3-pf4-perf-tuning` | localbolt-v3 | PF3/PF4 |
| `sdk-v0.6.19-perf-chunk64k-bp256k` | bolt-core-sdk | PF3/PF4 |
