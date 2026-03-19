# BR5 Evidence — Follow-On Consumer Rollout

**Stream:** RUSTIFY-BROWSER-ROLLOUT-1
**Phase:** BR5 — Follow-on consumer rollout
**Date:** 2026-03-19
**Tags:** `localbolt-v1.0.37-br5-wasm-init`, `localbolt-app-v1.2.26-br5-wasm-init`, `ecosystem-v0.1.177-rustify-browser-rollout1-br5-consumer-rollout`

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-BR-12 | localbolt wired with published WASM-capable SDK + protocol init | **PASS** — bolt-core@0.6.2, transport-web@0.7.2. initProtocolWasm() in main.ts. Test mock updated. 324/324 pass. |
| AC-BR-13 | localbolt-app wired with published WASM-capable SDK + protocol init | **PASS** — bolt-core@0.6.2, transport-web@0.7.2. initProtocolWasm() in main.ts. 73/74 pass (1 pre-existing header test). |
| AC-BR-14 | All touched consumer CI/tests/builds green | **PASS** — localbolt 324/324, localbolt-app 73/74 (pre-existing). Both builds succeed with WASM code-splitting. |

---

## Rollout Summary

| Consumer | SDK Versions | Init | Tests | Build | WASM Chunk |
|----------|-------------|------|-------|-------|------------|
| localbolt | bolt-core@0.6.2, transport-web@0.7.2 | initProtocolWasm() | 324/324 | SUCCESS | bolt_protocol_wasm-D4etjInJ.js |
| localbolt-app | bolt-core@0.6.2, transport-web@0.7.2 | initProtocolWasm() | 73/74 (1 pre-existing) | SUCCESS | bolt_protocol_wasm-D4etjInJ.js |

---

## Test Notes

- **localbolt:** `app.test.ts` mock needed `initProtocolWasm` + `getProtocolAuthorityMode` added to the `@the9ines/bolt-transport-web` mock. Also added microtask flush for async main.ts bootstrap. 324/324 after fix.
- **localbolt-app:** 1 pre-existing failure in `header.test.ts > computeUnifiedStatus > ready + active = HEALTHY`. Confirmed pre-existing (same 73/74 before our change). No mock changes needed.
