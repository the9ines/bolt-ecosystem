# Decision: EA1 PAKE v4 Protocol Profile — Revised Draft

> **Date:** 2026-07-17
> **Status:** **PROPOSED — NEEDS REVISION. NOT WIRE-FROZEN. NOT IMPLEMENTATION-AUTHORIZED. NO
> "verified" PRODUCT BEHAVIOR.** A v4 adversarial red-team (2026-07-17) returned **NEEDS-REVISION**
> (cryptographer-ready: No) — see the *Red-team outcome (v4): NEEDS REVISION* note below and
> `docs/evidence/EA1_PAKE_V4_REDTEAM.md`. Incorporates the nine required edits from the v3 adversarial
> red-team
> (`docs/evidence/EA1_PAKE_V3_REDTEAM.md`, verdict NEEDS-REVISION — no blocker, all draft-defects).
> Supersedes-in-specifics the v3 draft (`os/log/decisions/2026-07-16-ea1-pake-v3-profile-draft.md`,
> PROPOSED — NEEDS REVISION), which is retained verbatim. EA1 remains **OPEN**. Contains open items
> that REQUIRE an external cryptographer — marked **[CRYPTO-DECISION]** — and cannot be wire-frozen
> until they resolve.
> **Scope repos:** `bolt-protocol` (future spec), `bolt-core-sdk` (future SDK), products — all future,
> all gated.
> **Lineage:** direction ADR → v1 (REVISION REQUIRED) → v2 (REVISION REQUIRED) → v3 (NEEDS REVISION)
> → **this v4 draft.** Evidence: `docs/evidence/EA1_REDTEAM.md`, `docs/evidence/PAKE_EVAL.md`,
> `docs/evidence/EA1_PAKE_PROFILE_REDTEAM.md`, `docs/evidence/EA1_PAKE_V2_REDTEAM.md`,
> `docs/evidence/EA1_PAKE_V3_REDTEAM.md`.

## Red-team outcome (v4): NEEDS REVISION

A v4 UltraCode adversarial review (2026-07-17, the fourth pass) returned **NEEDS-REVISION**;
cryptographer-ready **No**. Full report: **`docs/evidence/EA1_PAKE_V4_REDTEAM.md`**.

- **This draft is PROPOSED — NEEDS REVISION. Not wire-frozen, not implementation-authorized.**
- **The closest pass yet — no blocker; 7 of 9 v3 edits landed cleanly.** Two confirmed draft-defects
  the author must fix before cryptographer handoff remain, plus LOW cleanups.
- **Blocking defect ① (HIGH):** §6's `session_root = HKDF(salt = PRK, …)` is **computed but unused** —
  the normative (unedited) `PROTOCOL.md` keys the data channel from `ee` alone (non-BTR direct-ee; BTR
  salt = EMPTY; BTR-INV-01), so §6's data-keying premise + the browser "secret PRK salt" claim are
  false for the wire and obligation #6 discharges against an unused value. File-byte confidentiality
  still holds via `ee`-authentication (∴ HIGH, not a blocker). Fix = pick a fork: **(A)** re-root the
  data/BTR schedule on `session_root` (needs explicitly lifting "no protocol-spec edits" for that one
  change; adds a PRK-salt backstop vs `ee`-recovery), or **(B)** re-attribute §6 to `ee`-authentication
  and drop the PRK-salt/browser sentences (design-only, no backstop).
- **Blocking defect ② (MEDIUM):** inbound `KEY_MISMATCH` is attacker-summonable via the stable
  rendezvous-visible `reconnect_handle` — an anonymous key-less party presenting a self-generated key
  forces a hostile "your contact's key changed" alert about the honest contact (obligation #7 + test
  L348 mandate it). It is the reconnect-path sibling of the §8/FIX-1 anonymous-inbound pattern. Fix =
  split `KEY_MISMATCH` by initiator (locally-initiated = hostile alert; unauthenticated inbound
  resolve-then-differ = silent, rate-limited, non-alerting, non-pin-mutating discard) + reconcile the
  FIX-8/FIX-9 contradiction.
