> **ARCHIVED** — historical artifact, not active governance. Moved to docs/archive/ during DOC-GOV-1 (2026-02-26).

# Phase 9E Synthesis: M1 + M2 + A2 Consolidated Implementation Plan

**Date:** 2026-02-24
**Author:** Agent D (synthesis)
**Inputs:** M1 design memo (Agent B), M2 design memo (Agent A), A2 design memo (Agent C)

---

## 1. Dependency Resolution

### 1.1 M1 / M2 Dependency Analysis

Both memos agree: **M2 depends on M1** because M2 needs `capabilities` in HELLO to negotiate `bolt.file-hash`. The question is whether this dependency is binary or decomposable.

**Current HELLO (WebRTCService.ts lines 395-402):**
```typescript
const hello = JSON.stringify({
  type: 'hello',
  version: 1,
  identityPublicKey: toBase64(this.options.identityPublicKey),
});
```

**PROTOCOL.md HELLO schema requires:**
- `bolt_version` (uint32)
- `capabilities` (string[])
- `encoding` (string)
- `identity_key` (bytes32)

The current implementation is non-conformant with PROTOCOL.md: it lacks `capabilities`, `encoding`, and uses `version` instead of `bolt_version`. This means any work that adds `capabilities` to HELLO is a **conformance correction**, not specific to either M1 or M2.

### 1.2 Can M2 Ship Before M1?

**Yes, partially.** Here is the decomposition:

| M2 Requirement | M1 Dependency | Verdict |
|----------------|---------------|---------|
| Add `capabilities` to HELLO | Shared infrastructure | Can be extracted as Phase 0 |
| Introduce `file-offer` / `file-finish` message types | None (new message types, independent of envelope) | Independent |
| Hash file pre-send (`hashFile`) | None (bolt-core already exports `hashFile`) | Independent |
| Verify hash post-reassembly | None | Independent |
| Gate hash on `bolt.file-hash` capability | Needs `capabilities` in HELLO | Needs Phase 0 only |
| `INTEGRITY_FAILED` error, no disconnect | None | Independent |
| Backward compat with legacy peers | Needs capability negotiation | Needs Phase 0 only |

| M1 Requirement | Dependency on M2 | Verdict |
|----------------|-------------------|---------|
| Canonical `bolt-envelope` structure | None | Independent |
| `sealEnvelope` / `openEnvelope` in bolt-core | None | Independent |
| Decompose overloaded `file-chunk` | Overlaps with M2 message decomposition | **Shared concern** |
| `bolt.envelope-v1` capability | Needs `capabilities` in HELLO | Needs Phase 0 |
| Dual-send HELLO for backward compat | None | Independent |
| Inner message type encryption | None | Independent |

### 1.3 Minimal M1 Slice That Unblocks M2

**Phase 0: HELLO Conformance + Capability Infrastructure**

This is NOT the full M1. It is a surgical extraction of exactly what both M1 and M2 need:

1. Add `capabilities: string[]` to HELLO payload (sender populates, receiver parses)
2. Add `encoding: string` to HELLO payload (value: `"json"` for all current peers)
3. Rename `version` to `bolt_version` (or accept both during transition)
4. Store negotiated capabilities after HELLO exchange (`Set<string>` on WebRTCService)
5. Add `hasCapability(name: string): boolean` accessor

This slice does NOT include:
- Envelope framing changes
- New crypto API (`sealEnvelope` / `openEnvelope`)
- Message type decomposition
- Backward compat dual-send

### 1.4 A2 Independence Confirmed

A2 (bolt-rendezvous-protocol crate extraction) is **fully independent** of M1 and M2:
- Different language (Rust vs TypeScript)
- Different repos (bolt-rendezvous + bolt-daemon vs bolt-core-sdk)
- No wire format changes
- No shared touch points

A2 can execute in parallel with any TypeScript phase.

---

## 2. Execution Order

### Recommended Sequence

```
Phase 0: HELLO Conformance + Capabilities     [bolt-core + bolt-transport-web]
    |
    +---> Phase M2: File Hash Wiring           [bolt-transport-web]
    |         |
    |         v
    |     Phase M1: Envelope + Message Decomposition  [bolt-core + bolt-transport-web]
    |
    +---> Phase A2: Protocol Type Deduplication [bolt-rendezvous + bolt-daemon]
              (parallel, independent)
```

