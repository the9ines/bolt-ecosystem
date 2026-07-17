# EA1 PAKE v5 Draft — Adversarial Red-Team Report

> **Date:** 2026-07-17
> **Type:** Immutable evidence record (do not edit; corrections get their own dated entry).
> **Subject:** `os/log/decisions/2026-07-17-ea1-pake-v5-profile-draft.md` (the EA1 PAKE **v5** draft —
> adopts §6 fork A and incorporates the v4 red-team's ten required edits).
> **Method:** UltraCode adversarial review (multi-agent, read-only) — the FIFTH pass. 10 red-teamers,
> one per named focus area; every candidate break independently refuted by a verifier that sorted each
> into REFUTED / DEFERRED-TO-CRYPTOGRAPHER / CONFIRMED / PLAUSIBLE and classified survivors
> **draft-defect** vs **cryptographer-decision**. **23 candidates → 10 refuted; of 13 survivors: 3
> CONFIRMED, 4 PLAUSIBLE, 6 DEFERRED-TO-CRYPTOGRAPHER.** 34 agents, 0 errors. (Workflow run
> `wf_811c9cdc-533`. Note: the safety classifier was unavailable for one finder subagent —
> `code-burning-availability`; its finding is a benign LOW design point, verified.)

## Verdict: **NEEDS-REVISION** · cryptographer-ready: **No** — two author-text edits away

The doorstep. **No blocker. Fork A legitimately closed the v4 HIGH.** The only thing holding v5 back
from ACCEPTABLE is **the `KEY_MISMATCH` surface, once more** — **two MEDIUM draft-defects, both cheap
author-text edits, not open crypto questions.** Everything else is genuinely cryptographer-ready.
Trajectory: **v1 (no-PoP blocker) → v2 (low-order blocker) → v3 (9 edits) → v4 (2 blocking) → v5 (2
MEDIUM text edits).** The persistent surface has been `KEY_MISMATCH` — the same "untrusted party
causes an adverse verdict/state against the honest contact" class recurring on a new path each pass
(v4: anonymous inbound; v5: rendezvous-redirected locally-initiated + the rate-limiter sibling).

## The four primary checks

| Check | Result |
|---|---|
| **1. Fork-A consistency + not-treated-as-shipped** | **PASS** — a clearly-flagged *proposed* future `PROTOCOL.md` delta; not asserted as current/shipped. |
| **2. v4 HIGH closed / no shadow `session_root`** | **PASS** — obligation #6 consumes `session_root`; no unconsumed value. (One LOW: the `session_root`/`session_root_key`/`K_session` naming collision remains unreconciled in-draft — non-exploitable, does not reopen the HIGH.) |
| **3. `KEY_MISMATCH` alert-forgery closed** | **NOT FULLY** — 2 MEDIUM draft-defects (below). |
| **4. Remaining items are true cryptographer decisions** | **PASS** — all deferred items have safe, non-exploitable interims. |

## The two defects that block handoff (both MEDIUM, both author edits)

### ① CONFIRMED — `[FIX 2]`'s "no forged alert" invariant is false as written

*(draft-defect; KEY_MISMATCH / reconnect_handle)*

`[FIX 2]` (L242-244) claims "the `reconnect_handle` cannot summon a forged alert about the honest
contact (satisfies FIX-9)" — but that is justified **only** via the *inbound* silent-discard. Under
the static-carrying reconnect the draft itself writes (`PinRecord` L221 "COMPARED value" + FIX-1
L233-235), the in-model **untrusted rendezvous redirects a locally-initiated reconnect** to an
attacker who presents a self-keyed `identity_key ≠ pinned` → fires a hostile *"your contact's key
changed / re-pair"* verdict about an honest `possession_proven` contact, **with no keys and no
SECRET**. Fail-closed (no impersonation, no pin-swap), but the standing security invariant is
over-claimed — it does not cover the redirected locally-initiated path.

- **Fix (pick one):** **(A)** commit strict-KK for reconnect (CD1a) and rewrite FIX-1 so a
  redirected/forged responder on a locally-initiated reconnect yields a neutral *TAMPER/UNREACHABLE*
  state, not a distinct "your contact's key changed / re-pair" verdict; or **(B)** keep static-carrying
  but **narrow** the `[FIX 2]` claim to the **inbound** path only, and render a locally-initiated
  resolve-then-differ as a neutral *"couldn't verify B — the connection may be tampered with"* state
  (never "your contact rotated their key, re-pair"; never drop the `possession_proven` pin). In BOTH:
  add a formal obligation — **a keyless/SECRET-less rendezvous cannot cause a hostile
  contact-key-changed verdict about an honest `possession_proven` contact on ANY path** (locally-initiated
  OR inbound). Stop asserting FIX-9 is satisfied until this holds.

### ② PLAUSIBLE — FIX-1's rate-limiter scope is unpinned → reconnect-DoS on the honest contact

*(draft-defect; KEY_MISMATCH)*

FIX-1's "silent, **rate-limited** discard" is stated alongside "**connection-scoped, never
contact-sticky**," but a rate-limiter is inherently multi-connection so "connection-scoped" cannot
bind it. The natural per-handle instantiation lets an off-path handle-knower **poison Alice's throttle
so an honest rendezvous's faithful relay of Bob's reconnect is dropped** — the availability sibling of
the class FIX-1 targeted.

- **Fix:** a one-line normative §9 scope invariant (parallel to §8 L198) — **no anonymous inbound may
  throttle, drop, or delay a subsequent handshake-completing (possession-proving) inbound reconnect on
  the same `reconnect_handle`.** Gate any handle-scoped budget on completion of the identity-DH (a
  garbage key that fails the DH consumes no handle-scoped budget) and/or a global work cap that never
  sheds a connection completing a valid handshake. Route the quantitative budget to CD2a but state the
  SCOPE invariant in the draft.

### Related (a cryptographer-decision, NOT a required edit) — rank 3

FIX-1's "locally-initiated = human/**app**" (L233) makes a background **app auto-reconnect** a
locally-initiated (alert-eligible) event the untrusted rendezvous can time/spam with
true-positive-but-attacker-cadenced alerts (habituation + phishing pretext; no crypto/impersonation
break). Whether to gate user-surfacing on **human**-initiated reconnects only is a product/UX +
reconnect-cadence decision (CD1c-adjacent), a genuine tradeoff.

## Ranked findings (13, deduped)

| # | Sev | Status | Class | Surface | Break |
|---|-----|--------|-------|---------|-------|
| 1 | MEDIUM | CONFIRMED | draft-defect | KEY_MISMATCH / reconnect_handle | `[FIX 2]`'s "reconnect_handle cannot summon a forged alert" false — rendezvous redirects a locally-initiated reconnect → hostile contact-key-changed verdict about an honest contact. |
| 2 | MEDIUM | PLAUSIBLE | draft-defect | KEY_MISMATCH | FIX-1 "rate-limited" vs "connection-scoped" inconsistent; per-handle throttle poisoning drops the honest peer's reconnect (DoS). |
| 3 | MEDIUM | PLAUSIBLE | cryptographer | KEY_MISMATCH | FIX-1 "locally-initiated = human/app" → app auto-reconnect is an attacker-cadenced hostile-alert vector; gate on human-initiated only (UX/cadence call). |
| 4 | LOW | CONFIRMED | draft-defect | v4-HIGH-closure | `session_root`/`session_root_key`/`K_session` naming collision unreconciled in-draft (deferred to future-delta #3); non-exploitable, HIGH stays closed. |
| 5 | LOW | CONFIRMED | draft-defect | anti-reflection-lr | `[FIX 9]` single `es>se` es/se vector can't catch a **descending-sort** impl — needs two vectors or a role-swap negative assertion. |
| 6 | LOW | PLAUSIBLE | draft-defect | routing-secret | SECRET-off-server scoped to reference clients, but the single-code split lives upstream of the harness layer → deployed first-party products have no stated conformance path. |
| 7 | LOW | PLAUSIBLE | draft-defect | code-burning | v4 edit #3 security substance landed + correctly deferred to CD2a; residual polish — fresh-per-refresh only in §8 prose (not §1), "confidential transport" undefined, attacker models conflated. |
| 8 | LOW | DEFERRED | cryptographer | KEY_MISMATCH | "cryptographically proves possession of the prior pinned key" undefined; distinct `KEY_MISMATCH` reachability is the open CD1a strict-vs-static-KK question (safe interim: all inbound → silent discard). |
| 9 | LOW | DEFERRED | cryptographer | remaining-CDs | CD1a strict-vs-static-KK governs whether the FIX-1 tripwire exists at all; §9/§10 state it unconditionally — detection-weaker not security-weaker; propagate the caveat. |
| 10 | LOW | DEFERRED | cryptographer | browser-native/formal | Obligation #7's tripwire stated unconditionally while §9 marks it CD1a-contingent — under strict-KK it's vacuously satisfied; two-branch obligation when CD1a is pinned. |
| 11 | INFO | DEFERRED | cryptographer | remaining-CDs | As-written es/se schedule non-convergent until CD1a pins wire-role convergence — fail-safe (confirmation fails closed), zero attacker gain. |
| 12 | INFO | DEFERRED | cryptographer | remaining-CDs | Deferring the PAKE primitive (CD6) leaves `pake_msg` point-validation unstated — inert interim (reflection caught by §0 reject + §5 confirmation). |
| 13 | INFO | DEFERRED | cryptographer | remaining-CDs | 1b (new-contact-only) / 1c (stable handle linkability) / 2a (one-guess bound) interims each safe — no required edit. |

## Required edits before wire-freeze (7)

1. **[MUST FIX BEFORE HANDOFF — finding #1, CONFIRMED MEDIUM]** Correct `[FIX 2]`'s over-claim. Pick
   ONE: **(A)** commit strict-KK for reconnect and rewrite FIX-1 so a redirected/forged responder on a
   locally-initiated reconnect yields a neutral *TAMPER/UNREACHABLE* state; **or (B)** keep
   static-carrying but narrow the `[FIX 2]` "cannot summon a forged alert (satisfies FIX-9)" claim
   (L242-244) to the **inbound** path, and render a locally-initiated resolve-then-differ as a neutral
   "couldn't verify B — connection may be tampered" state (never "re-pair"; never drop the pin). In
   BOTH, add a formal obligation: **a keyless/SECRET-less rendezvous cannot cause a hostile
   contact-key-changed verdict about an honest `possession_proven` contact on ANY path.** Stop
   asserting FIX-9 is satisfied until this holds.
2. **[MUST FIX BEFORE HANDOFF — finding #2, PLAUSIBLE MEDIUM]** Add a one-line normative scope invariant
   to §9 FIX-1 (parallel to §8 L198): **no anonymous inbound may throttle, drop, or delay a subsequent
   handshake-completing inbound reconnect on the same `reconnect_handle`.** Gate any handle-scoped
   budget on completion of the identity-DH; route the quantitative budget to CD2a but state the SCOPE
   invariant in the draft. Resolves the "rate-limited" vs "connection-scoped, never contact-sticky"
   contradiction.
3. **[LOW — non-blocking for handoff]** Propagate the CD1a strict-vs-static-carrying contingency inline
   to FIX-1's bullets (L232-241), obligation #7 (L295-297), and the §10 `key_mismatch` state (L257);
   specify the strict-KK fallback (a failing locally-initiated reconnect surfaces as generic "re-pair
   needed", not a crypto-distinct `KEY_MISMATCH`; no hostile verdict, no pin mutation, no first-contact
   fall-through). Define "cryptographically proves possession of the prior pinned key" (L238-239) or
   point it at the CD1b old-key cross-cert as the sole qualifying mechanism.
4. **[LOW — non-blocking]** Resolve the `session_root`/`session_root_key`/`K_session` collision in-draft
   (no `PROTOCOL.md` edit): state that `K_session` (§5 Expand output, L139) and `session_root` (§6
   Extract output, L161) are DISTINCT and which keys data, or pick the single authoritative name now;
   optionally re-tense the three §6 phrases (L164/L172/L176) to explicit proposed/future wording.
5. **[LOW — non-blocking]** Fix the `[FIX 9]` es/se test (L314-315): require TWO sort-discriminating
   vectors (one `es>se`, one `es<se`) OR add a role-swap negative assertion (swap L↔R ⇒ PRK MUST
   differ), since a single vector cannot fail a descending-sort impl; correct "role-L's es / role-R's
   se" (es and se are each one shared value, not per-role).
6. **[LOW — non-blocking]** Normatively pin WHERE the single-code split executes and whether deployed
   first-party products are in-scope: preferred — the split MUST live in the SDK/harness-covered layer
   (products pass the raw combined code and never touch SECRET/the split, also collapsing the CD5a
   split risk); OR products MUST run the byte-scan + mis-split fuzz harness as a release gate; OR forbid
   single-combined-code delivery in products (two-separate-inputs only).
7. **[LOW — non-blocking]** Pin fresh-per-refresh as a §1 ROUTING-lifecycle MUST connected to CD4a
   (independence across refreshes); define/scope "confidential transport" (off-path eavesdroppers only;
   NO protection against continuing rendezvous-mailbox visibility); separate one-shot-observer vs
   continuing-visibility attacker models; restore the "permanent/deterministic/stealthy" adjectives for
   the sustained-DoS variant.

## Correctly deferred to the cryptographer (8, all safe interims)

1. **CD1a** — reconnect KK **strict-vs-static-carrying** (decides explicit-compare vs generic
   MAC-failure on reconnect mismatch; governs whether a distinct `KEY_MISMATCH` exists at all + the
   FIX-8 reachability + obligation #7 form + §5 L/R basis); named Noise pattern + DH set/mixing order +
   PAKE⊕Noise composition; converge es/se BY WIRE ROLE (never sort). [Owns #4, #5, #9, #10, #11; the
   crypto substance behind #1 fork A.]
2. **CD1b** — identity-key rotation continuity (old-key cross-cert vs new-contact_id-on-loss) + es/se
   KCI scope + rotation-write vs concurrent-reconnect atomicity. [#8; interim new-contact-only is safe.]
3. **CD1c** — `reconnect_handle` unlinkability (rotating/blinded) + reconnect cadence + cloned-key
   detection/revocation; MUST NOT absorb the FIX-1 quiet-inbound security fix. Natural home for #3's
   app-auto-vs-human alert-gating (product/UX). [#2, #3, #8.]
4. **CD2a/2b** — lockout parameters + quantitative guessing-infeasibility budget **with availability in
   scope** + a shower-enforced-atomic single-flight/consume pin. [Quantitative half of #2, plus #7.]
5. **CD4a** — ROUTING grammar + anti-bleed MUST (non-alphanumeric prefix; separator not stripped/folded;
   disjoint alphabets) + SECRET entropy/MHF + fresh-ROUTING independence-across-refreshes. [#6, #7.]
6. **CD5a** — injective byte-layout freeze via a verified codec + cross-impl decoder equivalence
   including the single-code split determinism. [Collapses to one impl if #6's split-in-SDK is adopted.]
7. **CD6** — PAKE primitive (CPace vs SPAKE2-0.4.0 vs SPAKE2+) + internal point/cofactor/encoding
   validation (decides whether `pake_msg` needs canonicalization) + final small-order set +
   unaudited/not-constant-time HIGH sign-off. [#12.]
8. **CD7a** — native exporter + fold-locally + mixed native↔browser reconciliation with a non-forceable
   tier-select + soft browser-tier-default; discharge the browser identity-DH-suffices lemma.

## What holds up (keep it)

Fork A is validated: it closes the v4 HIGH honestly (data now roots on `session_root`, which is
consumed, not a shadow value) while correctly framing the required wire change as a *proposed* future
`PROTOCOL.md` delta the cryptographer reviews — not asserted as shipped. The KEY_MISMATCH security half
(no impersonation, no pin-swap, fail-closed) holds; the two remaining defects are about a **verdict
surfaced to the human** and a **throttle scope**, both bounded and both fixed by author text. Eight
substantive items are correctly scoped for the cryptographer with safe interims. Recommendation for the
next revision: state the class-level invariant **once** — no keyless/SECRET-less party may cause an
adverse verdict/state against an honest `possession_proven` contact on ANY path — rather than patch the
recurring class path-by-path. After the two edits (+ the LOW cleanups), the review expects v5's
successor clears for external cryptographer + formal-methods review.
