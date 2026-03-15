# BTR-SPEC-1 BS1 — Verification Evidence

Captured: 2026-03-14
Operator: oberfelder (local workstation)
Context: AC-BS-01..03 closure for BS1 DONE status.

---

## 1. AC Summary

| AC | Status | Key Evidence |
|----|--------|-------------|
| AC-BS-01 | PASS | 7-module taxonomy locked in GOVERNANCE_WORKSTREAMS.md § BS1. Maps to PROTOCOL.md §16 subsections. Matches P0 candidate list. |
| AC-BS-02 | PASS | 6-artifact checklist confirmed. Coverage matrix shows 5/7 modules complete; BTR-FC/BTR-RSM gaps are BS3 scope. |
| AC-BS-03 | PASS | Cross-reference audit: zero contradictions with SEC-BTR1 completion evidence (341 tests, 10 vectors, 11 invariants). |

---

## 2. Module Taxonomy (AC-BS-01)

| Module ID | Name | Spec Sections | Status |
|-----------|------|---------------|--------|
| BTR-HS | Handshake + Capability Negotiation | §4.2, §16.0 | Fully specified |
| BTR-KS | Key Schedule + Ratchet Lifecycle | §16.3, §16.5 | Fully specified |
| BTR-INT | Chunk Integrity + Replay/Ordering | §11, §16.6 | Fully specified |
| BTR-FC | Flow Control + Backpressure | NEW | Gap — BS3 scope |
| BTR-RSM | Resume/Recovery/Rollback | §16.7 | Partial — BS3 gap-fill |
| BTR-WIRE | Envelope Framing + Canonicalization | §16.2, §6.1 | Fully specified |
| BTR-CNF | Conformance + Vectors + Interop | Appendix C | Fully specified |

---

## 3. Per-Module Artifact Checklist (AC-BS-02)

6 artifacts per module: SM, INV, PSC, FAIL, SEC, VEC.

| Module | SM | INV | PSC | FAIL | SEC | VEC | Complete? |
|--------|:--:|:---:|:---:|:----:|:---:|:---:|:---------:|
| BTR-HS | Y | Y | Y | Y | Y | Y | YES |
| BTR-KS | Y | Y | Y | Y | Y | Y | YES |
| BTR-INT | — | Y | Y | Y | Y | Y | YES |
| BTR-FC | **GAP** | **GAP** | **GAP** | **GAP** | — | — | NO (BS3) |
| BTR-RSM | — | Y | **GAP** | partial | — | — | NO (BS3) |
| BTR-WIRE | Y | Y | Y | — | Y | Y | YES |
| BTR-CNF | — | — | Y | — | Y | Y | YES |

---

## 4. SEC-BTR1 Cross-Reference Audit (AC-BS-03)

| SEC-BTR1 Artifact | Modules Covered | Contradictions |
|-------------------|-----------------|----------------|
| BTR-0 spec lock (v0.1.6) | BTR-HS, BTR-WIRE | 0 |
| BTR-1 Rust reference (sdk-v0.5.36) | BTR-KS, BTR-INT | 0 |
| BTR-2 TS parity (sdk-v0.5.37) | BTR-KS, BTR-INT | 0 |
| BTR-3 conformance (sdk-v0.5.38) | BTR-CNF | 0 |
| BTR-4 wire integration (sdk-v0.5.39) | BTR-WIRE, BTR-HS | 0 |
| BTR-5 default-on (PM-BTR-08/09/11) | BTR-HS | 0 |
| 341 tests total | All 7 modules | 0 |
| 11 invariants (BTR-INV-01–11) | Mapped in checklist | 0 |
| **Total contradictions** | | **0** |

---

## 5. Guardrail Compliance

| Guardrail | Status |
|-----------|--------|
| BS-G1 (no runtime code) | PASS — docs/governance only |
| BS-G2 (no semantic rewrites) | PASS — taxonomy codifies existing behavior |
| BS-G3 (preserve SEC-BTR1 evidence) | PASS — AC-BS-03 audit confirms |
| BS-G4 (extend §16, not restructure) | PASS — module IDs map to existing subsections |
| BS-G5 (vectors remain Rust-authoritative) | PASS — BTR_VECTOR_POLICY.md preserved |
| BS-G6 (no new crypto primitives) | PASS — NaCl box + HKDF-SHA256 unchanged |

---

## 6. Files Changed

| File | Change |
|------|--------|
| `docs/GOVERNANCE_WORKSTREAMS.md` | BS1 phase status → DONE; BS2 → READY; AC-BS-01–03 status + full taxonomy/checklist/audit text |
| `docs/FORWARD_BACKLOG.md` | BTR-SPEC-1 status line + phase table + AC count updated |
| `docs/STATE.md` | Header + BTR-SPEC-1 row updated |
| `docs/CHANGELOG.md` | New BS1 DONE entry |
| `docs/evidence/BS1_EVIDENCE.md` | This evidence archive (new) |

---

## 7. BS2 Readiness

| Prerequisite | Status |
|-------------|--------|
| BS1 complete | YES |
| Module taxonomy locked | YES (7 modules) |
| Artifact checklist locked | YES (6 artifacts) |
| PM-BS-01 (crypto baseline) | PENDING — blocks AC-BS-07 |
| PM-BS-02 (rekey thresholds) | PENDING — blocks AC-BS-08 |

BS2 is READY for execution. PM-BS-01/02 decisions needed for AC-BS-07/08 but do not block BS2 start (can be resolved during BS2 execution).
