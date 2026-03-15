# EGUI-NATIVE-1 EN3 — Verification Evidence

Captured: 2026-03-15
Operator: oberfelder (local workstation)
Context: AC-EN-10..15 partial closure. EN3 IN-PROGRESS (daemon IPC blockers).

---

## 1. AC Summary

| AC | Status | Evidence |
|----|--------|---------|
| AC-EN-10 | **PASS** | Real peer code from bolt_core. Dynamic connection state. Zero placeholders. |
| AC-EN-11 | **PARTIAL** | TransferState enum drives UI. Blocker: daemon IPC for file transfer. |
| AC-EN-12 | **PARTIAL** | VerifyState enum drives UI. Blocker: daemon IPC for SAS generation. |
| AC-EN-13 | **PASS** | `cargo check --workspace` green. No regressions. |
| AC-EN-14 | **PASS** | `cargo tree`: bolt-core only, zero transport deps. |
| AC-EN-15 | **PARTIAL** | Connection error display wired. Blocker: transfer/kill-switch errors need daemon. |

---

## 2. Placeholder Removal

| Placeholder | File | Before | After |
|------------|------|--------|-------|
| `"ABC123"` | connect.rs:19 | Hardcoded | `bolt_core::peer_code::generate_secure_peer_code()` |
| `"A3 F7 2B"` | verify.rs:36 | Hardcoded | `VerifyState::Pending { sas_code }` (runtime) |
| Static progress 0.0 | transfer.rs:28 | Hardcoded | `transfer.progress()` (state-driven) |
| `"Not connected"` | connect.rs:58 | Static | `connection.status_text()` (dynamic) |
| `"Awaiting verification"` | verify.rs:73 | Static | `verify.status_text()` (dynamic) |

Grep verification: `grep -rn "ABC123\|A3 F7 2B" bolt-ui/src/screens/` = zero matches.

---

## 3. Token Parity (Web → egui)

| Token | Web Value | EN2 Value | EN3 Value | Match |
|-------|-----------|-----------|-----------|-------|
| Accent/primary | #A4E200 | #6366F1 | #A4E200 | YES |
| Background | #121212 | #111111 | #121212 | YES |
| Card/panel | #1A1A1A | #1C1C1E | #1A1A1A | YES |
| Foreground | #FAFAFA | #F5F5F5 | #FAFAFA | YES |
| Muted text | #A3A3A3 | #A3A3A3 | #A3A3A3 | YES |
| Error | #EF4444 | #EF4444 | #EF4444 | YES |
| Border | #262626 | #37373C | #262626 | YES |
| Radius | 12px | 8px | 12px | YES |

---

## 4. Validation Matrix

| Check | Command | Result |
|-------|---------|--------|
| Build | `cargo build -p bolt-ui` | PASS |
| Tests | `cargo test -p bolt-ui` | 9 passed, 0 failed |
| Dep audit | `cargo tree -p bolt-ui \| grep bolt-` | bolt-core only |
| No placeholders | `grep -rn "ABC123" bolt-ui/src/screens/` | 0 matches |
| Workspace regression | `cargo check --workspace` | PASS |
| Smoke test | `cargo run -p bolt-ui` (4s) | Real peer code, themed window |

---

## 5. Blockers for EN3 DONE

| AC | Blocker | What's Needed |
|----|---------|---------------|
| AC-EN-11 | Daemon IPC | bolt-ui must connect to bolt-daemon via IPC to initiate file transfers |
| AC-EN-12 | Daemon IPC | SAS code generated during HELLO exchange requires active daemon session |
| AC-EN-15 | Daemon IPC | Transfer failure and kill-switch error events require daemon event stream |

These blockers require bolt-daemon running and bolt-ui connected via Unix socket/named pipe (N-STREAM-1 IPC contract).

---

## 6. Files Changed

| Repo | File | Change |
|------|------|--------|
| bolt-core-sdk | `rust/bolt-ui/Cargo.toml` | Added bolt-core dependency |
| bolt-core-sdk | `rust/bolt-ui/src/main.rs` | Removed dead_code allow, added state mod |
| bolt-core-sdk | `rust/bolt-ui/src/app.rs` | Runtime state model, real peer code, connect logic |
| bolt-core-sdk | `rust/bolt-ui/src/state.rs` | NEW: ConnectionState, TransferState, VerifyState |
| bolt-core-sdk | `rust/bolt-ui/src/theme.rs` | Web-parity tokens (#A4E200, #121212, radius 12) |
| bolt-core-sdk | `rust/bolt-ui/src/screens/connect.rs` | Runtime peer code, dynamic status |
| bolt-core-sdk | `rust/bolt-ui/src/screens/transfer.rs` | State-driven progress, disabled send |
| bolt-core-sdk | `rust/bolt-ui/src/screens/verify.rs` | State-driven SAS, confirm/reject actions |
| bolt-core-sdk | `rust/Cargo.lock` | Updated |
| bolt-ecosystem | docs/* | Governance status updates |
