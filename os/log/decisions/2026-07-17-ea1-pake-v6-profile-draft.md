# Decision: EA1 PAKE v6 Protocol Profile — Revised Draft

> **Date:** 2026-07-17
> **Status:** **DRAFT — PROPOSED. NOT WIRE-FROZEN. NOT IMPLEMENTATION-AUTHORIZED. NO "verified"
> PRODUCT BEHAVIOR.** Adds the **class-level Adverse-Verdict Invariant** (§AV), fixes the two v5
> `KEY_MISMATCH` MEDIUMs, and lands the v5 LOW cleanups. Retains **§6 fork A** (data/BTR keys derive
> from the authenticated `session_root` — a future `PROTOCOL.md` delta, below). Supersedes-in-specifics
> the v5 draft (`os/log/decisions/2026-07-17-ea1-pake-v5-profile-draft.md`, PROPOSED — NEEDS REVISION),
> retained verbatim. EA1 remains **OPEN**. Contains open items that REQUIRE an external cryptographer —
> marked **[CRYPTO-DECISION]** — and a **required future `PROTOCOL.md` delta**; it cannot be wire-frozen
> until those resolve.
> **Scope repos:** `bolt-protocol` (future spec — see the required delta), `bolt-core-sdk` (future
> SDK), products — all future, all gated.
> **Lineage:** direction ADR → v1 → v2 → v3 → v4 → v5 (all superseded-in-specifics) → **this v6 draft.**
> Evidence: `docs/evidence/EA1_REDTEAM.md`, `docs/evidence/PAKE_EVAL.md`,
> `docs/evidence/EA1_PAKE_PROFILE_REDTEAM.md`, `docs/evidence/EA1_PAKE_V2_REDTEAM.md`,
> `docs/evidence/EA1_PAKE_V3_REDTEAM.md`, `docs/evidence/EA1_PAKE_V4_REDTEAM.md`,
> `docs/evidence/EA1_PAKE_V5_REDTEAM.md`.

## What v6 changes

The five prior passes kept finding the **same class** on a new path each time: an untrusted /
keyless party causing an *adverse verdict or state* against an honest contact (v4 §8 anonymous inbound;
v5 §9 rendezvous-redirected locally-initiated + the rate-limiter sibling). v6 stops patching path-by-path
and states the invariant **once** (§AV), then makes §9 a consequence of it.

| Area | v6 change |
|---|---|
| **§AV (NEW)** | **Adverse-Verdict Invariant** — no keyless/SECRET-less party may cause any adverse user-visible verdict, pin mutation, contact-key-changed warning, re-pair prompt, or contact-sticky throttle against an honest `possession_proven` contact on ANY path. |
| §9 [FIX 2] | Neutral locally-initiated failure (TAMPER/UNREACHABLE), never a contact-key-changed/re-pair verdict; FIX-9 satisfied by §AV, not path-specific logic. |
| §9 rate-limiter | Anonymous-inbound failures never throttle/drop/delay a later handshake-completing reconnect on the same handle; contact-scoped budget accrues only post-identity-DH; a failing DH consumes no contact-sticky budget. |
| §5/§6 naming | `session_root`/`session_root_key`/`K_session` collision resolved in-draft. |
| §4/test | es/se vectors: both `es>se` and `es<se` (or a role-swap negative). |
| §1 split | Single-code split pinned to the SDK/harness-covered layer (or forbid single-combined-code). |
| §1 ROUTING | Fresh-per-refresh is a normative MUST; "confidential transport" defined. |
| §9/obl.#7 | CD1a strict-vs-static-KK contingency echoed inline; "proves possession of the prior key" defined. |
| §6 | Fork A retained (future `PROTOCOL.md` delta). |

### Claims retracted/corrected across the lineage

- v1 lines 89/150/164 + "Closes … EA16" — retracted (v2).
- v2 §1/§4/§6/§7/§9 — retracted (v3). v3 §8/§6/§1/§4/§9 — retracted (v4). v4 §6/§9/§8/§0/obl.#3 —
  retracted/corrected (v5 + fork A).
