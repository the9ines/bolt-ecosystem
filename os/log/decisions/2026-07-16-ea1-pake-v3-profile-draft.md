# Decision: EA1 PAKE v3 Protocol Profile — Revised Draft

> **Date:** 2026-07-16
> **Status:** **PROPOSED — NEEDS REVISION. NOT WIRE-FROZEN. NOT IMPLEMENTATION-AUTHORIZED. NO
> "verified" PRODUCT BEHAVIOR.** A v3 adversarial red-team (2026-07-16) returned **NEEDS-REVISION** —
> see the *Red-team outcome (v3): NEEDS REVISION* note below and `docs/evidence/EA1_PAKE_V3_REDTEAM.md`.
> Incorporates the eight required changes from the v2 adversarial red-team
> (`docs/evidence/EA1_PAKE_V2_REDTEAM.md`, verdict HAS-BLOCKERS). Supersedes-in-specifics the v2
> draft (`os/log/decisions/2026-07-15-ea1-pake-v2-profile-draft.md`, PROPOSED — REVISION REQUIRED),
> which is retained verbatim. EA1 remains **OPEN**. Contains open items that REQUIRE an external
> cryptographer — marked **[CRYPTO-DECISION]** — and cannot be wire-frozen until they resolve.
> **Scope repos:** `bolt-protocol` (future spec), `bolt-core-sdk` (future SDK), products — all future,
> all gated.
> **Lineage:** direction ADR `2026-07-15-ea1-adopt-pake-direction.md` → v1 proposal
> (`…-ea1-pake-v1-profile-proposal.md`, REVISION REQUIRED) → v2 draft (REVISION REQUIRED) → **this
> v3 draft.** Evidence: `docs/evidence/EA1_REDTEAM.md`, `docs/evidence/PAKE_EVAL.md`,
> `docs/evidence/EA1_PAKE_PROFILE_REDTEAM.md`, `docs/evidence/EA1_PAKE_V2_REDTEAM.md`.

## Red-team outcome (v3): NEEDS REVISION

A v3 UltraCode adversarial review (2026-07-16, the third pass) returned **NEEDS-REVISION**. Full
report: **`docs/evidence/EA1_PAKE_V3_REDTEAM.md`**.

- **This draft is PROPOSED — NEEDS REVISION. Not wire-frozen, not implementation-authorized.**
- **The process is converging.** No confirmed blocker survives — the §0 low-order/all-zero-DH rule
  **genuinely closes the v2 rank-1 BLOCKER**, and the reconnect downgrade floor holds. The verdict is
  driven by **1 confirmed HIGH + 4 confirmed MEDIUM, all draft-defects** (author-fixable prose/spec/
  wire-precision corrections, not cryptographer primitive decisions), plus 11 items correctly deferred
  to the external cryptographer.
- **The confirmed defects:** (HIGH) §8 escalates device-wide backoff on a garbage `PAIR_CONFIRM`,
  self-contradicting its own "never anonymous inbound probes" and relocating the v2 anonymous-probe
  DoS; (MEDIUM) §6 `session_root` salt `(or TT)` permits a public salt that voids the backstop and
  breaks cross-impl determinism; (MEDIUM) §6 `ephemeral_shared_secret` is undefined and the equality
  MUST is type-confused (public key == DH output); (MEDIUM) §1's "a legacy parser rejects the `bolt2:`
  container" is *code-verified false* (the deployed `normalizePeerCode` forwards verbatim); (MEDIUM)
  §4's "reflection resistance independent of the confirmation mechanism" is false (§5's
  direction-separated confirmation is load-bearing).
- **The 9 required changes before wire-freeze** are enumerated in the evidence file: (1) §8 decouple
  consume from device-wide backoff (never escalate on anonymous inbound); (2) §6 mandate `salt = PRK`,
  drop `(or TT)`, TT only in `info`; (3) §6 define `ephemeral_shared_secret = ee` and fix the
  type-confused MUST; (4) §1 drop the false legacy-parser claim, strongest = separate ROUTING/SECRET
  inputs; (5) §4 attribute reflection resistance jointly (reject + TT-bind + mandatory
  direction-separated confirmation); (6) §4/§0 canonical X25519 equality; (7) §1 differential CSPRNG
  KAT + negative case; (8) §9 reconnect `contact_id` resolution so KEY_MISMATCH is reachable; (9) §9
  gate rotation-overwrite behind CD1b.
