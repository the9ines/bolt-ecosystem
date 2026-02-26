# Release Operations

Tagging, releasing, deployments, and SRE discipline.

---

## Immutable Tag Rule

- Tags MUST NOT be moved, deleted, or force-pushed after creation.
- Once a tag is pushed to origin, it is permanent.
- If a tag was applied to a wrong commit, create a new tag with incremented version.
- `git tag -d` and `git push --delete` are forbidden for published tags.

---

## Repository Tag Formats

| Repository | Format | Example |
|------------|--------|---------|
| bolt-core-sdk | `sdk-vX.Y.Z` | `sdk-v1.0.0` |
| bolt-rendezvous | `rendezvous-vX.Y.Z` | `rendezvous-v1.0.0` |
| bolt-daemon | `daemon-vX.Y.Z` | `daemon-v1.0.0` |
| localbolt | `localbolt-vX.Y.Z` | `localbolt-v2.1.0` |
| localbolt-app | `localbolt-app-vX.Y.Z` | `localbolt-app-v1.0.0` |
| localbolt-v3 | `v3.0.<N>-<slug>` | `v3.0.38-faq-sync` |
| bytebolt-app | `bytebolt-vX.Y.Z` | `bytebolt-v1.0.0` |
| bytebolt-relay | `relay-vX.Y.Z` | `relay-v1.0.0` |

Determine next tag: `git tag --list '<prefix>*' | sort -V | tail -1`

---

## Clean Tree Requirement

**Before starting work:**
- Run `git status`. Working tree MUST be clean.
- If dirty, stop and ask before proceeding.

**After completing work:**
- Run `git status`. Working tree MUST be clean.
- Zero untracked files. Zero modified files.
- No uncommitted work may remain.

---

## Commit Message Template

```
<imperative subject, max 72 chars>

<body: what changed and why>

Files changed:
- path/to/file1
- path/to/file2

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

Requirements:
- Subject line: imperative mood, under 72 characters.
- Body: explains what and why, not just what.
- Files changed: explicit list of modified files.
- Co-authored-by trailer: mandatory for all Claude commits.

---

## Docs Sync Subagent Procedure

After every code commit:

1. Spawn background subagent (Task tool, subagent_type=general-purpose).
2. Subagent reads: `git diff HEAD~1 HEAD`
3. Subagent updates:
   - `docs/CHANGELOG.md` — new entry with tag, date, hash, summary, files changed.
   - `docs/STATE.md` — current project state.
4. Subagent commits: `docs: sync after <tag>`
5. Subagent tags: `<tag>-docs`
6. Subagent pushes tag.

Constraints:
- Docs subagent MUST NOT modify source code.
- Docs subagent MUST only touch files under `docs/`.
- Docs commit is separate from code commit.

---

## Cross-Repo Version Compatibility

### bolt-core-sdk versioning (semver)

**Major bump (sdk-v2.0.0):**
- Breaking change to Core message schemas.
- Removal of mandatory fields.
- Change in envelope format.
- Change in handshake rules.

**Minor bump (sdk-v1.1.0):**
- New optional capability added.
- New optional HELLO field.
- New error code.
- New conformance test.

**Patch bump (sdk-v1.0.1):**
- Bug fix in existing logic.
- Documentation correction in SDK.
- Test fix.

### Compatibility rules

- Products MUST declare minimum SDK version in their manifest.
- SDK major version change MUST be coordinated across all product repos.
- Profile versions are independent but MUST declare Core version.
- Downgrading SDK version in a product requires explicit approval.

---

## Release Checklist

- [ ] Working tree clean before starting.
- [ ] All tests pass.
- [ ] `git diff --cached` reviewed (no secrets).
- [ ] Commit message follows template.
- [ ] Tag follows repo-specific format.
- [ ] Tag pushed to origin.
- [ ] Hash recorded (short + full) in summary.
- [ ] Docs sync subagent spawned.
- [ ] Working tree clean after completion.
