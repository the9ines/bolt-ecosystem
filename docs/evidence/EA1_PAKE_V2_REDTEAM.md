# EA1 PAKE v2 Draft — Adversarial Red-Team Report

> **Date:** 2026-07-16
> **Type:** Immutable evidence record (do not edit; corrections get their own dated entry).
> **Subject:** `os/log/decisions/2026-07-15-ea1-pake-v2-profile-draft.md` (the EA1 PAKE **v2** draft —
> the revision that addressed the v1 red-team's nine required changes).
> **Method:** UltraCode adversarial review (multi-agent, read-only). 11 red-teamers, one per named
> attack surface, each told to assume the design is wrong; every candidate break independently
> refuted by an adversarial verifier that sorted each into REFUTED / DEFERRED-TO-CRYPTOGRAPHER /
> CONFIRMED / PLAUSIBLE; one synthesis pass produced the verdict. **37 candidates → 12 refuted;
> of 25 survivors: 7 CONFIRMED, 5 PLAUSIBLE, 13 correctly DEFERRED-TO-CRYPTOGRAPHER.** 49 agents,
> 0 errors. (Workflow run `wf_78a33069-c62`.)

## Verdict: **HAS-BLOCKERS** — direction validated, blockers are fixable

This is a materially better result than the v1 review, not a dead end. The verdict is driven by **one
genuine, fixable new blocker plus two draft-fixable HIGHs** — all normative-spec changes, not
fundamental flaws. The review confirms v2 moved **all four** v1 blockers in the right design
direction and correctly retracted the three falsified v1 claims. **13 findings were correctly
deferred to the professional cryptographer** (properly-scoped open `[CRYPTO-DECISION]` items — they
do NOT count against the verdict). A green run is **not** available yet: the 8 required changes
(headlined by point-validation) must land in the draft before a cryptographer is the right next
reviewer.

## Are the v1 blockers closed?

All four moved in the correct direction; two of four are NOT closed *as written*:

- **Identity-PoP / reconnect public-key-match MITM** — direction right (identity-DH `ss/es/se` means
  reconnect no longer authenticates on a bare public-key match). **NOT closed as written:** the
  low-order-point BLOCKER (below) reopens it as a *permanent, universal, zero-secret* reconnect
  forgery — strictly worse than the v1 baseline.
- **One-guess code bound** — direction right and structurally far stronger (receiver-confirms-last +
  single-flight reject-not-queue + consume-on-attempt). Substantially addressed for confidentiality,
  with must-fix completeness gaps (typer-locus, unauthenticated-DoS, §2.3 false claim).
- **First-contact downgrade** — closed for *pairing* via the ceremony-bound floor + code-embedded
  marker. A reflection regression and an unaddressed *reconnect* downgrade remain.
- **Structural routing/secret** — right in intent; **NOT closed as written** for the legacy/
  version-skew actor v1 #4 named ("server can never receive SECRET" is an overclaim against an
  untrusted server).

## The BLOCKER (rank 1)

**Low-order / small-subgroup X25519 point forges the §1 identity possession proof (`ss=es=0`).**
Surface: static-identity-PoP / pake-noise-dh-composition. CONFIRMED.

- X25519 clamps every scalar to a multiple of the cofactor 8, so DH against a low-order identity
  public key returns the **all-zero constant** regardless of the honest party's private key. `ss`
  and `es` collapse to a value **any party can predict** (RFC 7748 §6.1 contributory-behavior issue).
- A malicious peer that completes ONE code-authenticated pairing (a normal in-model event — you pair
  with someone who may be malicious) presents a low-order `id_pub`, reproduces the victim's `ikm`
  from `k_pake` + its own ephemeral + the victim's **public** keys, and gets a pin written
  `possession_proven=true` on a key **nobody holds the discrete log of**.
- Thereafter **any codeless, keyless on-path / malicious-rendezvous MITM** forges the reconnect
  confirmation (`es=ss=0`; `ee/se` computable from public material) and impersonates that pinned
  contact **permanently** — precisely the v1 rank-1 reconnect zero-guess impersonation BLOCKER,
  reopened on the dominant pair-once/reconnect-many path.
- The draft mandates **no point validation or all-zero-DH rejection anywhere** (grep-confirmed), and
  no repo rule supplies one. No `[CRYPTO-DECISION]` covers it: 1a defers pattern/DH-set/mixing-order,
  not point validity, and "adopt Noise KK" does NOT add the check — Noise makes low-order rejection
  optional and assumes each peer static is authenticated **out-of-band** before use, an assumption
  this design inverts by authenticating the static via this very DH at pin time.
