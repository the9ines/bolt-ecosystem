# Phase Discipline

> **Status:** Normative. Universal rules extracted 2026-07-03 from
> `docs/GOVERNANCE_WORKSTREAMS.md`. Stream-specific guardrails (A/B/C/D/N/S streams)
> remain with their streams in that frozen record — they were scope contracts for
> those workstreams, not universal law.

## Universal Scope Guardrails

Apply to every phase of every workstream, always:

1. **No protocol semantic changes** unless a phase explicitly authorizes it.
2. **No wire-format changes** unless a phase explicitly authorizes it.
3. **No cryptographic changes** unless a phase explicitly authorizes it.
4. **Phase execution requires a separate phase prompt.** Codifying a workstream is not
   authorization to execute it.
5. **No stealth merges or tags.** No agent may merge branches or create tags outside
   declared STOP gates; tagging requires the phase prompt to authorize a tag window.
6. **New top-level workspace folders require explicit human approval** (ARCH-08).

## Phase Gate Checklist (Copy-Pasteable Template)

```
## Phase Report: [PHASE_ID]

**Tag:** [tag]
**Commit:** [short SHA] ([full SHA])
**Date:** [YYYY-MM-DD]

### Pre-Phase
- [ ] Working tree clean (tracked files; avoid full scans on iCloud-synced trees)
- [ ] Previous phase tag exists (or N/A for first phase)

### Implementation
- [ ] Only allowed files modified (list files changed)
- [ ] No protocol semantic changes
- [ ] No wire-format changes
- [ ] No cryptographic changes
- [ ] [If stream demands it] No public API changes

### Tests
- [ ] Existing tests pass (report: X tests, Y passed, Z failed)
- [ ] New tests pass (report: X tests, Y passed, Z failed)
- [ ] [If applicable] Golden vector tests pass
- [ ] [If applicable] `cargo clippy -- -D warnings` clean
- [ ] [If applicable] `scripts/check_no_panic.sh` passes

### Post-Phase
- [ ] Commit created (subject + body + Files changed)
- [ ] Local tag created (if the phase prompt authorized one)
- [ ] Journal line appended (`os/log/journal.md`)
- [ ] Working tree clean after commit
- [ ] DO NOT push (local only until the human authorizes)

### Files Changed
- `path/to/file` (new|modified|deleted)
```
