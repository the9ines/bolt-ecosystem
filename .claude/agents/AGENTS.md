# Agent Team Manifest

> **Version:** 1.1
> **Last Updated:** 2026-02-23
> **Status:** Active

This document defines the multi-agent coordination model for the Bolt ecosystem. All agents operate under fail-closed coordination with single-authority-per-domain enforcement.

---

## Core Design Principles

1. **Single Authority Per Domain** — Only one agent owns execution for each operational domain.
2. **Fail-Closed Coordination** — If any required stage fails or is skipped, downstream agents must halt.
3. **No Implicit Autonomy** — Agents cannot act without explicit upstream approval or defined trigger.
4. **Deterministic Handoff Chain** — Each stage has defined inputs and outputs.
5. **Read vs Write Separation** — Monitoring agents never mutate state. Execution agents never self-approve.
6. **Human Override Authority** — Human authority supersedes all agent constraints. Process evolves at human direction.

---

## Authority Boundaries

| Agent | Domain | Authority | Mutates State |
|-------|--------|-----------|---------------|
| `auditor` | Prompt + output review | Approval decisions only | No |
| `coder` | Code changes | Write code, commit, tag | Yes (code only) |
| `test-runner` | Quality validation | Run tests, report results | No |
| `docs-keeper` | Documentation | Update owned doc files | Yes (docs only) |
| `deployer` | Build + deployment | Build, transfer, deploy | Yes (deploy only) |
| `ops-monitor` | System health | Read-only monitoring | No |
| `security-auditor` | Security + protocol invariants | Audit and report | No |
| `reporter` | Post-execution verification | Generate after-action reports | No |
| `context-keeper` | Project state updates | Update STATUS.md, project_context.md, ROADMAP.md | Yes (state files only) |

No shared execution authority. Each domain has exactly one owner.

---

## Required Execution Order (Pipeline)

```
Human / Codex PM
    |
    v
auditor (approval gate)
    |
    v
coder (implementation)
    |
    v
test-runner (validation gate)
    |
    v
reporter (after-action report)
    |
    v
context-keeper (state file updates)
    |
    v
docs-keeper (documentation sync)
    |
    v
deployer (deployment authority)
    |
    v
ops-monitor (post-deploy verification)
```

`security-auditor` runs on-demand at any point. It is not a pipeline stage.

When orchestrated via `bolt-loop.sh`, Codex PM generates task prompts (read-only) and reviews after-action reports. The script routes prompts through the auditor → coder → reporter → context-keeper pipeline automatically.

**Pipeline halts on any failure.** No stage may proceed if its upstream stage has not completed successfully.

---

## Required Handoff Artifacts

| From | To | Artifact |
|------|----|----------|
| Human/PM | auditor | Implementation prompt or change request |
| auditor | coder | Approval decision (APPROVED / NEEDS REVISION / REJECTED) |
| coder | test-runner | Commit SHA + diff summary + repo name |
| test-runner | docs-keeper | Structured PASS/FAIL report with test counts |
| docs-keeper | deployer | Doc change summary (or "no doc changes required") |
| deployer | ops-monitor | Deployment report + tag + deploy timestamp |
| coder | reporter | Commit SHA + diff summary + task prompt |
| reporter | context-keeper | Structured after-action report (AAR) |
| reporter | Codex PM | AAR (via bolt-loop.sh stdout capture) |
| context-keeper | (state update) | Updated STATUS.md, project_context.md, ROADMAP.md |
| ops-monitor | (terminal) | Health report (HEALTHY / DEGRADED / FAILED) |

Missing or malformed artifacts halt the pipeline.

### Test-Runner PASS Artifact Definition

The test-runner PASS artifact is the structured report that gates deployment. It MUST contain:

```markdown
## Test Runner Report
### Pipeline Gate: PASS
### Repo: [repository name]
### Commit: [full SHA]
### Tag: [pending tag name]
### Timestamp: [ISO 8601]
### Commands Run: [exact commands executed]
### Results
| Suite | Total | Passed | Failed | Errors | Skipped |
|-------|-------|--------|--------|--------|---------|
| [suite] | N | N | N | N | N |
### Lint: PASS
### Build: PASS
### Verdict: PASS — deployer may proceed
```

If any required field is missing or any result is FAIL, the artifact is invalid and deployer MUST NOT proceed.

---

## Escalation Rules

Agents must halt and request human input when:

- Protocol invariant violation detected (see ARCHITECTURE.md)
- Security invariant violation detected (nonce, key lifecycle, TOFU, replay)
- Deploy verification fails
- Tag lineage cannot be proven
- Unexpected state detected (dirty tree, unknown processes, resource exhaustion)
- Conflicting agent outputs (e.g., test-runner PASS but security-auditor finds regression)
- Any action would be irreversible (tag push, production state change, package publish)
- **If a change affects protocol semantics, cryptographic behavior, or public API surface, auditor MUST require explicit human approval even if tests pass**
- **If tests pass but behavior changes, auditor MUST flag "behavioral change with green tests"**

Escalation format:
```
## ESCALATION REQUIRED

**Agent:** [agent name]
**Repo:** [repository name]
**Reason:** [specific reason]
**Context:** [what was being attempted]
**Options:** [possible paths forward]
**Recommendation:** [agent's suggested action, if any]
```

---

## Agent Self-Governance Lock

- Agents MUST NOT modify `.claude/agents/`, `AGENTS.md`, or workspace `CLAUDE.md` without explicit human approval.
- No agent may autonomously "improve" or restructure the governance layer.
- Changes to agent definitions, pipeline order, or authority boundaries require human direction.

---

## Agent Spawn Rules

| Initiator | May Spawn |
|-----------|-----------|
| Human / PM | Any agent |
| deployer | ops-monitor (post-deploy health check only) |
| All other agents | None |

`security-auditor` runs only on explicit human or PM request.

No agent may spawn itself. No circular spawn chains.

---

## Cross-Repo Scope

This workspace contains multiple repositories. Agents operate across all repos from this centralized control plane.

When working in any repo, agents must:
- Identify which repo they are operating in
- Use that repo's tag format (see workspace CLAUDE.md)
- Respect subtree boundaries (signal/ folders are read-only)
- Not modify files outside the target repo without explicit instruction

---

## Agent File Registry

| File | Role |
|------|------|
| `auditor.md` | Prompt reviewer + output auditor |
| `coder.md` | Implementation executor |
| `test-runner.md` | Quality gate |
| `docs-keeper.md` | Documentation maintainer |
| `deployer.md` | Build + deploy authority |
| `ops-monitor.md` | Read-only system health |
| `security-auditor.md` | Security + protocol invariant auditor |
| `reporter.md` | Post-execution verification + AAR generation |
| `context-keeper.md` | Project state file updater |
