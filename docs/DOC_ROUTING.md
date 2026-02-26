# Bolt Ecosystem — Document Routing Table

> **Status:** Normative
> **Created:** 2026-02-26
> **Phase:** DOC-GOV-1

This file is the single authoritative routing map for all documentation in the Bolt ecosystem. Agents and contributors MUST consult this table before creating, updating, or moving any documentation file.

---

## Warning

**Agents must not update any documentation outside the canonical paths defined in this file.**

Modifications to documentation not listed here require explicit human approval.

If a prompt states "update STATE.md" or "update CHANGELOG.md" without specifying both:
- the repository, and
- the exact path,

the agent MUST stop and request clarification. Agents must never infer or guess the target file.

---

## Canonical Ecosystem Docs

These live at the workspace root (`bolt-ecosystem/docs/`) and govern the entire ecosystem.

| File | Path | Purpose |
|------|------|---------|
| STATE.md | `docs/STATE.md` | Current ecosystem state snapshot |
| CHANGELOG.md | `docs/CHANGELOG.md` | Ecosystem-wide release history |
| PROTOCOL_ENFORCEMENT.md | `docs/PROTOCOL_ENFORCEMENT.md` | Protocol enforcement patterns and audit |
| ROADMAP.md | `docs/ROADMAP.md` | Ecosystem roadmap and release sequencing |
| RUST_CORE_PLAN.md | `docs/RUST_CORE_PLAN.md` | Rust SDK modernization plan |
| DOC_ROUTING.md | `docs/DOC_ROUTING.md` | This file — canonical doc routing table |
| AUDIT_TRACKER.md | `docs/AUDIT_TRACKER.md` | Ecosystem-wide audit findings tracker |

---

## Per-Repo Docs

Each product/infrastructure repo maintains its own local docs under `<repo>/docs/`.

| File | Path Pattern | Purpose |
|------|-------------|---------|
| STATE.md | `<repo>/docs/STATE.md` | Per-repo current state |
| CHANGELOG.md | `<repo>/docs/CHANGELOG.md` | Per-repo release history |

Repos with per-repo docs: bolt-core-sdk, bolt-daemon, bolt-rendezvous, localbolt, localbolt-app, localbolt-v3.

---

## Audit Tracker

| File | Path | Notes |
|------|------|-------|
| AUDIT_TRACKER.md | `docs/AUDIT_TRACKER.md` | Canonical. Relocated from bolt-core-sdk in DOC-GOV-2. |

### Audit Tracker Rules

- Audit findings are recorded **only** in `bolt-ecosystem/docs/AUDIT_TRACKER.md`. Repos may link but MUST NOT duplicate.
- `bolt-core-sdk/docs/AUDIT_TRACKER.md` is a stub — **never update it**.

---

## Read-Only (NEVER Edit)

These paths are managed via git subtree sync from bolt-rendezvous. They MUST NOT be modified in the product repo. All changes flow upstream to bolt-rendezvous first.

| Path | Reason |
|------|--------|
| `localbolt/signal/**` | Vendored subtree from bolt-rendezvous |
| `localbolt-app/signal/**` | Vendored subtree from bolt-rendezvous |
| `localbolt/signal/docs/STATE.md` | Subtree doc — read-only |
| `localbolt/signal/docs/CHANGELOG.md` | Subtree doc — read-only |
| `localbolt-app/signal/docs/STATE.md` | Subtree doc — read-only |
| `localbolt-app/signal/docs/CHANGELOG.md` | Subtree doc — read-only |

---

## Cross-Repo Specification Authority

| File | Canonical Repo | Path | Purpose |
|------|----------------|------|---------|
| PROTOCOL.md | bolt-protocol | /PROTOCOL.md | Core Bolt protocol spec |
| LOCALBOLT_PROFILE.md | bolt-protocol | /LOCALBOLT_PROFILE.md | LocalBolt Profile spec |

Protocol and profile specifications reside exclusively in bolt-protocol.
Implementation repos must not redefine protocol semantics.

---

## Archived Docs

Historical artifacts no longer under active governance. Preserved in `docs/archive/`.

| File | Original Location | Archived |
|------|------------------|----------|
| Phase-9E-synthesis.md | Workspace root | 2026-02-26 (DOC-GOV-1) |
| PIXEL_REBRAND_BRIEF.md | Workspace root | 2026-02-26 (DOC-GOV-1) |
| S2-prompt.md | Workspace root | 2026-02-26 (DOC-GOV-1) |
