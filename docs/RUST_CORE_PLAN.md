# Rust Canonical Core — Design Memo

> **Status:** DRAFT — design review, no production code yet.
> **Date:** 2026-02-24
> **Scope:** bolt-core-sdk `rust/bolt-core` crate (existing v0.1.0)

---

## 1. Current State

### 1.1 TypeScript (shipped, adopted)

| Package | Version | Public Exports | Tests |
|---------|---------|---------------|-------|
| `@the9ines/bolt-core` | 0.4.0 | 21 | 76 (vitest) |
| `@the9ines/bolt-transport-web` | 0.6.0 | N/A | 117 (vitest, jsdom) |

Consumers: localbolt, localbolt-app, localbolt-v3 (all on 0.4.0 / 0.6.0).

### 1.2 Rust (vector authority only)

| Item | Status |
|------|--------|
| `rust/bolt-core` v0.1.0 | Constants + vector generator |
| `constants` module | 8 constants, aligned with TS |
| `vectors` module | Box-payload + framing JSON generators |
| Golden vector tests | 3 compat + 2 equivalence (parse + structure) |
| Crypto API | **Not exposed** — `crypto_box` 0.9 used internally by vector generator only |

The Rust crate can produce the same sealed payloads as TS for fixed inputs
(vectors.rs), but exposes no public `seal`/`open` functions.

---

## 2. Interop Decision

### Decision: Dual-runtime, NOT wasm32 replacement

**Rust is the canonical implementation for native targets (daemon, Tauri,
CLI).** TypeScript remains the canonical implementation for browser/web
targets. Rust does NOT compile to wasm32 to replace TS crypto in the browser.

### Rationale

| Factor | wasm32 replacement | Dual-runtime (chosen) |
|--------|-------------------|----------------------|
| Browser bundle size | +200-400KB (crypto_box + wasm glue) | Zero (TS uses tweetnacl, 7KB) |
| Web Worker threading | Complex (SharedArrayBuffer, COOP/COEP headers) | Not needed |
| tweetnacl maturity | Discarded | Retained (audited, battle-tested) |
| Tauri/daemon benefit | Same as dual-runtime | Full native Rust crypto |
| CI complexity | wasm-pack + wasm-bindgen + browser test harness | Standard cargo test |
| Debugging | wasm stack traces are opaque | Native debugger support |
| Interop guarantee | Single implementation | Golden vectors enforce parity |

**The golden vector suite is the interop contract.** Both implementations
MUST produce identical outputs for identical inputs. The vector suite already
exists and is tested in CI (`ci-rust.yml`).

### Boundary Rule

> If a Rust peer and a TS peer exchange encrypted messages over any
> transport, the wire format MUST be identical. Parity is proven by
> shared golden vectors, not by shared code.

---

## 3. Crate Tree

All crates live under `bolt-core-sdk/rust/`. No new top-level repos.

```
bolt-core-sdk/
  rust/
    bolt-core/                    # existing v0.1.0
      Cargo.toml
      src/
        lib.rs                    # re-exports
        constants.rs              # protocol constants (existing, inline in lib.rs -> extract)
        encoding.rs               # NEW: base64 + hex utilities
        crypto.rs                 # NEW: seal_box_payload, open_box_payload
        identity.rs               # NEW: generate_identity_keypair, KeyMismatchError
        peer_code.rs              # NEW: generate, validate, normalize
        sas.rs                    # NEW: compute_sas
        hash.rs                   # NEW: sha256, buffer_to_hex
        errors.rs                 # NEW: BoltError hierarchy
        vectors.rs                # existing vector generator (test-only)
      tests/
        vector_compat.rs          # existing
        vector_equivalence.rs     # existing
        crypto_parity.rs          # NEW: seal/open against golden vectors
        sas_parity.rs             # NEW: SAS against golden vectors
        identity_parity.rs        # NEW: keypair generation properties
        peer_code_parity.rs       # NEW: format, alphabet, validation
```

