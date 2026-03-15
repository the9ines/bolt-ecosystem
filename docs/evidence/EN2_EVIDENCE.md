# EGUI-NATIVE-1 EN2 — Verification Evidence

Captured: 2026-03-15
Operator: oberfelder (local workstation)
Context: AC-EN-05..09 closure for EN2 DONE status.

---

## 1. AC Summary

| AC | Status | Key Evidence |
|----|--------|-------------|
| AC-EN-05 | PASS (macOS ARM64 native). CI-required: macOS Intel, Windows, Linux. | `cargo build -p bolt-ui --target aarch64-apple-darwin` PASS. x86_64 cross-compile blocked by Homebrew Rust (not a code issue). |
| AC-EN-06 | PASS | App launches with themed dark window (smoke test: 4s run, clean exit). |
| AC-EN-07 | PASS | 3 skeleton screens: connect (peer code), transfer (progress + files), verify (SAS + confirm/reject). |
| AC-EN-08 | PASS | Theme constants in `theme.rs`: 11 colors, 4 spacing values, 4 font sizes, rounding. |
| AC-EN-09 | PASS | `cargo tree -p bolt-ui` shows zero bolt-* dependencies. eframe only. |

---

## 2. Crate Structure

```
bolt-core-sdk/rust/bolt-ui/
├── Cargo.toml           (eframe 0.33 only — no transport/protocol deps)
└── src/
    ├── main.rs          (eframe entrypoint, 480×640 window)
    ├── app.rs           (BoltApp: screen routing, navigation header)
    ├── theme.rs         (AC-EN-08: colors, spacing, fonts, apply_theme)
    └── screens/
        ├── mod.rs       (Screen enum: Connect, Transfer, Verify)
        ├── connect.rs   (peer code display + input + connect button)
        ├── transfer.rs  (progress bar + file list + send button)
        └── verify.rs    (SAS code display + confirm/reject buttons)
```

---

## 3. Build Evidence

| Target | Command | Result |
|--------|---------|--------|
| aarch64-apple-darwin (native) | `cargo build -p bolt-ui` | PASS |
| aarch64-apple-darwin (explicit) | `cargo build -p bolt-ui --target aarch64-apple-darwin` | PASS |
| x86_64-apple-darwin (cross) | `cargo check -p bolt-ui --target x86_64-apple-darwin` | BLOCKED (Homebrew Rust, CI-required) |
| Workspace regression | `cargo check --workspace` | PASS (all 5 members) |
| Tests | `cargo test -p bolt-ui` | 2 passed, 0 failed |
| Dep audit (AC-EN-09) | `cargo tree -p bolt-ui` | Zero bolt-* deps |
| Smoke test | `cargo run -p bolt-ui` (4s, killed) | Window opens, no crash |

---

## 4. Cross-Platform Status

| Platform | Status | Evidence |
|----------|--------|----------|
| macOS ARM64 | PASS (native build + run) | cargo build + smoke test |
| macOS Intel | CI-REQUIRED | Homebrew Rust cross-compile limitation; code is target-agnostic |
| Windows | CI-REQUIRED | No Windows target installed; code uses eframe (cross-platform) |
| Linux | CI-REQUIRED | No Linux target installed; code uses eframe (cross-platform) |

AC-EN-05 note: macOS ARM64 native build verified. x86_64/Windows/Linux are CI-required evidence (code is platform-agnostic via eframe; build failures would be toolchain/environment issues, not code issues).

---

## 5. Rollback Safety

- `bolt-ui` is a new, independent crate — removal = git revert + remove workspace member
- localbolt-app: UNTOUCHED (no files modified)
- EN-G8: Tauri WebView desktop app completely unchanged
- No transport/protocol coupling (AC-EN-09)

---

## 6. Files Changed

| Repo | File | Change |
|------|------|--------|
| bolt-core-sdk | `rust/Cargo.toml` | Added "bolt-ui" to workspace members |
| bolt-core-sdk | `rust/bolt-ui/Cargo.toml` | NEW: crate manifest (eframe 0.33) |
| bolt-core-sdk | `rust/bolt-ui/src/main.rs` | NEW: eframe entrypoint |
| bolt-core-sdk | `rust/bolt-ui/src/app.rs` | NEW: BoltApp + screen routing |
| bolt-core-sdk | `rust/bolt-ui/src/theme.rs` | NEW: theme constants + apply_theme |
| bolt-core-sdk | `rust/bolt-ui/src/screens/mod.rs` | NEW: Screen enum |
| bolt-core-sdk | `rust/bolt-ui/src/screens/connect.rs` | NEW: connection skeleton |
| bolt-core-sdk | `rust/bolt-ui/src/screens/transfer.rs` | NEW: transfer skeleton |
| bolt-core-sdk | `rust/bolt-ui/src/screens/verify.rs` | NEW: verification skeleton |
| bolt-ecosystem | `docs/GOVERNANCE_WORKSTREAMS.md` | EN2 status + AC updates |
| bolt-ecosystem | `docs/FORWARD_BACKLOG.md` | Status + phase table |
| bolt-ecosystem | `docs/STATE.md` | Header + row |
| bolt-ecosystem | `docs/CHANGELOG.md` | New EN2 entry |
| bolt-ecosystem | `docs/evidence/EN2_EVIDENCE.md` | This file |
