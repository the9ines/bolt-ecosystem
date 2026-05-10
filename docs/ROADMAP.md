# Bolt Ecosystem — Roadmap

> **Status:** Normative
> **Last Updated:** 2026-03-09 (SEC-BTR1 replaces SEC-DR1 — BTR-STREAM-1 codified)
> **Authority:** PM-approved execution plan.

---

## H-Phase Truthful Ledger

Status labels: **DONE-MERGED** | **DONE-NOT-MERGED** | **IN-PROGRESS** | **NOT-STARTED**

| Phase | Description | Status | Evidence |
|-------|-------------|--------|----------|
| H0 | Protocol enforcement posture | DONE-MERGED | `docs/PROTOCOL_ENFORCEMENT.md` published (filesystem) |
| H1 | Signal server trust-boundary hardening | DONE-MERGED | localbolt-v3 main, tags `v3.0.59-signal-hardening` + `v3.0.62-h1-mainline-merge` |
| H2 | WebRTC enforcement compliance | DONE-MERGED | bolt-core-sdk main, tag `sdk-v0.5.3-h2-h3-mainline` |
| H3 | Cross-implementation golden vectors | DONE-MERGED | SDK: `sdk-v0.5.3-h2-h3-mainline`. Daemon: `daemon-v0.2.10-h3-h6-mainline` |
| H3.1 | Hermetic vectors (daemon) | DONE-MERGED | bolt-daemon main, `daemon-v0.2.10-h3-h6-mainline` |
| H4 | Daemon panic surface elimination | DONE-MERGED | bolt-daemon main, `daemon-v0.2.10-h3-h6-mainline` |
| H5 | Downgrade resistance + enforcement validation (daemon) | DONE-MERGED | bolt-daemon main, `daemon-v0.2.10-h3-h6-mainline` |
| H5-v3 | TOFU/SAS wiring + identity/pin store (localbolt-v3) | DONE-MERGED | localbolt-v3 main, tag `v3.0.61-h5v3-tofu-sas-pinning` |
| H6 | CI enforcement across repos | DONE-MERGED | SDK: `sdk-v0.5.2-h6` on main. Daemon: `daemon-v0.2.9-h6` (via merge). Rendezvous: `rendezvous-v0.2.1-h6` on main. v3: `v3.0.60-h6` on main. |

---

## Merge Train (PM Decision)

**Status: COMPLETE** (2026-02-25)

All H-phase work has been merged to main across all repos. Feature branches preserved (not deleted).

### Step 1: H1 → localbolt-v3 main

- **Branch:** `feature/h1-signal-hardening`
- **Tag on branch:** `v3.0.59-signal-hardening` (`ac5110c`)
- **Gates:**
  - Signal server tests pass
  - Existing v3 tests pass (`npm test`)
  - No regressions in localbolt-v3 functionality
- **Post-merge:** Docs sync commit updating STATE.md + CHANGELOG.md in bolt-ecosystem

### Step 2: H2 → bolt-core-sdk main

- **Branch:** `feature/h2-webrtc-enforcement`
- **Tag on branch:** `sdk-v0.5.0-h2-webrtc-enforcement` (`b4ce544`)
- **Gates:**
  - All TS tests pass: bolt-core (94 tests) + transport-web (138 tests including 21 H2 enforcement tests)
  - No regressions in SDK public API
- **Post-merge:** Docs sync commit

### Step 3: H3 → bolt-core-sdk main

- **Branch:** `feature/h3-golden-vectors` (stacked on H2)
- **Tag on branch:** `sdk-v0.5.1` (`9d8617d`)
- **Gates:**
  - All TS tests pass (94 bolt-core, 138 transport-web)
  - Rust: `cargo test --features vectors` (68 tests)
  - `node print-test-vectors.mjs --check` exits 0 (no vector drift)
- **Post-merge:** Docs sync commit

### Step 4: H3.1 — Fix Daemon Vector Hermeticity

- **Repo:** bolt-daemon
- **Problem:** `tests/h3_golden_vectors.rs` references sibling repo paths (`../bolt-core-sdk/...`). Tests fail unless bolt-core-sdk exists at a specific relative filesystem path. This violates test hermeticity and will break CI.
- **Resolution:** Embed vector JSON directly in daemon test fixtures (e.g., `include_str!` with vendored copies under `tests/vectors/`). Remove all sibling-repo filesystem path dependencies.
- **Gates:**
  - `cargo test --features test-support` passes in a clean checkout (no sibling repos)
  - `cargo clippy` clean
- **Tag:** `daemon-v0.2.8-h3.1-vectors-hermetic`
- **Post-fix:** Docs sync commit

### Step 5: H3 → bolt-daemon main

- **Branch:** `feature/h3-golden-vectors` (must include H3.1 fix)
- **Tag on branch:** `daemon-v0.2.5-h3-golden-vectors` (`3751118`)
- **Gates:**
  - All daemon tests pass (215+ with `--features test-support`)
  - Golden vector parity with SDK vectors verified
- **Post-merge:** Docs sync commit. Final ledger update: H1–H3 status → DONE-MERGED.

### Merge Blockers

| Blocker | Blocks | Resolution | Status |
|---------|--------|------------|--------|
| H3.1 hermeticity — sibling-repo path dependency in daemon tests | Step 5 (daemon H3 merge) | Vendor vector fixtures into daemon repo | **Resolved** — `daemon-v0.2.8-h3.1-vectors-hermetic` |

---

## Execution Queue

### H4 — Daemon Panic Surface Elimination (Reliability)

**Repo:** bolt-daemon
**Status:** DONE-MERGED (tag: `daemon-v0.2.6-h4-panic-elimination`, commit: `678c808`, merged via `daemon-v0.2.10-h3-h6-mainline`)

Removed all `unwrap()`, `expect()`, and `panic!()` from production code paths. Panic in production is a denial-of-service vector.

**Acceptance Criteria:**
- [x] Zero `unwrap()`/`expect()` in `src/*.rs` outside `#[cfg(test)]` and `fn main()`
- [x] Zero `panic!()` in `src/*.rs` outside `#[cfg(test)]`
- [x] `cargo clippy -- -D warnings` clean
- [x] `unwrap_used` / `expect_used` clippy lints enabled as deny in `Cargo.toml` or `clippy.toml`
- [x] All existing tests pass (215+ with `--features test-support`)
- [x] New tests for error paths that previously panicked

**Tag:** `daemon-v0.2.6-h4-panic-elimination`

---

### H5 — Downgrade Resistance + Enforcement Validation (Security + Correctness)

**Repo:** bolt-daemon
**Status:** DONE-MERGED (tag: `daemon-v0.2.7-h5-downgrade-validation`, commit: `257c4a4`, merged via `daemon-v0.2.10-h3-h6-mainline`)

Daemon error code alignment with PROTOCOL_ENFORCEMENT.md Appendix A (13/14 codes validated, `LIMIT_EXCEEDED` deferred), no-downgrade enforcement tests, and enforcement validation across all protocol states.

**Tag:** `daemon-v0.2.7-h5-downgrade-validation`

---

### H5-v3 — TOFU/SAS Wiring + Identity/Pin Store (Security + Correctness)

