# Bolt Ecosystem — State

> **Last Updated:** 2026-02-26 (S2 policy core in progress)
> **Authority:** Informational. Updated after each tagged release or H-phase completion.

---

## H-Phase Truthful Ledger

Status labels: **DONE-MERGED** | **DONE-NOT-MERGED** | **IN-PROGRESS** | **NOT-STARTED**

| Phase | Description | Status | Repo(s) | Tag(s) | Commit(s) |
|-------|-------------|--------|---------|--------|-----------|
| H0 | Protocol enforcement posture | DONE-MERGED | bolt-ecosystem/docs/ | N/A | N/A |
| H1 | Signal server trust-boundary hardening | DONE-MERGED | localbolt-v3 | `v3.0.59-signal-hardening`, `v3.0.62-h1-mainline-merge` | `ac5110c`, `7571d35` (merge) |
| H2 | WebRTC enforcement compliance | DONE-MERGED | bolt-core-sdk | `sdk-v0.5.0-h2-webrtc-enforcement`, `sdk-v0.5.3-h2-h3-mainline` | `b4ce544`, `3f66da9` (mainline tag) |
| H3 | Cross-implementation golden vectors (SDK) | DONE-MERGED | bolt-core-sdk | `sdk-v0.5.1`, `sdk-v0.5.3-h2-h3-mainline` | `9d8617d`, `3f66da9` (mainline tag) |
| H3 | Cross-implementation golden vectors (daemon) | DONE-MERGED | bolt-daemon | `daemon-v0.2.5-h3-golden-vectors`, `daemon-v0.2.10-h3-h6-mainline` | `3751118`, `0b16392` (merge) |
| H3.1 | Hermetic vectors (daemon) | DONE-MERGED | bolt-daemon | `daemon-v0.2.8-h3.1-vectors-hermetic`, `daemon-v0.2.10-h3-h6-mainline` | `e6c8851`, `0b16392` (merge) |
| H4 | Daemon panic surface elimination | DONE-MERGED | bolt-daemon | `daemon-v0.2.6-h4-panic-elimination`, `daemon-v0.2.10-h3-h6-mainline` | `678c808`, `0b16392` (merge) |
| H5 | Daemon downgrade resistance + enforcement validation | DONE-MERGED | bolt-daemon | `daemon-v0.2.7-h5-downgrade-validation`, `daemon-v0.2.10-h3-h6-mainline` | `257c4a4`, `0b16392` (merge) |
| H5-v3 | localbolt-v3 TOFU/SAS identity + pinning wiring | DONE-MERGED | localbolt-v3 | `v3.0.61-h5v3-tofu-sas-pinning` | `532d391` |
| H6 | CI enforcement across repos | DONE-MERGED | bolt-core-sdk, bolt-daemon, bolt-rendezvous, localbolt-v3 | See below | See below |

### Ledger Notes

- **H0** is filesystem-only (bolt-ecosystem root is not a versioned git repo). Status DONE-MERGED by convention.
- **H1** merged into localbolt-v3 main via `--no-ff` at merge train STOP 1. Forward tag `v3.0.62-h1-mainline-merge` on main.
- **H2 + H3 (SDK)** merged into bolt-core-sdk main via `--no-ff` at merge train STOP 2. Forward tag `sdk-v0.5.3-h2-h3-mainline` on main. H3 test files received `cargo fmt` fixup (pre-H6 formatting).
- **H3/H3.1/H4/H5 (daemon)** merged into bolt-daemon main via `--no-ff` at merge train STOP 3. Forward tag `daemon-v0.2.10-h3-h6-mainline` on main.
- **H5-v3** was already on localbolt-v3 main (commits `532d391` and `1e659c3`) before the merge train.
- **H6** was already on main for SDK, rendezvous, and localbolt-v3. Daemon H6 (`398a63d`) was on `feature/h5-downgrade-validation` and merged via STOP 3.
- All feature branches preserved (not deleted).

---

## Merge Train Status

**Status: COMPLETE** (2026-02-25)