- All three HAS-BLOCKERS triggers fire: a claimed fix that demonstrably fails, a new critical hole,
  AND the headline v1 reconnect blocker not actually closed. This is a **required normative draft
  change, not a deferred cryptographer decision.**

## Ranked findings (19, deduped)

| # | Sev | Status | Surface | Break |
|---|-----|--------|---------|-------|
| 1 | BLOCKER | CONFIRMED | static-PoP / dh-composition | Low-order X25519 point → `ss=es=0` → `possession_proven` pin on an unowned key → permanent universal zero-secret reconnect forgery. |
| 2 | HIGH | CONFIRMED | routing/secret | "Server can never receive SECRET" overclaimed; untrusted server won't self-reject; a legacy typer forwards the whole ROUTING+SECRET string at mailbox-lookup → reopens v1 #4 zero-guess MITM. |
| 3 | HIGH | CONFIRMED | formal-model / channel-binding | §8 model stops at "paired"; `session_root = HKDF(empty-salt, bare-ephemeral-DH)` unbound to the handshake; the §7 `ephemeral==BTR-root` rider is prose-only → a green model certifies a silently content-MITM-able wire. |
| 4 | MEDIUM | CONFIRMED | kci-uks-reflection | Anti-reflection reject demoted to SPAKE2-only while CPace is recommended; §8(4) mis-scoped; "§6 CPace sidesteps reflection" is an unretracted overclaim over a reflection-symmetric outer schedule. |
| 5 | MEDIUM | CONFIRMED | routing/secret | §4's statistical/property test to enforce ROUTING⊥SECRET independence is a category error — PRF-derived pairs pass every black-box test; only a white-box construction/KAT catches derivation. |
| 6 | MEDIUM | PLAUSIBLE | reconnect | Reconnect downgrade unguarded — §3's floor is entirely code-ceremony-scoped (reconnect has no ceremony) and `possession_proven` is not stated to override legacy "old device" mode on both peers. |
| 7 | MEDIUM | PLAUSIBLE | code-consumption | Unauthenticated bare `PAIR_INIT` consumes-and-locks any live code → persistent denial-of-pairing (consume-at-IN_FLIGHT + single-flight reject + rate-limit removed). |
| 8 | MEDIUM | PLAUSIBLE | pin-contact_id | §9 permits a non-unique, potentially peer-advertised device label as the pin-store primary KEY with no collision/write semantics → silent trusted-identity replacement or mis-flagged re-pair. |
| 9 | MEDIUM | PLAUSIBLE | channel-binding | Browser "rely on identity-PoP" is sufficient ONLY via the unspecified `ephemeral==session_root` rider; §7's "a MITM that cannot complete the PAKE is caught" is false for a *relaying* MITM (it completes the PAKE). |
| 10 | MEDIUM | DEFERRED | code-consumption | Receiver-confirms-last relocates the oracle to the typer, but §2 mechanizes consume/lockout only in shower-shaped triggers; typer-side consume is only implied by prose. |
| 11 | LOW | CONFIRMED | code-consumption | §2.3 "throttles serial guessing across regenerated codes" is false under its own peer/mailbox keying (a regenerated code = a fresh mailbox). |
| 12 | LOW | PLAUSIBLE | routing/secret | The short-checksummed-prefix variant can pass a mis-boundaried string with ~1/256 checksum collision on a one-char under-type; confusable glyphs weaken even the disjoint variant. |
| 13 | LOW | DEFERRED | dh-composition / reflection | §1 `es/se` written in symmetric self/peer terms transpose between endpoints (fail-safe MAC mismatch, no attacker gain); the role/side_id source + a dangling "§ key-confirmation" reference are unspecified. |
| 14 | LOW | DEFERRED | dh-composition | `ikm` is a single flat unframed concatenation (non-exploitable at fixed 32-byte widths, but diverges from the Noise-PSK sequential domain-separated mix 1a names). |
| 15 | LOW | DEFERRED | channel-binding | fold-locally (§7) collides with consume-on-any-terminal-failure (§2): benign transport-binding divergence could burn the code + stack lockout. |
| 16 | LOW | DEFERRED | browser-native | No defined reconciliation between a native require-binding floor and a no-exporter browser peer; mixed-case tier-select is attacker-forceable (loses a defense-in-depth layer only). |
| 17 | LOW | DEFERRED | formal-model | §8 over-assigns to the symbolic model three properties it structurally cannot establish (byte injectivity, quantitative guess-infeasibility, PAKE⊕Noise composition soundness). |
| 18 | LOW | DEFERRED | formal-model / browser-native | §8 models one monolithic handshake but §7 defines native/browser/mixed variants — enumerate as explicit configs. |
| 19 | INFO | DEFERRED | reconnect | Static-DH-per-reconnect with no re-anchoring: a one-time id_priv compromise → permanent undetectable reconnect impersonation (out-of-model; universal key-continuity residual; v2 strictly improves on v1). |