### Rationale

1. **Phase 0 first** because both M1 and M2 need capability infrastructure in HELLO. It is small (< 100 LOC), low risk, and unblocks everything downstream.

2. **M2 before M1** because:
   - M2 is smaller and lower risk (file-offer/file-finish + hashFile integration)
   - M2 delivers user-visible value (file integrity verification) immediately
   - M1 is the largest change with the most architectural risk (envelope framing, crypto API, backward compat)
   - Shipping M2 first validates the capability negotiation infrastructure before M1 relies on it
   - M2's message type additions (`file-offer`, `file-finish`) are wire-compatible with M1's later decomposition

3. **M1 after M2** because:
   - By the time M1 starts, capability negotiation is battle-tested
   - M1's message decomposition (splitting `file-chunk` into `file-offer`, `file-accept`, `file-chunk`, `file-finish`, `pause`, `resume`, `cancel`) can build on M2's already-introduced `file-offer` and `file-finish` types
   - M1's envelope framing wraps ALL messages -- including the new types M2 introduced

4. **A2 in parallel** because it is completely isolated. Can start immediately.

### Alternative Considered: M1 First

Rejected because:
- M1 is a 500+ LOC change across two packages with crypto API changes
- If M1 introduces regressions, M2 is blocked
- M1's full message decomposition is a superset of what M2 needs
- Shipping M1 first delays file integrity verification (the user-facing feature) behind infrastructure work

---

## 3. Shared Touch Points

### 3.1 WebRTCService.ts Method-Level Conflict Map

| Method/Section | M1 Modifies | M2 Modifies | Conflict Risk |
|----------------|-------------|-------------|---------------|
| `FileChunkMessage` interface (L31-43) | **REMOVES** -- replaced by distinct types | **EXTENDS** -- adds `fileHash` field | HIGH |
| `handleMessage()` (L675-735) | **REWRITES** -- envelope unwrap + dispatch by type | **EXTENDS** -- adds `file-offer` / `file-finish` routing | HIGH |
| `processChunk()` (L766-783) | **REFACTORS** -- chunk routing changes | **EXTENDS** -- hash accumulation | MEDIUM |
| `processChunkGuarded()` (L785-843) | Minimal change | **EXTENDS** -- hash verification on completion | MEDIUM |
| `processChunkLegacy()` (L845-879) | Minimal change | **EXTENDS** -- hash verification (legacy path) | LOW |
| `sendFile()` (L593-671) | **REFACTORS** -- sends via envelope | **EXTENDS** -- computes hash pre-send, sends `file-offer`/`file-finish` | HIGH |
| `initiateHello()` (L383-419) | **REWRITES** -- dual-format HELLO, envelope | **EXTENDS** -- adds `capabilities` | MEDIUM |
| `processHello()` (L421-485) | **REWRITES** -- envelope unwrap, capability parse | **EXTENDS** -- stores `bolt.file-hash` capability | MEDIUM |
| `sendControlMessage()` (L922-925) | **REFACTORS** -- distinct message types via envelope | No change | LOW |
| `pauseTransfer()` / `resumeTransfer()` / `cancelTransfer()` (L883-920) | **REFACTORS** -- distinct PAUSE/RESUME/CANCEL types | No change | LOW |

### 3.2 Conflict Mitigation

**If M2 lands before M1 (recommended order):**
- M2 introduces `file-offer` and `file-finish` as new message types within the EXISTING framing (JSON over DataChannel, encrypted via `sealBoxPayload`)
- M1 then wraps ALL message types (including the new ones from M2) inside `bolt-envelope`
- M1's `handleMessage` rewrite consumes M2's types rather than conflicting with them
- Net conflict: minimal, because M1 builds on M2's types rather than replacing them simultaneously

**If both land simultaneously or M1 first:**
- Significant merge conflict in `handleMessage`, `sendFile`, and `FileChunkMessage`
- Would require a single agent to implement both, or careful rebasing

