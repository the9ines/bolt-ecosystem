# RU5 Evidence — Reconnect / Cancel / Resume Polish

**Stream:** LOCALBOLT-RELIABILITY-UX-1
**Phase:** RU5 — Reconnect/cancel/resume polish
**Date:** 2026-03-19
**Tags:** `v3.0.98-ru5-reconnect-cancel`, `ecosystem-v0.1.184-localbolt-reliability-ux1-ru5-reconnect-cancel`

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-RU-12 | Connection drop produces a clear message and recovery guidance | **PASS** — User disconnect: "Select the device again to reconnect." Connection loss: "Connection Lost — The connection was interrupted. Select the device again to reconnect." (destructive toast) |
| AC-RU-13 | Cancel during transfer produces immediate, clean feedback | **PASS** — Grey "Transfer cancelled" label with filename shown for 2s (transfer-progress.ts renders cancelled state), then UI clears. Toast: "Transfer Canceled." |
| AC-RU-14 | Post-disconnect reconnect path is obvious | **PASS** — Both disconnect and connection-loss toasts explicitly say "Select the device again to reconnect." No automatic reconnect implied. No resume-after-disconnect implied. |

---

## Disconnect/Cancel/Reconnect UX Changes

| Scenario | Before | After |
|----------|--------|-------|
| **User-initiated disconnect** | "Disconnected: Connection closed successfully" | "Disconnected: Select the device again to reconnect." |
| **Connection drop (WebRTC failed/closed)** | Silent reset — no toast, no guidance | "Connection Lost: The connection was interrupted. Select the device again to reconnect." (destructive) |
| **Transfer cancel** | Progress UI vanishes instantly, then toast | Grey "Transfer cancelled" label visible for 2s, then UI clears. Toast confirms. |
| **Reconnect path** | Not communicated | Explicitly stated in both disconnect toasts |

---

## Recovery Semantics (Honest)

| Recovery | Supported? |
|----------|-----------|
| Pause/resume within a transfer | Yes (RU2 improved visibility) |
| Reconnect after disconnect | Yes — select the device again (manual) |
| Automatic reconnect | No |
| Resume transfer after disconnect | No — must start new transfer |
| Resume transfer after cancel | No — must start new transfer |

No copy implies unsupported automatic reconnect or resumable transfer-after-disconnect.

---

## Tests

| Suite | Count | Status |
|-------|-------|--------|
| bolt-transport-web | 375/375 | All pass |
| localbolt-v3 | 141/143 | 2 pre-existing |
