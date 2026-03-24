# Bolt Ecosystem — Architecture

> **Status:** Normative
> **Last Updated:** 2026-03-22
> **Canonical Protocol Spec:** `bolt-protocol/PROTOCOL.md` (canonical)

This document defines architectural invariants, security guarantees, protocol structure, and repository boundaries for the Bolt ecosystem. It uses RFC 2119 language: MUST, MUST NOT, NEVER, REQUIRED, SHOULD.

**Authority:** If conflict exists between PROTOCOL.md and this document, PROTOCOL.md is authoritative. This document references PROTOCOL.md; it does not restate wire-level details unless citing the exact source.

---

## 1. Bolt Protocol Architecture

### Core vs Profile Separation

Bolt Core:
- MUST be transport-agnostic.
- Defines identity, handshake, encrypted envelope, state machines.
- MUST NOT reference specific transports or serialization formats.

Profiles:
- Bind Bolt Core to concrete transports and encodings.
- LocalBolt Profile uses WebRTC and json-envelope-v1.
- ByteBolt Profile may use libdatachannel and relay.

Prohibited:
- Adding transport terminology to Core.
- Mixing product logic into protocol specification.
- Reimplementing protocol rules inside product repositories.

### Core Denylist

The following terms MUST NOT appear in Bolt Core specification or Core SDK code:

**Transport terms:**
`WebRTC`, `WebSocket`, `DataChannel`, `SDP`, `ICE`, `STUN`, `TURN`,
`libdatachannel`, `RTCPeerConnection`, `RTCDataChannel`, `wss://`, `ws://`

**Encoding terms:**
`json-envelope-v1`, `bin-v1`, `JSON`, `UTF-8`, `base64`, `hex`,
`camelCase`, `snake_case`

**Allowed exception:**
- "Profile-defined encoding identifier" (abstract reference only)

---

## 2. Protocol Invariants

These invariants are derived from PROTOCOL.md. See PROTOCOL.md for canonical wire-level definitions.

| ID | Invariant | Normative |
|----|-----------|-----------|
| PROTO-01 | HELLO MUST be inside an encrypted envelope | REQUIRED |
| PROTO-02 | Handshake gating MUST be enforced — only HELLO/ERROR/PING/PONG before mutual HELLO completion | REQUIRED |
| PROTO-03 | TOFU key mismatch MUST be fail-closed: ERROR(KEY_MISMATCH) then close session | REQUIRED |
| PROTO-04 | Replay detection MUST cover (transfer_id, chunk_index) | REQUIRED |
| PROTO-05 | file_hash MUST only be required when bolt.file-hash is negotiated | REQUIRED |
| PROTO-06 | SAS MUST be computed over raw 32-byte keys, not encoded representations | REQUIRED |
| PROTO-07 | All protected messages MUST be inside an encrypted envelope | REQUIRED |
| PROTO-08 | ERROR MUST be inside an encrypted envelope | REQUIRED |

### Envelope Schema, HELLO Contents, and SAS Computation

Canonical definitions for envelope fields, HELLO message contents, and SAS computation live in PROTOCOL.md. See:
- PROTOCOL.md § Encrypted Envelope — field names, types, sizes
- PROTOCOL.md § HELLO — required and optional fields
- PROTOCOL.md § SAS Verification — computation inputs and display format

Key behavioral constraints (enforced here, defined there):
- HELLO MUST NOT contain ephemeral key. Ephemeral public key comes from the envelope header.
- SAS MUST be computed over raw bytes, not encoded representations.

### Handshake Gating

Before mutual HELLO completion, a peer MUST accept only:
1. PING / PONG (plaintext)
2. Encrypted envelope containing HELLO
3. Encrypted envelope containing ERROR

All other messages MUST be rejected with `ENVELOPE(ERROR(INVALID_STATE))`.
Each peer MUST send exactly one HELLO per connection attempt.

### Protected vs Unprotected Messages

**Protected (MUST be inside envelope):**
HELLO, FILE_OFFER, FILE_ACCEPT, FILE_CHUNK, FILE_FINISH, PAUSE, RESUME, CANCEL, ERROR

**Unprotected (plaintext, no envelope):**
PING, PONG

Unprotected messages MUST NOT contain sensitive data.

---

## 3. Security Invariants

