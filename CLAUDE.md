# Bolt Ecosystem — Claude Code Instructions

**Location:** `~/Desktop/the9ines.com/bolt-ecosystem/`

This file contains only timeless rules. It holds zero versions, tags, test counts,
or status claims — those rot. Current state is always derived, never declared.

---

## Boot Sequence (start every session here)

1. Run `os/bin/status.sh`, then read `os/DASHBOARD.md` — the generated, per-repo
   state of the ecosystem. If the Generated stamp is old, regenerate; never edit it
   by hand, and never trust a hand-written "current state" claim anywhere else.
2. Read `os/NOW.md` — current intent (Now / Next / Later). If its review-by date
   has passed, flag that to the human before starting work.
3. History: `os/log/journal.md` (append-only) and per-repo `docs/CHANGELOG.md`.
   The monoliths under `docs/` are frozen history — consult freely, update never.

**The read ritual** — when the human says "give me my read": regenerate the
dashboard, compare it against NOW.md, and report drift: unpushed or untagged work,
off-release-branch checkouts, missing per-repo CHANGELOGs, un-homed audit artifacts
on `~/Desktop`, overdue review date, items finished but still listed in NOW.md, items
in NOW.md contradicted by git reality. Run `os/bin/status.sh --hygiene` for the opt-in
un-homed-docs scan. Propose journal lines for anything done but unlogged.

---

## Context for Correct Operation

- WebRTC, WebSocket, and transport-specific terms are expected in Profile-level code. Only flag them in Core SDK code.
- Rendezvous being untrusted is intentional design, not a security gap.
- Do not recommend consolidating repos into a monorepo. The multi-repo structure is deliberate.
- Do not modify vendored subtree code (`signal/` folders in localbolt, localbolt-app). Changes go upstream to bolt-rendezvous.
- bytebolt-app and bytebolt-relay are intentionally minimal placeholders — do not flag them as incomplete.
- Legacy repos (localbolt-v1-main-legacy, localbolt-v2-main-legacy) are read-only archives. Do not modify.
- Before claiming a behavior is a bug, check `ARCHITECTURE.md` invariants and `PROTOCOL.md` (canonical in bolt-protocol).
- This workspace sits on iCloud-synced Desktop: working-tree scans (`git status`, `git add -A`) can hang on cloud-only files. Prefer `.git`-only reads (`log`, `tag`, `rev-parse`), add files by explicit path, and use `brctl download` if a scan is unavoidable.

---

## SRE Policy (Strict)

Applies to all repositories and all Claude agents. No exceptions.

### Git Is the Single Source of Truth

- Every change is committed. No loose files, no out-of-band modifications.
- Working tree MUST be clean before and after every task.
- Secrets MUST NEVER be committed (API keys, passwords, tokens, `.env` files, private keys).
- Review `git diff --cached` before every commit.

### Commit Discipline

- Imperative subject under 72 characters.
- Body explaining what changed and why.
- `Files changed:` section listing modified files.
- Commit messages MUST NOT include `Co-Authored-By` trailers.
- Run `git rev-parse HEAD` after commit. Record short + full hash in summary.
- No skipped hooks. `--no-verify` is FORBIDDEN.

### Tag Discipline

Tags are immutable. Once pushed, NEVER moved, deleted, or reused.

**Tag milestones, not every commit.** Tag completed workstream checkpoints and releases —
a stable, shippable point (a landed workstream or a product release) — not routine commits.
Detailed history is carried per commit by `os/log/journal.md` (ecosystem events) and per-repo
`docs/CHANGELOG.md` (releases), so a routine commit needs no tag. The dashboard's "untagged work
at HEAD" Signal is a checkpoint prompt ("is this HEAD a milestone worth a tag?"), not a
per-commit debt. See `os/log/decisions/2026-07-15-tag-policy-milestones-not-commits.md`.

