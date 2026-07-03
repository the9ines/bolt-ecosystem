# Manual Validation — 2026-07-03

> Immutable evidence record. Executed on oberfelder's Mac Studio (arm64).
> Classifications per `os/rules/validation-protocol.md`.
> Governance OS journal reference: 2026-07-03 entry.

Two manual checklists from the (frozen) `docs/GOVERNANCE_WORKSTREAMS.md`
"Manual Validation Checklist" section, both previously **NOT YET EXECUTED**.

Software under test: locally built `LocalBolt.app` (arm64, ad-hoc signed) with the
just-recovered May work — daemon `a45b76b` (WT BTR receive + IPC transfer events)
and app `90ff3a7` (order-aware WT lifecycle parse). Daemon built `--features
native-full` (WS + WebTransport + QUIC).

---

## App ↔ Browser — CONFIRMED (7/8 steps; step 8 native path confirmed)

Native app: `LocalBolt.app` pid 27050, bundled `bolt-daemon` pid 27054
(`--mode ws-endpoint --ws-listen 0.0.0.0:9150`). Browser: Chrome at
`https://localbolt.app` (production site), driven via the Chrome extension.

**Transport actually exercised:** WebTransport (HTTP/3) to
`https://192.168.4.210:9151` with `serverCertificateHashes` cert-hash pinning
(HTTPS origin path). BTR negotiated — per-transfer DH ratchet + per-chunk chain
active (`[BTR_FULL]`, WASM Rust authority on the browser, `BtrEngine` on the daemon).

| # | Step | Result | Evidence |
|---|------|--------|----------|
| 1 | Launch native app | CONFIRMED | App + daemon processes up; UI shows ONLINE, own peer code NDEWCV |
| 2 | Browser online via cloud signaling | CONFIRMED | `[WS-SIGNAL] Connected` / `Registered as SPU6MS` to `wss://bolt-rendezvous.fly.dev` |
| 3 | Browser sees native in Devices | CONFIRMED | `[DUAL] Peer discovered via cloud: NDEWCV (oberfelder's Mac Studio)` |
| 4 | Browser Connect → native shows request | CONFIRMED | Native UI: "Mac wants to connect" with Decline/Accept |
| 5 | Native accepts → session + SAS | CONFIRMED | WT connect + cert-hash pin; `HELLO complete`; **SAS `4F548A` displayed identically on BOTH endpoints**; both marked verified |
| 6 | Browser → native file send | CONFIRMED | `b2n-test.txt` (108 B) saved to `~/Downloads`; sha256 `2672079d…31bec` matches sent bytes exactly |
| 7 | Native → browser file send | CONFIRMED | Native `send_file.signal` → browser `[TRANSFER] Completed receiving n2b-test.txt`; downloaded file sha256 `ee4ff333…1258e3` matches source exactly |
| 8 | Disconnect → return to discovery | CONFIRMED (native path) | Native-initiated disconnect: confirm dialog → "Disconnected: connection closed" → Devices/discovery view, still ONLINE. Browser reloaded and re-discovered the peer cleanly. |

**Step 8 caveat (INSUFFICIENT EVIDENCE, browser-initiated path only):** clicking the
browser's own "Disconnect" button via the automation harness stalled the page
renderer (CDP `Input.dispatchMouseEvent` timeout — WT/WASM teardown blocking the
main thread under automation). The tab recovered fully on reload and re-registered
+ re-discovered the peer. Native-initiated disconnect was clean end-to-end. Whether
the renderer stall reproduces under normal human interaction was not established.

**Bonus finding:** this is the first runtime validation of **W2-RUNTIME-VALIDATION-1**
(Chrome-on-HTTPS WebTransport session with the native daemon), which was PENDING.
Both file directions completed over WT with cert-hash pinning and full BTR. → CONFIRMED.

---

## App ↔ App (Mac Studio ↔ MacBook) — BLOCKED

**Blocker:** both MacBook nodes are offline on Tailscale — `evans-macbook-pro`
(100.93.60.117) last seen ~8 min ago, `eos-macbook-pro` (100.96.250.55) last seen
~1 day ago; `ssh` to both times out at the TCP layer. The checklist requires two
physical machines running the app with GUI interaction (accept + SAS compare) on
both ends; a powered-down/asleep peer cannot be driven remotely.

**Partial evidence (not a substitute for the run):**
- x86_64 daemon cross-build capability is present: `native/macos/build-x86_64/`,
  `deploy-macbook.sh` (builds x86_64, rsyncs to MacBook, registers firewall).
  The checklist's own noted blocker was "x64 daemon untested."
- The App↔App data path uses the same WebTransport/WS + BTR session machinery just
  runtime-confirmed in App↔Browser, so the transport core is exercised — but the
  two-native-peer discovery + mutual-accept flow specifically was not run.

**To unblock:** wake a MacBook on Tailscale (no standalone VPN — see
`macstudio-mobile-access-vpn`), `bash native/macos/deploy-macbook.sh`, then run the
8-step App↔App checklist with a human present for the accept/SAS-compare steps.
