# EA1 PAKE v4 Draft — Adversarial Red-Team Report

> **Date:** 2026-07-17
> **Type:** Immutable evidence record (do not edit; corrections get their own dated entry).
> **Subject:** `os/log/decisions/2026-07-17-ea1-pake-v4-profile-draft.md` (the EA1 PAKE **v4** draft —
> the revision that incorporated the v3 red-team's nine required edits).
> **Method:** UltraCode adversarial review (multi-agent, read-only) — the FOURTH pass. 10 red-teamers,
> one per named focus area, each told to assume the design is wrong and to check both whether each
> v3-required fix actually closes its hole and whether v4 introduced new ones; every candidate break
> independently refuted by a verifier that sorted each into REFUTED / DEFERRED-TO-CRYPTOGRAPHER /
> CONFIRMED / PLAUSIBLE and classified survivors **draft-defect** vs **cryptographer-decision**.
> **28 candidates → 9 refuted; of 19 survivors: 5 CONFIRMED, 8 PLAUSIBLE, 6 DEFERRED-TO-CRYPTOGRAPHER.**
> 39 agents, 0 errors. (Workflow run `wf_52c4b5b4-54d`.)

## Verdict: **NEEDS-REVISION** · cryptographer-ready: **No** (two fixes away)

The closest pass yet. **No blocker; 7 of 9 v3 edits landed cleanly.** Two confirmed draft-defects the
author must fix before handoff remain (1 HIGH + 1 MEDIUM), plus LOW cleanups and correctly-scoped
cryptographer decisions. **Do not hand it to a cryptographer yet** — as written, formal obligation #6
would prove secrecy of a PRK-salted `session_root` that (per the untouched normative schedule) does
not key the data, and obligation #7 + test L348 would certify a forgeable, anonymous-inbound-summonable
hostile `KEY_MISMATCH` as *required* behavior. Fix those two (and reconcile the FIX-8/FIX-9
contradiction) first; the rest are LOW cleanups and `[CRYPTO-DECISION]` items. Trajectory:
**v1 (no-PoP blocker) → v2 (low-order blocker) → v3 (NEEDS-REVISION, 9 edits) → v4 (NEEDS-REVISION,
2 blocking + 8 LOW)** — converging.

## The two defects that block cryptographer handoff

### ① HIGH — §6 PRK-salted `session_root` is disconnected from the normative data key schedule

*(draft-defect; ephemeral_shared_secret / session_root-binding)*

- v4's `session_root = HKDF(salt = PRK, ikm = ephemeral_shared_secret)` is **computed but unused**.
  The normative `PROTOCOL.md` — which v4's own Hard Boundaries forbid editing — keys the data channel
  from **`ee` alone** (non-BTR direct-ee, §PROTOCOL L197/L1441; BTR salt = EMPTY, §16.3 L1078-1081;
  BTR-INV-01 roots on the ephemeral shared secret, not PRK). v4's `session_root` also **name-collides**
  with the existing `session_root_key`/`K_session`.
- Consequence: §6's settled premise "the honest endpoints key the data channel with `session_root`"
  and the browser "secret PRK salt" backstop are **false for the wire**, and formal obligation #6 would
  discharge against a value nothing uses. **File-byte confidentiality still holds via `ee`-authentication**
  (TT + sender-ephemeral binding + confirmation) — which is why this is HIGH, not a BLOCKER.
- **Fix — the author must pick ONE fork (they have materially different security properties):**
  - **(A)** re-root the normative data/BTR schedule on `session_root` (change `PROTOCOL.md` §16.3
    `salt=EMPTY` → a PRK-derived value — which requires **explicitly lifting the "no protocol-spec
    edits" boundary** for that one change), rename to kill the `session_root` / `session_root_key` /
    `K_session` collision, and extend obligation #6 to require the data AEAD key be a function of
    `session_root`. **(A) delivers a PRK-salt backstop against `ee`-recovery.**
  - **(B)** delete §6's "keys the data channel with `session_root`" + browser "secret PRK salt"
    sentences, re-attribute §6 confidentiality to `ee`-authentication, and acknowledge `ee`-compromise
    is **not** PRK-backstopped. **(B) stays design-only; no PRK backstop.**

### ② MEDIUM — inbound `KEY_MISMATCH` is attacker-summonable via the stable `reconnect_handle`

*(draft-defect; contact_id / reconnect_handle)*

- An anonymous, secret-less, key-less party (or the untrusted rendezvous) that knows the
  rendezvous-visible stable `reconnect_handle` presents a self-generated key → §9 resolve-then-differ →
  a **hostile "your contact's key changed" alert + re-pair about the honest contact**. Obligation #7 +
  test L348 currently **mandate** this behavior.
- No impersonation or confidentiality break (identity-DH + FIX 9 contain it → MEDIUM), but it degrades
  the sole human-facing MITM tripwire (warning-habituation) and manufactures a phishing pretext. **It is
  the reconnect-path sibling of the §8/FIX-1 anonymous-inbound pattern v4 just closed** — the fix did
  not generalize.
- **Fix:** split `KEY_MISMATCH` by initiator — keep the hostile user-visible alert + re-pair for a
  **locally-initiated** reconnect (human-chosen = genuine signal); make an **unauthenticated inbound**
  resolve-then-differ a **silent, rate-limited, non-alerting, non-pin-mutating discard** (mirror
  §8/FIX-1's anonymous-inbound rule verbatim); only a locally-initiated reconnect or an inbound that
  cryptographically proves possession of the PRIOR pinned key may surface `KEY_MISMATCH`; make it
  connection-scoped, never contact-sticky. Revise obligation #7 + test L348, and reconcile the internal
  contradiction between FIX 8 ("MUST NOT fall through to first-contact") and FIX 9 ("never converts the
  retained old key into a `KEY_MISMATCH`-hostile verdict against the real peer").

## Did the nine v3 edits close?

| # | v3 edit | v4 status |
|---|---------|-----------|
| 1 | §8 backoff decouple | **Closes** the device-lockout flavor (only the typer's local value-keyed attempts escalate device backoff); but the anonymous-inbound-adverse-state *class* wasn't carried to §9 (defect ②), and the code-burning residual is under-characterized as "acceptable" (rank 3). |
| 2 | session_root salt=PRK | Delivers the letter (salt MUST=PRK, `(or TT)` removed, deterministic golden vector) **but ships the new HIGH** (disconnected from the normative data schedule). |
| 3 | ephemeral_shared_secret=ee | **Closes** the letter (ee defined, one ephemeral/side, well-typed pubkey==pubkey binding); shares defect ①'s disconnect. |
| 4 | ROUTING/SECRET API separation | **Partial** — two-input path is genuinely structural, false "legacy parser" claim retracted; overstates "structural/type-level" and the "every deployed/forked client" test wording is un-runnable (2 LOW). |
| 5 | joint anti-reflection | **Closes** the core (§5 elevated to LOAD-BEARING, joint 3-control model, negative obligation); new LOW (§5 L/R comparison basis unpinned → cross-impl non-determinism). |
| 6 | canonical X25519 | **Closes** the security substance (§0 non-canonical rejection + high-bit-flip vector; all-zero abort backstop); 2 LOW draft-defects (RFC 7748 miscitation; obligation #3 over-assignment). |
| 7 | differential CSPRNG KAT | **Closes** — no surviving finding challenges it. |
| 8 | reconnect KEY_MISMATCH | Resolves the v3 dead-code/blanket defect **but ships the new MEDIUM** (defect ②); FIX-8-vs-FIX-9 contradiction. |
| 9 | rotation gated behind 1b | **Closes / correctly deferred** — and actively contains defect ②'s blast radius. |

## Ranked findings (18, deduped)

| # | Sev | Status | Class | Surface | Break |
|---|-----|--------|-------|---------|-------|
| 1 | HIGH | CONFIRMED | draft-defect | session_root | PRK-salted `session_root` disconnected from the normative data schedule (data keys from `ee`); §6 data-keying + browser claims false for the wire; obligation #6 vacuous. |
| 2 | MEDIUM | CONFIRMED | draft-defect | reconnect_handle | Inbound `KEY_MISMATCH` attacker-summonable via the stable handle → forged hostile alert about the honest contact; obligation #7 + test L348 mandate it. |
| 3 | MEDIUM | PLAUSIBLE | draft-defect | code-consumption | §8 code-burning DoS mis-rated "acceptable" — a ROUTING-only party can permanently/deterministically/stealthily burn every displayed code through an honest rendezvous. |
| 4 | LOW | CONFIRMED | draft-defect | formal-model | Obligation #3 assigns byte-level non-canonical rejection to the symbolic model (no byte layer; contradicts obligation #10's injective-serialization premise). |
| 5 | LOW | CONFIRMED | draft-defect | canonical-x25519 | "RFC 7748 §6.1 blacklist" miscitation (§6.1 = the all-zero abort, not a blacklist; the value set is implementation-derived). |
| 6 | LOW | PLAUSIBLE | draft-defect | session_root | §6 secrecy premise + obligation #6 stated only for pairing; vacuous on reconnect (no k_pake) — reconnect confidentiality asserted-not-justified. |
| 7 | LOW | PLAUSIBLE | draft-defect | routing-secret | §1 "structural / type-level" SECRET-off-server guarantee overstated — the single-combined-code split reduces it to split-correctness over a plain-string wire. |
| 8 | LOW | PLAUSIBLE | draft-defect | routing-secret | §1 conformance-test "across every deployed/forked client" is un-runnable + contradicts the conforming-client scoping. |
| 9 | LOW | PLAUSIBLE | draft-defect | browser-native | §5 role rule "owner of the smaller side_id" has an unpinned comparison basis → a signed-byte native port flips L/R for ~50% of pairs (fail-closed interop break on the load-bearing confirmation). |
| 10 | LOW | PLAUSIBLE | draft-defect | reconnect_handle | FIX-8 "precise reachability" rests on a key-carrying reconnect (contradicts the deferred KK, CD1a) and on unspecified `reconnect_handle` invariants. |
| 11 | LOW | PLAUSIBLE | draft-defect | formal-model | es/se-orientation golden vector not required to be sort-discriminating → can't catch a KCI-destroying sorting impl (the CD1a hazard). |
| 12 | LOW | PLAUSIBLE | cryptographer | code-consumption | The one-guess bound's enforcement locus/atomicity unspecified; non-atomic it degrades toward an N-guess oracle (route to CD2a with a shower-enforced-atomic pin). |
| 13 | LOW | DEFERRED | cryptographer | anti-reflection | FIX-6 canonicalizes identity/ephemeral but not `pake_msg` → §4's "canonical compare" for `peer_pake_msg==own` unbacked (inert; CD6-owned). |
| 14 | LOW | DEFERRED | cryptographer | formal-model | FIX-4 model obligation cuts at "the API boundary", leaving the single-code split leak surface to CD4a/CD5a (backstopped by the byte-scan harness). |
| 15 | INFO | DEFERRED | cryptographer | reconnect_handle | Stable wire-visible `reconnect_handle` is a rendezvous-linkability regression (metadata-only) — correctly deferred to CD1c. |
| 16 | INFO | DEFERRED | cryptographer | browser-native | §6 browser premise states only the pairing chain; browser reconnect `session_root` secrecy (identity-DH) unstated — CD7a's lemma. |
| 17 | INFO | DEFERRED | cryptographer | browser-native | Mixed native↔browser tier-select coercion is DiD-loss only (capabilities[] is under the §5 MAC); CD7a must pin the tier signal + a soft browser-default interim rule. |
| 18 | INFO | DEFERRED | cryptographer | formal-model | `reconnect_handle` is a new on-wire identifier with no model obligation; add a one-line "obligation #7 certifies nothing about handle privacy; unlinkability → CD1c" marker. |

## Required edits before wire-freeze (10)

1. **[BLOCKS HANDOFF — HIGH, rank 1]** Resolve the §6 `session_root`-vs-data-key disconnect: pick and
   state normatively ONE fork — **(A)** re-root the data/BTR schedule on `session_root` (requires
   explicitly lifting "no protocol-spec edits" for that one `PROTOCOL.md` §16.3 change), kill the
   `session_root`/`session_root_key`/`K_session` collision, extend obligation #6 to require the data
   AEAD key be a function of `session_root`; **or (B)** delete the data-keying + browser "secret PRK
   salt" sentences and re-attribute §6 to `ee`-authentication (no PRK backstop). Choose explicitly.
2. **[BLOCKS HANDOFF — MEDIUM, rank 2]** Split §9 `KEY_MISMATCH` by initiator: hostile + re-pair for a
   locally-initiated reconnect; a silent, rate-limited, non-alerting, non-pin-mutating discard for an
   unauthenticated inbound resolve-then-differ; only locally-initiated or prior-key-proving inbound may
   surface `KEY_MISMATCH`; connection-scoped, never contact-sticky. Revise obligation #7 + test L348;
   reconcile the FIX-8-vs-FIX-9 contradiction.
3. **[MEDIUM, rank 3]** §8: stop asserting the code-burning DoS "acceptable" as settled; re-characterize
   honestly (permanent, deterministic, stealthy pairing-denial by any party who learns the non-secret
   ROUTING, through an honest rendezvous); pin ROUTING fresh-per-refresh over confidential transport
   (§1 is silent); route guesses-per-code into CD2a **with availability in scope**; add a normative
   MUST-NOT — no device-wide penalty may escalate from consumed-code COUNT.
4. **[LOW, rank 4]** Strike "assert non-canonical encodings are rejected at ingress" from formal-model
   obligation #3 (keep DH(low-order,·)=0); leave non-canonical rejection to the §0 wire rule + test.
5. **[LOW, rank 5]** Fix the §0 RFC 7748 miscitation (§6.1/§7 = the all-zero/contributory abort; the
   small-order set is implementation-derived — libsodium `has_small_order` / curve25519-dalek — pinned
   under CD6); optionally restore v3's explicit value list for traceability.
6. **[LOW, rank 6]** Add the reconnect confidentiality chain to §6 + obligation #6: pairing (no SECRET ⇒
   no k_pake ⇒ no PRK) AND reconnect (no identity private key ⇒ no es/se/ss ⇒ no PRK ⇒ no session_root;
   §9 `KEY_MISMATCH` catches identity substitution before any data envelope). (Folds into fork B.)
7. **[LOW, ranks 7-8]** §1 [FIX 4]: relabel "structural / type-level" → "conforming-client property
   enforced by the MANDATORY runtime byte-scan harness"; restate the type-level clause as
   variable-confusion-only (no byte guarantee); narrow the harness to the conforming reference clients
   (Rust/WASM/TS), both delivery modes, + a mis-split / separator-fold fuzz vector; state forks/legacy
   are un-testable and out of scope.
8. **[LOW, rank 9]** §5: pin the L/R comparison basis (unsigned byte-wise over the canonical §0/CD5a
   `side_id` encoding, fail-closed on tie) OR assign L/R from the deterministic wire role (per CD1a's
   "never sort"); restate "never try-both" as a MUST-NOT with the FIX-5 negative-obligation rationale;
   add a mixed Rust↔WASM role-assignment golden vector incl. a first-differing-byte ≥0x80 `side_id` pair.
9. **[LOW, rank 11]** Add a parity requirement to the es/se golden-vector obligation: the vector MUST be
   sort-discriminating (role-L's es lexicographically greater than role-R's se) so a KCI-destroying
   sorting impl fails, mirroring the §5/§7 negative vectors.
10. **[LOW, rank 10]** Give `reconnect_handle` the same normative invariants as `contact_id`
    (locally-minted, not peer-choosable, high-entropy CSPRNG, locally-unique-on-write) or fold
    minting/uniqueness/guessability into CD1c alongside linkability; mark FIX-8's reachability
    CONTINGENT on CD1a delivering a key-carrying reconnect handshake.

## Correctly deferred to the cryptographer (6)

1. **CD2a/2b** — lockout parameters + the quantitative guessing-infeasibility budget (now with
   **availability** in scope) + a normative shower-enforced-atomic single-flight/consume pin.
2. **CD6** — PAKE primitive (CPace vs SPAKE2-0.4.0 vs SPAKE2+) + its internal point/cofactor/encoding
   validation (decides whether `pake_msg` needs canonicalization) + the final small-order set.
3. **CD4a/5a** — ROUTING grammar + anti-bleed MUST (non-alphanumeric prefix; separator not
   stripped/folded — the rendezvous strips hyphens and caps 16-alnum; disjoint alphabets) + the
   injective codec + cross-impl decoder equivalence incl. the single-code split; attach an adversarial
   "SECRET-never-bleeds-into-ROUTING" vector or forbid single-code delivery.
4. **CD1a/1b** — named Noise pattern (reconnect ≈ KK; strict-KK vs static-carrying decides whether a
   reconnect mismatch surfaces as an explicit compare or an implicit MAC failure), DH set/mixing order,
   converge es/se BY WIRE ROLE (never sort — KCI), pairing↔reconnect + §5-Expand-vs-§6-Extract domain
   separation; identity-key rotation continuity + atomicity.
5. **CD1c** — reconnect cadence + detection/revocation (a cloned key raises no `KEY_MISMATCH`) + the
   `reconnect_handle` linkability tradeoff. Must **not** be read as absorbing the rank-2 forgeable-alert
   SECURITY defect; any rotating/blinded design must preserve resolve-then-differ reachability AND the
   rank-2 quiet-inbound fix.
6. **CD7a** — native exporter + fold-locally + mixed native↔browser reconciliation with a
   non-forceable tier-select (in `capabilities[]`/TT) + a soft browser-tier-default interim rule;
   discharge the browser identity-DH-suffices lemma (which is the browser-reconnect `session_root`
   secrecy argument).

## What holds up (keep it)

Seven of nine v3 edits landed cleanly: the §8 device-lockout decouple, the well-typed
`ephemeral_shared_secret = ee` definition, the joint load-bearing anti-reflection core, the canonical
X25519 security substance, the differential CSPRNG KAT, and the rotation gating. No blocker. The two
remaining confirmed defects are precise and bounded — a claim/wire mismatch (§6) and a recurring
anonymous-inbound pattern (§9) — both with concrete fixes. After they land plus the LOW cleanups, the
review expects v4 clears for cryptographer + formal-methods handoff.
