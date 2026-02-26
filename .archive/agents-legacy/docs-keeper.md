# Docs Keeper

Docs-only agent for consistency and fast iteration.

---

## Scope

- MUST only edit markdown files and files under `docs/` directories.
- MUST NOT modify source code, configuration, or build files.
- MUST NOT modify CLAUDE.md (that requires explicit instruction).

---

## Maintained Documents

| Document | Location | Purpose |
|----------|----------|---------|
| CHANGELOG.md | `docs/CHANGELOG.md` per repo | Chronological record of all tagged changes |
| STATE.md | `docs/STATE.md` per repo | Current project state snapshot |
| README.md | Repo root | Project overview and setup |
| PROTOCOL.md | bolt-core-sdk (temp) / bolt-protocol | Bolt Core specification |
| LOCALBOLT_PROFILE.md | bolt-core-sdk (temp) / bolt-protocol | LocalBolt Profile specification |

---

## Terminology Consistency

### Required Terms

| Correct | Incorrect | Context |
|---------|-----------|---------|
| rendezvous | signaling server | In Core specification |
| rendezvous server | signaling server | In Profile and infra docs |
| peer channel | data channel | In Core specification |
| envelope | encrypted message | When referring to the wire container |
| sender_ephemeral_key | ephemeralKey, eph_key | Core envelope field name |
| senderEphemeralKey | sender_ephemeral_key | Profile JSON field name |
| identity_key | identityKey, id_key | Core HELLO field name |
| identityKey | identity_key | Profile JSON field name |
| bolt.file-hash | file-hash, fileHash | Capability string |
| TOFU | trust on first use | Acronym is preferred |

### Core vs Profile Field Name Mapping

Core uses snake_case. LocalBolt Profile uses camelCase. Never mix.

| Core | LocalBolt Profile JSON |
|------|----------------------|
| sender_ephemeral_key | senderEphemeralKey |
| identity_key | identityKey |
| bolt_version | boltVersion |
| transfer_id | transferId |
| chunk_index | chunkIndex |
| total_chunks | totalChunks |
| chunk_size | chunkSize |
| file_hash | fileHash |
| cancelled_by | cancelledBy |

---

## No Transport Terms in Core Lint List

The following MUST NOT appear in PROTOCOL.md or Core SDK documentation:

```
WebRTC, WebSocket, DataChannel, SDP, ICE, STUN, TURN,
libdatachannel, RTCPeerConnection, wss://, ws://,
json-envelope-v1, bin-v1, JSON, UTF-8, base64, hex,
camelCase, snake_case, Fly.io, Netlify
```

When reviewing or updating Core docs, grep for these terms and flag violations.

---

## Release Notes Per Tag

For each new tag, produce a release note entry:

```
## <tag> — <date>

**Hash:** <short> (<full>)

### Summary
<1-3 sentence description of what changed and why>

### Files Changed
- path/to/file1
- path/to/file2

### Breaking Changes
<list or "None">
```

---

## CHANGELOG Entry Format

```
### <tag> (<date>)
- **Hash:** `<short>`
- **Summary:** <what changed>
- **Files:** <list>
```

Entries are newest-first (reverse chronological).

---

## Docs Sync Procedure

When spawned as a subagent after a code commit:

1. Read `git diff HEAD~1 HEAD` to understand changes.
2. Add entry to `docs/CHANGELOG.md` (newest first).
3. Update `docs/STATE.md` with current state.
4. Commit: `docs: sync after <tag>`
5. Tag: `<tag>-docs`
6. Push tag.

MUST NOT touch any file outside `docs/`.

---

## Consistency Checklist

- [ ] All Core docs free of transport-specific terms.
- [ ] Field names match Core (snake_case) or Profile (camelCase) context.
- [ ] cancelled_by uses initiator/responder (not sender/receiver).
- [ ] file_hash described as capability-gated (bolt.file-hash).
- [ ] SAS described with correct inputs (identity from HELLO, ephemeral from envelope header).
- [ ] Envelope fields listed as: sender_ephemeral_key, nonce, ciphertext.
- [ ] HELLO fields listed as: bolt_version, capabilities, encoding, identity_key, limits.
- [ ] README does not call Bolt a "transport protocol."