**Recommendation: Same agent for Phase 0 + M2. Different agent (or same) for M1.** The ordering ensures M1 reads M2's changes rather than fighting them.

### 3.3 bolt-core Touch Points

| File | M1 Modifies | M2 Modifies | Conflict Risk |
|------|-------------|-------------|---------------|
| `crypto.ts` | **ADDS** `sealEnvelope` / `openEnvelope` | No change | NONE |
| `hash.ts` | No change | No change (already exports `hashFile`) | NONE |
| `index.ts` | **ADDS** exports for new envelope API | No change | NONE |
| `errors.ts` | Possible new error types | **ADDS** `IntegrityError` | LOW |

No conflicts in bolt-core. M1 and M2 touch different parts.

---

## 4. Risk Notes

### R1: Message Type Proliferation (M2 then M1)

If M2 adds `file-offer` and `file-finish` as top-level JSON types (e.g., `{ type: "file-offer", ... }`), and M1 later wraps everything in envelopes, the inner message types remain the same. This is clean. However, if M2 adds them as sub-types of `file-chunk` (e.g., `{ type: "file-chunk", subType: "offer" }`), M1 would need to decompose them again. **M2 MUST introduce `file-offer` and `file-finish` as distinct `type` values, not as extensions of `file-chunk`.**

### R2: `hashFile` Memory Scalability

`hashFile` (bolt-core `hash.ts` line 23) loads the entire file into memory: `const buffer = await file.arrayBuffer()`. For files > 500MB this is problematic. Both memos acknowledge this. **M2 scope explicitly excludes streaming hash.** The M2 implementation MUST document this limitation. A future phase can add streaming hash via Web Streams API.

### R3: Backward Compatibility Window

After Phase 0, HELLO messages will contain `capabilities`. Legacy peers (current code) will:
- Send HELLO without `capabilities` (old format)
- Receive HELLO with `capabilities` and ignore unknown fields

This is safe because the current `processHello()` only checks `hello.type`, `hello.version`, and `hello.identityPublicKey`. Unknown fields are ignored by JSON parsing. However, Phase 0 MUST NOT change the HELLO `version` field semantics -- it should add `capabilities` alongside the existing `version: 1` field. The rename to `bolt_version` can happen in M1 when envelope framing provides a clean break.

### R4: A2 Wire Compatibility

The A2 crate extraction changes `device_type` from `String` (in bolt-daemon) to `DeviceType` enum (from bolt-rendezvous). Since `DeviceType` serializes with `#[serde(rename_all = "lowercase")]`, the JSON wire format is identical: `"device_type": "desktop"`. The snapshot tests proposed in A2 validate this. Risk is LOW but the snapshot tests are mandatory.

### R5: Test Coverage Regression

WebRTCService.ts currently has tests for:
- HELLO encryption/decryption (`hello.test.ts`)
- Handshake gating (`webrtcservice-handshake-gating.test.ts`)
- Lifecycle (`webrtcservice-lifecycle.test.ts`)
- Replay protection (`replay-protection.test.ts`)
- Security (`security.test.ts`)
- Verification (`verification.test.ts`)

Each phase MUST maintain or increase test count. No phase may reduce coverage.

---

## 5. Coder Prompts

---

### Coder Prompt: Phase 0 -- HELLO Conformance + Capability Infrastructure

**Objective:** Add `capabilities` array to HELLO exchange so downstream phases (M2, M1) can negotiate features via capability strings.

**Scope:**
- `bolt-core-sdk/ts/bolt-transport-web/src/services/webrtc/WebRTCService.ts`
- `bolt-core-sdk/ts/bolt-transport-web/src/__tests__/hello.test.ts`
- `bolt-core-sdk/ts/bolt-transport-web/src/__tests__/webrtcservice-handshake-gating.test.ts` (if affected)

**Deliverables:**

1. **HELLO payload extension.** In `initiateHello()`, add `capabilities` and `encoding` fields to the HELLO JSON:
   ```typescript
   const hello = JSON.stringify({
     type: 'hello',
     version: 1,
     capabilities: this.getLocalCapabilities(),
     encoding: 'json',
     identityPublicKey: toBase64(this.options.identityPublicKey),
   });
   ```