| Step | Action | Repo | Result |
|:---:|--------|------|--------|
| 0 | Preflight — sync all repos, push tags to origin | All | PASS |
| 1 | Merge `feature/h1-signal-hardening` → main | localbolt-v3 | PASS — `v3.0.62-h1-mainline-merge` (`7571d35`) |
| 2 | Merge `feature/h2-webrtc-enforcement` + `feature/h3-golden-vectors` → main | bolt-core-sdk | PASS — `sdk-v0.5.3-h2-h3-mainline` (`3f66da9`) |
| 3 | Merge `feature/h5-downgrade-validation` → main | bolt-daemon | PASS — `daemon-v0.2.10-h3-h6-mainline` (`0b16392`) |
| 4 | Verify H6 tag on main | bolt-rendezvous | PASS — `rendezvous-v0.2.1-h6-ci-enforcement` points at HEAD |
| 5 | Governance ledger updates | bolt-ecosystem/docs/ | PASS — this update |

---

## Audit Finding Details (Resolved)

### H5-v3 — TOFU/SAS Wiring + Identity/Pin Store (Security + Correctness)

**Repo:** localbolt-v3
**Status:** DONE-MERGED (tag: `v3.0.61-h5v3-tofu-sas-pinning`, commit: `532d391`)

TOFU identity pinning and SAS verification wired into localbolt-v3 product UI with IndexedDB persistence, verification state bus, and transfer gating. 22 tests.

### H6 — CI Enforcement Across Repos (Operational)

**Repos:** bolt-core-sdk, bolt-daemon, bolt-rendezvous, localbolt-v3
**Status:** DONE-MERGED

| Repo | Tag | Commit | On Main |
|------|-----|--------|:---:|
| bolt-core-sdk | `sdk-v0.5.2-h6-ci-enforcement` | `476881a` | Yes |
| bolt-daemon | `daemon-v0.2.9-h6-ci-enforcement` | `398a63d` | Yes (via merge) |
| bolt-rendezvous | `rendezvous-v0.2.1-h6-ci-enforcement` | `6f48ba7` | Yes |
| localbolt-v3 | `v3.0.60-h6-ci-enforcement` | `3b12f73` | Yes |

---

## S-Phase Ledger

| Phase | Description | Status | Repo(s) | Tag(s) | Commit(s) |
|-------|-------------|--------|---------|--------|-----------|
| S0 | Canonical hardened rendezvous | DONE-MERGED | bolt-rendezvous, localbolt-v3 | `rendezvous-v0.2.2-s0-canonical-lib-verified`, `v3.0.63-s0-canonical-rendezvous` | `fd8d3df`, `2963539` |
| S1 | Core protocol conformance harness (Rust SDK) | DONE-MERGED | bolt-core-sdk | `sdk-v0.5.4-s1-conformance-harness` | `cced058` |
| S2 | Transfer performance program | IN-PROGRESS | bolt-core-sdk | `sdk-v0.5.5-s2-policy-skeleton`, `sdk-v0.5.6-s2-policy-contract-tests`, `transport-web-v0.6.1-s2b-instrumentation` | `31bdc0b`, `39ed6dc`, `02e36b1` |

## Governance Phases

| Phase | Description | Status | Repo(s) | Commit(s) |
|-------|-------------|--------|---------|-----------|
| CONFORMANCE-1R | Spec conformance matrix + PR review gate | DONE | bolt-protocol, bolt-ecosystem | bolt-protocol: `69a0907`, bolt-ecosystem: see below |
| CONFORMANCE-2R | Enforceable conformance matrix with minimum coverage | DONE | bolt-protocol, bolt-ecosystem | bolt-protocol: `81171c5` (`v0.1.1-spec`), bolt-ecosystem: `0b68fe2` (`ecosystem-v0.1.1-conformance-2r`) |
| PROTO-HARDEN-1 | Handshake invariants codified in spec (§15, 12 invariants) | DONE | bolt-protocol, bolt-ecosystem | bolt-protocol: `ee024d7` (`v0.1.2-spec`) |
| PROTO-HARDEN-1R1 | Canonical error registry unification in §10 (22 codes) | DONE | bolt-protocol, bolt-ecosystem | bolt-protocol: `6a6de3f` (`v0.1.3-spec`) |

## P-Phase Ledger (Post-H Hardening)

| Phase | Description | Status | Repo(s) | Tag(s) | Commit(s) |
|-------|-------------|--------|---------|--------|-----------|
| P1 | Inbound error validation hardening | DONE | bolt-daemon | `daemon-v0.2.12-p1-inbound-error-validation` | `8c45819` |

### S1 Completion Notes

