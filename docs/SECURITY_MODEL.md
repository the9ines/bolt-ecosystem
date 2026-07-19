# Bolt Ecosystem — Canonical Security Model

> **Status:** Normative
> **Stream:** SECURITY-MODEL-1
> **Created:** 2026-03-24
> **Authority:** PM-approved. References ARCHITECTURE.md §10–12 and PROTOCOL.md.

This document is the canonical threat model, trust boundary definition, and security invariant registry for the Bolt ecosystem. All hardening streams (DAEMON-BTR-1, DAEMON-HARDENING-1, RENDEZVOUS-HARDENING-1, PROTOCOL-HARDENING-1, ENDPOINT-SECURITY-1, DEWEBRTC-1) derive their scope from this model.

---

## 1. Trust Boundaries

### Component Trust Levels

| Component | Trust Level | Rationale |
|-----------|------------|-----------|
| **Browser endpoint** | Trusted local agent | Holds identity keys (IndexedDB), performs crypto. Origin-sandboxed. Full session authority when no daemon present. |
| **Native app wrapper (localbolt-app native shell)** | Trusted local UI | Does not hold crypto keys directly. Delegates to daemon via IPC or embedded sidecar. Compromise reveals UI state but not in-transit plaintext without daemon compromise. |
| **CLI client** | Trusted local agent | Same trust model as native wrapper — delegates crypto to daemon. |
| **Daemon (bolt-daemon)** | Trusted local authority | Highest-privilege local component. Owns identity, session, crypto, transfer engine. Compromise is full endpoint compromise. |
| **Local IPC** | Trusted local channel | Unix socket with 0600 permissions. Protected by OS user isolation. Equivalent trust to daemon process boundary. |
| **Local filesystem** | Trusted local storage | Identity keys (0600), trust store, received files. Protected by OS file permissions. |
| **Rendezvous server** | Untrusted relay | Routes encrypted signals. Cannot read envelope contents. Sees IP addresses, peer codes, connection metadata. |
| **Network transport (WS/WT)** | Untrusted channel | All data is envelope-encrypted. MitM sees ciphertext only. Transport is untrusted by design. |
| **Remote peer** | Authenticated after HELLO | Untrusted until mutual HELLO + SAS verification. After verification, trusted for the scope of that session only. |

### Boundary Diagram

```
┌─────────────────────────────────────────────────────┐
│                  Local Device                        │
│                                                     │
│  ┌──────────┐  IPC / sidecar  ┌──────────────────┐  │
│  │ native   │◄──────────────►│   bolt-daemon    │  │
│  │  shell   │                │  identity keys   │  │
│  └──────────┘                │  session crypto  │  │
│                              │  transfer engine │  │
│                              └────────┬─────────┘  │
│                                       │ WS/WT      │
│  ┌──────────────┐                     │             │
│  │   Browser    │─────────────────────┤             │
│  │  identity    │  (direct transport) │             │
│  │  session     │                     │             │
│  └──────────────┘                     │             │
└───────────────────────────────────────┼─────────────┘
                                        │
                          ──────────────┼──────────── network
                                        │
                              ┌─────────▼─────────┐
                              │    Rendezvous     │
                              │  (untrusted relay)│
                              │  signals only     │
                              └───────────────────┘
```

---

## 2. Attacker Model

### Attacker Classes

#### A1: Passive Network Observer
- **Can do:** See encrypted frames, connection timing, frame sizes, IP addresses, peer codes in signaling.
- **Cannot do:** Read plaintext, forge messages, determine file contents from frame sizes alone.
- **Exposed components:** Network transport, rendezvous metadata.

#### A2: Active Network Meddler (MitM)
- **Can do:** Drop, delay, replay, or mutate encrypted traffic. Inject malformed frames. Block connections.
- **Cannot do:** Forge valid encrypted envelopes without key material. Break SAS verification if users compare codes correctly. Decrypt envelope contents.
- **Exposed components:** Network transport, rendezvous signaling path.
- **Mitigation:** NaCl-box authenticated encryption (MAC verified before processing). SAS verification detects MitM on session keys.

