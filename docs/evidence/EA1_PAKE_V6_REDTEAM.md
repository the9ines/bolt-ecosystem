# EA1 PAKE v6 Draft — Adversarial Red-Team Report

> **Date:** 2026-07-17 (review run; recorded 2026-07-18)
> **Type:** Immutable evidence record (do not edit; corrections get their own dated entry).
> **Subject:** `os/log/decisions/2026-07-17-ea1-pake-v6-profile-draft.md` (the EA1 PAKE **v6** draft —
> adds the class-level §AV Adverse-Verdict Invariant, retains §6 fork A, and lands the v5 review's two
> MEDIUM fixes + six LOW cleanups).
> **Method:** UltraCode adversarial review (multi-agent, read-only) — the SIXTH pass. 12 red-teamers,
> one per named focus area; every candidate break independently refuted by a verifier that sorted each
> into REFUTED / DEFERRED-TO-CRYPTOGRAPHER / CONFIRMED / PLAUSIBLE and classified survivors
> **draft-defect** vs **cryptographer-decision**. **25 candidates → 13 refuted; of 12 survivors: 4
> CONFIRMED, 1 PLAUSIBLE, 7 DEFERRED-TO-CRYPTOGRAPHER.** 38 agents, 0 errors. (Workflow run
> `wf_df09d584-412`. Note: the safety classifier was unavailable for one finder subagent —
> `rotation-linkability-revocation`; its finding is a deferred cryptographer-decision, verified benign.)

## Verdict: **NEEDS-REVISION** · cryptographer-ready: **No** — one localized text fix away