| ID | Invariant | Normative |
|----|-----------|-----------|
| SEC-01 | Every encrypted envelope MUST use a fresh 24-byte CSPRNG nonce | REQUIRED |
| SEC-02 | Nonce MUST NOT be reused with the same ephemeral keypair | NEVER |
| SEC-03 | Fresh X25519 ephemeral keypair MUST be generated per connection | REQUIRED |
| SEC-04 | Ephemeral secret keys MUST NOT be persisted to disk or logged | NEVER |
| SEC-05 | Ephemeral keys MUST be discarded on disconnection (provides forward secrecy) | REQUIRED |
| SEC-06 | MAC MUST be verified before any plaintext processing | REQUIRED |
| SEC-07 | Identity keys MUST NOT be used for bulk encryption | NEVER |

### Ephemeral Key Lifecycle

- Fresh X25519 ephemeral keypair generated per connection.
- Used for all protected messages within that session.
- MUST NOT be rotated mid-session in v1.
- MUST be discarded on disconnection.
- MUST NOT be persisted to disk.
- MUST NOT be reused across connections.

### TOFU Pinning Flow

- **First contact**: SHOULD prompt SAS verification. Pin key on acceptance.
- **Known key match**: proceed silently.
- **Key mismatch**: MUST send ENVELOPE(ERROR(KEY_MISMATCH)) and close session.
  - MUST present clear warning to user.
  - Re-pairing MUST delete old pinned key.
  - Re-pairing MUST store new key.
  - Re-pairing MUST require SAS confirmation.

This is fail-closed: mismatch always blocks, never falls through.

### Decrypt Failure Handling

- If decryption fails, receiver SHOULD send ENVELOPE(ERROR(ENCRYPTION_FAILED)).
- Receiver MAY terminate session without response if unsafe to reply.
- MUST NOT process message contents before MAC verification passes.
- MUST NOT silently ignore decrypt failures.

### Replay Protection

- Scoped per (transfer_id, chunk_index).
- Receiver MUST reject duplicate chunk_index for same transfer_id.
- Receiver MUST reject chunk_index >= total_chunks.

### Threat Model

| Threat | Mitigation |
|--------|-----------|
| Rendezvous MITM | Detectable via SAS |
| Eavesdropping | NaCl box encryption |
| Replay | (transfer_id, chunk_index) dedup |
| File tampering | SHA-256 file_hash when negotiated |
| Identity impersonation | TOFU pinning + SAS |
| Key compromise (identity) | Forward secrecy via ephemeral keys |
| Nonce reuse | CSPRNG per envelope |
| Traffic analysis | Not mitigated (non-goal) |

---

## 4. Shared Cryptographic Stack

Encryption:
- X25519.
- NaCl box using XSalsa20-Poly1305.
- TweetNaCl-compatible implementations.
- 24-byte cryptographically random nonce per envelope.
- Nonce reuse with the same ephemeral keypair is forbidden.

Transport (Profile-level, not Core):
- WebRTC DataChannel in LocalBolt Profile.
- libdatachannel in ByteBolt Profile.
- json-envelope-v1 encoding in LocalBolt Profile.

Server:
- Rust rendezvous server.
- Optional managed relay in bytebolt-relay.

Handshake invariants:
- HELLO message is always encrypted inside envelope.
- identity_key appears only inside HELLO.
- Ephemeral public key appears only in envelope header.
- SAS computation binds identity keys and envelope-carried ephemeral keys.

MUST preserve:
- Envelope-first security model.
- Handshake gating rules.
- bolt.file-hash capability negotiation.

---

## 5. Repository Boundaries

### What Lives Where

| Content | Repository | Notes |
|---------|-----------|-------|
| Bolt Core specification | bolt-protocol | PROTOCOL.md, profile docs, no code |
| Bolt Core SDK (Rust) | bolt-core-sdk | Reference implementation |
| Bolt Core SDK (TypeScript) | bolt-core-sdk | Same repo, separate package |
| Conformance test vectors | bolt-core-sdk | Shared between Rust and TS |
| App runtime core | bolt-core-sdk (`bolt-app-core`) | Shell-agnostic daemon lifecycle, IPC, watchdog, platform (ADR-001) |
| Desktop UI shell | bolt-core-sdk (`bolt-ui`) | egui/eframe native binary, consumes bolt-app-core |
| Rendezvous server (Rust) | bolt-rendezvous | Canonical implementation |
| Rendezvous (vendored) | localbolt, localbolt-app | Via git subtree only |
| Daemon (Rust) | bolt-daemon | Canonical implementation |
| Relay infrastructure | bytebolt-relay | Commercial |
| Web lite app | localbolt | Open source |
| Native multi-platform app | localbolt-app | Open source (**retired** — Tauri adapter. Desktop rollback CLOSED all platforms. Replaced by bolt-ui.) |
| Web app (Netlify) | localbolt-v3 | Open source |
| Commercial global app | bytebolt-app | Commercial |
| Protocol spec (stubs) | bolt-core-sdk | Stubs pointing to bolt-protocol |