#### A3: Compromised Rendezvous Server
- **Can do:** Inject/modify signals, drop connections, log metadata (who connects to whom, when, peer codes, IP addresses), refuse to relay, inject fake peer announcements.
- **Cannot do:** Read envelope contents, forge HELLO messages (encrypted), break SAS verification, access file contents.
- **Exposed components:** Discovery/signaling layer only.
- **Mitigation:** Rendezvous is untrusted by design. All protected messages are envelope-encrypted.

#### A4: Malicious Remote Peer
- **Can do:** Send malformed messages, attempt protocol downgrade, send oversized transfers, send files with path-traversal filenames, refuse to complete HELLO, send duplicate HELLOs.
- **Cannot do:** Bypass envelope encryption, read local identity keys, access local filesystem beyond what the protocol permits, impersonate another verified peer (SAS mismatch).
- **Exposed components:** Session protocol, transfer engine, file receive path.
- **Mitigation:** Fail-closed protocol enforcement, filename sanitization (NEEDED — currently insufficient), transfer size limits (NEEDED), HELLO exactly-once guard.

#### A5: Malicious Local Unprivileged Process (Different OS User)
- **Can do:** Observe network traffic (same as A1).
- **Cannot do:** Connect to daemon IPC (socket 0600, wrong user), read identity keys (file 0600, wrong user), access daemon memory.
- **Exposed components:** Network transport only (ciphertext).

#### A6: Malicious Local Same-User Process
- **Can do:** Connect to daemon IPC socket (same user, socket 0600 allows), send IPC commands, read identity key files, read received files, inject signal files.
- **Cannot do:** Nothing beyond what the daemon itself can do — this is equivalent to daemon compromise.
- **Exposed components:** All local: daemon, identity keys, trust store, received files, IPC.
- **Note:** Same-user compromise is full endpoint compromise. IPC has no additional authentication beyond filesystem permissions.

#### A7: Compromised Endpoint Device
- **Can do:** Everything. Full control of daemon, identity, sessions, plaintext.
- **Cannot do:** Compromise other peers' endpoints (sessions are isolated per-peer).
- **Blast radius:** That device's sessions only.

#### A8: Stale/Legacy Client (Downgrade Pressure)
- **Can do:** Advertise fewer capabilities, cause negotiation to select weaker mode (e.g., no BTR).
- **Cannot do:** Force the other side to accept a capability it doesn't support. Protocol negotiation is intersection-based.
- **Exposed components:** Capability negotiation, BTR availability.
- **Mitigation:** Truthful capability advertisement. UI should indicate when BTR is not active. DAEMON-BTR-1 will close the gap.

#### A9: Abusive Automation / Spam Peer
- **Can do:** Flood connection requests, create many rooms, exhaust rendezvous resources, send rapid signals.
- **Cannot do:** Access file contents (still needs to complete HELLO and pass SAS verification for trusted transfer).
- **Exposed components:** Rendezvous server (DoS), signaling layer.
- **Mitigation:** Rate limiting (NEEDED — RENDEZVOUS-HARDENING-1 scope).

---

## 3. Asset Inventory

### Cryptographic Material

| Asset | Storage | Confidentiality | Integrity | Availability | Persistence |
|-------|---------|----------------|-----------|-------------|-------------|
| **Identity keypair (Ed25519)** | Daemon: `data_dir/identity.key` (0600). Browser: IndexedDB (origin-scoped). | HIGH | HIGH | HIGH (loss = new identity) | Persistent across sessions |
| **Ephemeral session keys (X25519)** | Memory only | HIGH | HIGH | Session-scoped | Discarded on disconnect. MUST NOT persist. |
| **BTR ratchet state** | Memory only | HIGH | HIGH | Transfer-scoped | Cleared after transfer. MUST NOT persist beyond active transfer. |
| **BTR chain keys / derived keys** | Memory only | HIGH | HIGH | Transfer-scoped | Minimal retention. Cleared with transfer context. |

### Trust Material

| Asset | Storage | Confidentiality | Integrity | Availability | Persistence |
|-------|---------|----------------|-----------|-------------|-------------|
| **TOFU pin store** | Daemon: `trust.json` (data_dir). Browser: IndexedDB. | LOW (peer codes + public keys) | HIGH (tampering = TOFU bypass) | MEDIUM | Persistent |
| **SAS verification code** | Displayed in UI only | LOW (short-lived, public to both peers) | HIGH (wrong code = wrong peer verified) | Session-scoped | Not persisted |

