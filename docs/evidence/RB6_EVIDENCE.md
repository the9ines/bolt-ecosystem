# RB6 Evidence — Rollout + Compatibility Gate + Closure

**Stream:** RUSTIFY-BROWSER-CORE-1
**Phase:** RB6 — Rollout + compatibility gate + TS deprecation + closure
**Date:** 2026-03-17
**Tag:** `ecosystem-v0.1.171-rustify-browser-core1-rb6-closure`
**Type:** Governance gate (docs/evidence only, no runtime changes)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-RB-21 | Per-consumer rollout completed per PM-RB-04 scope | **PASS** — Per-consumer rollout completed for the approved first-stage consumer (localbolt-v3). Remaining consumers (localbolt, localbolt-app) are explicitly deferred follow-on rollout under PM-RB-04 staged scope. |
| AC-RB-22 | TS protocol deprecation timeline confirmed (PM-RB-03 resolution) | **PASS** — TS fallback retained as non-authoritative condition-gated rollback path. No fixed removal date. Removal requires explicit PM approval after burn-in evidence. |
| AC-RB-23 | Stream closure criteria met | **PASS** — Stream closes on architectural delivery (browser-path Rust/WASM protocol authority proven and wired) and approved staged rollout completion. Operational follow-on (remaining consumers, npm publish, WASM artifact deployment) remains outside stream scope. |

---

## Rollout Status by Consumer

| Consumer | Status | Detail |
|----------|--------|--------|
| **localbolt-v3** | **COMPLETE** | `initWasmCrypto()` in main.ts. `createBtrAdapter()` factory in transport-web. Production WASM path active when artifact available. |
| **localbolt** | **DEFERRED** | Intentionally deferred under PM-RB-04 staged rollout. Uses published npm packages (0.5.1/0.6.7) without WASM adapter code. Requires npm publish cycle + main.ts wiring. |
| **localbolt-app** | **DEFERRED** | Intentionally deferred under PM-RB-04 staged rollout. Uses published npm packages (0.5.2/0.6.8) without WASM adapter code. Requires npm publish cycle + main.ts wiring. |

---

## Fallback / Deprecation Decision

**PM-RB-03 (condition-gated sunset) confirmed:**

- TS protocol fallback is **retained** as non-authoritative rollback path
- TS crypto modules (tweetnacl), BTR modules (btr/*.ts), and BtrTransferAdapter remain in codebase
- They are **not authoritative** on the production WASM path — only activated when WASM initialization fails
- **No fixed removal date** — removal requires explicit PM approval after:
  - Burn-in evidence from localbolt-v3 production deployment
  - WASM artifact deployment pipeline established
  - Remaining consumers wired and verified
- Rollback procedure: remove `initWasmCrypto()` call (one-line revert) or don't deploy WASM artifact (fallback auto-activates)

---

## Stream Closure Rationale

RUSTIFY-BROWSER-CORE-1 closes on architectural delivery and approved staged rollout completion:

1. **Architecture proven:** Browser-path Rust/WASM protocol authority is real, not theoretical.
   - bolt-protocol-wasm crate: 102 KiB gzipped (198 KiB headroom under 300 KiB budget)
   - Hot-path benchmark: 42 μs/call, 372 MiB/s (practical, 37× headroom)
   - 8 crypto/session exports (RB3) + BTR opaque handles + transfer SM (RB4)

2. **Production path wired:** localbolt-v3 calls `initWasmCrypto()` at startup. When WASM loads:
   - Crypto: Rust seal/open/SAS/identity (not tweetnacl)
   - BTR: Rust BtrEngine/BtrTransferContext (not TS btr/*.ts)
   - Transfer SM: Rust SendSession (not TS ad-hoc state)

3. **Staged rollout per PM-RB-04:** localbolt-v3 is complete. localbolt and localbolt-app are intentionally deferred follow-on consumers — their wiring is an operational task (npm publish + one-line main.ts change), not architectural work.

4. **Dual-path safety per PM-RB-03:** TS fallback is retained, non-authoritative, and auto-activates on WASM failure.

---

## Full Stream Summary

| Phase | Status | Key Deliverable |
|-------|--------|----------------|
| RB1 | DONE | Policy lock: ≤300 KiB budget, WebRTC retained, condition-gated sunset, staged rollout, ARCH-WASM1 superseded |
| RB2 | DONE | Authority boundary audit: 31+ TS modules inventoried. Protocol WASM measured at 67 KiB. |
| RB3 | DONE | Rust/WASM crypto+session: bolt-protocol-wasm crate (61 KiB). 8 exports. TS dual-path wired. |
| RB4 | DONE | BTR+transfer WASM: opaque handles (BtrEngine, BtrTransferCtx, SendSession). 102 KiB. 42 μs/chunk. |
| RB5 | DONE | Consumer wiring: localbolt-v3 production path + BTR factory in transport-web. |
| RB6 | DONE | Closure: staged rollout confirmed, TS fallback retained, stream closed. |

**Total ACs:** 23 (AC-RB-01–23). All PASS.
**PM decisions:** 5 (PM-RB-01–05). All APPROVED.

---

## Verification

- **No runtime files changed in RB6** — governance closure only
- **All three authoritative docs updated consistently**
- **RUSTIFY-CORE-1 status unchanged** (COMPLETE — not reframed)
- **No unrelated stream status drift**
