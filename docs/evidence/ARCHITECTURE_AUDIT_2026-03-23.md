# Architecture & Language Ownership Audit — 2026-03-23

**Type:** Full multi-repo architecture audit
**Date:** 2026-03-23
**Scope:** All repos in bolt-ecosystem

---

## Repo Inventory

| Repo | Type | Language Authority | Status |
|------|------|-------------------|--------|
| bolt-protocol | Spec | Markdown | Active |
| bolt-core-sdk | Canonical SDK | Rust + TS | Active |
| bolt-daemon | Daemon runtime | Rust | Active |
| bolt-rendezvous | Signaling server | Rust | Active |
| localbolt | Web consumer | TS | Active |
| localbolt-v3 | Web consumer (production) | TS | Active |
| localbolt-app | Tauri desktop | Rust + TS | **Retired** |
| bytebolt-app | Commercial app | — | Planned |
| bytebolt-relay | Commercial relay | — | Planned |

---

## Subsystem Ownership

### Aligned (Correct)

| Subsystem | Owner | Language | Notes |
|-----------|-------|----------|-------|
| Protocol / wire contracts | bolt-core-sdk | Rust | Canonical |
| BTR / transfer ratchet | bolt-core-sdk (bolt-btr) | Rust | Canonical |
| Transfer state machine | bolt-core-sdk (bolt-transfer-core) | Rust | Canonical |
| Daemon lifecycle | bolt-app-core | Rust | Extracted from Tauri |
| App runtime orchestration | bolt-app-core | Rust | Shell-agnostic |
| Signaling server | bolt-rendezvous | Rust | Canonical |
| Desktop shell | bolt-ui | Rust (egui) | Canonical |
| Daemon file transfer | bolt-daemon | Rust | WS/WT/QUIC endpoints |
| Daemon handshake/session | bolt-daemon | Rust | HELLO/envelope/routing |
| Identity store (daemon) | bolt-daemon | Rust | Persistent keypair |
| Browser↔browser WebRTC | bolt-transport-web | TS | Necessarily browser-side |
| Web shells | localbolt, localbolt-v3 | TS | Necessarily browser-side |
| Browser signaling client | bolt-transport-web | TS | Browser WebSocket API |
| Identity / TOFU in browser | bolt-transport-web | TS | IndexedDB |

### Acceptable Drift

| Item | Current State | Severity | Notes |
|------|--------------|----------|-------|
| Browser transfer orchestration | `TransferManager.ts` (~865 lines) is thick TS | LOW | Rust SM + WASM exist. TS path retained for compatibility. WASM should become default over time. |
| Browser crypto dual-path | TS NaCl + Rust/WASM NaCl both active | LOW | `WasmBtrTransferAdapter` preferred when available. TS fallback retained. Migration path clear. |
| `localbolt-core` TS orchestration | Session state, peer code gen, BTR negotiation in TS | LOW | Adapter layer. Not protocol authority. Acceptable while WASM authority grows. |

### Concerning Drift

| Item | Current State | Severity | Required Action |
|------|--------------|----------|----------------|
| `localbolt-app` still exists | Code present, commits possible | MEDIUM | Freeze/archive. No new strategic work. |
| Browser↔daemon WebRTC coupling | localbolt-v3 used `WebRTCService` for all peers including desktop | HIGH (resolved) | Now uses `BrowserAppTransport` for desktop peers. Must not regress. |
| Browser transfer TS thickness | `TransferManager.ts` owns chunk processing, backpressure, progress | MEDIUM | Should converge toward Rust/WASM SM authority over time. |
| Browser crypto growth risk | New crypto logic could be added in TS instead of Rust | MEDIUM | Codify anti-pattern: no new TS crypto. |

---

## Key Findings

1. **The ecosystem is mostly architecturally sound.** The Rust-first foundation (bolt-core, bolt-btr, bolt-transfer-core, bolt-app-core, bolt-daemon, bolt-rendezvous) is canonical and well-tested. The main risk is adoption drift, not missing foundations.

2. **The direct browser↔app transport stack already exists and works.** Daemon WS/WT endpoints + browser `BrowserAppTransport` are built, tested, and now integrated into localbolt-v3. This is the correct path — not deeper daemon↔browser WebRTC coupling.

3. **TS ownership is appropriate for browser-only concerns** (WebRTC, DOM, IndexedDB, signaling WebSocket client) but should not grow into protocol authority or canonical transfer logic.

4. **`localbolt-app` is a dead-code risk.** It's retired but not frozen/archived. New commits could accidentally flow into it.

---

## Anti-Patterns (Prohibited)

| ID | Anti-Pattern | Rationale |
|----|-------------|-----------|
| AP-01 | New strategic work in `localbolt-app` | Desktop is `bolt-ui`. Tauri is retired. |
| AP-02 | Deepening daemon↔browser WebRTC interop | Direct transport (WS/WT) is the browser↔app path. |
| AP-03 | New TS crypto logic | Rust/WASM is crypto authority. TS is fallback only. |
| AP-04 | New TS transfer orchestration authority | Rust SM (bolt-transfer-core) is canonical. |
| AP-05 | TS protocol wire format changes | Wire format owned by Rust core. TS mirrors, does not author. |