2. **Local capabilities method.** Add `private getLocalCapabilities(): string[]` that returns the list of capabilities this peer supports. For Phase 0, return an empty array `[]`. M2 will add `'bolt.file-hash'` to this list.

3. **Capability storage.** In `processHello()`, after successful decryption and validation:
   - Parse `hello.capabilities` (default to `[]` if absent -- backward compat with legacy peers)
   - Compute intersection with local capabilities
   - Store as `private negotiatedCapabilities: Set<string>` on WebRTCService

4. **Public accessor.** Add:
   ```typescript
   hasCapability(name: string): boolean {
     return this.negotiatedCapabilities.has(name);
   }
   ```

5. **Reset on disconnect.** Clear `negotiatedCapabilities` in `disconnect()`.

6. **WebRTCServiceOptions extension.** Add optional `capabilities?: string[]` to `WebRTCServiceOptions` for callers to declare supported capabilities.

**Test Requirements:**
- HELLO message includes `capabilities` and `encoding` fields after encryption round-trip
- Legacy HELLO (no `capabilities` field) is accepted gracefully (backward compat)
- Capability intersection is computed correctly (both peers share `['a', 'b']`, one has `['a']`, result is `['a']`)
- `hasCapability()` returns correct results after HELLO exchange
- `hasCapability()` returns false before HELLO exchange
- `negotiatedCapabilities` cleared on disconnect

**Versioning:** No version bump. This is additive and backward-compatible. Unknown fields in HELLO are ignored per PROTOCOL.md section 4.

**What NOT to do:**
- Do NOT rename `version` to `bolt_version` yet (that is M1 scope with envelope migration)
- Do NOT add any specific capabilities (like `bolt.file-hash` or `bolt.envelope-v1`) -- those are M2 and M1 scope
- Do NOT change the HELLO wire format for the outer envelope (`{ type: 'hello', payload: '...' }`) -- that is M1 scope
- Do NOT modify bolt-core package
- Do NOT add envelope framing
- Do NOT decompose `file-chunk` message type

---

### Coder Prompt: Phase M2 -- File Hash Wiring

**Objective:** Implement file integrity verification via SHA-256 hash, gated on `bolt.file-hash` capability negotiation. Introduce `file-offer` and `file-finish` as new distinct message types.

**Scope:**
- `bolt-core-sdk/ts/bolt-transport-web/src/services/webrtc/WebRTCService.ts`
- `bolt-core-sdk/ts/bolt-transport-web/src/__tests__/file-hash.test.ts` (new file)
- `bolt-core-sdk/ts/bolt-core/src/errors.ts` (add `IntegrityError`)
- `bolt-core-sdk/ts/bolt-core/src/index.ts` (export `IntegrityError`)

**Prerequisite:** Phase 0 must be complete (`capabilities` in HELLO, `hasCapability()`, `negotiatedCapabilities`).

**Deliverables:**

1. **Declare `bolt.file-hash` capability.** Update `getLocalCapabilities()` to include `'bolt.file-hash'` in the returned array.

2. **`file-offer` message type.** Before sending the first chunk in `sendFile()`:
   - If `hasCapability('bolt.file-hash')`, compute hash: `const fileHash = await hashFile(file)` (import from bolt-core)
   - Send a `file-offer` message:
     ```typescript
     {
       type: 'file-offer',
       transferId,
       filename: file.name,
       fileSize: file.size,
       totalChunks,
       fileHash: fileHash ?? undefined,  // only if bolt.file-hash negotiated
     }
     ```
   - Emit a "preparing" progress state while hashing (for UX feedback on large files)

3. **`file-finish` message type.** After all chunks are sent in `sendFile()`:
   - Send a `file-finish` message:
     ```typescript
     {
       type: 'file-finish',
       transferId,
       fileHash: fileHash ?? undefined,  // echo for debugging; receiver uses file-offer hash
     }
     ```

4. **Receiver: `file-offer` handling.** In `handleMessage()`, add routing for `type === 'file-offer'`:
   - Store the `fileHash` from the offer as the authoritative expected hash for this transfer
   - Initialize the guarded transfer state (currently done on first chunk; now done on offer)
   - If transfer already exists for this `transferId`, reject (replay)

