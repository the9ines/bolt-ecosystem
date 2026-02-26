# SDK API Design

Bolt Core SDK productization, API ergonomics, and stability.

---

## Transport Agnosticism

- SDK Core layer MUST be transport-agnostic.
- Transports are pluggable via Profile adapters.
- Profile adapters provide: rendezvous binding, peer-channel binding, encoding hooks.
- SDK Core MUST NOT import or depend on any transport library directly.

---

## Public API Stability Rules

### Semver Policy

- SDK follows strict semver aligned with bolt-core-sdk tag format (`sdk-vX.Y.Z`).
- Public API changes require minor or major bump.
- Internal refactors with no API change: patch bump only.

### Deprecation Policy

- Deprecated APIs MUST be marked with deprecation notice and target removal version.
- Deprecated APIs MUST remain functional for at least one minor version cycle.
- Removal only on major version bump.

### Feature Flags

- New optional protocol features gated via `bolt.*` capabilities.
- SDK MUST support capability negotiation at HELLO.
- Unknown capabilities MUST be ignored, not rejected.

---

## Canonical Types

These are the public-facing types the SDK exposes:

| Type | Description |
|------|-------------|
| `IdentityKey` | Persistent X25519 public key (32 bytes) |
| `EphemeralKey` | Per-connection X25519 public key (32 bytes) |
| `Envelope` | sender_ephemeral_key + nonce + ciphertext |
| `Hello` | bolt_version, capabilities, encoding, identity_key, limits |
| `TransferId` | 16-byte CSPRNG random identifier |
| `FileOffer` | transfer_id, filename, size, total_chunks, chunk_size, file_hash |
| `FileChunk` | transfer_id, chunk_index, total_chunks, payload |
| `Limits` | max_file_size, max_total_chunks, max_concurrent_transfers |
| `SasCode` | 6-char uppercase hex string |
| `BoltError` | code (from error taxonomy) + message + optional transfer_id |

---

## Forbidden Patterns

- MUST NOT expose NaCl box primitives directly in public API.
- MUST NOT expose ephemeral secret key type publicly.
- MUST NOT expose identity secret key type publicly.
- MUST NOT leak Profile-specific fields (e.g. camelCase JSON names) into Core types.
- MUST NOT allow callers to construct envelopes with caller-supplied nonces.
- MUST NOT allow callers to skip MAC verification.

---

## Packaging Targets

### Rust Crate

- Crate name: `bolt-core`
- Workspace member in bolt-core-sdk repo.
- No default features that pull in a specific transport.
- Feature flags for optional capabilities (e.g. `file-hash`).

### TypeScript Package

- Package name: `@the9ines/bolt-core`
- Published to npm.
- ESM and CJS builds.
- Zero transport dependencies at Core level.

### Version Alignment

- Rust crate version and TS package version SHOULD track sdk-vX.Y.Z tag.
- Both packages MUST implement the same Core version.
- Conformance test vectors shared between Rust and TS implementations.

---

## API Design Checklist

- [ ] All public types map to Bolt Core message model.
- [ ] No transport-specific types in Core API surface.
- [ ] Envelope construction handles nonce generation internally.
- [ ] Key generation handled internally (caller receives public key only).
- [ ] Error types map to Bolt Core error taxonomy.
- [ ] Capability negotiation exposed but not bypassable.
- [ ] SAS computation is a single function call with well-typed inputs.
- [ ] State machine transitions enforced (cannot send FILE_OFFER before HELLO).