- **Plus 8 LOW cleanups** (enumerated in the evidence file): §8 DoS honestly re-characterized; strike
  the byte-layer clause from formal-model obligation #3; fix the RFC 7748 citation; add the reconnect
  confidentiality chain; narrow the SECRET-off-server claim to conforming reference clients + the
  harness; pin the §5 L/R comparison basis; add sort-discriminating es/se vectors; give
  `reconnect_handle` `contact_id`-grade invariants.
- Old "verified" stays disabled (EA29). Wire-freeze remains FORBIDDEN. After the two blocking fixes +
  the LOW cleanups, the review expects the draft clears for cryptographer + formal-methods handoff.

This draft is retained verbatim as the *reviewed v4*; the revision (choosing §6 fork A and landing the
fixes) is tracked separately as the v5 draft.

## What v4 changes (the nine required edits)

v4 keeps the type-a-secret PAKE + identity-DH direction and applies the nine draft-defect corrections
the v3 review required. Each is tagged **[FIX n]** below. The v3 review found no blocker (the §0
low-order/all-zero-DH rule closed the v2 blocker); these are precision/wire corrections.

| # | Area | v4 fix |
|---|------|--------|
| 1 | Code consumption / backoff | Consume the single displayed code on a failed confirm (one-guess bound); **never** device-wide backoff from anonymous inbound; backoff only from the typer's own local value-keyed attempts (§8). |
| 2 | Session root | `session_root = HKDF(salt = PRK, ikm = ephemeral_shared_secret)`; TT only in `info`, never as salt; state the no-SECRET-⇒-no-PRK premise (§6). |
| 3 | Ephemeral shared secret | `ephemeral_shared_secret := ee = X25519(own PAIR_INIT eph priv, peer PAIR_INIT eph pub)`; exactly one session ephemeral per side; well-typed pubkey==pubkey binding (§6). |
| 4 | Routing/SECRET | No legacy-parser claim; SECRET-off-server is a conforming-client property; **separate ROUTING/SECRET API inputs** so no string containing SECRET reaches the mailbox/signaling layer (§1). |
| 5 | Anti-reflection | Resistance is **joint** (equality reject + TT identity binding + a mandatory direction-separated confirmation); §5 is load-bearing; negative vector (§4/§5). |
| 6 | Canonical X25519 | Equality over canonical encodings + reject non-canonical byte forms at ingress; high-bit-flip vector (§0/§4). |
| 7 | CSPRNG independence | Two separate CSPRNG reads; **differential** KAT + a negative shared-seed reference that MUST fail (§1). |
| 8 | KEY_MISMATCH | Reconnect resolves to `contact_id` first, then compares `identity_key` (resolve-then-differ ⇒ hostile); precise reachability, not a blanket claim (§9). |
| 9 | Rotation overwrite | Gated behind `[CRYPTO-DECISION 1b]`; interim = new-contact-only or old-key cross-cert; **no human-confirm-only overwrite** (§9). |

### Claims retracted/corrected (falsified by the v1/v2/v3 reviews)

- v1 lines 89/150/164 + "Closes … EA16" — retracted (v2), stay retracted.
- v2 §1/§4/§6/§7/§9 overclaims — retracted (v3), stay retracted.
- v3 §8 "removes the v2 unauthenticated-probe DoS" — **corrected [FIX 1]:** a failed confirm consumes
  the single displayed code but never device-wide-backs-off; a residual bounded nuisance-DoS on the
  displayed code is acknowledged, not denied.
- v3 §6 "fails cryptographically on every transport — not merely via a byte-check" — **corrected
  [FIX 2]:** true only under `salt = PRK` (the `(or TT)` public-salt option is removed).
- v3 §1 "a legacy parser rejects the `bolt2:` container" — **retracted [FIX 4]** (code-verified
  false; replaced by structural separate-input separation).