### Transfer Data

| Asset | Storage | Confidentiality | Integrity | Availability | Persistence |
|-------|---------|----------------|-----------|-------------|-------------|
| **File contents in transit** | Envelope-encrypted over WS/WT | HIGH | HIGH (MAC) | Session-scoped | Not persisted beyond transport |
| **File contents at rest (received)** | ~/Downloads (daemon) or browser download | HIGH (user responsibility) | MEDIUM | Persistent | No at-rest encryption by Bolt |
| **Transfer metadata (filename, size, chunk count)** | Inside encrypted envelope | MEDIUM | HIGH | Transfer-scoped | Not persisted |

### Operational Material

| Asset | Storage | Confidentiality | Integrity | Availability | Persistence |
|-------|---------|----------------|-----------|-------------|-------------|
| **IPC messages** | Unix socket (0600) | MEDIUM (contains file paths, peer info) | HIGH | Session-scoped | Not persisted |
| **Signal files (send_file.signal)** | `data_dir/` (0700) | MEDIUM (contains file paths) | HIGH (tampering = wrong file sent) | Transient | Deleted after read |
| **Peer metadata (codes, device names, IPs)** | Memory (signaling state) | LOW | LOW | Session-scoped | Not persisted by Bolt (rendezvous may log) |
| **Logs / diagnostics** | stderr | LOW | LOW | Transient | MUST NOT contain secret keys |

---

## 4. Security Invariants

### Protocol Invariants (from ARCHITECTURE.md §2–3)

| ID | Invariant | Enforcement | Test Coverage |
|----|-----------|-------------|---------------|
| SI-01 | HELLO MUST be inside encrypted envelope | daemon: `web_hello.rs` parse_hello_typed decrypts. browser: HandshakeManager decrypts. | UNIT: web_hello tests. INTEROP: ws_hello_handshake_succeeds. |
| SI-02 | Handshake gating: only HELLO/ERROR/PING/PONG before mutual HELLO completion | daemon: envelope.rs route_inner_message. browser: WsDataTransport handleMessage pre_hello gate. | UNIT: envelope tests. |
| SI-03 | TOFU key mismatch MUST fail-closed (ERROR + close) | browser: HandshakeManager.processHello KeyMismatchError path. daemon: web_hello parse_hello_typed KeyMismatch. | UNIT: both. |
| SI-04 | Replay detection: (transfer_id, chunk_index) dedup | browser: TransferManager processChunkGuarded. daemon: not yet implemented (receive path new). | **GAP: daemon receive has no dedup.** |
| SI-05 | Fresh 24-byte CSPRNG nonce per envelope | bolt_core::crypto::seal_box_payload uses OsRng. TS: tweetnacl randomBytes. | UNIT: crypto tests. |
| SI-06 | Ephemeral keypair per connection, discarded on disconnect | Rust: generated in handle_connection. TS: generateEphemeralKeyPair in connect(). | **GAP: TS key zeroing not verified.** |
| SI-07 | MAC verified before plaintext processing | NaCl-box: decrypt fails if MAC invalid. | Inherent in crypto_box. |

### Capability Invariants

| ID | Invariant | Enforcement | Test Coverage |
|----|-----------|-------------|---------------|
| CI-01 | Capability advertisement MUST be truthful | daemon: DAEMON_CAPABILITIES const. Browser: localCapabilities array. | UNIT: daemon_capabilities tests. |
| CI-02 | Unnegotiated capabilities MUST NOT be acted on | daemon: envelope_v1_negotiated() guard. browser: negotiatedEnvelopeV1() check. | UNIT: envelope tests. |
| CI-03 | BTR MUST NOT be advertised without full implementation | daemon: BTR removed from caps (BROWSER-APP-DIRECT-1). Test asserts NOT present. | UNIT: rc5_btr_over_ws assertion. |

### Transfer Invariants

