# DISCOVERY-MODE-1 DM2 — Verification Evidence

Captured: 2026-03-15
Operator: oberfelder (local workstation)
Context: AC-DM-05..08 closure for DM2 DONE status.

---

## 1. AC Summary

| AC | Status | Evidence |
|----|--------|---------|
| AC-DM-05 | **PASS** | "NEARBY" indicator implemented in all 3 consumers. |
| AC-DM-06 | **PASS** | Mode is deterministic: signalingConnected=true → "NEARBY", false → "OFFLINE". No ambiguity. |
| AC-DM-07 | **PASS** | LAN_ONLY enforced by default (cloud URL absent = no cloud peers). Existing DualSignaling behavior. |
| AC-DM-08 | **N/A for LocalBolt** | HYBRID degraded state applies only to web contexts where cloud IS configured (localbolt-v3 on localbolt.app). LocalBolt desktop = LAN_ONLY per DM1. For localbolt-v3: existing "SIG DEGRADED" behavior preserved — but localbolt-v3 still shows "NEARBY" when LAN signaling active. |

---

## 2. Per-App Before/After vs localbolt-v3 Baseline

### localbolt-v3 (BASELINE)

| State | Before | After |
|-------|--------|-------|
| Connected (LAN signaling active) | "ACTIVE" (green dot) | **"NEARBY"** (green dot) |
| Disconnected | "OFFLINE" (red dot) | "OFFLINE" (red dot) |

### localbolt (aligned to baseline)

| State | Before | After | Parity |
|-------|--------|-------|--------|
| Connected | "ACTIVE" | **"NEARBY"** | ✓ Matches baseline |
| Disconnected | "OFFLINE" | "OFFLINE" | ✓ Matches baseline |

### localbolt-app (aligned to baseline)

| State | Before | After | Parity |
|-------|--------|-------|--------|
| Daemon ready + signal active | "HEALTHY" | **"NEARBY"** | ✓ Matches baseline semantics |
| Daemon ready (status map) | "ACTIVE" | **"NEARBY"** | ✓ Matches baseline |
| Daemon starting | "STARTING" | "STARTING" | N/A (daemon lifecycle, no baseline equivalent) |
| Signal degraded | "SIG DEGRADED" | "SIG DEGRADED" | N/A (daemon-specific) |

### Remaining Parity Gaps

| Gap | Severity | Notes |
|-----|----------|-------|
| localbolt-app has daemon/signal sub-indicators | LOW | Baseline (localbolt-v3) has single indicator only. localbolt-app's extra indicators are additive (daemon lifecycle). Not a DM2 concern — cosmetic. |
| localbolt-app shows STARTING/RESTARTING states | LOW | Daemon-specific lifecycle states. No baseline equivalent. Acceptable divergence. |

---

## 3. LAN-Only Policy Compliance

| Check | Result |
|-------|--------|
| "NEARBY" shown when LAN connected | ✓ All 3 apps |
| No "ACTIVE" as mode label | ✓ Zero occurrences in all headers |
| No "Online" text | ✓ Zero occurrences |
| No "HYBRID" text | ✓ Zero occurrences |
| Manual code entry = fallback only | ✓ Peer code entry available but not primary discovery UX |
| Cloud peers not in LocalBolt discovery | ✓ Cloud URL absent by default in localbolt/localbolt-app |

---

## 4. Validation Matrix

| Check | App | Result |
|-------|-----|--------|
| NEARBY in header | localbolt-v3 | ✓ line 26 |
| NEARBY in header | localbolt | ✓ line 26 |
| NEARBY in header (unified) | localbolt-app | ✓ line 32 |
| NEARBY in daemon-ready map | localbolt-app | ✓ line 7 |
| No ACTIVE/ONLINE grep | All 3 | ✓ CLEAN |
| BTR regression (cbtr1) | localbolt-v3 | 5/5 pass |
| BTR regression (cbtr2) | localbolt | 5/5 pass |
| BTR regression (cbtr3) | localbolt-app | 10/10 pass |

---

## 5. Files Changed

| Repo | Commit | File |
|------|--------|------|
| localbolt-v3 | `8e20d41` | packages/localbolt-web/src/sections/header.ts |
| localbolt | `df9d71d` | web/src/sections/header.ts |
| localbolt-app | `e281643` | web/src/sections/header.ts |
