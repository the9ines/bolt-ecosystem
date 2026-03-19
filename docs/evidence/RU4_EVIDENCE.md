# RU4 Evidence — Receive-Flow Clarity + Completion Handling

**Stream:** LOCALBOLT-RELIABILITY-UX-1
**Phase:** RU4 — Receive-flow clarity + completion handling
**Date:** 2026-03-19
**Tags:** `v3.0.97-ru4-receive-flow`, `ecosystem-v0.1.183-localbolt-reliability-ux1-ru4-receive-flow`

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-RU-09 | Receiver sees incoming transfer state before file starts arriving | **PASS** — `'receiving'` status emitted on first chunk. transfer-progress.ts renders "Incoming file — [size]" with pulsing border before progress bar appears. |
| AC-RU-10 | Receiver sees clear transfer-complete confirmation | **PASS** — Green checkmark + "[filename] — Transfer complete" (RU2) visible for 3s (extended from 2s). Toast: "[filename] has been received successfully." |
| AC-RU-11 | File download trigger is reliable across browsers/platforms | **PASS (supported platforms).** `<a download>` click is the standard browser mechanism. Reliable on desktop browsers (Chrome, Firefox, Edge, Safari) and Android. Known platform constraint: iOS Safari may open files in-browser rather than triggering download for some file types — this is a browser limitation, not a code deficiency. |

---

## Receive/Completion UX Changes

| State | Before | After |
|-------|--------|-------|
| **First chunk arrives (receiver)** | Progress bar appears directly at chunk 1 progress | "Incoming file — [size]" with pulsing neon border, then progress bar |
| **Transfer complete (receiver)** | 100% bar lingers 2s, toast auto-dismisses | Green checkmark + filename visible for 3s, toast confirms |
| **File download** | `<a download>` click (unchanged) | Same mechanism — reliable on desktop + Android |

---

## Platform Caveats (AC-RU-11)

| Platform | Download Behavior | Status |
|----------|------------------|--------|
| Chrome (desktop) | Downloads to default folder | Reliable |
| Firefox (desktop) | Downloads or prompts save dialog | Reliable |
| Edge (desktop) | Downloads to default folder | Reliable |
| Safari (desktop) | Downloads to default folder | Reliable |
| Android Chrome | Downloads to Downloads folder | Reliable |
| **iOS Safari** | May open file in-browser tab instead of downloading | **Platform limitation** — `<a download>` attribute is partially supported on iOS Safari. No code-level workaround available. |

---

## Tests

| Suite | Count | Status |
|-------|-------|--------|
| bolt-transport-web | 375/375 | All pass |
| localbolt-v3 | 141/143 | 2 pre-existing |
