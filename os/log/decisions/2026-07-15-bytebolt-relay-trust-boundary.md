# Decision: ByteBolt Relay Trust Boundary (shelved)

> **Date:** 2026-07-15
> **Status:** Recorded. ByteBolt is SHELVED — this ADR fixes the boundary as an immutable
> commitment so it stops being restated in living prose; it authorizes NO build work.
> **Scope repo:** ecosystem (governance) + future `bytebolt-relay` / `bytebolt-app`.
> **Supersedes:** the repeated ByteBolt-boundary prose in `os/NOW.md` and the out-of-scope note
> in `os/log/decisions/2026-07-03-transport-session-unification.md` — both now point here.

## Context

Bolt is a protocol + platform. LocalBolt is the free, LAN-only adoption vehicle. ByteBolt is the
future commercial global tier: a relay backbone whose only job is connectivity / reliability (NAT
traversal, a guaranteed path across networks; TURN/DERP-style). It is NOT built. Its trust
boundary has been restated in multiple living documents, which invites drift.

## Decision

Record the boundary once, here, as an immutable architectural commitment:

1. The ByteBolt relay forwards **opaque ciphertext only.** It never sees, stores, or persists
   plaintext, keys, or file content.
2. **Zero server-side custody.** Strictly peer-to-peer end-to-end; the relay is an untrusted
   intermediary by construction (consistent with frozen ARCHITECTURE ARCH-04/05 and PRD §9).
3. The core / daemon MUST NEVER assume a trusted intermediary. A relay-assisted path is "just
   another transport" behind the frame-trait seam.
4. ByteBolt remains **SHELVED.** Nothing in the open base builds ByteBolt; do not start until Evan
   un-shelves it.

## SOC 2 forward (design only, nothing started)

The zero-custody boundary is the single most SOC-2-relevant architectural fact about ByteBolt.
When ByteBolt un-shelves, its audits / evidence / decisions route into the SAME homes
(`docs/AUDITS/`, `docs/evidence/`, `os/log/decisions/`) under a `bytebolt-` ID series. No SOC 2
work is started here — no control matrix, no relay, no code.

## Out of scope

No relay implementation, no ByteBolt app, no SOC 2 program. This ADR is a boundary record only.
