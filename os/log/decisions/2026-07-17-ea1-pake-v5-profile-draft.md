# Decision: EA1 PAKE v5 Protocol Profile — Revised Draft

> **Date:** 2026-07-17
> **Status:** **DRAFT — PROPOSED. NOT WIRE-FROZEN. NOT IMPLEMENTATION-AUTHORIZED. NO "verified"
> PRODUCT BEHAVIOR.** Incorporates the ten required edits from the v4 adversarial red-team
> (`docs/evidence/EA1_PAKE_V4_REDTEAM.md`, verdict NEEDS-REVISION — no blocker) and adopts **§6 fork
> A**: EA1 requires a future protocol-spec change so post-handshake data/BTR keys derive from the
> authenticated `session_root`, not bare `ee`. Supersedes-in-specifics the v4 draft
> (`os/log/decisions/2026-07-17-ea1-pake-v4-profile-draft.md`, PROPOSED — NEEDS REVISION), retained
> verbatim. EA1 remains **OPEN**. Contains open items that REQUIRE an external cryptographer — marked
> **[CRYPTO-DECISION]** — and a **required future `PROTOCOL.md` delta** (below); it cannot be
> wire-frozen until those resolve.
> **Scope repos:** `bolt-protocol` (future spec — see the required delta), `bolt-core-sdk` (future
> SDK), products — all future, all gated.
> **Lineage:** direction ADR → v1 → v2 → v3 → v4 (all superseded-in-specifics) → **this v5 draft.**
> Evidence: `docs/evidence/EA1_REDTEAM.md`, `docs/evidence/PAKE_EVAL.md`,
> `docs/evidence/EA1_PAKE_PROFILE_REDTEAM.md`, `docs/evidence/EA1_PAKE_V2_REDTEAM.md`,
> `docs/evidence/EA1_PAKE_V3_REDTEAM.md`, `docs/evidence/EA1_PAKE_V4_REDTEAM.md`.

## What v5 changes

