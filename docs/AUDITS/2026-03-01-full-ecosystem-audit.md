# Bolt Ecosystem — Full 5-Audit Synthesis Report

**Date:** 2026-03-01
**Audits Run:** 5 (all parallel, read-only)
**Scope:** All 9 repositories in the Bolt Ecosystem
**Baseline Tags:**
- bolt-core-sdk: `transport-web-v0.6.9-n8-caplen-1` (ded0a40)
- bolt-daemon: `daemon-v0.2.19-low-n8` (8683cbc)
- bolt-rendezvous: `rendezvous-v0.2.2-s0-canonical-lib-verified` (fd8d3df)
- localbolt: `localbolt-v1.0.17` (276047a)
- localbolt-app: `localbolt-app-v1.2.1` (2e8ef6a)
- localbolt-v3: `v3.0.63-s0-canonical-rendezvous` (2963539)
- bolt-protocol: `v0.1.3-spec` (6a6de3f)

---

## Audits Executed

| # | Audit | Tool Calls | Duration | Agent |
|---|-------|-----------|----------|-------|
| 1 | Spec-Implementation Conformance | 55 | 411s | Claude Opus |
| 2 | Dependency Graph & Trust Boundary | 99 | 420s | Claude Opus |
| 3 | Crypto & Security Primitive Review | 60 | 711s | Claude Opus |
| 4 | Test Coverage Gap Analysis | 96 | 358s | Claude Opus |
| 5 | Wire Format & Interop Readiness | 75 | 240s | Claude Opus |

---

## Executive Summary

All 5 audits completed successfully. The overall security posture is **strong** — all 10 claimed security properties hold, all 22 error codes are present in both TS and Rust, and web-to-web interop has **zero blockers**. The massive H1–H6, S0/S1, SA-series, and N-series work has paid off. What remains is CI/testing infrastructure gaps and minor architectural hygiene.

**Total findings: 25** — 2 Critical, 4 High, 3 Significant, 7 Medium, 6 Low, 3 Info

---

## CRITICAL (2) — CI/Testing Infrastructure

| ID | Source | Finding | Impact |
|----|--------|---------|--------|
| **C-1** | Audit 4 | **localbolt-app has ZERO web frontend tests and no CI test gate** | Bugs in the Tauri app's web layer (same codebase as localbolt) ship without any automated check. The `ci.yml` runs Rust fmt/clippy/test and TS build, but never `npm test`. |
| **C-2** | Audit 4 | **bolt-core-sdk CI (`ci.yml`) doesn't gate on Rust tests or transport-web tests** | The TS CI pipeline only runs bolt-core tests. The Rust CI (`ci-rust.yml`) exists separately but a PR could merge with Rust tests failing if only TS CI is required. Transport-web's 199 tests aren't gated either. |

**Recommended fix:** Both are CI configuration changes — no code modifications needed. Add `npm test` to localbolt-app CI; make Rust CI and transport-web tests required status checks in bolt-core-sdk.

---

## HIGH (4) — Testing & Architecture Gaps

| ID | Source | Finding | Impact |
|----|--------|---------|--------|
| **H-1** | Audit 2 | **Subtrees structurally diverged from canonical bolt-rendezvous** — localbolt/signal and localbolt-app/signal have `pub(crate)` vs `pub` visibility, inline types vs re-exports, and missing `protocol/` subcrate | Not currently causing wire-format issues (Audit 5 confirmed), but makes subtree refresh risky — a naive `git subtree pull` would conflict. |
| **H-2** | Audit 4 | **localbolt-v3 coverage thresholds defined but not enforced** — CI runs `npm test` without `--coverage` flag; thresholds (45/5/31/48) in vite.config are decorative | 10 of 13 source files have zero test coverage. Thresholds provide false confidence. |
| **H-3** | Audit 4 | **4 of 12 §15 Handshake Invariants have zero test coverage** — INV-09 (error-in-envelope), INV-10 (no-plaintext-protected), INV-11 (close-on-decrypt-fail), INV-12 (MAC-before-process) | All 12 are *implemented* in code (Audit 3 confirmed), but 4 have no automated regression test. A refactor could silently break them. |
| **H-4** | Audit 5 | **No cross-implementation interop test exists** — TS and Rust each have unit tests, golden vectors prove byte parity for crypto primitives, but no test actually connects a TS client to a Rust signal server | The S1 conformance harness tests Rust-internal invariants. The golden vectors test crypto parity. But the actual signaling wire format (JSON over WebSocket) has no cross-language test. |