- Old "verified" stays disabled (EA29). Wire-freeze remains FORBIDDEN until these edits land, the
  external cryptographer signs off the deferred `[CRYPTO-DECISION]` items, and the formal model passes.
  After the nine edits, the draft is expected to reach ACCEPTABLE-FOR-CRYPTOGRAPHER-REVIEW.

This draft is retained verbatim as the *reviewed v3*; the revision that incorporates the nine edits is
tracked separately as the v4 draft.

## What v3 changes (the eight required fixes)

v3 keeps the type-a-secret PAKE + identity-DH direction the v2 review validated and applies the eight
required changes. Each is called out in the design below with a **[FIX n]** tag.

| # | Area | v3 fix |
|---|------|--------|
| 1 | Low-order X25519 / all-zero DH | Normative point validation + all-zero-DH abort, identity + ephemeral, pairing + reconnect (§0). |
| 2 | Routing/SECRET split | SECRET-off-server is a *conforming-client* property; separate ROUTING/SECRET artifacts; version-container so legacy parsers reject rather than forward (§1). |
| 3 | Session-root binding | `session_root` bound to the authenticated transcript; `ephemeral==BTR-root` a fail-closed MUST (§6). |
| 4 | Anti-reflection | Primitive-independent self/reflection reject before key derivation, all paths (§4). |
| 5 | CSPRNG independence | Two separate CSPRNG reads; white-box KAT, no statistical test (§1). |
| 6 | Reconnect downgrade | `possession_proven` pin ⇒ identity-DH reconnect mandatory, legacy forbidden fail-closed (§7). |
| 7 | Pin / contact_id | CSPRNG `contact_id`, `identity_key` compared, human-confirmed rotation, hostile KEY_MISMATCH (§9). |
| 8 | Code consumption | Typer consumes on value at confirm-exposure; no consume/backoff on unauthenticated probes (§8). |

### Claims retracted/corrected (falsified by v1/v2 review)

- v1 lines 89/150/164 + "Closes … EA16" — retracted in v2, stay retracted.
- v2 §1 "directly closes the reconnect BLOCKER" — **hedged:** reconnect security is contingent on the
  §0 point validation being in the frozen wire AND the cryptographer sign-off; not an achieved fact.
- v2 §4 "the server can never process SECRET as a routing token" — **retracted:** an untrusted server
  cannot be relied on to reject; SECRET-off-server is a conforming-client property (§1).
- v2 §6 "CPace sidesteps reflection" — **retracted:** reflection resistance is provided by the §4
  reject, primitive-independently (§4).
- v2 §7 "a MITM that cannot complete the PAKE is caught anyway" — **retracted:** a *relaying* MITM
  completes the PAKE; the anti-content-MITM property is provided by the §6 ephemeral binding, not by
  PAKE-completion.
- v2 §9 `possession_proven`-as-achieved-fact — **conditioned:** set only after §0 validation succeeds.

---

## §0 — Key validity (NEW, normative — [FIX 1])

All Curve25519 public keys and all X25519 DH outputs are validated **before use**. This is a wire
rule, not a `[CRYPTO-DECISION]`.

- **Reject known small-order u-coordinates.** Any received `identity_key` or `ephemeral_key` whose
  u-coordinate is one of the known small-order Curve25519 points (the RFC 7748 §6.1 blacklist — 0, 1,
  the two low-order x-coords and their negations, `p-1`, `p`, `p+1`, etc.) MUST be rejected before any
  DH.
- **Abort on all-zero DH output.** After every X25519 (`ee`, `es`, `se`, `ss`, and the
  ephemeral-shared-secret of §6), if the 32-byte output is all-zero, the session MUST abort
  (constant-time check; RFC 7748 §6.1 contributory-behaviour requirement). This catches any
  low-order/small-subgroup input that clamping did not.
