# WTE1 Evidence — WEBTRANSPORT-BROWSER-APP-E2E-1 Stream Complete

**Stream:** WEBTRANSPORT-BROWSER-APP-E2E-1
**Date:** 2026-03-21
**Type:** Validation (real browser-runtime proof)

---

## Stream Scope

Real browser-runtime validation of the shipped browser↔app WebTransport path.
Proves that a real Chrome browser can connect to the daemon's WT endpoint and
exchange length-prefixed frames, and that the WS fallback path works in the
same browser session.

**This stream validates transport-layer runtime connectivity and framing.**
It does NOT validate the full application protocol (HELLO + ProfileEnvelopeV1 +
file transfer) over WebTransport in a real browser. Full app-protocol E2E over
WT would require bundling the SDK into a browser page — that is a separate
future concern.

---

## Acceptance Summary

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Runnable browser harness | **PASS** — `bolt-daemon/tests/e2e-browser/`, `npm test` |
| 2 | Real browser→daemon WT connectivity | **PASS** — Chrome 146 `WebTransport` connects to daemon WT endpoint via `serverCertificateHashes` |
| 3 | WT length-prefixed frame echo | **PASS** — 4-byte BE framing, 18-byte payload echoed correctly |
| 4 | WT multi-frame round-trip | **PASS** — 3 frames (7B, 16B, 1000B) all echoed correctly |
| 5 | Real browser→daemon WS fallback | **PASS** — WebSocket connect + text echo in same browser session |
| 6 | Reproducible run instructions | **PASS** — `tests/e2e-browser/README.md` |

---

## Implementation

### Echo Server (`examples/wt_e2e_echo.rs`)

- Generates short-lived self-signed cert (13-day validity, required for Chrome `serverCertificateHashes`)
- Starts WT endpoint on random port (HTTP/3, 4-byte BE length-prefixed echo)
- Starts WS endpoint on random port (text echo)
- Prints JSON config to stdout: `{"wt_port", "ws_port", "cert_hash"}`
- Exits on stdin close (harness controls lifecycle)

### Playwright Harness (`tests/e2e-browser/wt-e2e-browser.mjs`)

- Spawns echo server via `cargo run --example wt_e2e_echo`
- Launches real Chrome via Playwright (`channel: 'chrome'`)
- Navigates to HTTPS page for secure context (WebTransport requires secure context)
- Runs 4 tests via `page.evaluate()`:
  1. WT feature detection (`typeof WebTransport`)
  2. WT connect with `serverCertificateHashes` + framed echo
  3. WS connect + text echo
  4. WT multi-frame round-trip
- Structured `[PASS]`/`[FAIL]` output with summary

---

## Files Changed

| File | Change |
|------|--------|
| `bolt-daemon/examples/wt_e2e_echo.rs` | **New** — WT+WS echo server with self-signed cert |
| `bolt-daemon/tests/e2e-browser/wt-e2e-browser.mjs` | **New** — Playwright browser test (4 tests) |
| `bolt-daemon/tests/e2e-browser/package.json` | **New** — Playwright dep |
| `bolt-daemon/tests/e2e-browser/README.md` | **New** — Run instructions |
| `bolt-daemon/Cargo.toml` | Added `time = "0.3"` dev-dep |

**Commit/tag:** Not provided.

---

## Validation Output

```
[PASS] WT feature detection
[PASS] WT connect + framed echo
[PASS] WS connect + echo
[PASS] WT multi-frame round-trip

[SUMMARY] 4 passed, 0 failed
```

Daemon `cargo test`: 381 passed, 0 failed. `cargo fmt` clean.

---

## Known Limits

| Item | Status |
|------|--------|
| Full HELLO + ProfileEnvelopeV1 + file transfer over WT in browser | Not tested. Would require bundling SDK into browser page. Transport-layer proof only. |
| Playwright bundled Chromium lacks WebTransport | Harness requires real Chrome (`channel: 'chrome'`). Documented in README. |
| LAN/WAN network conditions | Tests run on localhost loopback only. |

---

## Dependency

This stream depends on WEBTRANSPORT-BROWSER-APP-IMPL-1 (CLOSED, `ecosystem-v0.1.196`).

---

## Final Status

**WEBTRANSPORT-BROWSER-APP-E2E-1: COMPLETE.**

Scope: transport-runtime validation. All 6 acceptance criteria satisfied. Stream CLOSED.
