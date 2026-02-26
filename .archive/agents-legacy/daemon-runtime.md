# Daemon Runtime

bolt-daemon minimal resource, reliability, and interface contracts.

---

## Goals

- Low CPU: event-driven, no busy polling, no spin loops.
- Low RAM: bounded buffers, streaming IO, no full-file buffering.
- Predictable IO: chunk pipeline with backpressure, no unbounded queues.
- Crash-safe: supervised process, clean state on restart, no corruption.

---

## Responsibilities

| Responsibility | Description |
|---------------|-------------|
| Identity storage | Persistent identity keypair and pinned peer store (TOFU) |
| Session orchestration | Manage peer connections, handshake lifecycle |
| Transfer scheduler | Queue, prioritize, and execute file transfers |
| Resume hooks | Future: resume interrupted transfers (bolt.resume capability) |
| Metrics and events | Expose structured metrics and transfer events to apps |

---

## Non-Responsibilities

- MUST NOT implement UI or user-facing presentation.
- MUST NOT modify protocol semantics (that is bolt-core-sdk).
- MUST NOT perform discovery or rendezvous (that is Profile/app layer).
- MUST NOT make network routing decisions.
- MUST NOT define new message types.

---

## Interface Boundary

```
App <--local IPC--> bolt-daemon <--bolt-core-sdk--> peer channel <--wire--> remote peer
```

- Daemon speaks to applications via a local IPC API (unix socket, local HTTP, or similar).
- Protocol on the wire uses bolt-core-sdk. Daemon does not implement its own wire format.
- IPC API exposes: pair, list-peers, trust/untrust, send, accept, cancel, transfer-status.
- IPC messages are local-only and MUST NOT be exposed on network interfaces.

---

## Operational Constraints

### Memory

- MUST bound total memory usage.
- MUST NOT buffer entire files in memory.
- Chunk pipeline: read chunk, encrypt, send, release. One chunk in flight at a time per transfer.
- Connection state bounded per peer.

### IO

- Streaming reads and writes. No full-file slurp.
- Backpressure: if peer cannot accept data, pause reading from disk.
- File handles closed promptly after transfer completion or cancellation.

### Concurrency

- Bounded concurrent transfers (default: 1, configurable).
- Bounded concurrent peer connections.
- Async runtime (tokio or equivalent) with bounded task count.

### Shutdown

- Graceful shutdown on SIGTERM/SIGINT.
- Drain active transfers: send CANCEL, wait bounded time, then force close.
- Persist any resumable state before exit.
- Release all file handles and network connections.

### State Journaling

- Identity store and pin store MUST survive crashes.
- Transfer progress MAY be journaled for future resume capability.
- Journal writes MUST be atomic or use write-ahead pattern.

---

## Logging Policy

- MUST use structured logging (key-value pairs, not free text).
- MUST NOT log plaintext file contents.
- MUST NOT log secret keys (identity or ephemeral).
- MUST NOT log nonces alongside ciphertext (defense in depth).
- MAY log: peer codes, transfer IDs, chunk progress, error codes, timing.
- Log levels: error, warn, info, debug. Production default: info.

---

## Inclusion Policy

| Repo | Includes Daemon |
|------|----------------|
| localbolt-app | Yes |
| bytebolt-app | Yes |
| localbolt | No (initially) |
| localbolt-v3 | No (not applicable) |
