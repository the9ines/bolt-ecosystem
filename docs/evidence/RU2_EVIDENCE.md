# RU2 Evidence — Transfer-State Visibility Hardening

**Stream:** LOCALBOLT-RELIABILITY-UX-1
**Phase:** RU2 — Transfer-state visibility hardening
**Date:** 2026-03-19
**Tags:** `v3.0.95-ru2-state-visibility`, `ecosystem-v0.1.181-localbolt-reliability-ux1-ru2-state-visibility`

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-RU-03 | User can distinguish "waiting for peer" from "actively establishing connection" | **PASS** — `connectingPhase` store field: `'requesting'` shows "Waiting for [device] to accept..." / `'establishing'` shows "Establishing secure connection with [device]..." with help text "Setting up encrypted channel." |
| AC-RU-04 | Paused state is explicitly labeled | **PASS** — Yellow "PAUSED" badge shown next to filename. Progress bar turns yellow. Both visually distinct from active transfer. |
| AC-RU-05 | Transfer completion is clearly confirmed with filename | **PASS** — Green checkmark + "[filename] — Transfer complete" rendered as distinct completion state, replacing the progress bar. |

---

## User-Visible State Changes

| State | Before | After |
|-------|--------|-------|
| **Peer accepted, connecting** | "Waiting for [device] to accept..." (same as requesting) | "Establishing secure connection with [device]..." + "Setting up encrypted channel" |
| **Transfer paused** | Frozen progress bar, play icon (no text) | Yellow "PAUSED" badge, yellow progress bar, play icon |
| **Transfer complete** | 100% green bar lingers 2s then vanishes | Green checkmark + "[filename] — Transfer complete" |
| **SAS verification** | Code displayed, no explanation | Code + "Compare this code with the other device." |

---

## Tests

| Suite | Count | Status |
|-------|-------|--------|
| bolt-transport-web | 375/375 | All pass (verification test updated) |
| localbolt-v3 | 141/143 | 2 pre-existing |
