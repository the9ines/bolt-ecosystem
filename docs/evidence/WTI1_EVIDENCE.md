# WTI1 Evidence — Implementation Audit + Integration Plan

**Stream:** WEBTRANSPORT-BROWSER-APP-IMPL-1
**Phase:** WTI1 — Implementation audit + integration plan
**Date:** 2026-03-21
**Type:** Audit (read-only codebase analysis, no runtime changes)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-WTI-01 | Existing daemon QUIC/quinn code audited for HTTP/3 WebTransport reuse | **PASS** — All 6 daemon modules audited (quic_transport.rs, ws_endpoint.rs, session.rs, web_hello.rs, envelope.rs, main.rs). Protocol layer (~80%) is transport-agnostic and reusable. Transport layer (~20%) requires new `wt_endpoint.rs`. Key finding: quinn 0.11 is raw QUIC — does NOT serve HTTP/3 WebTransport sessions directly. Requires HTTP/3 layer crate (`wtransport`, `h3` + `h3-quinn`, or equivalent). |
| AC-WTI-02 | Browser `DataTransport` interface confirmed sufficient for WebTransport (or gap identified) | **PASS** — Interface `{ send(data: string): void; readonly readyState: string; }` is sufficient with an adapter. Three gaps identified: (1) WebTransport provides byte streams, not messages — requires length-prefix framing; (2) no synchronous `readyState` — must track manually; (3) `WritableStream.write()` is async — must queue internally. All solvable via `WtDataTransport` adapter without changing the interface. |
| AC-WTI-03 | Integration plan: exact files to create/modify in daemon + SDK, with dependency order | **PASS** — 2 files to create, 6 files to modify, 8+ files untouched. Dependency order: daemon endpoint first (WTI2) → browser adapter (WTI3) → capability/gating (WTI4). See integration plan below. |
| AC-WTI-04 | TLS provisioning approach (C2 local CA) validated against daemon deployment model | **PASS** — mkcert-style local CA validated as workable for localhost/LAN. Daemon needs cert/key path config args (`--wt-cert`, `--wt-key`). First-run UX: user runs `mkcert -install && mkcert localhost 127.0.0.1`. No automated rotation (C3 ACME deferred per PM-WT-03). |

---

## Tested Path / Topology

This audit covers the **browser↔app** transport path only. WebTransport over HTTP/3 requires a server/app endpoint — it is not peer-to-peer.

Browser↔browser remains WebRTC (G1 invariant preserved). The WebTransport path never enters browser↔browser flows.

---

## 1. Daemon-Side Reuse Audit

### Files Audited

| File | Lines | Role |
|------|-------|------|
| `quic_transport.rs` | 648 | Raw QUIC transport (RC3 app↔app) |
| `ws_endpoint.rs` | 678 | WebSocket browser↔app endpoint (RC5) |
| `session.rs` | 11 | Re-export of `bolt_core::session::SessionContext` |
| `web_hello.rs` | 651 | HELLO handshake (parse/build/negotiate) |
| `envelope.rs` | 861 | ProfileEnvelopeV1 codec + message router |
| `main.rs` | — | Transport mode selection, port config, endpoint spawning |
| `lib.rs` | 98 | Module structure, feature gates |
| `Cargo.toml` | 81 | quinn = "0.11", rustls = "0.23", feature gates |

### Reusable Protocol Layer (~80%)

| Module | Reusability | Notes |
|--------|------------|-------|
| `envelope.rs` — encode/decode/route | 95% | `ProfileEnvelopeV1` codec, `route_inner_message()`, `build_error_payload()` are fully transport-agnostic. No adaptation needed. |
| `web_hello.rs` — HELLO parse/build/negotiate | 70% | Crypto sealing/opening and capability negotiation reusable as-is. Session-key exchange framing (`{"type":"session-key"}` frame at ws_endpoint.rs:164-172) is WS-specific — WT endpoint needs its own key exchange mechanism. |
| `session.rs` — SessionContext | 100% | Pure re-export of `bolt_core::session::SessionContext`. Transport-agnostic. |
| `dc_messages.rs` — message types | 100% | DcMessage parsing/encoding is transport-agnostic. |

### Non-Reusable Transport Layer (~20%)

| Code | Why Not Reusable |
|------|-----------------|
| `quic_transport.rs` TLS config + self-signed certs | RC3 uses `rcgen` self-signed certs + insecure verifier (`Rc3SkipVerification`). WebTransport requires CA-signed or locally-trusted TLS. |
| `quic_transport.rs` Listener/Dialer model | Raw QUIC socket accept. WebTransport uses HTTP request-handler model. |
| `ws_endpoint.rs` TCP listener + tungstenite codec | HTTP/3 WebTransport is a different server stack. |
| ALPN `"bolt-rc3"` | HTTP/3 uses standard ALPN `"h3"`. |