**Repo:** localbolt-v3
**Status:** DONE-MERGED (tag: `v3.0.61-h5v3-tofu-sas-pinning`, commit: `532d391`)

TOFU identity pinning and SAS verification wired into localbolt-v3 product UI. IndexedDB persistence for identity keypair and peer pins. Verification state bus. Transfer gating. 22 tests.

**Acceptance Criteria:**
- [x] TOFU identity pinning wired into connection flow
- [x] SAS verification displayed to user during first-contact handshake
- [x] Identity/pin store persistence (IndexedDB via SDK)
- [x] Pin store survives page reload and session restart
- [x] Key mismatch → user-visible warning (fail-closed, not silent)
- [x] Re-pairing: delete old pin → store new key → require SAS confirmation
- [x] Tests covering pin store CRUD, mismatch handling, and SAS display

**Tag:** `v3.0.61-h5v3-tofu-sas-pinning`

---

### H6 — CI Enforcement Across Repos (Operational)

**Repos:** bolt-core-sdk, bolt-daemon, bolt-rendezvous, localbolt-v3
**Status:** DONE-MERGED

**Acceptance Criteria:**
- [x] bolt-core-sdk: nonce uniqueness test in CI (TS: 3 tests, Rust: 1 test)
- [x] bolt-core-sdk: golden vector `--check` mode in CI (already present, ordering tightened — drift check before tests)
- [x] bolt-core-sdk (Rust): `cargo test --features vectors` in CI (already present)
- [x] bolt-core-sdk: .nvmrc added (Node 20, parity with CI)
- [x] bolt-daemon: `cargo test --features test-support` in CI (added)
- [x] bolt-daemon: `scripts/check_no_panic.sh` in CI (added)
- [x] bolt-daemon: clippy upgraded from -W to -D warnings (added)
- [x] bolt-rendezvous: clippy upgraded from -W to -D warnings (added)
- [x] localbolt-v3: all gates verified present (clippy -D warnings, coverage thresholds, transport drift guards — no changes needed)
- [x] Working tree clean in all repos
- [ ] localbolt-app: `npm test` enforced in CI — **deferred** (not in H6 scope per prompt)

**Coverage Status:**
- localbolt-v3: enforced (vitest v8, statements:45, branches:5, functions:31, lines:48)
- bolt-core-sdk: deferred — no existing tooling
- bolt-daemon: deferred — no existing tooling
- bolt-rendezvous: deferred — no existing tooling

**Gate Matrix:**

| Gate | bolt-core-sdk | bolt-daemon | bolt-rendezvous | localbolt-v3 |
|------|:---:|:---:|:---:|:---:|
| fmt | TS: tsc, Rust: cargo fmt | cargo fmt | cargo fmt | Rust: cargo fmt |
| clippy -D warnings | Rust: default + vectors | Yes | Yes | Rust: Yes |
| unit tests | TS: vitest (79), Rust: cargo test (55) | cargo test (212) | cargo test (49) | TS: vitest (4), Rust: cargo test (11) |
| feature-gated tests | Rust: --features vectors (60 total) | --features test-support (267 total) | N/A | N/A |
| vector drift check | npm run check-vectors (before tests) | N/A | N/A | N/A |
| nonce uniqueness | TS: 3 tests, Rust: 1 test | N/A | N/A | N/A |
| coverage threshold | deferred | deferred | deferred | vitest v8 (45/5/31/48%) |
| no-panic guard | N/A | scripts/check_no_panic.sh | N/A | N/A |
| build | TS: tsc, Rust: implicit | implicit | implicit | TS: vite build, Rust: cargo build --release |

**Tags:**
- `sdk-v0.5.2-h6-ci-enforcement` (`476881a`)
- `daemon-v0.2.9-h6-ci-enforcement` (`398a63d`)
- `rendezvous-v0.2.1-h6-ci-enforcement` (`6f48ba7`)
- `v3.0.60-h6-ci-enforcement` (`3b12f73`)

---

## Post-H6 Program: S0–S4

Strategic direction approved by PM. Execution order is S0 → S1 → S2 → S3 → S4 unless PM explicitly reorders.

### S0 — Canonical Hardened Rendezvous

**Decision:** One canonical signaling server implementation: bolt-rendezvous.

localbolt-v3 currently maintains its own signal server (`packages/localbolt-signal/`). H1 ported bolt-rendezvous hardening into it. Two implementations create enforcement drift. The ecosystem must converge on bolt-rendezvous as the single implementation.

**Migration plan:**
1. Publish bolt-rendezvous as consumable dependency (Docker image, npm package, or subtree)
2. localbolt-v3 replaces `packages/localbolt-signal/` with bolt-rendezvous
3. All signal server tests migrate to bolt-rendezvous repo
4. localbolt and localbolt-app already consume via subtree — no change
5. localbolt-v3 signal server code removed or reduced to thin config wrapper

**Acceptance Criteria:**
- [x] localbolt-v3 consumes bolt-rendezvous as a dependency
- [x] `packages/localbolt-signal/` reduced to thin wrapper (canonical bolt-rendezvous via cargo git dep)
- [x] bolt-rendezvous owns all trust-boundary enforcement, rate limiting, room lifecycle
- [x] All signal server tests live in bolt-rendezvous (49 tests)

**Status:** DONE-MERGED (`rendezvous-v0.2.2-s0-canonical-lib-verified`, `v3.0.63-s0-canonical-rendezvous`)

### S1 — Core Protocol Conformance Harness (SDK)

**Repo:** bolt-core-sdk
**Status:** DONE-MERGED (tag: `sdk-v0.5.4-s1-conformance-harness`, commit: `cced058`)

Deterministic Rust conformance harness under `rust/bolt-core/tests/conformance/`. 27 tests enforcing MUST-level core protocol invariants using H3 golden vectors. Prevents silent regression in envelope, nonce, SAS, and error mapping logic.

**Scope (enforcement-only, no protocol changes):**
- Envelope roundtrip determinism via H3 vectors (PROTO-01, PROTO-07)
- MAC verification enforcement — tampered/truncated/nonce-only rejection (SEC-06)
- Nonce freshness and uniqueness — 256-seal no-reuse, 24-byte wire format (SEC-01, SEC-02)
- SAS determinism — golden vector match, commutativity, 100-round idempotency (PROTO-06)
- Error code mapping — BoltError + KeyMismatchError display stability (Appendix A, Rust surface)

**TS-owned invariants (not in S1 scope):**
Handshake gating, downgrade resistance, HELLO exactly-once, and 11 of 14 Appendix A error frame codes are transport-level (WebRTCService) and not enforced in the core SDK Rust crate.

**Acceptance Criteria:**
- [x] Conformance test modules in bolt-core-sdk (`rust/bolt-core/tests/conformance/`)
- [x] Tests for MUST-level invariants with Rust-side enforcement
- [x] Tests for Appendix A error codes represented as stable Rust types
- [x] Golden vector consumption from H3 vector files
- [x] Harness runs in CI (default: 11 tests, vectors: 27 tests)
- [x] No protocol behavior, wire format, or crypto logic changed

**Tag:** `sdk-v0.5.4-s1-conformance-harness`

### S2 — Transfer Performance Program (Rust)

