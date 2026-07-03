# NOW — Bolt Ecosystem Intent

> The only hand-written state file in the ecosystem. Keep it under ~60 lines.
> When an item finishes: append one line to `os/log/journal.md`, then DELETE it here.
> Where things stand is NOT recorded here — run `os/bin/status.sh` and read `os/DASHBOARD.md`.
>
> **Review by: 2026-07-17.** Reading this later than that? Say "give me my read".

Seeded 2026-07-03 from the last live items in the frozen backlog
(docs/GOVERNANCE_WORKSTREAMS.md, docs/ROADMAP.md). Prune anything no longer wanted.

## Now

- **Transport session unification (frame-trait).** Primary workstream. Scope:
  `os/log/decisions/2026-07-03-transport-session-unification.md`. Behavior-preserving;
  protocol/wire untouched.
  - **Phase 1 DONE** (daemon `4ca6192`, tag `daemon-v0.2.52-transport-unify-p1`): WS+QUIC
    unified onto one session loop via the `session_frame` seam; duplicate QUIC loops deleted.
  - **Phase 2 DONE** (daemon `8248390`, tag `daemon-v0.2.53-transport-unify-p2`): WebTransport
    folded onto the shared loop via `session_frame::{WtFrameSink, wt_message_stream}`;
    `wt_endpoint.rs`'s `run_message_loop` deleted (~280 lines); WT inherits BTR + `transfer.*`.
    `ipc_tx` threaded correctly (the one real risk); 378 tests green; 3-agent adversarial
    review CLEAN. All three transports now share ONE session loop.
  - **NOW: WT session-path integration test** — the one open item. No test executes the WT
    post-HELLO session path (pre-existing gap; never covered even for the recovered May code).
    Port `ws_endpoint::quic_session_emits_ipc_transfer_events_for_send_and_receive` to WT
    (in-process wtransport client doing HELLO + a file chunk; assert `transfer.*` IPC + saved
    bytes). Runtime browser-over-WT check was blocked by an environmental Chrome WT
    cert-handshake issue (unrelated; WT endpoint confirmed up).
  - **Phase 3** (opportunistic handshake unify) and **Phase 4** (centralize/de-race
    ACTIVE_SESSION) remain. Plus deferred cosmetic: neutralize the shared loop's `[WS_*]`
    log tags (QUIC + now WT log under them) and rename the misnamed `ws_endpoint.rs` (it
    holds the shared session logic, not WS-specific).

- **BUG: app↔app initiator never dials after accept.** Found 2026-07-03 running the
  App↔App validation cross-machine (Studio ↔ M5, same LAN). Discovery + accept work,
  but neither daemon ever dials the other → both apps hang at "waiting for encrypted
  channel." Root-caused: headless daemon↔daemon over the same LAN establishes a full
  session (SAS matched, BTR) and transfers both directions (checksum-verified), so the
  transport/crypto/daemon are sound. The gap is native-app wiring: after the peer
  accepts, the initiator never hands the peer's LAN address to its daemon (connect_remote
  / FFI connect). Fix lives in localbolt-app. Evidence:
  `docs/evidence/MANUAL_VALIDATION_2026-07-03.md` (see UPDATE section).

## Next

- **Tag reconciliation** — the dashboard flags untagged work at HEAD in most repos
  (run `os/bin/status.sh` for live counts; includes the STATE-retirement doc commits).
  Decide: tag the current HEADs once, or codify "tag releases, not every commit."
  (Still parked — Evan unsure. Now larger: recovered-code + validation commits added.)

## Later

- **W2-RUNTIME-VALIDATION-1 follow-up** — runtime-CONFIRMED 2026-07-03 (WT over HTTPS
  with cert-hash pinning + full BTR, both file directions; see evidence file). If CI
  can assert it, add a gate; otherwise this item is closed.
- **M4-PARITY-1** — cross-product contract parity tests in CI (bolt-core-sdk,
  localbolt-v3, localbolt-app).
- **ECOSYSTEM-DOCS-1** — bolt-core-sdk integration guide for external adopters.
- **SIDECHANNEL-REDUCTION-1** — product exception audit (quality, blocks nothing).

## Shelved (not now)

- **ByteBolt** — commercial global tier (relay backbone + app). Deferred per Evan
  2026-07-03: build and harden the open base first. The relay is a connectivity/
  reliability backbone only — zero server-side storage, strictly P2P, forwards opaque
  ciphertext. The transport-unification work makes the core *ready* for a relay
  transport but builds nothing ByteBolt. Do not start ByteBolt work until un-shelved.
