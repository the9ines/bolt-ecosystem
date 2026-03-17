# RB1 Evidence — RUSTIFY-BROWSER-CORE-1 Policy Lock

**Stream:** RUSTIFY-BROWSER-CORE-1
**Phase:** RB1 — Policy Lock + Target Boundary
**Date:** 2026-03-17
**Tag:** `ecosystem-v0.1.166-rustify-browser-core1-rb1-policy-lock`
**Type:** PM gate (governance only, no runtime changes)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-RB-01 | WASM bundle budget locked (PM-RB-01) | **PASS** — ≤300 KiB gzipped. Exceeding fails the gate. |
| AC-RB-02 | Transport binding posture confirmed (PM-RB-02) | **PASS** — WebRTC retained, WebTransport deferred. |
| AC-RB-03 | Rollback/deprecation model confirmed (PM-RB-03) | **PASS** — Condition-gated sunset. No fixed deadline. |
| AC-RB-04 | Consumer scope confirmed (PM-RB-04) | **PASS** — localbolt-v3 first, staged rollout. |

---

## PM Decision Summary

| ID | Decision | Approved Option | Rationale |
|----|----------|----------------|-----------|
| PM-RB-01 | WASM bundle budget | **≤300 KiB gzipped** | Protocol-only (no UI/font/GL). Existing policy WASM is 9 KiB gzipped. Full crypto + BTR + transfer may reach 100–300 KiB. 300 KiB gives headroom without being permissive. Exceeding the budget **fails the gate** and requires explicit PM disposition — not an automatic reassessment path. |
| PM-RB-02 | Transport binding posture | **WebRTC retained, WebTransport deferred** | Focused scope. WebTransport governed by WEBTRANSPORT-BROWSER-APP-1 (separate complete stream). Mixing transport migration with authority migration doubles risk. |
| PM-RB-03 | Rollback/deprecation model | **Condition-gated sunset** | Dual-path (WASM + TS) until explicit PM approval for TS protocol removal. Matches PM-RC-05 and PM-EN-03 patterns. Removal happens when evidence says it is safe, not on a calendar. |
| PM-RB-04 | Consumer scope | **localbolt-v3 first, staged** | localbolt-v3 has strongest test coverage (RECON-XFER-1 hardening). Proves viability before extending to localbolt and localbolt-app. Lower blast radius. |
| PM-RB-05 | ARCH-WASM1 disposition | **Formally superseded** | ARCH-WASM1 was a placeholder with no codified phases, ACs, or PM decisions. RUSTIFY-BROWSER-CORE-1 is the concrete execution. Retaining ARCH-WASM1 creates governance confusion. |

---

## Existing Constraints That Informed Decisions

- **PM-RC-05** (RUSTIFY-CORE-1): Established condition-gated sunset pattern for TS paths
- **PM-EN-03** (EGUI-NATIVE-1): Same pattern for legacy Tauri WebView
- **WEBTRANSPORT-BROWSER-APP-1** (COMPLETE): Already governs browser transport evolution
- **EGUI-WASM-1** (ABANDONED): Proved UI WASM is too large (1.3 MiB); protocol-only WASM is structurally different
- **T-STREAM-1** (DONE): Existing policy WASM module (9 KiB gzipped) demonstrates viable protocol-only WASM

---

## RUSTIFY-CORE-1 Status Confirmation

RUSTIFY-CORE-1 remains **COMPLETE** (RC1–RC7 all DONE, all 33 ACs PASS, all 8 PM decisions APPROVED). RUSTIFY-BROWSER-CORE-1 is a follow-on stream for browser runtime authority — not a correction, failure indication, or retroactive negation of RUSTIFY-CORE-1 completion.

---

## Verification

- **Runtime files changed:** NONE
- **Docs files changed:** GOVERNANCE_WORKSTREAMS.md, FORWARD_BACKLOG.md, STATE.md, CHANGELOG.md, evidence/RB1_EVIDENCE.md (new)
- **RUSTIFY-CORE-1 status:** Unchanged (COMPLETE)
- **ARCH-WASM1 status:** Updated to SUPERSEDED consistently in GOVERNANCE_WORKSTREAMS.md, FORWARD_BACKLOG.md, STATE.md
- **Cross-doc consistency:** All three authoritative docs agree on RB1 DONE, PM-RB-01–05 APPROVED, RB2 READY
