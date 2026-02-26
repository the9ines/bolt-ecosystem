# Bolt Ecosystem — Architecture

> **Status:** Normative
> **Last Updated:** 2026-02-21
> **Canonical Protocol Spec:** `bolt-core-sdk/PROTOCOL.md` (until bolt-protocol is separated)

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
| Rendezvous server (Rust) | bolt-rendezvous | Canonical implementation |
| Rendezvous (vendored) | localbolt, localbolt-app | Via git subtree only |
| Daemon (Rust) | bolt-daemon | Canonical implementation |
| Relay infrastructure | bytebolt-relay | Commercial |
| Web lite app | localbolt | Open source |
| Native multi-platform app | localbolt-app | Open source |
| Web app (Netlify) | localbolt-v3 | Open source |
| Commercial global app | bytebolt-app | Commercial |
| Protocol spec (temp) | bolt-core-sdk | Until bolt-protocol separated |

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
| bolt-core-sdk | SDK code, tests, spec (temp) | Product UI, transport impl |
| bolt-rendezvous | Rendezvous server code | Protocol logic, UI |
| bolt-daemon | Daemon code, IPC API | Protocol logic, UI |
| localbolt | Web app, vendored signal | SDK internals, spec |
| localbolt-app | Tauri app, vendored signal+daemon | SDK internals, spec |
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
| localbolt-v3 | No | No | No |
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