- **bolt-core-sdk** (`cced058`): Deterministic Rust conformance harness under `rust/bolt-core/tests/conformance/`. 27 tests (16 envelope + 5 SAS + 6 error mapping, with 11 error_code_mapping tests running under default `cargo test`). Enforces MUST-level invariants: envelope roundtrip determinism (PROTO-01, PROTO-07), MAC verification (SEC-06), nonce freshness/uniqueness (SEC-01, SEC-02), SAS determinism (PROTO-06), and error code mapping stability (Appendix A, Rust surface). No protocol behavior, wire format, or crypto logic changed.
- **TS-owned invariants (not tested in S1):** Handshake gating (WebRTCService state machine), downgrade resistance (capability negotiation), HELLO exactly-once enforcement (WebRTCService), and 11 of 14 Appendix A error frame codes (transport-level, not core SDK types).
- **Test delta:** Default 55→66 (+11), vectors 69→96 (+27). No regressions.

### S2 Progress Notes

- **S2A scope (this sub-phase):** Policy core types + deterministic stub + contract tests. Greenfield Rust module `transfer_policy` in bolt-core-sdk. No behavior change; no callers wired.
- **S2B (instrumentation):** DONE — `transport-web-v0.6.1-s2b-instrumentation` (`02e36b1`). Passive observability for TS transfer path: RingBuffer, TransferMetricsCollector, summarizeTransfer. Stall detection (retroactive, no timers). Feature-gated via `ENABLE_TRANSFER_METRICS` (default false). 24 new tests. Zero overhead when disabled. No behavior change.
- **S2B (remaining):** WASM build/plumbing, TS runtime opt-in integration, rollback proof (flag OFF). NOT-STARTED.
- **Architecture:** Policy core is greenfield; transfer runtime remains TS; WASM consumption planned but no WASM infrastructure exists yet.
- **bolt-core-sdk** (`31bdc0b`): Policy skeleton — `transfer_policy/` module with types (ChunkId, LinkStats, DeviceClass, TransferConstraints, FairnessMode, PolicyInput, Backpressure, ScheduleDecision, MAX_PACING_DELAY_MS) and deterministic `decide()` stub. 4 inline unit tests.
- **bolt-core-sdk** (`39ed6dc`): 15 integration contract tests in `tests/s2_policy_contracts.rs`. Validates determinism, bounds, backpressure, and sanity contracts. Any future real policy must pass these contracts.
- **Test delta:** Default 66→85 (+19), vectors 96→115 (+19). No regressions.

### S0 Completion Notes

- **bolt-rendezvous** (`fd8d3df`): Promoted trust-boundary API (5 constants, 4 validation functions, RateLimit struct + methods) from `pub(crate)` to `pub`. Added `Default` impl for clippy compliance. These pub items exist solely so the wrapper/tests reuse identical validation/rate-limit logic without reimplementation — internal server policy exposure, not a public SDK-like API. 49 tests pass.
- **localbolt-v3** (`2963539`): Replaced `packages/localbolt-signal` local implementation (protocol.rs, server.rs, room.rs) with canonical bolt-rendezvous wrapper via cargo git dependency pinned to `rendezvous-v0.2.2-s0-canonical-lib-verified`. 36 tests (up from 32). Wire-format parity verified. LAN-only compatibility preserved.
- **Wire-format parity evidence:** 8 fixture-based tests in `localbolt-signal/src/lib.rs::tests` (`wire_deserialize_register`, `wire_deserialize_signal`, `wire_deserialize_ping`, `wire_serialize_peers`, `wire_serialize_peer_joined`, `wire_serialize_peer_left`, `wire_serialize_signal_relay`, `wire_serialize_error`). These exercise canonical `bolt-rendezvous-protocol` types through the wrapper using the same JSON shapes as the upstream golden snapshots (`protocol/src/lib.rs::tests::wire_*`). Since localbolt-signal imports canonical types directly (no local reimplementation), parity is structural — drift eliminated by construction.
- **Git dependency resolution:** Tag confirmed on origin. `Cargo.lock` pins both `bolt-rendezvous` and `bolt-rendezvous-protocol` to exact commit `fd8d3df7196b25bfeb25d99868c0525c4a75f917`. Fly builds resolve deterministically.
- **Dockerfile:** git installed in builder stage. Dev-dep stripping via awk documented inline (sibling-path dev-deps unavailable in Docker build context).
- **Smoke test:** Peer discovery, peer_joined, signal relay verified. LAN test: bound `0.0.0.0`, connected via LAN IP `192.168.4.210`.

