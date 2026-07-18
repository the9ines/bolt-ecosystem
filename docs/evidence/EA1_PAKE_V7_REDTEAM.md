# EA1 PAKE v7 Draft — Adversarial Red-Team Report

> **Date:** 2026-07-18
> **Type:** Immutable evidence record (do not edit; corrections get their own dated entry).
> **Subject:** `os/log/decisions/2026-07-18-ea1-pake-v7-profile-draft.md` (the EA1 PAKE **v7** draft —
> corrects the v6 BTR-schedule over-flattening so fork A *re-seeds* the ratchet, and lands the v6
> review's four LOW cleanups).
> **Method:** UltraCode adversarial review (multi-agent, read-only) — the SEVENTH pass. 12 red-teamers,
> one per named focus area; the fork-A/BTR red-teamer was given canonical `bolt-protocol/PROTOCOL.md`
> and instructed to verify the two-level re-seed correction **line-by-line against §16.3**. Every
> candidate break independently refuted; survivors classified **draft-defect** vs
> **cryptographer-decision**. **12 candidates → 6 refuted; of 6 survivors: 1 CONFIRMED, 2 PLAUSIBLE,
> 3 DEFERRED-TO-CRYPTOGRAPHER.** 25 agents, 0 errors. (Workflow run `wf_735aaf7b-425`.)

## Verdict: **ACCEPTABLE-FOR-CRYPTOGRAPHER-REVIEW** · cryptographer-ready: **Yes**

After seven adversarial passes, EA1 is design-complete for external review. **No blocker, no confirmed
HIGH/MEDIUM draft-defect, all three primary checks pass** — the fork-A check verified line-by-line
against `PROTOCOL.md §16.3` (the same grounding that caught the v6 error), so the clearance is
trustworthy, not optimistic. The crypto core, the fork-A two-level re-seed, and the §AV invariant are
sound and internally consistent; a professional cryptographer + formal-methods reviewer is the correct
next step.

**The seven-pass convergence** (each pass found a real, fixable defect; the loop stopped finding
protocol-breaking ones): **v1 (no-PoP BLOCKER) → v2 (low-order BLOCKER) → v3 (9 required edits) → v4 (2
blocking) → v5 (2 MEDIUM) → v6 (1 MEDIUM) → v7 (ACCEPTABLE).**

## The three primary checks — all PASS

| Check | Result |
|---|---|
| **1. Fork-A BTR re-seed correct vs §16.3** | **PASS, verified line-by-line.** v7 §6 re-seeds the generation-0 root `session_root_key` from the authenticated `session_root`, replacing the canonical `salt=EMPTY`/`ikm=ephemeral_shared_secret` seed (§16.3 L1078-1083), and **RETAINS** `transfer_root_key`→chain/message keys (L1091-1096), the inter-transfer DH ratchet (L1125-1145), BTR-INV-01..11 (L1219-1229), and per-transfer forward secrecy (L1372) — only the gen-0 seed changes `ee`→`session_root`, with the BTR-INV-01 restatement correctly flagged. The v6 over-flattening MEDIUM is **CLOSED**; the delta is explicitly **NOT shipped** (this gate does not edit `PROTOCOL.md`; the proposed future delta is gated on cryptographer + formal-model sign-off). |
| **2. §AV holds on all paths, no regression** | **PASS.** §AV is retained verbatim, normative, formal-obligation #0; it governs the §9 reconnect outcomes and the §10 neutral `tamper_unreachable` state (hostile `key_mismatch` removed); every surviving finding confirms §AV intact and NOT absorbed ("MUST NOT absorb §AV"). |
| **3. Remaining items are true cryptographer/formal decisions** | **PASS.** 4 of 6 survivors are cryptographer-decisions; the 2 draft-defects are 1 PLAUSIBLE-MEDIUM (§1 product-conformance completeness) + 1 CONFIRMED-LOW (obligation #3↔#6 DH-set alignment). No CONFIRMED HIGH/MEDIUM draft-defect; no blocker. |

## Surviving findings (6) — none block cryptographer handoff

| # | Sev | Status | Class | Finding |
|---|-----|--------|-------|---------|
| 1 | MEDIUM | PLAUSIBLE | draft-defect | **§1 product-handling gap** — a §1-conforming *hosted* product (SDK does the split; byte-scan harness passes) can still leak the SECRET-bearing combined code to a server via its own deep-link / analytics / error-reporting egress, enabling an active PAKE MITM. The certified reference display+type path is safe, so this is a spec-completeness gap needing a normative §1 product-handling MUST — orthogonal to the primitive/key-schedule; **pre-wire-freeze, not pre-handoff.** |
| 3 | LOW | CONFIRMED | draft-defect | **5th-DH scope mismatch** — §0/obligation #3 (point-validity on `ee/es/se/ss`, 4 DHs) omits the *fifth* X25519 DH that fork A retains and models in obligation #6: the BTR inter-transfer ratchet `dh_output = X25519(new_ratchet_sec, remote_ratchet_pub)` (§16.3 L1130), which has no small-order/all-zero abort in §16.6/§16.7. Non-exploitable (ratchet key inside the authenticated Poly1305 envelope; `dh_output` feeds only as ikm under the secret `current_session_root_key` salt) — a one-clause completeness fix, not a break, and not a v7 regression (pre-existing §16.3 posture). |
| 2 | LOW | PLAUSIBLE | cryptographer | `reconnect_handle` property bundle not jointly realizable as written (establishment scheme unstated; single-field record vs both directions; "not peer-choosable" mechanism-dependent). Safety is §AV-neutered (identity-DH possession, independent of the handle); establishment/privacy → CD1c, availability → CD2a. Soften the flat PinRecord assertions to "target properties, scheme pending CD1c." |
| 4 | LOW | DEFERRED | cryptographer | HKDF info label `bolt-btr-session-root-v1` reused for the changed gen-0 derivation — versioning-hygiene (fail-closed: divergent keys → `RATCHET_DECRYPT_FAIL`). Scoped to the future `PROTOCOL.md` delta, where §17.6 change-control mandates the label bump + §17.6.2 compatibility/security-impact note. |
| 5 | LOW | DEFERRED | cryptographer | Layered HKDF chain reuses PRK as the §5 HKDF-Expand key AND the §6 HKDF-Extract salt (+ re-mixes `ee`) — sound under standard HMAC-PRF assumptions; the reductionist key-schedule proof must discharge domain-separation / PRF-independence (owned by CD1a / obligation #10). Optional no-security-delta refactor: single `Extract→PRK→Expand(distinct info)`. |
| 6 | LOW | DEFERRED | cryptographer | §4 "equality reject over canonical encodings" is unbacked for `pake_msg` (no canonical encoding until CD6 defines the primitive); `pake_msg` reflection is defeated by the load-bearing §5 direction-separated confirmation (no SECRET ⇒ no `k_pake`). A one-line scope clarification + a CD6 canonicalization deliverable. |

## Required edits before **WIRE-FREEZE** (2 — explicitly NOT pre-handoff blockers)

Wire-freeze is a *later* gate than cryptographer handoff. Neither item blocks the external review; both
are the only two genuine draft-defects (the other four survivors are cryptographer-decisions/LOWs).

1. **[MEDIUM, PLAUSIBLE — §1 product-handling]** Land a normative §1 product-handling MUST: the raw
   combined code is **SECRET-classified end-to-end** — a product MUST NOT log, persist, place in a URL
   query or fragment, or transmit to ANY server (analytics / telemetry / error-reporting / own-backend /
   rendezvous) the raw combined code; only the SDK-derived ROUTING is server-shareable. Mandate the
   two-separate-inputs path for any product with a server-facing code surface (all hosted/commercial
   web products), reserving single-combined-code for products with no server-facing code surface.
   Reconcile §1 with obligation #9 — either narrow the split-in-SDK closure claim ("the SDK does not
   leak SECRET; the product remains responsible for the raw combined code"), OR extend the mandatory
   byte-scan harness to a product-integration egress lint scanning all product server-facing egress as
   a release gate.
2. **[LOW, CONFIRMED — 5th-DH]** Align obligation #3 (point-validity, currently `ee/es/se/ss`) and
   obligation #6 (models the retained BTR ratchet) on the SAME X25519 DH set: either extend the
   constant-time all-zero abort to the BTR inter-transfer `dh_output` (§16.3 L1130 — cheap
   belt-and-suspenders that also turns the marginal post-compromise self-heal-nullification into a
   fail-closed abort), OR explicitly scope the ratchet DH OUT of obligation #3 with the stated
   rationale (arrives inside the authenticated post-handshake envelope; HKDF-salted with the secret
   `current_session_root_key`, so a small-order/zero `dh_output` is neither keyless-injectable nor
   predictable). Zero runtime exposure today.

## Deferred to the cryptographer + formal-methods reviewer (the handoff package)

1. **[fork-A HKDF label — future delta]** Bump the gen-0 info label (e.g. `bolt-btr-session-root-v2` /
   a PAKE-profile domain tag) or bind the re-seed to a distinct negotiated capability; attach the
   §17.6.2 compatibility + security-impact note (fork A's gen-0 schedule is interop-incompatible with
   the `ee`-seeded schedule).
2. **[PAKE⊕Noise composition — CD1a / obligation #10]** The reductionist sign-off must name and
   discharge the non-canonical schedule: PRK as BOTH §5 Expand-key AND §6 Extract-salt, plus the
   redundant `ee` re-mix — establishing domain-separation / PRF-independence.
3. **[reconnect_handle establishment — CD1c + CD2a]** Pin the handle establishment / mutual-agreement /
   not-peer-choosable reconciliation and deterministic-pre-emption/squat availability (per-side inbox
   handles exchanged inside the §5-confirmation-MAC'd transcript, or a derived-handle alternative);
   `reconnect_handle` privacy already NOT certified here → CD1c.
4. **[pake_msg validation — CD6]** Own `pake_msg` internal point/cofactor/encoding validation and
   enumerate `pake_msg` canonicalization/equality-compare as an explicit CD6 deliverable.
5. **[full CD set + formal package]** PAKE primitive selection incl. the unaudited/not-constant-time
   HIGH sign-off (CD6); Noise pattern + es/se convergence-by-wire-role + composition (CD1a); rotation
   continuity binding `K_new` to the `K_old` proof (CD1b); reconnect cadence + cloned-key detection +
   `reconnect_handle` unlinkability (CD1c); lockout + quantitative guessing+availability budget incl.
   pre-DH flood levers (CD2a/2b); ROUTING grammar/entropy/anti-bleed (CD4a); injective byte-layout codec
   freeze (CD5a); native exporter + mixed native↔browser reconciliation (CD7a); **and the formal-model
   pass over the proposed two-level fork-A schedule + §AV (obligations #0–#10)** — the hard wire-freeze
   gate, alongside authoring + authorizing the required `PROTOCOL.md` delta.

## What holds up (keep it)

The whole design. The type-a-secret PAKE + identity-DH direction, the §0 clamped-X25519 point validation,
the fork-A two-level BTR re-seed (ratchet retained), the joint load-bearing anti-reflection confirmation,
the class-level §AV invariant, the honest non-"verified" product states, and the honest availability
disclosures are sound and internally consistent. EA1 is **design-complete for external cryptographer +
formal-methods review** — it is **not** implementation-ready: wire-freeze remains gated on the resolved
`[CRYPTO-DECISION]` set, the authored+authorized `PROTOCOL.md` delta, the cryptographer sign-off, and a
passing formal model. The seven-pass adversarial loop has converged.
