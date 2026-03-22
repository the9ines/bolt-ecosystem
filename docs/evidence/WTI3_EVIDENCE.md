# WTI3 Evidence — Browser WebTransport Adapter + Three-Tier Fallback

**Stream:** WEBTRANSPORT-BROWSER-APP-IMPL-1
**Phase:** WTI3 — Browser WebTransport adapter + three-tier fallback
**Date:** 2026-03-21
**Type:** Engineering (browser-side transport adapter implementation)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-WTI-09 | `WtDataTransport` class implements `DataTransport` interface using browser WebTransport API | **PASS** — `WtDataTransport` class created, mirrors `WsDataTransport` structure. Connects via `globalThis.WebTransport`, opens one bidi stream, uses 4-byte BE length-prefixed framing. `WtDataTransportBridge` wraps async `WritableStream.write()` behind sync `send(data: string)` with internal queue. Manual `readyState` tracking. Delegates all protocol logic to shared `HandshakeManager` and `TransferManager`. |
| AC-WTI-10 | `BrowserAppTransport` updated: WT primary → WS fallback → WebRTC fallback (three-tier) | **PASS** — `BrowserAppTransport` updated from 2-tier (WS→WebRTC) to 3-tier (WT→WS→WebRTC). WebTransport attempted only when `webTransportUrl` configured AND `globalThis.WebTransport` exists. On WT failure, falls to WS. On WS failure, falls to WebRTC if `createWebRTCFallback` factory provided. |
| AC-WTI-11 | Runtime feature detection (`typeof WebTransport !== 'undefined'`) gates WT probe | **PASS** — Feature detection at both `WtDataTransport.connect()` and `BrowserAppTransport.connect()`. Safari/WebKit users transparently fall to WS path. |
| AC-WTI-12 | Fallback triggers are deterministic (cert error, UDP blocked, timeout, connection refused/reset) | **PASS** — WT connect timeout, transport.ready rejection, and createBidirectionalStream failure all resolve `connect()` to `false`, triggering deterministic fallback to WS. No loops, no flapping. 26 tests cover all fallback paths. |

---

## Implementation Summary

Added browser-side WebTransport adapter and three-tier fallback chain for browser↔app transport.

### WtDataTransport

- Connects to configured WebTransport URL via `globalThis.WebTransport`
- Awaits `transport.ready`, opens one bidirectional stream
- Uses **4-byte big-endian length-prefixed framing** matching daemon `wt_endpoint.rs`
- `FrameDeframer` class accumulates byte chunks and yields complete messages (handles partial reads, enforces 1 MiB max frame size)
- `WtDataTransportBridge` wraps async `WritableStream.write()` behind sync-style `send(data: string)` with internal send queue
- Tracks `readyState` manually (`connecting` → `open` → `closed`)
- Delegates all protocol logic to shared `HandshakeManager` and `TransferManager` via context bridges (identical pattern to WS)
- Fails closed on protocol violations and malformed frames
- Full BTR support via same `createBtrAdapter` path

### BrowserAppTransport Three-Tier Fallback

Updated from WS→WebRTC to WT→WS→WebRTC:
1. **WebTransport primary** — if `webTransportUrl` configured and `globalThis.WebTransport` exists
2. **WebSocket fallback** — always attempted when WT unavailable or fails
3. **WebRTC fallback** — if `createWebRTCFallback` factory provided

Transport mode reporting extended to `'webtransport' | 'ws' | 'webrtc'`.

Safari/WebKit users transparently fall to WS because `globalThis.WebTransport` is undefined.

---

## Files Changed (Implementation Repo: bolt-core-sdk)

| File | Change |
|------|--------|
| `bolt-transport-web/src/services/ws-transport/WtDataTransport.ts` | **New** — ~530 lines. WebTransport adapter + framing helpers + DataTransport bridge. |
| `bolt-transport-web/src/services/ws-transport/BrowserAppTransport.ts` | Rewritten — 3-tier fallback (WT→WS→WebRTC), `webTransportUrl` option, `'webtransport'` mode. |
| `bolt-transport-web/src/services/ws-transport/index.ts` | Export `WtDataTransport`, `encodeFrame`, `FrameDeframer`. |
| `bolt-transport-web/src/__tests__/wt-transport.test.ts` | **New** — 26 tests covering framing, deframing, WtDataTransport, and BrowserAppTransport fallback. |

**Commit/tag:** Not provided. Implementation is in working tree; commit/tag to be created on explicit request.

---

## Validation

```
npm test   → 401 passed, 0 failed (32 test files)
npm build  → clean (tsc, no errors)
```

---

## WTI3-Specific Tests (26)

| Category | Tests |
|----------|-------|
| Frame encoding | BE header + payload, empty string, unicode |
| FrameDeframer | single frame, multiple frames, partial across pushes, split payload, max size reject, reset |
| WtDataTransport | feature detection, timeout, legacy connect, readyState transitions, cleanup, shared managers, BTR propagation, send queue |
| BrowserAppTransport | WT success, WT unavailable→WS, WT fail→WS, WT+WS fail→WebRTC, skip WT when unconfigured, all-fail throws, mode reporting, sendFile delegation, Safari/WS-only path |

---

## Residual Gaps / WTI4 Handoff

| # | Gap | Target Phase |
|---|-----|-------------|
| 1 | Capability string `bolt.transport-webtransport-v1` not yet advertised in daemon or browser HELLO | WTI4 |
| 2 | Feature gate / kill-switch not yet added (no daemon or browser config flag to force-disable WT) | WTI4 |
| 3 | TLS cert docs / mkcert quick-start guide needed for `--wt-cert` / `--wt-key` first-run UX | WTI4 |
| 4 | `DataTransport` interface duplication still exists in `WsDataTransport.ts` and `EnvelopeCodec.ts` | Future |

---

## Status

| Phase | Status |
|-------|--------|
| **WTI3** | **DONE** |
| **WTI4** | **READY** |
