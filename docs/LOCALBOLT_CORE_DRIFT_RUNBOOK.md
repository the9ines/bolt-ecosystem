# localbolt-core Drift Validation Runbook

> **Created:** 2026-03-05 (C6 hardening)
> **Scope:** @the9ines/localbolt-core version pin, install, and reimplementation drift

---

## Consumer Repos (localbolt, localbolt-app)

### 1. Version Pin Drift

Detects semver ranges, `workspace:`, `file:`, or any non-exact version spec.

```bash
# CI-enforced (check-core-version-pin.sh):
bash scripts/check-core-version-pin.sh

# Combined check mode (also validates lockfile + single install):
bash scripts/upgrade-localbolt-core.sh --check
```

**Expected:** `PASS: version pin exact (X.Y.Z)`
**Failure:** Non-exact version spec in `web/package.json` dependencies.

### 2. Duplicate Install Detection

Detects multiple resolved versions of localbolt-core in the dependency tree.

```bash
# CI-enforced:
bash scripts/check-core-single-install.sh
```

**Expected:** `PASS: single instance of @the9ines/localbolt-core installed`
**Failure:** Transitive dependency pulling a different version.
**Fix:** Add `overrides` in `web/package.json` to force single version, or align transitive deps.

### 3. Lockfile Mismatch

Detects package.json version diverging from lockfile resolved version.

```bash
bash scripts/upgrade-localbolt-core.sh --check
```

**Expected:** `PASS: lockfile version matches (X.Y.Z)`
**Failure:** `npm install` was not run after changing the version in `package.json`.
**Fix:** `cd web && rm -rf node_modules && npm install`

### 4. Local Reimplementation Drift

Detects ad-hoc orchestration patterns that bypass localbolt-core exports.

```bash
# CI-enforced (check-core-drift.sh):
bash scripts/check-core-drift.sh src       # from web/ directory
bash scripts/check-core-drift.sh web/src   # from repo root
```

**Patterns detected:**
- `store.setState({ isConnected: false })` — should use `resetSession()`
- `type SessionPhase` local definition — should import from localbolt-core
- `function isTransferAllowed` / `const isTransferAllowed` — should import from localbolt-core
- `let generation` counter — should use `getGeneration/isCurrentGeneration`

**Expected:** All 4 checks PASS.

### 5. Upgrade Procedure

```bash
# Upgrade to a new version:
bash scripts/upgrade-localbolt-core.sh 0.2.0

# Steps performed:
# 1. Updates web/package.json to exact version
# 2. Clean install (rm -rf node_modules + npm install)
# 3. Build gate
# 4. Test gate
# 5. Reports PASS/FAIL — does NOT auto-commit
```

---

## Origin Workspace (localbolt-v3)

### Exemption Rationale

localbolt-v3 is the **origin workspace** for `@the9ines/localbolt-core`. The package lives at `packages/localbolt-core/` and is resolved via npm workspace dependency (`"@the9ines/localbolt-core": "0.1.0"` in `packages/localbolt-web/package.json` is resolved to the local workspace package, not the registry).

**Consumer-style guards NOT applicable:**
- **Version pin check** — workspace resolution always uses the local package; registry version spec is informational only.
- **Single install check** — npm workspaces guarantee single resolution.

**Applicable guard:**
- **Drift check** — detects ad-hoc reimplementation in `packages/localbolt-web/src` that should live in `packages/localbolt-core/`.

### Drift Check

```bash
# CI-enforced (check-core-drift.sh):
bash scripts/check-core-drift.sh packages/localbolt-web/src
```

**Expected:** All 4 checks PASS.

---

## CI Enforcement Summary

| Guard | localbolt | localbolt-app | localbolt-v3 | Rationale |
|-------|:---------:|:-------------:|:------------:|-----------|
| Version pin | CI | CI | N/A | Workspace-resolved |
| Single install | CI | CI | N/A | Workspace-resolved |
| Drift check | CI | CI | CI | All consumers |
| Upgrade tooling | Manual | Manual | N/A | Origin workspace |
