# Rendezvous Infrastructure

Rust rendezvous server and deployment rules.

---

## Trust Model

- Rendezvous is UNTRUSTED for confidentiality and integrity.
- MUST NOT rely on rendezvous for message secrecy or authentication.
- Rendezvous MAY observe: peer codes, IP addresses, timing, connection patterns.
- Rendezvous MUST NOT observe: file contents, filenames, encryption keys, transfer metadata.
- All security guarantees come from Bolt-layer encryption (envelope).

---

## Wire Responsibilities

The rendezvous server is limited to:
- Peer presence (register, join, leave notifications)
- Signal routing (relay opaque payloads between peers by peer_code)
- Room grouping (assign peers to rooms based on IP heuristics)

The rendezvous server MUST NOT:
- Inspect or modify signal payloads
- Store messages persistently
- Authenticate Bolt-layer identity
- Participate in key exchange

---

## Room Grouping Heuristics

IP classification buckets for "local" room assignment:

| Range | Classification |
|-------|---------------|
| 10.0.0.0/8 | RFC 1918 private |
| 172.16.0.0/12 | RFC 1918 private |
| 192.168.0.0/16 | RFC 1918 private |
| 100.64.0.0/10 | CGNAT / Tailscale |
| 169.254.0.0/16 | Link-local |
| fc00::/7 | IPv6 ULA |
| fe80::/10 | IPv6 link-local |

- Peers sharing the same external IP or private subnet are grouped.
- This is a HEURISTIC, not a security boundary.
- VPN and CGNAT may cause false grouping.

---

## Profile Boundary

- WebSocket signaling message types (register, signal, peers, peer_joined, peer_left) are Profile-level.
- These MUST NOT appear in Bolt Core specification or Core SDK code.
- Core refers only to "rendezvous" abstractly.

---

## Deployment Patterns

**Hosted:**
- Fly.io deployment for cloud rendezvous.
- Serves localbolt-v3 web app and remote discovery.
- MUST use wss:// in production.

**Self-hosted / Local:**
- Runs on LAN (ws://<ip>:3001).
- Bundled into localbolt and localbolt-app for offline mode.
- No external dependencies required.

---

## Subtree Rule

- Canonical implementation lives in bolt-rendezvous repo only.
- localbolt and localbolt-app vendor via git subtree.
- Vendored copies MUST NOT be patched locally.
- All changes MUST occur upstream in bolt-rendezvous.
- Subtree pull procedure:
  1. Merge upstream changes in bolt-rendezvous.
  2. In product repo: `git subtree pull --prefix=signal <remote> main --squash`
  3. Verify build and tests pass.
  4. Commit and tag.

---

## Resource Posture

- MUST: bounded connection count per IP.
- MUST: bounded message queue depth per connection.
- MUST: enforce backpressure (drop or reject when full).
- MUST: rate limit registration and signal messages.
- SHOULD: low memory footprint (no per-message persistence).
- SHOULD: graceful shutdown (drain connections, close cleanly).
- MUST NOT: buffer unlimited data.
- MUST NOT: log message payloads (they are opaque to rendezvous).