**Decision:** Rust-centric transfer scheduling, backpressure, and device-class policy. Not part of H0–H6. Prioritized after audit closure.

**Acceptance Criteria:**
- [ ] Rust crate for transfer scheduling (chunk pacing, backpressure signals)
- [ ] Device-class policy table (mobile, desktop, headless — different buffer/rate limits)
- [ ] WASM build target for browser consumption
- [ ] TS adapter: WASM for scheduling decisions, WebRTC for I/O
- [ ] Integration test: Rust-scheduled transfer completes with correct ordering and pacing
- [ ] No regression in existing transfer tests

### S3 — Logic Not Transport Principle

**Decision:** Keep crypto, framing, state machine authority in Rust. TS is a consumer, not a source of protocol truth. Depends on S1 proving the model.

**Acceptance Criteria:**
- [ ] All new protocol logic implemented in Rust first, TS second
- [ ] Golden vectors generated from Rust (reversal of current TS-generates model)
- [ ] Protocol state machine defined in Rust, consumed by TS via WASM or FFI
- [ ] Transition plan for existing TS-generated vectors (frozen, then deprecated)

### S4 — WASM Protocol Engine (Optional)

**Decision:** WASM module owning state machine, enforcement codes, and routing. Proceed only if S2 demonstrates viable WASM-in-browser integration.

**Gate:** S2 must succeed first.

**Acceptance Criteria:**
- [ ] WASM module exports: `new_session()`, `process_message()`, `get_state()`, `get_error()`
- [ ] State machine transitions enforced in WASM, not in TS
- [ ] TS becomes thin I/O adapter: WebRTC ↔ WASM ↔ UI
- [ ] All conformance tests (S1) pass against WASM engine
- [ ] Bundle size < 100KB gzipped

---

## Workstream C — LocalBolt Application Convergence + Session UX Hardening

**Status:** COMPLETE (all phases C0–C7 DONE).

Converges app-layer behavior across localbolt-v3, localbolt, and localbolt-app into a shared `localbolt-core` package. Hardens session UX against disconnect/reconnect race conditions. Package-based distribution with exact version pins (not subtree).

**Extraction baseline:** localbolt-v3 (most advanced app-layer verification/session wiring).

### Execution Queue

| Phase | Description | Status | Blockers |
|-------|-------------|--------|----------|
| C0 | Policy lock — verification UX decision | DONE | `v3.0.70-session-hardening-cpre2` |
| C1 | localbolt-core scaffold + ARCH-08 disposition | DONE | `v3.0.71-localbolt-core-c2` |
| C2 | Extract canonical runtime from v3 baseline | DONE | `v3.0.71-localbolt-core-c2` |
| C3 | Migrate localbolt-v3 consumer | DONE | `v3.0.71-localbolt-core-c2` |
| C4 | Migrate localbolt consumer | DONE | `localbolt-v1.0.21-c4-localbolt-core` |
| C5 | Migrate localbolt-app web consumer | DONE | `localbolt-app-v1.2.4-c5-localbolt-core` |
| C6 | Drift guards + upgrade protocol | DONE | `localbolt-v1.0.24-c6-hardening`, `localbolt-app-v1.2.7-c6-hardening`, `v3.0.73-c6-hardening` |
| C7 | Session UX race-hardening | DONE | `v3.0.74-c7-closure` |

### Dependency Map

```
C0 (PM policy decision) ← BLOCKER
 │
 └── C1 (scaffold + ARCH-08 gate) ← BLOCKER
      │
      └── C2 (extract from v3)
           │
           ├── C3 (migrate v3) ──────┐
           ├── C4 (migrate localbolt) ├── C6 (drift guards)
           ├── C5 (migrate app) ─────┘
           │
           └── C7 (session race-hardening)  [parallel with C3–C6]
```

### Parallelization

- C3, C4, C5 can execute in parallel after C2.
- C7 can execute in parallel with C3–C6 (requires C2 only).
- C6 requires all three consumer migrations (C3+C4+C5) before guard enforcement.

### Audit Findings (Q-series)

| Finding | ID | Severity | C-Phase |
|---------|------|----------|---------|
| Disconnect/reconnect stale callback races | Q7 | MEDIUM | C7 |
| Verification policy mismatch | Q8 | MEDIUM | C0 |
| App-layer behavior drift | Q9 | MEDIUM | C2–C5 |
| Missing app-layer drift guards | Q10 | MEDIUM | C6 |

---

## Workstream D — CI Stabilization + Package Auth Migration (D-STREAM-1)

**Status:** Codified (IN-PROGRESS — D0 policy locked, D0.5 NOT-STARTED)
**Codified:** ecosystem-v0.1.60-d-stream-1-codify (2026-03-05)
**Primary success gate:** Netlify deploy reliability (PAT-independent)

| Phase | Description | Status | Dependencies |
|-------|-------------|--------|-------------|
| D0 | Policy lock | IN-PROGRESS | None (policy 1–4 decided; D0.5 pending) |
| D1 | Failure triage + classification | NOT-STARTED | None |
| D2 | CI stabilization (evidence-driven) | NOT-STARTED | D1 |
| D3 | Package auth/registry migration | NOT-STARTED | BLOCKED-BY D0.5 |
| D4 | Netlify hardening (critical path) | NOT-STARTED | D3 |
| D5 | Drift guards + enforcement | NOT-STARTED | D4 |
| D6 | Burn-in + closure | NOT-STARTED | D4, D5 |

**Full specification:** `docs/GOVERNANCE_WORKSTREAMS.md` (Workstream D section)

---

## Workstream N — Native App + Daemon Bundling (N-STREAM-1)

**Status:** **CLOSED** (N0–N7 DONE, A0 DONE)
**Codified:** ecosystem-v0.1.72-n-stream-1-codify (2026-03-07)
**N0 locked:** ecosystem-v0.1.73-n-stream-1-n0-policy-lock (2026-03-07)
**N1+N2 locked:** ecosystem-v0.1.74-n-stream-1-n1-n2-lock (2026-03-07)
**N3 locked:** ecosystem-v0.1.75-n-stream-1-n3-supervision (2026-03-07)
**N4+N5 locked:** ecosystem-v0.1.76-n-stream-1-n4-n5-lock (2026-03-07)
**N7 closure:** ecosystem-v0.1.82-n-stream-1-n7-closure (2026-03-07)
**Primary success gate:** localbolt-app ships with bundled bolt-daemon as a single supervised product.

| Phase | Description | Status | Dependencies |
|-------|-------------|--------|-------------|
| N0 | Policy lock (lifecycle, restart, single-instance, crash recovery) | **DONE** | None |
| N1 | Packaging + security matrix (macOS/Windows/Linux) | **DONE** | N0 |
| N2 | IPC contract stabilization | **DONE** (spec locked; all impl deps resolved) | N0 |
| N3 | Process supervision + diagnostics | **DONE** (spec locked; B-DEP-N2-1/N2-2 **RESOLVED**) | N2 |
| N4 | Rollout + migration | **DONE** (spec locked) | N1, N2 |
| N5 | Acceptance harness | **DONE** (spec locked) | N2, N3 |
| N6 | Execution + hardening | **DONE** | N4, N5 |
| A0 | Signaling ownership evaluation (governance-only) | **DONE** | N6 |
| N7 | Closure | **DONE** | N6, A0 |
| N8 | D2 signal observability (post-closure follow-on) | **DONE** | N7, A0 |