v5 adopts **§6 fork A** (the v4 review's blocking-HIGH decision) and lands the v4 review's ten required
edits. Each is tagged **[FIX n]**. The headline is a deliberate change to the *future* EA1 wire
schedule — see the **Required future `PROTOCOL.md` delta** section.

| # | Area | v5 change |
|---|------|-----------|
| A | §6 data-key root | **Fork A:** post-handshake data/BTR keys derive from the authenticated `session_root = HKDF(salt = PRK, ikm = ephemeral_shared_secret, info = TT/domain labels)`, not bare `ee`. Requires a future `PROTOCOL.md` delta (below). |
| 1 | §9 KEY_MISMATCH | Split by initiator: locally-initiated mismatch = hostile alert; unauthenticated inbound resolve-then-differ = silent, rate-limited discard (no alert, no pin mutation). |
| 2 | §9 FIX-8/FIX-9 | Reconciled: `reconnect_handle` cannot summon alerts; rotation stays CD1b/cross-cert-gated; no human-confirm-only overwrite. |
| 3 | §8 code-burning | Re-characterized honestly (a learned ROUTING can deny pairing availability); not "acceptable"; budget → CD2a; MUST-NOT device penalty from consumed-code count. |
| 4 | formal model | Byte-layer / non-canonical rejection removed from the symbolic model → wire tests + codec proofs. |
| 5 | §0 citation | RFC 7748 = the all-zero-DH abort; the small-order blacklist is implementation-derived. |
| 6 | §6 reconnect chain | Confidentiality chain stated for both pairing and reconnect. |
| 7 | §1 SECRET-off-server | Narrowed to a conforming-reference-client property enforced by the split API + byte-scan harness. |
| 8 | §5 L/R basis | Pinned unsigned byte-wise (+ ≥0x80 vector), or deferred to CD1a wire-role assignment. |
| 9 | test | Sort-discriminating es/se vectors (a sorting impl MUST fail). |
| 10 | §9 reconnect_handle | Invariants pinned (CSPRNG-minted, not peer-choosable) + explicit linkability risk → CD1c. |

### Claims retracted/corrected across the lineage

- v1 lines 89/150/164 + "Closes … EA16" — retracted (v2).
- v2 §1/§4/§6/§7/§9 overclaims — retracted (v3).
- v3 §8/§6/§1/§4/§9 overclaims — retracted (v4).
- **v4 §6 "the honest endpoints key the data channel with `session_root`" + browser "secret PRK salt"**
  — were *false for the old ee-rooted wire*; v5 makes them **true by intentional design** via fork A +
  the required `PROTOCOL.md` delta (no longer a false claim — a declared future wire change).
- v4 §9 attacker-summonable `KEY_MISMATCH` — corrected **[FIX 1]**.
- v4 §8 "acceptable" DoS — corrected **[FIX 3]**.
- v4 §0 RFC 7748 miscitation — corrected **[FIX 5]**.
- v4 formal obligation #3 byte-layer clause — corrected **[FIX 4]**.

---

## Required future `PROTOCOL.md` delta (fork A — NOT applied in this gate)

**This gate does not edit `PROTOCOL.md`.** This section states the wire change EA1 requires; it is
applied only in a future, separately-authorized spec gate.

- **Current wire (unchanged here):** `PROTOCOL.md` keys the post-handshake data channel from `ee`
  alone — non-BTR direct-ee (§PROTOCOL L197/L1441) and BTR §16.3 with `salt = EMPTY` over
  `ephemeral_shared_secret`; BTR-INV-01 roots the ratchet on the ephemeral shared secret.
- **Proposed EA1 wire (fork A):** post-handshake data/BTR keys MUST derive from
  `session_root = HKDF(salt = PRK, ikm = ephemeral_shared_secret, info = TT/domain labels)`. Concrete
  future deltas:
  1. **BTR root (§16.3):** replace `salt = EMPTY` with `session_root` (the BTR root key becomes a
     function of `session_root`, not bare `ee`); restate **BTR-INV-01** to root on `session_root`.
  2. **Non-BTR direct AEAD:** key from `session_root`, not bare `ee`.
  3. **Naming:** resolve the `session_root` / `session_root_key` / `K_session` collision → one
     authoritative name for the data-channel root.
- **Why:** it makes §6's confidentiality property *actually load-bearing on the wire* (the v4 review's
  HIGH was that v5's predecessor computed `session_root` but the wire ignored it), and adds a **PRK-salt
  backstop against `ee`-recovery** — a later ephemeral compromise does not by itself expose data, since
  the data root also depends on `PRK` (which requires SECRET + the identity/ephemeral privates).
- **Review scope:** the external cryptographer / formal model MUST review the **proposed EA1 schedule**
  (`session_root`-rooted), **not** the old `ee`-rooted wire. Formal obligation #6 asserts the data AEAD
  key is a function of `session_root`.
- **Change-control:** this is a breaking protocol change → major SDK version bump; gated on the
  cryptographer sign-off, the formal model, and an explicit future authorization to edit `PROTOCOL.md`.
  Until then it is a *proposed* schedule only.

---

## §0 — Key validity (normative) ([FIX 5])

- **Reject known small-order Curve25519 u-coordinates** on every received `identity_key` /
  `ephemeral_key` before any DH. **[FIX 5]** This small-order set is **implementation-derived**
  (libsodium `has_small_order` / curve25519-dalek), pinned under `[CRYPTO-DECISION 6]` — it is **not**
  a table from RFC 7748 §6.1. (An explicit value list may be restored inline for traceability.)
- **Reject non-canonical encodings at ingress:** u with the high (255th) bit set, or u ≥ p.
- **Abort on all-zero DH output** (constant-time) after every X25519 — `ee` (= `ephemeral_shared_secret`,
  §6), `es`, `se`, `ss`. **[FIX 5]** This all-zero/contributory-behaviour abort is the RFC 7748
  (§6.1/§7) guidance and is the self-sufficient security backstop against low-order inputs (a clamped
  scalar is a multiple of cofactor 8, so any low-order point → identity → all-zero).
- **Scope:** identity + ephemeral keys, pairing + reconnect. A failing key is never used, pinned, or
  set `possession_proven`; pinned keys are re-validated before every reconnect DH.

---

## §1 — Human-code UX + routing/secret ([FIX 7])

- One-sided entry; ROUTING and SECRET handled as **two separate API inputs** — ROUTING is the only
  value the signaling/mailbox API accepts; SECRET goes only to a dedicated PAKE-password input that is
  not a parameter of any rendezvous-facing call. A single displayed code is split **locally** into the
  two inputs before any network I/O.
- **[FIX 7] SECRET-off-server is a *conforming-reference-client* property**, enforced by the split API
  **and a mandatory runtime byte-scan conformance harness**. It is **not** a guarantee over
  arbitrary/forked/manual clients — those are un-testable and explicitly out of scope. The "signaling
  API type-level cannot carry SECRET" clause is complementary variable-confusion protection only, **not**
  a byte guarantee. The harness runs across the conforming reference clients (Rust/WASM/TS), both
  delivery modes, including a mis-split / separator-fold fuzz vector.
- CSPRNG independence (v4 [FIX 7]): two separate CSPRNG reads; differential KAT + a negative shared-seed
  reference that MUST fail. ROUTING length/format constant, independent of SECRET.
- Alphabet/entropy + ROUTING grammar/anti-bleed/MHF → `[CRYPTO-DECISION 4a]`.

---

## §2–§3 — Message sequence + transcript TT

As v4: symmetric `PAIR_INIT` (`side_id`, `pake_msg`, `identity_key`, `ephemeral_key`, `bolt_version`,
`capabilities[]`) then `PAIR_CONFIRM`; `TT` = the canonical injective encoding of both PAIR_INITs
(byte-layout freeze via a verified codec, `[CRYPTO-DECISION 5a]`). §0 validation runs on every received
public key before any use.

---

## §4 — PAKE + identity-DH key schedule

**Pairing:** `ikm = k_pake ‖ ee ‖ es ‖ se ‖ ss`, `PRK = HKDF-Extract(salt = TT, ikm)`.
**Reconnect:** `ikm = ee ‖ es ‖ se ‖ ss` (no `k_pake`). Every DH is §0-validated (canonical + all-zero
abort). Anti-reflection is **joint** (equality reject over canonical encodings + TT identity binding +
the mandatory LOAD-BEARING direction-separated confirmation, §5). Noise pattern / es-se role
convergence / composition → `[CRYPTO-DECISION 1a]`; PAKE primitive → `[CRYPTO-DECISION 6]`.

---

## §5 — Key confirmation (direction-separated, LOAD-BEARING) ([FIX 8])

`PRK` → HKDF-Expand → `K_conf_L`, `K_conf_R`, `K_session`, optional `SAS_disp`. Each side sends its
role's MAC and verifies the peer's under the **complement** role key — this is a **MUST-NOT** on
try-both (the FIX-5 negative obligation shows a reflection completes if the confirmation is made
symmetric). Receiver-confirms-last.

- **[FIX 8] Role L/R basis is pinned:** L/R = owner of the lexicographically-smaller `side_id`, compared
  **unsigned byte-wise** over the canonical §0/CD5a `side_id` encoding, **fail-closed on tie**. (A
  signed-byte native port ordering a first-differing byte ≥0x80 opposite Rust's `[u8]` would flip L/R
  and fail honest mixed pairings closed — so the basis MUST be unsigned.) Add a mixed Rust↔WASM
  role-assignment golden vector including a first-differing-byte ≥0x80 `side_id` pair. **Alternative
  (cleaner, per CD1a "never sort"):** assign L/R from the deterministic wire role (shower/typer or
  initiator/responder) and drop the `side_id` sort — deferred to `[CRYPTO-DECISION 1a]`.

---

## §6 — Session root binding (FORK A) ([FIX 6])

- **`ephemeral_shared_secret := ee := X25519(own PAIR_INIT ephemeral private, peer PAIR_INIT ephemeral
  public)`** (v4 [FIX 3]); exactly one session ephemeral per side = the PAIR_INIT ephemeral (never a
  transport/DTLS/QUIC ephemeral); well-typed binding: `PAIR_INIT.ephemeral_key` MUST be the public key
  whose private half computes `ee` and MUST equal the `sender_ephemeral_key` of every post-handshake
  envelope, fail-closed before `HANDSHAKE_COMPLETE`.
- **[FORK A] `session_root = HKDF(salt = PRK, ikm = ephemeral_shared_secret, info = "bolt-pake-v5
  session-root" ‖ TT/domain labels)`.** `salt` MUST be `PRK` (the secret handshake key). TT/domain
  separation lives in `info`. **Post-handshake data/BTR keys derive from `session_root`** (the required
  `PROTOCOL.md` delta above) — `session_root` is now the *actual* data-channel root, not a
  computed-but-unused value.
- **[FIX 6] Confidentiality chain (both paths), an explicit obligation:**
  - **Pairing:** a relaying MITM lacks SECRET ⇒ no `k_pake` ⇒ no `PRK` ⇒ no `session_root` ⇒ cannot key
    or read the data channel.
  - **Reconnect:** a MITM lacks the identity/ephemeral private keys ⇒ cannot compute `es`/`se`/`ss` ⇒
    no `PRK` ⇒ no `session_root`; §9 `KEY_MISMATCH` catches identity substitution **before any data
    envelope**.
  Under fork A this is load-bearing on the wire (not vacuous), and the PRK salt backstops `ee`-recovery.
- **Channel binding:** native transports that can export fold a locally-observed exporter (require-binding
  floor); browsers have no exporter — their transport-MITM resistance now comes from the `session_root`
  (secret PRK salt, fork A) + identity-DH, which is genuine because the data actually keys from
  `session_root`. Exporter + mixed native↔browser reconciliation (non-forceable tier-select in
  `capabilities[]`/TT) → `[CRYPTO-DECISION 7a]`.

---

## §7 — Downgrade floor: pairing + reconnect

As v4: pairing floor bound to the human code ceremony + an unstrippable PAKE-capable marker, default
require-PAKE ON, bare-legacy-HELLO rejected during a ceremony. Reconnect: a `possession_proven` pin
makes identity-DH reconnect mandatory and non-overridable on both peers; legacy / BTR→static downgrade
forbidden for a `possession_proven` contact, fail-closed; floor enforced from the authenticated
identity-DH result, not MITM-mutable HELLO caps.

---

## §8 — One-time code consumption ([FIX 3])

- **One-guess bound (per displayed code):** an inbound `PAIR_CONFIRM` that fails verification consumes
  the single currently-displayed code; the shower prompts a fresh code.
- **Single-flight:** one IN_FLIGHT pairing per displayed code; an incomplete exchange returns the slot
  to LIVE without consuming.
- **Device-wide backoff is LOCAL-ONLY** (v4 [FIX 1]): escalates only from the typer's own
  locally-initiated, value-keyed attempts; **never** from anonymous inbound. **[FIX 3] MUST-NOT:** no
  device-wide penalty may escalate from the consumed-code **count** (closes a re-entry vector for the
  v3 device-lockout via a "too many failed pairings" heuristic).
- **[FIX 3] Availability DoS — stated honestly, NOT "acceptable":** a party who learns the *non-secret*
  ROUTING can **deny pairing availability** by burning displayed codes (a garbage confirm needs no
  SECRET and consumes the displayed code; codes can be burned faster than a human refreshes) — through
  an **honest** rendezvous, no rendezvous compromise required. Mitigations: **ROUTING is minted fresh
  per code refresh** over confidential transport (a burned code yields a new ROUTING, so an attacker who
  learned only the old ROUTING loses the channel); rendezvous rate-limiting is anti-spam only. The
  quantitative availability / rate-limit / guesses-per-code budget is a **`[CRYPTO-DECISION 2a]` +
  product decision (availability in scope)**, not settled here.
- **Typer side** (v4): consumes the typed SECRET by value at confirm-exposure; refuses re-entry of a
  consumed value; no auto-retry; local value-keyed lockout.
- **Adversarial vectors:** anonymous garbage `PAIR_CONFIRM` → at most one displayed-code consumed, **no**
  device backoff and **no** consumed-code-count penalty; garbage/abandoned `PAIR_INIT` → returns to
  LIVE; local repeated wrong SECRET → value-keyed backoff.

---

## §9 — Pins + reconnect ([FIX 1], [FIX 2], [FIX 10])

- **`PinRecord v5`:**
  ```
  { pin_format: 5, contact_id (KEY, CSPRNG local handle), reconnect_handle, identity_key: [32]u8
    (COMPARED value), pake_profile, bound_via, possession_proven: bool, first_paired_at,
    transcript_hash?, device_label }
  ```
- **[FIX 10] `reconnect_handle` invariants (pinned):** CSPRNG-minted, **local/contact-scoped**, **not
  peer-choosable**, high-entropy, locally-unique-on-write — the same invariants as `contact_id`.
  **Explicit privacy risk:** a stable wire-visible `reconnect_handle` lets the untrusted rendezvous link
  a pair's reconnects (metadata-only; no impersonation/confidentiality break). Reconciliation
  (rotating/blinded handles) → `[CRYPTO-DECISION 1c]`. FIX-8's inbound resolution is **contingent on
  `[CRYPTO-DECISION 1a]`** delivering a key-carrying reconnect handshake (strict-KK surfaces a generic
  MAC failure rather than a distinct KEY_MISMATCH).
- **[FIX 1] `KEY_MISMATCH` split by initiator:**
  - **Locally-initiated reconnect** (human/app selects a known contact) → if the peer's presented
    `identity_key` ≠ the pinned value → **hostile, user-visible `KEY_MISMATCH` alert** + explicit
    re-pair (a genuine signal).
  - **Unauthenticated inbound** reconnect (on the contact's `reconnect_handle`) that resolves-then-differs
    → a **silent, rate-limited discard**: **no user alert, no pin mutation, no fall-through to
    first-contact**. Only a locally-initiated reconnect, or an inbound that cryptographically **proves
    possession of the prior pinned key**, may surface `KEY_MISMATCH`. The anonymous-case verdict is
    connection-scoped, never contact-sticky.
  - **Unpinned inbound** `identity_key` on no known handle → first-contact (fresh PAKE), not a mismatch.
- **[FIX 2] FIX-8/FIX-9 reconciled:** because an unauthenticated inbound mismatch is a *silent discard*
  (not a hostile verdict, and not a first-contact fall-through), the `reconnect_handle` cannot summon a
  forged alert about the honest contact (satisfies FIX-9 "never a hostile verdict against the real
  peer") and cannot launder a key swap into a new pairing. Key rotation (writing an existing `contact_id`
  with a new `identity_key`) stays gated behind `[CRYPTO-DECISION 1b]`: interim = new-contact-only or
  old-key cross-cert; a single human confirmation MUST NOT overwrite a `possession_proven` pin.
- `possession_proven` set only after §0 validation + §4 DH confirmation. Migration transactional; old
  pins ignored for trust (EA29); `pin_format` byte-distinguishable; no mass reset.

---

## §10 — Product states (honest, NO "verified")

As v4: `unverified` (block-default) · `approved_for_session` · `code_confirmed` (same-code +
private-key possession; persistent pin only with explicit "remember this device") ·
`reconnect_authenticated` · `pake_failed` / `key_mismatch` (hostile, fail-closed, per the FIX-1 split) ·
`legacy` (policy-gated, never "verified"). No product-facing "verified" claim ships. Transfer gate on
the receive path. Anti-phishing UX: SECRET sensitive/never-share; no single off-app full-code copy.

---

## Remaining cryptographer decisions ([CRYPTO-DECISION])

| Tag | Decision |
|---|---|
| 1a | Named Noise pattern + DH set/mixing order + PAKE⊕Noise composition; converge es/se BY WIRE ROLE (never sort); pairing↔reconnect + §5-Expand-vs-§6-Extract domain separation; **reconnect KK strict-vs-static-carrying** (decides explicit-compare vs MAC-failure on reconnect mismatch — informs §5 L/R basis + FIX-8 reachability) |
| 1b | Identity-key rotation continuity (old-key cross-cert; new contact_id on loss) + es/se KCI scope + rotation-write vs concurrent-reconnect atomicity |
| 1c | Reconnect cadence + detection/revocation (a cloned key raises no KEY_MISMATCH) + the `reconnect_handle` linkability tradeoff (rotating/blinded). Must **not** be read as absorbing the FIX-1 quiet-inbound security fix |
| 2a/2b | Lockout parameters + a quantitative guessing-infeasibility budget **with availability in scope** (guesses-per-code, code-burn rate, human-refresh) + a shower-enforced-atomic single-flight/consume pin |
| 4a | ROUTING grammar + anti-bleed MUST (non-alphanumeric prefix; separator not stripped/folded by the deployed normalization; disjoint alphabets) + SECRET entropy/MHF + confusable-free/non-ASCII normalization |
| 5a | Injective byte-layout freeze via a verified codec + cross-impl decoder equivalence (incl. the single-code split) |
| 6 | PAKE primitive (CPace primary vs SPAKE2-0.4.0 vs SPAKE2+) + its internal point/cofactor/encoding validation (decides whether `pake_msg` needs canonicalization) + the final small-order set + unaudited/not-constant-time HIGH sign-off |
| 7a | Native exporter + fold-locally + mixed native↔browser reconciliation with a non-forceable tier-select (in `capabilities[]`/TT) + a soft browser-tier-default; discharge the browser identity-DH-suffices lemma |

## Formal-model obligations (wire-freeze gate)

Modeled against the **proposed EA1 schedule** (fork A `session_root`-rooted), not the old wire. No
wire-freeze until it passes:

1. Pairing handshake: PAKE + §4 DH schedule + TT + confirmation.
2. Reconnect / KK path — entity auth requires identity-key **possession**.
3. **[FIX 4/5]** Point-validity: encode `DH(low-order,·)=0`; assert §0's all-zero abort rejects it.
   **Byte-level non-canonical rejection is NOT a symbolic-model obligation** (a Dolev-Yao term algebra
   has no byte layer; it contradicts the injective-serialization assumed premise) — it lives in the §0
   wire rule + wire tests + the codec proof (5a).
4. **[v4 FIX 1]** Consumption/lockout: one-guess-per-displayed-code; device-wide backoff never escalates
   from anonymous inbound **nor from consumed-code count**.
5. **[v4 FIX 5]** Reflection/UKS resistance **given** a direction-separated confirmation + the negative
   obligation (reflection completes if confirmation is symmetric).
6. **[FORK A / FIX 6]** `session_root` secrecy AND that the **data AEAD/BTR key is a function of
   `session_root`**, under a relaying + transport-terminating MITM, on BOTH paths (pairing: no SECRET ⇒
   no PRK; reconnect: no identity/ephemeral privates ⇒ no es/se/ss ⇒ no PRK); substitute-data-ephemeral
   → cryptographic fail; `ephemeral_key == PAIR_INIT ephemeral == envelope ephemeral` entity agreement.
7. **[FIX 1]** Reconnect resolution: locally-initiated resolve-then-differ ⇒ `KEY_MISMATCH`; an
   **anonymous inbound** resolve-then-differ ⇒ **no hostile user-surfaced verdict, no pin mutation**;
   unpinned ⇒ first-contact.
8. Reconnect-downgrade resistance (`possession_proven` non-overridable).
9. **[FIX 7]** Legacy/conforming-typer-leak: for a *conforming reference client*, SECRET never appears
   in any rendezvous-facing message (structural at the API boundary + byte-scan harness); non-conforming
   clients are documented out-of-scope, not modeled.
10. Three transport configs (native / browser / mixed). Record ideal-PAKE/ideal-DH + injective
    serialization as **assumed premises**; carve the computational PAKE⊕Noise composition to a separate
    reductionist sign-off (1a); keep the quantitative guess+availability budget (2a) separate. **[FIX
    10] `reconnect_handle` privacy is NOT certified by obligation #7; unlinkability is deferred to CD1c.**

## Test obligations

- **Cross-impl golden vectors (Rust ↔ WASM, byte-identical):** normalization; TT codec (both
  directions); `ikm`/`PRK` byte assembly; HKDF outputs; confirmation MAC; **`session_root` + the
  data/BTR key derived from it (fork A)**.
- **[FIX 8]** §5 L/R role: a mixed Rust↔WASM vector with a first-differing-byte **≥0x80** `side_id` pair
  (unsigned-basis regression).
- **[FIX 9]** es/se orientation: a **sort-discriminating** vector (role-L's es lexicographically greater
  than role-R's se) — a KCI-destroying sorting impl MUST FAIL it.
- **[FIX 1]** locally-initiated reconnect with a substituted `identity_key` → hostile `KEY_MISMATCH`;
  **anonymous inbound** substituted-key on a known handle → **silent discard, no alert, no pin
  mutation**; unpinned → first-contact.
- **[FIX 3]** anonymous garbage `PAIR_CONFIRM` → at most one displayed-code consumed, **no** device
  backoff, **no** consumed-code-count penalty; ROUTING fresh-per-refresh.
- **[FORK A]** substitute-data-ephemeral-after-PAKE → cryptographic decrypt-fail (data now roots on
  `session_root`); a MITM-computed `session_root` without SECRET → fail.
- **[FIX 10]** `reconnect_handle` CSPRNG-minted, not peer-choosable.
- Carry all v4 vectors: low-order-static/ephemeral abort; high-bit-flip / u≥p ingress reject +
  high-bit-flipped self-reflection reject; differential CSPRNG KAT + negative shared-seed;
  symmetric-confirmation negative (reflection completes); conforming-client → malicious-server byte-scan
  harness + mis-split fuzz.

## Hard boundaries

- **No implementation. No `PROTOCOL.md` edits in this gate. No wire-freeze. No spike merge. No
  "verified" product behavior.** The `bolt-spake2-spike` crate stays inert; old "verified" stays disabled
  (EA29).
- Fork A's wire change is a **proposed future delta** (above), applied only in a separately-authorized
  spec gate after the cryptographer + formal model sign off.
- Wire-freeze is FORBIDDEN until every `[CRYPTO-DECISION]` resolves, the required `PROTOCOL.md` delta is
  authorized + applied, the external cryptographer signs off, and the formal model passes.

## Next (not authorized here)

A fifth UltraCode adversarial pass is recommended. If it returns ACCEPTABLE-FOR-CRYPTOGRAPHER-REVIEW,
EA1 becomes the external-review package: the cryptographer + formal-methods reviewer evaluate the
proposed EA1 schedule (fork A) and the `[CRYPTO-DECISION]` set; a future spec gate applies the
`PROTOCOL.md` delta; wire-freeze remains the gated exit.
