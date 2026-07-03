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
  - **WT session-path test DONE** (daemon `2777357`, tag `daemon-v0.2.54-wt-session-test`):
    `wt_session_emits_ipc_transfer_events_on_receive` stands up a real wtransport client+server,
    drives `handle_incoming_session` through HELLO, sends an encrypted chunk, and asserts
    `transfer.started`/`transfer.complete` via the threaded `ipc_tx` + exact saved bytes. Closes
    the pre-existing gap and runtime-proves Phase 2. 379 tests green. Coverage gap CLOSED.
  - **Phase 3** (opportunistic handshake unify) and **Phase 4** (centralize/de-race
    ACTIVE_SESSION) remain. Plus deferred cosmetic: neutralize the shared loop's `[WS_*]`
    log tags (QUIC + now WT log under them) and rename the misnamed `ws_endpoint.rs` (it
    holds the shared session logic, not WS-specific).

- **FIXED: app↔app "waiting for encrypted channel" hang** (daemon `3404cac`, tag
  `daemon-v0.2.55-app-dial-fix`). Corrected root cause: NOT the localbolt-app Swift wiring
  (that's correct — it writes a QUIC-complete `connect_remote` signal with a WS fallback
  URL). The daemon tries QUIC first and falls back to WS on error, but the QUIC handshake
  had **no short timeout** — a stalled/unreachable QUIC peer blocked ~30s on the idle
  timeout before the (working) WS fallback fired, reading as a hang. Fix: `QUIC_CONNECT_TIMEOUT`
  (5s) in `connect_with_config`. Reproduced same-machine (fallback ~6s vs ~35s); regression
  test added; 380 tests green. Worth a 2-machine end-to-end confirmation when a MacBook is up,
  but the stall mechanism is fixed and verified.

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
