# Decision: EA1 PAKE v7 Protocol Profile — Revised Draft

> **Date:** 2026-07-18
> **Status:** **DRAFT — PROPOSED. NOT WIRE-FROZEN. NOT IMPLEMENTATION-AUTHORIZED. NO "verified"
> PRODUCT BEHAVIOR.** Corrects the v6 BTR-schedule over-flattening (fork A **re-seeds** the existing
> BTR ratchet, it does not replace it) and lands the v6 review's four LOW cleanups. Retains the
> class-level **§AV Adverse-Verdict Invariant** and **§6 fork A** (a future `PROTOCOL.md` delta, below).
> Supersedes-in-specifics the v6 draft (`os/log/decisions/2026-07-17-ea1-pake-v6-profile-draft.md`,
> PROPOSED — NEEDS REVISION), retained verbatim. EA1 remains **OPEN**. Contains open items that REQUIRE
> an external cryptographer — marked **[CRYPTO-DECISION]** — and a **required future `PROTOCOL.md`
> delta**; it cannot be wire-frozen until those resolve.
> **Scope repos:** `bolt-protocol` (future spec — see the required delta), `bolt-core-sdk` (future
> SDK), products — all future, all gated.
> **Lineage:** direction ADR → v1 → v2 → v3 → v4 → v5 → v6 (all superseded-in-specifics) → **this v7
> draft.** Evidence: `docs/evidence/EA1_REDTEAM.md`, `docs/evidence/PAKE_EVAL.md`,
> `docs/evidence/EA1_PAKE_PROFILE_REDTEAM.md`, `docs/evidence/EA1_PAKE_V2_REDTEAM.md`,
> `docs/evidence/EA1_PAKE_V3_REDTEAM.md`, `docs/evidence/EA1_PAKE_V4_REDTEAM.md`,
> `docs/evidence/EA1_PAKE_V5_REDTEAM.md`, `docs/evidence/EA1_PAKE_V6_REDTEAM.md`.

## What v7 changes

The v6 pass returned NEEDS-REVISION with **no blocker** and one CONFIRMED MEDIUM: the v6 §5
"K_session retirement" over-reached and falsely denied the canonical, load-bearing, ratcheting BTR
`session_root_key`, which (read literally) would collapse per-transfer forward secrecy. v7 makes the
**one localized correction** — fork A *re-seeds* the existing ratchet — plus the four LOW cleanups.

| Area | v7 change |
|---|---|
| **§5/§6 CORE** | **Fork A re-seeds, does not flatten.** `session_root` seeds the generation-0 BTR `session_root_key`; the BTR hierarchy + inter-transfer DH ratchet + BTR-INV-01..11 + per-transfer forward secrecy are RETAINED; only the gen-0 seed changes from `ee` to the authenticated `session_root`. |
| §9 [LOW 1] | Rate-limiter honesty: no unsatisfiable "never sheds a valid future connection" absolute; pre-DH availability-DoS disclosed honestly; budget/connection-slot/scalar-mult protection → CD2a. |
| §5/test [LOW 2] | es/se vector mandates a **wire-role** negative (swap initiator↔responder ⇒ es/se transpose ⇒ PRK MUST differ). |
| §0 [LOW 3] | Clamped X25519 stated for **ee/es/se/ss**; clamping named in the low-order/twist formal obligation. |
| §6/CD7a [LOW 4] | Restore the non-forceable exporter/tier-select pin into `capabilities[]`/TT. |
| §AV, fork A | Both retained (§AV holds on all paths per the v6 review; fork A stays a proposed future delta). |

### Claims retracted/corrected across the lineage

- v1 89/150/164 + "Closes … EA16" — retracted (v2). v2 §1/§4/§6/§7/§9 — retracted (v3). v3 §8/§6/§1/§4/§9
  — retracted (v4). v4 §6/§9/§8/§0/obl.#3 — retracted (v5 + fork A). v5 `[FIX 2]`/rate-limiter/K_session-
  vs-session_root_key/es-se/§1 — retracted (v6).
