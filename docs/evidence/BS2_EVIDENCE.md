# BTR-SPEC-1 BS2 — Verification Evidence

Captured: 2026-03-14
Operator: oberfelder (local workstation)
Context: AC-BS-04..08 closure for BS2 DONE status.

---

## 1. AC Summary

| AC | Status | Key Evidence |
|----|--------|-------------|
| AC-BS-04 | PASS | 5-state BTR-KS SM with 7 transitions + Tε. Error edges map to §16.7. |
| AC-BS-05 | PASS | 4-state BTR-HS SM with 6 transitions derived from §4.2 6-row matrix. |
| AC-BS-06 | PASS | 11/11 invariants mapped to SM states/transitions. Zero orphans. |
| AC-BS-07 | PASS | PM-BS-01 APPROVED. NaCl box + HKDF-SHA256 + X25519 ratified. |
| AC-BS-08 | PASS | PM-BS-02 APPROVED. Per-chunk chain + per-transfer DH + memory-only ratified. |

---

## 2. BTR-KS State Machine (AC-BS-04)

### States

| State | Description |
|-------|-------------|
| KS_UNINIT | No BTR session |
| KS_SESSION_ROOTED | Session root derived, ready for transfers |
| KS_TRANSFER_ACTIVE | Transfer root derived, chain advancing |
| KS_CHAIN_STEP | Transient: message key in use |
| KS_DH_RATCHET | Transient: inter-transfer DH step |

### Transitions

| # | From → To | Event | Error Edge |
|---|-----------|-------|------------|
| T1 | UNINIT → SESSION_ROOTED | BTR negotiated | — |
| T2 | SESSION_ROOTED → TRANSFER_ACTIVE | FILE_OFFER | RATCHET_STATE_ERROR |
| T3 | TRANSFER_ACTIVE → CHAIN_STEP | Chunk encrypt/decrypt | RATCHET_CHAIN_ERROR |
| T4 | CHAIN_STEP → TRANSFER_ACTIVE | Encrypt/decrypt done | RATCHET_DECRYPT_FAIL |
| T5 | TRANSFER_ACTIVE → SESSION_ROOTED | FILE_FINISH/CANCEL | — |
| T6 | SESSION_ROOTED → DH_RATCHET | Non-initial transfer boundary | RATCHET_STATE_ERROR |
| T7 | DH_RATCHET → SESSION_ROOTED | DH step complete | — |
| Tε | Any → UNINIT | Disconnect | — |

---

## 3. BTR-HS State Machine (AC-BS-05)

### States

| State | Description |
|-------|-------------|
| HS_PENDING | HELLO exchange in progress |
| HS_BTR_ACTIVE | Full BTR session (both YES) |
| HS_DOWNGRADED | One-sided, static ephemeral (warning logged) |
| HS_REJECTED | Malformed BTR metadata, disconnected |

### Transitions (from §4.2 6-row matrix)

| # | Condition (Local × Remote) | To | Error Edge |
|---|---------------------------|----|------------|
| H1 | YES × YES | BTR_ACTIVE | — |
| H2 | YES × NO | DOWNGRADED | — |
| H3 | NO × YES | DOWNGRADED | — |
| H4 | NO × NO | (no BTR) | — |
| H5 | YES × MALFORMED | REJECTED | RATCHET_DOWNGRADE_REJECTED |
| H6 | MALFORMED × YES | REJECTED | RATCHET_DOWNGRADE_REJECTED |

Matrix dimensions: 6 rows. 3 cells omitted (MALFORMED requires advertising capability).

---

## 4. Invariant-to-SM Mapping (AC-BS-06)

| Invariant | SM State/Transition |
|-----------|---------------------|
| BTR-INV-01 | KS T1 |
| BTR-INV-02 | KS T2 |
| BTR-INV-03 | KS T3 |
| BTR-INV-04 | KS T4 |
| BTR-INV-05 | KS T6 |
| BTR-INV-06 | KS T6 |
| BTR-INV-07 | KS T3 error edge |
| BTR-INV-08 | All KS states |
| BTR-INV-09 | KS Tε |
| BTR-INV-10 | HS H1 |
| BTR-INV-11 | KS T3/T4 |

Coverage: 11/11. Zero orphans.

---

## 5. PM Decisions (AC-BS-07, AC-BS-08)

### PM-BS-01 (Crypto Baseline) — APPROVED

| Primitive | Usage |
|-----------|-------|
| X25519 | Ephemeral DH + inter-transfer ratchet |
| HKDF-SHA256 | 4 key derivation steps (5 info strings) |
| NaCl secretbox | Chunk encryption with BTR message keys |
| NaCl box | HELLO envelope encryption (unchanged) |

Locked info strings: `bolt-btr-session-root-v1`, `bolt-btr-transfer-root-v1`, `bolt-btr-message-key-v1`, `bolt-btr-chain-advance-v1`, `bolt-btr-dh-ratchet-v1`.

### PM-BS-02 (Rekey/Lifecycle) — APPROVED

| Tier | Trigger | Mechanism |
|------|---------|-----------|
| Per-chunk | Every chunk | HKDF chain advance |
| Per-transfer | Every FILE_OFFER | Fresh X25519 DH |

No time/byte/count forced ratchet. Memory-only. No session resume in v1.

---

## 6. Guardrail Compliance

| Guardrail | Status |
|-----------|--------|
| BS-G1 (no runtime code) | PASS — docs/governance only |
| BS-G2 (no semantic rewrites) | PASS — SMs codify §16.3/16.5 existing behavior |
| BS-G3 (preserve SEC-BTR1 evidence) | PASS — no contradictions |
| BS-G6 (no new crypto primitives) | PASS — ratified existing stack only |

---

## 7. Cross-Doc Consistency

| Document | BS2 Status | AC-BS-04–08 | PM-BS-01/02 | BS3 |
|----------|-----------|-------------|-------------|-----|
| GOVERNANCE_WORKSTREAMS.md | DONE | All PASS | APPROVED | READY |
| FORWARD_BACKLOG.md | DONE in status | 8/22 delivered | APPROVED | READY |
| STATE.md | DONE in header + row | Referenced | Referenced | Referenced |
| CHANGELOG.md | DONE entry | All 5 detailed | APPROVED with details | READY noted |

---

## 8. Files Changed

| File | Change |
|------|--------|
| `docs/GOVERNANCE_WORKSTREAMS.md` | BS2 AC status + SM/INV/PM subsections; BS3 → READY; PM-BS-01/02 → APPROVED; "6-cell" → "6-row" |
| `docs/FORWARD_BACKLOG.md` | BTR-SPEC-1 status + phase table + AC count + PM table |
| `docs/STATE.md` | Header + BTR-SPEC-1 row |
| `docs/CHANGELOG.md` | New BS2 DONE entry |
| `docs/evidence/BS2_EVIDENCE.md` | This evidence archive (new) |

---

## 9. BS3 Readiness

| Prerequisite | Status |
|-------------|--------|
| BS2 complete | YES |
| State machines locked | YES (KS + HS) |
| Crypto baseline locked | YES (PM-BS-01) |
| Lifecycle policy locked | YES (PM-BS-02) |
| PM-BS-03 (wire format versioning) | PENDING — blocks AC-BS-11 |
| PM-BS-04 (compatibility contract) | PENDING — blocks AC-BS-12 |

BS3 is READY. PM-BS-03/04 needed for AC-BS-11/12.
