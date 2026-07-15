# EA1 PAKE v1 Profile — Adversarial Red-Team Report

> **Date:** 2026-07-15
> **Type:** Immutable evidence record (do not edit; corrections get their own dated entry).
> **Subject:** `os/log/decisions/2026-07-15-ea1-pake-v1-profile-proposal.md` (the EA1 PAKE v1
> profile *proposal* — PROPOSED, not wire-frozen, not implementation-authorized).
> **Method:** UltraCode adversarial review (multi-agent). 15 red-teamers, one per named attack
> surface, each told to assume the design is wrong; 50 candidate breaks; each independently refuted
> by an adversarial verifier (default-to-refuted); **20 refuted, 30 survived**, deduped to **10
> ranked findings**; one synthesis pass produced the verdict. (2 of 50 finding-verifications hit the
> structured-output retry cap and were dropped — a minor coverage gap on the one-sided-UX surface.)

## Verdict: **HAS-BLOCKERS**

**1 BLOCKER · 3 HIGH · 3 MEDIUM · 3 LOW.**

The design authenticates *knowledge of the code* (SPAKE2) and *possession of the ephemeral*
(envelope MAC) but **never possession of the identity private key**. On the reconnect path (no fresh
PAKE) an active rendezvous MITM impersonates any pinned peer using only its *public* identity key at
**zero online guesses**, reintroducing exactly the two-leg rendezvous MITM the PAKE was adopted to
close — on the dominant lifetime path (pair once, reconnect many). Because the repair is a
key-schedule / wire-format change, it cannot be retrofitted after a wire freeze.

**Live blast radius is currently zero** — the EA29 authorization boundary keeps `verified` disabled,
persists no verified pin, auto-trusts no reconnect, and never labels legacy "verified"; nothing is
wire-frozen and no code is authorized. That boundary is *why several findings were adjusted down*,
but it does **not** repair the design that a wire freeze would lock in.

## The BLOCKER (rank 1)

**Identity key is an unauthenticated bearer token — no proof-of-possession at pairing OR reconnect.**
Surface: identity-binding / reconnect-continuity / key-confirmation-MAC. Merges 5 candidate findings.

- The X25519 `identity_key` is committed in the transcript TT and pinned, but its private key is
  exercised nowhere (verified in-repo: HELLO sealing uses the ephemeral, never the identity key).
- Confirmation proves SECRET-knowledge (pairing) or ephemeral possession (reconnect), never key
  ownership.
- **Reconnect manifestation (BLOCKER):** with no fresh PAKE, an active rendezvous MITM impersonates
  any pinned peer using only the victim's PUBLIC key at zero guesses on every reconnect.
- **Pairing manifestations:** a code-knower grafts an arbitrary identity into a persistent
  "verified" pin; two legitimate pairings cross-graft into a two-session UKS relay.
- **Fix:** fold identity-DH — `ikm = k_pake ‖ DH(id_priv_self, id_pub_peer)` plus an
  identity×ephemeral DH for KCI resistance, Noise-IK/XX style — into the CONFIRMED key schedule at
  pairing AND reconnect, or run a fresh-code PAKE on every reconnect. Answer Open-Q(c) NO; resolve
  Unresolved #2; retract the authentication overclaims; do not mark `identity_key`
  authoritative/verified until a possession proof is in the frozen wire.

## Ranked findings