### Critical Finding: HTTP/3 Layer Required

quinn 0.11 is a raw QUIC implementation. WebTransport runs on HTTP/3, which runs on QUIC. The stack is:

```
WebTransport session
  ↓
HTTP/3 (h3 crate or equivalent)
  ↓
QUIC (quinn)
  ↓
UDP
```

The existing `quic_transport.rs` uses quinn directly for raw QUIC streams (RC3 app↔app mode). It does NOT serve HTTP/3 WebTransport sessions. The daemon needs an HTTP/3 layer crate — likely `wtransport` (Rust WebTransport server crate built on quinn) or `h3` + `h3-quinn`. This is the key nontrivial implementation requirement for WTI2.

The `QuicFramedStream` pattern (4-byte big-endian length prefix + payload) is conceptually reusable for message framing over WebTransport streams.

---

## 2. Browser-Side Transport Audit

### DataTransport Interface

Defined at `WsDataTransport.ts:39-42`:

```typescript
export interface DataTransport {
  send(data: string): void;
  readonly readyState: string;
}
```

Also duplicated at `EnvelopeCodec.ts:65-68` (identical, maintenance hazard).

### Three Gaps for WebTransport

| Gap | Current Assumption | WebTransport Reality | Solution |
|-----|-------------------|---------------------|----------|
| **Framing** | `send()` = one complete message. `onmessage` receives complete messages. WebSocket and RTCDataChannel provide native message boundaries. | WebTransport `ReadableStream.read()` returns arbitrary byte chunks, not messages. No native message boundaries. | Add length-prefix framing in `WtDataTransport`: 4-byte BE u32 length + UTF-8 payload. Matches daemon's `QuicFramedStream` pattern. |
| **readyState** | Synchronous string property (`'open'`, `'closed'`). Code checks `if (readyState !== 'open')` before sending. | WebTransport has no synchronous `readyState`. Uses `transport.ready` (Promise) and `transport.closed` (Promise). | Track state as instance property. Set `'open'` when `transport.ready` resolves, `'closed'` when `transport.closed` resolves. |
| **send() sync** | `send(data: string): void` is synchronous. Code calls `ws.send(JSON.stringify(...))` and expects immediate completion. | `WritableStream.write()` returns Promise. Backpressure is async. | Queue sends internally. Flush asynchronously via write loop on the WritableStream. External interface stays `send(data: string): void`. |

**Assessment:** All three gaps are solvable via a `WtDataTransport` adapter class that implements the existing `DataTransport` interface. No interface redesign needed. `HandshakeManager`, `TransferManager`, and `EnvelopeCodec` all work unchanged — they receive `DataTransport` via context accessors and never know which transport is underneath.

### BrowserAppTransport Fallback Integration

**Current orchestrator** (`BrowserAppTransport.ts`):
- `connect()` at line 80: tries WS primary → WebRTC fallback
- `onTransportMode` callback fires with `'ws'` or `'webrtc'`
- `createWebRTCFallback` factory injected optionally

**Proposed three-tier for browser↔app:**

```
tryWtConnect() → success? → mode = 'webtransport'
               → fail?   → tryWsConnect() → success? → mode = 'ws'
                                           → fail?   → [WebRTC fallback if configured]
```

The WebRTC fallback tier exists in `BrowserAppTransport` only because it was wired there for RC5. Whether it remains as a third tier for browser↔app depends on product configuration. The three-tier chain applies only to browser↔app flows. Browser↔browser WebRTC (`WebRTCService`) is a separate code path that never enters this chain.

---

## 3. Browser Support

WebTransport availability is feature-detected at runtime via `typeof WebTransport !== 'undefined'`. The product does not user-agent-sniff.

**Known support (per PM-WT-01 browser matrix):** Chromium-based browsers and Firefox have shipped WebTransport. Safari/WebKit has not shipped WebTransport as of this audit.

**Product impact:** Safari/WebKit users (including all iOS browsers, which use WebKit) do not get the WebTransport path. They fall to WS or WebRTC via the fallback chain. This is a real deployment constraint — Safari represents significant mobile reach.

Feature detection alone is sufficient for gating. If PM-WTI-02 decides opt-in at launch, an additional config flag would gate the WT probe before feature detection runs.

---

## 4. TLS / Local-Cert Assessment

**Requirement:** WebTransport over HTTP/3 requires TLS 1.3 with a certificate the browser trusts.

**C2 local CA validation:**