---

## SIGNIFICANT (3) — Spec-Code Drift

| ID | Source | Finding | Impact |
|----|--------|---------|--------|
| **S-1** | Audit 1 | **verify-constants.sh CI guard is BROKEN** — reads from `lib.rs` but constants now live in `constants.rs` after refactoring | The CI check that prevents cross-language constant drift silently passes without checking anything. Constants are currently in sync (verified manually), but the guard is inert. |
| **S-2** | Audit 1 | **Rust bolt-core crate lacks a wire error code registry** — TS has all 22 §10 error codes in `errors.ts`, but Rust only has `BoltErrorCode` enum without the corresponding wire-format string codes | Daemon currently maps its own error strings. When daemon-web interop ships, error code mismatch is likely. |
| **S-3** | Audit 1 | **5 §14 constants missing from both TS and Rust SDKs** — `MAX_PEER_CODE_LENGTH(16)`, `MAX_CAPABILITIES(32)`, `MAX_CAPABILITY_LENGTH(64)`, `HELLO_TIMEOUT_MS(10000)`, `MAX_ERROR_MESSAGE_LENGTH(256)` | These are enforced in transport-web and bolt-rendezvous but aren't in the core SDK constants files. A new consumer would have to rediscover them. |

---

## MEDIUM (7) — Maintenance & Hygiene

| ID | Source | Finding | Impact |
|----|--------|---------|--------|
| **M-1** | Audit 1,4 | **6 stale TODO rows in CONFORMANCE.md** — PROTO-02/03/04/08, SEC-04/05 still show "TODO" but tests now exist | Undermines CONFORMANCE.md as a drift sentinel. Anyone reading it gets a falsely pessimistic picture. |
| **M-2** | Audit 2 | **Daemon pins bolt-rendezvous-protocol at stale v0.1.0** — canonical is v0.2.2 | No current bug (daemon has its own signaling schema), but when daemon-web interop ships, this stale pin will be the first friction point. |
| **M-3** | Audit 2 | **ARCHITECTURE.md doesn't document localbolt-v3's cargo git dependency on bolt-rendezvous** — S0 introduced this, but the bundling matrix still shows "Hosted endpoint only" | Documentation gap only — the actual dependency works correctly. |
| **M-4** | Audit 2 | **3 localbolt "shadow tests" confirmed** — `encryption.test.ts`, `store.test.ts`, `transfer-progress.test.ts` test reimplemented copies of functions, not actual app code | These inflate the 80% coverage threshold. They're not "fake" (they do run real assertions), but they test local copies rather than the imported SDK functions. |
| **M-5** | Audit 5 | **Subtree staleness** — localbolt/signal and localbolt-app/signal may be behind canonical bolt-rendezvous after S0 promoted pub APIs | No wire-format impact (Audit 5 verified), but the structural divergence (H-1) means refresh is non-trivial. |
| **M-6** | Audit 3 | **Cross-room signal relay via `find_peer`** — `server.rs` `find_peer()` searches ALL rooms, meaning a Signal message with a `to` field targeting a peer in a different room would be relayed | By design, rooms are IP-scoped groupings, and peers can only know peer codes of peers they've discovered. Low exploitability but violates least-privilege. |
| **M-7** | Audit 3 | **X-Forwarded-For trusted without restriction** — signal server reads `X-Forwarded-For` for room assignment with no allowlist | An attacker behind a non-Fly.io proxy could spoof their IP to join arbitrary rooms. Mitigated by the fact that room membership alone doesn't bypass encryption. |

---

## LOW (6)

