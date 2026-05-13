# NDP3 Closure — NATIVE-DESKTOP-PKG-1 Stream Complete

**Stream:** NATIVE-DESKTOP-PKG-1
**Phase:** NDP3 — Tauri rollback window closure
**Date:** 2026-03-22
**Type:** PM gate (rollback window closure)

---

## PM Decision: PM-EN-03 Resolved

**APPROVED (Option A):** Close rollback window for macOS + Linux desktop.

| Platform | Rollback Window | Status |
|----------|----------------|--------|
| **macOS** | **CLOSED** | `LocalBolt.app` proven (7.4 MB), embedded rendezvous, one-app model |
| **Linux** | **CLOSED** | `bolt-ui_0.2.0_arm64.deb` proven (4.0 MB), `.deb` accepted as deliverable |
| **Windows** | **Conditionally open** | MSI config-ready, closure pending Windows CI validation |

**Additional PM determinations:**
- `.deb` is the accepted Linux deliverable. AppImage is optional follow-on.
- Placeholder icon is not a blocker for closure.
- `bolt-ui` is the primary desktop path. Tauri is legacy/transitional only.

---

## Stream Summary

NATIVE-DESKTOP-PKG-1 delivered:

1. **NDP1:** Desktop packaging scaffold — cargo-bundle metadata, embedded rendezvous server, macOS `.app` bundle, signal health monitoring, structured logging
2. **NDP2:** Cross-platform packaging validation — macOS `.app` and Linux `.deb` proven, Windows/AppImage config-ready, icon assets for all platforms
3. **NDP3:** Rollback window closure — PM-EN-03 resolved for macOS + Linux

---

## Desktop Architecture (Post-Closure)

| Component | Authority | Notes |
|-----------|----------|-------|
| Desktop UI shell | `bolt-core-sdk/rust/bolt-ui` | egui/eframe, standalone binary |
| App runtime core | `bolt-core-sdk/rust/bolt-app-core` | Daemon lifecycle, IPC, watchdog, platform |
| Daemon | `bolt-daemon` | Sidecar, managed by app |
| Signaling | Embedded `bolt-rendezvous` in bolt-ui | Background thread, 0.0.0.0:3001 |
| Tauri path | `localbolt-app` | **Legacy.** Transitional only. Not the desktop target. |

---

## What This Closes

- PM-EN-03 rollback window for macOS + Linux desktop
- Tauri as the desktop-primary architecture on those platforms
- NATIVE-DESKTOP-PKG-1 stream (macOS + Linux scope)

## What Remains Conditionally Open

| Item | Condition |
|------|-----------|
| Windows desktop rollback window | MSI validated in Windows CI |
| `localbolt-app/src-tauri/` removal | After Windows closure or PM explicit approval |
| Professional icon design asset | Operational follow-on |

---

## Evidence Documents

| Phase | Evidence |
|-------|----------|
| NDP1 | `docs/evidence/NDP1_EVIDENCE.md` |
| NDP2 | `docs/evidence/NDP2_EVIDENCE.md` |
| NDP3 | `docs/evidence/NDP3_CLOSURE.md` (this document) |

---

## Final Status

**NATIVE-DESKTOP-PKG-1: COMPLETE (macOS + Linux).** Windows conditionally open.

Stream status: **CLOSED** for governance purposes. Windows MSI validation is a CI follow-on, not a stream-level gate.