**Ownership boundary:** N-STREAM-1 governs bundling/lifecycle/packaging/supervision. B-STREAM governs daemon protocol/runtime. N-STREAM-1 consumes daemon API surface, does not redefine it.

**Signal ownership decision (A0, 2026-03-07):** Option A (status quo coexistence) approved. App owns embedded signaling server (bolt-rendezvous via signal/ subtree). Daemon owns IPC decisions only. Options B (daemon-only signaling) and D1 (daemon spawns signal) rejected — amendment burden (7–9 locked decisions) and guardrail 13 violation outweigh benefits.

**N7 closure (2026-03-07):** All closure criteria (C1–C5) passed. Phase ledger finalized. All 4 B-DEPs RESOLVED. Residual R17 (Windows runtime validation, Low) was OPEN at closure — subsequently CLOSED 2026-03-08 via Windows CI validation. Stream status: CLOSED.

**R17 closure (2026-03-08):** Windows CI (`windows-latest`) provisioned for bolt-daemon and localbolt-app. Named pipe IPC code validated on real Windows runtime. Daemon: fmt/clippy/test all PASS (362+429 tests, 0 failures). App: fmt/clippy PASS (test binary crash: WebView2 DLL missing on headless CI — Tauri platform dependency, not IPC). 8 R17 fix commits across both repos. Tags: `daemon-v0.2.34-r17-windows-validated` (`82d0f83`), `localbolt-app-v1.2.15-r17-windows-validated` (`7116d12`).

**N8 signal observability (2026-03-07):** D2 follow-on delivered as post-closure item (Option C stream semantics — standalone lineage-linked, stream remains CLOSED). AC-SE-06/07 realized with architecture-neutral wording: app-side TCP probe (Path 1), zero daemon changes. Unified health indicator aggregates daemon + signal status. No transfer gating changes (observability only). 146 tests (82 Rust + 64 web), 0 regressions. Tag: `localbolt-app-v1.2.14-n8-signal-observability` (`a7e4f8b`).

**Full specification:** `docs/GOVERNANCE_WORKSTREAMS.md` (Workstream N section)

---

## Workstream Q — APP-TO-APP-QUIC-MIGRATION-1

**Status:** NOT-STARTED (PM scope locked 2026-05-10; security model locked 2026-05-10 via APP-TO-APP-QUIC-SECURITY-DECISION-1, see Security Decision below)
**Scope:** Promote QUIC from RC3 reference to production native↔native transport in bolt-daemon.
**Repos:** bolt-daemon (primary), localbolt-app (integration), bolt-core-sdk (doc authority)
**Dependency:** None blocking. WS client mode remains the production native↔native path until QUIC clears every promotion gate, including the transport-auth gate in Q2.

### PM Constraints

1. **Accept-any TLS (`Rc3SkipVerification`) is NOT an acceptable production end state.** QUIC must ship with real transport-layer authentication.
2. **Production transport authentication = mutual cert-hash pinning** (locked 2026-05-10 via APP-TO-APP-QUIC-SECURITY-DECISION-1; see Security Decision below). Bolt HELLO / SAS / TOFU remains the identity-authentication layer; cert-hash pinning is the transport-authentication layer.
3. **WS client mode remains fallback** after QUIC graduation — not removed.

### Security Decision — APP-TO-APP-QUIC-SECURITY-DECISION-1 (CLOSED 2026-05-10)

**Decision:** Native↔native QUIC production authentication will use mutual cert-hash pinning. Each daemon presents an ephemeral self-signed QUIC certificate, shares the expected certificate hash through rendezvous signaling, and verifies the peer certificate hash during the QUIC TLS handshake. Bolt HELLO / SAS / TOFU remains the identity-authentication layer; cert-hash pinning is the transport-authentication layer. The model mirrors the proven WebTransport cert-hash flow, adapted for symmetric daemon↔daemon where both peers can present certificates.

**Production promotion blocker:** QUIC must NOT be promoted to the production app↔app path while `Rc3SkipVerification`, accept-any certificate verification, or any equivalent envelope-only transport authentication remains reachable in a default-feature code path.

**Interim milestone allowance:** One-way cert-hash pinning (dialer verifies acceptor only) may be used ONLY as an internal non-production milestone (see Q1) to retire `Rc3SkipVerification` on the dialer side. One-way pinning alone does NOT satisfy the production promotion blocker. Production promotion requires mutual daemon↔daemon pinning (Q2) or a later explicit PM / security exception that is recorded as a separate decision.

**Rejected alternatives (do not revisit without a new decision record):**
- *"Accept any TLS certificate and rely only on the Bolt envelope."* Rejected for production. Transport-layer MitM remains possible even with payload encryption, and defense-in-depth at the transport layer is required.
- *"Embed the X25519 identity public key inside an X.509 certificate extension and treat the extension as identity binding."* Rejected because it provides no cryptographic binding — the X25519 public key is exchanged via signaling, so any party aware of it can forge a certificate that carries the same extension without proving possession of the X25519 private key.
- *"Migrate the Bolt identity key from X25519 to Ed25519 solely to enable identity-bound QUIC TLS certificates."* Rejected for this migration. Bolt identity keys are X25519 / Curve25519 (DH-only) by design; X25519 cannot sign TLS certificates. An identity migration would touch identity storage, trust-store keying, SAS derivation, and HELLO payloads across bolt-core-sdk, bolt-daemon, localbolt-app, and localbolt-v3. The cost / risk ratio is wrong relative to cert-hash pinning, which provides equivalent practical security with zero changes to the identity model. This decision does not preclude a future Ed25519 migration driven by independent requirements (e.g., signed profile metadata).

**Out of scope of this decision:**
- TLS-exporter channel binding inside Bolt HELLO is a future hardening option, not a Q-stream gate.
- The WT (browser↔native) cert-hash model is unaffected; this decision applies only to native↔native QUIC.

### Current State

| | Status |
|---|---|
| **Production app↔app transport** | WebSocket client mode (NATIVE-CONNECT-1) |
| **QUIC transport layer** | Functional (tests pass: connect, framing, 1 MiB transfer) |
| **QUIC cert validation** | `Rc3SkipVerification` — accepts any cert (INSECURE) |
| **QUIC signaling integration** | None — not wired into rendezvous or WsEndpoint mode |
| **QUIC IPC/pairing** | None — no session events, no pairing approval |
| **QUIC feature flag** | `transport-quic` (opt-in, not in default features) |

### Phase Plan