5. **Receiver: `file-finish` handling.** In `handleMessage()`, add routing for `type === 'file-finish'`:
   - Trigger reassembly verification
   - If `bolt.file-hash` was negotiated AND the `file-offer` included a `fileHash`:
     - Compute SHA-256 of the reassembled Blob
     - Compare against the stored `fileHash` from the `file-offer`
     - On match: deliver file via `onReceiveFile`
     - On mismatch: discard file, emit `INTEGRITY_FAILED` error via `onError`, do NOT disconnect
   - If `bolt.file-hash` was NOT negotiated: deliver file immediately (current behavior)

6. **`IntegrityError` class.** In `bolt-core/src/errors.ts`:
   ```typescript
   export class IntegrityError extends BoltError {
     constructor(message: string, details?: unknown) {
       super(message, details);
       this.name = 'IntegrityError';
     }
   }
   ```
   Export from `bolt-core/src/index.ts`.

7. **Backward compatibility.** When remote peer lacks `bolt.file-hash` capability:
   - Do NOT compute hash (skip `hashFile` call)
   - Do NOT send `file-offer` or `file-finish` messages
   - Fall back to current behavior (chunks only, deliver on last chunk)
   - Legacy peers will ignore unknown message types (`file-offer`, `file-finish`) per PROTOCOL.md section 4

8. **ActiveTransfer extension.** Add `expectedHash: string | null` field to `ActiveTransfer` interface.

**Test Requirements (16 tests):**
1. `file-offer` message sent before first chunk when `bolt.file-hash` negotiated
2. `file-offer` message NOT sent when `bolt.file-hash` NOT negotiated
3. `file-finish` message sent after last chunk when `bolt.file-hash` negotiated
4. `file-finish` message NOT sent when `bolt.file-hash` NOT negotiated
5. Hash computed via `hashFile` matches known test vector
6. Receiver stores `fileHash` from `file-offer` (not from `file-finish`)
7. Receiver verifies hash after reassembly -- match case
8. Receiver verifies hash after reassembly -- mismatch case (file discarded, `IntegrityError`)
9. Mismatch does NOT disconnect (transfer-scoped error)
10. `file-offer` with duplicate `transferId` rejected
11. Legacy peer (no `bolt.file-hash`) receives file without verification (current behavior)
12. `file-finish` without prior `file-offer` is ignored
13. `capabilities` includes `bolt.file-hash` when feature is available
14. `hasCapability('bolt.file-hash')` returns true after negotiation with supporting peer
15. `hasCapability('bolt.file-hash')` returns false after negotiation with legacy peer
16. Hash computation does not block chunk sending (hash computed before send loop)

**Test approach:** Mock `hashFile` to return deterministic values. No large files. No timing dependence. Use vitest with `vi.mock()`.

**Versioning:**
- `bolt-core`: `0.2.1` -> `0.2.2` (additive: `IntegrityError` class)
- `bolt-transport-web`: `0.4.2` -> `0.5.0` (new message types, new capability)

**What NOT to do:**
- Do NOT implement streaming hash (whole-file `hashFile` is M2 scope; streaming is a future optimization)
- Do NOT modify envelope framing (that is M1 scope)
- Do NOT add `sealEnvelope` / `openEnvelope` to bolt-core (that is M1 scope)
- Do NOT decompose `file-chunk` into `pause`, `resume`, `cancel` (that is M1 scope)
- Do NOT rename `version` to `bolt_version` in HELLO
- Do NOT change the outer DataChannel message format (`JSON.stringify` -> `dc.send`)
- Do NOT add `file-accept` message type (that is M1 scope, per PROTOCOL.md transfer state machine)
- Do NOT touch `sendControlMessage`, `pauseTransfer`, `resumeTransfer`, `cancelTransfer`

---

### Coder Prompt: Phase M1 -- Envelope Framing + Message Decomposition

**Objective:** Implement canonical `bolt-envelope` structure per PROTOCOL.md section 6.1. Decompose overloaded `file-chunk` into distinct message types. Add `sealEnvelope` / `openEnvelope` to bolt-core. Implement backward compatibility via `bolt.envelope-v1` capability.

