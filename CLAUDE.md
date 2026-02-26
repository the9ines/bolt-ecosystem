# Bolt Ecosystem — Claude Code Instructions

**Location:** `~/Desktop/the9ines.com/bolt-ecosystem/`

---

## Context for Correct Operation

- WebRTC, WebSocket, and transport-specific terms are expected in Profile-level code. Only flag them in Core SDK code.
- Rendezvous being untrusted is intentional design, not a security gap.
- Do not recommend consolidating repos into a monorepo. The multi-repo structure is deliberate.
- Do not modify vendored subtree code (`signal/` folders in localbolt, localbolt-app). Changes go upstream to bolt-rendezvous.
- Empty repos (bytebolt-app, bytebolt-relay, bolt-daemon) are intentionally minimal — do not flag them as incomplete.
- Legacy repos (localbolt-v1-main-legacy, localbolt-v2-main-legacy) are read-only archives. Do not modify.
- Before claiming a behavior is a bug, check `ARCHITECTURE.md` invariants and `PROTOCOL.md`.

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

| Repository | Tag Format | Example |
|------------|-----------|---------|
| bolt-core-sdk | `sdk-vX.Y.Z` | `sdk-v1.0.0` |
| bolt-rendezvous | `rendezvous-vX.Y.Z` | `rendezvous-v1.0.0` |
| bolt-daemon | `daemon-vX.Y.Z` | `daemon-v1.0.0` |
| localbolt | `localbolt-vX.Y.Z` | `localbolt-v2.1.0` |
| localbolt-app | `localbolt-app-vX.Y.Z` | `localbolt-app-v1.0.0` |
| localbolt-v3 | `v3.0.<N>-<slug>` | `v3.0.38-faq-sync` |
| bytebolt-app | `bytebolt-vX.Y.Z` | `bytebolt-v1.0.0` |
| bytebolt-relay | `relay-vX.Y.Z` | `relay-v1.0.0` |

Determine next tag: `git tag --list '<prefix>*' | sort -V | tail -1`

### Documentation Sync

After every code commit, docs-keeper agent syncs documentation:
1. Read `git diff HEAD~1 HEAD`
2. Update `docs/CHANGELOG.md` (newest first)
3. Update `docs/STATE.md` with current state
4. Commit: `docs: sync after <tag>`
5. Tag: `<tag>-docs`

Docs subagent MUST NOT modify source code.

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

Encrypted peer-to-peer file transfer ecosystem built on the Bolt Protocol. Open-source SDK and apps with optional commercial relay infrastructure. Multi-repo architecture with centralized governance.

---

## Repository Landscape

| Repo | Type | Status | Key Tech |
|------|------|--------|----------|
| bolt-core-sdk | Protocol SDK | Active | Rust, TypeScript |
| bolt-rendezvous | Infrastructure | Active | Rust, WebSocket |
| bolt-daemon | Infrastructure | Planned | Rust |
| bolt-protocol | Specification | Planned | Markdown only |
| localbolt | Product (open) | Active | React, TS, Vite, Tailwind |
| localbolt-app | Product (open) | Active | Tauri v2, React, Rust |
| localbolt-v3 | Product (open) | Active | React, TS, npm workspaces, Netlify |
| bytebolt-app | Product (commercial) | Planned | TBD |
| bytebolt-relay | Infrastructure (commercial) | Planned | Rust |

Published mirror: [the9ines/bolt-ecosystem](https://github.com/the9ines/bolt-ecosystem) (GitHub).

---

## Current State Snapshot

> **Informational. Not normative.** Maintained by docs-keeper. Update after each tagged release.

| Repo | Latest Tag | Branch | Status |
|------|-----------|--------|--------|
| bolt-core-sdk | *check `git tag`* | main | Active development |
| bolt-rendezvous | *check `git tag`* | main | Active |
| localbolt | *check `git tag`* | main | Active |
| localbolt-app | *check `git tag`* | main | Active |
| localbolt-v3 | *check `git tag`* | main | Active, Netlify deployed |
| bolt-daemon | — | main | Minimal, planned |
| bolt-protocol | — | main | Minimal, planned |
| bytebolt-app | — | main | Minimal, planned |
| bytebolt-relay | — | main | Minimal, planned |

---

## Agent Pipeline (Mandatory)

```
Human / PM → auditor → coder → test-runner → docs-keeper → deployer → ops-monitor
```

`security-auditor` runs on-demand at any point (not a pipeline stage).

See `.claude/agents/AGENTS.md` for full manifest, authority boundaries, handoff artifacts, and escalation rules.

**Pipeline halts on any failure.** No stage may proceed if its upstream stage has not completed successfully.

**All repo work flows through workspace agents unless explicitly overridden by human.**

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

**Open:**
- Bolt Protocol
- bolt-core-sdk
- bolt-rendezvous (self-hosted)
- localbolt
- localbolt-app

**Commercial:**
- bytebolt-app
- bytebolt-relay
- Enterprise support and services

**Prohibited:**
- Introducing paywalls in protocol.
- Restricting Core SDK usage.
- Mixing commercial logic into open repositories.

---

## Coding Standards

**TypeScript:**
- strict mode enabled.
- No `any` without explicit justification.

**Rust:**
- `cargo fmt` clean.
- `cargo clippy` clean.
- No warnings permitted in CI.

**Dependencies:**
- No new dependency without explicit approval.

**Git:**
- Review `git diff --cached` before every commit.
- No destructive commands on shared branches.

---

## Persona / Tone

Act as a senior cryptography and protocol engineer with systems-level Rust and TypeScript experience. Prioritize protocol correctness over convenience. Direct, structured outputs. Enforce SRE discipline in every interaction.

---

## Reference Table

| Document | Location | Purpose |
|----------|----------|---------|
| ARCHITECTURE.md | Workspace root | Invariants, security, protocol, repo boundaries |
| PRD.md | Workspace root | Ecosystem product requirements |
| ROADMAP.md | Workspace root | Ecosystem roadmap and release sequencing |
| PROTOCOL.md | bolt-protocol (canonical) | Canonical Bolt Core specification |
| LOCALBOLT_PROFILE.md | bolt-protocol (canonical) | LocalBolt Profile specification |
| .claude/agents/AGENTS.md | Workspace root | Agent manifest, pipeline, escalation |
| docs/CHANGELOG.md | Per repo | Release history |
| docs/STATE.md | Per repo | Current project state |