| ID | Invariant | Enforcement | Test Coverage |
|----|-----------|-------------|---------------|
| TI-01 | File chunks MUST be individually encrypted | daemon: seal_box_payload per chunk (send), open_box_payload per chunk (receive). browser: sealBoxPayload/openBoxPayload in TransferManager. | UNIT: envelope roundtrip tests. |
| TI-02 | Received filenames MUST be sanitized before filesystem write | **NOT ENFORCED.** Daemon writes `~/Downloads/{filename}` with no path traversal guard. | **GAP: No test. No sanitization.** |
| TI-03 | Transfer size MUST be bounded | **NOT ENFORCED.** Daemon accumulates all chunks in memory. | **GAP: No limit.** |

### IPC Invariants

| ID | Invariant | Enforcement | Test Coverage |
|----|-----------|-------------|---------------|
| IP-01 | IPC socket MUST be 0600 (owner-only) | transport.rs: chmod after bind. | UNIT: permission test. |
| IP-02 | IPC message size MUST be bounded | server.rs: MAX_LINE_BYTES = 1 MiB. | UNIT: bounded reader test. |
| IP-03 | Malformed IPC messages MUST fail-closed (disconnect client) | server.rs: parse_ipc_line returns Err → client disconnected. | UNIT: parse tests. |
| IP-04 | IPC SHOULD authenticate connecting client | **NOT ENFORCED.** Relies on socket permissions only. | **GAP: No client auth.** |

---

## 5. Bolt Transfer Ratchet (BTR) Security Model

### Role of BTR
BTR is the preferred file-transfer protection mode for Bolt-compatible endpoints that support `bolt.transfer-ratchet-v1`.

BTR strengthens transfer security beyond static session-key encryption by providing:
- per-transfer ratchet context
- per-chunk key evolution
- improved forward-secrecy properties within a transfer
- tighter isolation between chunks and transfers

BTR does not replace the overall session/authentication model.
It composes on top of the authenticated session established by the protocol.

### BTR Trust Assumptions
BTR assumes:
- the underlying session identity binding is already established correctly
- the negotiated peer identity/session is the intended peer
- both endpoints truthfully advertise `bolt.transfer-ratchet-v1`
- both endpoints implement the same ratchet semantics correctly

BTR does not protect against:
- a fully compromised endpoint that legitimately holds current ratchet state
- misleading UX that causes a user to verify the wrong peer/session
- false capability claims by an endpoint implementation
- insecure local storage of ratchet/session material

### Asset Classification
The following are security-sensitive assets under BTR:
- transfer ratchet state
- chain keys
- transfer-scoped derived keys
- current ratchet public/private material where applicable
- metadata that binds chunks to a specific transfer context

Required properties:
- confidentiality: high
- integrity: high
- persistence: minimal; retain no longer than required for active transfer semantics
- reuse: forbidden across unrelated transfers/sessions

### BTR Security Invariants
The system must preserve all of the following:

1. **Truthful advertisement**
   - No endpoint may advertise `bolt.transfer-ratchet-v1` unless it fully implements the BTR state machine required for both advertised directions.

2. **No silent downgrade**
   - If BTR is absent, disabled, or unsupported, negotiation outcome must be truthful and observable through normal capability negotiation semantics.
   - The system must not claim BTR protection when operating in static session-key mode.

3. **Transfer-scoped isolation**
   - Ratchet state must be scoped to the intended transfer/session context.
   - Ratchet state from one transfer must not be reused for another transfer.

4. **Directional correctness**
   - Sender and receiver must remain synchronized according to the BTR algorithm's defined state progression.
   - Mixed-direction same-session transfers must not corrupt or reuse ratchet state incorrectly.

5. **Session binding**
   - BTR state must be bound to the actual authenticated session/peer context.
   - Ratchet material from one peer/session must never be accepted for another.

6. **Fail-closed behavior**
   - Malformed, out-of-order, or unverifiable BTR payloads must fail closed.
   - Failure to decrypt/advance ratchet state must not silently produce unauthenticated plaintext.

7. **Minimal retention**
   - BTR state must be cleared when no longer needed for the active transfer/session semantics.
   - Endpoints should avoid unnecessary persistence of ratchet material.

### Security Consequences of Compromise
- **Compromised rendezvous server:**
  - may influence signaling metadata or attempt downgrade pressure
  - must not obtain plaintext file contents solely by controlling rendezvous
  - must not defeat BTR if endpoints negotiate and implement it correctly

