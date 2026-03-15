# EGUI-NATIVE-1 EN3e — IPC Client Evidence

Captured: 2026-03-15
Operator: oberfelder (local workstation)
Context: EN3 blocker closure via daemon IPC events + bolt-ui IPC client.

---

## 1. Daemon IPC Events Verified

Real two-daemon rendezvous test with Python IPC client connected to host daemon socket:

```
EVENT: version.status -> {"compatible": true, "daemon_version": "0.0.1"}
EVENT: daemon.status -> {"connected_peers": 0, "ui_connected": true, "version": "0.0.1"}
EVENT: session.connected -> {"negotiated_capabilities": [], "remote_peer_id": "IPCJOIN"}
EVENT: session.sas -> {"remote_identity_pk_b64": "79qJ9YO6B/...", "sas": "399939"}
EVENT: session.connected -> {"negotiated_capabilities": ["bolt.profile-envelope-v1", "bolt.file-hash", "bolt.transfer-ratchet-v1"], "remote_peer_id": "IPCJOIN"}
TOTAL EVENTS: 5
```

**SAS codes match on both sides:** 399939 (host) = 399939 (join)

---

## 2. AC Status

| AC | Status | Evidence |
|----|--------|---------|
| AC-EN-10 | **PASS** | Real peer code, Host/Join mode, rendezvous connect, IPC-driven status |
| AC-EN-11 | **PARTIAL** | TransferState driven by IPC events (transfer.started/progress/complete types defined). Real file transfer requires daemon transfer path to emit events — transfer progress emit points not yet added in rendezvous.rs data loop. |
| AC-EN-12 | **PASS** | session.sas IPC event received with real SAS code (399939). VerifyState::Pending populated from IPC. Both sides compute matching SAS. |
| AC-EN-13 | **PASS** | 353 daemon tests pass. 14 bolt-ui tests pass. Workspace green. |
| AC-EN-14 | **PASS** | bolt-core dep only. No transport deps. |
| AC-EN-15 | **PASS** | IPC connect failure surfaced. Daemon exit detected. Timeout works. Cancel works. |

---

## 3. Daemon Changes

| File | Change |
|------|--------|
| `src/ipc/types.rs` | New payload structs: SessionConnectedPayload, SessionSasPayload, SessionErrorPayload, SessionEndedPayload, TransferStartedPayload, TransferProgressPayload, TransferCompletePayload |
| `src/ipc/server.rs` | New message types in parse_ipc_line |
| `src/rendezvous.rs` | emit_ipc helper, to_32 helper, session.connected + session.sas emissions in both offerer and answerer paths |
| `src/main.rs` | Offerer callsite updated for ipc_server parameter |

---

## 4. bolt-ui IPC Client

| File | Change |
|------|--------|
| `src/ipc.rs` | NEW: IpcClient (Unix socket, NDJSON handshake, event reader thread) |
| `src/app.rs` | IPC client lifecycle, event processing for session/transfer states |
| `src/main.rs` | Added ipc module |

---

## 5. Remaining Blocker

AC-EN-11 (transfer) is PARTIAL because the daemon's rendezvous data loop does not yet emit `transfer.started`, `transfer.progress`, `transfer.complete` events. The IPC types and bolt-ui processing are ready — only the daemon emit points in the transfer code path are missing.

This is a targeted daemon change (add emit_ipc calls in the B3 transfer loop in rendezvous.rs) and does not require architectural changes.