### Subtree Policy

- bolt-rendezvous is vendored into product repos via `git subtree`.
- Subtree prefix: `signal/` (in localbolt and localbolt-app).
- Vendored code MUST NOT be modified in the product repo.
- All fixes and features MUST be made upstream in bolt-rendezvous.
- Pull upstream: `git subtree pull --prefix=signal <remote> main --squash`

### No Code Copying Rule

- MUST NOT copy source files between repositories.
- MUST NOT duplicate protocol logic across repos.
- Use one of:
  - **Dependency**: add bolt-core-sdk as a package dependency.
  - **Subtree**: vendor bolt-rendezvous via git subtree.
- If logic is needed in two places, it belongs in a shared dependency (SDK or rendezvous).

### Canonical Repo Allowed Contents

| Repo | Allowed | Forbidden |
|------|---------|-----------|
| bolt-protocol | Markdown specs only | Code, configs, CI |
| bolt-core-sdk | SDK code, tests, spec stubs, bolt-app-core, bolt-ui | Product-specific policy, Tauri deps |
| bolt-rendezvous | Rendezvous server code | Protocol logic, UI |
| bolt-daemon | Daemon code, IPC API | Protocol logic, UI |
| localbolt | Web app, vendored signal | SDK internals, spec |
| localbolt-app | Tauri shell adapter (**retired** — replaced by bolt-ui) | Runtime logic (moved to bolt-app-core) |
| localbolt-v3 | Web app (TS only) | Servers, daemons, native code |
| bytebolt-app | Commercial app | Open-source protocol changes |
| bytebolt-relay | Relay infra | Protocol changes, free features |

---

## 6. Build and Integration Rules

### Per-Repo Runtime Constraints

| Repo | Bundles Rendezvous | Bundles Daemon | Offline Capable |
|------|--------------------|----------------|-----------------|
| localbolt | Yes (subtree) | No (initially) | Yes |
| localbolt-app | Yes (subtree) | Yes | Yes |
| localbolt-v3 | Yes (cargo git dep) | No | No |
| bytebolt-app | No (uses relay) | Yes | No |

- localbolt-v3 MUST NOT bundle servers, daemons, or native binaries.
- localbolt-v3 connects to hosted bolt-rendezvous endpoint only.

### Offline and Online Requirement

localbolt and localbolt-app MUST support:
- **Offline mode**: local rendezvous server on LAN, no internet required.
- **Online mode**: optional remote rendezvous for broader discovery.

The application MUST function without internet connectivity when peers are on the same network.

### Protocol Integration Rule

- Products MUST depend on bolt-core-sdk for all protocol logic.
- Products MUST NOT copy, fork, or reimplement:
  - Envelope encryption/decryption
  - HELLO handshake
  - SAS computation
  - State machine transitions
  - Message serialization at Core level
- Profile-level encoding (e.g. json-envelope-v1 serialization) lives in SDK profile adapters, not in product code.

### Subtree Update Procedure (bolt-rendezvous)

1. Ensure product repo working tree is clean.
2. `git subtree pull --prefix=signal <bolt-rendezvous-remote> main --squash`
3. Resolve any conflicts (should be rare if subtree rule is followed).
4. Run full build and test suite.
5. Commit with message: `chore: update bolt-rendezvous subtree to <upstream-tag>`
6. Tag per repo convention.

MUST NOT modify files under the subtree prefix directly.

### Cargo Git Dependency Pattern

Some Rust crates are consumed via `cargo` git dependencies rather than crates.io
or local paths. This pattern applies when a crate lives in a sibling repository
that is not published to crates.io and cannot use a filesystem path (e.g., Docker
builds, CI runners without sibling repos on disk).

**Rationale:** bolt-rendezvous is not published to crates.io. Consumers that
cannot use a relative filesystem path (localbolt-v3 deploys on Fly.io,
bolt-daemon in standalone CI) use tagged git dependencies for deterministic
resolution.