- v3 §4/obligation-#5 "reflection resistance independent of the confirmation mechanism" — **retracted
  [FIX 5]:** it is joint and depends on the confirmation layer.
- v3 §9 blanket "KEY_MISMATCH stays reachable" — **softened [FIX 8]** to precise resolve-then-differ
  conditions.

---

## §0 — Key validity (normative)

All Curve25519 public keys and all X25519 DH outputs are validated before use — a wire rule, not a
`[CRYPTO-DECISION]`.

- **Reject known small-order u-coordinates** (RFC 7748 §6.1 blacklist) on every received
  `identity_key` and `ephemeral_key` before any DH.
- **[FIX 6] Reject non-canonical encodings at ingress:** an `identity_key`/`ephemeral_key` whose
  32-byte u-coordinate has the high (255th) bit set, or encodes u ≥ p, MUST be rejected before use.
  This canonicalizes every public key at ingress so downstream byte-equality (§4) is over canonical
  forms.
- **Abort on all-zero DH output** (constant-time) after every X25519 — `ee` (= `ephemeral_shared_secret`,
  §6), `es`, `se`, `ss`.
- **Scope:** identity **and** ephemeral keys, at **both** pairing and reconnect. A key that fails
  validation MUST NOT be used, pinned, or set `possession_proven`. Pinned keys are re-validated before
  every reconnect DH.
- **Model + tests:** point-validity is a formal-model obligation (encode DH(low-order,·)=0); ship
  low-order-static, low-order-ephemeral, **and [FIX 6] high-bit-flipped / u≥p** adversarial golden
  vectors. (The chosen PAKE's internal scalar-mult point validation is folded into
  `[CRYPTO-DECISION 6]`.)

---

## §1 — Human-code UX + routing/secret ([FIX 4], [FIX 7])

- **One-sided entry** (magic-wormhole model): displaying peer shows the code; initiating peer's human
  supplies it.
- **[FIX 4] Structural ROUTING/SECRET separation — no single string containing SECRET reaches the
  transport/mailbox layer.** ROUTING and SECRET are handled as **two separate inputs/artifacts**:
  - `ROUTING` — the rendezvous mailbox locator; the **only** value the signaling/mailbox API accepts.
  - `SECRET` — the PAKE password; fed **only** to a dedicated PAKE-password input that is **not a
    parameter of any rendezvous-facing call**. The mailbox/signaling API's surface takes ROUTING only;
    there is no code path where SECRET is an argument to a rendezvous message.
  - Delivery: QR encodes two fields; a typed code is either two UI fields, or a single displayed code
    the **client splits locally into the two API inputs before any network I/O** (validating ROUTING
    locally first, feeding SECRET only to the PAKE input).
  - **SECRET-off-server is a conforming-client property.** We make **no** claim that a server or a
    legacy parser "cannot receive" SECRET (the v3 "legacy parser rejects `bolt2:`" claim was
    code-verified false and is **removed**). The guarantee is structural at the *conforming* client's
    API boundary; a non-conforming/legacy client predating this split is explicitly **outside** the
    guarantee. Honest-server rejection of non-ROUTING ids is hygiene, not a security control.
  - **Test [FIX 4]:** a legacy/forked → malicious-server conformance harness asserting SECRET bytes
    never appear in any rendezvous-facing message across every deployed/forked client; assert the
    signaling API type-level cannot carry SECRET.
- **[FIX 7] CSPRNG independence:** ROUTING and SECRET are produced by one audited routine doing **two
  separate CSPRNG reads** (no shared/derivable seed) — the only sanctioned API; deriving either from
  the other is FORBIDDEN. Enforcement is a **differential** white-box KAT: (i) fix stream-A, vary
  stream-B (≥2 values) → ROUTING byte-identical, SECRET differs; (ii) fix stream-B, vary stream-A →
  SECRET byte-identical, ROUTING differs; (iii) a **negative** reference — a deliberately shared-seed
  impl **MUST FAIL** the suite. ROUTING length/format is constant, independent of SECRET.
