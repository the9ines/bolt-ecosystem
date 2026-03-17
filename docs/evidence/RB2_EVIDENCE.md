# RB2 Evidence — Authority Boundary Audit + TS Adapter Inventory

**Stream:** RUSTIFY-BROWSER-CORE-1
**Phase:** RB2 — Authority Boundary Audit + TS Adapter Inventory
**Date:** 2026-03-17
**Tag:** `ecosystem-v0.1.167-rustify-browser-core1-rb2-boundary-audit`
**Type:** Engineering audit (read-only code analysis + WASM size measurement, no runtime changes)

---

## Key De-Risking Result

**Protocol-only WASM bundle: 67 KiB gzipped (233 KiB headroom under 300 KiB budget).**

bolt-core + bolt-btr + bolt-transfer-core compiled to WASM with full crypto (NaCl box, X25519-dalek, SHA-256, HKDF, secretbox): 125 KiB uncompressed, 67 KiB gzipped. This is the inverse of EGUI-WASM-1 (1.3 MiB) — protocol logic without UI rendering is structurally compact.

| Metric | Value |
|--------|-------|
| WASM uncompressed | 125 KiB |
| **WASM gzipped** | **67 KiB** |
| PM-RB-01 budget | ≤300 KiB |
| **Headroom** | **233 KiB (78%)** |
| Current browser app | 65 KiB |
| Post-migration estimate | ~132 KiB (65 KiB TS + 67 KiB WASM) |

**Residual risk:** Per-chunk WASM hot-path overhead still needs RB3 benchmarking. Size viability is proven; runtime performance is not yet measured.

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-RB-05 | Every TS protocol-authority module inventoried with disposition | **PASS** — 31+ modules classified (see inventory below) |
| AC-RB-06 | WASM API surface defined (function signatures for JS↔WASM boundary) | **PASS** — BoltProtocolCore + BtrSession + BtrTransferHandle boundary defined |
| AC-RB-07 | Bundle size estimate for protocol WASM | **PASS** — Measured 67 KiB gzipped (well within 300 KiB budget) |

---

## TS Module Inventory by Disposition

### WASM-replace (13 modules, ~883 LOC)

Entire module moves to Rust/WASM. TS code becomes dead after migration.

| Module | Package | LOC | Rust Target |
|--------|---------|-----|-------------|
| crypto.ts | bolt-core | 66 | bolt_core::crypto |
| sas.ts | bolt-core | 64 | bolt_core::sas |
| hash.ts | bolt-core | 27 | bolt_core::hash |
| identity.ts | bolt-core | 35 | bolt_core::identity |
| peer-code.ts | bolt-core | 62 | bolt_core::peer_code |
| btr/key-schedule.ts | bolt-core | 58 | bolt_btr::key_schedule |
| btr/ratchet.ts | bolt-core | 65 | bolt_btr::ratchet |
| btr/encrypt.ts | bolt-core | 69 | bolt_btr::encrypt |
| btr/state.ts | bolt-core | 191 | bolt_btr::state |
| btr/replay.ts | bolt-core | 102 | bolt_btr::replay |
| btr/negotiate.ts | bolt-core | 59 | bolt_btr::negotiate |
| btr/constants.ts | bolt-core | 32 | bolt_btr::constants |
| EnvelopeCodec.ts | bolt-transport-web | 90 | New: envelope codec in Rust |

### Split modules (3 modules, ~1,946 LOC)

Crypto/protocol calls migrate to WASM; WebRTC I/O and browser API wiring stays in TS.

| Module | Package | LOC | Crypto→WASM | I/O→TS-retain |
|--------|---------|-----|-------------|---------------|
| HandshakeManager.ts | bolt-transport-web | 253 | seal/open/SAS calls | WebRTC event wiring, timeout logic |
| TransferManager.ts | bolt-transport-web | 836 | seal_chunk/open_chunk, BTR state | DataChannel read/write, progress, backpressure |
| WebRTCService.ts | bolt-transport-web | 857 | Ephemeral keys, BTR adapter, envelope parsing | RTCPeerConnection, ICE, connection state |

### TS-retain (18+ modules, ~2,500+ LOC)

Stays in TypeScript. Browser APIs, UI, persistence, application orchestration.

| Module | Package | LOC | Rationale |
|--------|---------|-----|-----------|
| constants.ts | bolt-core | 38 | Immutable protocol constants (consumed by both) |
| errors.ts | bolt-core | 81 | Error display/validation table |
| encoding.ts | bolt-core | 12 | Base64 trivial utility |
| btr/errors.ts | bolt-core | 53 | Error types (consumed by both) |
| identity-store.ts | bolt-transport-web | 98 | IndexedDB (browser API) |
| pin-store.ts | bolt-transport-web | 167 | IndexedDB (browser API) |
| WebSocketSignaling.ts | bolt-transport-web | 388 | WebSocket (browser API) |
| DualSignaling.ts | bolt-transport-web | 198 | Signaling failover |
| WsDataTransport.ts | bolt-transport-web | 548 | WebSocket data transport |
| BrowserAppTransport.ts | bolt-transport-web | 171 | Transport failover |
| types.ts | bolt-transport-web | 117 | Type definitions |
| transferMetrics.ts | bolt-transport-web | 272 | Telemetry |
| device-detect.ts | bolt-transport-web | 48 | Platform detection |
| PolicyAdapter.ts | bolt-transport-web | 286 | Already WASM (T-STREAM-1) |
| session-state.ts | localbolt-core | ~80 | Application-level session phases |
| verification-state.ts | localbolt-core | ~50 | Application-level pub/sub |
| transfer-policy.ts | localbolt-core | ~30 | Application-level gating |
| peer-connection.ts | consumers | ~300-495 | UI orchestration |

