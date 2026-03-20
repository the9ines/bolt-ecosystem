# PF5 Evidence — Comparative Transport / Ceiling Assessment

**Stream:** LOCALBOLT-PERF-1
**Phase:** PF5 — Comparative transport assessment (conditional)
**Date:** 2026-03-20
**Type:** Analysis (read-only assessment of measured data, no new runtime changes)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-PF-13 | Current path throughput ceiling documented with evidence | **PASS** — Measured convergence across PF2→PF3/PF4 suggests the tuned path is approaching a plausible practical ceiling on the tested path (~47 Mbps sustained). See ceiling assessment below. |
| AC-PF-14 | If executed: alternative transport measured against same workload | **N/A — Conditional, not executed.** No browser↔browser alternative transport implementation exists in the codebase. A true comparative study would require a new implementation stream. |

---

## Tested Path

All data in this assessment comes from the same tested product path:

- Sender: Chrome on Mac Studio (macOS)
- Receiver: Safari/WebKit on iPhone 15 Pro (iOS)
- Network: Same LAN (Wi-Fi)
- Protocol authority: WASM (bolt-protocol-wasm)

No cross-browser, cross-network, or alternative-transport data was collected.

---

## Ceiling Assessment

### Measured Convergence Pattern

| File Size | PF2 Baseline (Mbps) | PF3/PF4 Tuned (Mbps) | Delta | Tuned Range/Mean |
|-----------|---------------------|----------------------|-------|------------------|
| 1 MiB | 30.5 | 38.5 | +26% | 28% |
| 10 MiB | 38.4 | 45.6 | +19% | 14% |
| 50 MiB | 33.0 | 46.8 | +42% | 4% |

### Evidence of Convergence

1. **Tight clustering at 50 MiB:** 45.7–47.6 Mbps (4% range/mean) in the tuned configuration. This tight grouping suggests the path is settling at a steady-state limit on the tested route, not fluctuating randomly.

2. **10 MiB and 50 MiB converging:** 45.6 vs 46.8 Mbps (3% gap). In the PF2 baseline, the gap between these file sizes was 16% (38.4 vs 33.0). The narrowing indicates file size no longer differentiates throughput — the bottleneck is somewhere constant, not per-chunk.

3. **Sublinear return from chunk size increase:** 4× chunk size increase (16KB→64KB) yielded 1.42× throughput improvement at 50 MiB. If chunk count were the sole constraint, the relationship would be closer to linear. The remaining constraint is elsewhere in the pipeline.

4. **Zero stalls in both configurations:** Backpressure was never the binding constraint in either the baseline or tuned runs. The threshold increase helped by allowing more pipelining, not by eliminating stalls.

### Assessment

The measured convergence suggests the tuned path is approaching a plausible practical ceiling on the tested route (Chrome Mac Studio → Safari/WebKit iPhone 15 Pro, same-LAN Wi-Fi). The steady-state throughput has converged to ~47 Mbps with tight reproducibility, and the most accessible parameter tuning (chunk size, backpressure threshold) shows diminishing returns.

This does not establish a universal WebRTC ceiling. Different hardware, browsers, or network conditions could yield different results. It characterizes the current product path on the tested route.

---

## Remaining Tunable Items (Current Path)

| # | Item | PF1 Hypothesis | Credible Headroom | Effort |
|---|------|---------------|-------------------|--------|
| A | **Double encryption** | H1 — 2 NaCl box ops per chunk | Moderate — removing envelope encryption for file-chunk messages would eliminate ~50% of crypto per chunk. Protocol-level change. | High — protocol boundary |
| B | **Binary wire format** | H2 — JSON+base64 = 1.37× expansion | Moderate — binary framing would reduce wire size by ~27%. At 47 Mbps effective, actual wire rate is ~64 Mbps (47 × 1.37). | Medium — EnvelopeCodec rewrite |
| C | **Further chunk size increase** | Extension of PF4 | Low — diminishing returns visible (4× input → 1.42× output). Risk of exceeding SCTP limits on some browsers. | Low effort, low return |
| D | **Ordered→unordered DC** | H5 — head-of-line blocking | Low on LAN — zero packet loss means ordered mode costs nothing. Relevant only on lossy networks. | Structural risk |
| E | **Further backpressure threshold increase** | Extension of PF4 | Negligible — zero stalls at 256KB. Max buffered stayed at ~59KB in PF2 baseline. | No evidence of value |

Items A and B are the only remaining tunables with credible headroom. Both require meaningful architectural work (protocol change and codec rewrite respectively). Items C, D, and E show no evidence of further return on the tested path.

---

## Transport Comparison Feasibility

### What Exists in the Codebase

| Transport | Status | Browser↔Browser File Transfer? |
|-----------|--------|-------------------------------|
| WebRTC DataChannel | Implemented, measured | **Yes** — this is the current path |
| WebSocket (WsDataTransport) | Implemented | **No** — used for daemon/relay connections, not browser↔browser file transfer |
| WebTransport over HTTP/3 | Governed in roadmap (WT-STREAM items), not implemented | **No** |
| Raw QUIC | Not possible in browser runtime | **No** — browser "QUIC" means WebTransport over HTTP/3, which requires a server endpoint and is not a peer-to-peer primitive |

### Why AC-PF-14 Is N/A

No browser↔browser alternative transport implementation exists to compare against the same workload. The WebSocket transport serves a different purpose (app↔relay). WebTransport is governed but unbuilt. A true comparative transport study would require a new implementation stream to build an alternative browser↔browser transfer path, then measure the same file sizes through it.

Fabricating a comparison from unlike transports (e.g., WebRTC DataChannel vs WebSocket relay) would not be an honest apples-to-apples assessment.

---

## Conclusion

The tuned WebRTC DataChannel path is approaching a plausible practical ceiling on the tested route at ~47 Mbps sustained. The most accessible tuning levers (chunk size, backpressure thresholds) are exhausted with diminishing returns. Remaining credible headroom exists in protocol-level changes (double encryption removal, binary wire format) that would require dedicated implementation streams.

A true transport comparison is not possible with the current codebase and would require a new implementation stream. PF5 closes as a ceiling assessment; the transport comparison component is conditional and not executed.

---

## Tests

No code changes in this phase. Test suites unchanged from PF3/PF4:

| Suite | Count | Status |
|-------|-------|--------|
| bolt-core | 232/232 | All pass |
| bolt-transport-web | 375/375 | All pass |
| localbolt-v3 | 141/143 | 2 pre-existing (FAQ jsdom) |
