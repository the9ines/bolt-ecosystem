# SRE Enforcer

Global operational discipline enforcement across all repositories.

Loaded for ALL sessions in this workspace. Non-negotiable.

---

## 1. Clean Tree Rule

**Before any task:**
- Run `git status`.
- If working tree is dirty, STOP and report to user.
- Do not proceed with dirty tree unless user explicitly approves.

**After any task:**
- Run `git status`.
- Working tree MUST be clean before session ends.
- Zero untracked files. Zero modified files. Zero staged changes.

Failure: stop execution and report.

---

## 2. Commit Rule

Every code change MUST be committed. No exceptions.

Each commit MUST:
- Follow the commit message template (imperative subject, body, files changed section).
- Include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` trailer.
- Be tagged using the repository-specific format.
- Have its hash (short + full) recorded via `git rev-parse HEAD`.
- Have its short hash included in summary output to user.

"I'll commit later" is not permitted.

---

## 3. Tag Rule

- Every commit MUST be tagged.
- Tags are immutable. Once pushed, never moved or deleted.
- Tag format MUST match the repository convention (see release-ops.md).
- Determine next tag number via `git tag --list`.
- Push tags explicitly: `git push origin <tag>`.
- If a tag was applied to the wrong commit, create a new incremented tag.

---

## 4. Subtree Protection

If a file path falls under a vendored subtree (e.g. `signal/`):

- MUST reject the modification.
- MUST instruct user to make changes in the canonical upstream repository.
- MUST NOT apply patches, hotfixes, or "temporary" changes to vendored code.

The only way to update vendored code is `git subtree pull` from upstream.

---

## 5. Version Discipline

If a change in bolt-core-sdk modifies protocol semantics:

- MUST enforce appropriate semver bump (major for breaking, minor for additive, patch for fix).
- MUST require conformance tests to be updated or added.
- MUST verify no transport terms introduced in Core.

If a product repo updates its SDK dependency:

- MUST declare the new minimum SDK version.
- MUST verify tests pass with updated SDK.

---

## 6. Secret Protection

The following MUST NEVER be committed:

- `.env` files
- API keys
- Authentication tokens
- Passwords or credentials
- Private keys (identity or ephemeral)
- Signing keys

**Before every commit:**
- Run `git diff --cached` and inspect for secrets.
- If secrets are detected, unstage the file and report to user.

---

## 7. Destructive Command Ban

The following commands are unconditionally forbidden:

| Command | Reason |
|---------|--------|
| `git push --force` | Rewrites shared history |
| `git push --force-with-lease` | Still destructive on shared branches |
| `git reset --hard` on shared branches | Destroys commits |
| `git rebase` on shared/pushed history | Rewrites history |
| `git tag -d <pushed-tag>` | Violates immutable tag rule |
| `git push --delete origin <tag>` | Violates immutable tag rule |
| `git clean -f` without user approval | Destroys untracked files |

If any of these are needed, STOP and ask user for explicit confirmation with explanation of consequences.

---

## 8. Docs Sync Enforcement

After each code commit, the following MUST happen:

1. Spawn docs sync subagent (Task tool, subagent_type=general-purpose).
2. Subagent reads `git diff HEAD~1 HEAD`.
3. Subagent updates `docs/CHANGELOG.md` with new entry.
4. Subagent updates `docs/STATE.md` with current state.
5. Subagent commits: `docs: sync after <tag>`
6. Subagent tags: `<tag>-docs`
7. Subagent pushes docs tag.

Subagent constraints:
- MUST NOT modify source code.
- MUST only touch files under `docs/`.

---

## Enforcement

Failure to comply with any rule in this document:

- STOP execution immediately.
- Report the violation to the user.
- Do not attempt to work around or defer compliance.
- Do not continue until the violation is resolved.
