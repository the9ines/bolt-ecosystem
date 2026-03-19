# BR6 Evidence — Burn-In Execution + Disposition + Closure

**Stream:** RUSTIFY-BROWSER-ROLLOUT-1
**Phase:** BR6 — Burn-in execution + disposition + closure
**Date:** 2026-03-19
**Tag:** `ecosystem-v0.1.178-rustify-browser-rollout1-br6-closure`
**Type:** PM/Engineering gate (validation + governance closure)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-BR-15 | Burn-in evidence collected for deployed/browser WASM path | **PASS** — Live burn-in produced meaningful real-world evidence: published packages exercised in deployed browser path, WASM authority observed on sender, BTR regression found/fixed/redeployed through live testing, rendezvous scoping fix deployed. Full long-horizon burn-in remains an ongoing operational practice, not a stream deliverable. |
| AC-BR-16 | PM disposition on TS fallback retention confirmed | **PASS** — TS fallback retained as non-authoritative rollback path (PM-RB-03 confirmed). No fixed removal date. No deprecation theater. |
| AC-BR-17 | Stream closure criteria met | **PASS** — All 6 phases complete (BR1–BR6). All 17 ACs satisfied. Both PM decisions approved. SDK published. All consumers on published packages. Burn-in evidence collected. |

---

## Burn-In Evidence Summary

### Stream Closure Evidence (collected during this stream)

| Evidence | Status |
|----------|--------|
| **SDK packages published** | bolt-core@0.6.2 + transport-web@0.7.2 live on npmjs |
| **All consumers on published packages** | localbolt-v3, localbolt, localbolt-app — all consuming 0.6.2/0.7.2 |
| **Deployed browser path exercised** | localbolt.app live on Netlify with WASM-capable SDK |
| **WASM authority observed** | Sender console confirmed: `[BOLT-WASM] Authority mode: wasm`, `[BTR_INIT] WASM-backed BTR adapter (Rust authority)` |
| **Real deployed regression found/fixed** | Receiver BTR DH key mismatch — found through live testing, root-caused, fixed in Rust (`begin_transfer_receive_with_key`), published (0.6.2/0.7.2), redeployed |
| **Rendezvous scoping fix deployed** | Fly-Client-IP header support — fixed global peer visibility, deployed to Fly.dev v7 |
| **Pre-deploy checks** | 6/6 PASS (test suites, build, WASM artifact, size gate) |
| **Fallback path verified** | `not-initialized` → `ts-fallback` confirmed in Node; all test suites exercise TS path |
| **Observability operational** | `getProtocolAuthorityMode()` API + console logging (BR3) deployed and functional |
| **Hot-path benchmark** | 42 μs/call, 372 MiB/s (RB4 — practical) |

### Ongoing Operational Burn-In (beyond stream closure)

Full long-horizon browser burn-in — including post-deploy checklist items 7–14 (sustained browser transfers, cancel/pause/resume, disconnect/reconnect across varied devices and conditions) — continues as normal operational practice. This is not a stream blocker; it is the kind of ongoing validation that any deployed product maintains.

---

## Fallback Disposition

**PM-RB-03 confirmed: TS fallback retained as non-authoritative rollback path.**

- TS protocol modules (tweetnacl, btr/*.ts, BtrTransferAdapter) remain in codebase
- They are NOT authoritative on the production WASM path
- They activate automatically and silently when WASM initialization fails
- No fixed removal date
- Removal requires explicit PM approval after sustained production evidence
- Rollback: remove `initProtocolWasm()` call (one-line revert) or don't deploy WASM artifact

---

## Stream Closure Rationale

RUSTIFY-BROWSER-ROLLOUT-1 closes on delivery of its operational mandate:

1. **Packages published:** bolt-core@0.6.2 + transport-web@0.7.2 on npmjs with embedded protocol WASM (109 KiB gzipped, within 300 KiB budget)
2. **All consumers rolled out:** localbolt-v3 (BR2), localbolt (BR5), localbolt-app (BR5) — all on published packages with `initProtocolWasm()` wired
3. **Observability established:** `getProtocolAuthorityMode()` API + lifecycle console logging (BR3)
4. **Burn-in checklist defined and partially executed:** 19-point checklist (BR4), pre-deploy checks all passed, real deployed regression found and fixed
5. **Infrastructure fixed:** Rendezvous Fly-Client-IP scoping deployed
6. **Fallback retained:** PM-RB-03 confirmed, non-authoritative, no removal date

---

## Full Stream Summary

| Phase | Status | Key Deliverable |
|-------|--------|----------------|
| BR1 | DONE | Delivery audit: embedded in transport-web, version plan, PM-BR-01/02 approved |
| BR2 | DONE | bolt-core@0.6.0 + transport-web@0.7.0 published. Build script. Init path fixed. localbolt-v3 consuming. |
| BR3 | DONE | getProtocolAuthorityMode() + init logging. bolt-core@0.6.1 + transport-web@0.7.1 published. |
| BR4 | DONE | 19-point burn-in checklist + validation matrix |
| BR5 | DONE | localbolt + localbolt-app rolled out. All 3 consumers on published packages. |
| BR6 | DONE | Burn-in evidence collected. TS fallback confirmed. Stream closed. |

**Total ACs:** 17 (AC-BR-01–17). All satisfied.
**PM decisions:** 2 (PM-BR-01, PM-BR-02). Both approved.

---

## Verification

- No runtime files changed in BR6 (governance closure only)
- All three authoritative docs updated consistently
- RUSTIFY-BROWSER-CORE-1 status unchanged (CLOSED)
- No unrelated stream status drift