---

## Interop Path Status

| Milestone | Daemon Tag | Commit | Status |
|-----------|-----------|--------|--------|
| INTEROP-1 — Web signaling payloads | `daemon-v0.2.1-interop-1-web-signal-payload` | `14c7448` | Merged to main |
| INTEROP-2 — Web HELLO handshake | `daemon-v0.2.2-interop-2-web-hello` | `dd82669` | Merged to main |
| INTEROP-3 — Session context + Profile Envelope v1 | `daemon-v0.2.3-interop-3-session-envelope` | `a39fefc` | Merged to main |
| INTEROP-4 — Minimal post-HELLO message set | `daemon-v0.2.4-interop-4-min-msgset` | `d7a79c4` | Merged to main |
| H3 — Golden vector integration tests | `daemon-v0.2.5-h3-golden-vectors` | `3751118` | Merged to main |

---

## Current Enforcement Posture

| Invariant | TS Implementation | Rust Implementation | Test Evidence | On Main? |
|-----------|-------------------|---------------------|---------------|----------|
| Exactly-once HELLO | `WebRTCService` (H2) | `web_hello.rs` HelloState | SDK: 21 H2 tests, daemon: 20 tests | Yes |
| Envelope-required binary enforcement | `WebRTCService` envelope mode (H2) | `envelope.rs` (INTEROP-3) | SDK: H2 rejection tests, daemon: 12 tests | Yes |
| Fail-closed semantics | All protocol errors → disconnect (H2) | Error framing + disconnect | SDK: per-error-code tests, daemon: EnvelopeError | Yes |
| Error code registry (14 codes) | Appendix A codes emitted | DcErrorMessage framing | H2: emission tests per code | Yes |
| Downgrade resistance | No runtime flag disables enforcement (H2) | web_dc_v1 no-downgrade gate | H2: downgrade resistance suite | Yes |
| Golden vector parity | SAS, HELLO-open, envelope-open (H3) | SAS, HELLO-open, envelope-open (H3) | SDK: 97 TS + 96 Rust (incl. S1 conformance), daemon: 267 tests | Yes |

---

## Repository Tag Snapshot

| Repo | Latest Tag (main) | Main HEAD |
|------|-------------------|-----------|
| bolt-core-sdk | `transport-web-v0.6.1-s2b-instrumentation` | `02e36b1` |
| bolt-daemon | `daemon-v0.2.10-h3-h6-mainline` | `0b16392` |
| bolt-rendezvous | `rendezvous-v0.2.2-s0-canonical-lib-verified` | `fd8d3df` |
| localbolt | `localbolt-v1.0.17` | `276047a` |
| localbolt-app | `localbolt-app-v1.2.1` | `2e8ef6a` |
| localbolt-v3 | `v3.0.63-s0-canonical-rendezvous` | `2963539` |
| bolt-protocol | `v0.1.3-spec` | `6a6de3f` |
| bytebolt-app | `bytebolt-v0.0.1` | — |
| bytebolt-relay | `relay-v0.0.1` | — |

---

## Test Counts (post-merge-train, on main)

| Repo | Tests | Notes |
|------|------:|-------|
| bolt-core-sdk (TS bolt-core) | 97 | Includes H2 enforcement + H3 golden vectors + H6 nonce tests |
| bolt-core-sdk (TS transport-web) | 156 | Includes H2 enforcement tests + 24 S2B transfer metrics |
| bolt-core-sdk (Rust, default) | 85 | main (59 unit + 11 S1 conformance + 15 S2 contract) |
| bolt-core-sdk (Rust, vectors) | 115 | main (59 unit + 27 S1 conformance + 14 H3 vectors + 15 S2 contract) |
| bolt-daemon (default) | 212 | main |
| bolt-daemon (test-support) | 267 | main (includes H3/H5 tests) |
| bolt-rendezvous | 49 | main (48 unit + 1 doc-test) |
| localbolt-v3 (TS) | 26 | main (includes H5-v3 TOFU/SAS tests) |
| localbolt-v3 (Rust signal) | 36 | main (S0 canonical bolt-rendezvous wrapper, up from 32) |

