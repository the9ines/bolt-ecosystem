# BR2 Evidence — Publish-Ready SDK Release

**Stream:** RUSTIFY-BROWSER-ROLLOUT-1
**Phase:** BR2 — Publish-ready SDK release
**Date:** 2026-03-18
**Tags:** `sdk-v0.6.0`, `transport-web-v0.7.0`, `v3.0.91-br2-published-wasm-sdk`, `ecosystem-v0.1.174-rustify-browser-rollout1-br2-publish`
**Type:** Engineering (build + publish + consumer update)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-BR-04 | bolt-core published with WASM adapter exports | **PASS** — @the9ines/bolt-core@0.6.0 published to npmjs. Exports: initWasmCrypto, initWasmCryptoFromModule, getWasmCrypto, createWasmBtrEngine, createWasmSendSession. |
| AC-BR-05 | bolt-transport-web published with protocol WASM artifact + BTR factory | **PASS** — @the9ines/bolt-transport-web@0.7.0 published to npmjs. Includes: wasm/bolt_protocol_wasm* artifacts, initProtocolWasm(), createBtrAdapter(), WasmBtrTransferAdapter. |
| AC-BR-06 | localbolt-v3 lockfile updated to published versions and CI green | **PASS** — bolt-core 0.5.1→0.6.0, transport-web 0.6.7→0.7.0. npm install clean. 141/143 tests pass (2 pre-existing). Vite build succeeds with WASM code-splitting. |

---

## Implementation Summary

**Build script:** `scripts/build-wasm-protocol.sh` — builds bolt-protocol-wasm via wasm-pack, copies artifacts to `ts/bolt-transport-web/wasm/`, enforces ≤300 KiB gzipped gate. Measured: **108 KiB combined gzipped (PASS, 196 KiB headroom).**

**Init path fix:** `initProtocolWasm()` in transport-web loads embedded WASM via relative import (same pattern as policy WASM adapter). bolt-core provides `initWasmCryptoFromModule()` for the loaded module. Consumer apps call transport-web's `initProtocolWasm()`.

**Version bumps:**
- @the9ines/bolt-core: 0.5.2 → 0.6.0
- @the9ines/bolt-transport-web: 0.6.8 → 0.7.0

---

## Versions Published

| Package | Version | Registry | Verified |
|---------|---------|----------|----------|
| @the9ines/bolt-core | 0.6.0 | npmjs.org | `npm view @the9ines/bolt-core@0.6.0 version` → 0.6.0 |
| @the9ines/bolt-transport-web | 0.7.0 | npmjs.org | `npm view @the9ines/bolt-transport-web@0.7.0 version` → 0.7.0 |
| @the9ines/bolt-core | 0.6.0 | GitHub Packages | Auto-published via tag workflow |
| @the9ines/bolt-transport-web | 0.7.0 | GitHub Packages | Auto-published via tag workflow |

---

## localbolt-v3 Consumption

- package.json: bolt-core 0.5.1→0.6.0, transport-web 0.6.7→0.7.0
- main.ts: `initProtocolWasm()` from `@the9ines/bolt-transport-web` (replaces `initWasmCrypto()` from bolt-core)
- npm install: clean (0 vulnerabilities)
- WASM artifact present: `node_modules/@the9ines/bolt-transport-web/wasm/bolt_protocol_wasm_bg.wasm`
- Vite build: protocol WASM correctly code-split as `bolt_protocol_wasm-BeYM8e5v.js` (12 KiB gzip) + `bolt_protocol_wasm_bg-DzH8rtAU.wasm` (228 KiB)

---

## Validation Results

| Check | Result |
|-------|--------|
| Build script size gate | PASS (108 KiB ≤ 300 KiB) |
| bolt-core tests | 232 pass |
| bolt-transport-web tests | 375 pass |
| localbolt-v3 tests | 141/143 (2 pre-existing) |
| localbolt-v3 build | SUCCESS (Vite, WASM code-split) |
| npm registry verification | Both packages live on npmjs |
| WASM artifact in installed package | Present |