- **Scope:** applies to **both identity and ephemeral** keys, at **both pairing and reconnect**.
- **Pins:** an identity key that fails validation MUST NOT be used, MUST NOT be pinned, and MUST NOT
  set `possession_proven`.
- **Reconnect revalidation:** the pinned `identity_key` and the peer's fresh ephemeral MUST be
  re-validated (blacklist + all-zero-DH) before every reconnect DH — a pin written before this rule,
  or a peer presenting a fresh bad ephemeral, is caught.
- **Rationale:** X25519 clamps scalars to a multiple of cofactor 8, so DH against a low-order point
  returns the all-zero constant regardless of the honest private key. Without §0, a peer pairing once
  with a low-order identity key gets a `possession_proven` pin on a key nobody owns, and any codeless
  MITM then forges every reconnect. §0 is the direct fix for the v2 rank-1 BLOCKER.
- **Model + tests:** §0 is an explicit formal-model obligation (the symbolic model MUST encode
  DH(low-order, ·)=0, which an algebraic DH abstraction misses) and ships low-order-static and
  low-order-ephemeral adversarial golden vectors. "Adopt Noise KK" does **not** supply §0 — Noise
  treats all-zero DH as legitimate (dummy static keys).

---

## §1 — Human-code UX + routing/secret split ([FIX 2], [FIX 5])

- **One-sided entry** (magic-wormhole model): the displaying peer generates + shows the code; the
  initiating peer's human types it. (Unchanged from v2.)
- **Two separate artifacts, not one string [FIX 2]:** the pairing code is structurally two fields:
  - `ROUTING` — the rendezvous mailbox locator. Public. The only value sent to the rendezvous.
  - `SECRET` — the PAKE password. Fed **only** to the local PAKE; **never** placed in any
    rendezvous-facing message.
  Delivery keeps them separate so a legacy/version-skewed client cannot forward SECRET:
  - **QR / structured transport:** `ROUTING` and `SECRET` are distinct fields; the client reads
    SECRET into the PAKE-secret input and only ROUTING into the mailbox lookup.
  - **Typed code:** wrapped in a **version container** (e.g. `bolt2:<ROUTING>.<SECRET>`) whose
    `bolt2:` tag a legacy "enter code" parser does **not** recognize, so it **rejects** the input
    rather than forwarding the whole string verbatim as a mailbox id. A conforming v3 client parses
    the container, sends only ROUTING to the rendezvous, and feeds SECRET to the PAKE.
  - **Local validation before any network I/O:** the client extracts and validates ROUTING locally
    (grammar/length) and fails locally on malformed input — transmitting nothing on failure.
- **SECRET-off-server is a conforming-client property [FIX 2].** We do **not** claim the server
  "cannot receive" SECRET — an untrusted/malicious rendezvous will not self-enforce anything. The
  guarantee is: a *conforming* client never emits SECRET in a rendezvous-facing message. Honest-server
  rejection of non-ROUTING ids is retained as hygiene only, explicitly **not** a security control.
- **CSPRNG independence [FIX 5]:** ROUTING and SECRET are produced by a single audited sampling
  routine doing **two separate CSPRNG reads** (no shared or derivable seed). Deriving either from the
  other, or both from a shared seed, is **FORBIDDEN**. There is **no** "statistical/property test"
  claim (a black-box test cannot detect PRF-derivation). Enforcement is a **white-box KAT**: feed two
  distinct mocked entropy streams and assert ROUTING is a function of stream-A only and SECRET of
  stream-B only, cross-impl (Rust + WASM). ROUTING length/format is a constant independent of SECRET
  (kills length/timing correlation).
- **Alphabet / entropy:** SECRET ≈ 8 chars from the 31-char unambiguous alphabet (~40 bits) with the
  v1 NFC→uppercase-fold→drop→re-segment normalization re-pinned as a v3 golden vector; the ROUTING
  grammar (disjoint alphabet vs typed checksummed prefix) and the final SECRET entropy/MHF are
  **[CRYPTO-DECISION 4a]** (must satisfy the anti-bleed MUST: a full separator/MAC, confusable-free,
  transmit-nothing-on-failure — not a short human checksum).

