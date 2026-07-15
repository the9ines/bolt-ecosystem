# LocalBolt PAKE Adoption, Phase 1 GO/NO-GO

**Verdict: CONDITIONAL GO.** Adopt RustCrypto `spake2` (stable **0.4.0**), balanced `start_symmetric()`, implemented once in bolt-core-sdk and compiled to WASM through the existing `bolt-protocol-wasm` surface. This clears the PM's hard gate: one maintained library covers both Rust and browser/WASM. It is not a clean GO because the crate is unaudited and not constant-time, ships no key confirmation, and is not RFC 9382 on the wire. Those are acceptable for LocalBolt only with explicit risk sign-off and defined Phase-2 build work.

## Recommendation

- **Library:** `spake2` (RustCrypto/PAKEs), balanced `start_symmetric()`.
- **Version:** pin **stable 0.4.0**. Do not use 0.5.0-pre.0.
- **Lockfile:** pin `curve25519-dalek >= 4.1.3` (RUSTSEC-2024-0344 fixed there).
- **Placement:** one implementation in bolt-core-sdk, exported through `bolt-protocol-wasm`. Native daemon and browser run the identical construction, so parity holds by construction and no second implementation is maintained.
- **Do not vendor** magic-wormhole.rs itself (EUPL-1.2 copyleft, clashes with MIT). Take the `spake2` crate directly.

## Why this clears the gate, verified against the repo

Both ecosystems are genuinely covered by ONE implementation, and the integration cost is low because bolt-core-sdk already carries the pieces:

| Requirement | Status in bolt-ecosystem (verified 2026-07-14) |
|---|---|
| curve25519-dalek | Already present via `bolt-btr` `x25519-dalek = "2"` (pulls dalek ^4) |
| sha2 / hkdf | Already present (`sha2 0.10`, `hkdf 0.12`) |
| rand_core | `bolt-core` on `rand_core 0.6` + getrandom, exactly what 0.4.0 wants |
| Browser CSPRNG | `bolt-protocol-wasm` already wires `getrandom 0.2` (`js` feature) |
| Edition/MSRV | Workspace is edition 2021; 0.4.0 fits, 0.5.0-pre.0 would force edition 2024 / MSRV 1.85 |
| License | `bolt-core` is MIT; spake2 is MIT OR Apache-2.0, clean |

Consequence: adding `spake2 0.4.0` is a thin protocol layer over deps already in the tree, so the marginal WASM bundle cost is small and the browser entropy path is already solved. Pinning **0.4.0** is correct for this workspace on integration grounds (rand_core 0.6, edition 2021), independent of the general avoid-pre-release-crypto argument.

## Honest scorecard

| Axis | Reading |
|---|---|
| Maintenance | SLOW but org-backed (RustCrypto), not abandoned. Stable 0.4.0 is ~3 yrs old; 0.5 line stuck in pre-release. Fine for a frozen-wire primitive. |
| Audit | NONE. Docs: never audited, probably not constant-time, no secret zeroization. Biggest risk vs a vetted bar. Needs explicit sign-off. |
| RFC 9382 | NO. Warner/python-spake2 Ed25519 variant; transcript deviates (open issue #186). Harmless for a closed 2-endpoint system; cannot claim RFC compliance or use RFC KATs. |
| License | CLEAN (MIT OR Apache-2.0). Landmine is only the wormhole crate (EUPL-1.2), not spake2. |
| Dependency risk | LOW. Tiny tree, all already in bolt-core-sdk. One chore: lock curve25519-dalek >= 4.1.3. |
| WASM viability | HIGH confidence, unproven in bolt's exact toolchain. Heavy deps already build to wasm32 today; spake2 itself needs a spike. |

## What LocalBolt must build (not in the crate)

1. **Key confirmation.** The crate returns the raw shared key only. Add a Wormhole-style encrypted version message using the already-present `crypto_secretbox 0.1` keyed by an `hkdf 0.12` subkey of the SPAKE2 output. Both sides must verify before the session leaves `unverified`. This MAC check is the concrete replacement for the manual Mark Verified click.
2. **Symmetric-mode hardening.** Use `start_symmetric()` (M=N) or deterministic roles, bind identities + both messages in the transcript, so reflection and unknown-key-share attacks fail.
3. **One-time-code enforcement.** Consume the peer code and rendezvous room on first use, with retry/lockout, so an attacker cannot farm guesses.

## What SPAKE2 replaces (migration is not greenfield)

The current flow (verified in code) is an unauthenticated X25519 ephemeral exchange, then `bolt_core::sas::compute_sas` (SHA-256 over sorted identity+ephemeral keys, first 6 hex = 24-bit compare-SAS), displayed for a manual **Mark Verified** click, gating a `session_contract` state machine (`unverified` / `verified` / `legacy`). SPAKE2 folds the peer code INTO the key agreement, so the manual compare-SAS is replaced by automatic key-confirmation. Recommended migration: re-source the display SAS from the SPAKE2 transcript key (Wormhole verifier style) to keep the UI while making it cryptographically bound, re-map `unverified -> verified` to key-confirmation, and keep a `legacy` path for peers without SPAKE2. The one-time code is the existing peer code (31-char unambiguous alphabet, ~29.7 bits at 6 chars or ~39.6 bits at 8 chars, CSPRNG, rejection-sampled); use the 8-char ~40-bit long code as the SPAKE2 password, MHF=none is defensible at that entropy.

## Conditions for GO (must clear before commit)

1. **Risk sign-off** that an unaudited, not-constant-time, non-RFC-9382 crate meets the bar, filed as an AUDIT_TRACKER finding (HIGH severity implies INTEROP + at least one ADVERSARIAL test).
2. **Requirement clarification:** confirm bolt-protocol wants a vetted wormhole-style SPAKE2, not literal RFC 9382 wire interop. If the latter is hard-required, that sub-path is STOP (no maintained Rust+WASM crate implements it).
3. **WASM spike:** compile spake2 0.4.0 to wasm32 in bolt's toolchain and run a native<->browser round-trip with regression vectors generated from the crate.
4. **Protocol governance:** schedule as a bolt-protocol spec revision + major SDK version bump, routed through the no-new-dependency-without-approval gate.

## Bottom line

There is a suitable, maintained, single Rust crate that serves both the daemon and the browser, and this repo already carries its dependency tree, so the architecture-fit test passes and the correct output is not STOP. It is CONDITIONAL rather than a clean GO because the crate is unaudited, ships no key confirmation, and is not RFC 9382, and because adopting it is a governed, breaking protocol change, not a drop-in. Pin `spake2 = 0.4.0`, lock `curve25519-dalek >= 4.1.3`, build key confirmation, and get the audit-risk sign-off.