| Phase | Description | Status | Dependencies |
|-------|-------------|--------|-------------|
| Q0 | Policy + security decision lock (this section; APP-TO-APP-QUIC-SECURITY-DECISION-1 closed 2026-05-10) | **DONE** | None |
| Q1 | Transport auth milestone (internal, non-production) — replace `Rc3SkipVerification` with one-way cert-hash pinning verifier on the dialer | NOT-STARTED | None |
| Q2 | Signaling integration + mutual cert-hash pinning (production transport-auth gate) — when implemented, both daemons must exchange cert hashes via rendezvous and verify the peer cert during the QUIC TLS handshake. Not started; mutual pinning does not yet exist. | NOT-STARTED | Q1 |
| Q3 | IPC/pairing + disconnect propagation — full session lifecycle parity with WS | NOT-STARTED | Q2 |
| Q4 | Feature flag promotion + localbolt-app wiring (production-promotion gate) — end-to-end native↔native QUIC, with the production promotion blocker (no `Rc3SkipVerification` / accept-any reachable, mutual pinning live) verified | NOT-STARTED | Q3 |
| Q5 | E2E validation + WS fallback — two-device proof, fallback tested | NOT-STARTED | Q4 |
| Q6 | Docs graduation — TRANSPORT_CONTRACT.md: QUIC → Production, WS → Fallback | NOT-STARTED | Q5 |

### Q1 — Transport Auth Milestone (Internal, Non-Production)

**Objective:** Retire `Rc3SkipVerification` on the dialer side by introducing a one-way cert-hash pinning verifier. This is an internal milestone — sufficient to remove accept-any verification from the dialer, NOT sufficient for production promotion (the acceptor still cannot verify the dialer).

**Approach (per APP-TO-APP-QUIC-SECURITY-DECISION-1):** Mirror the WT cert-hash flow on the dialer:
- Acceptor daemon generates an ephemeral self-signed QUIC certificate. Reuse `wt_cert.rs` cert-generation logic where practical (extract a shared helper if needed).
- Acceptor computes `SHA-256(cert_der) → cert_hash_hex` and exposes it through a local mechanism (file in data dir or IPC) suitable for an internal milestone. Q1 does NOT require signaling-protocol changes.
- Dialer daemon's QUIC client config replaces `Rc3SkipVerification` with a `CertHashPinVerifier` that computes `SHA-256(received_cert_der)` and compares it against the pinned hash. Mismatch → connection refused, fail-closed.
- After TLS: Bolt HELLO → SAS → TOFU (unchanged).

**Acceptance criteria:**
- [ ] `Rc3SkipVerification` is removed from any code path reachable in a default-feature build.
- [ ] Dialer-side cert-hash verifier rejects connections when the received cert hash does not match the pinned hash.
- [ ] Cert mismatch = connection refused (fail-closed); the failure surfaces as a typed transport error.
- [ ] Unit tests: matching hash succeeds; mismatched hash fails; corrupted hash input fails closed.
- [ ] No regression in existing QUIC transport tests.
- [ ] Q1 is explicitly labeled "internal, non-production" in code comments and in `bolt-daemon/docs/STATE.md` transport table.

**Production gating:** Q1 alone does NOT satisfy the APP-TO-APP-QUIC-SECURITY-DECISION-1 production promotion blocker. The acceptor still cannot verify the dialer, and signaling integration is not yet present. Production promotion remains blocked until Q2 lands mutual pinning.

**Rejected at Q1 (per Security Decision):**
- Accept-any TLS / envelope-only auth as an interim posture beyond Q1 (only acceptable as the existing pre-Q1 RC3 state).
- Embedding the X25519 identity public key in an X.509 extension as a substitute for cert-hash verification.
- Migrating Bolt identity keys to Ed25519 to enable identity-bound TLS certificates instead of cert-hash pinning.

### Q2 — Signaling Integration + Mutual Cert-Hash Pinning (Production Transport-Auth Gate)

**Status:** NOT-STARTED. None of the items below currently exist in the codebase. Mutual cert-hash pinning does not yet exist anywhere in bolt-daemon, the rendezvous signaling protocol, or localbolt-app. Q2 is a forward gate that must be crossed; it is not a present-state description.

**Objective:** Q2 will wire QUIC into the default daemon startup path and the rendezvous signaling protocol, and will establish mutual cert-hash pinning between both daemons. Crossing Q2 — i.e., satisfying every acceptance criterion below and verifying the result — is what would satisfy the APP-TO-APP-QUIC-SECURITY-DECISION-1 production promotion blocker at the transport layer. Until Q2 is crossed, the blocker remains in force and QUIC remains a Reference (RC3) transport. Remaining work (Q3–Q5) covers session-lifecycle parity and validation, not transport-auth.

**Acceptance criteria:**
- [ ] QUIC listener starts alongside WS + WT in WsEndpoint mode.
- [ ] Acceptor daemon writes its QUIC listen address and `quicCertHash` for the native app to consume (analogous to `wt_info.json` for WT).
- [ ] Native app includes `quicAddr` and `quicCertHash` in the `connection_accepted` signaling payload.
- [ ] The dialer also publishes its own cert hash so the acceptor can pin it (exact field name — e.g. `quicClientCertHash` — settled during implementation).
- [ ] Both daemons present client and server certificates via `with_client_auth()` / `ClientCertVerifier` (rustls/quinn), and both sides verify the peer cert hash against the signaling-supplied hash. Mismatch on either side → connection refused, fail-closed.
- [ ] No code path reachable in a default-feature build uses `Rc3SkipVerification`, accept-any verification, or otherwise bypasses cert-hash pinning. Static / build-time check preferred where feasible.
- [ ] Backward compat: if `quicAddr` / `quicCertHash` absent in signaling, fall back to WS client mode.
- [ ] Unit + integration tests: mutual pin success; one-side mismatch fail-closed; missing-hash fall-back to WS.

### Q3 — IPC/Pairing + Disconnect

**Objective:** QUIC sessions have full lifecycle parity with WS sessions.

**Acceptance criteria:**
- [ ] `session.connected` / `session.ended` / `session.error` IPC events for QUIC
- [ ] Pairing approval flow (trust store check before accepting QUIC connection)
- [ ] `DISCONNECT_REQUESTED` flag + `request_disconnect()` for QUIC (mirror WS/WT pattern)

### Q4 — Feature Flag + App Wiring (Production-Promotion Gate)

**Objective:** End-to-end native↔native QUIC path operational and promoted to production. Q4 is the production-promotion gate — promotion is blocked until the APP-TO-APP-QUIC-SECURITY-DECISION-1 production blocker is verifiably satisfied.

**Pre-gate (must be true before Q4 can be marked complete):**
- Q2 mutual cert-hash pinning is live in default-feature code paths.
- `Rc3SkipVerification`, accept-any cert verification, and any envelope-only transport-auth code paths are not reachable in a default-feature build (verified by code search and, where feasible, a build-time check).

**Acceptance criteria:**
- [ ] Pre-gate verified (mutual cert-hash pinning live; no accept-any reachable in default features).
- [ ] `transport-quic` added to default features (or a `native-full` meta-feature) — only after the pre-gate is satisfied.
- [ ] localbolt-app build enables QUIC feature.
- [ ] `connect_remote.signal` routes to QUIC when available, WS fallback otherwise.
- [ ] All existing daemon tests pass with QUIC enabled.

### Q5 — E2E Validation

**Objective:** Production-ready evidence.

**Acceptance criteria:**
- [ ] Two-device QUIC transfer test (Mac Studio ↔ MacBook Pro)
- [ ] Disconnect propagation validated
- [ ] Pairing approval validated
- [ ] WS fallback tested (QUIC unavailable → WS client mode)
- [ ] Performance comparison vs WS client mode documented

