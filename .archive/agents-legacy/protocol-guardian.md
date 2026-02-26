# Protocol Guardian

Guards Bolt Core correctness in bolt-protocol and bolt-core-sdk.

---

## Core vs Profile Separation (Hard Rule)

- Bolt Core defines message semantics, security, state machines, conformance.
- Profiles define transport, framing, encoding, rendezvous, platform policies.
- Core MUST NOT reference any transport or encoding implementation.
- Profile MUST declare which Core version it implements.

---

## Core Denylist

The following terms MUST NOT appear in Bolt Core text or code:

**Transport terms:**
`WebRTC`, `WebSocket`, `DataChannel`, `SDP`, `ICE`, `STUN`, `TURN`,
`libdatachannel`, `RTCPeerConnection`, `RTCDataChannel`, `wss://`, `ws://`

**Encoding terms:**
`json-envelope-v1`, `bin-v1`, `JSON`, `UTF-8`, `base64`, `hex`,
`camelCase`, `snake_case`

**Allowed exception:**
- "Profile-defined encoding identifier" (abstract reference only)

---

## Envelope Schema (Core Level)

| Field | Type | Required |
|-------|------|----------|
| `sender_ephemeral_key` | bytes32 | required |
| `nonce` | bytes24 | required |
| `ciphertext` | bytes | required |

Ciphertext = `NaCl box(plaintext, nonce, receiver_eph_pub, sender_eph_sec)`

---

## HELLO Contents

| Field | Type | Required |
|-------|------|----------|
| `bolt_version` | uint32 | required |
| `capabilities` | string[] | required |
| `encoding` | string | required |
| `identity_key` | bytes32 | required |
| `limits` | object | optional |

- HELLO MUST NOT contain ephemeral key.
- Ephemeral public key source: `sender_ephemeral_key` from the envelope header that carried HELLO.

---

## SAS Computation

```
identity_A, identity_B  = raw 32-byte identity keys from decrypted HELLOs
ephemeral_A, ephemeral_B = raw 32-byte keys from envelope headers that carried those HELLOs

SAS_input = SHA-256( sort32(identity_A, identity_B) || sort32(ephemeral_A, ephemeral_B) )
Display = first 6 hex chars uppercase (24 bits)
```

- MUST use raw bytes, not encoded representations.
- sort32 = lexicographic sort of two 32-byte values, then concatenate.

---

## Protected vs Unprotected Messages

**Protected (MUST be inside envelope):**
HELLO, FILE_OFFER, FILE_ACCEPT, FILE_CHUNK, FILE_FINISH,
PAUSE, RESUME, CANCEL, ERROR

**Unprotected (plaintext, no envelope):**
PING, PONG

- Unprotected messages MUST NOT contain sensitive data.

---

## Handshake Gating Rule

Before mutual HELLO completion, a peer MUST accept only:
1. PING / PONG (plaintext)
2. Encrypted envelope containing HELLO
3. Encrypted envelope containing ERROR

All other messages MUST be rejected with `ENVELOPE(ERROR(INVALID_STATE))`.

Each peer MUST send exactly one HELLO per connection attempt.

---

## Conformance Tests

1. Handshake gating: FILE_OFFER before HELLO -> ERROR(INVALID_STATE)
2. Key mismatch: pinned key differs -> ERROR(KEY_MISMATCH) then close
3. Replay: duplicate (transfer_id, chunk_index) -> ERROR(REPLAY_DETECTED)
4. Limit: oversize offer -> ERROR(LIMIT_EXCEEDED)
5. SAS vectors: identity keys + envelope-header ephemeral keys -> expected 6 hex chars
6. Envelope: protected message outside envelope -> reject
7. Plaintext leak: PING/PONG contain no sensitive data

---

## Red Flags

Edits that likely violate Core:

- [ ] Adding any denylist term to PROTOCOL.md
- [ ] Putting ephemeral key inside HELLO message
- [ ] Referencing a concrete encoding format in Core
- [ ] Sending ERROR outside an encrypted envelope
- [ ] Adding transport-specific state to state machines
- [ ] Making file_hash unconditionally required (it is capability-gated)
- [ ] Using identity key for bulk encryption
- [ ] Allowing nonce reuse or static nonce
- [ ] Removing handshake gating checks
- [ ] Skipping MAC verification before processing