### Why one crate, not a workspace of micro-crates

The TS SDK is a single package (`@the9ines/bolt-core`). Splitting Rust into
`bolt-crypto`, `bolt-encoding`, `bolt-identity` creates version coordination
overhead with no consumer benefit. Consumers are: bolt-daemon (Rust), Tauri
apps (Rust), and the vector test harness. All need the full surface. One
crate, modules for organization.

---

## 4. API Surface (Public Functions and Types)

### 4.1 `constants` (existing, to be extracted to own file)

```rust
pub const NONCE_LENGTH: usize = 24;
pub const PUBLIC_KEY_LENGTH: usize = 32;
pub const SECRET_KEY_LENGTH: usize = 32;
pub const DEFAULT_CHUNK_SIZE: usize = 16_384;
pub const PEER_CODE_LENGTH: usize = 6;
pub const PEER_CODE_ALPHABET: &str = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
pub const SAS_LENGTH: usize = 6;
pub const BOX_OVERHEAD: usize = 16;
```

No changes. Already aligned and tested.

### 4.2 `encoding`

```rust
/// Encode bytes to standard base64.
pub fn to_base64(data: &[u8]) -> String;

/// Decode standard base64 to bytes. Returns BoltError on invalid input.
pub fn from_base64(encoded: &str) -> Result<Vec<u8>, BoltError>;

/// Encode bytes to lowercase hex.
pub fn to_hex(data: &[u8]) -> String;

/// Decode hex string to bytes. Returns BoltError on invalid input.
pub fn from_hex(encoded: &str) -> Result<Vec<u8>, BoltError>;
```

TS uses `tweetnacl-util` for base64. Rust uses `base64` 0.22 (already a dep).
Hex is hand-rolled in TS (`bufferToHex`); Rust can use `hex` crate or inline.

**Parity gate:** `to_base64(bytes) == TS toBase64(bytes)` for all vector
payloads. `to_hex(bytes) == TS bufferToHex(bytes)` for all vector nonces
and keys.

### 4.3 `crypto`

```rust
/// X25519 keypair (ephemeral or identity).
pub struct KeyPair {
    pub public_key: [u8; 32],
    pub secret_key: [u8; 32],
}

/// Generate a fresh ephemeral X25519 keypair.
pub fn generate_ephemeral_keypair() -> KeyPair;

/// Seal plaintext using NaCl box (XSalsa20-Poly1305).
/// Wire format: base64(nonce || ciphertext).
/// Random nonce generated internally.
pub fn seal_box_payload(
    plaintext: &[u8],
    remote_public_key: &[u8; 32],
    sender_secret_key: &[u8; 32],
) -> Result<String, BoltError>;

/// Open a sealed payload. Expects base64(nonce || ciphertext).
pub fn open_box_payload(
    sealed: &str,
    sender_public_key: &[u8; 32],
    receiver_secret_key: &[u8; 32],
) -> Result<Vec<u8>, BoltError>;
```

Mirrors TS `sealBoxPayload` / `openBoxPayload` exactly. Wire format is
`base64(nonce || ciphertext)` — same 24-byte nonce prefix, same Poly1305
MAC. `crypto_box` 0.9 (`SalsaBox`) is already a dependency.

**Parity gate:** For each golden vector, `open_box_payload(sealed, sender_pk, receiver_sk)`
returns the expected plaintext. For corrupt vectors, returns `BoltError`.
`seal_box_payload` with fixed nonce (test-only helper) produces byte-identical
output to TS.

### 4.4 `identity`

```rust
/// Long-lived X25519 identity keypair.
pub type IdentityKeyPair = KeyPair;

/// Generate a persistent identity keypair.
pub fn generate_identity_keypair() -> IdentityKeyPair;

/// TOFU violation error.
#[derive(Debug)]
pub struct KeyMismatchError {
    pub peer_code: String,
    pub expected: [u8; 32],
    pub received: [u8; 32],
}
```