- **v6 §5/§6/L332 "there is no separate `session_root_key` / all data/BTR keying references
  `session_root`"** — **retracted/corrected** to the two-level re-seed below. (v6's "`K_session` is
  retired" was correct and STAYS — `K_session` was an unused §5-Expand flat orphan and is distinct from
  the BTR `session_root_key`.)

---

## §AV — Adverse-Verdict Invariant (retained from v6, normative)

**No keyless/SECRET-less party — including an untrusted rendezvous — may cause ANY adverse user-visible
security verdict, pin mutation, contact-key-changed warning, re-pair prompt, or contact-sticky throttle
against an honest `possession_proven` contact on ANY path** (locally-initiated, inbound, or
rendezvous-redirected). Consequences (each MUST):

1. A **locally-initiated reconnect** whose identity-DH against the pinned key fails → neutral
   transport-level **`TAMPER/UNREACHABLE`** ("could not verify the peer; connection may be tampered or
   unreachable"), never `KEY_MISMATCH`/contact-key-changed/re-pair.
2. An **unauthenticated inbound** resolve-then-differ → **silent, rate-limited discard** (no alert, no
   pin mutation, no first-contact fall-through).
3. A **contact-key-changed** verdict is allowed **only after the peer cryptographically proves
   possession of the prior pinned identity private key** (identity-DH against the old key, **or** an
   old-key cross-certificate over the new key) — gated by `[CRYPTO-DECISION 1b]`, which MUST bind the
   new key to that proof (possession-of-old-key alone never authorizes a write to an unbound new key).
4. A keyless/SECRET-less failure MUST NOT drop, replace, or mutate the existing `possession_proven` pin.

§AV is formal-model obligation #0. The v6 review confirmed §AV holds on all paths and that removing the
prior hostile `key_mismatch` alert is a net security improvement, not a regression.

---

## Required future `PROTOCOL.md` delta (fork A, two-level re-seed — NOT applied in this gate)

**This gate does not edit `PROTOCOL.md`.**

- **Current wire (unchanged here):** the post-handshake data channel keys from `ee`. The BTR schedule
  (`PROTOCOL.md §16.3`) seeds its generation-0 root `session_root_key` with **`salt = EMPTY`,
  `ikm = ephemeral_shared_secret`** (L1078-1083); `session_root_key` then feeds `transfer_root_key` and
  the chain/message keys, is advanced by the inter-transfer DH ratchet (per-transfer forward secrecy),
  and is the subject of BTR-INV-01..11. Non-BTR direct AEAD keys from `ee`.
- **Proposed EA1 wire (fork A) — a surgical RE-SEED, not a flatten:**
  1. **Re-seed the BTR generation-0 root from the authenticated `session_root`:**
     `session_root_key = HKDF(ikm = session_root, info = "bolt-btr-session-root-v1")` **replacing** the
     current `salt=EMPTY`/`ikm=ephemeral_shared_secret` seed at §16.3 L1078-1083. **Restate BTR-INV-01**
     to root on the `session_root`-seeded `session_root_key`.
  2. **Retain everything downstream:** the BTR key hierarchy
     (`session_root_key → transfer_root_key → chain/message keys`), the inter-transfer DH ratchet,
     BTR-INV-01..11, and the per-transfer self-healing forward-secrecy intent (BTR-INV-05/09). **Only
     the generation-0 seed changes** from `ee` to `session_root`.
  3. **Non-BTR direct AEAD** keys from `session_root` (not bare `ee`).
  4. **Naming:** `session_root` (the handshake-derived data root, §6) and `session_root_key` (the BTR
     gen-0 ratchet root, §16.3) are **distinct, two-level** values. `K_session` (the former §5-Expand
     flat orphan) is **retired** and appears nowhere.
- **Why (corrects the v6 error):** fork A's benefit — a PRK-salt backstop against `ee`-recovery and a
  data root that is actually a function of the authenticated handshake — is achieved by re-seeding the
  ratchet's generation-0 root, **without** touching the ratchet that provides per-transfer forward
  secrecy. The v6 "flat `session_root` is the one root" wording is retracted.
- **Review scope:** the cryptographer / formal model review the **proposed** two-level schedule;
  obligation #6 asserts the BTR/data key is a **function of `session_root`** (via `session_root_key`),
  with the ratchet retained. Breaking change → major SDK bump; gated on sign-off + a future authorized
  spec gate. The existing `btr-key-schedule` / `btr-transfer-ratchet` conformance vectors
  (`PROTOCOL.md` L1464-1465) are updated for the new gen-0 seed only.

---

## §0 — Key validity (normative) ([LOW 3])

- Reject known small-order Curve25519 u-coords (implementation-derived set — libsodium/dalek — pinned
  under `[CRYPTO-DECISION 6]`, not an RFC 7748 §6.1 table).
- Reject non-canonical encodings at ingress (high-bit-set or u ≥ p).
- **Abort on all-zero DH output** (constant-time) on **`ee`, `es`, `se`, `ss`**.
- **[LOW 3] Clamped X25519 for all four DHs:** `ee`, `es`, `se`, `ss` are each computed by **clamped
  X25519** (RFC 7748 — secret scalars are clamped so `scalar ≡ 0 mod 8`). This clamping is the stated
  **completeness premise** that makes the all-zero abort a *self-sufficient* low-order/twist backstop:
  a low-order/small-subgroup input times a scalar that is a multiple of the cofactor 8 yields the
  identity → the all-zero output → abort. Named in formal obligation #3 so the reviewer can discharge
  the low-order/twist lemma; the CD6 blacklist is then belt-and-suspenders, not load-bearing.
- Identity + ephemeral keys, pairing + reconnect; a failing key is never used/pinned/`possession_proven`;
  pinned keys re-validated before every reconnect DH.

---

## §1 — Human-code UX + routing/secret (as v6)

Two separate API inputs; single-code split MUST execute in the SDK/harness-covered layer (or forbid
single-combined-code); SECRET-off-server = conforming-reference-client property + mandatory byte-scan
harness; **ROUTING fresh-per-refresh a normative MUST**, independent across refreshes (→ CD4a);
"confidential transport" = TLS-protected connection vs off-path eavesdroppers only (the rendezvous still
sees each ROUTING). CSPRNG independence: two separate reads + differential KAT + negative shared-seed.

---

## §2–§3 — Message sequence + transcript TT (as v6)

Symmetric `PAIR_INIT`/`PAIR_CONFIRM`; `TT` = canonical injective encoding (verified codec, CD5a); §0
validation on every received key.

---

## §4 — PAKE + identity-DH key schedule (as v6)

Pairing `ikm = k_pake ‖ ee ‖ es ‖ se ‖ ss`, `PRK = HKDF-Extract(salt = TT, ikm)`; reconnect
`ikm = ee ‖ es ‖ se ‖ ss`. Joint anti-reflection (equality reject over canonical encodings + TT identity
binding + the LOAD-BEARING direction-separated confirmation, §5). Noise pattern / es-se role convergence
BY WIRE ROLE (never sort) → CD1a; PAKE primitive → CD6.

---

## §5 — Key confirmation + naming + es/se test ([CORE naming], [LOW 2])

`PRK` → HKDF-Expand → **`K_conf_L`, `K_conf_R`** (+ optional `SAS_disp`). L/R = owner of the
lexicographically-smaller `side_id`, unsigned byte-wise, fail-closed on tie (+ a `≥0x80` boundary
vector); or wire-role per CD1a. Complement-verified, MUST-NOT try-both; receiver-confirms-last.

- **Naming (CORE correction):** the §5 HKDF-Expand produces **only** `K_conf_L/R` (+ optional
  `SAS_disp`); the flat `K_session` orphan is **retired**. This is **separate from** the BTR
  `session_root_key`: the data/BTR root is `session_root_key` (§16.3, re-seeded from `session_root`
  under fork A — see the delta), which is **retained**, not retired. `K_session ≠ session_root_key`.
- **[LOW 2] es/se sort-discrimination test (wire-role negative):** the golden-vector obligation is a
  **wire-role** role-swap negative — **"swap initiator↔responder ⇒ the `es`/`se` labels transpose ⇒
  the derived `PRK` MUST differ."** This is invariant under any sort basis/direction **and** decoupled
  from the §5 confirmation-role L/R basis (so it neither false-fails a sorted-`side_id` impl nor passes
  a signed-descending sort — the two defects of the v6 form). `es` and `se` are each one shared value,
  not per-role; the negative asserts the wire-role ORDER in `ikm` is load-bearing.

---

## §6 — Session root binding (FORK A, two-level) ([CORE], [LOW 4])

- `ephemeral_shared_secret := ee := X25519(own PAIR_INIT ephemeral private, peer PAIR_INIT ephemeral
  public)` (clamped, §0); one session ephemeral per side = the PAIR_INIT ephemeral; well-typed binding
  `PAIR_INIT.ephemeral_key` MUST be the public key whose private half computes `ee` and MUST equal the
  `sender_ephemeral_key` of every post-handshake envelope, fail-closed before `HANDSHAKE_COMPLETE`.
- **[FORK A] `session_root = HKDF(salt = PRK, ikm = ephemeral_shared_secret, info = "bolt-pake-v7
  session-root" ‖ TT/domain labels)`.** `salt` MUST be `PRK`.
- **[CORE] `session_root` seeds the BTR ratchet, it does not replace it:** under the proposed schedule,
  `session_root` re-seeds the generation-0 BTR root —
  `session_root_key = HKDF(ikm = session_root, info = "bolt-btr-session-root-v1")` — which then drives
  `transfer_root_key → chain/message keys` through the **retained** inter-transfer DH ratchet
  (BTR-INV-01..11, per-transfer forward secrecy intact). Non-BTR direct AEAD keys from `session_root`.
  (The wire change is the future `PROTOCOL.md` delta above; this gate does not edit it.)
- **Confidentiality chain (both paths):** pairing — no SECRET ⇒ no `k_pake` ⇒ no `PRK` ⇒ no
  `session_root` ⇒ no `session_root_key` ⇒ no data/BTR keys; reconnect — no identity/ephemeral privates
  ⇒ no `es`/`se`/`ss` ⇒ no `PRK` ⇒ no `session_root` (a failed reconnect DH surfaces neutrally per §AV,
  before any data envelope). The PRK salt backstops `ee`-recovery **without** disturbing the ratchet.
- **Channel binding [LOW 4]:** native exporters fold locally (require-binding floor); browsers rely on
  `session_root`(secret PRK salt) + identity-DH, genuine under fork A. The **exporter/tier-select
  capability signal MUST be carried in `capabilities[]`/TT** (under the §5 confirmation MAC) so it is
  **non-forceable** by an on-path party (restores the v6-dropped pin). Exporter choice + mixed
  native↔browser reconciliation → `[CRYPTO-DECISION 7a]`.

---

## §7 — Downgrade floor (as v6)

Pairing floor bound to the human code ceremony + unstrippable PAKE-capable marker, default require-PAKE
ON. Reconnect: a `possession_proven` pin makes identity-DH reconnect mandatory and non-overridable;
legacy / BTR→static forbidden for a `possession_proven` contact, fail-closed; floor from the
authenticated identity-DH result, not MITM-mutable HELLO caps.

---

## §8 — One-time code consumption (as v6)

One-guess-per-displayed-code; single-flight; device-wide backoff LOCAL-ONLY (typer's value-keyed
attempts, never anonymous inbound, no penalty from consumed-code count). Availability DoS stated
honestly (a learned non-secret ROUTING can deny pairing availability by burning displayed codes through
an honest rendezvous — permanent/deterministic/stealthy for a continuing-visibility attacker);
mitigation = ROUTING fresh-per-refresh; quantitative budget → CD2a. Typer consumes SECRET by value at
confirm-exposure; refuses re-entry; value-keyed lockout.

---

## §9 — Pins + reconnect (a consequence of §AV) ([LOW 1])

- **`PinRecord v7`:** `{ pin_format: 7, contact_id (KEY, CSPRNG local), reconnect_handle (CSPRNG-minted,
  local/contact-scoped, not peer-choosable, high-entropy, locally-unique-on-write), identity_key
  (COMPARED value), pake_profile, bound_via, possession_proven, first_paired_at, transcript_hash?,
  device_label }`.
- **Reconnect outcomes (governed by §AV):** success (peer proves possession of the **pinned** key via
  identity-DH → `reconnect_authenticated`); locally-initiated DH failure → neutral `TAMPER/UNREACHABLE`
  (no `KEY_MISMATCH`, no re-pair, no pin mutation); unauthenticated inbound resolve-then-differ →
  **silent, rate-limited discard**; unpinned inbound → first-contact. A **legitimate key rotation** is
  the ONLY "device key updated" event — gated by `[CRYPTO-DECISION 1b]` (prior-key proof binding the new
  key; interim = new-contact-only or old-key cross-cert; no human-confirm-only overwrite).
- **[LOW 1] Rate-limiter scope + honesty:**
  - **(Retained, verbatim):** anonymous-inbound failures MUST NOT throttle/drop/delay a subsequent
    **handshake-completing** reconnect on the same `reconnect_handle`; any handle/contact-scoped budget
    accrues **only after identity-DH completion**; a garbage key / failing DH consumes **no
    contact-sticky budget**. (This is the genuine v5-#2 fix; "resolves the contradiction" is scoped
    strictly to that v5 budget-scope inconsistency.)
  - **(Corrected honesty):** we do **NOT** claim a global anti-spam cap can *never* shed a
    would-be-valid future connection — validity is only knowable **post-DH**, so pre-admission the cap
    is **best-effort**, not absolute. **Honest availability disclosure (mirrors §8):** a keyless party
    (including the untrusted rendezvous) that knows the wire-visible `reconnect_handle` **can degrade
    honest reconnect availability** via a pre-DH connection-slot / scalar-mult (identity-DH CPU) flood,
    through an honest rendezvous. This is an **availability** concern (not an adverse *verdict* — §AV is
    untouched, and no pin mutates). The quantitative pre-DH flood budget — a stateless retry-cookie,
    a per-handle connection-admission cap, and/or proof-of-work — is `[CRYPTO-DECISION 2a]`
    (availability in scope), scoped best-effort given the CD1b concurrent-reconnect-atomicity ↔
    no-shed-a-valid-handshake tension.
- **CD1a contingency (inline):** whether a distinct verdict token exists depends on CD1a (strict-KK ⇒ a
  failed reconnect is a generic MAC failure = the neutral state; static-carrying ⇒ neutral via §AV) —
  both branches yield the neutral state and satisfy §AV.
- `reconnect_handle` linkability (metadata-only) → reconciled (rotating/blinded) under CD1c (MUST NOT
  absorb §AV). Migration transactional; old pins ignored for trust (EA29); `pin_format`
  byte-distinguishable; no mass reset.

---

## §10 — Product states (honest, NO "verified") (as v6)

`unverified` · `approved_for_session` · `code_confirmed` · `reconnect_authenticated` ·
**`tamper_unreachable`** (neutral transport-failure — not a contact-key-changed claim, no pin mutation,
no re-pair prompt) · `pake_failed` · `legacy` (never "verified"). The hostile product-facing
`key_mismatch` alert is REMOVED; a genuine key change is only the CD1b-gated "device key updated" flow.
No product-facing "verified" claim. Transfer gate on the receive path. Anti-phishing UX unchanged.

---

## Remaining cryptographer decisions ([CRYPTO-DECISION])

| Tag | Decision |
|---|---|
| 1a | Reconnect KK strict-vs-static-carrying (both → §AV neutral) + named Noise pattern + DH set/mixing order + PAKE⊕Noise composition + converge es/se BY WIRE ROLE (never sort) + one L/R confirmation-role basis coincident with the es/se order |
| 1b | Rotation continuity — the SOLE "device key updated" path: MUST **bind K_new** to the K_old-authenticated proof (transcript-bind or cross-cert over K_new) so possession-of-old-key alone never writes an unbound new key; prefer new-contact-only + inline KCI/PCS caveat; es/se KCI scope; rotation-write vs concurrent-reconnect atomicity |
| 1c | Reconnect cadence + cloned-key detection/revocation + `reconnect_handle` unlinkability (rotating/blinded) + app-auto-vs-human alert-gating + an additive-on-top-of-§AV responded-vs-unreachable split with bounded honest non-attributed OOB re-verify; MUST NOT absorb §AV |
| 2a/2b | Lockout parameters + quantitative guessing-infeasibility budget **with availability in scope** (incl. reconnect pre-DH flood: retry-cookie / per-handle admission cap / PoW) + a shower-enforced-atomic single-flight/consume pin |
| 4a | ROUTING grammar + anti-bleed MUST + SECRET entropy/MHF + fresh-ROUTING independence + confusable/non-ASCII normalization |
| 5a | Injective byte-layout freeze via a verified codec + cross-impl decoder equivalence (single split-in-SDK collapses to one impl) |
| 6 | PAKE primitive (CPace primary vs SPAKE2-0.4.0 vs SPAKE2+) + internal point/cofactor/encoding validation; clamped X25519 (§0) makes the deferred blacklist belt-and-suspenders + unaudited/not-constant-time HIGH sign-off |
| 7a | Native exporter + fold-locally + mixed native↔browser reconciliation; the tier-select signal is bound in `capabilities[]`/TT (non-forceable) — do NOT ship a soft browser-tier-default that accepts an unauthenticated tier signal; discharge the browser identity-DH-suffices lemma |

## Formal-model obligations (wire-freeze gate)

Modeled against the **proposed** two-level EA1 schedule (fork A). No wire-freeze until it passes:

0. **[§AV]** A Dolev-Yao / untrusted-rendezvous / keyless / SECRET-less attacker cannot cause any
   adverse user-visible verdict, pin mutation, contact-key-changed warning, re-pair prompt, or
   contact-sticky throttle against an honest `possession_proven` contact on ANY path.
1. Pairing handshake: PAKE + §4 DH schedule + TT + confirmation.
2. Reconnect / KK path — entity auth requires identity-key **possession**.
3. **[LOW 3]** Point-validity under **clamped X25519** (secret scalars ≡ 0 mod 8): `DH(low-order,·)=0`
   rejected by §0's all-zero abort; clamping named as the completeness premise. Byte-level non-canonical
   rejection is NOT a symbolic obligation (no byte layer) — §0 wire rule + wire tests + codec proof.
4. **[LOW 1]** Consumption/lockout: one-guess-per-displayed-code; device-wide backoff never from
   anonymous inbound nor consumed-code count; **contact-scoped budget accrues only post-identity-DH; a
   failing DH consumes no contact-sticky budget** — an availability sub-lemma of §AV (the pre-DH
   availability flood is a best-effort CD2a lever, not a modeled absolute).
5. Reflection/UKS resistance given a direction-separated confirmation + the negative obligation.
6. **[FORK A / CORE]** `session_root` secrecy AND the data/BTR key is a **function of `session_root`
   via the re-seeded `session_root_key`** (the BTR ratchet + BTR-INV-01..11 retained), both paths;
   substitute-data-ephemeral → cryptographic fail; ephemeral entity agreement.
7. **[§AV/FIX 2]** Reconnect resolution: a failed identity-DH (any path) → neutral `TAMPER/UNREACHABLE`,
   no hostile verdict, no pin mutation; a key-change verdict requires prior-key possession (binding
   K_new).
8. Reconnect-downgrade resistance (`possession_proven` non-overridable).
9. Legacy/conforming-typer-leak: SECRET never in a rendezvous-facing message for a conforming reference
   client (structural + harness); non-conforming out of scope.
10. Three transport configs. Ideal-PAKE/ideal-DH + injective serialization as **assumed premises**;
    computational PAKE⊕Noise composition to a separate reductionist sign-off (1a); quantitative
    guess+availability budget (2a) separate. **Scope note (safety-only):** obligations #0/#7 certify the
    *safety* half (no false/keyless verdict); **positive detection** (a prior-key-proven rotation MUST
    eventually surface "device key updated") is deferred to CD1b, and cloned/exfiltrated-key detection
    to CD1c; `reconnect_handle` privacy is NOT certified here → CD1c.

## Test obligations

- **Cross-impl golden vectors (Rust ↔ WASM, byte-identical):** normalization; TT codec (both
  directions); `ikm`/`PRK` byte assembly; HKDF outputs; `K_conf_L/R`; **`session_root`, the re-seeded
  `session_root_key = HKDF(ikm=session_root, …)`, and the two-level `session_root → session_root_key →
  transfer_root_key` schedule (fork A) — the ratchet + per-transfer FS retained** (update the existing
  `btr-key-schedule`/`btr-transfer-ratchet` vectors for the new gen-0 seed only).
- **[LOW 2]** es/se **wire-role** role-swap negative: swap initiator↔responder ⇒ `es`/`se` transpose ⇒
  PRK MUST differ (invariant under sort basis/direction; decoupled from confirmation-role L/R).
- **[§5 L/R]** first-differing-byte `≥0x80` `side_id` pair (unsigned-basis regression).
- **[LOW 3]** clamped-X25519 on `ee/es/se/ss`; low-order/high-bit-flip/all-zero abort.
- **[§AV]** keyless rendezvous redirecting a locally-initiated reconnect → neutral `TAMPER/UNREACHABLE`,
  no contact-key-changed alert, no re-pair prompt, no pin mutation; anonymous inbound → silent discard;
  all three paths.
- **[LOW 1]** anonymous-inbound flood on a handle → does not throttle/drop/delay a subsequent
  handshake-completing reconnect; garbage/failing-DH → no contact-sticky budget; pre-DH flood exercises
  the CD2a lever (best-effort, disclosed).
- **[FORK A]** substitute-data-ephemeral → cryptographic decrypt-fail (data roots on `session_root` via
  `session_root_key`).
- Carry all v6 vectors: differential CSPRNG + negative shared-seed; symmetric-confirmation negative;
  conforming-client → malicious-server byte-scan harness + mis-split fuzz.

## Hard boundaries

- **No implementation. No `PROTOCOL.md`/protocol-spec edits in this gate. No wire-freeze. No spike
  merge. No "verified" product behavior.** The `bolt-spake2-spike` crate stays inert; old "verified"
  stays disabled (EA29).
- Fork A's wire change (the two-level re-seed) is a **proposed future delta**, applied only in a
  separately-authorized spec gate after cryptographer + formal-model sign-off.
- Wire-freeze is FORBIDDEN until every `[CRYPTO-DECISION]` resolves, the required `PROTOCOL.md` delta is
  authorized + applied, the external cryptographer signs off, and the formal model (incl. §AV) passes.

## Next (not authorized here)

A seventh UltraCode adversarial pass is recommended. If it returns ACCEPTABLE-FOR-CRYPTOGRAPHER-REVIEW,
EA1 becomes the external-review package: the cryptographer + formal-methods reviewer evaluate the
proposed two-level EA1 schedule (fork A), §AV, and the `[CRYPTO-DECISION]` set; a future spec gate
applies the `PROTOCOL.md` delta; wire-freeze remains the gated exit.
