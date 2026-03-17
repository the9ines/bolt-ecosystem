# EW1 Evidence — EGUI-WASM-1 Feasibility Assessment

**Stream:** EGUI-WASM-1
**Phase:** EW1 — Feasibility + Success Gate Definition Lock
**Date:** 2026-03-16
**Tag:** `ecosystem-v0.1.163-egui-wasm1-ew1-feasibility`
**Type:** PM/Spec gate (governance + technical assessment, no runtime changes)

---

## AC-by-AC Status

| AC | Criterion | Disposition |
|----|-----------|------------|
| AC-EW-01 | egui WASM compilation feasibility confirmed | **PASS (conditional).** eframe 0.33 supports `wasm32-unknown-unknown` via `web` feature. bolt-core already ships a 20 KiB WASM module (`bolt_transfer_policy_wasm_bg.wasm`). However, bolt-ui's desktop runtime (daemon spawning via `std::process::Command`, Unix socket IPC, `/tmp` filesystem paths — 27% of codebase) is structurally incompatible with WASM. Compilation of a browser egui shell is feasible; reuse of bolt-ui's desktop runtime is not. The shared surface is presentation/state/core only. |
| AC-EW-02 | Success gates locked with quantitative thresholds | **PASS.** SG-01–SG-06 codified in governance spec (GOVERNANCE_WORKSTREAMS.md). Thresholds retained. PM-EW-01 (bundle size budget) deferred to EW2 measurement — the ≤500 KiB threshold is retained but final resolution depends on EW2 actuals. |
| AC-EW-03 | Browser rendering backend options evaluated | **PASS.** WebGL2 is the viable default (wide browser support: Chrome, Firefox, Edge, Safari). WebGPU available on Chrome/Edge but not Firefox stable as of 2026-03. eframe's `web` feature uses wgpu which auto-selects best available backend. No explicit backend decision needed at EW1; EW2 PoC will use WebGL2 as baseline. |
| AC-EW-04 | Accessibility risk assessment documented | **PASS (HIGH risk documented).** egui renders to `<canvas>`, producing no semantic HTML. Current web UI has native DOM accessibility: semantic elements (`<header>`, `<section>`, `<footer>`, `<button>`), ARIA labels on 8 elements, native keyboard navigation. Canvas-based rendering loses all of this. No production-ready ARIA overlay exists in the egui ecosystem. SG-04 (accessibility) is the hardest success gate and the most likely kill criterion. |

---

## Feasibility Assessment Summary

### Overall Finding: Negative on Structural Grounds

The feasibility case for EGUI-WASM-1 is negative when evaluated as "port bolt-ui desktop runtime to browser." It is potentially viable when evaluated as "browser egui shell sharing presentation/state/core with desktop."

### Bundle Size (SG-01)

| Component | Current (TS/Vanilla) | Estimated (egui WASM) |
|-----------|---------------------|----------------------|
| Application JS | 40 KiB gzip | N/A (replaced by WASM) |
| WASM binary | 20 KiB | ~300–500 KiB |
| CSS | 22 KiB | ~0 (egui self-renders) |
| **Total** | **~65 KiB** | **~300–500 KiB** |
| **Regression** | — | **5–8×** |

The codified threshold (≤500 KiB) may technically pass, but a 5–8× regression from 65 KiB is a material UX degradation for a file transfer tool.

### Accessibility (SG-04)

- **Current:** Semantic HTML + ARIA labels = native screen reader support
- **egui WASM:** Canvas rendering = no semantic HTML, no native screen reader support
- **Mitigation:** No production-ready solution in egui ecosystem
- **Assessment:** Likely FAIL. This is the hardest gate.

### Architecture Compatibility

**Desktop runtime (NOT shareable with browser):**
- `daemon.rs` (353 LOC) — process spawning via `std::process::Command`
- `ipc.rs` (148 LOC) — Unix domain socket client
- Runtime env vars, filesystem paths, binary detection
- **Total: ~501 LOC (27% of bolt-ui)**