- **Alphabet/entropy:** SECRET ≈ 8 chars / 31-char unambiguous alphabet (~40 bits), normalization a
  re-pinned golden vector; ROUTING grammar + anti-bleed + SECRET entropy/MHF are `[CRYPTO-DECISION 4a]`
  (prefix non-alphanumeric; separator not a char the deployed normalization strips/folds e.g. `-`;
  disjoint alphabets; confusable-free / non-ASCII normalization).

---

## §2–§3 — Message sequence + transcript TT

As v3: after the peer channel opens, symmetric `PAIR_INIT` (`side_id`, `pake_msg`, `identity_key`,
`ephemeral_key`, `bolt_version`, `capabilities[]`) then `PAIR_CONFIRM`; `TT` = the canonical injective
encoding of both PAIR_INITs (byte-layout freeze via a verified codec, `[CRYPTO-DECISION 5a]`). §0
validation (incl. **[FIX 6]** canonical-encoding rejection) runs on every received public key before
any use.

---

## §4 — PAKE + identity-DH key schedule + anti-reflection ([FIX 5], [FIX 6])

**Pairing:** `ikm = k_pake ‖ ee ‖ es ‖ se ‖ ss`, `PRK = HKDF-Extract(salt = TT, ikm)`.
**Reconnect:** `ikm = ee ‖ es ‖ se ‖ ss` (no `k_pake`). Every DH is §0-validated (canonical +
all-zero abort).

- **[FIX 6] Equality over canonical encodings:** the anti-reflection comparisons below are performed
  over the §0-canonicalized encodings, so a high-bit-flipped/non-canonical re-encoding of one's own key
  cannot dodge them.
- **[FIX 5] Anti-reflection / anti-UKS is JOINT — three controls, all required:**
  1. **Equality reject (before key derivation):** reject inbound `PAIR_INIT` if any of
     `peer_ephemeral == own`, `peer_identity_key == own`, `peer_pake_msg == own`, `peer_side_id == own`
     (canonical compare). Stops verbatim reflection (Vector-1).
  2. **TT identity binding:** both identity keys are canonically bound in TT. Stops unknown-key-share.
  3. **Mandatory direction-separated confirmation (§5) — LOAD-BEARING:** stops the fresh-key
     typer-reflection (Vector-2), where an attacker injects a `PAIR_INIT` with its own four fields so
     the equality reject never fires. This is **not** defense-in-depth; it is the sole control against
     Vector-2.
  Resistance is independent only of the PAKE **primitive's internal** complement mechanism (SPAKE2
  `side_id` / CPace structure), **not** of the confirmation layer. The v3 "independent of the
  confirmation mechanism" claim is retracted. Applies on CPace, SPAKE2, and the reconnect KK path.
- **[CRYPTO-DECISION 1a]** the named Noise pattern (reconnect ≈ KK, pairing ≈ XX/IK+PSK), DH set +
  mixing order, the PAKE⊕Noise composition, **converging `es`/`se` by wire role (never by sorting —
  sorting destroys the KCI binding)**, explicit pairing↔reconnect domain separation (per-path HKDF
  context / PSK label, not emergent), and domain-separating §5's PRK-as-Expand-key from §6's
  PRK-as-Extract-salt.
- **[CRYPTO-DECISION 6]** PAKE primitive (CPace recommended vs SPAKE2-0.4.0 vs SPAKE2+) + sign-off,
  incl. the primitive's internal point/cofactor validation.

---

## §5 — Key confirmation (direction-separated, LOAD-BEARING) ([FIX 5])

`PRK` → HKDF-Expand to `K_conf_L`, `K_conf_R`, `K_session`, optional `SAS_disp`. Role L/R = owner of
the lexicographically-smaller `side_id`. Each side sends its role's MAC and verifies the peer's under
the **complement** role key — **never try-both** — constant-time, fail-closed. **[FIX 5] This
direction separation is load-bearing** for reflection resistance (Vector-2), not merely defense in
depth. Receiver-confirms-last: the shower verifies the typer's `PAIR_CONFIRM` before disclosing its
own. On failure → `PAIR_CONFIRM_FAILED`, fail-closed (see §8 for consumption).

