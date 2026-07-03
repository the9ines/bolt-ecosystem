# NOW — Bolt Ecosystem Intent

> The only hand-written state file in the ecosystem. Keep it under ~60 lines.
> When an item finishes: append one line to `os/log/journal.md`, then DELETE it here.
> Where things stand is NOT recorded here — run `os/bin/status.sh` and read `os/DASHBOARD.md`.
>
> **Review by: 2026-07-17.** Reading this later than that? Say "give me my read".

Seeded 2026-07-03 from the last live items in the frozen backlog
(docs/GOVERNANCE_WORKSTREAMS.md, docs/ROADMAP.md). Prune anything no longer wanted.

## Now

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
- **ByteBolt** — commercial track (bytebolt-app, bytebolt-relay still placeholders).
