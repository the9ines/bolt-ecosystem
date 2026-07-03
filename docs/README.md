# docs/ — Frozen Archive + Audit Registry

As of 2026-07-03 this folder is the **historical layer** of the Governance OS.
Everything here is consult-freely, update-never — except the two active exceptions
below. The living surfaces are:

| What | Where |
|------|-------|
| Current state | `../os/DASHBOARD.md` (generate: `../os/bin/status.sh`) |
| Intent | `../os/NOW.md` |
| Ongoing history | `../os/log/journal.md` |
| New decisions | `../os/log/decisions/` |
| Rules | root `CLAUDE.md` + `../os/rules/` (routing: `../os/rules/doc-routing.md`) |

## Still active in this folder

- **`AUDIT_TRACKER.md`** — append-only registry of audit finding IDs. New findings
  still get IDs here; its status columns are historical snapshots.
- **`AUDITS/`**, **`evidence/`** — immutable dated audit sources and phase evidence.

## Frozen history (banner-marked)

STATE, ROADMAP, CHANGELOG, GOVERNANCE_WORKSTREAMS, FORWARD_BACKLOG, DOC_ROUTING
(superseded by `../os/rules/doc-routing.md`), SECURITY_MODEL (extracted verbatim to
`../os/rules/security-model.md`), PROTOCOL_COMPLIANCE, PROTOCOL_ENFORCEMENT,
RUST_CORE_PLAN — plus the dated decision memos (ADR-001, BTR5_DECISION_MEMO,
BTR5_EVIDENCE_INDEX) and `archive/`.