The closest pass yet, and the §AV bet paid off. **No blocker. §AV holds on all paths**, and the
`key_mismatch` removal is a **net improvement, not a regression** ("a forgeable keyless-summonable
tripwire replaced by an honest neutral state"). The recurring `KEY_MISMATCH`/adverse-state class — which
surfaced on a new path for five straight passes — is now closed at the class level. What remains is
**exactly one CONFIRMED MEDIUM draft-defect** (a factual naming error introduced in the v6
"K_session retirement" cleanup) plus three cheap LOW editorial cleanups. Trajectory: **v1 (no-PoP
blocker) → v2 (low-order blocker) → v3 (9 edits) → v4 (2 blocking) → v5 (2 MEDIUM) → v6 (1 MEDIUM
spec-consistency fix).**

## The three primary checks

| Check | Result |
|---|---|
| **1. §AV holds on all paths + no new regression** | **PASS** — holds everywhere; the §10 `key_mismatch` removal is a net improvement, not a regression; only a LOW §10-copy wording drift remains. |
| **2. Fork A: not-shipped / no-shadow / consistent** | not-shipped **PASS** (`PROTOCOL.md` verified untouched, `ee`-rooted/`salt=EMPTY`, edits forbidden), no-shadow **PASS** (`session_root` consumed, obligation #6), but **consistency FAILS** on the §5/§6/L332 false "no `session_root_key`" resolution — the one CONFIRMED MEDIUM. |
| **3. Remaining items are true cryptographer decisions** | **PASS** — CD1a/1b/1c/2a/6/7a with safe interims + a LOW model-facing restatement; other draft-defects are LOW/PLAUSIBLE editorial. |

## The one defect that blocks handoff (MEDIUM)

**§5 fork-A "naming resolution" falsely denies the canonical `session_root_key`.** *(draft-defect;
fork-A-consistency; CONFIRMED)*

The v6 "K_session retirement" cleanup over-reached: §5 (L171-172, echoed §6 L189-190, test-obligation
L332) asserts *"there is no separate `session_root_key` / all data/BTR keying references
`session_root`"*. But — verified against canonical `PROTOCOL.md` — **`session_root_key` is a real,
load-bearing, *ratcheting* BTR root**: derived at §16.3 L1078-1083, seeds `transfer_root_key`
(L1091-1096), advanced by the inter-transfer DH ratchet (L1133-1138), per-session lifecycle
(L1175/1201/1205), the subject of **BTR-INV-01** (L1219), tied to per-transfer self-healing forward
secrecy via BTR-INV-05/09 (L1313), and an existing conformance-vector value (L1464-1465).

- Consequently §5's denial is **factually false** about the spec fork A modifies, **internally
  contradicts** the draft's own delta *"restate BTR-INV-01"* (which presupposes `session_root_key`
  exists), and — read literally, or built into a conformance vector per L332 — **collapses per-transfer
  forward secrecy to a static flat schedule.**
- **Not a blocker** (nothing exploitable: `PROTOCOL.md` is verified untouched and still
  `ee`-rooted/`salt=EMPTY`; L92/L343 forbid editing it; the FS collapse is doubly conditional on fork-A
  implementation **and** following the literal flat wording over the two-level delta intent). But a
  cryptographer reading §5 against §16.3 hits it immediately → **handoff-gating.**
- **Fix (two-level correction):** replace §5/§6/L332 with — *"`session_root` **seeds** the generation-0
  BTR `session_root_key` (`session_root_key = HKDF(ikm = session_root, info = "bolt-btr-session-root-v1")`,
  replacing the current `salt=EMPTY`/`ikm=ephemeral_shared_secret` seed at `PROTOCOL.md` L1078-1083); the
  BTR key hierarchy, the inter-transfer DH ratchet (`session_root_key → transfer_root_key →
  chain/message keys`), and BTR-INV-01..11 are **retained** — only the gen-0 seed changes from `ee` to
  `session_root`."* Reconcile the same flat-schedule error in §6 L189-190 and test-obligation L332, and
  align delta L98 to *"re-seed the BTR `session_root_key` from `session_root`; restate BTR-INV-01
  accordingly."* Keep "`K_session` is retired" (that part is correct). Obligation #6 is unchanged and
  still satisfied.

## The three LOW cleanups (should land before wire-freeze; non-blocking for handoff)

- **§9 rate-limiter honesty (CONFIRMED LOW):** "a global anti-spam cap that never sheds a connection
  completing a valid handshake" (L250-251) is **unsatisfiable as an absolute** — validity is only
  knowable post-DH, so it cannot be honored pre-admission. §AV (adverse-*verdict*, not availability)
  holds and the v5 post-DH contact-sticky fix is genuine, but §9 must soften the clause to
  design-intent/best-effort, scope "resolves the contradiction" to the v5 budget-scope inconsistency,
  **mirror §8's honest availability-DoS disclosure** (a keyless party incl. the untrusted rendezvous
  knowing the wire-visible handle CAN degrade honest reconnect availability via a pre-DH
  connection-slot / scalar-mult flood), and route reconnect availability to CD2a with a named lever.
  Keep the post-DH-only contact-sticky budget rule verbatim.