| # | Sev | Status | Surface | Break |
|---|-----|--------|---------|-------|
| 1 | BLOCKER | CONFIRMED | identity-binding / reconnect / MAC | No proof-of-possession of the identity private key → zero-guess reconnect impersonation from the public key alone; pairing-time identity grafting + two-session UKS. |
| 2 | HIGH | CONFIRMED | replay / rate-limit | One-guess bound not enforced: order-free confirmation exposes a MAC oracle; consume fires only "on mismatch" (harvest-then-drop keeps the code live); no atomic single-flight → N parallel PAIR_INITs test N guesses; rendezvous rate-limit is untrusted/inert. Degrades 40-bit MHF=none to network-rate brute force. |
| 3 | HIGH | CONFIRMED | downgrade / caps / old-client | Downgrade floor strippable at first contact: off-by-default, mode-select on unauthenticated pre-PAKE caps → MITM suppresses `bolt.pake-v1` on both legs, forces two PAKE-capable peers onto the legacy MITM-passable path. Line-89 closure claim false for the default case. |
| 4 | HIGH | CONFIRMED | routing/secret split | Boundary is client-behavioral, not structural: a legacy/downgraded initiator submits the whole `ROUTING+SECRET` string as the mailbox id → hands SECRET to the untrusted rendezvous → deterministic zero-guess MITM. |
| 5 | MEDIUM | CONFIRMED | one-sided UX | Phished/mis-delivered attacker code drives the honest success path to `verified_pake_v1` + persistent pin + reconnect auto-trust with no initiator consent; "verified" overclaims what a one-sided PAKE proves. |
| 6 | MEDIUM | CONFIRMED | per-transport channel binding | `channel_binding` as a transmitted field symmetrized by `sort_pair` is byte-identical under verbatim relay → zero transport-MITM detection; also optional; browsers expose no RFC-5705 exporter. Rider: must mandate `PAIR_INIT.ephemeral_key` == the BTR-root ephemeral or a transport-terminating MITM is a latent content-MITM. |
| 7 | MEDIUM | PLAUSIBLE | TT / caps codec | TT not proven injective / canonically decoded: caps lack per-element framing, `sort_pair` length-prefixes only `routing_id` → two honest mixed impls can hash identical bytes yet decode different capability sets (envelope/plaintext split-brain). |
| 8 | LOW | CONFIRMED | SPAKE2 symmetric / side_id | Self-acknowledged Unresolved #1: the crate's `BadSide` is inert in symmetric mode → reflected PAIR_INIT reaches the code-consuming step (pairing DoS / lockout burn); complement-key confirmation discipline under-fenced; balanced reduction + non-RFC transcript not scoped into the sign-off. |
| 9 | LOW | PLAUSIBLE | typed-pin migration | Keying the store by `identity_key` while reusing today's code-keyed lookup makes the `KEY_MISMATCH` tripwire dead code (hit or first-contact-miss, never "mismatch"). Spec-completeness debt. |
| 10 | LOW | PLAUSIBLE | routing/secret UX | SECRET rendered as an undifferentiated same-alphabet segment with nothing marking it a never-share password → support-desk / phishing disclosure. Phase-6 UX requirement. |

## The 9 required design changes before wire freeze

1. **Add identity proof-of-possession** bound into the CONFIRMED key schedule, applied at BOTH
   pairing AND reconnect: `PRK = HKDF-Extract(salt=TT, ikm = k_pake ‖ DH(id_priv_self, id_pub_peer))`
   plus an identity×ephemeral DH (Noise-IK/XX) for KCI — OR a fresh-code PAKE every reconnect.
   Reconnect MUST NOT accept public-key-match + ephemeral-keyed MAC as re-authentication. Until a
   possession proof is in the frozen wire, do not mark `identity_key` authoritative/verified or
   persist a verified pin (treat pairing as `approved_for_session`). Answers Open-Q(c) NO; resolves
   Unresolved #2. Non-retrofittable post-freeze.
