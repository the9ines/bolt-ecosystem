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

## App ↔ App (Mac Studio ↔ MacBook) — RESOLVED (see UPDATE at bottom)

> The BLOCKED status below was the morning state. It was later unblocked the same
> day (M5 MacBook came online on the same LAN) and run to a definitive conclusion.
> **See "## App ↔ App — UPDATE" at the end of this file.**

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

---

## App ↔ App — UPDATE (unblocked + root-caused, 2026-07-03 afternoon)

M5 MacBook (`Evans-MacBook-Pro`, arm64) came online on the **same LAN** as the
Studio (Studio `192.168.4.210`, M5 `192.168.4.27`). Deployed the arm64
`LocalBolt.app` (with the recovered code, daemon `a45b76b`) to the M5 via rsync
(firewall step skipped intentionally). Ran the GUI checklist, then a headless
root-cause pass. Split result:

### GUI app↔app — FALSIFIED (hangs)

Steps 1–4 CONFIRMED: both apps launched, registered on the cloud rendezvous, and
**discovered each other cross-machine** (Studio's device list showed "Evan's
MacBook Pro"). Human tapped Connect on the Studio; the M5 showed the incoming
request; human accepted on the M5.

Then it **hung** — both apps stuck at "waiting for encrypted channel." Diagnosis:
`lsof` on both machines showed **zero TCP connections between the two daemons** on
any port. The network was fine (both daemon ports mutually reachable, TCP and UDP;
firewall not blocking). So after the accept, **neither daemon ever dialed the
other** — the dial is never issued.

### Headless daemon↔daemon — CONFIRMED (transport is sound)

To isolate app-layer vs daemon-layer, ran the two daemons directly (bypassing the
apps) and triggered a dial via the daemon's own `connect_remote.signal`
(`ws://192.168.4.27:9500`). Result — a **full cross-machine session**:

```
Studio (initiator)                     M5 (acceptor)
[WS_CLIENT] connected to ws://…:9500   [WS_SESSION] accepted TCP from 192.168.4.210
sent/received session-key              session-key exchange
sent HELLO                             HELLO ok, caps negotiated
[SAS] BE0FBF                           [SAS] BE0FBF          ← identical SAS
session established, BTR gen=0          session established, BTR gen=0
```

Then bidirectional file transfer over that session, **checksum-verified**:
- Studio → M5: `s2m-test.txt` → `sha256 cc26e2cf…f90b3` ✓ (exact match on M5)
- M5 → Studio: `m2s-test.txt` → `sha256 c03ecac6…a8faa2c` ✓ (exact match on Studio)

Capabilities negotiated both ways included `bolt.transfer-ratchet-v1` (BTR active).

### Conclusion — bug isolated to the app layer

The daemon-to-daemon path — discovery-independent dial, session-key exchange,
encrypted HELLO, SAS agreement, BTR, and bidirectional transfer — **works
perfectly cross-machine over the LAN.** The GUI app↔app hang is therefore **not a
transport, crypto, or daemon bug.** It is a **native-app wiring bug**: after the
remote peer accepts, the initiator app never hands the accepted peer's LAN address
to its daemon (via the connect_remote / FFI connect), so no dial is issued. This
path is exercised only in true two-machine app↔app, which is why neither the
browser↔app test nor the localhost suite caught it.

**Classification:** GUI app↔app transfer = FALSIFIED (app-layer connect not wired);
daemon transport core cross-machine = CONFIRMED (runtime, checksum-verified). New
bug filed to NOW.md: "app↔app: initiator never dials after accept."