TS `generateIdentityKeyPair()` returns `{ publicKey, secretKey }` — same
structure, different language idiom. `KeyMismatchError` carries the same
fields. TOFU pin storage is a transport concern (not in core).

**Parity gate:** Property tests — `generate_identity_keypair()` produces
valid 32-byte keys. `KeyMismatchError` serializes with expected field names.

### 4.5 `sas`

```rust
/// Compute 6-character SAS (Short Authentication String).
///
/// SAS_input = SHA-256(sort32(idA, idB) || sort32(ephA, ephB))
/// Display = first 6 hex chars, uppercase.
pub async fn compute_sas(
    identity_a: &[u8; 32],
    identity_b: &[u8; 32],
    ephemeral_a: &[u8; 32],
    ephemeral_b: &[u8; 32],
) -> Result<String, BoltError>;
```

Note: TS `computeSas` is async because `crypto.subtle.digest` is async.
Rust SHA-256 (via `sha2` crate) is synchronous. The Rust function can be
sync, but we keep the signature async-compatible for Tauri integration.
Alternatively, expose both `compute_sas` (sync) and `compute_sas_async`
(async wrapper). **Decision deferred to R2 implementation.**

**Parity gate:** New golden vectors needed. Generate SAS test vectors
from TS (`computeSas` with fixed keys), store in
`__tests__/vectors/sas.vectors.json`. Rust MUST produce identical 6-char
strings.

### 4.6 `peer_code`

```rust
/// Generate a 6-character peer code using rejection sampling.
pub fn generate_secure_peer_code() -> String;

/// Generate an 8-character peer code with dash: XXXX-XXXX.
pub fn generate_long_peer_code() -> String;

/// Validate peer code format (6-char or 8-char with optional dash).
pub fn is_valid_peer_code(code: &str) -> bool;

/// Normalize: strip dashes, uppercase.
pub fn normalize_peer_code(code: &str) -> String;
```

Rejection sampling with `REJECTION_MAX = floor(256/31) * 31 = 248` matches
TS exactly. The alphabet is already in `constants`.

**Parity gate:** Property tests — generated codes pass `is_valid_peer_code`.
`normalize_peer_code` matches TS for all test inputs. Rejection sampling
bias test (chi-squared over 100K samples, same as TS test).

### 4.7 `hash`

```rust
/// SHA-256 hash of arbitrary data.
pub fn sha256(data: &[u8]) -> [u8; 32];

/// Convert bytes to lowercase hex string.
pub fn buffer_to_hex(data: &[u8]) -> String;
```

TS uses `crypto.subtle.digest('SHA-256', ...)` (async, Web Crypto). Rust
uses `sha2` crate (sync). `hashFile` is a transport concern (reads a Blob)
and stays in TS/transport layer.

**Parity gate:** SHA-256 of each golden vector plaintext matches TS output.
`buffer_to_hex` matches TS `bufferToHex` for all vector nonces and keys.

### 4.8 `errors`

```rust
#[derive(Debug, thiserror::Error)]
pub enum BoltError {
    #[error("Encryption error: {0}")]
    Encryption(String),

    #[error("Connection error: {0}")]
    Connection(String),

    #[error("Transfer error: {0}")]
    Transfer(String),

    #[error("Integrity error: {0}")]
    Integrity(String),

    #[error("Encoding error: {0}")]
    Encoding(String),
}
```

Maps to TS error hierarchy: `BoltError` (base), `EncryptionError`,
`ConnectionError`, `TransferError`, `IntegrityError`. Rust uses an enum
instead of class inheritance.

---

## 5. Dependency Changes

### Current (`Cargo.toml` v0.1.0)

```toml
serde = { version = "1", features = ["derive"] }
serde_json = "1"
crypto_box = "0.9"
base64 = "0.22"
```

### After R3 completion

