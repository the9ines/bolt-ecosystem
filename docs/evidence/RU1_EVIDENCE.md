# RU1 Evidence — Reliability/UX Audit + Prioritized Fix List

**Stream:** LOCALBOLT-RELIABILITY-UX-1
**Phase:** RU1 — Reliability/UX audit
**Date:** 2026-03-19
**Tag:** `ecosystem-v0.1.180-localbolt-reliability-ux1-ru1-audit`
**Type:** Audit (read-only, no runtime changes)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-RU-01 | Prioritized issue list with severity and user impact | **PASS** — 10 issues identified, ordered by severity and user impact. |
| AC-RU-02 | Each issue has a concrete fix proposal | **PASS** — Every issue has exact files, layer classification, and phase assignment. |

---

## Top 4 Issues (Ambiguity + Failure Handling)

### 1. No "Establishing connection..." state after peer accepts — HIGH

**Impact:** User sees same "Awaiting approval" spinner for up to 30s during WebRTC handshake. Cannot tell if peer accepted or if something is stuck.

**Fix:** Add `connectingPhase` store field (`'awaiting' | 'establishing' | null`). Set to `'establishing'` when `connection_accepted` received (initiator, peer-connection.ts:250) or `acceptRequest()` fires (responder, peer-connection.ts:319). device-discovery.ts renders "Establishing secure connection..." text.

**Layer:** Consumer (peer-connection.ts, device-discovery.ts). No SDK change.
**Phase:** RU2.

### 2. Paused state has no label — HIGH

**Impact:** Progress bar freezes, icon swaps, but no text says "PAUSED." User may think transfer is broken.

**Fix:** When `isPaused` is true, show "PAUSED" badge next to filename in transfer-progress.ts:38-67. Optionally mute progress bar color.

**Layer:** SDK (transfer-progress.ts). Affects all consumers.
**Phase:** RU2.

### 3. Error toasts lack reason — HIGH

**Impact:** "Transfer Error" with no cause. User can't debug or decide what to try.

**Fix:** Pass error detail through progress callback. Change toasts from "Transfer Error" to "Transfer Error: encryption failed" / "network timeout" / etc. Consumer: peer-connection.ts:207-210, file-upload.ts:131-134. SDK: TransferManager.ts error detail in progress callback.

**Layer:** Mixed (SDK + consumer).
**Phase:** RU3.

### 4. Connection timeout is silent — HIGH

**Impact:** 30s WebRTC timeout (WebRTCService.ts:515) expires with no countdown or warning. Sudden error after long wait.

**Fix:** Consumer: set 10s timer after `beginConnecting()` that shows "Still establishing connection..." if not yet connected. SDK: ensure timeout rejection produces distinguishable error type.

**Layer:** Consumer-primary (peer-connection.ts). Minor SDK (error type).
**Phase:** RU3.

---

## Full Prioritized Issue List

| # | Issue | Severity | User Impact | Layer | Phase |
|---|-------|----------|-------------|-------|-------|
| 1 | No "Establishing connection..." state | HIGH | Ambiguous 30s wait | Consumer | RU2 |
| 2 | Paused state has no label | HIGH | Confusion — looks broken | SDK | RU2 |
| 3 | Error toasts lack reason | HIGH | Can't debug failures | Mixed | RU3 |
| 4 | Connection timeout is silent | HIGH | Sudden error after long wait | Consumer | RU3 |
| 5 | Receiver has no "incoming transfer" state | MEDIUM | File appears without warning | SDK | RU4 |
| 6 | Transfer completion at 100% lingers | MEDIUM | Unclear "done" moment | SDK | RU4 |
| 7 | Connection drop gives no recovery guidance | MEDIUM | No "how to reconnect" hint | Consumer | RU5 |
| 8 | Cancel feedback is abrupt | LOW | UI vanishes without transition | SDK | RU5 |
| 9 | SAS verification has no user guidance | LOW | User doesn't know what SAS code means | SDK | RU2 |
| 10 | Retry count shown without context | LOW | Alarming "Retries: 3/5" | SDK | RU3 |

---

## Fix Proposals Summary

| # | Fix | Likely Files | Consumer-Only? |
|---|-----|-------------|---------------|
| 1 | `connectingPhase` store field + "Establishing..." text | peer-connection.ts, device-discovery.ts | Yes |
| 2 | "PAUSED" badge when isPaused | transfer-progress.ts | No (SDK) |
| 3 | Error detail in progress callback + toasts | TransferManager.ts, peer-connection.ts, file-upload.ts | No (mixed) |
| 4 | 10s "still connecting" timer + timeout error type | peer-connection.ts, WebRTCService.ts | Mostly consumer |
| 5 | Emit early "receiving" progress on first chunk | TransferManager.ts, transfer-progress.ts | No (SDK) |
| 6 | Checkmark + "Complete" state instead of lingering bar | transfer-progress.ts, file-upload.ts | No (SDK) |
| 7 | "Select the device again to reconnect" in toast | peer-connection.ts | Yes |
| 8 | "Cancelled" label visible during 2s window | transfer-progress.ts, file-upload.ts | No (SDK) |
| 9 | "Compare this code with the other device" text | verification-status.ts | No (SDK) |
| 10 | "Auto-retrying — normal on slower connections" | transfer-progress.ts | No (SDK) |

---

## Recommended Implementation Order

**RU2 (transfer state visibility) — do first:**
- Issue 1: establishing-connection state (consumer-only, highest impact)
- Issue 2: pause label (SDK, small)
- Issue 9: SAS guidance (SDK, PM-RU-01 approved, small)

**RU3 (error/failure/retry UX) — parallel with RU2:**
- Issue 3: error reasons in toasts (mixed, high impact)
- Issue 4: timeout feedback (consumer-primary, high impact)
- Issue 10: retry context (SDK, small)

**RU4 (receive flow + completion) — after RU2:**
- Issue 5: incoming transfer state (SDK)
- Issue 6: completion state (SDK + consumer)

**RU5 (reconnect/cancel/resume) — after RU3:**
- Issue 7: disconnect guidance (consumer-only, one-line)
- Issue 8: cancel transition (SDK + consumer, small)

---

## Verification

- No runtime files changed (audit only)
- No unrelated stream status drift
