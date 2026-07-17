# EA1 PAKE v3 Draft — Adversarial Red-Team Report

> **Date:** 2026-07-16
> **Type:** Immutable evidence record (do not edit; corrections get their own dated entry).
> **Subject:** `os/log/decisions/2026-07-16-ea1-pake-v3-profile-draft.md` (the EA1 PAKE **v3** draft —
> the revision that incorporated the v2 red-team's eight required changes).
> **Method:** UltraCode adversarial review (multi-agent, read-only) — the THIRD pass. 10 red-teamers,
> one per named attack surface, each told to assume the design is wrong and to check both whether each
> v2-required fix actually closes its hole and whether v3 introduced new ones; every candidate break
> independently refuted by a verifier that sorted each into REFUTED / DEFERRED-TO-CRYPTOGRAPHER /
> CONFIRMED / PLAUSIBLE and classified survivors as **draft-defect** vs **cryptographer-decision**.
> **36 candidates → 14 refuted; of 22 survivors: 7 CONFIRMED, 4 PLAUSIBLE, 11 DEFERRED-TO-CRYPTOGRAPHER.**
> 47 agents, 0 errors. (Workflow run `wf_c149907a-20f`.)

## Verdict: **NEEDS-REVISION** — the process is converging

No CONFIRMED BLOCKER survives. The §0 low-order/all-zero-DH rule **genuinely closes the v2 rank-1
BLOCKER**, and the reconnect downgrade floor holds. The verdict is driven by **1 confirmed HIGH + 4
confirmed MEDIUM**, and every one is a **draft-defect** — an author-fixable prose/spec/wire-precision
correction, **not** a cryptographer primitive decision and **not** an unclosed design hole. The
trajectory across passes is the intended convergence: **v1 → no-proof-of-possession blocker; v2 →
low-order-point blocker; v3 → no blocker.** Two of the confirmed defects were caught against the
*actual deployed code* (`normalizePeerCode` forwarding a code verbatim; the absent `bolt2:` parser),
which is why they are trustworthy rather than "sounds wrong." The reviewer's bottom line: land the
nine required edits and the residual is cryptographer-decisions + LOWs — at which point the draft
becomes **ACCEPTABLE-FOR-CRYPTOGRAPHER-REVIEW**.

## Do the eight v2-required fixes close their holes?

| Fix | Status |
|---|---|
| 1. Low-order / all-zero DH (§0) | **CLOSES** the v2 BLOCKER — blacklist + all-zero abort, identity+ephemeral, pairing+reconnect; clamping collapses a low-order point to all-zero, no predictable-nonzero residual. Minor: non-canonical X25519 encodings not rejected (inert, §5-backstopped); a wording over-reach on "all DH outputs". |
| 2. Routing/SECRET split (§1) | **PARTIAL** — conforming-client SECRET-off-server closed; the **structural half FAILS**: "a legacy parser rejects the `bolt2:` container" is *code-verified false* (deployed `normalizePeerCode` forwards verbatim; `isValidPeerCode` unwired; no `bolt2:` parser exists). |
| 3. session_root binding (§6) | **PARTIAL + 2 new draft holes** — the `(or TT)` public-salt option voids the "cryptographic, not a byte-check" backstop on the exporter-less browser leg and breaks cross-impl determinism; `ephemeral_shared_secret` is undefined and the equality MUST is type-confused (public key == DH output). |
| 4. Anti-reflection (§4) | **CLOSES but OVERSHOOTS** — "reflection resistance independent of the confirmation mechanism" is *false* (§5's direction-separated confirmation is load-bearing). Not exploitable as written because §5's MUST is present, but the false lemma must be corrected. |
| 5. CSPRNG independence (§1) | **MOSTLY closes** (statistical → white-box is the right property); the single-pair KAT needs a differential + negative case (LOW, test-precision). |
| 6. Reconnect downgrade floor (§7) | **CLOSES** — `possession_proven` ⇒ mandatory, non-overridable identity-DH; legacy forbidden, fail-closed; floor from the authenticated DH result, not HELLO caps. |
| 7. Pin / contact_id rotation (§9) | **PARTIAL** — store-key half closed (CSPRNG `contact_id`, `identity_key` compared); rotation-overwrite has no old-key continuity (→ CD1b); KEY_MISMATCH reachability asserted-not-established (LOW). |
| 8. Code consumption (§8) | **PARTIAL + introduces the HIGH** — a self-contradiction: a secret-less attacker's garbage-MAC `PAIR_CONFIRM` is a "verified-failure" that escalates device-wide backoff, **relocating the v2 anonymous-probe DoS**. |

## Confirmed findings (all draft-defects)

| # | Sev | Surface | Defect |
|---|-----|---------|--------|
| 1 | **HIGH** | code-consumption | §8 bullet-1 ("backoff escalates on any verified-failure", L203-208) contradicts its own "never anonymous inbound probes" (L219-220); a garbage `PAIR_CONFIRM` from a secret-less attacker escalates honest device backoff → the v2 anonymous-lockout DoS returns; the "removes the v2 unauthenticated-probe DoS" headline is false. |
| 2 | MEDIUM | session_root / browser-native | §6 salt `(or TT)` permits a **public** salt → under `salt=TT`, `session_root` secrecy rests solely on the ephemeral so a substituting MITM computes it (voids the browser-leg backstop); and two conforming impls may pick different salts and never key up, leaving the mandated golden vector un-pinnable. |
| 3 | MEDIUM | session_root | `ephemeral_shared_secret` is undefined; the MUST "`PAIR_INIT.ephemeral_key == the input to session_root`" equates a public key to a DH output (unsatisfiable); §0 lists it as a 5th DH distinct from `ee` — so an impl can echo the authenticated ephemeral while keying `session_root` from a substituted transport/DTLS/QUIC ephemeral. |
| 4 | MEDIUM | routing/secret | §1 [FIX 2] "a legacy enter-code parser rejects the `bolt2:` container rather than forwarding" is falsified by the deployed parser (code-verified: `normalizePeerCode` peer-code.ts:60 forwards verbatim; `isValidPeerCode` rejects by length/alphabet, not prefix, and is unwired) — SECRET-off-server not closed for non-conforming/legacy/manual paths; the L314 "version-container rejected by a legacy parser" test obligation is false as written. |
| 5 | MEDIUM | anti-reflection | §4/obligation-#5 "reflection resistance independent of the confirmation mechanism" is **false** — a fresh-key typer-reflection (Vector-2: attacker injects `PAIR_INIT_M` with its own four fields → the §4 equality reject never fires) is stopped *only* by §5's direction-separated tags; the claim directs the formal model to prove a false lemma and invites removing the sole control. Not exploitable as-written because §5's MUST is present. |
| 8 | LOW | anti-reflection | §4 equality reject is byte-vs-canonical unspecified — RFC 7748 high-bit masking lets distinct bytes decode to the same point, so a high-bit-flipped self-reflection is not caught by a byte comparison while `peer_* != own`; inert end-to-end (§5-backstopped, no bad pin, all values A-private-derived) but a credited reflection control is holed at the encoding level. |

Plus 4 PLAUSIBLE (a CD4a anti-bleed separator interacting with the deployed `-`-stripping
normalization; the KAT precision; KEY_MISMATCH reachability; the legacy-typer-leak test rigor) and 11
findings correctly **deferred to the cryptographer**.

## Ranked findings (21, deduped)

| # | Sev | Status | Class | Surface | Break |
|---|-----|--------|-------|---------|-------|
| 1 | HIGH | CONFIRMED | draft-defect | code-consumption | §8 device-wide backoff on a garbage `PAIR_CONFIRM` → reopens the v2 anonymous-lockout DoS; self-contradicts §8. |
| 2 | MEDIUM | CONFIRMED | draft-defect | session_root | `session_root` salt `(or TT)` permits a public salt → MITM-computable + non-deterministic cross-impl. |
| 3 | MEDIUM | CONFIRMED | draft-defect | session_root | `ephemeral_shared_secret` undefined + type-confused equality MUST + §0-vs-§6 5th-DH contradiction. |
| 4 | MEDIUM | CONFIRMED | draft-defect | routing/secret | "legacy parser rejects `bolt2:`" is code-verified false; SECRET-off-server not closed for legacy paths. |
| 5 | MEDIUM | CONFIRMED | draft-defect | anti-reflection | "reflection resistance independent of confirmation" false; §5 direction separation is load-bearing. |
| 6 | MEDIUM | PLAUSIBLE | draft-defect | browser-native | CD4a anti-bleed MUST doesn't forbid a separator the deployed normalization strips (`-`); a dash-family 4a separator could bleed SECRET on a legacy leg. |
| 7 | MEDIUM | DEFERRED | cryptographer | pin/contact_id | Rotation overwrite has no cryptographic old-key continuity → social-engineered hijack + KEY_MISMATCH inversion; = CD1b; §9 must cross-reference/gate on 1b. |
| 8 | LOW | CONFIRMED | draft-defect | anti-reflection | §4 equality is byte-vs-canonical unspecified; non-canonical re-encoding self-pairs (inert, §5-backstopped). |
| 9 | LOW | PLAUSIBLE | draft-defect | routing/secret | [FIX 5] single-pair KAT cannot detect shared-seed derivation; needs a differential + negative case. |
| 10 | LOW | PLAUSIBLE | draft-defect | pin/contact_id | §9 KEY_MISMATCH reachability asserted-not-established; reconnect→contact_id resolution unspecified; natural lookup-by-`identity_key` makes the tripwire dead code (v1 #9 residual). |
| 11 | LOW | PLAUSIBLE | draft-defect | formal-model | Obligation #8 (legacy-typer-leak) scoped "for a conforming client"; the [FIX 2] test names no real deployed legacy parser → v2 HIGH #2 not shown closed (verification-rigor gap). |
| 12 | LOW | DEFERRED | cryptographer | low-order-dh | §0 "all X25519 DH outputs" wording omits the PAKE-internal (CPace) + open CD1a DH set (editorial scope-narrowing; PAKE-internal validation → CD6). |
| 13 | LOW | DEFERRED | cryptographer | dh-composition | es/se role transposition (fail-safe MAC mismatch); converge BY WIRE ROLE under CD1a, never by sorting (sorting destroys es/se KCI binding). |
| 14 | LOW | DEFERRED | cryptographer | dh-composition | `ikm` flat concat depends on an unpinned fixed-32-byte-width invariant; `k_pake` width undetermined → CD1a/CD6/CD5a. |
| 15 | LOW | DEFERRED | cryptographer | browser-native | Mixed native↔browser channel-binding tier has no interim rule; tier-select attacker-forceable (DiD loss) → CD7a. |
| 16 | LOW | DEFERRED | cryptographer | browser-native | SECRET uppercase-fold diverges cross-impl on non-ASCII (Rust vs JS); golden vector may only exercise ASCII → CD4a. |
| 17 | LOW | DEFERRED | cryptographer | formal-model | Golden-vector obligations omit the new `bolt2:` container parse → CD4a (grammar) + CD5a (decoder equivalence). |
| 18 | INFO | DEFERRED | cryptographer | reconnect | One-time id_priv compromise → permanent undetectable reconnect impersonation (universal static-key residual) → CD1c (add a detection/revocation story). |
| 19 | INFO | DEFERRED | cryptographer | session_root | §6 reuses PRK as HKDF-Extract salt while §5 uses PRK as HKDF-Expand key — no explicit domain separation (no exploitable collision; label hygiene) → CD1a. |
| 20 | INFO | DEFERRED | cryptographer | routing/secret | Illustrative container `bolt2:<ROUTING>.<SECRET>` uses a bare `.` that contradicts the anti-bleed MUST (marked "e.g."; `.` excluded from the 31-char alphabet) → CD4a. |
| 21 | INFO | DEFERRED | cryptographer | dh-composition | No explicit pairing↔reconnect domain-separation label; separation is only emergent → CD1a should deliver a per-path label/PSK. |

## The nine required changes before wire-freeze (all author-fixable draft-defects)

1. **§8 (HIGH):** resolve the L203-208 vs L219-220 contradiction toward "never escalate device-wide
   backoff on inbound." Keep consuming the single displayed code on an inbound failed confirm (needed
   for the one-guess bound) but **decouple it from device-wide backoff**; restrict device-backoff
   escalation to the TYPER's own locally-initiated, value-keyed attempts. Delete/qualify "any
   lockout/backoff escalates … on verified-failure" for the receive path, correct the false "removes
   the v2 unauthenticated-probe DoS" headline, and add a garbage-`PAIR_CONFIRM` adversarial vector.
2. **§6 (MEDIUM):** delete `(or TT)`; mandate `session_root = HKDF(salt = PRK, ikm =
   ephemeral_shared_secret)` (PRK secret from any relay); if TT domain-separation is wanted, put it in
   HKDF `info`, never as the salt. State the load-bearing premise ("a relaying MITM lacks SECRET ⇒
   cannot derive k_pake ⇒ cannot compute PRK ⇒ cannot compute `session_root`") and correct the false
   "fails cryptographically on every transport" sentence. Makes the mandated golden vector
   cross-impl-deterministic.
3. **§6 (MEDIUM):** define `ephemeral_shared_secret = X25519(own PAIR_INIT eph priv, peer PAIR_INIT eph
   pub)` — i.e. it **is** `ee`; pin exactly one session ephemeral per side (the PAIR_INIT ephemeral,
   never a transport/DTLS/QUIC/DataChannel ephemeral). Replace "MUST equal … the input to
   session_root" with "MUST be the public key whose private half computes `ephemeral_shared_secret`."
   Reconcile §0's 5th-DH enumeration (drop it or label it explicitly as `ee`).
4. **§1 / [FIX 2] (MEDIUM):** drop the false "legacy parser rejects the `bolt2:` tag / a legacy client
   cannot forward SECRET" mechanism (L25, L87, L90-93) and the "version-container rejected by a legacy
   parser" test sub-clause (L314). Re-scope the closure explicitly as a conforming-client gate.
   Strongest remedy: **never hand any single string containing SECRET to the transport/mailbox layer**
   — enter ROUTING and SECRET as two separate inputs, SECRET into a dedicated PAKE-password field the
   signaling API physically cannot transmit. If a combined typed code is retained, replace
   assumed-rejection with a real legacy/forked → malicious-server conformance harness against every
   deployed parser, restating "so it rejects" as "MUST be verified to reject."
5. **§4 / obligation #5 (MEDIUM):** rewrite §4 (L136-138) to attribute reflection/UKS resistance
   **jointly** to (a) the equality reject, (b) TT identity-binding, and (c) a **mandatory**
   direction-separated confirmation — independent only of the PAKE primitive's internal mechanism, not
   of the confirmation layer; label §5 direction separation LOAD-BEARING. Restate obligation #5 to
   require reflection/UKS resistance *given* a direction-separated confirmation, and add the negative
   obligation (a reflection COMPLETES if confirmation is made symmetric). Fix §5's rationale to also
   cover Vector-2 (confirmation reflection).
6. **§4 / §0 (LOW):** specify the §4 equality over canonical (masked/reduced) X25519 encodings, or
   extend §0 to reject non-canonical byte forms (high-bit-set or u ≥ p) at ingress; add a
   high-bit-flipped-self-reflection → reject golden vector.
7. **§1 / [FIX 5] (LOW):** replace the single-pair KAT with a **differential** white-box test: fix
   stream-A vary stream-B → ROUTING byte-identical / SECRET differs; fix stream-B vary stream-A →
   SECRET byte-identical / ROUTING differs; plus a **negative** shared-seed reference impl that MUST
   fail the suite.
8. **§9 (LOW):** either soften the "KEY_MISMATCH stays reachable" claim (contingent on the reconnect
   resolver) or add a stable per-contact reconnect identifier distinct from `identity_key` to
   `PinRecord` and require an inbound reconnect to resolve to `contact_id` first, then compare the
   presented `identity_key` (mismatch ⇒ hostile, MUST NOT fall through to first-contact/unknown-peer);
   extend model obligation #2 and the FIX-7 test to require substituted-key-reconnect ⇒ key_mismatch.
9. **§9 (draft-doc):** explicitly gate the rotation-overwrite clause (L240-242) behind **[CRYPTO-
   DECISION 1b]** and state the interim posture (new-contact-only / cross-cert-gated until 1b resolves)
   so an implementer reading §9 in isolation cannot build the vulnerable human-confirm-only overwrite.

## Correctly deferred to the cryptographer (7)

1. **CD1a** — named Noise pattern + DH set/mixing order + PAKE⊕Noise composition: converge es/se **by
   wire role, explicitly forbid sorting the {es,se} pair** (sorting destroys KCI binding); pin
   `k_pake` width / `ikm` framing; deliver **explicit designed** pairing↔reconnect domain separation
   (per-path HKDF context / PSK), not emergent; domain-separate §5's PRK-as-Expand-key from §6's
   PRK-as-Extract-salt.
2. **CD1b** — identity-key rotation continuity + es/se KCI scope: require the currently-pinned OLD key
   to cross-cert the NEW key before overwrite; on genuine key loss mint a NEW `contact_id` (do not
   inherit reconnect trust, do not convert the old key into a KEY_MISMATCH-hostile verdict against the
   real peer); specify rotation-write vs concurrent-reconnect atomicity.
3. **CD1c** — reconnect cadence / bounded re-anchoring **+ a detection/revocation story** (silent key
   cloning yields the same key, raises no KEY_MISMATCH, and §9's victim-initiated rotation won't fire
   for an unaware victim).
4. **CD4a** — ROUTING grammar + anti-bleed MUST: version prefix MUST be non-alphanumeric (deployed
   length/alphanumeric gates reject it); the ROUTING↔SECRET separator MUST NOT be any char the deployed
   normalization strips/folds (notably `-`); disjoint alphabets; length-framed/MAC'd separator;
   confusable-free / non-ASCII SECRET normalization.
5. **CD5a** — injective byte-layout freeze via a verified codec + cross-impl decoder equivalence; fold
   the `bolt2:` container parse under 5a with an adversarial cross-impl split golden vector.
6. **CD6** — PAKE primitive (CPace primary vs SPAKE2-0.4.0 vs SPAKE2+) + crate/reduction/composition +
   unaudited/not-constant-time HIGH sign-off; **fold the chosen primitive's internal scalar-mult
   point/cofactor validation** into the sign-off (§0's enumeration does not name the PAKE-internal DH).
7. **CD7a** — native exporter + fold-locally + mixed native↔browser reconciliation with a
   non-forceable tier-select binding; discharge obligation #9 (identity-DH alone suffices for
   transport-MITM resistance on the browser leg). Note: the browser backstop's strength depends on the
   §6 salt being pinned to PRK (required change #2).

## What holds up (keep it)

The §0 point-validation genuinely closes the v2 blocker (no predictable-nonzero residual on the
enumerated DH set); the reconnect downgrade floor holds; the CSPRNG-independence direction (statistical
→ white-box) and the honest non-"verified" product states are correct. Eleven substantive items are
correctly scoped for the cryptographer. The remaining defects are precision/wording/wire corrections
the author lands — none reopens a design hole with no fix in sight. This is a real net improvement over
v2, and after the nine edits the draft is expected to reach ACCEPTABLE-FOR-CRYPTOGRAPHER-REVIEW.
