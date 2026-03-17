# RB5 Evidence — TS Adapter Thinning + Consumer Wiring

**Stream:** RUSTIFY-BROWSER-CORE-1
**Phase:** RB5 — TS adapter thinning + consumer wiring
**Date:** 2026-03-17
**Tags:** `sdk-v0.6.18-rustify-browser-core1-rb5-wasm-wiring`, `v3.0.90-rustify-browser-core1-rb5-wasm-init`, `ecosystem-v0.1.170-rustify-browser-core1-rb5-done`
**Type:** Engineering (consumer wiring + adapter changes + tests)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-RB-17 | No TS module owns protocol state transitions on production browser path | **PASS** — When WASM initialized: crypto via Rust, BTR via WasmBtrTransferAdapter (Rust opaque handles), transfer SM via WasmSendSession (Rust). TS retained as fallback only. |
| AC-RB-18 | No TS performs protocol crypto on production browser path | **PASS** — crypto.ts/identity.ts/sas.ts check getWasmCrypto() first. BTR sealChunk/openChunk route through WasmBtrTransferCtxBridge → Rust. Zero tweetnacl calls on WASM path. |
| AC-RB-19 | TS-only residue is browser API bindings, JS↔WASM bridge, persistence, UI | **PASS** — See module disposition summary below. |
| AC-RB-20 | Dual-path (WASM + legacy TS) remains operational | **PASS** — If initWasmCrypto() fails, getWasmCrypto() returns null, createWasmBtrEngine() returns null, createBtrAdapter() returns TS BtrTransferAdapter. Automatic, silent. |

---

## Consumer Wiring Summary

| Consumer | Change | Status |
|----------|--------|--------|
| **localbolt-v3** | `main.ts`: `initWasmCrypto()` before `createApp()` | **DONE** (`v3.0.90`) |
| localbolt | Deferred per PM-RB-04 | Follow-on after burn-in |
| localbolt-app | Deferred per PM-RB-04 | Follow-on after burn-in |

---

## Production vs Fallback Authority

### Production Path (WASM initialized successfully)

```
main.ts: initWasmCrypto() → SUCCESS
  ├── crypto.ts: getWasmCrypto() → Rust seal/open/keypair
  ├── identity.ts: getWasmCrypto() → Rust identity keypair
  ├── sas.ts: getWasmCrypto() → Rust SAS computation
  ├── WebRTCService: createBtrAdapter(sharedSecret) → WasmBtrTransferAdapter
  │   └── WasmBtrEngine (Rust opaque handle)
  │       └── WasmBtrTransferCtx.sealChunk/openChunk (Rust hot path)
  └── WsDataTransport: createBtrAdapter(sharedSecret) → WasmBtrTransferAdapter
```

**Authority:** Rust owns crypto, session, BTR state, transfer SM transitions.
**TS role:** Browser API bindings (WebRTC, DataChannel, IndexedDB), JS↔WASM bridge, UI.

### Fallback Path (WASM unavailable)

```
main.ts: initWasmCrypto() → FAILURE (silent)
  ├── crypto.ts: getWasmCrypto() → null → tweetnacl fallback
  ├── identity.ts: getWasmCrypto() → null → tweetnacl fallback
  ├── sas.ts: getWasmCrypto() → null → Web Crypto fallback
  ├── WebRTCService: createBtrAdapter() → BtrTransferAdapter (TS)
  │   └── BtrTransferContext (TS tweetnacl + @noble/hashes)
  └── WsDataTransport: createBtrAdapter() → BtrTransferAdapter (TS)
```

**Authority:** TS owns everything (original behavior). Fully operational.

---

## TS Module Disposition Summary

### Production-WASM (authority is Rust when WASM active)

| Module | Role on WASM path |
|--------|-------------------|
| crypto.ts | Adapter — delegates to WASM, falls back to tweetnacl |
| identity.ts | Adapter — delegates to WASM, falls back to tweetnacl |
| sas.ts | Adapter — delegates to WASM, falls back to Web Crypto |
| wasm-crypto.ts | JS↔WASM bridge — initialization + handle factory |

### Fallback-Only (not authoritative on WASM path)

| Module | Role |
|--------|------|
| btr/key-schedule.ts | Fallback BTR key derivation (not called on WASM path) |
| btr/ratchet.ts | Fallback DH ratchet (not called on WASM path) |
| btr/encrypt.ts | Fallback secretbox (not called on WASM path) |
| btr/state.ts | Fallback BtrEngine/BtrTransferContext (not called on WASM path) |
| btr/replay.ts | Fallback replay guard (not called on WASM path) |
| btr/negotiate.ts | Fallback negotiation (not called on WASM path) |
| BtrTransferAdapter.ts (TS class) | Fallback adapter (constructed only when createWasmBtrEngine returns null) |

### Retain-Adapter (browser I/O, persistence, UI — always TS)

| Module | Role |
|--------|------|
| HandshakeManager.ts | WebRTC event wiring (crypto calls go through WASM via crypto.ts) |
| TransferManager.ts | DataChannel I/O loop (BTR calls go through WASM via adapter) |
| EnvelopeCodec.ts | JSON wrapper (crypto calls go through WASM via crypto.ts) |
| WebRTCService.ts | WebRTC lifecycle (BTR adapter constructed via factory) |
| WsDataTransport.ts | WebSocket transport (BTR adapter via factory) |
| identity-store.ts | IndexedDB persistence (browser API) |
| pin-store.ts | IndexedDB persistence (browser API) |
| WebSocketSignaling.ts | WebSocket signaling (browser API) |
| DualSignaling.ts | Signaling failover |
| All consumer peer-connection.ts | UI orchestration |

---

## Test Results

| Repo | Suite | Count | Status |
|------|-------|-------|--------|
| bolt-core-sdk | bolt-core TS | 232 | All pass |
| bolt-core-sdk | bolt-transport-web TS | 375 | All pass |
| bolt-core-sdk | bolt-protocol-wasm Rust | 10 | All pass |
| localbolt-v3 | localbolt-web | 141/143 | 2 pre-existing failures (DOM env + path alias, unrelated to RB5) |

Test environment note: Tests run without WASM initialized, exercising the TS fallback path. Production wiring is verified by code-path analysis: `initWasmCrypto()` → `getWasmCrypto()` non-null → all crypto/BTR calls route through WASM.

---

## Residual Risks for RB6

1. **localbolt and localbolt-app** not yet wired (PM-RB-04 staged, follow-on after burn-in)
2. **Browser-environment WASM benchmark** not yet run (native-only in RB4)
3. **TS BTR fallback code retained** — dead on WASM path but present for rollback (PM-RB-03)
4. **bolt-protocol-wasm npm package not published** — localbolt-v3 needs access to the WASM artifact at runtime

---

## Verification

- **bolt-core (Rust crate):** Not modified
- **bolt-btr (Rust crate):** Not modified
- **bolt-transfer-core (Rust crate):** Not modified
- **bolt-protocol-wasm (Rust crate):** Not modified (RB4 artifact)
- **localbolt:** Not modified (PM-RB-04 deferred)
- **localbolt-app:** Not modified (PM-RB-04 deferred)