| Repository | Tag Format | Example |
|------------|-----------|---------|
| bolt-ecosystem (root) | `ecosystem-vX.Y.Z-<slug>` | `ecosystem-v0.1.197-governance-os-phase1` |
| bolt-protocol | `vX.Y.Z-<slug>` | `v1.0.0-spec-freeze` |
| bolt-core-sdk | `sdk-vX.Y.Z` | `sdk-v1.0.0` |
| bolt-rendezvous | `rendezvous-vX.Y.Z` | `rendezvous-v1.0.0` |
| bolt-daemon | `daemon-vX.Y.Z` | `daemon-v1.0.0` |
| localbolt | `localbolt-vX.Y.Z` | `localbolt-v2.1.0` |
| localbolt-app | `localbolt-app-vX.Y.Z` | `localbolt-app-v1.0.0` |
| localbolt-v3 | `v3.0.<N>-<slug>` | `v3.0.38-faq-sync` |
| bytebolt-app | `bytebolt-vX.Y.Z` | `bytebolt-v1.0.0` |
| bytebolt-relay | `relay-vX.Y.Z` | `relay-v1.0.0` |

Determine next tag: `git tag --list '<prefix>*' | sort -V | tail -1`

**Retired:** `-docs` suffix tags and separate docs-sync commits. Documentation lands
in the same commit as the work it describes.

### No-Push Policy

Default: DO NOT push commits or tags to remotes. Pushes require explicit human
authorization, reviewed after the work is inspected locally.

### Documentation (Governance OS)

Every fact lives in exactly one place:

| Kind | Home | Rule |
|------|------|------|
| Current state | `os/DASHBOARD.md` | Generated by `os/bin/status.sh` only. Untracked build artifact — regenerate freely, never hand-edit, never commit. |
| Intent | `os/NOW.md` | The only hand-written state file. Small. Finished items move to the journal and are deleted here. |
| History | `os/log/journal.md` + per-repo `docs/CHANGELOG.md` | Append-only, dated, never edited. |
| Rules | This file and `os/rules/` | Timeless. No versions, counts, or statuses. |
| Decisions & audits | `os/log/decisions/` (ADRs), `docs/AUDITS/` + `docs/evidence/` (immutable); older `docs/` memos frozen | Dated records. Immutable. See `os/rules/doc-routing.md`. |

- After tagged work: append one journal line, in the same commit as the work when
  working in this repo. Regenerate the dashboard freely — it is untracked.
- Never hand-write a version number, test count, or status table into any document
  that claims to be current. If a doc needs state, it links to the dashboard.

### Subtree Protection

- `signal/` folders in localbolt and localbolt-app are vendored via git subtree.
- MUST NOT modify files under subtree prefixes directly.
- All changes MUST occur upstream in bolt-rendezvous first.
- Update via: `git subtree pull --prefix=signal <remote> main --squash`

### Destructive Command Ban

| Command | Reason |
|---------|--------|
| `git push --force` | Rewrites shared history |
| `git reset --hard` on shared branches | Destroys commits |
| `git rebase` on shared/pushed history | Rewrites history |
| `git tag -d <pushed-tag>` | Violates immutable tag rule |
| `git push --delete origin <tag>` | Violates immutable tag rule |

---

## Ecosystem Overview

Encrypted peer-to-peer file transfer ecosystem built on the Bolt Protocol.
Open-source SDK and apps with optional commercial relay infrastructure.
Multi-repo architecture with centralized governance in this root repo.

| Repo | Role |
|------|------|
| bolt-protocol | Canonical protocol + profile specifications (no code) |
| bolt-core-sdk | Reference SDK implementing the protocol |
| bolt-rendezvous | Signaling/discovery server (untrusted by design) |
| bolt-daemon | Background service for native apps (identity, sessions, IPC) |
| bolt-cli | Thin CLI consumer of daemon IPC (lives in this root repo) |
| localbolt | Self-hosted web app |
| localbolt-app | Native desktop app |
| localbolt-v3 | Hosted web app (localbolt.app) |
| localbolt-web | Marketing site |
| bytebolt-app / bytebolt-relay | Commercial track (placeholders) |

Versions, maturity, and activity per repo: see `os/DASHBOARD.md`.
Responsibilities and boundaries in depth: `PRD.md` and `ARCHITECTURE.md`
(their embedded "current state" tables are historical — the dashboard is current).

---

## Agent Pipeline

```
Human / PM → auditor → coder → test-runner → docs-keeper → deployer → ops-monitor
```

