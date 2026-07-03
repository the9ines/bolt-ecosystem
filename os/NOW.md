# NOW — Bolt Ecosystem Intent

> The only hand-written state file in the ecosystem. Keep it under ~60 lines.
> When an item finishes: append one line to `os/log/journal.md`, then DELETE it here.
> Where things stand is NOT recorded here — run `os/bin/status.sh` and read `os/DASHBOARD.md`.
>
> **Review by: 2026-07-17.** Reading this later than that? Say "give me my read".

Seeded 2026-07-03 from the last live items in the frozen backlog
(docs/GOVERNANCE_WORKSTREAMS.md, docs/ROADMAP.md). Prune anything no longer wanted.

## Now

- **Governance OS Phase 2** — extract the timeless rules from the docs/ monoliths into
  `os/rules/`; banner-freeze the monoliths as historical archive.
- **Manual validation: App ↔ App** (Mac Studio ↔ MacBook) — checklist in
  GOVERNANCE_WORKSTREAMS "Manual Validation Checklist". Status was NOT YET EXECUTED.
- **Manual validation: App ↔ Browser** (native app + localbolt.app) — same checklist,
  also NOT YET EXECUTED.

## Next

- **Governance OS Phase 3** — sub-repo STATE.md stubs, update DOC_ROUTING.md,
  fix localbolt-v3/CLAUDE.md contradictions (its Co-Authored-By rule conflicts with root).
- **Tag reconciliation** — dashboard shows untagged work at HEAD in 7 repos
  (96 commits at root, 24 daemon, 21 v3, ...). Decide: tag the current HEADs once,
  or accept "tag releases, not every commit" going forward and codify that.
- **W2-RUNTIME-VALIDATION-1** — Chrome-on-HTTPS WebTransport session with the native
  daemon, runtime-confirmed. (Was PENDING; blocks M4-PARITY-1.)

## Later

- **M4-PARITY-1** — cross-product contract parity tests in CI (bolt-core-sdk,
  localbolt-v3, localbolt-app).
- **ECOSYSTEM-DOCS-1** — bolt-core-sdk integration guide for external adopters.
- **SIDECHANNEL-REDUCTION-1** — product exception audit (quality, blocks nothing).
- **ByteBolt** — commercial track (bytebolt-app, bytebolt-relay still placeholders).