- **Passive network observer:**
  - must not recover plaintext chunks or ratchet secrets

- **Active network meddler:**
  - may drop, delay, replay, or mutate traffic
  - must not successfully forge valid BTR-protected chunk contents without key material

- **Compromised endpoint:**
  - can compromise active transfer confidentiality/integrity for sessions it legitimately participates in
  - may expose current ratchet/session state
  - this is within blast radius and not something BTR alone can prevent

### Current-State Governance Note
Current direct browser↔daemon transport may temporarily operate without BTR where daemon support is incomplete.
This is acceptable only if:
- capability advertisement is truthful
- static session-key encryption remains authenticated and encrypted
- restoration of daemon-side BTR is tracked as mandatory follow-up work

Temporary absence of BTR must never be misrepresented as full BTR protection.

### Required Validation
The following validation is required before any endpoint may claim full BTR support:

- sender/receiver conformance tests
- cross-implementation golden vectors
- bidirectional same-session transfer tests
- downgrade/false-capability tests
- malformed state / out-of-order / replay handling tests where applicable

### Ownership
- Browser-only sessions: browser endpoint owns BTR state locally
- Native/CLI with daemon present: daemon is the canonical local owner of BTR state for daemon-mediated transfer paths
- Any implementation that does not own and correctly maintain BTR state must not advertise BTR support

---

## 6. Compromise Analysis

### Browser Endpoint Compromised

| Aspect | Impact |
|--------|--------|
| **Allows** | Read all plaintext for that browser's sessions. Steal identity key from IndexedDB. Forge messages as that identity. Modify TOFU pin store. |
| **Does not allow** | Compromise other browsers or native endpoints. Access daemon's identity key (different storage). Affect sessions the browser is not party to. |
| **Blast radius** | That browser origin's sessions only. |
| **Containment** | Origin sandbox. Other tabs/origins unaffected. Other devices unaffected. |

### Daemon Compromised

| Aspect | Impact |
|--------|--------|
| **Allows** | Read all plaintext for all daemon-mediated sessions. Steal persistent identity key. Forge messages. Modify trust store. Read/write local files. Control IPC. |
| **Does not allow** | Compromise remote peers. Compromise browser-only sessions that don't involve this daemon. Break other devices' sessions. |
| **Blast radius** | All sessions mediated by this daemon instance. All local data accessible to the daemon user. |
| **Containment** | OS process isolation. Different-user processes cannot access daemon socket or files. |

### Rendezvous Compromised

| Aspect | Impact |
|--------|--------|
| **Allows** | Metadata exposure (who connects when, IP addresses, peer codes). Signal injection/modification. Connection denial. Fake peer announcements. |
| **Does not allow** | Read file contents. Decrypt envelopes. Forge HELLO messages. Break SAS verification. Access identity keys. |
| **Blast radius** | Discovery/signaling layer. All users of that rendezvous instance affected for metadata. No plaintext exposure. |
| **Containment** | Protocol design: rendezvous is untrusted. End-to-end encryption is independent of rendezvous integrity. |

### Native Wrapper (Native Shell) Compromised

| Aspect | Impact |
|--------|--------|
| **Allows** | Send unauthorized IPC commands to daemon (file.send with arbitrary path). Modify UI display (show wrong SAS code). Trigger file picker with injected paths. |
| **Does not allow** | Directly access session keys (held by daemon). Decrypt in-transit data without daemon cooperation. Access other devices. |
| **Blast radius** | Local UI session. If daemon trusts IPC commands blindly, effective daemon compromise for file operations. |
| **Containment** | Daemon should validate IPC commands (file paths within allowed directories — currently NOT enforced). |

---

## 7. Protocol Surface Review

### Discovery / Signaling

| Risk | Expected Control | Status |
|------|-----------------|--------|
| Signal injection (fake connection_request) | User approval before connection | ENFORCED |
| Signal flooding / DoS | Rate limiting at rendezvous | **NOT ENFORCED** (RENDEZVOUS-HARDENING-1) |
| Metadata exposure | Rendezvous minimization | **PARTIAL** (RENDEZVOUS-HARDENING-1) |
| Duplicate signal auto-decline | Dedup by peer code | ENFORCED (BROWSER-APP-DIRECT-1) |

