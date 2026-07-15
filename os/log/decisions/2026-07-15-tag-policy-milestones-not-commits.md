# Decision: Tag Milestones and Releases, Not Every Commit

> **Date:** 2026-07-15
> **Status:** Adopted. Ecosystem governance policy.
> **Scope repo:** ecosystem-wide (every repo + the root governance layer).
> **Supersedes:** the ambiguous prior norm of tagging most/every commit (the parked
> tag-reconciliation question in `os/NOW.md`).

## Context

The dashboard flags "untagged work at HEAD" in most repos, and the tag-reconciliation question
sat parked: *"tag the current HEADs once, or codify 'tag releases, not every commit'."* Tagging
every commit inflates the tag namespace and turns "untagged work" into a permanent nag instead of
a signal. Detailed history is already carried, per commit, by `os/log/journal.md` (ecosystem
events) and per-repo `docs/CHANGELOG.md` (releases).

## Decision

1. Tag **completed workstream checkpoints and releases**, not every commit. A tag marks a stable,
   shippable point — a landed workstream (e.g. a Governance OS phase set, an EA remediation track)
   or a product release.
2. **Routine commits do not each require a tag.** The journal + CHANGELOGs carry the detailed
   history; tags mark where to return to.
3. **Immutable-tag discipline stands, unchanged:** once pushed, a tag is NEVER moved, deleted, or
   reused (`CLAUDE.md` Tag Discipline + the Destructive Command Ban). The per-repo tag formats are
   unchanged.
4. The dashboard's "untagged work at HEAD" Signal is therefore a **checkpoint prompt** — "is this
   HEAD a milestone worth a tag?" — not a per-commit debt.

## Consequence for the pending checkpoint

Governance OS v2 (Phases 1-5) and the EA / Track B remediation are complete but untagged. Under
this policy they are milestone-tag candidates: one tag per completed workstream at the relevant
repo HEAD (root, bolt-daemon, localbolt-app, localbolt-v3, and optionally
bolt-rendezvous / localbolt), after pushing the unpushed commits. Creating those tags and any push
require explicit human authorization (No-Push policy); **none are created here.** The
bolt-core-sdk spike branch is not a tag candidate (unmerged / local-only).

## Out of scope

No tags created, no pushes. This ADR records the policy only.
