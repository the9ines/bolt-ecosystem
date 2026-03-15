# EGUI-NATIVE-1 EN3d — Launcher Pattern Evidence

Captured: 2026-03-15
Operator: oberfelder (local workstation)
Context: EN3 blocker closure via Host/Join daemon launcher pattern.

---

## 1. Two-Daemon Rendezvous Test

**Configuration:**
- Room: r965375, Session: s91617176
- Host peer code: HST543 (answerer)
- Join peer code: JN8347 (offerer)
- Separate --data-dir per side (0700 perms)
- Rendezvous: ws://127.0.0.1:3001

**Connection Evidence:**
```
HOST: [rendezvous] hello/ack complete — session 's91617176'
HOST: [pc] connection state: Connected
HOST: [answerer] DataChannel open
HOST: [INTEROP-2] HELLO exchange complete — negotiated_caps=["bolt.transfer-ratchet-v1"]

JOIN: [rendezvous] hello/ack complete — session 's91617176'
JOIN: [pc] connection state: Connected
JOIN: [offerer] DataChannel open
JOIN: [INTEROP-2] HELLO exchange complete — negotiated_caps=["bolt.transfer-ratchet-v1"]
```

**Heartbeat:** Ping/pong at 0-1ms RTT (LAN).

---

## 2. AC Status Assessment

| AC | Status | Evidence |
|----|--------|---------|
| AC-EN-10 | **PASS** | Real peer code, Host/Join mode, dynamic status, rendezvous connect |
| AC-EN-11 | **PARTIAL** | TransferState::Ready reached on connect. File transfer API not wired to UI (daemon handles transfers via IPC events, bolt-ui reads stderr for state). No file picker integration. |
| AC-EN-12 | **PARTIAL** | VerifyState driven by state model. SAS code visible in daemon HELLO exchange logs. UI SAS binding reads daemon stderr. No IPC-level SAS event yet. |
| AC-EN-13 | **PASS** | cargo check --workspace green. 12 bolt-ui tests pass. |
| AC-EN-14 | **PASS** | bolt-core dep only. No transport deps. |
| AC-EN-15 | **PASS** | Prerequisite errors surfaced (daemon missing, rendezvous unreachable). Timeout (30s). Cancel/retry. Daemon exit detection. |

---

## 3. Validation Matrix

| Check | Command | Result |
|-------|---------|--------|
| Build | `cargo build -p bolt-ui --release` | PASS (5.6 MB) |
| Tests | `cargo test -p bolt-ui` | 12 passed, 0 failed |
| Workspace | `cargo check --workspace` | PASS |
| Rendezvous connect | Two-daemon test with matching room/session | PASS — DataChannel open, BTR negotiated |
| Daemon missing | Remove daemon binary | Error state shown |
| Rendezvous down | No server on :3001 | "Rendezvous server not reachable" error |
| Cancel | Cancel during connecting | Daemon killed, state → Idle |

---

## 4. Remaining Blockers for Full EN3 PASS

| AC | Blocker | What's Needed |
|----|---------|---------------|
| AC-EN-11 | File transfer UI | File picker + transfer initiation via daemon IPC events (not stderr). Daemon handles transfer; UI needs to bind to IPC transfer.incoming.request events. |
| AC-EN-12 | SAS verification UI | IPC pairing.request event contains SAS code. bolt-ui needs IPC client to receive structured events (not stderr parsing). |

These require an IPC client in bolt-ui (connect to daemon socket, read NDJSON events). The daemon process is running and the IPC socket exists — bolt-ui just needs to connect to it.

---

## 5. Files Changed

| Repo | File | Change |
|------|------|--------|
| bolt-core-sdk | rust/bolt-ui/Cargo.toml | Added serde, serde_json |
| bolt-core-sdk | rust/bolt-ui/src/daemon.rs | NEW: DaemonProcess launcher |
| bolt-core-sdk | rust/bolt-ui/src/app.rs | Host/Join mode, daemon lifecycle |
| bolt-core-sdk | rust/bolt-ui/src/state.rs | ConnectMode, HostInfo, updated states |
| bolt-core-sdk | rust/bolt-ui/src/screens/connect.rs | Host/Join tabs |
| bolt-core-sdk | rust/bolt-ui/src/screens/transfer.rs | TransferState::Ready |
| bolt-core-sdk | rust/Cargo.lock | Updated |
