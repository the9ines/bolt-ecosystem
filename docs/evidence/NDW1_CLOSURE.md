# NDW1 Closure — NATIVE-DESKTOP-WINDOWS-1 Complete + Full Desktop Rollback CLOSED

**Stream:** NATIVE-DESKTOP-WINDOWS-1
**Date:** 2026-03-22
**Type:** PM gate (final desktop rollback closure)

---

## PM Decision

**APPROVED:** Close Windows rollback window. Desktop rollback is now CLOSED across all platforms.

- `.exe` distribution accepted as valid Windows delivery format
- MSI installer failure (cargo-bundle/WiX bug) is non-blocking
- Tauri desktop path is **retired**

---

## Windows CI Evidence

**Run:** [23412620528](https://github.com/the9ines/bolt-core-sdk/actions/runs/23412620528)
**Environment:** `windows-latest` (Windows Server 2025)
**Commits:** `ee00d08` (CI workflow), `9438412` (bolt-app-core + bolt-ui refactor)

| Step | Result | Detail |
|------|--------|--------|
| Build bolt-ui (release) | **PASS** | `bolt-ui.exe`, 7,044,096 bytes |
| bolt-app-core tests | **PASS** | 69 passed, 0 failed (6 Unix-only tests correctly skipped) |
| bolt-ui tests | **PASS** | 15 passed, 0 failed |
| MSI packaging | **FAIL** | cargo-bundle WiX `KeyPath` column error — tooling bug, not code issue |
| Artifact upload | **PASS** | `windows-desktop-artifacts` |

---

## Full Desktop Rollback Closure

| Platform | Artifact | Size | Rollback Status |
|----------|----------|------|----------------|
| **macOS** | `LocalBolt.app` | 7.4 MB | **CLOSED** (NDP3, 2026-03-22) |
| **Linux** | `bolt-ui_0.2.0_arm64.deb` | 4.0 MB | **CLOSED** (NDP3, 2026-03-22) |
| **Windows** | `bolt-ui.exe` | 6.7 MB | **CLOSED** (NDW1, 2026-03-22) |

---

## Desktop Authority (Final)

| Role | Owner |
|------|-------|
| Desktop UI shell | `bolt-core-sdk/rust/bolt-ui` (egui/eframe) |
| App runtime core | `bolt-core-sdk/rust/bolt-app-core` |
| Tauri desktop path | `localbolt-app` — **RETIRED** |

---

## Non-Blocking Follow-On

| Item | Status | Priority |
|------|--------|----------|
| MSI installer | cargo-bundle WiX bug — fix or use `wix` crate directly | Low |
| Professional icon design | Placeholder functional | Low |
| `localbolt-app/src-tauri/` code removal | Safe for deletion | When convenient |

---

## Final Status

**NATIVE-DESKTOP-WINDOWS-1: COMPLETE.** Stream CLOSED.
**Desktop rollback: CLOSED across all platforms.**
**Tauri desktop path: RETIRED.**