### Q6 — Docs Graduation

**Objective:** Remove "reference" label, update transport tables.

**Acceptance criteria:**
- [ ] TRANSPORT_CONTRACT.md: native↔native row updated to QUIC = Production, WS = Fallback
- [ ] INTEGRATION_GUIDE.md: same update
- [ ] bolt-daemon STATE.md: QUIC listed as production
- [ ] N1 invariant note updated or removed

### Risk Register (Q-STREAM)

| ID | Risk | Severity | Status |
|----|------|----------|--------|
| QR1 | Mutual cert-hash pinning requires bidirectional cert-hash exchange in signaling and dual-direction client+server cert verification (rustls `with_client_auth()` + `ClientCertVerifier`) — implementation risk in quinn/rustls integration | Medium | Open |
| QR2 | QUIC UDP may be blocked by some corporate firewalls (WS fallback mitigates) | Low | Accepted |
| QR3 | quinn crate major version changes during migration | Low | Open |
| QR4 | Identity-key-to-TLS-binding alternative (rejected) — rejected by APP-TO-APP-QUIC-SECURITY-DECISION-1 because Bolt identity is X25519/DH-only and an identity migration to Ed25519 is out of scope. Risk: future contributor proposes the rejected approach without consulting the decision record | Low | Mitigated (decision recorded in Security Decision section above) |

---

## Risk Register

| ID | Risk | Severity | Status | Closes When |
|----|------|----------|--------|-------------|
| R1 | H1–H3 on feature branches, not merged to main | High | **Closed** | Merge train complete (2026-02-25) |
| R2 | Daemon panic surface in production code | High | **Closed** | H4 merged to main (`daemon-v0.2.10-h3-h6-mainline`) |
| R3 | No CI gate for golden vector drift | Medium | Closed | H6 CI enforcement (sdk-v0.5.2-h6-ci-enforcement) |
| R4 | Two signal server implementations (bolt-rendezvous + localbolt-signal) | Medium | Open | S0 canonical convergence |
| R5 | TS is protocol-authoritative (vectors generated from TS) | Low | Accepted | S3 Rust-first generation |
| R6 | No cross-impl conformance harness | Medium | **Closed** | S1 conformance harness (`sdk-v0.5.4-s1-conformance-harness`) |
| R7 | Daemon H3 test hermeticity — sibling repo path dependency | High | **Closed** | H3.1 merged to main (`daemon-v0.2.10-h3-h6-mainline`) |
| R8 | H2/H3 feature branch stacking — merge conflict risk | Low | **Closed** | Merge train steps 2–3 completed cleanly |
| R9 | No TOFU/SAS wiring in localbolt-v3 product UI | Medium | **Closed** | H5-v3 merged (`v3.0.61-h5v3-tofu-sas-pinning`) |
| R10 | App-layer behavior drift across 3 LocalBolt products | Medium | **Closed** | C-stream convergence (C2–C5 DONE, all consumers on `@the9ines/localbolt-core@0.1.0`) |
| R11 | ARCH-08 disposition unresolved for localbolt-core placement | Medium | **Closed** | C1 ARCH-08 gate: Option 2 non-violating location (`localbolt-v3/packages/localbolt-core`) |
| R12 | Daemon IPC surface unstable — N2 depends on B-stream maturity | Medium | **Closed** | N2 IPC contract locked against current daemon API baseline (`ecosystem-v0.1.74-n-stream-1-n1-n2-lock`) |
| R13 | Cross-platform packaging complexity — macOS/Windows/Linux signing and notarization | Medium | **Closed** | N1 packaging matrix locked per platform (`ecosystem-v0.1.74-n-stream-1-n1-n2-lock`) |
| R14 | Daemon crash recovery undefined — single-instance and lifecycle policy not yet decided | Medium | **Closed** | N0 policy lock completed (`ecosystem-v0.1.73-n-stream-1-n0-policy-lock`) |
| R15 | B-DEP-N2-1/N2-2: daemon.status + version handshake not yet in default mode — N3 spec locked, blocks N6 implementation of readiness + version-gated supervision | High | **Closed** | `daemon-v0.2.31-bdep-n2-ipc-unblock` (`1ad2db8`) — daemon.status in all modes + version.handshake/version.status implemented |
| R16 | B-DEP-N2-3: Windows named pipe not supported — blocks N6 Windows GA | Medium | **Closed** | N6-B3 integrated Windows named pipe transport (`ipc_transport.rs` + `daemon-v0.2.33`). Code complete, B-DEP resolved. |
| R17 | Windows runtime validation — named pipe IPC on Windows | Low | **Closed** | Closed 2026-03-08: Windows CI provisioned (`windows-latest`). Daemon fmt/clippy/test all PASS (791 tests). App fmt/clippy PASS (test FAIL: WebView2 DLL, not IPC). Tags: `daemon-v0.2.34-r17-windows-validated`, `localbolt-app-v1.2.15-r17-windows-validated`. |

---

## Conformance

### Error Code Registry

Authoritative source: `docs/PROTOCOL_ENFORCEMENT.md` Appendix A (14 codes).

All implementations MUST emit the correct error code for each violation type.

Current status:
- Daemon: 13/14 codes validated (`LIMIT_EXCEEDED` deferred). Validated during INTEROP-2 through H3.
- SDK (TS): H2 covers core enforcement codes. Full 14-code gap analysis is part of H6.

### Golden Vector Drift Enforcement

Authoritative source: `bolt-core-sdk/ts/bolt-core/__tests__/vectors/` (5 vector files).

- `box-payload.vectors.json` — NaCl box seal/open (4 valid + 4 corrupt)
- `framing.vectors.json` — envelope framing (4 cases)
- `sas.vectors.json` — SAS computation (4 cases)
- `web-hello-open.vectors.json` — HELLO open (3 cases)
- `envelope-open.vectors.json` — envelope open (3 cases)

Generator: `ts/bolt-core/scripts/print-test-vectors.mjs`
Drift check: `node print-test-vectors.mjs --check` (exits non-zero on drift)

**Current consumers:**
- TS bolt-core: vector tests in `__tests__/`
- Rust bolt-core: `tests/vector_compat.rs`, `tests/vector_equivalence.rs`, `tests/h3_open_vectors.rs`, `tests/sas_vectors.rs`
- bolt-daemon: `tests/` (with `--features test-support`) — hermeticity fixed (H3.1), vectors vendored via `include_str!`

**CI gate status:** Enforced (H6). Drift check runs before tests in bolt-core-sdk CI.

---

## Dependency Map