- **Formal obligation [FIX 5]:** reflection/UKS resistance holds **given** a direction-separated
  confirmation, **and** the NEGATIVE obligation — a reflection **completes** if the confirmation is
  made symmetric (proving §5 is load-bearing).

---

## §6 — Session root binding ([FIX 2], [FIX 3])

- **[FIX 3] Define the ephemeral shared secret exactly:**
  `ephemeral_shared_secret := ee := X25519(own PAIR_INIT ephemeral private, peer PAIR_INIT ephemeral
  public)`. Each side has **exactly one** session ephemeral keypair = the one in its `PAIR_INIT`
  (bound in TT); it is **never** a transport/DTLS/QUIC/DataChannel ephemeral. §0's DH-output enumeration
  labels this as `ee` (no separate "5th DH").
- **Well-typed binding (replaces the v3 type-confused MUST):** the `ephemeral_key` in `PAIR_INIT`
  (bound in TT) **MUST** be the public key whose private half computes `ephemeral_shared_secret`, **and
  MUST** equal the `sender_ephemeral_key` of every post-handshake envelope. This is a public-key ==
  public-key check (well-typed), enforced fail-closed on the receive path before `HANDSHAKE_COMPLETE` /
  before any data envelope. (No public-key == DH-output comparison.)
- **[FIX 2] Session root:** `session_root = HKDF(salt = PRK, ikm = ephemeral_shared_secret, info =
  "bolt-pake-v4 session-root")`. **`salt` MUST be PRK** (the secret handshake key); the v3 `(or TT)`
  public-salt option is **removed**. Any transcript/domain separation goes in `info`, **never** as the
  salt.
- **Load-bearing premise (stated explicitly [FIX 2]):** a relaying MITM lacks SECRET ⇒ cannot derive
  `k_pake` ⇒ cannot compute `PRK` ⇒ **cannot compute `session_root`.** So a substituted data ephemeral
  yields a `session_root` the MITM cannot know, and the honest endpoints key the data channel with a
  root the MITM cannot compute — content confidentiality fails **cryptographically** for the MITM (not
  merely via a byte-check). The golden `session_root` vector is now cross-impl-deterministic (single
  mandated salt).
- **Channel binding:** fold a locally-observed transport secret on native transports that can export
  (require-binding floor); browsers have **no** exporter — their transport-MITM resistance comes from
  the §6 `session_root` binding (secret PRK salt) + identity-DH, not a relayed cert-hash. Exporter +
  mixed native↔browser reconciliation (non-forceable tier-select bound into TT/ceremony) is
  `[CRYPTO-DECISION 7a]`; its browser backstop depends on this salt being PRK.

---

## §7 — Downgrade floor: pairing + reconnect

As v3: pairing floor bound to the human code ceremony + an unstrippable PAKE-capable marker, default
require-PAKE ON, bare-legacy-HELLO rejected during a ceremony. **Reconnect:** a `possession_proven`
pin makes identity-DH reconnect **mandatory and non-overridable** on both peers; legacy / "old device"
mode and BTR→static downgrade are **forbidden** for a `possession_proven` contact, fail-closed; the
reconnect floor is enforced from the authenticated identity-DH result, never from MITM-mutable HELLO
caps.

---

## §8 — One-time code consumption ([FIX 1])

Two mechanisms, **cleanly decoupled** (the v3 §8 conflation was the confirmed HIGH):

- **One-guess bound (per displayed code):** an inbound `PAIR_CONFIRM` that fails verification consumes
  the **single currently-displayed code** (that code → CONSUMED); the shower prompts the human to
  display a fresh code to continue. This bounds anyone who knows the mailbox to **one guess per
  displayed code**. (The shower cannot distinguish a real wrong-guess confirm from garbage — both are
  a MAC that does not verify — so both consume the one displayed code; that is the correct, bounded
  behavior.)
