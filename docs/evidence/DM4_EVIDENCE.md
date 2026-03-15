# DISCOVERY-MODE-1 DM4 — Verification Evidence

Captured: 2026-03-15
Operator: oberfelder (local workstation)
Context: AC-DM-14..16 closure + DISCOVERY-MODE-1 stream COMPLETE.

---

## 1. AC Summary

| AC | Status | Evidence |
|----|--------|---------|
| AC-DM-14 | **PASS** | Env var naming matrix documented with rationale for differences. |
| AC-DM-15 | **PASS** | Mode semantics documented across DM1–DM4 governance sections. |
| AC-DM-16 | **PASS** | Zero runtime files changed. Docs only. |

---

## 2. Env Var Config Audit (AC-DM-14)

### Current Naming Matrix

| Purpose | localbolt-v3 | localbolt | localbolt-app |
|---------|-------------|-----------|---------------|
| **Local signal URL** | `VITE_LOCAL_SIGNAL_URL` | `VITE_SIGNAL_URL` | `VITE_SIGNAL_URL` |
| **Cloud signal URL** | `VITE_SIGNAL_URL` | `VITE_CLOUD_SIGNAL_URL` | `VITE_CLOUD_SIGNAL_URL` |
| **Default (absent)** | LAN_ONLY | LAN_ONLY | LAN_ONLY |
| **Local URL fallback** | `ws://${hostname}:3001` | `ws://${hostname}:3001` | `ws://${hostname}:3001` |

### Mismatch Detail

`VITE_SIGNAL_URL` means **different things** in different apps:
- **localbolt-v3:** cloud signaling URL (set to `wss://bolt-rendezvous.fly.dev` in production)
- **localbolt / localbolt-app:** local signaling URL (defaults to `ws://${hostname}:3001`)

### Why Names Differ

localbolt-v3 was developed first as the primary web consumer. `VITE_SIGNAL_URL` was chosen to mean "the signal server" — which in v3's cloud-deployed context is the cloud rendezvous. Local signaling was added later as `VITE_LOCAL_SIGNAL_URL`.

localbolt and localbolt-app were developed after DualSignaling. `VITE_SIGNAL_URL` was chosen to mean "the local signal server" (the default path), with `VITE_CLOUD_SIGNAL_URL` as the explicitly-named cloud addition.

### Migration Risk If Renamed

| Risk | Impact | Severity |
|------|--------|----------|
| Breaking localbolt.app Netlify .env | Production outage until updated | HIGH |
| Breaking developer local .env files | Development friction | MEDIUM |
| CI/CD pipeline references | Build failures | MEDIUM |
| Consumer documentation drift | Confusion | LOW |

### Forward Recommendation

A separate future harmonization pass (not DM4 scope) should:
1. Standardize all consumers to `VITE_LOCAL_SIGNAL_URL` + `VITE_CLOUD_SIGNAL_URL`
2. Add backward-compat aliases during transition period
3. Update all .env files, CI configs, and documentation
4. Remove aliases after 1 release cycle

This is a runtime change requiring careful migration — not appropriate for DM4's docs-only scope.

---

## 3. Stream Summary

| Phase | Status | ACs | Key Deliverable |
|-------|--------|-----|-----------------|
| DM1 | DONE | AC-DM-01–04 | LAN_ONLY default, PM-DM-01–04 APPROVED |
| DM2 | DONE | AC-DM-05–08 | "NEARBY" indicator in all 3 consumers |
| DM3 | DONE | AC-DM-10–13 | 11 acceptance tests for DualSignaling |
| DM4 | DONE | AC-DM-14–16 | Env var audit + docs alignment + closure |
| **Total** | **COMPLETE** | **16/16 PASS** | **4/4 PM APPROVED** |

---

## 4. Docs-Only Audit (AC-DM-16)

DM4 commit changes only `docs/` files:
- `docs/GOVERNANCE_WORKSTREAMS.md`
- `docs/FORWARD_BACKLOG.md`
- `docs/STATE.md`
- `docs/CHANGELOG.md`
- `docs/evidence/DM4_EVIDENCE.md`

Zero `.ts`, `.rs`, `.json`, `.env`, or other runtime files modified.