## The 8 required changes before wire-freeze

1. **[BLOCKER — low-order point]** Add a NORMATIVE wire rule: reject known small-order Curve25519
   u-coordinates AND MUST-abort if any DH output (`ee/es/se/ss`) is all-zero (RFC 7748 §6.1
   contributory check), for both identity and ephemeral keys, at pairing AND reconnect. Never set
   `possession_proven` / write a pin for an identity key that failed validation; re-validate the
   pinned `identity_key` before every reconnect DH. Hedge/retract §1's "directly closes the reconnect
   BLOCKER" and §9's `possession_proven`-as-achieved-fact until this is in the frozen wire. Add
   low-order-static and low-order-ephemeral adversarial golden vectors, and make point-validity an
   EXPLICIT §8 model obligation (a default symbolic model abstracts DH algebraically and misses the
   cofactor collapse). "Adopt Noise KK" does NOT supply this.
2. **[HIGH — routing/secret]** Delete the false §4 sentence ("the server can never process SECRET as
   a routing token, even if a buggy/downgraded client tries"); reclassify server-side rejection as
   honest-server hygiene with ZERO protection against the untrusted rendezvous; state SECRET-off-server
   is enforced SOLELY by conformant client-side extraction. Close the legacy/version-skew path
   STRUCTURALLY: deliver ROUTING and SECRET as two distinct artifacts (SECRET typed into a separate
   PAKE field never forwarded to the rendezvous) OR wrap any combined code in a version container that
   legacy "enter code" parsers reject rather than forward verbatim. Add the legacy-typer-leak
   requirement to `[CRYPTO-DECISION 4a]` and to §8's obligations, plus a legacy-client → malicious-server
   conformance test (assert SECRET bytes never appear in any rendezvous-facing message).
3. **[HIGH — formal-model / channel-binding]** Add a sixth §8 MUST-cover obligation: an
   injective/entity-agreement lemma asserting `PAIR_INIT.ephemeral_key == sender_ephemeral_key of every
   post-handshake envelope == BTR session_root input`, under a Dolev-Yao/untrusted-rendezvous +
   transport-terminating attacker; add a substitute-envelope-ephemeral-after-PAKE → reject vector.
   Promote the §7 rider from prose to a normative, receive-path-ordered MUST (enforced before
   HANDSHAKE_COMPLETE / before any data envelope); upgrade the profile's MAY-compare/warn to a
   fail-closed MUST. Preferred stronger fix: derive `session_root = HKDF(salt = PRK/TT,
   ikm = ephemeral_shared_secret)` so a substituted data ephemeral fails cryptographically on all
   transports. Rewrite §7's false sufficiency prose (a relaying MITM DOES complete the PAKE) to credit
   the rider, not PAKE-completion.
4. **[MEDIUM — reflection]** Make an anti-reflection / anti-self-pairing reject PRIMITIVE-INDEPENDENT
   and NORMATIVE in §1, evaluated BEFORE key derivation on BOTH the CPace and SPAKE2 paths: reject
   inbound `PAIR_INIT` if `peer_ephemeral==own` OR `peer_identity_key==own` OR `peer_pake_msg==own` OR
   `peer_side_id==own`. Retract the §6 "CPace sidesteps reflection" overclaim; re-scope §8(4)
   INDEPENDENT of the SPAKE2 complement-verified confirmation; specify key-confirmation with
   direction-separated tags. Confirm the same reject on the reconnect/KK path.
5. **[MEDIUM — CSPRNG independence]** Replace §4's "golden-vector-grade statistical/property test"
   with a WHITE-BOX construction mandate: a single audited sampling routine doing two SEPARATE CSPRNG
   reads (no shared/derivable seed) as the only sanctioned API, enforced by code review + a cross-impl
   KAT feeding TWO distinct mocked entropy streams and asserting ROUTING is a function of stream-A only
   and SECRET of stream-B only. Pin ROUTING length/format to a constant independent of SECRET.
6. **[MEDIUM — reconnect downgrade]** State normatively that a `possession_proven` pin makes
   identity-DH reconnect MANDATORY and NON-OVERRIDABLE for that contact on BOTH peers: legacy/"old
   device" mode and BTR→static are FORBIDDEN for any `possession_proven` contact, fail-closed. Enforce
   the reconnect capability floor from the authenticated identity-DH RESULT, not from MITM-mutable
   ephemeral-keyed HELLO caps. Add a reconnect-downgrade / suppress-DH-marker vector to §8.
7. **[MEDIUM — pin store]** `contact_id` MUST be a unique CSPRNG-minted local handle, never seeded
   from a user or peer-advertised label; keep the human name strictly as the non-key `device_label`.
   Specify write semantics: writing an existing `contact_id` with a NEW `identity_key` MUST be an
   explicit human-confirmed rotation via fresh PAKE, distinct from the reconnect-path KEY_MISMATCH
   hostile abort; two contacts may share a `device_label` but never a `contact_id`.
8. **[MEDIUM — §2 typer locus + availability]** Mechanize the typer side: the code-TYPER MUST consume
   the typed SECRET keyed on the VALUE at confirm-exposure (one `PAIR_CONFIRM` emitted = one guess
   spent), persist a consumed-value refusal, forbid auto-retry, extend §2.3 lockout to typer re-entry;
   name the typer-as-oracle leg in §8 item 3. Separately, do NOT drive a code to CONSUMED or escalate
   device-wide backoff on UNAUTHENTICATED outcomes (bare/abandoned/garbage `PAIR_INIT`, drop, timeout)
   — count a guess / consume only on a verified secret-authenticated `PAIR_CONFIRM` (a bare probe holds
   at most a short single-flight slot that returns the code to LIVE); reinstate rendezvous rate-limiting
   as the availability (anti-spam) throttle. Rewrite §2.3's false "throttles serial guessing across
   regenerated codes" claim and specify the lockout key (device-backoff only on locally-human-initiated
   ceremonies, never anonymous inbound probes).