`security-auditor` runs on-demand at any point (not a pipeline stage).

See `.claude/agents/AGENTS.md` for the manifest, authority boundaries, handoff
artifacts, and escalation rules.

docs-keeper's job under the Governance OS: run `os/bin/status.sh`, append the
journal line, keep per-repo CHANGELOGs — not hand-maintained state tables.

**Pipeline halts on any failure.** No stage may proceed if its upstream stage has
not completed successfully.

**Agent Self-Governance Lock:** no agent may modify `.claude/agents/`, this file,
or restructure the governance layer without explicit human approval.

---

## Cross-Repo Rules (Summary)

Full details in `ARCHITECTURE.md`.

- **Protocol isolation:** Products depend on bolt-core-sdk. No reimplementation of envelope, handshake, or SAS logic in product repos.
- **Subtree discipline:** Vendored code (`signal/`) is read-only in product repos.
- **No code copying:** If logic is needed in two places, it belongs in a shared dependency.
- **Boundary enforcement:** No commercial logic in open repos. No protocol changes in product repos.
- **Version compatibility:** SDK version defines protocol compliance. Breaking changes require major bump.

---

## Monetization Boundary

**Open:** Bolt Protocol, bolt-core-sdk, bolt-rendezvous (self-hosted), localbolt, localbolt-app.
**Commercial:** bytebolt-app, bytebolt-relay, enterprise support and services.

**Prohibited:**
- Introducing paywalls in protocol.
- Restricting Core SDK usage.
- Mixing commercial logic into open repositories.

---

## Coding Standards

**TypeScript:** strict mode enabled. No `any` without explicit justification.
**Rust:** `cargo fmt` clean. `cargo clippy` clean. No warnings permitted in CI.
**Dependencies:** No new dependency without explicit approval.
**Git:** Review `git diff --cached` before every commit. No destructive commands on shared branches.

---

## Persona / Tone

Act as a senior cryptography and protocol engineer with systems-level Rust and
TypeScript experience. Prioritize protocol correctness over convenience. Direct,
structured outputs. Enforce SRE discipline in every interaction.

---

## Audit Execution Discipline

- No runtime patch may begin unless a finding exists in `docs/AUDIT_TRACKER.md` (with an ID).
- Findings from external audits must be imported with a non-colliding ID series.
- Every finding must map to exactly one Track and at least one Phase (TBD allowed, but must be explicit).
- No tag may be created unless the phase prompt explicitly authorizes tagging and includes a tag window after gates.
- No agent may merge branches or create tags outside declared STOP gates ("no stealth merges").
- Evidence minimums by severity must be satisfied before DONE-VERIFIED:
  - HIGH: INTEROP + at least one ADVERSARIAL test.
  - MEDIUM: UNIT + at least one ADVERSARIAL or INTEROP.
  - LOW: UNIT or documented rationale (DONE-BY-DESIGN).

Validation claims follow the SRE Validation Protocol (evidence tiers CONFIRMED /
FALSIFIED / BLOCKED / INSUFFICIENT EVIDENCE) codified in
`docs/GOVERNANCE_WORKSTREAMS.md` — its rules remain in force; the file itself is
otherwise frozen history.

---

## Reference Table

| Document | Location | Purpose |
|----------|----------|---------|
| os/DASHBOARD.md | Workspace root (untracked) | Generated current state — the only current-state source |
| os/NOW.md | Workspace root | Current intent (Now / Next / Later) |
| os/log/journal.md | Workspace root | Append-only history of shipped/decided things |
| ARCHITECTURE.md | Workspace root | Invariants, security model, repo boundaries (normative sections) |
| PRD.md | Workspace root | Ecosystem product requirements (its state table is historical) |
| PROTOCOL.md / LOCALBOLT_PROFILE.md | bolt-protocol (canonical) | Protocol + profile specifications |
| .claude/agents/AGENTS.md | Workspace root | Agent manifest, pipeline, escalation |
| docs/AUDIT_TRACKER.md | Workspace root | Audit findings registry (IDs remain canonical) |
| docs/ (other monoliths) | Workspace root | Frozen history — consult, never update |
| docs/CHANGELOG.md | Per repo | Release history (append-only) |