**Presentation/state/core (potentially shareable):**
- `theme.rs` (127 LOC) — colors, spacing, typography constants
- `screens/` (588 LOC) — connect, transfer, verify screen composition
- `state.rs` (174 LOC) — ConnectionState, TransferState, VerifyState enums
- `app.rs` — screen routing, view-model logic (partial, ~200 LOC after removing daemon refs)
- bolt-core consumption — peer code generation (already WASM-proven)
- **Total: ~769 LOC potentially shareable, but structural viability requires EW2 measurement**

**Key distinction:** Meaningful reuse requires that shared code actually reduces future browser-shell implementation cost — not just cosmetic constant sharing.

### Current Web UI Baseline

The current browser UI is **vanilla TypeScript** (not React), with imperative DOM manipulation:
- 2,175 LOC across 19 files
- 40 KiB gzipped JS + 22 KiB CSS + 20 KiB existing WASM = ~65 KiB total
- No framework overhead, no virtual DOM, no hydration penalty
- Already near-optimal for its feature set

### Transport Architecture

- **Desktop:** Native QUIC via quinn (RUSTIFY-CORE-1)
- **Browser:** WebTransport-class (HTTP/3, browser-mediated) — NOT native quinn compiled to WASM
- **Shared core API:** Abstracts over both transport implementations
- **EW2 scope:** No transport implementation. Shell is transport-independent.

---

## Architectural Truths (Normative)

**Truth 1: Browser does not run desktop runtime.**
No daemon spawning, no Unix sockets, no `/tmp`, no `std::process::Command`, no native process lifecycle. The browser egui shell is a new thin host that consumes shared presentation/state/core code — not a port of bolt-ui's desktop runtime.

**Truth 2: Browser QUIC means WebTransport, not native quinn.**
"QUIC in the browser" means the browser's WebTransport API (HTTP/3-class, browser-mediated). It does not mean compiling quinn to WASM or opening raw UDP sockets. Desktop may use native quinn; browser uses browser APIs.

**Truth 3: Canvas replaces DOM — accessibility is structurally worse.**
egui renders to `<canvas>`, not semantic HTML. There is no production-ready egui WASM accessibility solution. SG-04 remains the hardest gate.

---

## PM Override

**Decision:** Proceed to EW2 as tightly-bounded measurement PoC.

**Framing:** This is a taste-driven exception, not a reversal of technical concerns. The technical concerns documented above remain fully in force and govern EW2 kill criteria. ABANDON remains the default outcome if EW2 does not materially beat the expectations documented here.

**Stream posture:** Dual-UI optionality, not forced migration. If the stream proceeds past EW2, the future is an optional browser egui shell coexisting with the vanilla TS UI — neither path forced out.

**What EW2 measures:**
1. Actual gzipped WASM bundle size (kill: >500 KiB)
2. Actual cold-start/render performance (kill: >3s or <30 FPS)
3. Meaningful reusable presentation/state/core surface from bolt-ui (kill: insufficient to reduce implementation cost)
4. Subjective viability of browser-hosted egui shell (PM taste call)
5. Whether dual-UI maintenance cost is plausibly justified by user preference and shared-core reuse (kill: cost clearly exceeds benefit)

**What EW2 does NOT do:**
- No browser migration
- No consumer app integration or deployment
- No transport implementation (no WebTransport, no WebRTC, no daemon)
- No React/TS removal or modification
- No accessibility solution (assessed, not built)

---

## EW2 Kill Criteria (Explicit)

EW2 closes the stream (ABANDON) if **any** of:
1. Gzipped WASM bundle >500 KiB
2. Cold start >3s on median hardware
3. FPS <30 during UI updates
4. Reusable presentation/state/core surface insufficient to materially reduce implementation cost
5. Dual-UI maintenance cost clearly exceeds benefit of optionality + shared-core reuse
6. PM subjective assessment: "not worth pursuing"

No EW3+ unless EW2 produces unexpectedly strong evidence. The bar is "unexpectedly strong," not "marginally acceptable."

---

## Verification

- **Runtime files changed:** NONE
- **Docs files changed:** GOVERNANCE_WORKSTREAMS.md, FORWARD_BACKLOG.md, STATE.md, CHANGELOG.md, evidence/EW1_EVIDENCE.md (new)
- **Cross-doc consistency:** All three authoritative docs agree on EGUI-WASM-1 EW1 DONE, EW2 measurement PoC approved, ABANDON default