- **Single-flight:** one IN_FLIGHT pairing per displayed code; concurrent `PAIR_INIT`s are rejected
  (not queued); an **incomplete** exchange (bare/abandoned `PAIR_INIT`, drop, timeout — no confirm)
  returns the slot to LIVE without consuming.
- **[FIX 1] Device-wide backoff (anti-serial-guessing) is LOCAL-ONLY:** it escalates **only** from the
  **typer's own locally-initiated, value-keyed** attempts (a wrong SECRET typed on this device). It
  **MUST NEVER** escalate from anonymous inbound confirms/probes — a remote attacker sending a garbage
  `PAIR_CONFIRM` to the shower **must not** lock the honest user's device. This is the direct fix for
  the v3 confirmed HIGH.
- **Typer side:** consumes the typed SECRET keyed on its **value** at confirm-exposure; refuses
  re-entry of a consumed value; no auto-retry; local value-keyed lockout on repeated wrong local
  entries.
- **Rendezvous rate-limiting:** anti-spam only (bounds inbound-probe volume), **not** a security proof.
- **Residual (acknowledged, not denied):** an attacker who knows the mailbox can burn *displayed
  codes* (a bounded nuisance-DoS on pairing availability — not a device lockout, not a confidentiality
  break), throttled by rate-limiting + human supervision. Flagged; acceptable.
- **Adversarial vectors [FIX 1]:** (a) anonymous garbage `PAIR_CONFIRM` → consumes at most the one
  displayed code, **MUST NOT** escalate device-wide backoff; (b) garbage/abandoned `PAIR_INIT` →
  returns to LIVE, no consume; (c) local repeated wrong SECRET entry → value-keyed device backoff.
- **[CRYPTO-DECISION 2a/2b]** lockout parameters + a separate **quantitative** guessing-infeasibility
  budget (SECRET entropy × guesses-per-code × human-refresh rate → work factor), gated separately from
  the symbolic proof.

---

## §9 — Pins + reconnect ([FIX 8], [FIX 9])

- **`PinRecord v4`:**
  ```
  { pin_format: 4, contact_id (KEY, CSPRNG local handle), reconnect_handle (stable, per-contact),
    identity_key: [32]u8 (COMPARED value), pake_profile, bound_via, possession_proven: bool,
    first_paired_at, transcript_hash?, device_label }
  ```
  `contact_id` is a unique CSPRNG-minted **local** handle (never a user/peer label); `device_label` is
  a separate display field.
