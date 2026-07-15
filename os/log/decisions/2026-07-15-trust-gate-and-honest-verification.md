# Decision: Trust-Gate Authorization Hardening + Honest Verification (Track B)

> **Date:** 2026-07-15
> **Status:** Decided + SHIPPED (Track B items 1-6). This ADR gives the workstream decisions a
> stable home ahead of the Governance OS v2 Phase 4 tracker thinning.
> **Scope repo:** bolt-daemon, localbolt-app (macOS Swift), localbolt-v3 (web SDK).
> **Workstream:** TRUST-GATE-CENTRALIZE-1 (+ NATIVE-PAIRING-ASK-1, HONEST-VERIFY-1).
> **Supersedes / reconciles:** EA2 is the daemon side of SA10 (web-SDK-only fix, never ported).
> The `SUPERSEDED-BY` tokens on the SA-series tracker rows are deferred to Phase 4 (no tracker-row
> rewrites in Phase 3).

## Context

The EA-series audit found the daemon's trust enforcement was a per-transport caller
responsibility that several paths skipped, the native app launched deny-nothing, and the products
shipped a false "verified" state — all while real device verification (EA1) does not yet exist.
Findings: EA2/EA3/EA4/EA26/EA27/EA28/EA29 in `docs/AUDIT_TRACKER.md`; evidence in
`docs/evidence/EA3_REDTEAM.md` and `docs/evidence/EA4_REDTEAM.md`.

## Decision (Evan's choices, all shipped, each mutation-verified + committed separately)

1. **Centralize + fail closed.** `enforce_session_trust` denies on a missing `trust_config`; the
   WebTransport path is gated like WS/QUIC; the attacker-settable `legacy` HELLO is rejected on
   both the offerer and answerer branches (EA2/EA3). Authorization gating only — never a
   verification claim.
2. **Deny by default on the native app.** Launch bolt-daemon with `--pairing-policy ask`, not
   `allow`; move the identity/trust store off the predictable `/tmp` path to the platform default
   (EA4 near-term + EA8). The FULL EA4 fix (interactive prompt + any verified pin) is
   **DESIGN-LOCKED behind EA1** — not built.
3. **Honest verification, no rename (EA29).** Products no longer claim "Verified", persist a
   `verified:true` pin, or auto-trust on reconnect. User-facing "Verified" → "Approved for this
   session"; approval is session-scoped and not persisted; a stored verified flag is never used to
   skip the SAS. The internal `verified` enum name is kept (the breaking canonical rename is
   deferred to a typed-future migration).
4. Real device verification stays **deferred to EA1** (see the adopt-PAKE ADR).

## Out of scope

No EA1 / PAKE work; no EA4 prompt wiring; no canonical `VerificationState` enum rename; no SOC 2.
Residual OPEN in the tracker (untouched here): EA5 (browser pin keyed on peer code), EA27
(`ACTIVE_SESSION` single-global race), EA28 (WT `session.connected`/`session.sas` observability).