---

## §2–§3 — Message sequence + transcript TT

Unchanged from v2 in shape: after the peer channel opens, peers exchange `PAIR_INIT` (symmetric,
carrying `side_id`, `pake_msg`, `identity_key`, `ephemeral_key`, `bolt_version`, `capabilities[]`),
then `PAIR_CONFIRM`. The transcript `TT` is the canonical, injective encoding of both PAIR_INITs
(the injective binary codec of v2 §5, with the byte-layout freeze a **[CRYPTO-DECISION 5a]** proven by
a verified codec, not the symbolic model). **Addition:** the §0 validation runs on every received
`identity_key`/`ephemeral_key` in `PAIR_INIT` before it is used in any DH or written to TT-derived
state.

---

## §4 — PAKE + identity-DH key schedule ([FIX 1] validation, [FIX 4] anti-reflection)

**Pairing:** `ikm = k_pake ‖ ee ‖ es ‖ se ‖ ss`, `PRK = HKDF-Extract(salt = TT, ikm)`.
**Reconnect:** `ikm = ee ‖ es ‖ se ‖ ss` (no `k_pake`). Every DH is §0-validated (all-zero abort).

- **Primitive-independent anti-reflection [FIX 4]:** **before any key derivation**, on **both** the
  CPace and SPAKE2 PAKE paths and on the reconnect KK path, reject the inbound `PAIR_INIT` if any of:
  `peer_ephemeral == own`, `peer_identity_key == own`, `peer_pake_msg == own`, `peer_side_id == own`.
  This anti-self-pairing/anti-reflection guard does **not** depend on the PAKE's internal structure.
- Reflection/UKS resistance is therefore provided by this reject **plus** binding both identity keys
  in TT — **independent** of the SPAKE2 complement-verified confirmation. The v2 "CPace sidesteps
  reflection" claim is **retracted**.
- **[CRYPTO-DECISION 1a]** the named Noise pattern (reconnect ≈ KK, pairing ≈ XX/IK+PSK), the exact
  DH set/mixing order and the PAKE⊕Noise composition — this also role-fixes the `es`/`se` slot order
  (initiator/responder) so the two endpoints converge, supplies pairing↔reconnect domain separation,
  and reconciles the flat-concat `ikm` with a Noise-PSK sequential domain-separated mix.
- **[CRYPTO-DECISION 6]** PAKE primitive: CPace (recommended primary) vs SPAKE2-0.4.0 (fallback) vs
  SPAKE2+; plus the balanced-reduction / non-RFC transcript / external-HKDF composition and the
  unaudited / not-constant-time / no-zeroization HIGH sign-off. Wire-affecting; the §4 anti-reflection
  reject holds for whichever primitive is chosen.

---

## §5 — Key confirmation

As v2: `PRK` → HKDF-Expand to `K_conf_L`, `K_conf_R`, `K_session`, optional `SAS_disp`; each side
sends its role's MAC and verifies the peer's under the complement role key, constant-time,
fail-closed. **Additions:** the confirmation MUST use direction-separated tags (not "try-both"); the
reflection reject (§4) runs first, so a reflected `PAIR_INIT` never reaches the confirmation step. On
failure → `PAIR_CONFIRM_FAILED`, fail-closed, no pin (see §8 for consumption).

---

## §6 — Session root binding + channel binding ([FIX 3])

