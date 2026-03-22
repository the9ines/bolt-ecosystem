# WTI2 Evidence — Daemon HTTP/3 WebTransport Endpoint

**Stream:** WEBTRANSPORT-BROWSER-APP-IMPL-1
**Phase:** WTI2 — Daemon HTTP/3 WebTransport endpoint
**Date:** 2026-03-21
**Type:** Engineering (new transport endpoint implementation)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-WTI-05 | Daemon serves HTTP/3 WebTransport endpoint on configurable port | **PASS** — New `wt_endpoint.rs` module serves WebTransport sessions via `wtransport` 0.7 (quinn 0.11 + rustls 0.23). Configurable via `--wt-listen <addr>`. Feature-gated behind `transport-webtransport`. |
| AC-WTI-06 | WebTransport endpoint accepts bidirectional streams with ProfileEnvelopeV1 JSON text framing | **PASS** — Accepts one bidirectional stream per session. Uses 4-byte big-endian length-prefixed framing for JSON messages. Full HELLO exchange + ProfileEnvelopeV1 envelope decode/route/reply loop. |
| AC-WTI-07 | TLS cert loading from configurable path (C2 local CA cert + key) | **PASS** — `--wt-cert` and `--wt-key` CLI flags load PEM-encoded cert chain and private key from disk via `wtransport::Identity::load_pemfiles()`. Compatible with mkcert-generated certs. |
| AC-WTI-08 | Daemon WebTransport endpoint tested with unit/integration tests | **PASS** — 6 WTI2-specific tests, all passing. Full test suite: 371 passed, 0 failed. `cargo fmt` clean. |

---

## Implementation Summary

Added a daemon-side WebTransport/HTTP3 endpoint that mirrors the existing `ws_endpoint.rs` pattern. The endpoint:

- Binds a UDP socket with TLS from PEM cert/key files
- Accepts browser WebTransport sessions over HTTP/3
- Opens/accepts one bidirectional stream per session
- Uses 4-byte big-endian length-prefixed framing for JSON messages
- Performs the encrypted HELLO flow (session-key exchange → HELLO → capability negotiation)
- Builds `SessionContext` and enters the envelope decode / route / reply loop
- Fails closed on protocol violations
- Mirrors WS logging style: `[WT_ENDPOINT]`, `[WT_SESSION]`, `[WT_HELLO]`

### Crate Selection

`wtransport` 0.7 selected over `h3` + `h3-quinn` based on WTI1 audit findings. Built on quinn 0.11 + rustls 0.23 (compatible with existing bolt-daemon dependencies). Provides clean server API with built-in PEM loading and self-signed cert generation for tests.

### Protocol Reuse

Reuses transport-agnostic protocol layer from:
- `envelope.rs` — `decode_envelope()`, `route_inner_message()`, `build_error_payload()`
- `web_hello.rs` — `parse_hello_typed()`, `build_hello_message()`, `daemon_capabilities()`, `negotiate_capabilities()`
- `session.rs` — `SessionContext`

### Framing

WebTransport bidirectional streams are byte-oriented (unlike WebSocket which has native message boundaries). The WT endpoint uses 4-byte big-endian length-prefix framing: `[u32 length][payload bytes]`. Max frame size enforced at 1 MiB. This matches the approach identified in the WTI1 audit.

---

## Files Changed (Implementation Repo: bolt-daemon)

| File | Change |
|------|--------|
| `bolt-daemon/src/wt_endpoint.rs` | **New** — ~520 lines. Full WebTransport server endpoint + 4 tests. |
| `bolt-daemon/Cargo.toml` | `transport-webtransport` feature gate. `wtransport = "0.7"` (optional). `rcgen` + `wtransport` dev-deps. |
| `bolt-daemon/src/lib.rs` | Feature-gated `pub mod wt_endpoint` export. |
| `bolt-daemon/src/main.rs` | `--wt-listen`, `--wt-cert`, `--wt-key` CLI flags. WT endpoint spawn logic in Default daemon mode. 2 CLI parse tests. |

**Commit/tag:** Not provided. Implementation is in working tree; commit/tag to be created on explicit request.

---

## Validation

```
cargo test --features transport-webtransport,transport-ws
  371 passed, 0 failed

cargo fmt
  clean (no changes)
```

---

## WTI2-Specific Tests (6)

| Test | Scope |
|------|-------|
| `wt_config_struct_fields` | Config struct construction and field access |
| `wt_endpoint_starts_with_self_signed_cert` | Server binds UDP socket with self-signed identity |
| `wt_frame_roundtrip` | Full client↔server length-prefixed frame echo over real WebTransport connection |
| `wt_endpoint_run_and_shutdown` | `run_wt_endpoint()` starts from PEM files and shuts down cleanly on signal |
| `wti2_wt_listen_parsed` | CLI flag parse: `--wt-listen`, `--wt-cert`, `--wt-key` |
| `wti2_wt_flags_default_none` | CLI defaults: all WT flags are None when absent |

---

## Residual Gaps / WTI3 Handoff

| # | Gap | Target Phase |
|---|-----|-------------|
| 1 | Browser adapter (`WtDataTransport.ts`) not yet implemented | WTI3 |
| 2 | WebTransport capability string (`bolt.transport-webtransport-v1`) not yet advertised in daemon capabilities | WTI4 |
| 3 | Multi-stream support deferred; current impl is one bidi stream per session (matches WS 1:1 model) | Future |
| 4 | mkcert quick-start docs needed for `--wt-cert` / `--wt-key` first-run UX | WTI4 |
| 5 | QUIC 0-RTT not enabled (reduces connection latency) | Future |
| 6 | Shared HELLO/session-key helper extraction deferred (WT + WS have similar exchange logic) | Future |

---

## Status

| Phase | Status |
|-------|--------|
| **WTI2** | **DONE** |
| **WTI3** | **READY** |