```toml
[dependencies]
crypto_box = "0.9"
base64 = "0.22"
sha2 = "0.10"
thiserror = "2"
rand = "0.8"              # for peer code rejection sampling + nonce generation

[dev-dependencies]
serde = { version = "1", features = ["derive"] }
serde_json = "1"
proptest = "1"            # property-based testing for peer codes
```

`serde` + `serde_json` move to dev-dependencies (only needed for vector
JSON parsing in tests and the vector generator). Production code does not
need JSON serialization — wire format is defined by the transport layer.

`rand` provides `OsRng` for `crypto.getRandomValues` equivalent. `crypto_box`
already depends on `rand_core` internally.

---

## 6. Parity Vector Strategy

### 6.1 Existing vectors (no changes needed)

| Suite | File | Tests |
|-------|------|-------|
| box-payload | `ts/bolt-core/__tests__/vectors/box-payload.vectors.json` | 4 valid + 4 corrupt |
| framing | `ts/bolt-core/__tests__/vectors/framing.vectors.json` | 4 framing |

### 6.2 New vectors (generated by TS, consumed by Rust)

| Suite | File | Content | Phase |
|-------|------|---------|-------|
| sas | `ts/bolt-core/__tests__/vectors/sas.vectors.json` | Fixed key quads -> expected SAS strings | R2 |
| peer-code | `ts/bolt-core/__tests__/vectors/peer-code.vectors.json` | Validation inputs + expected results | R3 |
| encoding | `ts/bolt-core/__tests__/vectors/encoding.vectors.json` | base64/hex round-trip pairs | R1 |

### 6.3 Vector generation rule

> TS generates vectors. Rust consumes them. Never the reverse for parity
> vectors. The Rust vector generator (`vectors.rs`) exists for equivalence
> proofs — confirming that Rust can independently produce the same output.
> But the authoritative test fixtures are always the TS-generated JSON files.

This matches the existing `SDK_AUTHORITY.md` model: "Canonical truth =
contracts + vectors + Rust crate."

### 6.4 CI enforcement

Existing `ci-rust.yml` runs `cargo test` which includes vector compat and
equivalence tests. New parity tests (R1-R3) are added to the same workflow.
No new CI files needed.

---

## 7. Migration Phases

### Phase R0: Crate Restructure + CI Gate

**Goal:** Extract constants to own file, add new module stubs, verify CI.

**Work:**
1. Move `constants` from inline in `lib.rs` to `src/constants.rs`
2. Create empty module files: `encoding.rs`, `crypto.rs`, `identity.rs`,
   `peer_code.rs`, `sas.rs`, `hash.rs`, `errors.rs`
3. Add `pub mod` declarations in `lib.rs`
4. Add `sha2`, `thiserror`, `rand` to `Cargo.toml`
5. Move `serde`/`serde_json` to `[dev-dependencies]`
6. Verify: `cargo build`, `cargo clippy`, `cargo test` all pass
7. Verify: CI green (existing vector tests still pass)

**Exit criteria:**
- `cargo build` clean, zero warnings
- `cargo clippy` clean
- All 7 existing tests pass
- `lib.rs` only contains `pub mod` + doc comments (no inline code)

**Version:** 0.1.1 (patch — internal restructure, no API change)

**Tag:** `sdk-v0.1.1-crate-restructure`

---

### Phase R1: Crypto + Encoding Parity

**Goal:** Public `seal_box_payload` / `open_box_payload` + encoding utils
pass all golden vector tests.

**Work:**
1. Implement `encoding.rs`: `to_base64`, `from_base64`, `to_hex`, `from_hex`
2. Implement `errors.rs`: `BoltError` enum
3. Implement `crypto.rs`: `KeyPair`, `generate_ephemeral_keypair`,
   `seal_box_payload`, `open_box_payload`
4. Generate `encoding.vectors.json` from TS (new script)
5. Write `tests/crypto_parity.rs`:
   - For each box-payload vector: `open_box_payload` returns expected plaintext
   - For each corrupt vector: `open_box_payload` returns `BoltError::Encryption`
   - Round-trip: `seal` then `open` recovers plaintext
   - Fixed-nonce seal (test helper) matches TS sealed_base64 byte-for-byte
