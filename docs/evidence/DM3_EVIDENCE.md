# DISCOVERY-MODE-1 DM3 — Verification Evidence

Captured: 2026-03-15
Operator: oberfelder (local workstation)
Context: AC-DM-10..13 closure for DM3 DONE status.

---

## 1. AC Summary

| AC | Status | Tests |
|----|--------|-------|
| AC-DM-10 | **PASS** | 3 tests: LAN_ONLY local-only, LAN_ONLY cloud guard, HYBRID merged |
| AC-DM-11 | **PASS** | 2 tests: same peer deduped, different peers not deduped |
| AC-DM-12 | **PASS** | 3 tests: source-aware removal, offline peer gone (AirDrop), wrong-source guard |
| AC-DM-13 | **PASS** | 3 tests: source tracking, source cleanup on loss, disconnect clears all |

---

## 2. Test-to-AC Mapping

| # | Test Name | AC |
|---|-----------|-----|
| 1 | LAN_ONLY: peers from local source only appear in list | AC-DM-10 |
| 2 | LAN_ONLY: no cloud-origin peers when cloud not connected | AC-DM-10 |
| 3 | HYBRID: peers from both sources appear in merged list | AC-DM-10 |
| 4 | same peer from both sources → single entry (first-discovery-wins) | AC-DM-11 |
| 5 | different peer codes are not deduped | AC-DM-11 |
| 6 | peer removed only by originating source | AC-DM-12 |
| 7 | offline peer removed from visible list (AirDrop-style) | AC-DM-12 |
| 8 | peer loss callback not fired for wrong-source loss | AC-DM-12 |
| 9 | peerSource tracks originating source correctly | AC-DM-13 |
| 10 | source cleared after peer loss | AC-DM-13 |
| 11 | disconnect clears all peers and sources | AC-DM-13 |

---

## 3. Test Results

```
Test Files  1 passed (1)
     Tests  11 passed (11)

Full regression: 31 files, 375 tests, 0 failed
(was 364 pre-DM3 + 11 new = 375)
```

---

## 4. Runtime Code Changes

**NONE.** Test-only harness. DualSignaling.ts unchanged. All 11 tests validate existing behavior.

---

## 5. Files Changed

| Repo | File | Change |
|------|------|--------|
| bolt-core-sdk | `ts/bolt-transport-web/src/__tests__/dm3-discovery-mode.test.ts` | NEW: 11 tests |
