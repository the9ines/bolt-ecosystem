# BR3 Evidence — Observability + Fallback Telemetry

**Stream:** RUSTIFY-BROWSER-ROLLOUT-1
**Phase:** BR3 — Observability + fallback telemetry
**Date:** 2026-03-18
**Tags:** `sdk-v0.6.1`, `transport-web-v0.7.1`, `v3.0.92-br3-observability`, `ecosystem-v0.1.175-rustify-browser-rollout1-br3-observability`
**Type:** Engineering (observability + publish)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-BR-07 | Runtime log distinguishes WASM authority vs TS fallback | **PASS** — `[BOLT-WASM] Authority mode: wasm` or `[BOLT-WASM] Authority mode: ts-fallback` emitted after every init attempt. |
| AC-BR-08 | Console includes WASM load status, authority mode, fallback trigger reason | **PASS** — Success: `Protocol WASM loaded and initialized` + `Authority mode: wasm`. Failure: `Protocol WASM load failed: <reason>` + `Authority mode: ts-fallback`. |
| AC-BR-09 | No silent failures; partial/failed WASM init is visible | **PASS** — Failure always logs warning with error message + summary mode line. `not-initialized` mode queryable if init was never called. |

---

## Observability Design

**API:** `getProtocolAuthorityMode()` → `'wasm' | 'ts-fallback' | 'not-initialized'`
- Exported from both `@the9ines/bolt-core` and `@the9ines/bolt-transport-web`
- Queryable at any time, synchronous, no side effects

**Console output (lifecycle only, no hot-path logging):**

| Event | Log |
|-------|-----|
| WASM load success | `[BOLT-WASM] Protocol WASM loaded and initialized` |
| WASM adapter registered | `[BOLT-WASM] Protocol authority initialized (Rust/WASM: crypto + BTR + transfer)` |
| WASM load failure | `[BOLT-WASM] Protocol WASM load failed: <error message>` |
| Summary (always) | `[BOLT-WASM] Authority mode: <wasm|ts-fallback>` |
| BTR adapter (per session) | `[BTR_INIT] WASM-backed BTR adapter (Rust authority)` or `[BTR_INIT] TS BTR adapter (fallback)` |

---

## Authority Mode Validation

| Scenario | Mode | Console Output | Verified |
|----------|------|---------------|----------|
| WASM init succeeds | `wasm` | `Protocol WASM loaded...` + `Authority mode: wasm` | Code path + integration |
| WASM init fails (no artifact) | `ts-fallback` | `Protocol WASM load failed: ...` + `Authority mode: ts-fallback` | Node.js test (see evidence) |
| Init never called | `not-initialized` | No output | Node.js test: `getProtocolAuthorityMode()` returns `'not-initialized'` |

**Node.js validation output:**
```
Before init: not-initialized
[BOLT-WASM] Failed to initialize — falling back to TS protocol: Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'bolt-protocol-wasm'
After init (no WASM in Node): ts-fallback
```

---

## Published Versions

| Package | Version |
|---------|---------|
| @the9ines/bolt-core | 0.6.1 |
| @the9ines/bolt-transport-web | 0.7.1 |

---

## Tests

| Suite | Count | Status |
|-------|-------|--------|
| bolt-core | 232 | All pass |
| bolt-transport-web | 375 | All pass |
| localbolt-v3 | 141/143 | 2 pre-existing |