```
H0 (PROTOCOL_ENFORCEMENT.md)
 │
 ├── H1 (signal hardening) ─────────────────────────── S0 (canonical rendezvous)
 │
 ├── H2 (WebRTC enforcement)
 │     │
 │     └── H3 (golden vectors)
 │           │
 │           ├── H3.1 (hermetic vectors) ✓ ──► daemon H3 merge
 │           │
 │           └── H5-v3 (TOFU/SAS wiring)
 │
 ├── H4 (daemon panic elimination) ✓
 │
 └── H5 (downgrade validation) ✓

Merge Train: COMPLETE ✓
  H1 → H2 → H3(SDK) → H3.1/H4/H5/H6(daemon) — all merged to main
  H5-v3: merged ✓
  H6 (CI enforcement): merged ✓

Post-merge-train: S0 → S1 → S2 → S3 → S4 (optional)

Workstream C (COMPLETE):
  C0→C1→C2→C3/C4/C5→C6→C7 — all DONE

Workstream D (independent of A/B/S, builds on C6 guards):
  D0 (policy lock, IN-PROGRESS) ──┐
  D0.5 (npmjs scope gate) ────────┼── D3 (registry migration) → D4 (Netlify) → D5 (guards) → D6 (burn-in)
  D1 (failure triage) → D2 (CI stabilization)

S-STREAM-R1 (security/foundation recovery, independent of D-stream):
  R1-0 (baseline evidence) ✓ → R1-1 (dispositions locked) ✓
    ├── R1-2 (daemon remediation) ✓ DONE-NO-ACTION
    ├── R1-3 (product crypto converge) ✓ DONE-NO-ACTION
    └── R1-4 (security test lift) ✓ DONE
         └── R1-5 (validation) ✓ DONE → R1-6 (closure) ✓ DONE

C-STREAM-R1 (UI/state regression recovery, independent of D-stream):
  Single phase: generation guards + snapshot fix + trust truth table → DONE (v3.0.80-c-stream-r1-ui-state-fix)

Q-STREAM (APP-TO-APP-QUIC-MIGRATION-1 — NOT-STARTED):
  Q0 (policy lock) ✓ → Q1 (transport auth) → Q2 (signaling) → Q3 (IPC) → Q4 (app wiring) → Q5 (E2E) → Q6 (docs)

N-STREAM-1 (native app + daemon bundling — **CLOSED**):
  N0 (policy lock) ✓ ──┬── N1 (packaging) ✓ ──┐
                       │                      ├── N4 (rollout) ✓ ──┐
                       └── N2 (IPC contract) ✓┤                    ├── N6 (execution) ✓ → N7 (closure) ✓
                            │                 └── N5 (harness) ✓ ──┘
                            └── N3 (supervision) ✓ ──┘
  B-STREAM deps: ALL RESOLVED
  Residuals: R17 (CLOSED 2026-03-08), OQ-2 (graceful shutdown, Low, OPEN)
```

---

## S-STREAM-R1 — Security/Foundation Recovery

**Status:** **CLOSED/DONE** (ecosystem-v0.1.69-s-stream-r1-closeout)
**Codified:** ecosystem-v0.1.65-s-stream-r1-codify (2026-03-06)
**R1-1:** ecosystem-v0.1.67-s-stream-r1-r1.1-disposition (2026-03-06)
**Priority:** Resolve foundational security/runtime risks before further UX work.

| Phase | Description | Status | Dependencies |
|-------|-------------|--------|-------------|
| R1-0 | Baseline evidence + risk classification | **DONE** | None |
| R1-1 | Architecture decision (evidence-informed) | **DONE** | R1-0 |
| R1-2 | Daemon remediation + security tests | **DONE-NO-ACTION** | R1-1 |
| R1-3 | Product crypto-path convergence | **DONE-NO-ACTION** | R1-1 |
| R1-4 | Security-focused product test lift | **DONE** | R1-1 |
| R1-5 | Validation gates | **DONE** | R1-4 |
| R1-6 | Governance reconciliation + closure | **DONE** | R1-5 |

**Sole residual:** Rust SDK reconnect/race tests (LOW) — deferred, not a critical/high risk.

Full specification in `docs/GOVERNANCE_WORKSTREAMS.md` (S-STREAM-R1 section).

---

## Forward Backlog (Post-R17)

**Status:** Codified
**Codified:** ecosystem-v0.1.86-roadmap-codify-transfer-security-mobile (2026-03-08)
**Full specification:** `docs/FORWARD_BACKLOG.md`

### Priority Tiers

**NOW:**
| ID | Item | Routing | Status |
|----|------|---------|--------|
| B-XFER-1 | Transfer pause/resume completion (daemon transfer SM remaining scope) | bolt-daemon | **DONE** (`daemon-v0.2.35-bxfer1-pause-resume`) |
| REL-ARCH1 | Multi-arch daemon build/package matrix | bolt-daemon + ecosystem | **DONE** (`daemon-v0.2.38-relarch1-multiarch-matrix`, `ab56606`) |
| RECON-XFER-1 | Transfer reconnect recovery after mid-transfer disconnect | bolt-core-sdk (TS) + consumers | NOT-STARTED |

**NEXT:**
| ID | Item | Routing | Status |
|----|------|---------|--------|
| SEC-DR1 | Double Ratchet pre-ByteBolt security gate (DR-STREAM-1) | bolt-core-sdk + bolt-protocol | **SUPERSEDED-BY: SEC-BTR1** (frozen) |
| SEC-BTR1 | Bolt Transfer Ratchet pre-ByteBolt security gate (BTR-STREAM-1) | bolt-core-sdk + bolt-protocol | **P0-DONE** (stream kickoff codified) |
| T-STREAM-0 | Rust transfer core (no UDP in v1) | `bolt-transfer-core` (bolt-core-sdk workspace) + daemon consumer | **DONE** (`sdk-v0.5.30-tstream0-transfer-core-v1`) |
| SEC-CORE2 | Rust-first security/protocol consolidation | bolt-core-sdk | NOT-STARTED |

**LATER:**
| ID | Item | Routing | Status |
|----|------|---------|--------|
| T-STREAM-1 | Browser selective WASM integration | bolt-core-sdk (TS) + WASM + consumers | **DONE** (`sdk-v0.5.32-tstream1-wasm-policy-wiring`, consumers adopted) |
| PLAT-CORE1 | Shared Rust core + thin platform UIs | TBD | NOT-STARTED |
| MOB-RUNTIME1 | Mobile embedded runtime model | TBD | NOT-STARTED |
| ARCH-WASM1 | WASM protocol engine (medium risk) | bolt-core-sdk + WASM | NOT-STARTED |

### Dependency Map

```
NOW:
  B-XFER-1 ──────────────────┐  ✓ DONE (daemon-v0.2.35)
  REL-ARCH1 ──────────────────┘ ✓ DONE (daemon-v0.2.38)
  RECON-XFER-1 ◄── T-STREAM-1 (DONE, prerequisite context)
                              │
NEXT:                         │
  T-STREAM-0 ◄───────────────┘ ✓ DONE (sdk-v0.5.30, daemon-v0.2.36)
  SEC-DR1 (independent, pre-ByteBolt gate)
  SEC-CORE2 ◄── S1 (DONE)
                              │
LATER:                        │
  T-STREAM-1 ◄── T-STREAM-0  │  ✓ DONE (sdk-v0.5.32, consumers adopted)
  PLAT-CORE1 ◄── T-STREAM-0 + SEC-CORE2
  MOB-RUNTIME1 ◄── PLAT-CORE1 (priority ≤ PLAT-CORE1)
  ARCH-WASM1 ◄── T-STREAM-0 + S4 gate
```

### Relationship to Existing S-Program

