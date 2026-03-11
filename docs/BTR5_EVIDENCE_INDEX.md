# BTR-5 Evidence Index — AC-BTR-32 through AC-BTR-40

> **Phase:** BTR-5 (PM decision gate)
> **Date:** 2026-03-11
> **Prerequisite tag:** `sdk-v0.5.39-btr4-wire-integration` (`a7b3a7b`)

---

## AC Mapping: BTR-4 Acceptance Criteria (AC-BTR-32 through AC-BTR-39)

| AC ID | Criterion | Disposition | Evidence Location | Test Count |
|-------|-----------|-------------|-------------------|------------|
| AC-BTR-32 | Handshake integration: `bolt.transfer-ratchet-v1` negotiated in HELLO | **SATISFIED** | `ts/bolt-transport-web/src/__tests__/btr4-wire-integration.test.ts` — P1 negotiation tests | 5 negotiation + 3 kill switch = 8 |
| AC-BTR-33 | Envelope v2 with ratchet object sent/received when capability negotiated | **SATISFIED** | `ts/bolt-transport-web/src/__tests__/btr4-wire-integration.test.ts` — P2 envelope tests; `ts/bolt-transport-web/src/services/webrtc/EnvelopeCodec.ts` | 7 (encode + extract) |
| AC-BTR-34 | Downgrade to v1 envelope when capability not negotiated | **SATISFIED** | `ts/bolt-transport-web/src/__tests__/btr4-wire-integration.test.ts` — P4 backward compat tests | 4 |
| AC-BTR-35 | Warning surfaced to user on downgrade | **SATISFIED** | `onBtrDowngrade()` callback in `WebRTCServiceOptions`; `[BTR_DOWNGRADE]` log token; P5 log token tests | 4 |
| AC-BTR-36 | Daemon integration: `bolt-daemon` consumes `bolt-btr` crate | **DEFERRED** | See §AC-BTR-36 Disposition below | 0 (deferred) |
| AC-BTR-37 | Dark launch flag: BTR capability advertised but disabled by default | **SATISFIED** | `btrEnabled: false` default in `WebRTCServiceOptions`; P1 kill switch tests | 3 |
| AC-BTR-38 | Rollback path: disabling BTR returns to v1 behavior cleanly | **SATISFIED** | `ts/bolt-transport-web/src/__tests__/btr4-wire-integration.test.ts` — P6 reconnect/reset tests | 2 |
| AC-BTR-39 | All existing test suites pass across all repos (no regression) | **SATISFIED** | 338/338 transport-web, 232 bolt-core, 280 Rust workspace, BTR conformance 5/5 | 850+ total |

**Summary:** 7 of 8 BTR-4 ACs satisfied. 1 deferred (AC-BTR-36, daemon integration — non-blocking for default-on decision).

---

## AC-BTR-36 Disposition: Daemon Integration

**Status:** DOCUMENTED GAP — deferred to ByteBolt stream.

**Why non-blocking:**
1. All consumer file transfers use the TypeScript WebRTC path, not daemon.
2. ByteBolt (daemon consumer for BTR) is not yet in development.
3. `bolt-btr` Rust crate is fully tested and ready for daemon consumption.
4. BTR-4 wire integration validates the protocol at the transport-web layer, which is the active runtime path.

**Bounded follow-up:**
- **Stream:** ByteBolt development stream (new stream ID, outside BTR-STREAM-1)
- **Deliverable:** Daemon consumes `bolt-btr` crate via Cargo dependency
- **AC satisfaction:** Daemon tests pass with BTR-enabled sessions
- **Prerequisite:** BTR-5 approved (this gate) + ByteBolt stream kickoff

---

## PM-BTR-05 Reconciliation Note

**Decision:** PM-BTR-05 RESOLVED — capability-only gate (conditional fields per PROTOCOL.md §16.2, no envelope version bump needed).

**Impact on ACs:** AC-BTR-33 originally referenced "Envelope v2 with ratchet object." Per PM-BTR-05, the envelope `version` field remains `1`. The ratchet fields (`ratchet_public_key`, `ratchet_generation`, `chain_index`) are capability-gated additions to the existing ProfileEnvelopeV1 schema, not a version-2 envelope.

**AC wording clarification:** AC-BTR-33 should be read as "Envelope with ratchet fields sent/received when capability negotiated" — the "v2" reference is a convenience label for the field set, not a wire version bump. The implementation in `EnvelopeCodec.ts` correctly adds fields to `ProfileEnvelopeV1` rather than creating a new envelope version.

---

## AC-BTR-40 Definition

Now that BTR-4 is complete, AC-BTR-40 can be concretely defined:

| ID | Criterion | Evidence Required |
|----|-----------|------------------|
| AC-BTR-40 | PM approval of default-on decision with all three pending decisions resolved (PM-BTR-08, PM-BTR-09, PM-BTR-11) | Signed-off BTR5_DECISION_MEMO.md with GO decision recorded; PM-BTR-08/09/11 status changed to APPROVED in GOVERNANCE_WORKSTREAMS.md |

**Rationale:** BTR-5 is a PM decision gate, not an engineering gate. The acceptance criterion is the decision itself — approval of the rollout posture (which option from the decision memo) and resolution of the three pending PM decisions that govern rollout timing.

---

## Residual Risk and Blocked Evidence

### Open Risks

| ID | Risk | Severity | Blocking? | Mitigation Path |
|----|------|----------|-----------|-----------------|
| BTR-R7 | Novel protocol without external audit | HIGH | No (for default-on fail-open) | External audit before legacy deprecation (PM-BTR-11) |
| BTR-R8 | Daemon integration gap (AC-BTR-36) | MEDIUM | No (deferred to ByteBolt) | ByteBolt stream will satisfy |

### Blocked Evidence

| Item | Blocked By | Resolution Path |
|------|-----------|-----------------|
| Real-traffic BTR error rates | No BTR-enabled users yet | Dark-launch / opt-in phase (PM-BTR-08) |
| Adoption metrics for deprecation | No default-on yet | Default-on rollout + telemetry |
| External audit findings | No audit engaged | PM-BTR-11 decision + auditor engagement |
| Daemon BTR round-trip proof | No ByteBolt development | ByteBolt stream kickoff |

---

## Cross-Reference: Prior Phase Evidence

| Phase | Tag | Tests Added | Vector Categories |
|-------|-----|-------------|-------------------|
| BTR-1 | `sdk-v0.5.36-btr1-rust-reference` | 58 unit + 7 golden (superseded by BTR-3 golden expansion) | 6 initial |
| BTR-2 | `sdk-v0.5.37-btr2-ts-parity` | 78 TS BTR tests | 8 (consumed from Rust) |
| BTR-3 | `sdk-v0.5.38-btr3-conformance-gapfill` | 11 Rust golden (replaces BTR-1's 7; net: 58 unit + 11 golden = 69 Rust BTR total) | 10 total |
| BTR-4 | `sdk-v0.5.39-btr4-wire-integration` | 40 wire integration | N/A (integration-level) |

**Conformance scripts:**
- `scripts/btr-conformance.sh` — unified runner (5 checks)
- `scripts/verify-btr-constants.sh` — cross-language constant parity
- `docs/BTR_VECTOR_POLICY.md` — vector governance

---

*This index is an evidence companion to BTR5_DECISION_MEMO.md. Both documents are required for the PM decision gate.*