6. Write `tests/encoding_parity.rs`:
   - `to_base64` / `from_base64` round-trip for all vector payloads
   - `to_hex` matches TS `bufferToHex` for all vector nonces and keys

**Exit criteria:**
- All existing tests pass (7)
- New crypto parity tests pass (minimum 12: 4 valid open + 4 corrupt + 2 round-trip + 2 fixed-nonce)
- New encoding parity tests pass (minimum 8)
- `cargo clippy` clean, zero warnings

**Version:** 0.2.0 (minor — new public API: crypto + encoding)

**Tag:** `sdk-v0.2.0-crypto-parity`

---

### Phase R2: Identity + SAS Parity

**Goal:** Identity keypair generation and SAS computation match TS behavior.

**Work:**
1. Implement `hash.rs`: `sha256`, `buffer_to_hex`
2. Implement `identity.rs`: `IdentityKeyPair`, `generate_identity_keypair`,
   `KeyMismatchError`
3. Implement `sas.rs`: `compute_sas` (sync, using `sha2` crate)
4. Generate `sas.vectors.json` from TS:
   - 4 fixed key quads with expected 6-char SAS strings
   - 2 edge cases: identical keys, keys that sort differently
5. Write `tests/sas_parity.rs`:
   - Each SAS vector produces expected string
   - Commutative: `compute_sas(A, B, ...) == compute_sas(B, A, ...)`
   - Wrong key lengths rejected
6. Write `tests/identity_parity.rs`:
   - Generated keypair has 32-byte public and secret keys
   - Public key derived from secret key (X25519 property)
   - `KeyMismatchError` carries correct fields

**Exit criteria:**
- All previous tests pass
- SAS parity tests pass (minimum 8)
- Identity property tests pass (minimum 4)
- SHA-256 of golden vector plaintexts matches TS output
- `cargo clippy` clean

**Version:** 0.3.0 (minor — new public API: identity + SAS + hash)

**Tag:** `sdk-v0.3.0-identity-sas-parity`

---

### Phase R3: Peer Code + Validation Parity

**Goal:** Peer code generation and validation match TS behavior.

**Work:**
1. Implement `peer_code.rs`: `generate_secure_peer_code`,
   `generate_long_peer_code`, `is_valid_peer_code`, `normalize_peer_code`
2. Rejection sampling with `REJECTION_MAX = 248` (matching TS)
3. Generate `peer-code.vectors.json` from TS:
   - Valid codes: 6-char, 8-char with dash, uppercase, lowercase
   - Invalid codes: wrong length, bad chars (0, O, 1, I, L), empty
   - Normalize cases: lowercase -> uppercase, dashes stripped
4. Write `tests/peer_code_parity.rs`:
   - Validation matches TS for all vector inputs
   - Normalization matches TS for all vector inputs
   - Generated codes: length correct, chars in alphabet
   - Rejection sampling bias test (chi-squared, 100K samples)
   - Long code format: `XXXX-XXXX`

**Exit criteria:**
- All previous tests pass
- Peer code parity tests pass (minimum 10)
- Bias test: chi-squared p-value > 0.01 for each alphabet character
- `cargo clippy` clean

**Version:** 0.4.0 (minor — new public API: peer codes)

**Tag:** `sdk-v0.4.0-peer-code-parity`

---

### Phase R4: Shared Schema Types (Optional, Deferred)

**Goal:** Evaluate whether `serde`-derived Rust types for wire messages
provide value to Rust consumers (bolt-daemon, Tauri).

**Work:**
1. Survey bolt-daemon and Tauri app message handling needs
2. If needed: define `FileChunkMessage`, `HelloMessage`, `ControlMessage`
   as Rust structs with `serde::Serialize`/`Deserialize`
3. If NOT needed: close phase with a decision record (ADR)