**Scope:**
- `bolt-core-sdk/ts/bolt-core/src/crypto.ts` (add `sealEnvelope`, `openEnvelope`)
- `bolt-core-sdk/ts/bolt-core/src/index.ts` (export new API)
- `bolt-core-sdk/ts/bolt-core/__tests__/crypto.test.ts` (envelope tests)
- `bolt-core-sdk/ts/bolt-transport-web/src/services/webrtc/WebRTCService.ts` (major refactor)
- `bolt-core-sdk/ts/bolt-transport-web/src/__tests__/envelope.test.ts` (new file)
- `bolt-core-sdk/ts/bolt-transport-web/src/__tests__/backward-compat.test.ts` (new file)

**Prerequisites:** Phase 0 and Phase M2 must be complete.

**Deliverables:**

1. **`sealEnvelope` in bolt-core.** New function in `crypto.ts`:
   ```typescript
   export interface BoltEnvelope {
     type: 'bolt-envelope';
     senderEphemeralKey: string;  // base64
     nonce: string;               // base64
     ciphertext: string;          // base64
   }

   export function sealEnvelope(
     message: object,
     remotePublicKey: Uint8Array,
     senderKeyPair: { publicKey: Uint8Array; secretKey: Uint8Array },
   ): BoltEnvelope
   ```
   - Serializes `message` to JSON, then UTF-8 encodes, then NaCl box encrypts
   - Returns structured `BoltEnvelope` (NOT opaque base64 string like `sealBoxPayload`)
   - Nonce is generated fresh (24 random bytes)
   - `senderEphemeralKey` is the sender's ephemeral public key in base64

2. **`openEnvelope` in bolt-core.** New function in `crypto.ts`:
   ```typescript
   export function openEnvelope(
     envelope: BoltEnvelope,
     receiverSecretKey: Uint8Array,
   ): object
   ```
   - Uses `envelope.senderEphemeralKey` to decrypt (stateless -- no need to know sender in advance)
   - Returns parsed JSON object (the inner message)
   - Throws `EncryptionError` on MAC failure

3. **Keep `sealBoxPayload` / `openBoxPayload`.** Do NOT remove. They are used for legacy HELLO format.

4. **Message type decomposition in WebRTCService.** Replace the overloaded `FileChunkMessage` interface with distinct types matching PROTOCOL.md section 7:
   - `FileChunkMessage` (type: `'file-chunk'`, transferId, chunkIndex, totalChunks, payload)
   - `PauseMessage` (type: `'pause'`, transferId)
   - `ResumeMessage` (type: `'resume'`, transferId)
   - `CancelMessage` (type: `'cancel'`, transferId, cancelledBy)
   - Keep `FileOfferMessage` and `FileFinishMessage` from M2 (already exist)
   - Add `FileAcceptMessage` (type: `'file-accept'`, transferId)

5. **Envelope wrapping.** All protected messages (HELLO, FILE_OFFER, FILE_ACCEPT, FILE_CHUNK, FILE_FINISH, PAUSE, RESUME, CANCEL, ERROR) sent via `sealEnvelope` when remote supports `bolt.envelope-v1`.

6. **Envelope unwrapping.** In `handleMessage()`:
   - If incoming message has `type === 'bolt-envelope'`: call `openEnvelope`, then dispatch inner message by type
   - If incoming message has legacy `type` (e.g., `'file-chunk'`, `'hello'`): handle as current code (backward compat)

7. **`bolt.envelope-v1` capability.** Add to `getLocalCapabilities()`. Gate envelope framing on `hasCapability('bolt.envelope-v1')`.

8. **HELLO dual-send.** When DataChannel opens:
   - Always send HELLO inside a `bolt-envelope` (new format)
   - Receiver attempts envelope unwrap first; on failure, falls back to legacy `{ type: 'hello', payload: '...' }` parsing
   - This provides backward compat without requiring the sender to know the receiver's capabilities before HELLO

9. **`sendControlMessage` refactor.** Replace single method with typed senders:
   ```typescript
   private sendPause(transferId: string): void
   private sendResume(transferId: string): void
   private sendCancel(transferId: string, cancelledBy: 'sender' | 'receiver'): void
   ```
   Each uses `sealEnvelope` when envelope framing is negotiated.

