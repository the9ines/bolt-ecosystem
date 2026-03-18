# BR4 Evidence — Burn-In Harness + Validation Checklist

**Stream:** RUSTIFY-BROWSER-ROLLOUT-1
**Phase:** BR4 — Burn-in harness + validation checklist
**Date:** 2026-03-18
**Tags:** `v3.0.93-br4-burn-in-checklist`, `ecosystem-v0.1.176-rustify-browser-rollout1-br4-burnin`
**Type:** Documentation (checklist + validation matrix, no runtime changes)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-BR-10 | Burn-in checklist defined | **PASS** — `localbolt-v3/docs/BURN_IN_CHECKLIST.md`: 19-point checklist (6 pre-deploy, 8 post-deploy, 5 forced fallback). Includes pass/fail disposition criteria for BR6. |
| AC-BR-11 | Manual test plan for WASM path vs fallback path | **PASS** — Validation matrix covers both paths with explicit signal references. Forced fallback section verifies TS path independently. |

---

## Burn-In Checklist Summary

**19 checks across 3 categories:**

- **Pre-deploy (6):** test suites (bolt-core, transport-web, localbolt-v3), build verification, WASM artifact presence, size gate
- **Post-deploy (8):** WASM loads in browser, authority mode confirmed, peer discovery, small/medium file transfers, BTR WASM active, cancel, disconnect/reconnect
- **Forced fallback (5):** disable WASM init, verify fallback authority mode, transfer with TS, BTR TS fallback, restore WASM

**Disposition criteria:** PASS requires all post-deploy checks green + WASM authority confirmed + at least one medium file transfer with BTR WASM.

---

## Validation Matrix

| Scenario | WASM Path Expected | TS Fallback Expected |
|----------|-------------------|---------------------|
| Authority mode query | `'wasm'` | `'ts-fallback'` / `'not-initialized'` |
| Init console log | `Authority mode: wasm` | `Protocol WASM load failed: ...` + `Authority mode: ts-fallback` |
| BTR adapter log | `WASM-backed BTR adapter` | `TS BTR adapter (fallback)` |
| File transfer | Works | Works |
| Cancel mid-transfer | Works | Works |

---

## Observable Signals Referenced

- `getProtocolAuthorityMode()` — API, returns `'wasm'` / `'ts-fallback'` / `'not-initialized'`
- `[BOLT-WASM] Authority mode: <mode>` — console, emitted at init
- `[BTR_INIT] WASM-backed BTR adapter (Rust authority)` — console, per session
- `[BTR_INIT] TS BTR adapter (fallback)` — console, per session

---

## Helper Additions

None. BR4 is docs-only. The existing `getProtocolAuthorityMode()` API and console logging (BR3) provide sufficient inspection surface.

---

## Verification

- No runtime files changed
- No protocol/behavior changes
- Checklist references actual current signals from BR3