## Correctly deferred to the cryptographer (10 — NOT draft defects)

1. **[1a]** Named, analyzed Noise pattern (reconnect≈KK, pairing≈XX/IK+PSK) + DH set/mixing order +
   PAKE⊕Noise composition; canonicalizes `es/se` slot order by role, supplies pairing↔reconnect domain
   separation, reconciles the flat-concat `ikm` with the Noise-PSK sequential mix, threads the typer/
   shower role into the confirm-key split + reflection reject.
2. **[1b]** KCI scope of `es/se`; identity-key rotation + whether a signed cross-cert is needed.
3. **[1c]** Reconnect cadence — bounded re-anchoring vs "sufficient indefinitely"; compromise-recovery
   / revocation path.
4. **[2a/2b]** Lockout parameters + consume-trigger timing; PLUS an explicit QUANTITATIVE
   guessing-infeasibility budget (SECRET entropy × allowed-guesses × backoff → work factor), gated
   SEPARATELY from the symbolic proof.
5. **[4a]** ROUTING grammar (disjoint alphabet vs typed/checksummed prefix) satisfying the anti-bleed
   MUST (full MAC/separator, confusable-free, transmit-nothing-on-failure), ROUTING length, SECRET
   entropy/MHF, re-pin the normalization order as a v2 golden vector.
6. **[5a]** Final injective byte-layout freeze via a mechanized verified-codec (EverParse/F*-style) or
   exhaustive grammar proof (the symbolic model cannot prove byte injectivity or cross-impl decoder
   equivalence); extend golden vectors to the `ikm/PRK` byte assembly.
7. **[6]** PAKE primitive selection (CPace primary vs SPAKE2-0.4.0 fallback vs SPAKE2+) + the balanced-
   reduction / non-RFC transcript / external-HKDF composition sign-off + the unaudited / not-constant-
   time / no-zeroization HIGH sign-off.
8. **[7a]** Native-transport exporter choice + ratify fold-locally + the browser "no exporter, rely on
   identity-PoP" argument; define the mixed native↔browser fold, bind the transport-tier signal into
   TT/ceremony, gate require-binding on confirmed symmetric exportability, make binding-divergence a
   non-consuming soft failure.
9. **[8a]** Formal-methods tool/scope/ownership; record ideal-PAKE/ideal-DH + injective serialization
   as ASSUMED PREMISES (not results); carve the computational PAKE⊕Noise composition out of the
   symbolic deliverable; enumerate the three transport configs as distinct model configs.
10. **[9a]** Whether to show a verifier string to both humans (optional, not load-bearing).

## What holds up (keep it)

The type-a-secret PAKE + identity-DH direction is sound and a real advance over v1 — for well-formed
keys, reconnect now requires private-key possession, not a public-key match. The receiver-confirms-last
+ single-flight + consume-on-attempt consumption model is structurally strong. The ceremony-bound
first-contact pairing floor closes the v1 first-contact gap. The honest non-"verified" product states
and the retraction of the three falsified v1 claims are correct. Thirteen substantive open items are
correctly scoped for the professional cryptographer. The design is close; the 8 required changes
(headlined by point-validation) must land before a cryptographer is the right next reviewer.
