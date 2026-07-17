# Decision: EA1 PAKE v2 Protocol Profile — Revised Draft

> **Date:** 2026-07-15
> **Status:** **PROPOSED — REVISION REQUIRED. NOT WIRE-FROZEN. NOT
> IMPLEMENTATION-AUTHORIZED. NO "verified" PRODUCT BEHAVIOR.** A v2 adversarial red-team (2026-07-16)
> returned **HAS-BLOCKERS** — see the *Red-team outcome (v2): REVISION REQUIRED* note below and
> `docs/evidence/EA1_PAKE_V2_REDTEAM.md`. Addresses the nine required changes
> from the v1 red-team; supersedes the v1 profile *in the specifics* while keeping the type-a-secret
> PAKE direction. EA1 remains **OPEN**. Contains open items that REQUIRE an external cryptographer —
> marked **[CRYPTO-DECISION]** — and cannot be wire-frozen until they resolve.
> **Scope repos:** `bolt-protocol` (future spec revision), `bolt-core-sdk` (future SDK), products —
> all future, all gated.
> **Supersedes-in-specifics:** `os/log/decisions/2026-07-15-ea1-pake-v1-profile-proposal.md`
> (PROPOSED — REVISION REQUIRED). **Evidence:** `docs/evidence/EA1_PAKE_PROFILE_REDTEAM.md`
> (HAS-BLOCKERS), `docs/evidence/EA1_REDTEAM.md`, `docs/evidence/PAKE_EVAL.md`. **Builds on:**
> `os/log/decisions/2026-07-15-ea1-adopt-pake-direction.md`.

## Red-team outcome (v2): REVISION REQUIRED

A v2 UltraCode adversarial review (2026-07-16) returned **HAS-BLOCKERS**. Full report:
**`docs/evidence/EA1_PAKE_V2_REDTEAM.md`**.

- **This draft is PROPOSED — REVISION REQUIRED. Not wire-frozen, not implementation-authorized.**
- **Direction validated, but blockers remain.** The review confirmed v2 moved all four v1 blockers
  the right way and retracted the three falsified v1 claims, and it correctly deferred 13 items to
  the professional cryptographer — but **7 findings are confirmed** and must be fixed first.
- **Top blocker (new, fixable):** the §1 identity-DH possession proof is defeated by a **low-order /
  small-subgroup X25519 point** — X25519 clamps to a multiple of cofactor 8, so DH against a
  low-order `id_pub` returns the all-zero constant (`ss=es=0`), letting a peer who pairs once get a
  `possession_proven=true` pin on a key nobody owns and then be impersonated by any codeless MITM on
  every reconnect (reopens the v1 reconnect blocker, permanently). The draft mandates **no point /
  all-zero-DH validation** — this is a required normative wire rule (RFC 7748 §6.1), not a deferred
  cryptographer decision.
- **The 8 required changes before wire-freeze** are enumerated in the evidence file: (1) low-order
  point + all-zero-DH abort; (2) structural routing/secret split that does not rely on server
  honesty; (3) `session_root` bound to the authenticated PAKE/DH transcript + the ephemeral-binding
  rider as a §8 model obligation; (4) primitive-independent anti-reflection reject; (5) white-box
  CSPRNG independence for ROUTING/SECRET; (6) reconnect downgrade floor from `possession_proven`
  pins; (7) CSPRNG `contact_id` + key-rotation semantics; (8) typer-side code consumption without
  unauthenticated-lockout DoS. Plus retract the falsified §1/§4/§6/§7 sufficiency claims.
- Old "verified" stays disabled (EA29). Wire-freeze remains FORBIDDEN until these changes land, the
  external cryptographer signs off the 10 deferred `[CRYPTO-DECISION]` items, and the widened formal
  model (§8, extended per the review) passes.

This draft is retained verbatim as the *reviewed v2*; the revision that incorporates the 8 changes is
tracked separately as the v3 draft.

## What this draft is