- **[FIX 8] Reconnect resolves to a contact BEFORE comparing the identity key:**
  - **Locally-initiated reconnect** (the app/human selects a known contact): the local side knows
    `contact_id` → the expected `identity_key`; it runs the identity-DH; if the peer's presented
    `identity_key` ≠ the pinned value → **`KEY_MISMATCH` hostile abort** + explicit re-pair.
  - **Inbound reconnect:** carried on the contact's stable `reconnect_handle` (agreed at pairing), so
    an inbound connection **resolves to `contact_id` first**, then compares the presented
    `identity_key` (resolve-then-differ ⇒ `KEY_MISMATCH` hostile, MUST NOT fall through to
    first-contact). An inbound connection on **no** known handle / presenting an **unpinned**
    `identity_key` is treated as **first-contact** (fresh PAKE required) — this is *not* a mismatch.
  - **Precise reachability (replaces the v3 blanket claim):** `KEY_MISMATCH` is reachable and hostile
    exactly on the **resolve-then-differ** path (a known contact resolves to a different identity key);
    an unknown/unpinned key is first-contact, not a mismatch.
  - **Caveat (deferred):** a stable `reconnect_handle` is linkable by the untrusted rendezvous (it can
    correlate a pair's reconnects). Linkability-vs-mismatch-reachability is `[CRYPTO-DECISION 1c]`
    (candidates: rotating handles, blinded handles).
- **[FIX 9] Key rotation is gated behind `[CRYPTO-DECISION 1b]`; NO human-confirm-only overwrite.**
  Writing an existing `contact_id` with a **new** `identity_key` is not a settled MUST. Interim posture
  until 1b resolves:
  - **Default = new-contact-only:** a changed/new `identity_key` mints a **new** `contact_id` (a
    visibly new relationship); it never silently overwrites the trusted contact's pin, never inherits
    its reconnect trust, and never converts the retained old key into a `KEY_MISMATCH`-hostile verdict
    against the real peer.
  - **Or = old-key cross-cert-gated:** the currently-pinned OLD key signs/authenticates the NEW key,
    verified **before** any overwrite.
  - A single human confirmation MUST NOT, by itself, overwrite a `possession_proven` pin (a phishing
    click must not erase `key_B` → `key_M`).
- `possession_proven` is set only after §0 validation + §4 DH confirmation. Migration: transactional;
  old v1/v2/v3 pins ignored for trust (EA29), `pin_format` keeps versions byte-distinguishable, no mass
  reset.

---

## §10 — Product states (honest, NO "verified")

As v3: `unverified` (block-default) · `approved_for_session` · `code_confirmed` (same-code +
private-key possession; persistent pin only with explicit "remember this device") ·
`reconnect_authenticated` (matched `possession_proven` pin via identity-DH) · `pake_failed` /
`key_mismatch` (hostile, fail-closed) · `legacy` (policy-gated authorization, never "verified"). No
product-facing "verified" claim ships. Transfer gate enforced on the receive path. Anti-phishing UX:
SECRET rendered as sensitive/never-share; no single off-app full-code copy affordance.

---

## Remaining cryptographer decisions ([CRYPTO-DECISION])

| Tag | Decision |
|---|---|
| 1a | Named Noise pattern + DH set/mixing order + PAKE⊕Noise composition; converge es/se BY WIRE ROLE (never sort); explicit pairing↔reconnect domain separation; domain-separate §5-Expand-key vs §6-Extract-salt |
| 1b | Identity-key rotation continuity (old-key cross-cert; new contact_id on loss) + es/se KCI scope; rotation-write vs concurrent-reconnect atomicity |
| 1c | Reconnect cadence / bounded re-anchoring + a **detection/revocation** story (a cloned key raises no KEY_MISMATCH) + the `reconnect_handle` **linkability** tradeoff |
| 2a/2b | Lockout parameters + a separate quantitative guessing-infeasibility budget |
| 4a | ROUTING grammar + anti-bleed MUST (non-alphanumeric prefix; separator not stripped by normalization; disjoint alphabets) + SECRET entropy/MHF + confusable-free/non-ASCII normalization |
| 5a | Injective byte-layout freeze via a verified codec + cross-impl decoder equivalence (incl. the split/parse of the two artifacts) |
| 6 | PAKE primitive (CPace primary vs SPAKE2-0.4.0 vs SPAKE2+) + crate/reduction/composition + internal point/cofactor validation + unaudited/not-constant-time HIGH sign-off |
| 7a | Native exporter + fold-locally + mixed native↔browser reconciliation with non-forceable tier-select binding; discharge the browser identity-DH-suffices lemma |

## Formal-model obligations (wire-freeze gate)

No wire-freeze until the Tamarin/ProVerif model passes, covering:

1. Pairing handshake: PAKE + §4 DH schedule + TT + confirmation.
2. Reconnect / KK path — entity auth requires identity-key **possession** at pairing and reconnect.
3. **[§0/FIX 6]** Point-validity: encode DH(low-order,·)=0; assert §0 rejects it; assert non-canonical
   encodings are rejected at ingress.
4. **[FIX 1]** Consumption/lockout: the one-guess-per-displayed-code bound; **device-wide backoff never
   escalates from anonymous inbound** (only from the typer's local value-keyed attempts).
5. **[FIX 5]** Reflection/UKS resistance **given** a direction-separated confirmation, **plus** the
   negative obligation (reflection completes if confirmation is symmetric).
6. **[FIX 2/3]** `session_root` secrecy under a relaying + transport-terminating MITM: no SECRET ⇒ no
   PRK ⇒ no `session_root`; substitute-data-ephemeral → cryptographic fail; `ephemeral_key ==
   PAIR_INIT ephemeral == envelope ephemeral` entity agreement.
7. **[FIX 8]** Reconnect resolves to `contact_id` before the identity compare; resolve-then-differ ⇒
   `KEY_MISMATCH`; unpinned ⇒ first-contact.
8. Reconnect-downgrade resistance (`possession_proven` non-overridable).
9. **[FIX 4]** Legacy-typer-leak: for a conforming client, SECRET never appears in any rendezvous-facing
   message (structural at the API boundary); the non-conforming residual is documented, not modeled.
10. Three transport configs (both-native / both-browser / mixed). Record ideal-PAKE/ideal-DH +
    injective serialization as **assumed premises**; carve the computational PAKE⊕Noise composition to
    a separate reductionist sign-off (1a); keep the quantitative guess-budget (2a) separate.

## Test obligations

- **Cross-impl golden vectors (Rust ↔ WASM, byte-identical):** normalization; TT codec (both
  directions); `ikm`/`PRK` byte assembly (es/se orientation, ee/ss order, X25519 endianness); HKDF
  outputs; confirmation MAC; **`session_root` (now pinnable — single salt=PRK) [FIX 2]**.
- **[§0/FIX 6]** low-order-static/ephemeral → abort; all-zero-DH → abort; **high-bit-flipped / u≥p →
  reject at ingress; high-bit-flipped self-reflection → §4 reject**.
- **[FIX 4]** legacy/forked → malicious-server harness: SECRET bytes never in any rendezvous-facing
  message; signaling API type-level cannot carry SECRET.
- **[FIX 5]** symmetric-confirmation **negative** vector: a reflection **completes** (proving §5 is
  load-bearing); direction-separated confirmation → reflection rejected.
- **[FIX 2/3]** substitute-data-ephemeral-after-PAKE → cryptographic decrypt-fail; `ephemeral_key` !=
  PAIR_INIT ephemeral → fail-closed.
- **[FIX 7]** differential CSPRNG KAT (vary-one/hold-other, both directions) + a negative shared-seed
  impl that MUST fail.
- **[FIX 8]** locally-initiated reconnect to a known contact with a substituted `identity_key` →
  `KEY_MISMATCH` hostile; inbound on a known `reconnect_handle` with a substituted key → `KEY_MISMATCH`;
  inbound unpinned key → first-contact.
- **[FIX 9]** human-confirm-only overwrite of a `possession_proven` pin → FORBIDDEN; new-contact-only /
  cross-cert-gated path exercised.
- **[FIX 1]** anonymous garbage `PAIR_CONFIRM` → at most one-displayed-code consumed, **no** device
  backoff; garbage/abandoned `PAIR_INIT` → returns to LIVE; local repeated wrong SECRET → value-keyed
  backoff.

## Hard boundaries

- **No implementation. No protocol-spec edits. No wire-freeze. No spike merge. No "verified" product
  behavior.** The `bolt-spake2-spike` crate stays inert and unmerged; old "verified" stays disabled
  (EA29).
- Wire-freeze is FORBIDDEN until every `[CRYPTO-DECISION]` resolves, the external cryptographer signs
  off, and the formal model (above) passes. This draft is a design input, not an authorization.

## Next (not authorized here)

A fourth UltraCode adversarial pass is recommended before cryptographer handoff. If it returns
ACCEPTABLE-FOR-CRYPTOGRAPHER-REVIEW, EA1 becomes the external-review package (spec design-freeze
drafting may proceed against this draft; wire-freeze remains the gated exit).