- **v5 `[FIX 2]` "the `reconnect_handle` cannot summon a forged alert (satisfies FIX-9)"** — **retracted**:
  the per-path claim was false (an untrusted rendezvous redirects a locally-initiated reconnect). It is
  replaced by **§AV**, which satisfies the property on all paths structurally.
- v5 FIX-1 "rate-limited discard / connection-scoped" inconsistency — corrected (§9 rate-limiter scope).
- v5 §5 `K_session` orphan / naming collision — resolved (§5/§6 naming).
- v5 `[FIX 9]` single-vector es/se test — corrected (both vectors). v5 §1 fresh-per-refresh prose-only —
  corrected (§1 MUST).

---

## §AV — Adverse-Verdict Invariant (NEW, normative — the core of v6)

**No keyless/SECRET-less party — including an untrusted rendezvous — may cause ANY adverse
user-visible security verdict, pin mutation, contact-key-changed warning, re-pair prompt, or
contact-sticky throttle against an honest `possession_proven` contact on ANY path** (locally-initiated,
inbound, or rendezvous-redirected).

Normative consequences (each MUST):

1. **Neutral failure, not a contact verdict.** A **locally-initiated reconnect** whose identity-DH
   against the pinned key fails — for any reason a keyless party can induce (redirection, substitution,
   tamper) — MUST surface as a **neutral transport-level `TAMPER/UNREACHABLE` ("could not verify the
   peer; the connection may be tampered with or the peer is unreachable")** state. It MUST NOT surface
   as `KEY_MISMATCH`, "your contact changed their key," or a re-pair prompt. Rationale: the local side
   expected the pinned key; a failed identity-DH is indistinguishable (to it) from a MITM, and only a
   party proving the prior key could legitimately assert a key change (consequence 3).
2. **Silent inbound.** An **unauthenticated inbound** resolve-then-differ MUST be a **silent,
   rate-limited discard** (no alert, no pin mutation, no first-contact fall-through).
3. **A key-change verdict requires prior-key possession.** `KEY_MISMATCH` / "contact-key-changed" as a
   user-surfaced verdict is allowed **only after the peer cryptographically proves possession of the
   prior pinned identity private key** (an authenticated rotation), **or** under a cryptographer-approved
   **strict-KK / cross-cert** path (`[CRYPTO-DECISION 1a]`/`1b`). A keyless/SECRET-less party cannot
   satisfy this, so it can never trigger the verdict.
4. **Never mutate the pin on a keyless failure.** A keyless/SECRET-less failure MUST NOT drop, replace,
   or mutate the existing `possession_proven` pin. Pin mutation happens only via the CD1b-gated rotation
   flow (prior-key proof) or an explicit human unpair.

§AV is a **formal-model obligation** (below) and is what satisfies the property the v5 `[FIX 2]`
per-path claim tried and failed to establish. "**Cryptographically proves possession of the prior
pinned key**" (consequences 3-4) is defined as: the peer authenticates using the **old pinned identity
private key** — either by completing the identity-DH against the *old pinned* key, or by an old-key
signature / cross-certificate over the new key — the **sole** mechanism authorizing a key-change/rotation
verdict; the full continuity design is `[CRYPTO-DECISION 1b]`.

---

## Required future `PROTOCOL.md` delta (fork A — NOT applied in this gate)

**This gate does not edit `PROTOCOL.md`.** (Retained verbatim in intent from v5.)

- **Current wire:** `PROTOCOL.md` keys the post-handshake data channel from `ee` alone (non-BTR
  direct-ee L197/L1441; BTR §16.3 `salt=EMPTY`; BTR-INV-01 roots on `ee`).
- **Proposed EA1 wire (fork A):** post-handshake data/BTR keys MUST derive from
  `session_root = HKDF(salt = PRK, ikm = ephemeral_shared_secret, info = TT/domain labels)`. Deltas:
  (1) BTR root §16.3 `salt=EMPTY` → `session_root`, restate BTR-INV-01; (2) non-BTR direct AEAD →
  `session_root`; (3) resolve the naming so `session_root` is the one authoritative data-channel root.
- **Review scope:** the cryptographer / formal model review the **proposed** `session_root`-rooted
  schedule, not the old `ee`-rooted wire; obligation #6 asserts the data key is a function of
  `session_root`. Breaking change → major SDK bump; gated on sign-off + a future authorized spec gate.

---

## §0 — Key validity (normative)

- Reject known small-order Curve25519 u-coords (implementation-derived set — libsodium/dalek — pinned
  under `[CRYPTO-DECISION 6]`, **not** an RFC 7748 §6.1 table).
- Reject non-canonical encodings at ingress (high-bit-set or u ≥ p).
- **All-zero-DH abort** (constant-time; RFC 7748 §6.1/§7 guidance) on `ee`/`es`/`se`/`ss` — the
  self-sufficient low-order backstop.
- Identity + ephemeral keys, pairing + reconnect; a failing key is never used/pinned/`possession_proven`;
  pinned keys re-validated before every reconnect DH.

---

## §1 — Human-code UX + routing/secret

- One-sided entry; **two separate API inputs** — ROUTING is the only value the signaling/mailbox API
  accepts; SECRET goes only to a dedicated PAKE-password input that is not a parameter of any
  rendezvous-facing call.
- **Single-code split location pinned (LOW cleanup):** if a single displayed code is offered, the split
  into (ROUTING, SECRET) **MUST execute in the SDK / harness-covered layer** — products pass the raw
  combined code to the SDK and never touch SECRET or the split (so deployed first-party products
  inherit the SECRET-off-server property and the byte-scan harness covers them, collapsing the CD5a
  cross-impl split risk to one implementation). **Or** products MUST forbid single-combined-code
  delivery (two-separate-inputs only, fully structural).
- **SECRET-off-server is a conforming-reference-client property**, enforced by the split API **and** a
  mandatory runtime byte-scan conformance harness (across Rust/WASM/TS reference clients, both delivery
  modes, + a mis-split fuzz vector); not a guarantee over arbitrary/forked clients (out of scope).
- **ROUTING lifecycle (LOW cleanup, normative MUST):** a **fresh ROUTING MUST be minted per code
  refresh**, independent across refreshes (independence precondition → `[CRYPTO-DECISION 4a]`), so a
  burned/abandoned code yields a new ROUTING. **"Confidential transport"** is defined as the
  TLS-protected rendezvous connection / peer channel that protects ROUTING from **off-path
  eavesdroppers**; it explicitly does **NOT** protect against the rendezvous's own continuing
  mailbox-visibility (the rendezvous sees ROUTING by definition — see §8's honest availability note).
- CSPRNG independence: two separate CSPRNG reads; differential KAT + a negative shared-seed reference
  that MUST fail. ROUTING length/format constant. Grammar/anti-bleed/MHF → `[CRYPTO-DECISION 4a]`.

---

## §2–§3 — Message sequence + transcript TT

As v5: symmetric `PAIR_INIT` (`side_id`, `pake_msg`, `identity_key`, `ephemeral_key`, `bolt_version`,
`capabilities[]`) then `PAIR_CONFIRM`; `TT` = canonical injective encoding of both PAIR_INITs (verified
codec, `[CRYPTO-DECISION 5a]`). §0 validation on every received key before use.

---

## §4 — PAKE + identity-DH key schedule

**Pairing:** `ikm = k_pake ‖ ee ‖ es ‖ se ‖ ss`, `PRK = HKDF-Extract(salt = TT, ikm)`.
**Reconnect:** `ikm = ee ‖ es ‖ se ‖ ss` (no `k_pake`). Every DH §0-validated. Anti-reflection is
**joint** (equality reject over canonical encodings + TT identity binding + the mandatory LOAD-BEARING
direction-separated confirmation, §5). Noise pattern / es-se role convergence (by wire role, never sort)
→ `[CRYPTO-DECISION 1a]`; PAKE primitive → `[CRYPTO-DECISION 6]`.

---

## §5 — Key confirmation + naming ([naming cleanup])

`PRK` → HKDF-Expand → **`K_conf_L`, `K_conf_R`** (+ optional `SAS_disp`). L/R = owner of the
lexicographically-smaller `side_id`, compared **unsigned byte-wise** over the canonical `side_id`
encoding, fail-closed on tie (+ a `≥0x80` boundary golden vector); or assign L/R by deterministic wire
role per `[CRYPTO-DECISION 1a]` ("never sort"). Complement-verified, **MUST-NOT** try-both;
receiver-confirms-last.

- **Naming resolution (LOW cleanup):** the data-channel root is **`session_root`** (§6, fork A) — the
  single authoritative name. §5 produces **only** the confirmation keys (`K_conf_L/R`) and the optional
  `SAS_disp`. The prior **`K_session` name is RETIRED** (it was an unused orphan; there is no separate
  `session_root_key`). All data/BTR keying references `session_root`.
- **es/se test (LOW cleanup):** the sort-discriminating obligation requires **two** vectors — one
  `es>se` and one `es<se` (unsigned byte-wise) — **or** a role-swap negative assertion (swap L↔R ⇒ PRK
  MUST differ; a value-sort is role-swap-invariant and fails). A single vector cannot catch a
  descending-sort impl. (`es` and `se` are each one shared value, not per-role.)

---

## §6 — Session root binding (FORK A)

- `ephemeral_shared_secret := ee := X25519(own PAIR_INIT ephemeral private, peer PAIR_INIT ephemeral
  public)`; exactly one session ephemeral per side = the PAIR_INIT ephemeral (never a transport
  ephemeral); well-typed binding: `PAIR_INIT.ephemeral_key` MUST be the public key whose private half
  computes `ee` and MUST equal the `sender_ephemeral_key` of every post-handshake envelope, fail-closed
  before `HANDSHAKE_COMPLETE`.
- **[FORK A] `session_root = HKDF(salt = PRK, ikm = ephemeral_shared_secret, info = "bolt-pake-v6
  session-root" ‖ TT/domain labels)`.** `salt` MUST be `PRK`. Post-handshake data/BTR keys derive from
  `session_root` (the required `PROTOCOL.md` delta above) — it is the actual data-channel root under the
  proposed schedule, not a computed-but-unused value.
- **Confidentiality chain (both paths):** pairing — no SECRET ⇒ no `k_pake` ⇒ no `PRK` ⇒ no
  `session_root`; reconnect — no identity/ephemeral private keys ⇒ no `es`/`se`/`ss` ⇒ no `PRK` ⇒ no
  `session_root` (and a failed reconnect DH surfaces neutrally per §AV, before any data envelope). The
  PRK salt backstops `ee`-recovery.
- **Channel binding:** native exporters fold locally (require-binding floor); browsers rely on the
  `session_root`(secret PRK salt) + identity-DH, genuine under fork A. Exporter + mixed reconciliation →
  `[CRYPTO-DECISION 7a]`.

---

## §7 — Downgrade floor: pairing + reconnect

As v5: pairing floor bound to the human code ceremony + unstrippable PAKE-capable marker, default
require-PAKE ON. Reconnect: a `possession_proven` pin makes identity-DH reconnect mandatory and
non-overridable; legacy / BTR→static forbidden for a `possession_proven` contact, fail-closed; floor
from the authenticated identity-DH result, not MITM-mutable HELLO caps.

---

## §8 — One-time code consumption

- One-guess-per-displayed-code (an inbound failed `PAIR_CONFIRM` consumes the displayed code; shower
  prompts a fresh code). Single-flight; incomplete exchange returns the slot to LIVE.
- **Device-wide backoff is LOCAL-ONLY** — from the typer's own locally-initiated, value-keyed attempts;
  never from anonymous inbound; **no device penalty from consumed-code count.**
- **Availability DoS — stated honestly, NOT "acceptable":** a party who learns the non-secret ROUTING
  can deny pairing availability by burning displayed codes (a garbage confirm needs no SECRET), through
  an honest rendezvous — a **permanent, deterministic, stealthy** sustained-DoS variant for a
  continuing-visibility attacker, or a one-shot burn for a one-time observer. Mitigation: **ROUTING is
  minted fresh per refresh** (§1 MUST) over confidential transport (off-path eavesdroppers only — the
  rendezvous still sees each ROUTING, so a room-present attacker retains the channel). The quantitative
  availability / rate-limit / guesses-per-code budget → `[CRYPTO-DECISION 2a]` (availability in scope).
- Typer consumes the typed SECRET by value at confirm-exposure; refuses re-entry of a consumed value;
  local value-keyed lockout.

---

## §9 — Pins + reconnect (a consequence of §AV)

- **`PinRecord v6`:** `{ pin_format: 6, contact_id (KEY, CSPRNG local handle), reconnect_handle
  (CSPRNG-minted, local/contact-scoped, not peer-choosable, high-entropy, locally-unique-on-write),
  identity_key: [32]u8 (COMPARED value), pake_profile, bound_via, possession_proven: bool,
  first_paired_at, transcript_hash?, device_label }`.
- **Reconnect outcomes (all governed by §AV):**
  - **Success:** peer proves possession of the **pinned** identity private key via the identity-DH →
    authenticated `reconnect_authenticated`.
  - **Locally-initiated, DH fails [FIX 2]:** → neutral **`TAMPER/UNREACHABLE`** ("couldn't verify the
    peer; connection may be tampered/unreachable"). **NOT** `KEY_MISMATCH`, **not** "contact key changed,"
    **not** a re-pair prompt, **no pin mutation.** (This is the v5 rank-1 fix, generalized by §AV. We no
    longer claim any per-path "cannot summon a forged alert" — §AV covers it.)
  - **Unauthenticated inbound, resolve-then-differ:** → **silent, rate-limited discard** (no alert, no
    pin mutation, no first-contact fall-through).
  - **Legitimate key rotation:** the ONLY path to a user-surfaced "device key updated" event — the peer
    **proves possession of the prior pinned key** (identity-DH against the old key, or an old-key
    cross-cert) → gated by `[CRYPTO-DECISION 1b]`; interim = new-contact-only or old-key cross-cert; a
    single human confirmation MUST NOT overwrite a `possession_proven` pin.
- **Rate-limiter scope (rate-limiter fix, normative):** anonymous-inbound failures **MUST NOT throttle,
  drop, or delay a subsequent handshake-completing reconnect on the same `reconnect_handle`.** Any
  handle/contact-scoped budget accrues **only after identity-DH completion** (i.e., from authenticated
  peers); a garbage key / failing DH consumes **no contact-sticky budget** (at most a global anti-spam
  cap that never sheds a connection completing a valid handshake). This satisfies the §AV
  "no contact-sticky throttle" clause and resolves the v5 "rate-limited vs connection-scoped"
  contradiction.
- **CD1a contingency echoed inline:** whether a *distinct* verdict token exists at all depends on
  `[CRYPTO-DECISION 1a]` (strict-KK ⇒ a failed reconnect is a generic Noise MAC failure = the neutral
  `TAMPER/UNREACHABLE` state; static-carrying ⇒ the same neutral state via §AV). **Both branches yield
  the neutral state and satisfy §AV** — no hostile verdict, no pin mutation, on either.
- `possession_proven` set only after §0 validation + §4 DH confirmation. `reconnect_handle` linkability
  (a stable wire-visible handle lets the rendezvous link a pair's reconnects; metadata-only) → reconciled
  (rotating/blinded) under `[CRYPTO-DECISION 1c]`, which MUST NOT be read as absorbing §AV. Migration
  transactional; old pins ignored for trust (EA29); `pin_format` byte-distinguishable; no mass reset.

---

## §10 — Product states (honest, NO "verified")

`unverified` (block-default) · `approved_for_session` · `code_confirmed` (same-code + private-key
possession; persistent pin only with explicit "remember this device") · `reconnect_authenticated` ·
**`tamper_unreachable`** (NEW — a reconnect that failed to verify the peer; a **neutral transport-level**
state, **not** a contact-key-changed claim, no pin mutation, no re-pair prompt; the product surfaces
"couldn't reach/verify this device — retry", per §AV) · `pake_failed` (pairing) · `legacy`
(policy-gated, never "verified"). **The hostile product-facing `key_mismatch` alert of prior drafts is
REMOVED** — a genuine key change is only ever the CD1b-gated "device key updated" flow (prior-key proof),
never triggerable by a keyless party. No product-facing "verified" claim. Transfer gate on the receive
path. Anti-phishing UX unchanged.

---

## Remaining cryptographer decisions ([CRYPTO-DECISION])

| Tag | Decision |
|---|---|
| 1a | Reconnect KK strict-vs-static-carrying (both branches → §AV neutral state; also whether a distinct verdict token exists) + named Noise pattern + DH set/mixing order + PAKE⊕Noise composition + converge es/se BY WIRE ROLE (never sort) + domain separations |
| 1b | Identity-key rotation continuity — the SOLE mechanism for a "device key updated" verdict: prior-key possession (identity-DH vs old key, or old-key cross-cert); new-contact_id-on-loss; es/se KCI scope; rotation-write vs concurrent-reconnect atomicity |
| 1c | Reconnect cadence + cloned-key detection/revocation + `reconnect_handle` unlinkability (rotating/blinded); the app-auto-vs-human alert-gating policy; MUST NOT absorb §AV |
| 2a/2b | Lockout parameters + quantitative guessing-infeasibility budget **with availability in scope** + a shower-enforced-atomic single-flight/consume pin |
| 4a | ROUTING grammar + anti-bleed MUST + SECRET entropy/MHF + fresh-ROUTING independence-across-refreshes + confusable/non-ASCII normalization |
| 5a | Injective byte-layout freeze via a verified codec + cross-impl decoder equivalence (single split-in-SDK collapses this to one impl) |
| 6 | PAKE primitive (CPace primary vs SPAKE2-0.4.0 vs SPAKE2+) + internal point/cofactor/encoding validation + final small-order set + unaudited/not-constant-time HIGH sign-off |
| 7a | Native exporter + fold-locally + mixed native↔browser reconciliation with a non-forceable tier-select + soft browser-tier-default; browser identity-DH-suffices lemma |

## Formal-model obligations (wire-freeze gate)

Modeled against the proposed EA1 schedule (fork A). No wire-freeze until it passes:

0. **[§AV] Adverse-Verdict Invariant:** a Dolev-Yao / untrusted-rendezvous / keyless / SECRET-less
   attacker cannot cause ANY adverse user-visible verdict, pin mutation, contact-key-changed warning,
   re-pair prompt, or contact-sticky throttle against an honest `possession_proven` contact on ANY path
   (locally-initiated, inbound, redirected). A "device key updated" verdict requires prior-key
   possession.
1. Pairing handshake: PAKE + §4 DH schedule + TT + confirmation.
2. Reconnect / KK path — entity auth requires identity-key **possession**.
3. Point-validity: `DH(low-order,·)=0` rejected by §0's all-zero abort. **Byte-level non-canonical
   rejection is NOT a symbolic obligation** (no byte layer) — it is the §0 wire rule + wire tests + the
   codec proof (5a).
4. Consumption/lockout: one-guess-per-displayed-code; device-wide backoff never from anonymous inbound
   nor from consumed-code count; **contact-scoped budget accrues only post-identity-DH; a failing DH
   consumes no contact-sticky budget** (rate-limiter fix — a sub-lemma of §AV).
5. Reflection/UKS resistance **given** a direction-separated confirmation + the negative obligation.
6. **[FORK A]** `session_root` secrecy AND the data AEAD/BTR key is a **function of `session_root`**,
   both paths; substitute-data-ephemeral → cryptographic fail; ephemeral entity agreement.
7. **[§AV/FIX 2]** Reconnect resolution: a failed identity-DH (any path) → neutral `TAMPER/UNREACHABLE`,
   no hostile verdict, no pin mutation; a key-change verdict requires prior-key possession.
8. Reconnect-downgrade resistance (`possession_proven` non-overridable).
9. Legacy/conforming-typer-leak: for a conforming reference client, SECRET never in a rendezvous-facing
   message (structural at the API boundary + harness); non-conforming out of scope, not modeled.
10. Three transport configs. Ideal-PAKE/ideal-DH + injective serialization as **assumed premises**;
    computational PAKE⊕Noise composition to a separate reductionist sign-off (1a); quantitative
    guess+availability budget (2a) separate. `reconnect_handle` privacy NOT certified here → CD1c.

## Test obligations

- **Cross-impl golden vectors (Rust ↔ WASM, byte-identical):** normalization; TT codec (both
  directions); `ikm`/`PRK` byte assembly; HKDF outputs; `K_conf_L/R`; **`session_root` + the data/BTR
  key derived from it (fork A)**.
- **[§AV]** a keyless/SECRET-less rendezvous redirecting a **locally-initiated** reconnect → neutral
  `TAMPER/UNREACHABLE`, **no** contact-key-changed alert, **no** re-pair prompt, **no** pin mutation;
  an **anonymous inbound** resolve-then-differ → silent discard; verify on **all three paths**.
- **[rate-limiter]** an anonymous-inbound flood on a handle → does **not** throttle/drop/delay a
  subsequent handshake-completing reconnect on that handle; a garbage/failing-DH connection consumes
  **no** contact-sticky budget.
- **[§5 naming]** no `K_session`/`session_root_key` reference remains; data keys from `session_root`.
- **[es/se]** BOTH `es>se` and `es<se` vectors (or a role-swap negative) — a sorting impl MUST fail.
- **[§5 L/R]** a first-differing-byte `≥0x80` `side_id` pair (unsigned-basis regression).
- **[§1]** ROUTING fresh-per-refresh (distinct across refreshes); single-code split runs in the SDK
  layer; legacy/forked → malicious-server byte-scan harness + mis-split fuzz.
- **[FORK A]** substitute-data-ephemeral → cryptographic decrypt-fail.
- Carry all v5 vectors: low-order/high-bit-flip/all-zero; differential CSPRNG + negative shared-seed;
  symmetric-confirmation negative.

## Hard boundaries

- **No implementation. No `PROTOCOL.md`/protocol-spec edits in this gate. No wire-freeze. No spike
  merge. No "verified" product behavior.** The `bolt-spake2-spike` crate stays inert; old "verified"
  stays disabled (EA29).
- Fork A's wire change is a **proposed future delta**, applied only in a separately-authorized spec gate
  after cryptographer + formal-model sign-off.
- Wire-freeze is FORBIDDEN until every `[CRYPTO-DECISION]` resolves, the required `PROTOCOL.md` delta is
  authorized + applied, the external cryptographer signs off, and the formal model (incl. §AV) passes.

## Next (not authorized here)

A sixth UltraCode adversarial pass is recommended. If it returns ACCEPTABLE-FOR-CRYPTOGRAPHER-REVIEW,
EA1 becomes the external-review package: the cryptographer + formal-methods reviewer evaluate the
proposed EA1 schedule (fork A), the §AV invariant, and the `[CRYPTO-DECISION]` set; a future spec gate
applies the `PROTOCOL.md` delta; wire-freeze remains the gated exit.
