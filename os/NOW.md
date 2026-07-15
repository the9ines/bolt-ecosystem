# NOW — Bolt Ecosystem Intent

> The only hand-written state file in the ecosystem. Keep it under ~60 lines.
> When an item finishes: append one line to `os/log/journal.md`, then DELETE it here.
> Where things stand is NOT recorded here — run `os/bin/status.sh` and read `os/DASHBOARD.md`.
>
> **Review by: 2026-07-29.** Reading this later than that? Say "give me my read".

## Now

- **Governance OS v2 migration** — the delta that homes audit evidence and retires stale
  status docs. Phase 1 (evidence homed + tracker custody repaired) and Phase 2 (routing law +
  status vocabulary) are DONE; Phase 3 (reconcile NOW / journal / ADRs — this) is in progress;
  Phase 4 (thin `docs/AUDIT_TRACKER.md` to an index) and Phase 5 (sensor Signals + docs-keeper
  owner) remain. Authority + full plan: `os/log/decisions/2026-07-15-governance-os-v2-design.md`.
  Each phase needs explicit authorization.

## Next

- **EA1 — real device verification (SAS / pairing)** — the gating security decision. Red-teamed
  twice (HAS-BLOCKERS); direction = do NOT hand-roll, adopt a vetted PAKE WITH an external
  cryptographer (`os/log/decisions/2026-07-15-ea1-adopt-pake-direction.md`). The Rust→WASM spike
  is done but UNMERGED and not productized. EA1 blocks all "verified" / persistent-pin behavior,
  including EA4's full interactive-prompt fix. Decision for Evan: when to engage the cryptographer.
- **Tag reconciliation** — the dashboard flags untagged work at HEAD in most repos (run
  `os/bin/status.sh` for live counts). Decide: tag the current HEADs once, or codify "tag
  releases, not every commit." (Parked — Evan's call.)

## Later

- **W2-RUNTIME-VALIDATION-1 CI gate** — WT-over-HTTPS runtime was CONFIRMED 2026-07-03 (evidence
  homed). If CI can assert it, add a gate; otherwise close.
- **M4-PARITY-1** — cross-product contract parity tests in CI (bolt-core-sdk, localbolt-v3, localbolt-app).
- **ECOSYSTEM-DOCS-1** — bolt-core-sdk integration guide for external adopters.
- **SIDECHANNEL-REDUCTION-1** — product exception audit (quality, blocks nothing).

## Shelved (not now)

- **ByteBolt** — commercial global relay tier. SHELVED per Evan (build and harden the open base
  first). Its relay trust boundary is defined ONCE in
  `os/log/decisions/2026-07-15-bytebolt-relay-trust-boundary.md` — do not restate it elsewhere.
  Do not start ByteBolt work until un-shelved.