2. **Fix one-time-code consumption** so the one-guess bound holds: receiver-confirms-last (the
   code-shower verifies the typer's PAIR_CONFIRM before disclosing any confirmation value); atomic
   consume + lockout at the first attempt / oracle exposure AND on drop/timeout, endpoint-local, at
   BOTH peers; per-code single-flight (reject, don't queue). Reclassify rendezvous rate-limiting as
   non-load-bearing (untrusted, SECRET-blind). Add concurrent-N-guess + abandonment adversarial
   tests. Resolve the consume-trigger contradiction toward consume-on-attempt.
3. **Make the downgrade floor un-strippable and mutual** by binding it to the out-of-band human code
   ceremony: showing a pake-v1 code MUST require PAIR_INIT/PAIR_CONFIRM and refuse any legacy/HELLO
   completion for that pairing; typing a pake-format code MUST refuse legacy fallback; default
   require-PAKE ON with legacy only via an explicit per-device "receive from an old device" mode;
   remove pre-`HANDSHAKE_COMPLETE` acceptance of a bare legacy HELLO once a ceremony is active; fold
   an unstrippable PAKE-capable signal into the code/QR. Add a suppress-PAIR_INIT adversarial test.
   Retract the line-89 closure claim until first-contact is covered.
4. **Make the ROUTING/SECRET boundary structural, not client-behavioral:** disjoint ROUTING/SECRET
   alphabets (or a typed/checksummed routing prefix); rendezvous MUST reject any mailbox id not
   matching the ROUTING grammar/length; mandate ROUTING and SECRET be independently CSPRNG-sampled
   (shared seed FORBIDDEN) with a golden-vector-grade property test; validate the extracted ROUTING
   locally BEFORE contacting the server; do not display SECRET until pake-v1 capability is proven.
5. **Specify one canonical, INJECTIVE binary codec** for `enc(PAIR_INIT)` and prove decode-canonicity
   before freeze: fixed-width length prefix on every variable field, count + per-element length on
   `capabilities[]`, presence + length on optional `channel_binding`, length-prefix each PAIR_INIT
   blob inside `sort_pair`, no trailing bytes at any level, fixed ASCII grammar for cap-names /
   version; strict canonical DECODE (reject non-minimal encodings); decode-direction + mixed
   TS-encode/Rust-decode round-trip golden vectors; soften the closure claim to
   conditional-on-injective-codec.
6. **Resolve Unresolved #1 + Open-Q(d):** the external cryptographer must RATIFY OR REPLACE symmetric
   SPAKE2 (role-assigned SPAKE2 / SPAKE2+ / CPace), the sign-off explicitly scoping the balanced
   Kobara-Imai reduction, the non-RFC-9382 wormhole transcript, and its composition with the external
   `HKDF(salt=TT)` + role-split HMAC confirmation. Pin the complement-key MUSTs, the reject-self-role
   tripwire, and an early reflection reject (`peer_pake_msg == own` → reject before key derivation).
7. **Redesign channel binding (Unresolved #3):** abandon the transmitted+symmetrized field (inert
   under relay); each endpoint MUST fold its LOCALLY-OBSERVED transport secret into a COMMON
   transcript slot (or apply an explicit fail-closed peer-claimed==observed check) with a
   require-binding floor on native transports that can export (WS/WT/QUIC via rustls/quinn); state
   plainly that browsers expose no (D)TLS exporter and a rendezvous-relayed cert-hash is not a trust
   anchor (close browser EA13 via identity-key TOFU on the PAKE-bound ephemeral). Load-bearing:
   MANDATE and VERIFY that `PAIR_INIT.ephemeral_key` equals the ephemeral keying the BTR
   `session_root`, so a transport-terminating MITM cannot substitute its own DH ephemeral.
8. **Widen the mandatory formal-model scope (Unresolved #6)** beyond the commit/transcript/confirm
   byte layout to ALSO model the reconnect / TOFU-continuity path and the endpoint one-time-code
   consumption + lockout state machine — as scoped, the model would miss both the reconnect BLOCKER
   and the guess-harvesting HIGH. It must assert: entity authentication requires identity-key
   possession (not just key-value agreement) at pairing and reconnect; the one-guess bound under an
   untrusted rendezvous; reflection/UKS resistance from the password-keyed complement-verified
   confirmation; and TT injectivity (distinct structures → distinct bytes).
9. **Complete the remaining spec-correctness items:** (a) fix PinRecord v2 so `KEY_MISMATCH` stays
   reachable — key the store by a stable locally-assigned contact handle and store `identity_key` as
   a compared VALUE; (b) label first one-sided pairings honestly ("code-confirmed" vs "verified"),
   add an initiator consent that the MAC proves only same-code, gate persistent verified pins /
   reconnect auto-trust behind explicit "remember this device", resolve Unresolved #5 toward showing
   the verifier to both humans as a wrong-device cross-check; (c) file the `spake2 0.4.0` unaudited /
   not-constant-time / no-zeroization HIGH sign-off (Unresolved #4); (d) add Phase-6 anti-phishing UX
   (mark SECRET sensitive/never-share; no single off-app full-code copy affordance); (e) retract or
   scope every affirmative closure/authentication claim the review falsified (ADR lines 89, 150, 164,
   and "Closes … EA16").

## Phase 1 / implementation status

**Phase 1 spec drafting may begin only as drafting / formal-model work; implementation and
wire-freeze are forbidden.**

Detail: Phase 1 is spec design-freeze DRAFTING + formal-model work — no product code — and
wire-freeze is the Phase-1 EXIT gate, not its entry. The nine required changes are the mandatory
spec inputs Phase 1 must resolve and cannot be resolved without doing spec work, so drafting may
proceed in parallel with the Phase-0 external-cryptographer engagement. Hard gates on the single
irreversible step (wire-freeze):

- The nine required changes are mandatory spec inputs; all are wire/key-schedule changes that cannot
  be retrofitted after freeze.
- **Wire-freeze is FORBIDDEN** until the external cryptographer signs off — including the symmetric-
  mode reduction, the no-proof-of-possession question answered NO, and an explicit SPAKE2-vs-CPace
  accept/reject — AND the widened formal model passes.
- Primitive-dependent sections stay UNFROZEN until the ratify-or-replace decision resolves (CPace /
  role-assigned SPAKE2 / SPAKE2+ would change the wire).
- The ADR's falsified affirmative closure/authentication claims must be retracted or scoped in the
  same draft.

**No implementation is authorized. The `spake2` spike stays inert and unmerged. Old "verified"
stays disabled until EA1 ships and passes its gates (EA29 posture).**

## What holds up (keep it)

The type-a-secret PAKE direction is sound (it eliminates the offline SAS grind). Symmetric SPAKE2
is a viable primitive pending cryptographer ratification. External transcript binding, typed
identity-keyed pins, one-time-code consumption, and the honest product-state model are the right
shape — the review's changes harden *how* they are specified, not *whether* to use them. The EA29
authorization boundary correctly bounds live risk to zero while the design is revised.
