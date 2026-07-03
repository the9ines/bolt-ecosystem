# os/rules/ — The Timeless Kernel

Rules only. Nothing in this folder may contain a version number, test count, tag
position, or status claim — those rot, and they live elsewhere (state → `os/DASHBOARD.md`,
history → `os/log/journal.md`, intent → `os/NOW.md`).

Agent-behavioral rules (SRE policy, commit/tag discipline, No-Push, doc homes) live in
the root `CLAUDE.md`. This folder holds ecosystem law:

| File | Law |
|------|-----|
| `security-model.md` | Trust boundaries, attacker model, assets, security invariants, BTR model, compromise analysis |
| `validation-protocol.md` | How validation claims are made: result classification + evidence tiers |
| `phase-discipline.md` | Universal scope guardrails and the phase-gate checklist |
| `doc-routing.md` | Where every kind of document lives; what is frozen |
| `btr-vector-policy.md` | BTR test-vector authority, regeneration, review requirements |
| `localbolt-core-drift-runbook.md` | Operational runbook: localbolt-core version-pin and drift checks |

Provenance: extracted 2026-07-03 from the pre-OS monoliths (see `doc-routing.md`).
Changing a rule here requires explicit human approval, same as the originals.
