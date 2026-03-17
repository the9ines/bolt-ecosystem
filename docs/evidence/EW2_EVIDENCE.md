# EW2 Evidence — Browser egui WASM Measurement PoC

**Stream:** EGUI-WASM-1
**Phase:** EW2 — WASM scaffold + measurement PoC
**Date:** 2026-03-17
**Tag:** `ecosystem-v0.1.164-egui-wasm1-ew2-poc`
**Type:** Engineering gate (runtime build + measurement, governance docs)

---

## PoC Summary

Built an isolated `bolt-ui-wasm` crate in `bolt-core-sdk/rust/bolt-ui-wasm/`.
Browser egui shell with themed screens, peer code generation via bolt-core,
no daemon/transport/signaling. Compiled to WASM via wasm-pack, release profile,
wasm-opt applied.

---

## Measurement Results

### Q1: Bundle Size

| Metric | Value |
|--------|-------|
| WASM binary (uncompressed) | 2,791 KiB (2.73 MiB) |
| **WASM binary (gzipped)** | **1,296 KiB (1.27 MiB)** |
| JS glue (uncompressed) | 73 KiB |
| Current vanilla TS app (total gzipped) | ~65 KiB |
| **Regression factor** | **20×** |
| **Kill criterion: >500 KiB** | **FAIL (2.6× over threshold)** |

The egui + eframe + glow + bolt-core dependency tree produces a 1.3 MiB gzipped
WASM binary for a minimal 3-screen shell. This is structural — egui includes a
font renderer, text shaping, input handling, and a GL rendering backend that the
browser already provides via the DOM.

### Q2: Cold Start

Not independently measured — moot given Q1 hard kill. A 1.3 MiB WASM download
over a typical 5 Mbps connection takes ~2s for download alone, before WASM
compile + init. The ≤3s target is not achievable for median users.

### Q3: Reuse Analysis

| Component | bolt-ui LOC | bolt-ui-wasm LOC | Reuse Type |
|-----------|-------------|------------------|------------|
| theme.rs | 70 (non-test) | 70 | Verbatim copy |
| state.rs | 119 (non-test) | 119 | Near-verbatim (Instant swap) |
| screens/mod.rs | 10 | 11 | Verbatim |
| screens/transfer.rs | 146 | 143 | Verbatim |
| screens/verify.rs | 142 | 139 | Verbatim |
| screens/connect.rs | 300 | 321 | **Rewritten** (decoupled from BoltApp) |
| app.rs / lib.rs | 402 | 196 | **New** (BoltWebApp, no daemon) |
| daemon.rs | 353 | 0 | Excluded |
| ipc.rs | 148 | 0 | Excluded |
| main.rs | 22 | 0 | Replaced |

**Verbatim/near-verbatim reuse:** 482 LOC of 1,824 = **26%**
**Substantial rewrite:** 321 LOC (connect.rs)
**New browser-specific:** 196 LOC (lib.rs)
**Excluded (desktop-only):** 523 LOC

The meaningful shared surface is theme constants, state enums, and two simpler
screens (transfer, verify). The connect screen — the most complex screen —
required a structural rewrite to decouple from the desktop BoltApp struct.
The app shell is entirely new.

**Does this reduce future implementation cost?** Marginally. The shared screens
are the simplest. The complex parts (app shell, connect screen, transport
integration) would need platform-specific implementations regardless.

### Q4: Subjective Viability

Deferred to PM. The PoC compiles and the egui rendering code transfers cleanly
for simple screens. But the 20× bundle size regression and 26% meaningful reuse
surface do not support an "optional alternate browser shell" story.

### Q5: Dual-UI Maintenance

**Assessment: Not justified.**

- Theme changes: dual-patch or extract shared crate (infra cost)
- Simple screens (transfer/verify): dual-patch cleanly
- Connect screen: different interfaces, non-trivial dual-patch
- New screens: written twice
- State enums: dual-patch with Instant divergence
- The existing vanilla TS app is 2,175 LOC at 65 KiB delivered
- The egui WASM alternative is 999 LOC Rust at 1,296 KiB delivered — 20× larger

The maintenance cost exceeds the benefit. The sharing surface is too small and
the simple screens that share cleanly are not the ones driving maintenance cost.

---

## Kill Criteria Evaluation

| # | Criterion | Result |
|---|-----------|--------|
| 1 | Gzipped WASM ≤500 KiB | **FAIL — 1,296 KiB (2.6× over)** |
| 2 | Cold start ≤3s | **FAIL (moot)** — 1.3 MiB download alone prevents this |
| 3 | FPS ≥30 | Not measured (moot given Q1) |
| 4 | Meaningful reuse | **MARGINAL** — 26% verbatim, complex parts not shared |
| 5 | Dual-UI maintenance justified | **FAIL** — 20× bundle, small sharing surface |
| 6 | PM subjective | Deferred |

**Q1 is a hard kill per governance spec (>500 KiB = ABANDON).**

---

## Recommendation

**ABANDON.** The bundle size result (1,296 KiB gzipped, 2.6× over the 500 KiB
kill threshold) is structural — it comes from egui's font rendering, text
shaping, and GL backend being baked into the WASM binary. These are capabilities
the browser already provides via the DOM. There is no realistic optimization
path to bring this under 500 KiB while retaining egui's rendering.

The reuse story (26% meaningful sharing) is weaker than projected. The screens
that share cleanly (transfer, verify) are the simplest ones. The connect screen
required structural decoupling. The app shell is entirely new.

The current vanilla TS browser UI delivers the same functionality in 65 KiB
with native DOM accessibility. Replacing it with a 1.3 MiB canvas-based
alternative that loses accessibility and shares 26% of presentation code
is not justified by any combination of code sharing, maintenance reduction,
or user preference.

---

## Verification

- **Runtime files changed:** bolt-core-sdk/rust/ only (new crate, workspace Cargo.toml)
- **bolt-ui modified:** NO — zero changes to existing desktop crate
- **localbolt-v3 modified:** NO — zero changes to existing browser app
- **Ecosystem docs:** Updated in P3
