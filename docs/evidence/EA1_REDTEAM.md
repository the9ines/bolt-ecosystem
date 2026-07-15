# EA1 Pairing Design: Consolidated Red-Team Report

**Verdict: HAS-BLOCKERS. Do not write protocol code yet.**

Seven red-teamers produced 40-plus findings. After dedup they collapse to **6 blockers, 7 high, 10 medium, 2 low**, plus one cross-cutting fact: the design's central security claim is false as written.

## The root defect (why the claim fails)
The design says a MITM "must commit to its per-side ephemeral before seeing the victim's key, so it gets ONE blind guess." That is false. The commitment covers only the ephemeral, but the SAS also binds the attacker-chosen Ed25519 identity keys, which are uncommitted and revealed AFTER the commit-reveal. An active MITM runs the ephemeral commit-reveal honestly on both legs, then birthday-grinds roughly 2^15 to 2^16 throwaway Ed25519 identities per leg OFFLINE until the two displayed SAS values collide, signs valid PoP under keys it owns, and both humans confirm identical codes. Residual success is about 1 per session at a 30-bit SAS, with zero online mismatches. Raising the SAS to 30/40/48 bits does not help: this is an offline birthday search (about 2^(b/2) work), so only committing the right variables stops it, not SAS length. Three of the seven found this independently. That is why the verdict is HAS-BLOCKERS.

## Ranked, deduped findings

| Sev | Finding | Consolidates |
|-----|---------|--------------|
| BLOCKER | Identity not committed, so the SAS is offline-grindable and commit-reveal is bypassed | 3 reports |
| BLOCKER | Commitment is vacuous on current signaling (offerer ephemeral rides in the first message) | 3 reports |
| BLOCKER | Downgrade/mode-select acted on before authenticated; rendezvous routes both peers to a no-SAS path (legacy/cross-transport/cap-strip) | 4 reports |
| BLOCKER | Untyped pins; v1/v2 byte-indistinguishable; honest upgrade fires KEY_MISMATCH fleet-wide | 1 report |
| BLOCKER | No canonical transcript encoding; Rust vs TS cap-order drift breaks honest peers | 2 reports |
| BLOCKER | Human ceremony (passive confirm + transfer nudge) collapses the bound to click-through | 2 reports |
| HIGH | Symmetric role-less signature, no key confirmation, circular ordering (UKS/reflection) | 3 reports |
| HIGH | Ed25519 verify-semantics divergence (tweetnacl vs dalek); no single signing authority | 2 reports |
| HIGH | X25519 to Ed25519 key reuse unspecified (one generator primes scalar reuse) | 1 report |
| HIGH | Caps bind the intersection not the advertisement; no mandatory floor (invisible strip) | 1 report |
| HIGH | "verified" carries no strength/version record; pin keyed on peer code not identity | 2 reports |
| HIGH | Pin vs verify conflated: goal (e) regresses continuity; pre-SAS pin launders MITM | 2 reports |
| HIGH | "verified" is unilateral; mismatch not hostile; forced retries amplify the guess | 1 report |
| MEDIUM | No X25519 canonical/small-order validation (attacker-known key pre-SAS) | 3 reports |
| MEDIUM | Keys not actually transcript-bound in the schedule (no channel binding yet) | 2 reports |
| MEDIUM | Check ordering not fail-closed (SAS shown before commit/PoP verified) | 2 reports |
| MEDIUM | v1-pin invalidation lazy, non-atomic, fails open (no DB_VERSION bump) | 1 report |
| MEDIUM | Mass migration resets whole population to first-contact TOFU at once | 1 report |
| MEDIUM | Transfer gate is UI-only; sendFile() has no verification check | 1 report |
| MEDIUM | No transport/DTLS binding and no per-session hvi in the commit | 2 reports |
| MEDIUM | Re-pair/re-verify fatigue is an unbounded amplifier (no rate limit) | 1 report |
| MEDIUM | SAS rendering unspecified; raw hex today (confusable glyphs) is worst for read-aloud | 1 report |
| MEDIUM | Constant-time requirement is misdirected (names moot compares, omits scalarmult/signing) | 1 report |
| LOW | commit_nonce underspecified (no length/CSPRNG/freshness) | 1 report |
| LOW | SAS/AEAD domain separation and exact bit budget need review | 1 report |

## The four load-bearing changes
1. Commit EVERY attacker-controlled SAS input (identity, ephemeral, caps, version) with symmetric dual commitment before either reveals; fail-closed ordering.
2. Remove ephemerals from the first signaling message; make commit-before-reveal a conformance-tested invariant across all transports.
3. One canonical Rust/WASM transcript codec with cross-language golden vectors.
4. Replace passive "Mark Verified" with an active, forced, block-default comparison decoupled from the transfer unlock.

## A correction on secret-derived SAS
One red-teamer recommends deriving the SAS from the DH secret (ZRTP-style) and states this "stops grinding any public input." That framing is imprecise in the two-leg MITM model: the MITM owns BOTH DH secrets and can still birthday-grind any uncommitted public input that feeds the SAS. The anti-grind property comes from the COMMITMENT covering every attacker input, not from secret-derivation. Derive the SAS from HKDF(DH, H(transcript)) anyway for channel binding (SAS-match implies key-match), but do not treat it as the anti-grind mechanism. This is one of several points the external cryptographer must ratify.

## Migration and pins are a second, independent front
Even with the crypto fixed, the migration as written is unshippable. Untyped pins make every honest upgrade look like an impersonation alarm (blocker B4), invalidation is lazy and fails open, "verified" carries no strength/version record so a v1 24-bit trust decision is honored as v2, and pinning gated on the optional SAS regresses continuity for the majority who skip it. Rebuild the pin store (typed, identity-keyed, transactional migration, pin decoupled from verify) and ship the SAS-grind fixes FIRST: migrating onto a grindable SAS is worse than the status quo.

## What holds up (keep it)
Commit-reveal is the right primitive (scope and ordering are the defects, not the mechanism). The commitment hash primitive is fine. Ed25519 PoP is the right addition to close the current no-proof-of-possession hole. Channel-binding the SAS and keys to one transcript is correct. Gating verified status and pinning on a confirmed SAS is the right trust model. The existing fail-closed primitives (HELLO-timeout, KEY_MISMATCH hard-abort, envelope-v1 enforcement) are sound to build on. Ed25519 is platform-feasible everywhere it is needed.

## External review: yes, before shipping
This is ZRTP/PGPfone-grade subtle core. Commitment scope, reveal ordering, the one-blind-guess reduction, the SIGMA-style signature, the secret-derived-vs-committed question, and the >=30-bit budget under an online-only threat all need a professional cryptographer. The commit + transcript + signed-message byte layout should get a formal (Tamarin or ProVerif) review before the wire format is frozen.

## Sequencing
Governance reconciliation first (the code says X25519, a prior decision rejected Ed25519), then design freeze with external review, then canonical encoding, signaling restructure, identity/signature layer, SAS and key schedule, pin store and migration, human ceremony and transfer gate, conformance CI, and a staged rollout last.