### Already WASM (1 module)

| Module | Package | LOC | Status |
|--------|---------|-----|--------|
| PolicyAdapter.ts | bolt-transport-web | 286 | Rust WASM via T-STREAM-1 |

---

## JS↔WASM API Boundary

### Design Principle

Coarse-grained Rust ownership. Rust holds all protocol state and key material. JS calls Rust at lifecycle boundaries and per-chunk. Minimize per-call overhead. No JSON serialization in the hot path.

### Proposed API Surface

**Session / Crypto (RB3 scope):**

| Function | Direction | Frequency |
|----------|-----------|-----------|
| `generate_identity_keypair() → {pk, sk}` | JS→WASM | Once per app lifecycle |
| `generate_ephemeral_keypair() → {pk, sk}` | JS→WASM | Once per connection |
| `seal_box(plaintext, remote_pk, sk) → base64` | JS→WASM | Per HELLO / envelope |
| `open_box(sealed_b64, remote_pk, sk) → bytes` | JS→WASM | Per HELLO / envelope |
| `compute_sas(local_id, remote_id, local_eph, remote_eph) → string` | JS→WASM | Once per session |
| `generate_peer_code() → string` | JS→WASM | Once per session |
| `sha256_hex(data) → string` | JS→WASM | Once per transfer |
| `encode_envelope_v1(inner, remote_pk, sk, btr_fields?) → bytes` | JS→WASM | Per message |
| `decode_envelope_v1(sealed, remote_pk, sk) → {inner, btr_fields?}` | JS→WASM | Per message |
| `negotiate_btr(local_caps, remote_caps) → mode` | JS→WASM | Once per session |

**BTR + Transfer (RB4 scope):**

| Function | Direction | Frequency |
|----------|-----------|-----------|
| `BtrSession::new(session_secret) → handle` | JS→WASM | Once per session |
| `BtrSession::begin_send(remote_ratchet_pk) → transfer_handle` | JS→WASM | Once per transfer |
| `BtrSession::begin_receive(remote_ratchet_pk) → transfer_handle` | JS→WASM | Once per transfer |
| `BtrTransferHandle::seal_chunk(plaintext) → ciphertext` | JS→WASM | **Per chunk (hot path)** |
| `BtrTransferHandle::open_chunk(ciphertext) → plaintext` | JS→WASM | **Per chunk (hot path)** |
| `BtrSession::free()` | JS→WASM | Once per session |

**State ownership:**
- **Rust owns:** All key material, BTR state, replay guard, envelope codec
- **JS owns:** WebRTC DataChannel I/O, IndexedDB persistence, WebSocket signaling, UI

**Hot path:** `seal_chunk` and `open_chunk` — two WASM calls per 16 KiB chunk (~62 calls/MiB). Each is a single function call with memory copy in, compute, memory copy out. Performance needs RB3 benchmarking.

---

## Migration Path Assessment

The migration path appears to be targeted substitution of crypto/protocol authority within existing TS transport adapters, not a full browser-stack rewrite. The three split modules (HandshakeManager, TransferManager, WebRTCService) retain their structure and WebRTC wiring — only crypto function calls change from TS tweetnacl to Rust WASM.

This assessment is based on code structure analysis, not implementation proof. RB3 will validate whether the substitution is as clean in practice as it appears in the inventory.

---

## Residual Risks Before RB3

| # | Risk | Severity | Status |
|---|------|----------|--------|
| 1 | Per-chunk WASM hot-path overhead | Medium | **Unresolved — needs RB3 benchmarking.** Size viability proven; runtime performance not yet measured. |
| 2 | BTR state ownership across JS↔WASM boundary | Medium | Mitigated by opaque handle design. wasm-bindgen supports this. |
| 3 | Envelope codec not yet in Rust | Low | 90 LOC stateless codec. Straightforward to implement. |
| 4 | wasm-opt version mismatch (bulk-memory) | Low | Update wasm-pack or enable bulk-memory flag. All modern browsers support it. |
| 5 | HandshakeManager/TransferManager split complexity | Medium | Targeted substitution of crypto calls. Not a rewrite — but needs careful testing. |

---

## Verification

- **Runtime files changed:** NONE (size measurement used temporary /tmp crate, not committed)
- **bolt-core-sdk modified:** NO
- **localbolt-v3 modified:** NO
- **Cross-doc consistency:** All three authoritative docs agree on RB2 DONE, RB3 READY