The v1 proposal was adversarially reviewed and returned **HAS-BLOCKERS** (1 BLOCKER, 3 HIGH,
3 MEDIUM, 3 LOW). This v2 draft rewrites the flawed parts. It changes the *design*, not the wire —
nothing here is frozen and no code is authorized. Its purpose is to be the input the external
cryptographer and the formal model work against. The type-a-secret PAKE pivot is kept; the way it is
*specified* is corrected.

### Retracted v1 claims (superseded here)

The v1 profile asserted guarantees the red-team falsified. They are **retracted**; v2 replaces the
mechanism behind each:

- v1 "Closes the downgrade blocker + EA16 + EA-D2" (under *Transcript TT*) — **false at first
  contact.** Replaced by the ceremony-bound floor (§3).
- v1 "the PAKE supplies the authentication a PoP signature would have" (under *Identity and typed
  pins*) — **false; the identity private key was never exercised.** Replaced by the identity-DH key
  schedule (§1).
- v1 reconnect "authenticates that key via the envelope MAC" — **false; the envelope MAC is keyed by
  the ephemeral, proving nothing about the identity private key.** Replaced by the reconnect
  static-DH rule (§1).

---

## §1 — Identity proof-of-possession + reconnect rule (THE BLOCKER)

**Problem (v1):** the X25519 identity key was committed in the transcript and pinned, but its
*private* key was never used. Confirmation proved SECRET-knowledge (pairing) or ephemeral possession
(reconnect), never identity ownership. On reconnect (no fresh PAKE) an active rendezvous MITM
impersonated any pinned peer from the *public* key alone at zero online guesses.

**v2 design — a Noise-style DH key schedule that proves private-key possession, at pairing AND
reconnect.** Keep X25519 identity keys (ADR-locked; X25519 is ECDH-capable, so it can prove
possession via DH without a signature). The confirmed key is derived from a mix of Diffie-Hellman
outputs, not from the PAKE secret alone:

```
ee = X25519(eph_priv_self,  eph_pub_peer)   // ephemeral–ephemeral   → forward secrecy
es = X25519(eph_priv_self,  id_pub_peer)    // ephemeral–static      → bind + KCI
se = X25519(id_priv_self,   eph_pub_peer)   // static–ephemeral      → bind + KCI
ss = X25519(id_priv_self,   id_pub_peer)    // static–static         → MUTUAL identity possession
```

- **Pairing (first contact, no pins):**
  `ikm = k_pake ‖ ee ‖ es ‖ se ‖ ss`, then `PRK = HKDF-Extract(salt = TT, ikm)`.
  The PAKE authenticates *the code*; `ss`/`es`/`se` prove *each side holds its identity private
  key*. The confirmation MAC (§ key-confirmation) succeeds only if both the same SECRET was used AND
  each side possesses its identity private key. The pin recorded is therefore a **proven-possessed**
  identity, not a bare committed public key.
- **Reconnect (pins exist, no code):**
  `ikm = ee ‖ es ‖ se ‖ ss` (no `k_pake` — there is no code). This is a Noise-KK-shaped mutual
  authenticated DH over the *pinned* static keys plus fresh ephemerals. A MITM holding only the
  public identity keys cannot compute `ss = a_priv·b_priv·G` (CDH), so it cannot forge the
  confirmation. **Reconnect authentication no longer relies on a public-key match — it requires a
  static-static (+ ephemeral-static) DH that only the private-key holders can produce.** This
  directly closes the reconnect BLOCKER.

**Reconnect rule (normative intent):** a reconnect is authenticated ONLY by a successful
static+ephemeral DH confirmation against a `possession_proven` pin. A matching public identity key
with an ephemeral-keyed envelope MAC is **not** sufficient and MUST NOT grant transfer.