10. **Error wrapping.** ERROR messages inside envelopes when remote ephemeral key is available. Silent disconnect when not.

**Test Requirements:**

*bolt-core crypto tests:*
- `sealEnvelope` produces valid `BoltEnvelope` structure
- `openEnvelope` decrypts correctly
- `openEnvelope` with wrong key throws `EncryptionError`
- `sealEnvelope` -> `openEnvelope` round-trip preserves message content
- Nonce is 24 bytes and unique across calls
- `senderEphemeralKey` matches sender's actual public key
- Inner message type is NOT visible in the envelope (only `'bolt-envelope'` type)

*bolt-transport-web envelope tests:*
- Envelope-wrapped file-chunk is correctly dispatched
- Envelope-wrapped HELLO is processed (new peer)
- Legacy HELLO (no envelope) is still processed (old peer)
- Mixed session: new peer sends envelope, old peer sends legacy -- both work
- PAUSE/RESUME/CANCEL sent as distinct types, not overloaded file-chunk
- ERROR sent inside envelope when ephemeral key available
- All protected message types are wrapped in envelope when `bolt.envelope-v1` negotiated
- PING/PONG remain plaintext (not wrapped)

*backward compat tests:*
- New peer -> old peer: old peer ignores `bolt-envelope` (unknown type), HELLO fallback works
- Old peer -> new peer: new peer handles legacy messages
- Capability negotiation: `bolt.envelope-v1` absent -> legacy framing used

**Versioning:**
- `bolt-core`: `0.2.2` -> `0.3.0` (new public API: `sealEnvelope`, `openEnvelope`, `BoltEnvelope` type)
- `bolt-transport-web`: `0.5.0` -> `0.6.0` (message type decomposition, envelope framing)

**What NOT to do:**
- Do NOT remove `sealBoxPayload` / `openBoxPayload` (needed for legacy compat)
- Do NOT change the Rust daemon/rendezvous code (out of scope)
- Do NOT implement message batching (PROTOCOL.md: "MUST NOT batch multiple messages")
- Do NOT implement key rotation mid-session (PROTOCOL.md: "MUST NOT rotate ephemeral keys mid-session in v1")
- Do NOT bump protocol version (this is a minor, additive change gated by capability)
- Do NOT modify the signaling layer (offer/answer/ice-candidate via WebSocket are unchanged)
- Do NOT touch `hashFile` logic (M2 scope, already complete)

---

### Coder Prompt: Phase A2 -- Protocol Type Deduplication

**Objective:** Extract shared protocol types (`DeviceType`, `PeerData`, `ClientMessage`, `ServerMessage`) into a `bolt-rendezvous-protocol` crate. Eliminate the duplicated type definitions in bolt-daemon.

**Scope:**
- `bolt-rendezvous/protocol/` (new crate directory)
- `bolt-rendezvous/Cargo.toml` (workspace member or path dependency)
- `bolt-rendezvous/src/protocol.rs` (re-export from shared crate)
- `bolt-daemon/Cargo.toml` (add path dependency)
- `bolt-daemon/src/rendezvous.rs` (consume shared types, remove local duplicates)

**This phase is fully independent of M1/M2 and can execute in parallel.**

**Deliverables:**

1. **Create `bolt-rendezvous/protocol/` crate.**
   - `bolt-rendezvous/protocol/Cargo.toml`:
     ```toml
     [package]
     name = "bolt-rendezvous-protocol"
     version = "0.1.0"
     edition = "2021"
     description = "Shared protocol types for bolt-rendezvous signaling"

     [dependencies]
     serde = { version = "1", features = ["derive"] }
     serde_json = "1"
     ```
   - `bolt-rendezvous/protocol/src/lib.rs`: Move `DeviceType`, `PeerData`, `ClientMessage`, `ServerMessage` here. ALL types get both `Serialize + Deserialize`.

2. **Update bolt-rendezvous to consume.**
   - Add to `bolt-rendezvous/Cargo.toml`:
     ```toml
     bolt-rendezvous-protocol = { path = "protocol" }
     ```
   - In `bolt-rendezvous/src/protocol.rs`: replace type definitions with `pub use bolt_rendezvous_protocol::*;`
   - Keep existing tests, update imports.

