# DISCOVERY-MODE-1 DM1 — Verification Evidence

Captured: 2026-03-15
Operator: oberfelder (local workstation)
Context: AC-DM-01..04 closure for DM1 DONE status.

---

## 1. AC Summary

| AC | Status | Key Evidence |
|----|--------|-------------|
| AC-DM-01 | PASS | PM-DM-01 APPROVED. LAN_ONLY automatic proximity (AirDrop-style). No HYBRID default. |
| AC-DM-02 | PASS | PM-DM-02 APPROVED. No mode toggle. Automatic LAN discovery. |
| AC-DM-03 | PASS | PM-DM-03 APPROVED. "Nearby" wording. Manual code entry as optional fallback. |
| AC-DM-04 | PASS | PM-DM-04 APPROVED. CLOUD_ONLY deferred. ByteBolt/web scope. |

---

## 2. Policy Summary

| Property | Decision |
|----------|----------|
| Default mode | LAN_ONLY (automatic proximity) |
| UX model | AirDrop-style: nearby peers appear automatically |
| Cloud peers | NOT shown in LocalBolt discovery |
| HYBRID | NOT default for LocalBolt |
| Manual code entry | Optional fallback, not primary |
| Mode indicator | "Nearby" |
| Toggle UI | None |
| CLOUD_ONLY | Deferred to ByteBolt/web |

---

## 3. PM Decisions

| ID | Decision | Status |
|----|----------|--------|
| PM-DM-01 | LAN_ONLY default | APPROVED |
| PM-DM-02 | No toggle | APPROVED |
| PM-DM-03 | "Nearby" wording | APPROVED |
| PM-DM-04 | CLOUD_ONLY deferred | APPROVED |

---

## 4. Scope Boundary

| Context | Discovery Mode | DM1 Scope |
|---------|---------------|-----------|
| LocalBolt (desktop app) | LAN_ONLY | IN SCOPE |
| localbolt-v3 (web, localbolt.app) | Existing DualSignaling (cloud configured) | Existing behavior preserved |
| localbolt (web) | Existing DualSignaling | Existing behavior preserved |
| ByteBolt (future) | Cloud/relay | OUT OF SCOPE |

DM1 establishes LocalBolt's **default** discovery UX. It does not modify existing cloud signaling for web consumers.

---

## 5. Files Changed

| File | Change |
|------|--------|
| `docs/GOVERNANCE_WORKSTREAMS.md` | DM1 AC status + PM subsections; DM2 → READY; PM-DM-01–04 → APPROVED |
| `docs/FORWARD_BACKLOG.md` | Status + phase table + AC count + PM table |
| `docs/STATE.md` | Header + DM row |
| `docs/CHANGELOG.md` | New DM1 DONE entry |
| `docs/evidence/DM1_EVIDENCE.md` | This file (new) |