### Session-Key Exchange

| Risk | Expected Control | Status |
|------|-----------------|--------|
| MitM on session keys | SAS verification | ENFORCED |
| Key reuse across sessions | Fresh ephemeral per connection | ENFORCED |
| Key persistence after disconnect | Memory zeroing | **PARTIAL** (Rust: yes. TS: gap identified) |

### HELLO / Capability Negotiation

| Risk | Expected Control | Status |
|------|-----------------|--------|
| False capability advertisement | Truthful DAEMON_CAPABILITIES | ENFORCED |
| Capability downgrade attack | Intersection negotiation + UI indication | **PARTIAL** (negotiation correct; UI indication limited) |
| Duplicate HELLO | Exactly-once guard (HelloState) | ENFORCED |
| Oversized capability array | Max 32 capabilities enforced | ENFORCED (browser SA17) |

### SAS Verification

| Risk | Expected Control | Status |
|------|-----------------|--------|
| SAS mismatch ignored by user | UI must display prominently | ENFORCED (both sides show SAS) |
| SAS computed over wrong keys | Raw 32-byte key inputs only | ENFORCED (PROTO-06) |
| SAS display inconsistency | Same algorithm, same inputs, both sides | ENFORCED (compute_sas canonical) |

### Transfer Encryption

| Risk | Expected Control | Status |
|------|-----------------|--------|
| Plaintext chunk exposure | Per-chunk seal_box_payload | ENFORCED |
| Chunk replay | (transfer_id, chunk_index) dedup | **PARTIAL** (browser: yes. daemon: NOT enforced) |
| Chunk tampering | NaCl-box MAC | ENFORCED (decrypt fails on tamper) |
| Oversized transfer / memory exhaustion | Transfer size limits | **NOT ENFORCED** (DAEMON-HARDENING-1) |

### IPC Control Path

| Risk | Expected Control | Status |
|------|-----------------|--------|
| Unauthorized IPC client | Socket permissions (0600) | ENFORCED |
| IPC client authentication | Process identity verification | **NOT ENFORCED** (DAEMON-HARDENING-1) |
| Malformed IPC message | Bounded reader + fail-closed parse | ENFORCED |
| Path traversal via file.send | Restrict to allowed directories | **NOT ENFORCED** (DAEMON-HARDENING-1) |

### File Receive / Write Path

| Risk | Expected Control | Status |
|------|-----------------|--------|
| Path traversal in filename | Sanitize before write | **NOT ENFORCED** (ENDPOINT-SECURITY-1) |
| Symlink following | Check target before write | **NOT ENFORCED** |
| Overwrite existing files | Unique naming or confirmation | **NOT ENFORCED** |
| Disk exhaustion | Size limit before accumulation | **NOT ENFORCED** (DAEMON-HARDENING-1) |

---

## 8. Invariant-to-Test Matrix

### Covered (test exists)

| Invariant | Test Location | Stream |
|-----------|--------------|--------|
| SI-01 HELLO encrypted | `bolt-daemon/src/web_hello.rs` tests, `ws_endpoint::tests::ws_hello_handshake_succeeds` | Existing |
| SI-02 Handshake gating | `bolt-daemon/src/envelope.rs` route_inner_message tests | Existing |
| SI-03 TOFU fail-closed | `bolt-daemon/src/web_hello.rs` key_mismatch tests | Existing |
| SI-05 Fresh nonce | Inherent in NaCl-box (OsRng) | Existing |
| SI-07 MAC before plaintext | Inherent in crypto_box | Existing |
| CI-01 Truthful caps | `bolt-daemon/tests/rc5_btr_over_ws.rs` (BTR NOT present assertion) | Existing |
| CI-02 Unnegotiated guard | `bolt-daemon/src/envelope.rs` envelope_v1_negotiated tests | Existing |
| IP-01 Socket 0600 | `bolt-daemon/src/ipc/transport.rs` permission tests | Existing |
| IP-02 Message size | `bolt-daemon/src/ipc/server.rs` bounded reader tests | Existing |
| IP-03 Malformed fail-closed | `bolt-daemon/src/ipc/server.rs` parse tests | Existing |
| TI-01 Chunk encryption | `bolt-daemon/tests/rc5_btr_over_ws.rs` framing tests, envelope roundtrip | Existing |

