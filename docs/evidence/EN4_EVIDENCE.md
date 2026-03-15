# EGUI-NATIVE-1 EN4 — Verification Evidence

Captured: 2026-03-15
Operator: oberfelder (local workstation)
Context: AC-EN-16..20 closure for EN4 DONE status.

---

## 1. AC Summary

| AC | Status | Evidence |
|----|--------|---------|
| AC-EN-16 | **PASS** | Legacy Tauri path: `cargo check` PASS. Tests: 10/10 pass. Completely untouched by EN1–EN3. |
| AC-EN-17 | **PASS** | No packaging change. bolt-ui is standalone in bolt-core-sdk. localbolt-app packaging unchanged. |
| AC-EN-18 | **PASS** | daemon.rs in localbolt-app: 10 spawn references intact. N-STREAM-1 bundling unchanged. |
| AC-EN-19 | **PASS** | PM-EN-03 APPROVED: condition-gated rollback window. Dual-build until EN5 PM approval. |
| AC-EN-20 | **PASS** | No install/update flow changed. bolt-ui is new standalone binary. |

---

## 2. Dual-Path Compatibility Matrix

| Property | egui (bolt-ui) | Legacy (localbolt-app) |
|----------|---------------|----------------------|
| Repo | bolt-core-sdk/rust/bolt-ui | localbolt-app/src-tauri |
| Framework | eframe 0.33 (egui) | Tauri v2 (WebView) |
| Build | `cargo build -p bolt-ui` | `cargo tauri dev` |
| Binary | `target/release/bolt-ui` (5.7 MB) | Tauri app bundle |
| Dependencies | eframe + bolt-core | Tauri + bolt-rendezvous |
| Modified in EN1–EN3? | YES (new crate) | NO (zero changes) |
| Tests | 14 pass | 10 pass (cbtr3) |
| Smoke test | Launches, themed window | Compiles cleanly |

**Independence:** Zero shared dependencies between bolt-ui and localbolt-app. Different workspaces, different frameworks, different build commands. Removing one has zero impact on the other.

---

## 3. Rollback Drill Evidence

| Step | Command | Result |
|------|---------|--------|
| egui build | `cargo build -p bolt-ui --release` | PASS (5.7 MB) |
| egui tests | `cargo test -p bolt-ui` | 14 pass, 0 fail |
| egui smoke | `cargo run -p bolt-ui` (3s) | Window opens, killed cleanly |
| Legacy build | `cargo check` (localbolt-app/src-tauri) | PASS |
| Legacy tests | `npx vitest run cbtr3` | 10 pass, 0 fail |
| Legacy unchanged | `git log --oneline -5` | Last change: DM2 header text only |
| Daemon bundling | `daemon.rs` spawn references | 10 intact |

**Rollback procedure:** To revert to legacy-only desktop path:
1. Stop using bolt-ui binary
2. localbolt-app continues functioning unchanged
3. No rollback code changes needed — paths are independent
4. Optional: remove bolt-ui from bolt-core-sdk workspace

---

## 4. PM-EN-03 Decision

**APPROVED (2026-03-15): Option C — condition-gated rollback window.**

| Property | Value |
|----------|-------|
| Dual-build maintenance | Active until EN5 PM approval |
| Fixed time sunset | NONE |
| Legacy removal gate | Explicit EN5 PM decision |
| Pattern | Matches PM-RC-05 (TS-path deprecation) |

---

## 5. Files Changed

| File | Change |
|------|--------|
| `docs/GOVERNANCE_WORKSTREAMS.md` | EN4 AC status + PM-EN-03 → APPROVED |
| `docs/FORWARD_BACKLOG.md` | Status + phase table |
| `docs/STATE.md` | Header + row |
| `docs/CHANGELOG.md` | New EN4 entry |
| `docs/evidence/EN4_EVIDENCE.md` | This file (new) |
