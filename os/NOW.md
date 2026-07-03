# NOW — Bolt Ecosystem Intent

> The only hand-written state file in the ecosystem. Keep it under ~60 lines.
> When an item finishes: append one line to `os/log/journal.md`, then DELETE it here.
> Where things stand is NOT recorded here — run `os/bin/status.sh` and read `os/DASHBOARD.md`.
>
> **Review by: 2026-07-17.** Reading this later than that? Say "give me my read".

Seeded 2026-07-03 from the last live items in the frozen backlog
(docs/GOVERNANCE_WORKSTREAMS.md, docs/ROADMAP.md). Prune anything no longer wanted.

## Now

- _(nothing in flight — transport unification closed at Phases 1+2+cleanup; see journal.)_

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
