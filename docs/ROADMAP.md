# Bolt Ecosystem — Roadmap

> **Status:** Normative
> **Last Updated:** 2026-02-25 (post-merge-train)
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
- [ ] localbolt-v3 consumes bolt-rendezvous as a dependency
- [ ] `packages/localbolt-signal/` removed or reduced to thin wrapper
- [ ] bolt-rendezvous owns all trust-boundary enforcement, rate limiting, room lifecycle
- [ ] All signal server tests live in bolt-rendezvous

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
```
