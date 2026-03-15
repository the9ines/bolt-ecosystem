# BTR-SPEC-1 BS3 — Verification Evidence

Captured: 2026-03-14
Operator: oberfelder (local workstation)
Context: AC-BS-09..13 closure for BS3 DONE status.

---

## 1. AC Summary

| AC | Status | Key Evidence |
|----|--------|-------------|
| AC-BS-09 | PASS | BTR-FC normative text: 5 rules (FC-01–05). No BTR-specific flow control; inherits transport §8. |
| AC-BS-10 | PASS | BTR-RSM normative text: 5 rules (RSM-01–05). No v1 resume. Zeroize + fresh handshake. 7 recovery paths. |
| AC-BS-11 | PASS | PM-BS-03 APPROVED. Additive = backward-compatible. Breaking = new capability string + PM decision. |
| AC-BS-12 | PASS | PM-BS-04 APPROVED. Strict on security-critical. Tolerant on optional only. Deterministic failures. |
| AC-BS-13 | PASS | 4-error failure matrix. All codes → SM transitions → actions → recovery paths → invariants. |

---

## 2. BTR-FC Summary (AC-BS-09)

**Core principle:** BTR introduces no v1 flow-control algorithm. Transport backpressure (§8) is inherited.

| Rule | Statement |
|------|-----------|
| FC-01 | No BTR flow-control primitives in v1 |
| FC-02 | Chain advance synchronous with chunk send/receive |
| FC-03 | Backpressure applied before BTR encrypt (send) / after BTR decrypt (receive) |
| FC-04 | No speculative chain advance |
| FC-05 | Pause/resume does not affect BTR key state |

Implementation alignment: Rust `BackpressureController` + TS `awaitBackpressureDrain()` operate at transport layer. BTR is transparent.

---

## 3. BTR-RSM Summary (AC-BS-10)

**Core principle:** No v1 resume. Disconnect → zeroize → fresh handshake.

| Rule | Statement |
|------|-----------|
| RSM-01 | No session resume in v1 |
| RSM-02 | No transfer resume in v1 |
| RSM-03 | All BTR state zeroized immediately on disconnect |
| RSM-04 | Reconnect starts from KS_UNINIT → KS_SESSION_ROOTED (fresh) |
| RSM-05 | Error recovery follows AC-BS-13 failure matrix |

Recovery paths: 7 scenarios mapped to SM transitions and §16.7 actions.

---

## 4. Failure-to-Action Matrix (AC-BS-13)

| Error Code | Action | Recovery |
|------------|--------|----------|
| RATCHET_STATE_ERROR | Disconnect immediately | Fresh handshake → new session |
| RATCHET_CHAIN_ERROR | Cancel transfer | New transfer in same session |
| RATCHET_DECRYPT_FAIL | Cancel transfer | New transfer in same session |
| RATCHET_DOWNGRADE_REJECTED | Disconnect immediately | Fresh handshake → new session |

Properties: complete (4/4), deterministic, SM-linked, invariant-backed.

---

## 5. PM Decisions

### PM-BS-03 — Wire Versioning (APPROVED)

- Additive fields: backward-compatible, no version bump
- Breaking changes: new capability string + PM decision + updated vectors
- `bolt.transfer-ratchet-v1` locked

### PM-BS-04 — Parsing Contract (APPROVED)

- Strict: security-critical required fields/values
- Tolerant: explicitly optional/unknown fields only
- Downgrade detection: strict
- All failures: §16.7 error codes, deterministic

---

## 6. Guardrail Compliance

| Guardrail | Status |
|-----------|--------|
| BS-G1 (no runtime code) | PASS |
| BS-G2 (no semantic rewrites) | PASS — codifies existing behavior |
| BS-G3 (preserve SEC-BTR1 evidence) | PASS |
| BS-G4 (extend §16, not restructure) | PASS |

---

## 7. Cross-Doc Consistency

| Document | BS3 Status | AC-BS-09–13 | PM-BS-03/04 | BS4 |
|----------|-----------|-------------|-------------|-----|
| GOVERNANCE_WORKSTREAMS.md | DONE | All PASS | APPROVED | READY |
| FORWARD_BACKLOG.md | DONE | 13/22 delivered | APPROVED | READY |
| STATE.md | DONE | Referenced | Referenced | Referenced |
| CHANGELOG.md | DONE entry | All 5 detailed | APPROVED | READY |

---

## 8. Files Changed

| File | Change |
|------|--------|
| `docs/GOVERNANCE_WORKSTREAMS.md` | BS3 AC status + BTR-FC/BTR-RSM/versioning/parsing/failure subsections; BS4 → READY; PM-BS-03/04 → APPROVED |
| `docs/FORWARD_BACKLOG.md` | BTR-SPEC-1 status + phase table + AC count |
| `docs/STATE.md` | Header + BTR-SPEC-1 row |
| `docs/CHANGELOG.md` | New BS3 DONE entry |
| `docs/evidence/BS3_EVIDENCE.md` | This evidence archive (new) |

---

## 9. BS4 Readiness

| Prerequisite | Status |
|-------------|--------|
| BS3 complete | YES |
| BTR-FC normative text | YES |
| BTR-RSM normative text | YES |
| Wire versioning policy | YES (PM-BS-03) |
| Parsing contract | YES (PM-BS-04) |
| Failure matrix | YES (AC-BS-13) |

BS4 is READY. No PM decisions required for BS4.
