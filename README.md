# bolt-ecosystem

Governance control plane for the `the9ines/bolt-*` ecosystem.

## Authority

This repository is the single authoritative source for ecosystem-wide governance documents. Canonical docs live in `docs/`.

| Document | Purpose |
|----------|---------|
| `docs/AUDIT_TRACKER.md` | Ecosystem-wide audit findings tracker (authoritative) |
| `docs/DOC_ROUTING.md` | Canonical document routing table |
| `docs/PROTOCOL_ENFORCEMENT.md` | Protocol enforcement patterns and audit |
| `docs/STATE.md` | Ecosystem state snapshot |
| `docs/CHANGELOG.md` | Ecosystem-wide release history |
| `docs/ROADMAP.md` | Ecosystem roadmap and release sequencing |
| `docs/RUST_CORE_PLAN.md` | Rust SDK modernization plan |

## Routing Rule

Other repos (bolt-core-sdk, bolt-daemon, localbolt, etc.) may contain **stub pointers** to docs in this repo. Those stubs are not authoritative — always consult `docs/DOC_ROUTING.md` for the canonical location of any governance document.

## Repository Landscape

Child repos are **not** included in this git repository. They are independent repos that live alongside this one on disk. See `ARCHITECTURE.md` for the full repo map.
