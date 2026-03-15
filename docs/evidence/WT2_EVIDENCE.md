# WEBTRANSPORT-BROWSER-APP-1 WT2 — Verification Evidence

Captured: 2026-03-15
Operator: oberfelder (local workstation)
Context: AC-WT-05..08 closure for WT2 DONE status.

---

## 1. AC Summary

| AC | Status | Key Evidence |
|----|--------|-------------|
| AC-WT-05 | PASS | Daemon endpoint: HTTP/3, ALPN h3, TLS 1.3, configurable port, connection lifecycle defined. |
| AC-WT-06 | PASS | Auth: origin validation, optional connection token, rate limiting. No mutual TLS v1. |
| AC-WT-07 | PASS | PM-WT-03 APPROVED: C2 local CA primary, C1 self-signed dev fallback. C3 ACME deferred. |
| AC-WT-08 | PASS | Feature gate `transport-webtransport`, default OFF, independent from ws/quic gates. |

---

## 2. PM-WT-03 Decision

Primary: C2 local CA (mkcert-style) for localhost/LAN.
Dev fallback: C1 self-signed.
Out of scope: C3 ACME/Let's Encrypt (WAN, deferred).

---

## 3. Invariants Preserved

- G1: browser↔browser = WebRTC (unchanged)
- WT-G4: session/protocol authority in daemon/shared Rust core
- Runtime implementation deferred

---

## 4. Files Changed

| File | Change |
|------|--------|
| `docs/GOVERNANCE_WORKSTREAMS.md` | WT2 AC status + 4 subsections; WT3 → READY; PM-WT-03 → APPROVED |
| `docs/FORWARD_BACKLOG.md` | Status + phase table + AC count + PM table |
| `docs/STATE.md` | Header + WT row |
| `docs/CHANGELOG.md` | New WT2 DONE entry |
| `docs/evidence/WT2_EVIDENCE.md` | This file (new) |