- **[CRYPTO-DECISION 1a]** Adopt a *named, analyzed* Noise pattern rather than a bespoke mix:
  reconnect ≈ Noise **KK** (both static keys pre-known); pairing ≈ Noise **XX**/**IK** with the PAKE
  output mixed in as a PSK-like input (Noise `…psk` family). The cryptographer ratifies the exact
  pattern, the DH set and mixing order, and the **PAKE ⊕ Noise composition** (this composition is
  the subtle part).
- **[CRYPTO-DECISION 1b]** KCI scope: confirm `es`/`se` give the intended key-compromise-impersonation
  resistance for this threat model, and whether identity-key rotation needs a signed cross-cert
  (probably not, given DH possession).
- **[CRYPTO-DECISION 1c]** Reconnect cadence (resolves v1 Unresolved #2): is per-reconnect
  static-DH sufficient indefinitely, or should a fresh-code PAKE be forced on some schedule / on any
  observed key change? Recommendation: static-DH per reconnect is sufficient for authentication;
  a fresh code is required only to (re)establish or rotate a pin. Cryptographer confirms.

---

## §2 — One-time code consumption / single-flight / lockout

**Problem (v1):** "one online guess per session" was not enforced — order-free confirmation exposed
a MAC oracle; the only consume trigger was "on mismatch" (harvest-then-drop kept the code live); no
atomic single-flight (N parallel PAIR_INITs = N guesses); and the bound leaned on the *untrusted*
rendezvous's rate-limiting.

**v2 design — the one-guess bound rests SOLELY on endpoint-local state, enforced at both peers.**

1. **Receiver-confirms-last (asymmetric confirmation):** break the symmetric confirmation. The
   code-**typing** peer sends its `PAIR_CONFIRM` first; the code-**showing** peer verifies it and
   only then discloses its own confirmation value. An attacker probing the shower must produce a
   valid confirmation *first* (which requires the SECRET), so it cannot harvest the shower's MAC as a
   free offline oracle.
2. **Endpoint code state machine** (local, at both peers): `LIVE → IN_FLIGHT → CONSUMED`.
   - First inbound `PAIR_INIT` for a displayed code: atomic CAS `LIVE → IN_FLIGHT`.
   - Any further `PAIR_INIT` for that code while `IN_FLIGHT`/`CONSUMED`: **reject** (`PAIR_IN_FLIGHT`
     / `PAIR_CODE_CONSUMED`) — **per-code single-flight, reject not queue** (kills the parallel-N
     TOCTOU).
   - The code is consumed (`IN_FLIGHT → CONSUMED`) on **any** terminal outcome — success, MAC
     failure, drop, OR timeout — **not only on mismatch.** One attempt burns the code.
3. **Lockout:** after a `CONSUMED`-via-failure, impose a cooldown with exponential backoff before a
   *new* code for that peer/mailbox may be issued, throttling serial guessing across regenerated
   codes. A new pairing after consumption requires the human to display a **fresh** code.
4. **Rendezvous rate-limiting is reclassified as non-load-bearing** (untrusted, SECRET-blind — it
   sees only ROUTING). The bound is: **one online guess per displayed code; the code dies after one
   attempt; a fresh human-displayed code + lockout gate any retry.** With a ~40-bit SECRET this makes
   online guessing hopeless.

- **[CRYPTO-DECISION 2a]** Exact lockout parameters (cooldown, backoff curve, attempts-before-long-lockout).
- **[CRYPTO-DECISION 2b]** Consume trigger timing: recommend consume at `LIVE → IN_FLIGHT` (the
  moment the code is committed to a session), i.e. before any MAC is computed, so even an abandoned
  probe burns the code. Cryptographer confirms this vs consume-at-oracle-exposure.

---

## §3 — Unstrippable downgrade floor

**Problem (v1):** the floor was off-by-default and conditioned on a pin/require-PAKE config that does
not exist at first contact; the PAKE-vs-legacy choice ran on the *unauthenticated pre-PAKE* capability
advertisement, so an on-path MITM stripped `bolt.pake-v1` on both legs and forced two PAKE-capable
peers onto the legacy path.

**v2 design — bind the floor to the out-of-band human code ceremony, which the MITM cannot touch.**

- **Showing a pake-v1 code ⇒ that pairing MUST complete via PAIR_INIT/PAIR_CONFIRM.** The shower
  refuses any legacy/HELLO-only completion for that ceremony (`PAIR_REQUIRED`). The human's act of
  starting a code ceremony is the trust anchor — it is local and unstrippable.
- **Typing a pake-format code ⇒ the typer refuses legacy fallback for that attempt.**
- **An unstrippable PAKE-capable marker is folded into the code/QR itself** (a version tag the typer
  reads locally). The typer therefore knows the shower is PAKE-capable regardless of what the
  attacker-controlled rendezvous caps claim. An attacker cannot strip a signal carried in the
  human-transported code.
- **Default require-PAKE ON** for the code ceremony. Legacy is reachable only via an explicit,
  pre-designated, per-device "receive from an old device" mode (a deliberate human choice, never a
  silent fallback).
- **Remove pre-`HANDSHAKE_COMPLETE` acceptance of a bare legacy HELLO while a code ceremony is
  active.**
- Capabilities/version remain bound in TT (defense-in-depth against post-ceremony tampering), but the
  *mode-select* no longer depends on them.

This covers first contact (the v1 gap). The v1 line-89 closure claim is retracted (see above) and
re-earned by this mechanism.

- **[CRYPTO-DECISION 3a]** The code-embedded capability marker format (bits in the code vs a QR
  field) and its interaction with the routing/secret grammar (§4).

---

## §4 — Structural routing/secret split

**Problem (v1):** the `ROUTING-SECRET` boundary was client-behavioral (one shared alphabet, positional
split). A legacy/downgraded initiator could submit the whole `ROUTING+SECRET` string as the mailbox
id, handing SECRET to the untrusted rendezvous → deterministic zero-guess MITM.

**v2 design — make the boundary STRUCTURAL so the server cannot receive SECRET.**

- **Disjoint grammar:** ROUTING and SECRET draw from distinguishable structures — either disjoint
  alphabets, or a typed, checksummed routing prefix that is self-describing. The rendezvous can
  structurally tell them apart.
- **Rendezvous MUST reject any mailbox id that is not valid ROUTING grammar/length.** A client that
  submits `ROUTING+SECRET` as the id is rejected — the server can never process SECRET as a routing
  token, even if a buggy/downgraded client tries.
- **ROUTING and SECRET are independently CSPRNG-sampled.** Deriving either from the other, or both
  from a shared reachable seed, is FORBIDDEN (a shared seed lets a passive server bucket the SECRET
  space offline). Enforced by a golden-vector-grade statistical/property test.
- **Client validates the extracted ROUTING locally BEFORE contacting the rendezvous** and fails
  locally on malformed input (a one-char under-type must fail locally, never bleed a SECRET char to
  the server).
- **SECRET is not displayed until pake-v1 capability is committed** for the ceremony.

- **[CRYPTO-DECISION 4a]** ROUTING grammar (disjoint alphabet vs typed/checksummed prefix), ROUTING
  length vs mailbox-collision needs in a LAN room, and the SECRET entropy/MHF choice (v1 assumed
  ~40 bits, MHF=none — revisit under the chosen PAKE).

---

## §5 — Injective transcript codec

**Problem (v1):** "strip a cap → TT differs → MAC fails" was not guaranteed. Caps had no per-element
framing, `sort_pair` length-prefixed only `routing_id`, and canonicalization was encode-only — so two
honest mixed impls (TS/WASM web vs Rust daemon) could hash identical bytes yet *decode* different
capability sets (an envelope/plaintext split-brain), or two logical transcripts could collide.

**v2 design — one canonical, provably INJECTIVE binary codec with strict canonical decode.**

- Fixed-width big-endian length prefix on **every** variable-length field (pake_msg, each identity
  key, each ephemeral key, each capability string, channel_binding).
- `capabilities[]`: **count prefix + per-element length prefix** (no `{X,Y}` vs `{XY}` ambiguity).
- **Length-prefix each `PAIR_INIT` blob inside `sort_pair`** (the two blobs cannot merge ambiguously).
- Presence flag + length for every optional field.
- **No trailing bytes at any nesting level;** fixed ASCII grammar for cap-names / version.
- **Strict canonical DECODE:** reject non-minimal or ambiguous encodings; reject length prefixes that
  do not match; reject non-canonical capability order.
- **Single source of truth:** the *exact bytes* bound into TT are the exact bytes consumed by the
  require-PAKE floor check and by `negotiate_capabilities` — no re-derivation, no separate decode path
  → no split-brain. Caps are order-canonicalized (sorted) but otherwise byte-exact (NO dedup/case/
  whitespace folding that could mask an edit).
- **Golden vectors in BOTH directions** (encode→bytes AND decode→struct), plus mixed TS-encode/
  Rust-decode round-trips, plus duplicate-cap / case-mutation → *failure* adversarial vectors.
- Strengthen the PROTOCOL.md canonical rule from "equivalent inputs → same bytes" to also **"distinct
  field-structures → distinct bytes"** (injectivity).

Injectivity is an explicit assertion the formal model (§8) must discharge.

- **[CRYPTO-DECISION 5a]** Final byte layout freeze happens only after the formal injectivity check
  and cryptographer review.

---

## §6 — PAKE primitive: SPAKE2 vs CPace vs SPAKE2+

**Problem (v1):** symmetric SPAKE2's reflection/UKS mitigation was bespoke (side_id + complement-key)
and unratified; the crate is unaudited, not constant-time, and non-RFC-9382; the balanced reduction
was not scoped into the sign-off.

**v2 — this is an explicit [CRYPTO-DECISION 6], not a foregone choice.** Options for the cryptographer:

| Option | For | Against |
|---|---|---|
| **SPAKE2** (RustCrypto `0.4.0`, symmetric) — the v1/eval choice | one maintained Rust+WASM crate already in-tree (PAKE_EVAL); spike proved wasm build + entropy path | unaudited, not constant-time, non-RFC-9382; **symmetric-mode reflection/UKS is the bespoke, subtle part**; balanced Kobara-Imai reduction, not the cleaner asymmetric proof |
| **CPace** (CFRG-selected balanced PAKE) | standards-track; **designed for the balanced 2-party setting**, sidesteps the symmetric-SPAKE2 reflection subtlety; cleaner security story | must verify a maintained Rust **+ WASM** crate exists and builds in this toolchain (the PAKE_EVAL gate) |
| **SPAKE2+** (augmented) | verifier-based | asymmetric/server-verifier shape — wrong fit for a symmetric device-to-device pairing where neither side is a server |

**Recommendation to put to the cryptographer:** treat **CPace as the primary candidate** (CFRG chose
it for exactly this balanced setting) and keep **SPAKE2-0.4.0 as fallback** if no maintained Rust+WASM
CPace clears the PAKE_EVAL bar. Because the §1 identity-DH schedule now wraps the PAKE (the PAKE only
supplies the password-authenticated secret mixed into `ikm`), swapping SPAKE2 ↔ CPace is **modular** —
it changes the `k_pake` producer and the PAKE wire messages, not the surrounding schedule. This
de-risks the decision but it is still **wire-affecting: primitive-dependent sections stay UNFROZEN
until [CRYPTO-DECISION 6] resolves.**

If SPAKE2 is retained: pin the complement-key confirmation MUSTs, the reject-`side_id==own` tripwire,
and an early reflection reject (`peer_pake_msg == own outbound` → reject before key derivation), and
scope the balanced reduction + non-RFC transcript + composition with the external HKDF/HMAC into the
sign-off.

---

## §7 — Channel binding position

**Problem (v1):** `channel_binding` was a *transmitted* per-side field symmetrized by `sort_pair`, so
both peers hashed the same unordered pair under a verbatim-relay MITM → **zero** transport-MITM
detection. It was also optional, and browsers expose no (D)TLS exporter.

**v2 design — fold a LOCALLY-OBSERVED transport secret; never transmit-and-symmetrize.**

- **Each endpoint folds its own locally-observed transport binding value into a COMMON key-schedule
  slot** (the same position on both sides). If a MITM terminates the transport (distinct TLS/QUIC
  sessions per leg), the two locally-observed values differ → derived keys/confirmation differ → MAC
  fails. (Equivalently: an explicit fail-closed "peer-claimed == locally-observed" check *outside* the
  symmetric transcript. Folding-locally is preferred — no reveal.)
- **Require-binding floor on native transports that CAN export** (WS/WT/QUIC via rustls RFC-5705 /
  QUIC exporters). Mandatory there.
- **Browsers:** state plainly they expose **no** (D)TLS exporter; the only readable value is the
  rendezvous-relayed cert-hash, i.e. EA13's own attacker input, and is **not** a trust anchor. Browser
  transport-MITM is instead closed by **identity-key TOFU on the PAKE-bound ephemeral** (§1): the PAKE
  + identity-DH authenticate the peer end-to-end regardless of transport, so a transport MITM that
  cannot complete the PAKE/identity-DH is caught anyway. Channel binding is defense-in-depth on
  native, not the primary control.
- **Load-bearing rider:** MANDATE and VERIFY that `PAIR_INIT.ephemeral_key` equals the ephemeral that
  actually keys the envelope / BTR `session_root`. Otherwise a transport-terminating MITM could bind
  one ephemeral in TT but key the real data channel with another → latent silent content-MITM.

- **[CRYPTO-DECISION 7a]** Exact exporter per native transport (rustls RFC-5705 label; QUIC exporter);
  ratify the fold-locally construction and the browser "no exporter, rely on identity-PoP" argument.

---

## §8 — Formal model scope

**Problem (v1):** the mandatory model was scoped to the "commit/transcript/confirm byte layout" — it
would have missed both the reconnect BLOCKER and the guess-harvesting HIGH.

**v2 design — the Tamarin/ProVerif model (a wire-freeze GATE) MUST cover:**

1. The pairing handshake: PAKE + the §1 DH schedule + transcript + confirmation.
2. **The reconnect / TOFU-continuity path** (Noise-KK-shaped static+ephemeral DH) — asserting entity
   authentication requires identity-key **possession** (not key-value agreement) at pairing AND
   reconnect.
3. **The endpoint one-time-code consumption + lockout + single-flight state machine** — asserting the
   one-online-guess bound under a Dolev-Yao / untrusted-rendezvous attacker (consume-on-attempt,
   reject-not-queue).
4. Reflection/UKS resistance from the password-keyed, complement-verified confirmation.
5. **TT injectivity** (distinct structures → distinct bytes), and downgrade resistance under the
   §3 human-ceremony floor.

**No wire-freeze until this widened model passes.**

- **[CRYPTO-DECISION 8a]** Tool choice (Tamarin vs ProVerif), abstraction level, and who runs it
  (external cryptographer + formal-methods engineer).

---

## §9 — Corrected pin model + honest product states

**Problem (v1):** keying the pin store by `identity_key` made `KEY_MISMATCH` unreachable (hit or
first-contact-miss, never "mismatch"); and one-sided entry produced an over-strong "verified" bond +
persistent pin from a phished code.

### Pin model

- **Key the store by a stable, locally-assigned contact handle** — a random `contact_id` minted at
  first successful pairing (or the user's chosen device label). NOT the rendezvous code (fixes EA5),
  NOT solely the identity key (keeps `KEY_MISMATCH` reachable).
- **`PinRecord v2`:**
  ```
  { pin_format: 2, contact_id (KEY), identity_key: [32]u8 (COMPARED value),
    pake_profile, bound_via: "pake-v1" | "reconnect-dh", possession_proven: bool,
    first_paired_at, transcript_hash?, device_label }
  ```
  `possession_proven` is set only when the §1 DH schedule proved the identity private key; a pin is
  trusted for reconnect auth only when it is `true`.
- **Reconnect:** resolve by `contact_id`; require the §1 static+ephemeral DH confirmation. If the
  presented `identity_key` ≠ the pinned compared value for that handle → `KEY_MISMATCH` hard-abort +
  explicit re-pair (a fresh PAKE). The tripwire is now reachable.
- **Migration:** transactional (bump `DB_VERSION`); old v1 code-keyed pins are **ignored for trust**
  (EA29 posture), optionally kept as weak "seen-before" hints and upgraded on next PAKE pairing; v1/v2
  are byte-distinguishable via `pin_format`. No mass reset.

### Honest product states (respecting "No 'verified' product behavior")

The v1 `verified` label over-claimed what a one-sided PAKE proves (a phished code drives the honest
success path). v2 uses **honest authorization/continuity language and introduces NO product-facing
"verified" state.** None of these ship until EA1 passes its gates.

| State | Meaning | Transfer? |
|---|---|---|
| `unverified` | Connected; no PAKE, no reconnect-auth. | No (block-default) |
| `approved_for_session` | Human authorized this session only; no pin. | This session only |
| `code_confirmed` | PAKE + identity-DH succeeded, proving **same code + private-key possession** — but one-sided entry proves "the peer used this code," NOT "this is the person/device I intended." Honest label; a persistent pin is written only with explicit **"remember this device"** consent. | Yes (labeled honestly) |
| `reconnect_authenticated` | Reconnect to a `possession_proven` pin succeeded via the static+ephemeral DH. Honest continuity. | Yes |
| `pake_failed` / `key_mismatch` | Hostile; fail-closed; no pin; code consumed/locked. | No |
| `legacy` | Policy-gated authorization (explicit old-device mode); **never** "verified." | Policy-gated |

- A true, product-facing **"verified"** claim (mutual, out-of-band-checked identity) remains **future
  work** requiring an out-of-band identity check beyond a one-sided code; it is out of scope here and
  stays disabled (EA29).
- **Initiator consent:** the UI states "you are connecting to a device that used this code" — not
  "verified/trusted device" — and gates persistent pins behind an explicit opt-in.
- Enforce the transfer gate on the **receive path** in the SDK, not UI-visibility-only (EA14).
- The internal canonical enum currently named `Verified` should be **renamed to honest semantics**
  (was deferred in v1; finding #5 + this constraint make it a real item, though a naming task, not
  wire).
- **Anti-phishing UX:** render SECRET as visibly sensitive ("type only into LocalBolt, never share");
  no single off-app full-code copy/share affordance.
- **[CRYPTO-DECISION 9a]** Whether to show a verifier string to both humans as a wrong-device
  cross-check (v1 Unresolved #5). Recommendation: optional both-sides display, not the mechanism.

---

## Consolidated unresolved cryptographer decisions

| Tag | Decision |
|---|---|
| 1a | Named Noise pattern (KK reconnect / XX·IK+PSK pairing) + DH set/order + **PAKE ⊕ Noise composition** |
| 1b | KCI scope of `es`/`se`; identity-key rotation handling |
| 1c | Reconnect cadence — static-DH-per-reconnect vs forced fresh-code schedule |
| 2a/2b | Lockout parameters; consume-trigger timing (recommend consume at `LIVE → IN_FLIGHT`) |
| 3a | Code-embedded PAKE-capable marker format |
| 4a | ROUTING grammar (disjoint alphabet vs typed prefix); SECRET entropy/MHF |
| 5a | Final injective byte-layout freeze (post formal check) |
| 6 | **PAKE primitive: CPace (recommended primary) vs SPAKE2-0.4.0 (fallback) vs SPAKE2+** — wire-affecting |
| 7a | Native-transport exporter choice; ratify fold-locally + browser no-exporter argument |
| 8a | Formal-methods tool + scope sign-off + who runs it |
| 9a | Show a verifier string or not |
| — | File the `spake2 0.4.0` (or CPace) unaudited / not-constant-time / no-zeroization HIGH sign-off (v1 Unresolved #4) |

## Hard boundaries (unchanged)

- **No implementation. No spec wire-freeze. No spike merge. No "verified" product behavior.**
- The `bolt-spake2-spike` crate stays inert and unmerged; old "verified" stays disabled (EA29) until
  EA1 ships and passes its gates.
- This draft is a design input; wire-freeze is FORBIDDEN until every **[CRYPTO-DECISION]** resolves,
  the external cryptographer signs off, and the widened formal model (§8) passes.

## What's next (not authorized here)

Phase 0 (engage the cryptographer) + Phase 1 spec design-freeze *drafting* may proceed against this
draft; wire-freeze is the Phase-1 exit gate, not its entry. Implementation stays gated behind the
resolved decisions, the sign-off, and the formal model.
