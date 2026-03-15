# RUSTIFY-CORE-1 RC5 — Verification Evidence

Captured: 2026-03-14
Operator: oberfelder (local workstation)
Context: AC-RC-21..24 closure verification for RC5 DONE status.

---

## 1. Remote Tag Confirmations

### bolt-daemon

```
$ git ls-remote --tags origin | grep rc5
58a0dd926e9ceefcba723871ae69107173039cd6  refs/tags/daemon-v0.2.41-rustify-core1-rc5-ws-endpoint
8eb9c3189403914a8336aa67c5152e080030569b  refs/tags/daemon-v0.2.42-rustify-core1-rc5-btr-ws
```

### bolt-core-sdk

```
$ git ls-remote --tags origin | grep rc5
1799e1bf1cc2fdfbfe46ceebd1e677d0789fbe14  refs/tags/sdk-v0.6.9-rustify-core1-rc5-ws-transport
```

### bolt-ecosystem

```
$ git ls-remote --tags origin | grep rc5
18d69b1a701951658a0f349e14528ba6a7069ceb  refs/tags/ecosystem-v0.1.132-rustify-core1-rc5-executed
3b96bb5e76ecdfff74da84e390c5d3be2bf3d201  refs/tags/ecosystem-v0.1.133-rustify-core1-rc5-done
```

---

## 2. Daemon Test Results — `cargo test --features transport-ws`

```
running 190 tests
test result: ok. 190 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.16s
running 128 tests
test result: ok. 128 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.11s
running 0 tests
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
running 15 tests
test result: ok. 15 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
running 0 tests (x4, d_e2e_bidirectional, d_e2e_web_to_daemon, h3_golden_vectors, h5_downgrade_validation)
running 13 tests
test result: ok. 13 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
running 11 tests
test result: ok. 11 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.48s
running 0 tests (x2, rc3_btr_over_quic, rc3_quic_e2e — gated behind transport-quic)
running 5 tests
test ac_rc_23_btr_sealed_chunk_over_ws ... ok
test ac_rc_23_btr_tampered_chunk_detected_over_ws ... ok
test ac_rc_23_btr_multi_chunk_transfer_over_ws ... ok
test ac_rc_23_ws_framing_preserves_sealed_bytes ... ok
test ac_rc_23_ws_hello_negotiates_btr_capability ... ok
test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.06s
running 0 tests (x2, sa1_identity_separation, sa1_identity_store)

TOTAL: 362 passed, 0 failed
```

### Breakdown

| Test binary | Tests | Status |
|-------------|-------|--------|
| lib (bolt_daemon) | 190 | PASS |
| main (bolt-daemon) | 128 | PASS |
| relay (bolt-relay) | 15 | PASS |
| n6b1_path_flags | 13 | PASS |
| n6b2_windows_pipe | 11 | PASS |
| rc5_btr_over_ws (AC-RC-23) | 5 | PASS |
| **Total** | **362** | **0 failed** |

---

## 3. Daemon Test Results — `cargo test` (without transport-ws)

```
test result: ok. 186 passed; 0 failed; (lib)
test result: ok. 128 passed; 0 failed; (main)
test result: ok. 15 passed; 0 failed; (relay)
test result: ok. 13 passed; 0 failed; (n6b1)
test result: ok. 11 passed; 0 failed; (n6b2)
test result: ok. 0 passed; (rc5_btr_over_ws — correctly gated out)

TOTAL: 353 passed, 0 failed
```

---

## 4. Browser Test Results — `npx vitest run`

```
Test Files  30 passed (30)
     Tests  364 passed (364)
```

---

## 5. AC-RC-23 Specific Tests (5 tests)

| Test Name | Result |
|-----------|--------|
| `ac_rc_23_ws_hello_negotiates_btr_capability` | PASS |
| `ac_rc_23_btr_sealed_chunk_over_ws` | PASS |
| `ac_rc_23_btr_multi_chunk_transfer_over_ws` | PASS |
| `ac_rc_23_btr_tampered_chunk_detected_over_ws` | PASS |
| `ac_rc_23_ws_framing_preserves_sealed_bytes` | PASS |

---

## 6. AC Summary

| AC | Status | Key Evidence |
|----|--------|-------------|
| AC-RC-21 | PASS | `ws_endpoint_starts_and_accepts_connection`, `ws_hello_handshake_succeeds` (daemon); WS connect tests (browser) |
| AC-RC-22 | PASS | `ws_envelope_roundtrip_over_ws` (daemon); `dcSendMessage` over DataTransport (browser) |
| AC-RC-23 | PASS | 5 dedicated BTR-over-WS tests; daemon `DAEMON_CAPABILITIES` includes `bolt.transfer-ratchet-v1` |
| AC-RC-24 | PASS | `BrowserAppTransport` fallback tests: WS refused/timeout -> WebRTC (browser) |

---

## 7. Commit History (RC5 scope)

### bolt-daemon

| SHA | Message |
|-----|---------|
| `58a0dd9` | feat(ws): add WebSocket endpoint for browser-app transport (AC-RC-21, AC-RC-22) |
| `8eb9c31` | feat(btr): advertise bolt.transfer-ratchet-v1 and add BTR-over-WS tests (AC-RC-23) |

### bolt-core-sdk

| SHA | Message |
|-----|---------|
| `1799e1b` | feat(transport-web): add WS primary transport + WebRTC fallback orchestrator (AC-RC-21..24) |

### bolt-ecosystem

| SHA | Message |
|-----|---------|
| `d38f25d` | docs(rustify-core1): record RC5 browser-app ws-primary integration results |
| `18d69b1` | docs(rustify-core1): correct RC5 tags, status, and AC-RC-23 evidence |
| `3b96bb5` | docs(rustify-core1): close AC-RC-23, mark RC5 DONE |

---

## 8. Governance Notes

- Tags `daemon-v0.2.39-rustify-core1-rc5-ws-endpoint` and `ecosystem-v0.1.131-rustify-core1-rc5-executed` were deleted from origin (immutable-tag policy violation). Documented in CHANGELOG.md.
- Commits `58a0dd9` (daemon), `1799e1b` (sdk), `d38f25d` (ecosystem) contain prohibited `Co-Authored-By` trailers. Left in place; no history rewrite performed.
- All subsequent commits (`8eb9c31`, `18d69b1`, `3b96bb5`) are fully policy-compliant.
- Forward-only corrective tags created: `v0.2.41` -> `v0.2.42`, `v0.1.132` -> `v0.1.133`.