### Gap (test missing)

| Invariant | What's Missing | Owning Stream |
|-----------|---------------|---------------|
| SI-04 Replay dedup | Daemon receive has no (transfer_id, chunk_index) dedup | DAEMON-HARDENING-1 |
| SI-06 TS key zeroing | Browser ephemeral keys not zeroed on disconnect (TS limitation) | ENDPOINT-SECURITY-1 |
| TI-02 Filename sanitization | No path traversal test, no sanitization code | ENDPOINT-SECURITY-1 |
| TI-03 Transfer size limit | No memory/disk bound on received transfer | DAEMON-HARDENING-1 |
| IP-04 IPC client auth | No client process verification | DAEMON-HARDENING-1 |
| BTR cross-impl vectors | No golden vectors between Rust bolt-btr and TS BtrTransferAdapter | DAEMON-BTR-1 |
| BTR transfer isolation | No test for ratchet state reuse across transfers | DAEMON-BTR-1 |
| Rendezvous rate limiting | No rate limit tests | RENDEZVOUS-HARDENING-1 |
| Protocol compliance matrix | No systematic MUST/MUST NOT coverage audit | PROTOCOL-HARDENING-1 |

---

## 9. Audit Findings Summary

Findings from code audit performed 2026-03-24 during SECURITY-MODEL-1.

### High Severity

| ID | Finding | Location | Owning Stream |
|----|---------|----------|---------------|
| F-HIGH-01 | Browser identity keys loaded from IndexedDB are never zeroed from memory | `ts/bolt-transport-web/src/services/identity/identity-store.ts` | ENDPOINT-SECURITY-1 |
| F-HIGH-02 | No received filename path traversal guard | `bolt-daemon/src/ws_endpoint.rs` run_read_loop file save path | ENDPOINT-SECURITY-1 |

### Medium Severity

| ID | Finding | Location | Owning Stream |
|----|---------|----------|---------------|
| F-MED-01 | TS sealBoxPayload/openBoxPayload do not zero nonce after use | `ts/bolt-core/src/crypto.ts` | ENDPOINT-SECURITY-1 |
| F-MED-02 | BtrTransferContext intermediate keys not fully zeroed on cleanup | `ts/bolt-core/src/btr/state.ts` | DAEMON-BTR-1 |
| F-MED-03 | No IPC client authentication beyond socket permissions | `bolt-daemon/src/ipc/server.rs` | DAEMON-HARDENING-1 |
| F-MED-04 | Daemon receive path has no transfer replay dedup | `bolt-daemon/src/ws_endpoint.rs` run_read_loop | DAEMON-HARDENING-1 |
| F-MED-05 | No transfer size limit — unbounded memory accumulation | `bolt-daemon/src/ws_endpoint.rs` active_receives HashMap | DAEMON-HARDENING-1 |

### Low Severity

| ID | Finding | Location | Owning Stream |
|----|---------|----------|---------------|
| F-LOW-01 | Trust store JSON load does not validate schema against injection | `bolt-daemon/src/ipc/trust.rs` | DAEMON-HARDENING-1 |
| F-LOW-02 | Signal file (send_file.signal) path not restricted to data_dir | `bolt-daemon/src/main.rs` signal watcher | DAEMON-HARDENING-1 |

---

## 10. Stream Dependency Map

```
SECURITY-MODEL-1 (this document)
    │
    ├── DAEMON-BTR-1 (P1: restore forward secrecy)
    │       └── DEWEBRTC-1 (P5: remove legacy attack surface)
    │
    ├── DAEMON-HARDENING-1 (P2: harden local authority)
    │       Fixes: F-MED-03, F-MED-04, F-MED-05, F-LOW-01, F-LOW-02
    │
    ├── RENDEZVOUS-HARDENING-1 (P3: harden relay)
    │
    ├── PROTOCOL-HARDENING-1 (P4: spec compliance)
    │       └── ENDPOINT-SECURITY-1 (P6: harden endpoints)
    │               Fixes: F-HIGH-01, F-HIGH-02, F-MED-01, F-MED-02
    │
    └── DEWEBRTC-1 (P5: reduce attack surface)
```