3. **Update bolt-daemon to consume.**
   - Add to `bolt-daemon/Cargo.toml`:
     ```toml
     bolt-rendezvous-protocol = { path = "../bolt-rendezvous/protocol" }
     ```
   - In `bolt-daemon/src/rendezvous.rs`:
     - Remove local `ClientMsg`, `ServerMsg`, `PeerInfo` types (lines 36-85)
     - Import from `bolt_rendezvous_protocol`: `use bolt_rendezvous_protocol::{ClientMessage, ServerMessage, PeerData, DeviceType};`
     - Update type aliases/renames as needed (current code uses `ClientMsg`/`ServerMsg` -- rename usages to `ClientMessage`/`ServerMessage`, or add `use ... as` aliases)
   - Key difference to handle: bolt-daemon currently uses `device_type: String` in `Register` (line 44) while bolt-rendezvous uses `device_type: DeviceType` (enum). The shared crate uses the enum. The daemon must send `DeviceType::Desktop` instead of `"desktop".to_string()`. This is wire-compatible because the enum serializes to lowercase strings.

4. **Wire compatibility snapshot tests.** In the shared crate (`protocol/src/lib.rs` tests or a dedicated test file):
   - Serialize each `ClientMessage` variant and assert exact JSON string
   - Serialize each `ServerMessage` variant and assert exact JSON string
   - Deserialize known JSON strings into each variant (round-trip)
   - These are **snapshot tests**: if any byte changes, the test fails. This is the wire compat guarantee.

5. **Existing test preservation.** All existing tests in `bolt-rendezvous/src/protocol.rs` and `bolt-daemon/src/rendezvous.rs` must continue to pass with updated imports.

**Test Requirements:**
- All 7 existing bolt-rendezvous protocol tests pass
- All 14 existing bolt-daemon rendezvous tests pass
- New snapshot tests: at least 1 per `ClientMessage` variant (Register, Signal, Ping) and 1 per `ServerMessage` variant (Peers, PeerJoined, PeerLeft, Signal, Error) = 8 snapshot tests minimum
- `cargo test` passes in both bolt-rendezvous and bolt-daemon
- `cargo clippy` clean in both repos
- `cargo fmt` clean in both repos

**Versioning:**
- `bolt-rendezvous-protocol`: `0.1.0` (new crate)
- `bolt-rendezvous`: no version bump (internal refactor, no behavior change)
- `bolt-daemon`: no version bump (internal refactor, no behavior change)

**What NOT to do:**
- Do NOT add tokio, async, or any heavy dependencies to the protocol crate (serde + serde_json ONLY)
- Do NOT change any wire format (the whole point is byte-identical JSON)
- Do NOT add the protocol crate to bolt-core-sdk or any TypeScript package
- Do NOT use feature gates on the shared crate
- Do NOT publish the protocol crate to crates.io (path dependency between sibling repos under `bolt-ecosystem/`)
- Do NOT modify `bolt-daemon/src/rendezvous.rs::SignalPayload` -- that is bolt-daemon's internal payload structure, not a shared rendezvous protocol type
- Do NOT touch bolt-rendezvous server logic (`server.rs`, `room.rs`, `lib.rs`, `main.rs`) -- only `protocol.rs` imports change

---

## 6. Summary Table

| Phase | Package(s) | LOC Estimate | Risk | Depends On | Parallel? |
|-------|-----------|-------------|------|------------|-----------|
| Phase 0 | bolt-transport-web | ~80 | LOW | None | -- |
| Phase M2 | bolt-core + bolt-transport-web | ~250 | LOW | Phase 0 | No (sequential after 0) |
| Phase M1 | bolt-core + bolt-transport-web | ~500 | MEDIUM | Phase 0, Phase M2 | No (sequential after M2) |
| Phase A2 | bolt-rendezvous + bolt-daemon | ~200 | LOW | None | Yes (parallel with all TS phases) |

Total: ~1030 LOC across 4 phases.

**Critical path:** Phase 0 -> Phase M2 -> Phase M1
**Parallel lane:** Phase A2 (independent)