| Aspect | Status |
|--------|--------|
| mkcert generates local CA + leaf cert for localhost, 127.0.0.1, hostname | Validated — standard, well-maintained tooling |
| OS trust store insertion | `mkcert -install` handles macOS Keychain, Windows cert store, Linux ca-certificates |
| Daemon loads cert + key from disk | **Needs implementation** — current `quic_transport.rs` generates certs at runtime. WT endpoint must accept `--wt-cert` and `--wt-key` config args |
| LAN peers via hostname | Requires cert with SAN matching hostname. mkcert supports arbitrary hostnames |

**Missing operational pieces:**
- Daemon config args for cert/key file paths
- First-run documentation: user must run `mkcert -install && mkcert localhost 127.0.0.1`
- No automated cert rotation (C3 ACME deferred per PM-WT-03)

---

## 5. Exact Integration Plan

### Files to CREATE

| File | Repo | Purpose | Phase |
|------|------|---------|-------|
| `bolt-daemon/src/wt_endpoint.rs` | bolt-daemon | HTTP/3 WebTransport endpoint. Parallel to `ws_endpoint.rs`. Uses `wtransport` or `h3` + `h3-quinn`. Reuses envelope/HELLO/session/routing from protocol layer. | WTI2 |
| `bolt-transport-web/src/services/ws-transport/WtDataTransport.ts` | bolt-core-sdk | Browser WebTransport adapter. Implements `DataTransport` with length-prefix framing, manual readyState tracking, async send queue. | WTI3 |

### Files to MODIFY

| File | Repo | Change | Phase |
|------|------|--------|-------|
| `bolt-daemon/Cargo.toml` | bolt-daemon | Add `transport-webtransport` feature gate + HTTP/3 WebTransport crate dependency | WTI2 |
| `bolt-daemon/src/lib.rs` | bolt-daemon | Add `#[cfg(feature = "transport-webtransport")] pub mod wt_endpoint;` | WTI2 |
| `bolt-daemon/src/main.rs` | bolt-daemon | Add `--wt-listen`, `--wt-cert`, `--wt-key` args. Spawn WT endpoint task. | WTI2 |
| `bolt-transport-web/src/services/ws-transport/BrowserAppTransport.ts` | bolt-core-sdk | Add WT as primary tier in `connect()`. Extend `onTransportMode` to include `'webtransport'`. | WTI3 |
| `bolt-transport-web/src/services/ws-transport/index.ts` | bolt-core-sdk | Export `WtDataTransport` class | WTI3 |
| `bolt-daemon/src/web_hello.rs` | bolt-daemon | Add `bolt.transport-webtransport-v1` to `DAEMON_CAPABILITIES` array | WTI4 |

### Files LEFT UNTOUCHED

| File | Why |
|------|-----|
| `envelope.rs` | Fully transport-agnostic |
| `session.rs` | Pure re-export |
| `dc_messages.rs` | Transport-agnostic |
| `quic_transport.rs` | RC3 app↔app path — independent |
| `HandshakeManager.ts` | Receives DataTransport via context — works as-is |
| `TransferManager.ts` | Receives DataTransport via context — works as-is |
| `EnvelopeCodec.ts` | Transport-agnostic |
| `WebRTCService.ts` | Browser↔browser path — G1 preserved |
| `BtrTransferAdapter.ts` | BTR operates above transport — transparent |

### Dependency Order

```
WTI2: daemon HTTP/3 endpoint (wt_endpoint.rs + Cargo.toml + lib.rs + main.rs)
  ↓
WTI3: browser adapter (WtDataTransport.ts + BrowserAppTransport.ts + index.ts)
  ↓
WTI4: capability + gating (web_hello.rs capability + daemon config flag + browser config flag)
```

---

## 6. Risks

| # | Risk | Category |
|---|------|----------|
| 1 | **Rust HTTP/3 WebTransport crate maturity** — `wtransport` or `h3` + `h3-quinn` must be evaluated for API stability and browser interop | Unknown until early WTI2 |
| 2 | **Length-prefix framing must match daemon↔browser** — both sides must agree on 4-byte BE u32 format | Likely manageable |
| 3 | **Safari/WebKit reach gap** — no WebTransport support, all iOS browsers affected | Deployment constraint, not blocker |
| 4 | **TLS cert first-run UX** — user must run mkcert setup before daemon can serve WT | Likely manageable, needs docs |
| 5 | **DataTransport interface duplication** — defined in both WsDataTransport.ts and EnvelopeCodec.ts | Maintenance hazard, not blocker |

No architectural blockers identified. Risk #1 is the only unknown that could affect WTI2 scope.