**Gate:** Only proceed if at least one Rust consumer (bolt-daemon or Tauri)
has an active need for typed message schemas. Do not speculatively define
types that no consumer uses.

**Exit criteria:**
- ADR documenting decision (proceed or defer)
- If proceeding: typed schemas with serde derives, round-trip tests against
  TS JSON output

**Version:** 0.5.0 if proceeding, no version bump if deferred

---

## 8. "Do Not Break" Invariants

These invariants MUST hold through all phases. Any phase that violates
these invariants MUST be reverted before merge.

### I1. Wire Format Stability

The on-wire format for encrypted payloads is `base64(nonce || ciphertext)`
where nonce is 24 bytes and ciphertext includes the 16-byte Poly1305 MAC.
This format MUST NOT change. Both Rust and TS MUST produce and consume
this format.

### I2. Capability Negotiation Semantics

The `bolt.file-hash` and `bolt.envelope` capabilities are negotiated in
the encrypted HELLO handshake. The negotiation logic (intersection-based,
backward-compatible with peers that omit capabilities) is a transport
concern. Rust core does not implement capability negotiation — that
belongs in the transport layer.

### I3. Mixed-Peer Compatibility

A Rust-native peer (bolt-daemon, Tauri) MUST be able to exchange encrypted
files with a TS-web peer (localbolt, localbolt-v3) over any shared
transport. Compatibility is proven by golden vectors, not by code sharing.

### I4. Constants Alignment

All constants in `rust/bolt-core/src/constants.rs` MUST exactly match
the values in `ts/bolt-core/src/constants.ts`. The existing
`scripts/verify-constants.sh` enforces this in CI.

### I5. Vector Authority Chain

TS generates golden vectors. Rust consumes them. The vector files in
`ts/bolt-core/__tests__/vectors/` are the single source of truth.
`rust/bolt-core/src/vectors.rs` exists only to prove the Rust crate
can independently reproduce the same outputs — it does not define truth.

---

## 9. Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| `crypto_box` 0.9 API drift vs tweetnacl | Medium | Golden vectors catch any divergence. Pin `crypto_box` version. |
| `sha2` output differs from Web Crypto | Low | SHA-256 is deterministic. Vector test catches immediately. |
| Rejection sampling PRNG difference | Low | Bias test (chi-squared) validates distribution. Exact output differs by design (random). |
| R4 schema types diverge from TS wire format | Medium | Only define if consumer exists. Round-trip tests mandatory. |
| Tauri WASM confusion | Low | Decision documented in section 2. Review before any wasm work. |

---

## 10. Non-Goals

- **No wasm32 target.** Rust does not replace TS crypto in browsers. See section 2.
- **No transport layer in Rust core.** WebRTC, signaling, DataChannel are transport concerns. Rust core provides primitives only.
- **No message framing in core.** How chunks are serialized (JSON, MessagePack, protobuf) is a transport decision.
- **No TOFU pin storage in core.** Pin persistence (IndexedDB, filesystem) is a transport/product concern.
- **No breaking changes to TS API.** The TS SDK public API is frozen per `SDK_STABILITY.md`. Rust core is additive.
- **No capability negotiation in core.** Capabilities are exchanged in the HELLO handshake, which is a transport concern.
- **No file I/O in core.** `hashFile` (Blob -> SHA-256) stays in transport. Core provides `sha256(bytes)`.

---

## 11. Exit Criteria (Full Plan)

The Rust canonical core is considered complete when:

1. All 8 TS public API functions have Rust equivalents (R1-R3)
2. All golden vector suites pass in Rust CI
3. `cargo clippy` and `cargo fmt` clean
4. bolt-daemon can import `bolt-core` and use `seal_box_payload` / `open_box_payload`
5. No TS tests broken by any Rust change
6. Version is 0.4.0+ with documented public API

The TS SDK remains the production implementation for web. The Rust crate
becomes the production implementation for native. Both are canonical.
Both pass the same vectors.
