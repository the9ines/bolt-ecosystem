# Decision: EA1 — Adopt a Vetted PAKE for Device Verification (direction)

> **Date:** 2026-07-15
> **Status:** Direction accepted. NOT productized — EA1 remains OPEN; a spike exists but is
> unmerged; the full workstream is future governed work gated on an external cryptographer.
> **Scope repo:** bolt-core-sdk (SDK), bolt-protocol (spec), downstream products — all future.
> **Supersedes:** the "hand-roll a SAS commit-reveal" direction (rejected). EA1 reopens SA11's
> DONE-BY-DESIGN "bind keys into the SAS" mitigation; the `SUPERSEDED-BY:EA1` token on the SA11
> tracker row is deferred to Governance OS v2 Phase 4 (no tracker-row rewrites in Phase 3).

## Context

The shipping 24-bit SAS has no commitment, and the identity key is X25519 (non-signing, no
proof-of-possession), so an active MITM at the rendezvous can grind both peers to a matching
"verified" code. Two red-teams (the EA1 pairing red-team; the trust-gate design red-team) returned
HAS-BLOCKERS and showed a hand-rolled commit-reveal is ALSO broken (it commits only the ephemeral;
the uncommitted identity is birthday-grindable offline). Evidence: `docs/evidence/EA1_REDTEAM.md`,
`docs/evidence/EA4_REDTEAM.md`, `docs/evidence/PAKE_EVAL.md`, and the EA1 row in
`docs/AUDIT_TRACKER.md`.

## Decision

1. Do **NOT** hand-roll pairing crypto. Adopt a **vetted PAKE** (SPAKE2 / Magic-Wormhole-style
   typed code) with a **professional cryptographer** engaged before design-freeze.
2. A Rust→WASM feasibility **spike is DONE but UNMERGED** and explicitly **not productized**
   (`spike/spake2-wasm` in bolt-core-sdk; library eval `docs/evidence/PAKE_EVAL.md`). Do not touch
   the spike branch as part of unrelated work.
3. EA1 **gates** all "verified" / persistent-pin behavior. Until it lands, products stay honest:
   authorization-only, no cryptographic "verified" claim, no persistent verified pin (see the
   trust-gate + honest-verification ADR / EA29).
4. This is a **direction record, not a start order.** The PAKE workstream (protocol-spec revision +
   major SDK bump + single canonical codec + cross-impl golden vectors + adversarial tests +
   forced-comparison UX + staged rollout) begins only on explicit authorization.

## Out of scope

No PAKE implementation, no spike merge, no spec change, no security code, no SOC 2. Direction only.
