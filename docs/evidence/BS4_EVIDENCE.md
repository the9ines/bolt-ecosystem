# BTR-SPEC-1 BS4 — Verification Evidence

Captured: 2026-03-14
Operator: oberfelder (local workstation)
Context: AC-BS-14..17 closure for BS4 DONE status.

---

## 1. AC Summary

| AC | Status | Key Evidence |
|----|--------|-------------|
| AC-BS-14 | PASS | 10 vector files mapped to spec sections, modules, invariants. 38 vectors + 1 lifecycle. |
| AC-BS-15 | PASS | 14 negative-test obligations across 5 modules. All map to §16.7 + BS2 SM. |
| AC-BS-16 | PASS | Rust authority / TS consumer. 6 requirements. 4 CI jobs. BTR_VECTOR_POLICY.md. |
| AC-BS-17 | PASS | 6/6 negotiation rows covered in btr-downgrade-negotiate.vectors.json. |

---

## 2. Vector-to-Spec Mapping (AC-BS-14)

| Vector File | Count | Module | Spec | Invariants |
|-------------|-------|--------|------|------------|
| btr-key-schedule | 3 | BTR-KS | §16.3 | INV-01 |
| btr-transfer-ratchet | 4 | BTR-KS | §16.3 | INV-02 |
| btr-chain-advance | 5 | BTR-KS/INT | §16.3 | INV-03, 04 |
| btr-dh-ratchet | 3 | BTR-KS | §16.3 | INV-05, 06 |
| btr-dh-sanity | 4 | BTR-KS | §3 | — |
| btr-encrypt-decrypt | 6 | BTR-INT | §16.4 | INV-11 |
| btr-replay-reject | 4 | BTR-INT | §16.6, §11 | INV-06, 07 |
| btr-downgrade-negotiate | 6 | BTR-HS | §4.2 | INV-10 |
| btr-lifecycle | 1 (multi) | BTR-KS/INT | §16.3/5 | INV-01–06, 08, 09 |
| btr-adversarial | 2 | BTR-INT | §16.7 | INV-04, 07 |
| **Total** | **38+1** | | | |

---

## 3. Negative-Test Matrix (AC-BS-15)

14 obligations across BTR-KS (4), BTR-INT (4), BTR-HS (3), BTR-WIRE (3).
All map to §16.7 error codes and BS2 SM transitions.
BTR-FC/BTR-RSM: no separate negative-test paths (failures map to existing codes).

---

## 4. Cross-Language Contract (AC-BS-16)

- Authority: Rust generates, TS consumes
- 6 conformance requirements: vector pass, interop, isolation, adversarial, downgrade, constants
- 4 CI jobs: Rust vectors, TS consumer, constants parity, unified runner
- Change policy: BTR_VECTOR_POLICY.md (human review required)

---

## 5. Downgrade Coverage (AC-BS-17)

6/6 rows: YES×YES, YES×NO, NO×YES, NO×NO, YES×MALFORMED, MALFORMED×YES.

---

## 6. Files Changed

| File | Change |
|------|--------|
| `docs/GOVERNANCE_WORKSTREAMS.md` | BS4 AC status + 4 subsections; BS5 → READY |
| `docs/FORWARD_BACKLOG.md` | Status + phase table + AC count |
| `docs/STATE.md` | Header + row |
| `docs/CHANGELOG.md` | New BS4 DONE entry |
| `docs/evidence/BS4_EVIDENCE.md` | This file (new) |