**Current consumers:**

| Consumer | Crate | Source Repo | Pinned Tag |
|----------|-------|-------------|------------|
| localbolt-v3 (`packages/localbolt-signal`) | `bolt-rendezvous` | bolt-rendezvous | `rendezvous-v0.2.2-s0-canonical-lib-verified` |
| bolt-daemon | `bolt-rendezvous-protocol` | bolt-rendezvous | `rendezvous-v0.2.6-clean-1` |

**Mandatory tag pinning:** All cargo git dependencies MUST use `tag = "<tag>"`
pointing to an immutable, pushed tag in the source repository. Branch or revision
pins are prohibited — they create non-reproducible builds and violate tag
discipline.

**Example Cargo.toml entry:**

```toml
bolt-rendezvous-protocol = {
    git = "https://github.com/the9ines/bolt-rendezvous.git",
    tag = "rendezvous-v0.2.6-clean-1",
    package = "bolt-rendezvous-protocol"
}
```

**Update procedure:** When the source crate is updated and a new tag is pushed,
bump the `tag` field in Cargo.toml, run `cargo build` to update Cargo.lock,
verify tests pass, and commit both files.

### Rendezvous Trust Model

- Rendezvous is UNTRUSTED for confidentiality and integrity.
- MUST NOT rely on rendezvous for message secrecy or authentication.
- Rendezvous MAY observe: peer codes, IP addresses, timing, connection patterns.
- Rendezvous MUST NOT observe: file contents, filenames, encryption keys, transfer metadata.
- All security guarantees come from Bolt-layer encryption (envelope).

### Version Compatibility

- bolt-core-sdk version defines protocol compliance.
- Products MUST declare minimum supported SDK version.
- Profiles MUST declare supported Core version.
- Incompatible Core changes REQUIRE major version increment.

---

## 7. Architectural Invariants

These invariants REQUIRE explicit human approval to change:

| ID | Invariant |
|----|-----------|
| ARCH-01 | Core remains transport-agnostic |
| ARCH-02 | Encrypted envelope is mandatory for all protected messages |
| ARCH-03 | HELLO is always encrypted |
| ARCH-04 | Rendezvous infrastructure is untrusted |
| ARCH-05 | Relay is optional and commercial |
| ARCH-06 | SDK remains open |
| ARCH-07 | Infrastructure may be monetized |
| ARCH-08 | No new top-level folders under workspace root |
| ARCH-09 | Ephemeral keys are per connection and discarded on disconnect |
| ARCH-10 | Identity keys are persistent and TOFU-pinned |

Violation of any ARCH invariant MUST be escalated to human immediately.

---

## 8. Canonical Ownership & Promotion Order

### Canonical Authority

| Domain | Canonical Owner | Consumers |
|--------|----------------|-----------|
| Protocol specification | bolt-protocol | All repos |
| Protocol SDK (Rust + TS) | bolt-core-sdk | bolt-daemon, bolt-transport-web, product repos |
| App runtime core | bolt-core-sdk (`bolt-app-core`) | bolt-ui, localbolt-app, future mobile shells |
| Desktop UI shell | bolt-core-sdk (`bolt-ui`) | Standalone binary, future packaging |
| BTR (transfer ratchet) | bolt-core-sdk (`bolt-btr`) | bolt-daemon, bolt-transport-web |
| Daemon runtime | bolt-daemon | Product apps (sidecar or embedded) |
| Signaling server | bolt-rendezvous | Product apps (embedded or hosted) |
| Browser transport | bolt-core-sdk (`bolt-transport-web`) | localbolt-v3, localbolt |

- `bolt-core-sdk` is the canonical shared-code authority. Protocol, BTR, transport, app runtime, and desktop shell all live here.
- `bolt-app-core` is canonical app/runtime truth. Future shells (SwiftUI, Kotlin) consume it via FFI.
- `bolt-ui` is the canonical desktop shell. It is a standalone binary — no WebView dependency.
- Product repos (`localbolt-v3`, `localbolt`, `localbolt-app`) are **consumers only**. They MUST NOT own protocol, runtime, or transport logic.
- `localbolt-app` is **retired**. Desktop rollback window CLOSED for all platforms (2026-03-22). `bolt-ui` is the canonical desktop shell. Tauri desktop path is no longer maintained.