- **§5 es/se test obligation (CONFIRMED LOW):** "swap L↔R ⇒ PRK MUST differ" (L174-176) is coherent
  only if L/R == wire role, but §5 permits L/R by sorted `side_id` (PRK-invariant), so it **false-fails
  a correct impl**; and the two-vector form **passes a signed-descending sort** with a straddling
  vector. Fix by mandating a **wire-role-phrased** role-swap-negative (*"swap initiator↔responder ⇒
  es/se transpose ⇒ PRK MUST differ"*), decoupled from the §5 confirmation-role L/R basis; if the
  two-vector form is retained, force the first-differing bytes to straddle 0x80.
- **§0 clamping premise (PLAUSIBLE LOW):** the all-zero-DH abort is a complete low-order/twist backstop
  **only because** X25519 clamps secret scalars to `8|k`; the draft specifies X25519 so a conforming
  impl is safe, but only `ee` gets an explicit clamped formula and obligation #3 / "ideal-DH" never name
  clamping. Extend the clamped-X25519 pin to `es/se/ss` and name RFC 7748 clamping as the completeness
  premise in obligation #3 (so the CD6 blacklist reads belt-and-suspenders, not load-bearing).

*(Optional, no-crypto hardening, non-blocking: restore "(in `capabilities[]`/TT)" to §6 L195 and CD7a
L290 — a v5→v6 DiD tier-select pin that was dropped; LOW, no mechanical break.)*

## Ranked findings (10, deduped)

| # | Sev | Status | Class | Surface | Break |
|---|-----|--------|-------|---------|-------|
| 1 | MEDIUM | CONFIRMED | draft-defect | fork-A-consistency | §5/§6/L332 falsely deny the canonical ratcheting `session_root_key`; contradicts §16.3 + the draft's own delta; literal reading collapses per-transfer FS. |
| 2 | LOW | CONFIRMED | draft-defect | rate-limiter | §9 "never sheds a valid handshake" unsatisfiable-as-absolute + "resolves the contradiction" overclaim; §AV itself holds. |
| 3 | LOW | CONFIRMED | draft-defect | es/se test | Role-swap-negative conflates confirmation-role L/R with wire role; two-vector form passes a signed-descending sort. |
| 4 | LOW | PLAUSIBLE | draft-defect | §0/X25519 | All-zero backstop + obligation #3 rely on an unstated clamping premise; `es/se/ss` not explicitly pinned to clamped X25519. |
| 5 | LOW | DEFERRED | cryptographer | av-detection | §AV detection-regression refuted as a break (fail-closed holds; keyless MITM can't complete the handshake — only the announcement is missing); responded-vs-unreachable split + bounded OOB re-verify is additive, CD1c-owned; §10 copy = LOW editorial. |
| 6 | LOW | DEFERRED | cryptographer | rotation | Old-key-cross-cert rotation enables post-compromise pin-laundering by a **non-keyless** old-key thief (outside §AV); safe new-contact-only branch exists; CD1b. |
| 7 | LOW | DEFERRED | cryptographer | browser-native | v5→v6 regression: exporter tier-select no longer pinned into `capabilities[]`/TT → native require-binding floor on-path strippable (DiD detection only, no mechanical break); restore the pin, CD7a binds tier-select to the authenticated transcript. |
| 8 | LOW | DEFERRED | cryptographer | formal-model | §AV/obligations #0/#7 are safety-only (nothing falsely emitted) with no positive-detection/liveness companion; add a scope line; positive detection → CD1b, clone-detection → CD1c. |
| 9 | LOW | DEFERRED | cryptographer | open-items | §AV consequence-3 rotation authorizer: "identity-DH against the old pinned key" disjunct doesn't bind K_new; not reachable under the §9 interim; fold "possession-of-old-key alone never authorizes a write to an unbound new key" into CD1b. |
| 10 | INFO | DEFERRED | cryptographer | reconnect_handle | Stable `reconnect_handle` metadata-linkability is an acceptable handoff interim (grants no summon/DoS/verdict power; rotating/blinded → CD1c). |

## Required edits before wire-freeze (5)

1. **[HANDOFF-GATING — the only one, CONFIRMED MEDIUM]** Fix the fork-A §5 naming resolution: delete
   "there is no separate `session_root_key`" and "all data/BTR keying references `session_root`"
   (§5 L171-172); replace with the two-level seed relationship (`session_root` seeds the gen-0
   `session_root_key = HKDF(ikm=session_root, info="bolt-btr-session-root-v1")` replacing the current
   `salt=EMPTY`/`ikm=ee` seed at `PROTOCOL.md` L1078-1083; the BTR hierarchy + inter-transfer DH ratchet
   + BTR-INV-01..11 are retained; only the gen-0 seed changes `ee`→`session_root`). Reconcile §6
   L189-190 and test-obligation L332 (else a conformance vector codifies the FS-broken flat schedule and
   contradicts the existing btr-key-schedule/btr-transfer-ratchet vectors at `PROTOCOL.md` L1464-1465);
   align delta L98. Keep "`K_session` retired". Obligation #6 unchanged and still satisfied.
2. **[LOW — non-blocking]** §9 rate-limiter: soften the unsatisfiable absolute (L250-251) to
   best-effort; scope "resolves the contradiction" (L252-253) to the v5 budget-scope inconsistency;
   mirror §8's honest availability-DoS disclosure; route reconnect availability to CD2a with a named
   lever. Keep the post-DH-only contact-sticky budget rule verbatim.
3. **[LOW — non-blocking]** es/se test obligation: mandate a wire-role-phrased role-swap-negative
   (L174-176/L333) decoupled from the §5 confirmation-role L/R; if the two-vector form is retained,
   force first-differing bytes to straddle 0x80.
4. **[LOW/PLAUSIBLE — non-blocking]** Extend the explicit clamped-X25519 pin from `ee` (§6 L182) to
   `es/se/ss`; restate obligation #3 + the §0 "self-sufficient backstop" wording (L111-112) to name RFC
   7748 clamping (secret scalars ≡ 0 mod 8) as the completeness premise.
5. **NOTE:** apart from item 1 (the sole CONFIRMED MEDIUM handoff-blocker), NO other draft-defect blocks
   the cryptographer handoff — items 2-4 are LOW/PLAUSIBLE editorial cleanups that make the formal/test
   package self-consistent and should land before wire-freeze but are non-blocking for the review gate.
   Optional no-crypto hardening: restore "(in `capabilities[]`/TT)" to §6 L195 and CD7a L290.

## Correctly deferred to the cryptographer (7, all safe interims)

1. **CD1a** — reconnect KK strict-vs-static-carrying (both branches → §AV neutral); named Noise pattern +
   DH set/mixing order + PAKE⊕Noise composition sign-off; converge es/se BY WIRE ROLE (never sort); pin
   a single L/R confirmation-role basis coincident with the es/se-order convention.
2. **CD1b** — identity-key rotation as the SOLE "device key updated" verdict path: MUST bind `K_new` to
   the `K_old`-authenticated proof (transcript-bind `K_new` or old-key cross-cert over `K_new`) so
   possession-of-old-key alone never writes an unbound new key; prefer new-contact-only with an inline
   KCI/PCS caveat; es/se KCI scope; rotation-write vs concurrent-reconnect atomicity.
3. **CD1c** — reconnect cadence + cloned-key detection/revocation + `reconnect_handle` unlinkability
   (rotating/blinded); app-auto-vs-human alert-gating including the additive-on-top-of-§AV
   responded-but-failed split (`tamper_suspected` vs unreachable + bounded honest non-attributed OOB
   re-verify after N failures); MUST NOT absorb/weaken §AV.
4. **CD2a** — quantitative availability / rate-limit / guesses-per-code budget with availability in
   scope, including reconnect pre-DH flood resistance (stateless retry-cookie / per-handle admission cap
   / PoW), scoped best-effort given the CD1b concurrent-reconnect-atomicity ↔ no-shed tension.
5. **CD6** — PAKE primitive + internal point/cofactor/encoding validation + final small-order set;
   clamped X25519 makes the deferred blacklist belt-and-suspenders, not load-bearing.
6. **CD7a** — native exporter fold-locally + mixed native↔browser reconciliation: make tier-select
   NON-FORCEABLE by binding the tier/exporter-capability signal into the authenticated transcript;
   do NOT ship a "soft browser-tier-default" that accepts an unauthenticated tier signal (prefer
   fail-closed-to-require-binding when both authenticated capabilities advertise exporter support);
   discharge the browser identity-DH-suffices lemma.
7. **Formal-model scope (LOW, non-blocking)** — §AV/obligations #0/#7 certify the SAFETY half only; add
   a scope line that positive detection (a prior-key-proven rotation MUST eventually surface "device key
   updated") is deferred to CD1b and clone/exfiltrated-key detection to CD1c; consider a companion
   liveness/positive-detection obligation dual to #0/#7.

## What holds up (keep it)

**§AV worked.** The class-level Adverse-Verdict Invariant closed, once, the `KEY_MISMATCH`/adverse-state
class that recurred on a new path across v4/v5 — it holds on all paths, and removing the hostile
`key_mismatch` alert is a genuine security improvement (a keyless-summonable forgeable tripwire replaced
by an honest neutral `tamper_unreachable` state), not a regression. Fork A remains not-shipped and
shadow-free. The one remaining MEDIUM is a localized draft-text / spec-consistency error (an
over-flattening of the BTR schedule under fork A), correctable in-draft against the canonical
`PROTOCOL.md §16.3`. After that single fix (+ the three LOW cleanups so the formal/test package is
self-consistent), the review's read is that the successor draft clears for external cryptographer +
formal-methods review.