| ID | Source | Finding |
|----|--------|---------|
| **L-1** | Audit 2 | 27 of 48 transport-web exports have zero consumers (56% dead API surface) |
| **L-2** | Audit 2 | `crypto-utils.ts` in localbolt is dead code (all functions now from SDK) |
| **L-3** | Audit 5 | TS `ServerMessage` union type missing `error` variant (parsed but not typed) |
| **L-4** | Audit 5 | No golden vectors for signaling messages (only crypto primitives covered) |
| **L-5** | Audit 1 | §10 references `bolt.envelope` but implementation uses `bolt.profile-envelope-v1` |
| **L-6** | Audit 3 | No concurrent WebSocket connection limit on signal server |

---

## INFO (3)

| ID | Source | Finding |
|----|--------|---------|
| **I-1** | Audit 5 | Peer code validation asymmetry (TS: 32-char alphabet, Rust: full alphanumeric) — intentional, TS is stricter |
| **I-2** | Audit 3 | SAS string logged to console during verification flow — acceptable for user-facing verification |
| **I-3** | Audit 3 | Identity secret key stored in cleartext IndexedDB — by design (browser has no secure enclave) |

---

## Resolved Since Last Audit

These were previously open and are now confirmed **CLOSED**:

- **R5** (uint8Equal non-constant-time): Compares public keys only, not secrets — INFO, not a vulnerability
- **R6** (Rust KeyPair Zeroize on Drop): Now uses `write_volatile` + `compiler_fence` + test — **RESOLVED**
- **SA1–SA19**: All 19 security audit findings — **ALL DONE-VERIFIED**
- **N1–N11**: All 11 audit delta findings — **ALL CLOSED**
- **10 of 19 previously-open architecture findings**: FIXED per Audit 2

---

## Security Verdict

| Claimed Property | Status |
|-----------------|--------|
| E2E encryption (rendezvous sees only ciphertext) | **HOLDS** |
| Forward secrecy (ephemeral keys per session) | **HOLDS** |
| TOFU identity pinning | **HOLDS** |
| SAS verification binds correct keys | **HOLDS** |
| Replay protection per (transfer_id, chunk_index) | **HOLDS** |
| File integrity via SHA-256 | **HOLDS** |
| Nonce freshness (CSPRNG per envelope) | **HOLDS** |
| MAC verified before plaintext processing | **HOLDS** |
| Rendezvous cannot observe file contents | **HOLDS** |
| No secret material persisted to disk | **HOLDS** (browser IndexedDB is accepted boundary) |

All 12 §15 Handshake Invariants are **implemented in code** (Audit 3 verified each one). 8/12 have test coverage; 4/12 need tests added (H-3).

---

## Web ↔ Web Interop Status

**Zero blockers.** All 3 web products (localbolt, localbolt-app, localbolt-v3) share bolt-transport-web and bolt-core via @the9ines packages. Production-verified between real machines. Signal wire format is compatible across all copies.

---

## Daemon ↔ Web Interop Roadmap (DEFERRED)

Not a release blocker. When this work begins, the following must be addressed:
- Daemon uses its own signaling schema (not bolt-rendezvous wire format)
- Daemon sends raw bytes on DataChannel (web expects JSON envelopes)
- Daemon does not use NaCl encryption
- Daemon pins bolt-rendezvous-protocol at stale v0.1.0

---

## Recommended Priority Order

| Priority | ID(s) | Action | Effort |
|----------|-------|--------|--------|
| 1 | C-1, C-2 | Fix CI gates (config-only, zero code risk, highest ROI) | ~1h |
| 2 | S-1 | Fix verify-constants.sh (one-line path change) | ~15m |
| 3 | M-1 | Update 6 CONFORMANCE.md TODO rows (doc-only) | ~30m |
| 4 | H-2 | Add `--coverage` to localbolt-v3 CI | ~15m |
| 5 | H-3 | Add tests for 4 untested §15 invariants | ~2h |
| 6 | S-3 | Add 5 missing constants to SDK | ~1h |
| 7 | S-2 | Add wire error code registry to Rust SDK | ~2h |
| 8 | H-1, M-5 | Plan subtree refresh (requires careful merge due to structural divergence) | ~4h |
| 9 | All others | Lower priority, tackle opportunistically | — |