### Product Policy Rule

- SDK/core provides capability (LAN and WAN capable).
- Products choose policy (e.g., `localbolt` is local-only by product policy, not SDK limitation).
- WAN/relay enablement belongs in product configuration, not in shared core.
- MUST NOT restrict shared core to serve a single product's policy.

### CI/CD Promotion Order

Release promotion follows the dependency graph. Upstream repos MUST pass before downstream consumers tag:

```
1. bolt-core-sdk        ←── canonical core: Rust + TS tests, bolt-app-core, bolt-ui
2. bolt-daemon          ←── daemon runtime tests, transport tests
   bolt-rendezvous      ←── server/protocol tests (parallel with daemon)
3. bolt-ui              ←── desktop shell build + tests (part of bolt-core-sdk workspace)
4. localbolt-v3         ←── consumer build/test
   localbolt-app        ←── retired (Tauri desktop path replaced by bolt-ui)
   future mobile shells ←── binding generation + shell smoke
5. bolt-ecosystem       ←── governance/docs sync (after code repos)
```

### Per-Repo CI Expectations

| Repo | Required CI | Notes |
|------|------------|-------|
| bolt-core-sdk | Rust unit/integration, TS package tests/build, cross-language vectors, bolt-app-core tests, bolt-ui tests/build | Canonical. All shared logic tested here. |
| bolt-daemon | Daemon tests (`cargo test --features transport-webtransport,transport-ws`), `cargo fmt`, `cargo clippy` | Includes WT/WS/QUIC transport tests. |
| bolt-rendezvous | Server + protocol tests | Independent of daemon. |
| localbolt-v3 | Consumer build + test only | MUST NOT duplicate SDK tests. |
| localbolt-app | **Retired** — no CI required | Freeze/archive. No new strategic work. |
| future iOS/Android | UniFFI binding generation + shell smoke | Platform CI (Xcode Cloud, Android SDK). |
| bolt-ecosystem | Docs/governance consistency checks | No code tests. |

### Release Tag Gate

- Tags MUST NOT be created until the repo's full CI suite passes.
- Downstream consumers SHOULD pin to upstream tags, not branches.
- Tag format per repo is defined in the ecosystem's SRE Policy (see CLAUDE.md § Tag Discipline).

---

## 9. Language Ownership & Drift Policy

> Audited: 2026-03-23. See `docs/evidence/ARCHITECTURE_AUDIT_2026-03-23.md`.

### Rust-First Principle

Rust is the canonical language for protocol, crypto, transfer, runtime, and daemon logic. TypeScript owns browser-only concerns (WebRTC, DOM, IndexedDB, signaling WebSocket client). TS MUST NOT grow into protocol authority.

### Language Ownership Table

| Domain | Canonical Language | Notes |
|--------|-------------------|-------|
| Protocol / wire format | Rust | TS mirrors; does not author |
| Crypto (NaCl, BTR, key management) | Rust / WASM | TS is fallback only |
| Transfer state machine | Rust (bolt-transfer-core) | TS adapter layer acceptable |
| App runtime / lifecycle | Rust (bolt-app-core) | Shells consume via API/FFI |
| Desktop shell | Rust (bolt-ui / egui) | No WebView dependency |
| Daemon transport | Rust (WS/WT/QUIC endpoints) | Canonical transport authority |
| Browser↔app transport | Rust daemon + TS adapter (BrowserAppTransport) | Direct WS/WT, not WebRTC |
| Browser↔browser transport | TS (WebRTCService) | Necessarily browser-side |
| Signaling server | Rust (bolt-rendezvous) | Canonical |
| Browser signaling client | TS (WebSocketSignaling) | Browser API binding |
| Web shell | TS (localbolt-v3) | Consumer only |

### Anti-Patterns (Prohibited)

These patterns MUST NOT be introduced. Violations should be escalated.

| ID | Anti-Pattern | Rationale |
|----|-------------|-----------|
| AP-01 | New strategic work in `localbolt-app` | Desktop is `bolt-ui`. Tauri is retired. |
| AP-02 | Deepening daemon↔browser WebRTC interop | Direct transport (WS/WT) is the browser↔app path. |
| AP-03 | New TS crypto logic | Rust/WASM is crypto authority. |
| AP-04 | New TS transfer orchestration authority | Rust SM is canonical. |
| AP-05 | TS protocol wire format changes | Wire format owned by Rust core. |

