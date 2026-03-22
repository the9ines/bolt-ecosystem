# WTI4 Evidence — Feature Gating + Capability Negotiation

**Stream:** WEBTRANSPORT-BROWSER-APP-IMPL-1
**Phase:** WTI4 — Feature gating + capability negotiation + TLS provisioning
**Date:** 2026-03-21
**Type:** Engineering (capability advertisement + runtime gating)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-WTI-13 | `bolt.transport-webtransport-v1` capability exchanged in HELLO (PM-WT-02) | **PASS** — Daemon: `daemon_capabilities(wt_enabled: bool)` conditionally includes WT capability. Browser: `WtDataTransport` always includes it; `WsDataTransport` includes it when `webTransportEnabled: true`. Capability set is coherent across endpoints. |
| AC-WTI-14 | Feature gate: daemon config flag enables/disables WT endpoint (kill-switch RB-L5) | **PASS** — `--no-wt` CLI flag. When set, WT endpoint is not spawned and WT capability is not advertised. `wt_enabled = wt_listen.is_some() && !no_wt`. |
| AC-WTI-15 | Browser feature gate: config/environment flag can force WS-only or WebRTC-only mode | **PASS** — `webTransportEnabled?: boolean` on `BrowserAppTransportOptions`. When `false`, WT attempt is skipped entirely; falls directly to WS→WebRTC. Default: enabled when `webTransportUrl` is present. |
| AC-WTI-16 | TLS cert generation documented (mkcert flow for C2 local CA) | **PARTIAL** — TLS cert loading implemented and tested (`--wt-cert`, `--wt-key`). Operator-facing mkcert quick-start guide deferred to WTI5. |

---

## Implementation Summary

### Capability Advertisement

- **Daemon**: `daemon_capabilities(wt_enabled: bool)` conditionally includes `bolt.transport-webtransport-v1`. Both WS and WT endpoints receive the same `wt_enabled` flag so capability sets stay coherent across all connections.
- **Browser**: `WtDataTransport` always includes the WT capability (it IS using WT). `WsDataTransport` includes it only when `webTransportEnabled: true`, signaling to the daemon that this client supports WT even on a WS connection.
- `BrowserAppTransport` passes `webTransportEnabled` through automatically based on whether `webTransportUrl` is configured and not force-disabled.

### Runtime Gating / Kill-Switches

- **Daemon**: `--no-wt` CLI flag acts as kill-switch. When set, WT endpoint is not spawned and WT capability is not advertised, even if `--wt-listen` / `--wt-cert` / `--wt-key` are provided. Derivation: `wt_enabled = wt_listen.is_some() && !no_wt`.
- **Browser**: `webTransportEnabled?: boolean` on `BrowserAppTransportOptions`. When `false`, WT attempt is skipped entirely and falls directly to WS→WebRTC fallback. Default: `true` when `webTransportUrl` is present.

### Negotiation Coherence

- Capability advertisement matches actual transport attempt policy on both sides.
- WS-only and WebRTC fallback paths remain unaffected.
- Fail-closed behavior preserved on protocol violations.

---

## Files Changed

### Daemon (bolt-daemon)

| File | Change |
|------|--------|
| `src/web_hello.rs` | `daemon_capabilities(wt_enabled: bool)` + 2 new tests |
| `src/ws_endpoint.rs` | `wt_enabled` field in `WsEndpointConfig`, threaded to `handle_connection` + `daemon_capabilities()` |
| `src/wt_endpoint.rs` | `daemon_capabilities(true)` call |
| `src/main.rs` | `--no-wt` flag, `no_wt` field in Args, `wt_enabled` derivation, 2 CLI tests |
| `src/rendezvous.rs` | Updated `daemon_capabilities(false)` calls |
| `tests/d_e2e_web_to_daemon.rs` | Updated `daemon_capabilities(false)` |
| `tests/h5_downgrade_validation.rs` | Updated `daemon_capabilities(false)` |
| `tests/rc5_btr_over_ws.rs` | Added `wt_enabled: false` to config |

### Browser (bolt-core-sdk/ts/bolt-transport-web)

| File | Change |
|------|--------|
| `src/services/ws-transport/WtDataTransport.ts` | WT cap in localCapabilities |
| `src/services/ws-transport/WsDataTransport.ts` | `webTransportEnabled` option, conditional WT cap |
| `src/services/ws-transport/BrowserAppTransport.ts` | `webTransportEnabled` option, kill-switch gating, pass-through to WS |
| `src/__tests__/wt-transport.test.ts` | 9 WTI4 tests |

**Commit/tag:** Not provided. Implementation is in working tree.

---

## Validation

```
Daemon:
  cargo test --features transport-webtransport,transport-ws → 375 passed, 0 failed
  cargo fmt → clean

Browser:
  npm test → 410 passed, 0 failed
  npm run build → clean
```

---

## WTI4-Specific Tests (13)

### Daemon (4)

| Test | Scope |
|------|-------|
| `wti4_daemon_capabilities_wt_when_enabled` | WT cap present when `wt_enabled=true` |
| `wti4_daemon_capabilities_no_wt_when_disabled` | WT cap absent when `wt_enabled=false` |
| `wti4_no_wt_flag_parsed` | `--no-wt` CLI flag parsing |
| `wti4_no_wt_default_false` | `--no-wt` defaults to `false` |

### Browser (9)

| Test | Scope |
|------|-------|
| WT cap in WtDataTransport (2) | Presence of `bolt.transport-webtransport-v1` in WtDataTransport localCapabilities |
| WsDataTransport cap gating (3) | WT cap present when `webTransportEnabled=true`, absent when `false` or default |
| Kill-switch: skip WT (1) | `webTransportEnabled=false` with URL+API → skips to WS |
| Kill-switch: default enabled (1) | `webTransportEnabled` unset + URL → WT attempted |
| Kill-switch: fallback (1) | WT disabled → falls to WS correctly |
| No regression (1) | WS-only path without any WT options |

---

## Residual Gaps / WTI5 Handoff

| # | Gap | Target Phase |
|---|-----|-------------|
| 1 | TLS cert docs / mkcert quick-start guide | WTI5 |
| 2 | End-to-end smoke test: browser→daemon file transfer over WT | WTI5 |
| 3 | Fallback smoke test: WT unavailable → WS transfer succeeds | WTI5 |
| 4 | Throughput measurement: WT vs WS baseline on browser↔app path | WTI5 |
| 5 | BTR parity verification: BTR transfer over WT matches WS/WebRTC | WTI5 |
| 6 | `DataTransport` interface duplication — non-blocking | Future |

---

## Status

| Phase | Status |
|-------|--------|
| **WTI4** | **DONE** |
| **WTI5** | **READY** |
