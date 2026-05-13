# NDP1 Evidence — Desktop Packaging Scaffold + Embedded Runtime

**Stream:** NATIVE-DESKTOP-PKG-1
**Phase:** NDP1 — Packaging scaffold
**Date:** 2026-03-22
**Type:** Engineering (desktop packaging + runtime integration)

---

## Summary

`bolt-ui` is now a self-contained desktop application on macOS with embedded rendezvous server, managed daemon lifecycle, signal health monitoring, and macOS `.app` bundle packaging. No WebView dependency. No external signal server required.

---

## What was implemented

| Capability | Status |
|-----------|--------|
| Embedded rendezvous server (0.0.0.0:3001) | **Done** — background thread, panic-guarded |
| Default rendezvous → 127.0.0.1:3001 (embedded) | **Done** — overridable via `BOLT_RENDEZVOUS_URL` |
| Signal health indicator in UI header | **Done** — green/red dot with hover tooltip |
| Structured logging (tracing + env-filter) | **Done** |
| macOS app bundle via cargo-bundle | **Done** — `LocalBolt.app`, 7.4 MB |
| Bundle metadata (identifier, category, copyright) | **Done** — `com.the9ines.localbolt` |
| Version bump to 0.2.0 | **Done** |

## Files changed

| File | Change |
|------|--------|
| `bolt-ui/Cargo.toml` | Added bolt-rendezvous, tokio, tracing deps. cargo-bundle metadata. Version 0.2.0. |
| `bolt-ui/src/main.rs` | Embedded signal server, tracing init, startup sequencing. |
| `bolt-ui/src/app.rs` | Rendezvous default → 127.0.0.1:3001. Signal health state + UI indicator. |
| `bolt-ui/src/daemon.rs` | Fixed test path reference. |

**Commit/tag:** Not provided.

## Validation

```
bolt-app-core: 75 passed, 0 failed, 0 warnings
bolt-ui:       15 passed, 0 failed, 0 warnings
localbolt-app:  3 passed, 0 failed, 0 warnings
Release binary: 7.4 MB Mach-O arm64
cargo bundle:   LocalBolt.app produced successfully
```

## macOS App Bundle

```
Path:       target/release/bundle/osx/LocalBolt.app
Binary:     7.4 MB (release, arm64)
Identifier: com.the9ines.localbolt
Category:   public.app-category.utilities
Copyright:  Copyright © 2026 The9ines
```

## Remaining for NDP2/NDP3

| Item | Status | Phase |
|------|--------|-------|
| Windows MSI packaging validation | Not done | NDP2 |
| Linux AppImage/deb validation | Not done | NDP2 |
| App icon asset | Not done | NDP2 |
| PM-EN-03 rollback window closure | Blocked on PM | NDP3 |
| localbolt-app/src-tauri/ removal | Blocked on PM-EN-03 | NDP3 |

## PM Decision Surface

`bolt-ui` is technically proven as the desktop-native replacement for Tauri on macOS. The remaining items (Windows/Linux packaging, icon) are operational, not architectural. PM-EN-03 closure is now a policy decision, not a technical blocker.
