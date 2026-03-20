# PF1 Evidence — Performance Audit + Bottleneck Model

**Stream:** LOCALBOLT-PERF-1
**Phase:** PF1 — Performance audit + bottleneck model
**Date:** 2026-03-20
**Tag:** `ecosystem-v0.1.187-localbolt-perf1-pf1-audit`
**Type:** Audit (read-only code analysis, no runtime changes)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-PF-01 | Baseline measurement approach defined | **PASS** — LAN-only measurement matrix defined: 3 file sizes (1/10/50 MiB), Chrome→Chrome primary, Chrome→Firefox secondary. Actual measurement is PF2 scope. |
| AC-PF-02 | Bottleneck model identified | **PASS** — 6 hypotheses ranked by code-audit confidence. Per-chunk pipeline traced end-to-end with exact files/lines. |
| AC-PF-03 | Prioritized improvement targets | **PASS** — 4 targets ranked by hypothesis confidence. All labeled as unverified pending PF2 measurement. |

---

## Bottleneck Model

### Per-Chunk Pipeline (Send Side)

```
file.slice(16KB) → arrayBuffer()           [File API, ~0.1ms]
  → Uint8Array(16384)
  → BTR sealChunk()                          [payload encrypt — NaCl secretbox]
  → toBase64(sealed)                          [base64 encode]
  → FileChunkMessage{chunk, metadata}
  → JSON.stringify(inner)                     [inner JSON]
  → TextEncoder.encode()
  → sealBoxPayload(innerBytes)               [ENVELOPE encrypt — NaCl box]
  → ProfileEnvelopeV1{payload: base64}
  → JSON.stringify(envelope)                  [outer JSON]
  → dc.send(jsonString)                      [~22KB wire for 16KB plaintext]
  → await backpressureDrain()                [0ms–5000ms]
```

**Key observations (code audit, not measured):**
- 2 encryption operations per chunk (payload + envelope)
- 2 base64 encode operations per chunk
- 3 JSON.stringify operations per chunk
- ~1.37× wire expansion (16KB → ~22KB)
- 2 async/await boundaries per chunk in hot path

### Per-Chunk Pipeline (Receive Side)

```
dc.onmessage(jsonString)
  → JSON.parse(envelope)
  → openBoxPayload(payload)                  [ENVELOPE decrypt]
  → JSON.parse(inner) + TextDecoder
  → BTR openChunk() or openBoxPayload()     [payload decrypt]
  → new Blob([decrypted])
  → transfer.buffer[chunkIndex]
  → (on completion: new Blob(all), hashFile(), onReceiveFile)
```

---

## Bottleneck Hypotheses (Ranked by Confidence)

All hypotheses are based on code audit. None are measured. Impact magnitudes are unknown until PF2.

| # | Hypothesis | Confidence | Evidence Basis | Tunable? |
|---|-----------|------------|----------------|----------|
| 1 | Double encryption per chunk may add significant crypto overhead | HIGH (code audit) | 2 NaCl box operations per chunk visible in pipeline. Impact unverified. | Potentially — subject to protocol-boundary review |
| 2 | JSON+base64 wire format expansion (~1.37×) may limit throughput | HIGH (code audit) | 16KB → ~22KB observed in code. Whether binding constraint is unverified. | Potentially — binary encoding possible |
| 3 | Conservative backpressure threshold (64KB) may limit pipelining | MEDIUM (inferred) | DP-9 set 64KB. Modern browsers support higher. Impact unverified. | Yes |
| 4 | Small chunk size (16KB) may increase per-chunk overhead | MEDIUM (inferred) | More chunks = more operations. Whether larger helps is unverified. | Yes — evaluate 32KB, 64KB |
| 5 | Ordered+reliable DataChannel may cause head-of-line blocking | LOW (theoretical) | TCP-over-UDP. On LAN near-zero loss, likely not binding. | Structural |
| 6 | WASM bridge per-chunk overhead | LOW (measured baseline) | 42μs native, ~60-70μs estimated WASM. ~4ms/MiB. Unlikely bottleneck. | Not needed |

---

## Prioritized Improvement Targets (for PF3/PF4)

| Priority | Target | Hypothesis Basis | Verification Needed (PF2) |
|----------|--------|-----------------|--------------------------|
| 1 | Double encryption analysis | Code: 2 NaCl ops/chunk | Measure time in crypto vs I/O |
| 2 | Wire format analysis | Code: 1.37× expansion | Measure DC throughput vs payload size |
| 3 | Backpressure threshold | Code: 64KB fixed | Measure buffer drain frequency |
| 4 | Chunk size evaluation | Code: 16KB fixed | Measure throughput vs chunk size |

No target is labeled as a "fix" until PF2 confirms it is a binding constraint.

---

## Measurement Matrix (LAN-Only)

| Scenario | File Size | Browser Pair | Purpose |
|----------|-----------|-------------|---------|
| Small file | 1 MiB | Chrome → Chrome | Startup/handshake overhead vs transfer |
| Medium file | 10 MiB | Chrome → Chrome | Sustained throughput baseline |
| Large file | 50 MiB | Chrome → Chrome | Throughput ceiling, backpressure |
| Medium file (cross-browser) | 10 MiB | Chrome → Firefox | Browser variance |

**Scope:** Same-LAN browser-to-browser only. Cross-network and mobile are out of scope for this stream.
**Mode:** WASM authority path (production).

---

## Evidence Classification

| Category | Items |
|----------|-------|
| **Measured** | RB4 seal_chunk: 42μs native. RC3 daemon: ~15-16 MB/s localhost. |
| **Inferred** | WASM bridge ~60-70μs (native + memory copy estimate). Wire expansion 1.37× (arithmetic from code constants). |
| **Anecdotal** | "Feels slow for larger files" (user observation, unquantified). |
| **Code audit** | Pipeline model, per-chunk operation count, constant values. |

No real browser-to-browser throughput baseline exists. PF2 provides that.

---

## Existing Instrumentation (Reusable in PF2)

S2B transfer metrics (`transferMetrics.ts`): feature-gated OFF, already collects per-chunk intervals, DC buffer samples, stall events, effective throughput. Enable flag + collect data = PF2 measurement harness with minimal new code.