- **Bind the data-channel root to the authenticated transcript [FIX 3].** Derive
  `session_root = HKDF(salt = PRK (or TT), ikm = ephemeral_shared_secret)`. A data ephemeral that was
  **not** the one authenticated in `PAIR_INIT`/TT produces a different `session_root`, so a
  transport-terminating/relaying MITM that substitutes its own DH ephemeral fails **cryptographically**
  on every transport — not merely via a byte-check. This replaces v2's `HKDF(empty-salt,
  bare-ephemeral-DH)`.
- **`ephemeral_key` equality is a fail-closed MUST [FIX 3].** `PAIR_INIT.ephemeral_key` (bound in TT)
  MUST equal the `sender_ephemeral_key` of every post-handshake envelope and the input to
  `session_root`. Enforced on the receive path **before** `HANDSHAKE_COMPLETE` / before any data
  envelope. The profile's prior MAY-compare/warn is upgraded to a fail-closed MUST. This is promoted
  from v2 prose to a normative rule **and** a §8 model obligation.
- **Channel binding (fold-locally):** each endpoint folds its **locally-observed** transport secret
  into a common schedule slot (never transmit-and-symmetrize). Require-binding floor on native
  transports that can export (rustls RFC-5705 / QUIC exporter). Browsers expose **no** exporter; the
  relayed cert-hash is attacker input and is **not** a trust anchor — the browser leg's
  transport-MITM resistance comes from the §6 `session_root` binding + identity-DH (§4), not from a
  transport exporter. Exact exporter, the fold construction, and the mixed native↔browser
  reconciliation are **[CRYPTO-DECISION 7a]** (bind the transport-tier signal into TT/ceremony so
  tier-select is not attacker-forceable; make binding-divergence a non-code-consuming soft failure).

---

## §7 — Downgrade floor: pairing + reconnect ([FIX 6])

- **Pairing (as v2):** the floor is bound to the out-of-band human code ceremony + an unstrippable
  PAKE-capable marker in the code/QR; default require-PAKE ON; bare-legacy-HELLO rejected during a
  ceremony.
- **Reconnect [FIX 6] (new):** a **`possession_proven` pin makes identity-DH reconnect MANDATORY and
  NON-OVERRIDABLE** for that contact, on **both** peers. Legacy / "receive from an old device" mode
  and any BTR→static downgrade are **FORBIDDEN** for a `possession_proven` contact — fail-closed
  (refuse, never fall back). The reconnect capability floor is enforced from the **authenticated
  identity-DH result**, never from MITM-mutable ephemeral-keyed HELLO caps. A reconnect-downgrade /
  suppress-DH-marker vector is added to §8.

---

## §8 — One-time code consumption ([FIX 8])

Endpoint-local state `LIVE → IN_FLIGHT → CONSUMED`, single-flight (reject-not-queue). Corrected so
consumption tracks **authenticated** guesses only:

- **Count a guess only on a secret-authenticated `PAIR_CONFIRM` [FIX 8].** A code is driven to
  `CONSUMED`, and any lockout/backoff escalates, **only** when a valid secret-authenticated
  `PAIR_CONFIRM` is processed (success or verified-failure). **Unauthenticated outcomes** — a bare,
  abandoned, or garbage `PAIR_INIT`, a drop, or a timeout — MUST NOT consume the code or escalate
  device backoff; such a probe holds at most a short single-flight slot that returns the code to
  `LIVE`. (This removes the v2 unauthenticated-probe denial-of-pairing.)
- **Typer-side consumption [FIX 8].** The code-**typer** MUST consume the typed SECRET keyed on its
  **value** at confirm-exposure (one `PAIR_CONFIRM` emitted = one guess spent), persist a
  consumed-value refusal so re-entry/re-run of the same SECRET is rejected, and **forbid auto-retry**.
  Lockout extends to typer re-entry of a consumed value. This mechanizes the leg where
  receiver-confirms-last relocates the oracle.
- **Receiver-confirms-last (as v2):** the shower verifies the typer's `PAIR_CONFIRM` before disclosing
  its own confirmation value.
- **Rendezvous rate-limiting is anti-spam only [FIX 8].** It is reinstated as an availability
  throttle, explicitly **NOT** a security proof — the untrusted, SECRET-blind rendezvous cannot bound
  guessing. The v2 §2.3 "throttles serial guessing across regenerated codes" claim is **removed**; the
  lockout key is local device backoff on **locally-human-initiated ceremonies only**, never anonymous
  inbound probes.
- **[CRYPTO-DECISION 2a/2b]** lockout parameters + consume-trigger timing, **plus** a separate
  **quantitative** guessing-infeasibility budget (SECRET entropy × allowed-guesses × backoff → work
  factor), gated separately from the symbolic proof.

---

## §9 — Pins + reconnect ([FIX 7], [FIX 1] revalidation, [FIX 6])

- **`PinRecord v3`:**
  ```
  { pin_format: 3, contact_id (KEY), identity_key: [32]u8 (COMPARED value),
    pake_profile, bound_via: "pake-v3" | "reconnect-dh", possession_proven: bool,
    first_paired_at, transcript_hash?, device_label }
  ```
- **`contact_id` is a unique, CSPRNG-minted local handle [FIX 7]** — never seeded from a user or
  peer-advertised label. `device_label` is a separate, non-key display field; two contacts may share a
  `device_label` but never a `contact_id`.
- **`identity_key` is a compared value [FIX 7]**, not the store key — so `KEY_MISMATCH` stays reachable
  (look up by `contact_id`; compare the presented `identity_key`).
- **Key rotation [FIX 7]:** writing an existing `contact_id` with a **new** `identity_key` MUST be an
  **explicit human-confirmed rotation via a fresh PAKE** — distinct from the reconnect-path
  `KEY_MISMATCH`, which remains a **hostile abort** (fail-closed + explicit re-pair).
- **`possession_proven` [FIX 1]** is set **only** after §0 validation succeeds and the §4 DH
  confirmation proves the identity private key. Reconnect requires the §0-revalidated identity-DH (§7
  floor) — never a bare public-key match.
- **Migration:** transactional (bump `DB_VERSION`); old v1/v2 pins ignored for trust (EA29), optionally
  kept as weak "seen-before" hints; `pin_format` keeps versions byte-distinguishable; no mass reset.

---

## §10 — Product states (honest, NO "verified")

Unchanged from v2 and consistent with the "No verified product behavior" constraint: `unverified`
(block-default) · `approved_for_session` · `code_confirmed` (same-code + private-key possession, not
"the intended device"; persistent pin only with explicit "remember this device") ·
`reconnect_authenticated` (matched `possession_proven` pin via identity-DH) · `pake_failed` /
`key_mismatch` (hostile, fail-closed) · `legacy` (policy-gated authorization, never "verified"). No
product-facing "verified" claim ships; the canonical enum rename to honest semantics is recommended.
Transfer gate enforced on the **receive path**. Anti-phishing UX: SECRET rendered as sensitive
(never-share), no single off-app full-code copy affordance.

---

## Remaining cryptographer decisions ([CRYPTO-DECISION])

Carried from the v2 review (unchanged by the eight fixes, which are draft-level):

| Tag | Decision |
|---|---|
| 1a | Named Noise pattern + DH set/mixing order + PAKE⊕Noise composition (role-fixes es/se; pairing↔reconnect domain separation) |
| 1b | KCI scope of es/se; identity-key rotation / whether a signed cross-cert is needed |
| 1c | Reconnect cadence — bounded re-anchoring vs "sufficient indefinitely"; compromise-recovery / revocation |
| 2a/2b | Lockout parameters + consume timing + a **separate quantitative** guess-work-factor budget |
| 4a | ROUTING grammar + anti-bleed MUST + ROUTING length + SECRET entropy/MHF |
| 5a | Injective byte-layout freeze via a **verified codec / grammar proof** (the symbolic model cannot prove byte injectivity or cross-impl decoder equivalence) |
| 6 | PAKE primitive: CPace (recommended) vs SPAKE2-0.4.0 vs SPAKE2+; + crate/reduction/composition sign-off |
| 7a | Native exporter choice + fold-locally + mixed native↔browser reconciliation + tier-select binding |
| 8a | Formal-methods tool/scope/ownership (see obligations below) |
| 9a | Whether to show a verifier string to both humans (optional, not load-bearing) |

## Formal-model obligations (wire-freeze gate)

The Tamarin/ProVerif model MUST cover, and no wire-freeze until it passes:

1. Pairing handshake: PAKE + §4 DH schedule + TT + confirmation.
2. Reconnect / TOFU path (KK DH) — entity auth requires identity-key **possession** at pairing AND
   reconnect (not key-value agreement).
3. **[FIX 1]** Point-validity: encode `DH(low-order, ·) = 0` and assert §0 rejects it (an algebraic DH
   abstraction misses the cofactor collapse).
4. One-time-code consumption + lockout + single-flight state machine — the one-guess bound under an
   untrusted rendezvous, consuming **only** on a secret-authenticated `PAIR_CONFIRM` **[FIX 8]**.
5. Reflection/UKS resistance **independent** of the confirmation mechanism **[FIX 4]**.
6. **[FIX 3]** Entity-agreement lemma: `PAIR_INIT.ephemeral_key == every post-handshake envelope's
   ephemeral == session_root input`, under a transport-terminating attacker (substitute-ephemeral →
   reject).
7. **[FIX 6]** Reconnect-downgrade resistance: a `possession_proven` contact cannot be forced onto a
   legacy/static path.
8. **[FIX 2]** Legacy-typer-leak: SECRET never appears in any rendezvous-facing message for a
   conforming client.
9. Enumerate the three transport configurations (both-native / both-browser / mixed) as distinct model
   configs; discharge the lemma that identity-DH alone suffices for transport-MITM resistance on the
   browser leg.
10. Record ideal-PAKE / ideal-DH and injective serialization as **ASSUMED PREMISES** (not results);
    carve the computational PAKE⊕Noise composition into a **separate reductionist** sign-off (1a); keep
    the quantitative guess-budget (2a) separate from the symbolic proof.

## Test obligations

- **Golden vectors (cross-impl Rust ↔ WASM, byte-identical):** code normalization; TT codec
  encode→bytes AND decode→struct; `ikm`/`PRK` byte assembly (es/se orientation, ee/ss order, X25519
  endianness); HKDF outputs; confirmation MAC; `session_root` derivation.
- **[FIX 1]** low-order-static + low-order-ephemeral → abort; all-zero-DH → abort.
- **[FIX 2]** legacy-client → malicious-server harness: assert SECRET bytes never appear in any
  rendezvous-facing message; version-container rejected by a legacy parser.
- **[FIX 3]** substitute-envelope-ephemeral-after-PAKE → reject / cryptographic decrypt-fail.
- **[FIX 4]** reflection: `peer_* == own` → reject before key derivation, on both PAKE paths + reconnect.
- **[FIX 5]** CSPRNG-independence KAT: two mocked entropy streams → ROUTING = f(A) only, SECRET = f(B) only.
- **[FIX 6]** reconnect-downgrade / suppress-DH-marker → reject; `possession_proven` non-overridable.
- **[FIX 7]** `KEY_MISMATCH` hostile-abort; human-confirmed rotation path distinct from mismatch;
  `contact_id` uniqueness/collision.
- **[FIX 8]** consumed-value re-entry → reject; unauthenticated probe → code returns to LIVE (no
  consume/backoff); guess counted only on authenticated `PAIR_CONFIRM`; concurrent-N + abandonment.
- Mixed-role golden vector (es_self==se_peer orientation) once 1a fixes the role order.

## Hard boundaries

- **No implementation. No protocol-spec edits. No wire-freeze. No spike merge. No "verified" product
  behavior.** The `bolt-spake2-spike` crate stays inert and unmerged; old "verified" stays disabled
  (EA29).
- Wire-freeze is FORBIDDEN until every `[CRYPTO-DECISION]` resolves, the external cryptographer signs
  off, and the formal model (above, widened) passes. This draft is a design input, not an authorization.

## Next (not authorized here)

Phase 0 (engage the cryptographer) + Phase 1 spec design-freeze *drafting* may proceed against this
v3 draft; wire-freeze is the Phase-1 exit gate. Recommended: a v3 adversarial re-review before
cryptographer handoff (the loop has surfaced a real fixable hole each round — v1: no PoP; v2:
low-order points).