T-STREAM-0 is the concrete extraction backing S2 (Transfer Performance Program). SEC-CORE2 continues S3 (Logic Not Transport). ARCH-WASM1 extends S4 (WASM Protocol Engine). The forward backlog items supersede S2–S4 as actionable execution plans; S2–S4 remain as strategic direction references.

---

## BOLT-ECOSYSTEM-1 — Cross-Product Contract + Transport Program

> **Status:** IN-PROGRESS
> **Codified:** 2026-03-29
> **Authority:** PM-approved. Execution order below is normative.

### Exit Criteria

Program is COMPLETE when all of:
1. Canonical session/transfer contract v1 is stable and tested (bolt-core-sdk)
2. Web and native products demonstrably conform to the contract
3. Production transport path (HTTPS web ↔ native) is runtime-validated
4. Parity tests exist across products
5. Integration docs exist for external adopters
6. At least one non-core consumer successfully adopts the contract

### Completed Work

| Stream | Description | Status | Evidence |
|--------|-------------|--------|----------|
| SESSION-STATE-CONTRACT-1 M1 | Contract scaffold (types, validators, schema, spec) | **DONE** | `bolt-core-sdk/docs/SESSION_CONTRACT.md`, `src/contracts/session_contract.rs` (19 tests) |
| SESSION-STATE-CONTRACT-1 M2 | Web conformance audit | **DONE** | localbolt-v3 CONFORMANT across all 5 session phases, 3 verification states, all invariants. Both RECOMMENDED invariants (INV-4/5) exceeded. |
| SESSION-STATE-CONTRACT-1 M3 | Native alignment | **DONE** | localbolt-app models 5 canonical phases + presentation-only `disconnected`. Generation counter, transfer gating (P1), canonical reset implemented. |
| NATIVE-CONNECT-1 | Native app↔app direct WS connection | **DONE** | WS client dialer in daemon, signal file mechanism, IPC session events. Runtime-confirmed: connect, transfer, disconnect. |
| NATIVE-SESSION-UX-2 | Native session/transfer state hardening | **DONE** | Disconnect propagation (daemon signal file), transfer cleanup on session end, declined handling. |
| TRANSPORT-VALIDATION-1 | Cross-path transport validation (SRE protocol) | **DONE (CLOSED)** | WS-direct CONFIRMED, WebTransport CONFIRMED (handshake), QUIC CONFIRMED (4/4 e2e), WebRTC signaling CONFIRMED. |
| WEB-NATIVE-TRANSPORT W1 | WT metadata plumbing through discovery | **DONE** | `wtUrl`/`wtCertHash` fields added: rendezvous protocol → signaling client → native FFI → web DiscoveredDevice. Backward-compatible. |
| WEB-NATIVE-TRANSPORT W2 | WT connection wiring (web → native) | **DONE (code)** | Native signals now include WT metadata. Web's existing WtDataTransport wired to native peers. |
| NATIVE-STABILITY-CRASH-1 | Native app crash fix | **DONE** | Root cause: dangling C string pointer in FFI `bolt_signaling_start` call (W1 regression). Fixed with nested `withCString` scoping. |

### Remaining Streams (Execution Order)

| # | Stream | Description | Repos | Blocks | Definition of Done |
|---|--------|-------------|-------|--------|--------------------|
| 1 | **W2-RUNTIME-VALIDATION-1** | Runtime-validate HTTPS browser ↔ native via WebTransport | localbolt-v3, localbolt-app | W3 | Chrome on HTTPS origin establishes WT session with native daemon. Session-connected + SAS verification confirmed. File transfer at least attempted. |
| 2 | **M4-PARITY-1** | Cross-product contract parity tests | bolt-core-sdk, localbolt-v3, localbolt-app | NONCORE-ADOPTER-1 | Both products export transition tables. CI validates both against contract validators. Any divergence is a test failure. |
| 3 | **ECOSYSTEM-DOCS-1** | Integration docs for external apps | bolt-core-sdk | NONCORE-ADOPTER-1 | `docs/INTEGRATION_GUIDE.md` in bolt-core-sdk: how to consume the session contract, implement a transport adapter, register with signaling. Covers Rust + TS paths. |
| 4 | **NONCORE-ADOPTER-1** | First non-core consumer adopts the contract | TBD (candidate: localbolt Lite or bytebolt-app) | Program exit | External consumer implements canonical 5 session phases, passes parity test against contract validators. |
| 5 | **SIDECHANNEL-REDUCTION-1** | Reduce product-specific exceptions and side channels | localbolt-app, localbolt-v3 | None (quality) | Audit product code for state managed outside canonical contract. Document remaining exceptions. Reduce where practical without UX regression. |

Deferred (non-blocking):
- **DESKTOP-SHELL-UX-1** — Native shell UX polish. Not a contract/transport concern. Execute when product priorities allow.
- **W3-TRANSFER-1** — Full file transfer validation over WebTransport. Blocked by W2-RUNTIME-VALIDATION-1.
- **W4-FALLBACK-1** — Unsupported-browser UX for non-WT browsers connecting to native peers.

### Dependency Map

```
W2-RUNTIME-VALIDATION-1 (next)
  │
  └── M4-PARITY-1
       │
       ├── ECOSYSTEM-DOCS-1
       │    │
       │    └── NONCORE-ADOPTER-1 ──► PROGRAM EXIT
       │
       └── SIDECHANNEL-REDUCTION-1 (parallel, non-blocking)
```

### Repo/Component Ownership

| Component | Owner Repo | Authority |
|-----------|-----------|-----------|
| Session/transfer contract (types, validators, schema) | bolt-core-sdk | Canonical — Rust validators are executable authority |
| Signaling protocol (PeerData, Register, signals) | bolt-rendezvous (protocol crate) | Canonical wire format |
| WT endpoint + WS endpoint | bolt-daemon | Transport authority |
| WT metadata (cert hash, port) | bolt-daemon (generates), signaling (carries) | Daemon is source of truth |
| Web session state machine | localbolt-v3 (localbolt-core) | Conforms to contract |
| Native session state machine | localbolt-app (BoltBridge.swift) | Conforms to contract |
| Product-specific UX (animation, disconnect display) | Each product repo | Out of contract scope |

### Risks

| ID | Risk | Severity | Status |
|----|------|----------|--------|
| R18 | WT browser support gaps (Firefox, Safari) | Medium | Accepted — Chrome/Edge cover majority. W4-FALLBACK-1 addresses messaging. |
| R19 | WT cert rotation on long-running daemon | Low | Mitigated — daemon generates fresh cert on each start. New hash distributed via signaling. |
| R20 | No non-core consumer exists yet to validate contract portability | Medium | Open — NONCORE-ADOPTER-1 is the resolution. |
| R21 | Native automated test coverage limited (Swift, no unit test infra) | Medium | Accepted — contract conformance verified by code review + runtime testing. M4 will add CI-level parity checks. |
| R22 | TRANSPORT_CONTRACT.md falsely claimed QUIC as production app↔app path | Medium | **Closed** | Corrected 2026-05-10: WS client mode documented as current production, QUIC as RC3 strategic target. APP-TO-APP-QUIC-MIGRATION-1 codified. |