### Browser↔App Transport Direction

The canonical browser↔desktop path is **direct transport** via daemon WS/WT endpoints:
- Browser uses `BrowserAppTransport` (WS primary, WT upgrade)
- Daemon serves via `ws_endpoint.rs` / `wt_endpoint.rs`
- Protocol: session-key → HELLO → ProfileEnvelopeV1 → file transfer
- Discovery/approval flows through signaling relay; transport is direct

WebRTC is retained for **browser↔browser only**. MUST NOT be extended as the browser↔daemon transport path.

### Signaling Endpoint Policy

Signaling endpoint selection MUST be security-context-aware:

1. **HTTPS origins MUST NOT attempt insecure `ws://` signaling connections.** Browsers block mixed content (HTTPS page → ws:// WebSocket). Attempting `ws://` from an HTTPS page is a bug, not acceptable fallback behavior.

2. **Localhost/dev origins (`http://localhost`, `http://127.0.0.1`) MAY use `ws://`.** Browser mixed-content policy does not apply to localhost origins.

3. **Public HTTPS deployments MUST use `wss://` for cloud signaling.** This is already the case for Fly.io-hosted rendezvous.

4. **Local/LAN signaling (embedded rendezvous) is only available when:**
   - The page is served from `http://` (dev mode), OR
   - The desktop app embeds the signaling server and connects locally (not subject to browser mixed-content rules)

5. **Endpoint selection logic MUST be deterministic and origin-aware.** The app MUST inspect its own origin protocol (`https:` vs `http:`) before constructing signaling URLs.

6. **Mixed-content signaling attempts are protocol violations**, not graceful degradation. They MUST NOT be attempted.

---

## 10. Security Model

### Trust Boundaries

| Boundary | Trust Level | Notes |
|----------|------------|-------|
| **Rendezvous server** | Untrusted | Routes encrypted envelopes. Cannot read contents. Sees IP addresses, peer codes, connection metadata. Compromise reveals who is talking to whom, not what they say. |
| **Daemon (local)** | Trusted local agent | Owns identity keys, session keys, crypto operations. Compromise of the daemon process is full compromise of that endpoint — keys, plaintext, transfer data. Protected by OS process isolation and filesystem permissions. |
| **Browser endpoint** | Trusted local agent | Same authority as daemon when daemon is absent. Identity keys in IndexedDB (origin-scoped). Compromise of the browser tab/origin is full compromise of that endpoint. |
| **Native endpoint (bolt-ui)** | Trusted local UI | Communicates with daemon via local IPC. Does not hold crypto keys directly — daemon is the crypto authority. Compromise of bolt-ui without daemon compromise reveals UI state but not plaintext content in transit. |
| **Local IPC (Unix socket)** | Trusted local channel | Protected by filesystem permissions (0600). Compromise requires local root or same-user access — equivalent to daemon compromise. |
| **Network transport (WS/WT)** | Untrusted | All data is envelope-encrypted. Transport is untrusted by design. MitM sees ciphertext only. |

### Attacker Model

| Attacker | Can do | Cannot do |
|----------|--------|-----------|
| **Network observer** | See encrypted frames, connection timing, frame sizes | Read plaintext, forge messages, replay (transfer_id+chunk_index dedup) |
| **Compromised rendezvous** | Inject signals, drop connections, log metadata | Read envelope contents, forge HELLO, break SAS verification |
| **Compromised daemon** | Read all plaintext, forge messages, steal identity | Compromise other endpoints not connected to this daemon |
| **Compromised browser** | Same as daemon for that session | Compromise other browsers or native endpoints |
| **Local user (same OS user)** | Access daemon IPC socket, read identity keys from disk | Nothing beyond what the daemon itself can do |

### Asset Classes

| Asset | Storage | Protection |
|-------|---------|------------|
| Identity keypair (Ed25519) | Daemon: `data_dir/identity.key` (0600). Browser: IndexedDB (origin-scoped). | Filesystem perms / browser sandbox. |
| Ephemeral session keys (X25519) | Memory only | Discarded on disconnect. Never persisted. |
| TOFU pin store | Browser: IndexedDB. Daemon: `trust.json` in data_dir. | Filesystem perms / browser sandbox. |
| File contents in transit | Envelope-encrypted over WS/WT | NaCl-box (XSalsa20-Poly1305). Per-chunk encryption. |
| File contents at rest (received) | Written to ~/Downloads (daemon) or browser download | No at-rest encryption by Bolt. OS responsibility. |

### Compromise Consequences

| Component compromised | Impact | Blast radius |
|----------------------|--------|-------------- |
| Rendezvous | Signal injection, metadata exposure, DoS | Connection layer only. No plaintext exposure. |
| Single daemon | Full endpoint compromise for that device | That device's sessions only. Other peers unaffected. |
| Single browser tab | Full endpoint compromise for that origin | That browser session only. |
| Local IPC | Equivalent to daemon compromise | Same as daemon. |
| Network transport | None (untrusted by design) | Ciphertext only. |

---

## 11. Daemon Role

### Authority Model

When present, bolt-daemon is the **canonical local protocol authority** for native apps and CLI clients:

1. **Identity**: Daemon owns the persistent identity keypair. Native UI (bolt-ui) does NOT hold identity keys — it delegates to the daemon.
2. **Trust/Pinning**: Daemon maintains the TOFU pin store. Pin decisions are made by the daemon based on UI input via IPC.
3. **Session Establishment**: Daemon performs HELLO exchange, capability negotiation, SAS computation. Native UI receives session state via IPC events.
4. **Crypto Operations**: All envelope encryption/decryption happens in the daemon. Native UI never touches plaintext in transit.
5. **Transfer Engine**: Daemon chunks, encrypts, and sends files. Daemon receives, decrypts, and saves files. Native UI triggers send via signal file; receives completion notification via daemon stderr/IPC.
6. **IPC Contract**: NDJSON over Unix socket (0600). Daemon → UI: events. UI → daemon: decisions. Bidirectional. Single-client at a time.

### Truthful Capability Advertisement

The daemon MUST NOT advertise capabilities it does not implement. Capability advertisement in HELLO is a protocol-level contract:

- If `bolt.transfer-ratchet-v1` is advertised, the daemon MUST be able to seal and open BTR-encrypted chunks.
- If `bolt.profile-envelope-v1` is advertised, the daemon MUST correctly encode and decode ProfileEnvelopeV1 frames.
- Advertising a capability the daemon cannot fulfill is a protocol violation.

### Daemon Is Not Mandatory

The daemon is the authority **when present**. Browser-only sessions (no daemon) are fully valid:

- Browser generates its own ephemeral keypair
- Browser manages its own identity and TOFU pin store (IndexedDB)
- Browser performs HELLO, SAS, envelope encryption directly
- Protocol guarantees are identical in both modes

The daemon adds: persistent identity across sessions, native file system access, CLI/automation support, and centralized crypto authority for multiple native UI clients.

---

## 12. WebRTC Disposition

### Current State

bolt-daemon contains WebRTC/DataChannel code from the rendezvous transport path. This code is **transitional legacy**.

### Target State

| Product | WebRTC | Direct Transport (WS/WT) |
|---------|--------|--------------------------|
| LocalBolt web (browser↔browser) | Retained (only path) | N/A |
| LocalBolt web↔desktop | **Deprecated** | **Canonical** (BROWSER-APP-DIRECT-1) |
| ByteBolt (all) | **Never** | **Only path** |
| bolt-daemon | **Legacy** | **Forward direction** |

### Governance Rules

1. **No new product work may deepen WebRTC paths.** Anti-pattern AP-02 (ARCHITECTURE.md §9) prohibits extending browser↔daemon WebRTC interoperability.
2. **ByteBolt is zero-WebRTC by design.** bytebolt-relay and bytebolt-app MUST NOT contain WebRTC dependencies.
3. **Bolt target state is zero WebRTC.** The direct WS/WT transport path replaces WebRTC for all non-browser-to-browser connections.
4. **DEWEBRTC-1** will formalize retirement of WebRTC code from bolt-daemon when the direct transport path is fully hardened.

### Drift Tracking

| Item | Severity | Current State | Target |
|------|----------|--------------|--------|
| `localbolt-app` not frozen | MEDIUM | Retired but not archived | Freeze/archive repo |
| Browser transfer TS thickness | MEDIUM | `TransferManager.ts` ~865 lines | Converge toward Rust/WASM SM |
| Browser crypto dual-path | LOW | TS NaCl + Rust/WASM both active | WASM-first, TS fallback only |
| `localbolt-core` TS orchestration | LOW | Session state, peer code gen | Acceptable adapter layer |
