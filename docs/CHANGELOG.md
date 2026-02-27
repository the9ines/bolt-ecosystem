# Bolt Ecosystem — Changelog

Cross-repo milestones and hardening phases. Newest first.
Per-repo details live in each repo's `docs/CHANGELOG.md`.

---

## PROTO-HARDEN-1 — Handshake Invariants Codified in Spec (2026-02-26)

Formalized five categories of handshake security properties as normative
spec text in PROTOCOL.md §15. Twelve numbered invariants (PROTO-HARDEN-01
through PROTO-HARDEN-12) make previously implicit guarantees explicit and
auditable.

**Categories:**
- §15.1 Ephemeral-first keying model — identity keys delivered only inside encrypted HELLO
- §15.2 Identity-ephemeral cryptographic binding — envelope MAC + SAS
- §15.3 Error registry invariants — single canonical registry, cross-impl parity
- §15.4 Post-handshake envelope requirement — no plaintext errors in normal operation
- §15.5 HELLO state machine — no reentrancy, exactly-once, immutable capabilities

**Deliverables:**
- **bolt-protocol** (`ee024d7`, `v0.1.2-spec`): PROTOCOL.md §15 added (+149 lines).
  docs/CONFORMANCE.md updated with 6 new rows (Status=TODO pending implementation audit).
- **bolt-ecosystem**: STATE.md, CHANGELOG.md, AUDIT_TRACKER.md updated.
  12 observations (O1–O12) mapped to PROTO-HARDEN invariants.

**No runtime code changed. No wire format changed. Governance only.**

---

## CONFORMANCE-2R — Enforceable Conformance Matrix with Minimum Coverage (2026-02-26)

Expanded conformance matrix with Evidence column, minimum coverage enforcement,
and CI validation. Converts IMPLEMENTED/PARTIAL assertions into demonstrated
traceability via concrete test file paths.

- **bolt-protocol**: docs/CONFORMANCE.md expanded — Evidence column added to both
  tables, 12/13 PROTOCOL rows and 12/13 PROFILE rows now have evidence links.
  Coverage Requirements section documents N=10 (protocol) and N=5 (profile)
  thresholds. Status migration: NOT REVIEWED → TODO (2 rows).
  .github/workflows/ci-conformance.yml updated — new inline coverage validation
  step parses Evidence column and enforces minimum counts.
- **bolt-ecosystem**: DOC_ROUTING.md updated with CONFORMANCE-2R note.
  STATE.md and CHANGELOG.md updated.
- **No runtime code changed. No dependencies added. No new script files created.**

---

## CONFORMANCE-1R — Spec Conformance Matrix + PR Review Gate (2026-02-26)

Introduced spec-to-implementation conformance matrix and CI review discipline
gate. Any PR to bolt-protocol that modifies PROTOCOL.md or LOCALBOLT_PROFILE.md
must also update docs/CONFORMANCE.md, or CI fails.

- **bolt-protocol** (`69a0907`): docs/CONFORMANCE.md (new) — maps all top-level
  spec sections to bolt-core-sdk and bolt-daemon implementation locations.
  .github/workflows/ci-conformance.yml (new) — PR gate using git merge-base diff.
  README.md updated with conformance link.
- **bolt-ecosystem**: DOC_ROUTING.md updated with CONFORMANCE.md entry.
  STATE.md and CHANGELOG.md updated.
- **No runtime code changed. No existing CI workflows modified. No dependencies added.**

---

## P1 — Inbound Error Validation Hardening (2026-02-26)

Daemon-side strict validation of inbound `{type:"error"}` messages.
Unknown/malformed error codes from remote peers are now treated as
`PROTOCOL_VIOLATION` + disconnect instead of `UNKNOWN_MESSAGE_TYPE`.
Single validator helper (`validate_inbound_error`), canonical registry
(`CANONICAL_ERROR_CODES`, 8 codes from Appendix A). No envelope decode
logic changed.

- **bolt-daemon** (`daemon-v0.2.12-p1-inbound-error-validation`, `8c45819`):
  +5 tests. Daemon total: 276 (up from 271).

---

## S2B — Transfer Instrumentation (2026-02-26)

Observability-only instrumentation of the TypeScript transfer path.
Structured metrics for chunk pacing, buffer pressure, and passive stall detection.
No behavior change. Zero overhead when disabled (default OFF).

- **bolt-core-sdk / transport-web** (`transport-web-v0.6.1-s2b-instrumentation`, `02e36b1`):
  New `transferMetrics` module: RingBuffer, TransferMetricsCollector, summarizeTransfer.
  Passive stall detection (retroactive, no timers).
  Feature-gated via `ENABLE_TRANSFER_METRICS` (default false).
  +24 tests. Transport-web total: 156 (up from 132).

---

## S2A — Transfer Policy Core (2026-02-26)

Greenfield Rust policy core for transfer scheduling. No behavior change; no callers wired; WASM consumption planned for S2B.

- **bolt-core-sdk** (`sdk-v0.5.5-s2-policy-skeleton`, `31bdc0b`):
  New `transfer_policy/` module — types (ChunkId, LinkStats, DeviceClass, TransferConstraints, FairnessMode, PolicyInput, Backpressure, ScheduleDecision, MAX_PACING_DELAY_MS) and deterministic `decide()` stub. 4 inline unit tests.
- **bolt-core-sdk** (`sdk-v0.5.6-s2-policy-contract-tests`, `39ed6dc`):
  15 integration contract tests in `tests/s2_policy_contracts.rs`. Validates determinism (identical inputs, ordering, across device classes/fairness modes), bounds (chunk count, window, pacing delay, edge cases), backpressure (over budget, exact boundary), and sanity contracts.
- **Test delta:** Rust default 66→85 (+19), vectors 96→115 (+19). No regressions. TS tests unchanged (97 + 132).
- **S2 status:** NOT-STARTED → IN-PROGRESS
- **WASM infra:** None present. Stop 3 (TS adapter) was NO-OP. S2B will address.

---

## Governance Sync — Roadmap Canonicalization (2026-02-26)

- Declared H/S spine as authoritative execution model
- Reclassified Phase 1/2/3 as legacy strategic roadmap
- Quarantined Cross-Repo Dependency Map + Release Sequencing as legacy strategic context
- Renamed S1 to "Core Protocol Conformance Harness (Rust SDK)" — scoped to bolt-core-sdk only
- S2 status corrected to NOT-STARTED
- Updated bolt-rendezvous/docs/STATE.md to match S0 truth (tag, commit, test counts, phase status)
- No code changes

---

## S0 — Canonical Hardened Rendezvous (2026-02-26)

Eliminated signaling authority drift. localbolt-v3 `packages/localbolt-signal/` now consumes bolt-rendezvous as a cargo git dependency. No independent protocol handling remains on the runtime path.

- **bolt-rendezvous** (`rendezvous-v0.2.2-s0-canonical-lib-verified`, `fd8d3df`):
  Promoted trust-boundary API to pub for library consumption. These pub items
  exist solely so the wrapper and tests reuse identical validation/rate-limit
  logic without reimplementation — not a public SDK-like API, only internal
  server policy exposure. 49 tests pass.

- **localbolt-v3** (`v3.0.63-s0-canonical-rendezvous`, `2963539`):
  Replaced local protocol.rs/server.rs/room.rs with canonical bolt-rendezvous wrapper.
  36 Rust tests (up from 32). Wire-format parity verified. LAN-only preserved.
  Dockerfile updated: git in builder stage for cargo git dep fetch.
  Dockerfile dev-dep stripping documented inline (awk workaround for sibling-path
  dev-deps unavailable in Docker build context).

- **Wire-format parity evidence:**
  8 fixture-based tests in `packages/localbolt-signal/src/lib.rs::tests` exercise
  canonical `bolt-rendezvous-protocol` types through the wrapper: `wire_deserialize_register`,
  `wire_deserialize_signal`, `wire_deserialize_ping`, `wire_serialize_peers`,
  `wire_serialize_peer_joined`, `wire_serialize_peer_left`, `wire_serialize_signal_relay`,
  `wire_serialize_error`. These use the same JSON shapes as bolt-rendezvous-protocol's
  16 golden snapshot tests (`protocol/src/lib.rs::tests::wire_*`). Since localbolt-signal
  now imports canonical types directly (no local reimplementation), parity is structural —
  both sides use identical serde types, eliminating drift by construction.

- **Git dependency resolution verified:**
  Tag `rendezvous-v0.2.2-s0-canonical-lib-verified` confirmed on origin (`fd8d3df7...`).
  `Cargo.lock` pins both `bolt-rendezvous` and `bolt-rendezvous-protocol` to exact commit
  `fd8d3df7196b25bfeb25d99868c0525c4a75f917`. Fly builds will resolve deterministically.

- **LAN smoke test:** Bound `0.0.0.0:3098`, connected via LAN IP `192.168.4.210`.
  Peer discovery, peer_joined, signal relay, clean disconnect all verified.

---

## Governance Sync — Post-Merge-Train Consolidation (2026-02-25)

Governance sync after merge train completion. Eliminated stale artifacts in PROTOCOL_ENFORCEMENT.md (Appendix B/C), verified H-series ledger accuracy, enriched S-series definitions in ROADMAP.md.

Mainline tags at time of sync:
- `v3.0.62-h1-mainline-merge` (localbolt-v3, `7571d35`)
- `sdk-v0.5.3-h2-h3-mainline` (bolt-core-sdk, `3f66da9`)
- `daemon-v0.2.10-h3-h6-mainline` (bolt-daemon, `0b16392`)
- `rendezvous-v0.2.1-h6-ci-enforcement` (bolt-rendezvous, `6f48ba7`)

---

## Mainline Convergence — Merge Train Complete (2026-02-25)

All H-phase work merged to main across all repos. Feature branches preserved.

- **localbolt-v3** (STOP 1): H1 signal hardening merged → `v3.0.62-h1-mainline-merge` (`7571d35`)
  - Docs: `v3.0.62-h1-mainline-merge-docs` (`a0c9dc8`)
  - Gates: 26 TS tests, 32 Rust tests, build, typecheck, fmt, clippy
- **bolt-core-sdk** (STOP 2): H2 + H3 merged → `sdk-v0.5.3-h2-h3-mainline` (`3f66da9`)
  - H3 test files received cargo fmt fixup (pre-H6 formatting)
  - Gates: 97 TS bolt-core, 132 TS transport-web, 69 Rust tests, audit-exports, check-vectors
- **bolt-daemon** (STOP 3): H3/H4/H3.1/H5/H6 stack merged → `daemon-v0.2.10-h3-h6-mainline` (`0b16392`)
  - Gates: 212 default tests, 267 test-support tests, fmt, clippy, no-panic check
- **bolt-rendezvous** (STOP 4): Verified — H6 tag already at HEAD, no action needed
- **Governance** (STOP 5): STATE.md + ROADMAP.md + CHANGELOG.md updated

Risk register: R1 (feature branch divergence), R2 (daemon panics), R7 (hermeticity), R8 (merge conflicts), R9 (no TOFU/SAS) all CLOSED.

---

## H6 — CI Enforcement Across Repos (2026-02-25)

Hardened CI gates across all four active repos. Gap-fill phase — no
greenfield CI creation, no protocol changes, no crypto changes.

- **bolt-core-sdk** (`sdk-v0.5.2-h6-ci-enforcement`, `476881a`):
  CI step reorder (vector drift check before tests), nonce uniqueness
  sanity tests (TS: 3 tests in `nonce-uniqueness.test.ts`, Rust: 1 test
  `nonce_uniqueness_sanity` in `crypto.rs`), `.nvmrc` added (Node 20).
  TS: 79 tests. Rust: 55 default, 60 with vectors.

- **bolt-daemon** (`daemon-v0.2.9-h6-ci-enforcement`, `398a63d`):
  Clippy upgraded from `-W clippy::all` to `-D warnings`. Added
  `cargo test --features test-support` (267 tests) and
  `scripts/check_no_panic.sh` to CI workflow. Branch:
  `feature/h5-downgrade-validation` (CI triggers on main only;
  local gates authoritative for tag).

- **bolt-rendezvous** (`rendezvous-v0.2.1-h6-ci-enforcement`, `6f48ba7`):
  Clippy upgraded from `-W clippy::all` to `-D warnings`. 49 tests pass.

- **localbolt-v3** (`v3.0.60-h6-ci-enforcement`, `3b12f73`):
  Audit-only — all gates already present (clippy -D warnings, coverage
  thresholds, transport drift guards). No code changes. 4 TS + 11 Rust tests.

Coverage enforcement: localbolt-v3 only (vitest v8 thresholds). All other
repos: deferred — no existing tooling. Risk R3 (no CI gate for vector
drift) closed.

---

## Docs Sync — H-Phase Ledger + Merge Train (2026-02-25)

Documentation-only update. No code, tag, or branch changes.

- **STATE.md**: Truthful ledger with `{DONE-MERGED, DONE-NOT-MERGED, IN-PROGRESS, NOT-STARTED}` status per H-phase. Fixed H2 branch name (`feature/h2-webrtc-enforcement`). Added H3.1 hermeticity blocker. Redefined H5 (TOFU/SAS wiring) and H6 (CI enforcement). Added merge train with per-step gates, remaining findings, and post-H6 roadmap.
- **ROADMAP.md**: Added truthful ledger and merge train with gates. Redefined H5 and H6. Noted old H5 scope absorption into H3/INTEROP. Added H3.1 as daemon merge prerequisite. Updated risk register and dependency map.
- **CHANGELOG.md**: Added H3.1 known-issue note. Added this entry.
- **PROTOCOL_ENFORCEMENT.md**: Added Appendix C (per-invariant adoption status across TS SDK and Rust daemon, with on-main column).

---

## H3 — Cross-Implementation Golden Vectors (2026-02-25)

Shared deterministic test vectors for SAS, HELLO-open, and envelope-open
operations. Eliminates cross-implementation drift between TS SDK, Rust SDK,
and bolt-daemon. Vector files generated by deterministic script with fixed
keypairs and nonces. Open-only testing (nonces are random in production).

- **bolt-core-sdk**: Generator (`generate-h3-vectors.mjs` with `--check` mode),
  3 vector files (SAS, HELLO-open, envelope-open), TS tests (94 total),
  Rust tests (68 total with `--features vectors`).
- **bolt-daemon**: HELLO-open and envelope-open vector integration tests
  (215+ total with `--features test-support`). Feature-gated `test-support`
  to avoid exposing test internals in production.
- **Tags**: `sdk-v0.5.1` (`9d8617d`), `daemon-v0.2.5-h3-golden-vectors` (`3751118`)
- **Branch**: `feature/h3-golden-vectors` (SDK + daemon). Not merged to main.

**Known issue (H3.1):** bolt-daemon `tests/h3_golden_vectors.rs` references
sibling repo paths (`../bolt-core-sdk/...`). Tests require bolt-core-sdk to
exist at a specific relative filesystem path, violating hermeticity. Tracked
as H3.1 — must be resolved before daemon H3 merges to main. See merge train
in `docs/ROADMAP.md` step 4.

## H2 — WebRTC Enforcement Compliance (2026-02-25)

Implement exactly-once HELLO, envelope-required binary enforcement, and
fail-closed semantics in WebRTCService per `PROTOCOL_ENFORCEMENT.md`.

- **bolt-core-sdk**: 21 enforcement tests covering exactly-once HELLO,
  envelope-required rejection, fail-closed per error code, downgrade resistance.
  transport-web total: 138 tests.
- **Tag**: `sdk-v0.5.0-h2-webrtc-enforcement` (`b4ce544`)
- **Branch**: `feature/h2-webrtc-enforcement`. Not merged to main.

## H1 — Signal Server Trust-Boundary Hardening (2026-02-25)

Port bolt-rendezvous-grade trust boundary enforcement into localbolt-v3
signal server. Rate limiting, message size caps, device name validation,
peer code length enforcement.

- **localbolt-v3**: `packages/localbolt-signal/src/server.rs` (+449/-26 lines).
- **Tag**: `v3.0.59-signal-hardening` (`ac5110c`)
- **Branch**: `feature/h1-signal-hardening`. Not merged to main.

## H0 — Protocol Enforcement Posture (2026-02-25)

Normative document defining runtime invariants and failure posture for all
Bolt Protocol implementations. Covers exactly-once HELLO, envelope-required
mode, fail-closed semantics, downgrade resistance, error frame requirements,
disconnect semantics, legacy mode boundary, and conformance test requirements.

- **bolt-ecosystem**: `docs/PROTOCOL_ENFORCEMENT.md` created.
- **Appendix A**: 14-code error registry.
- **Appendix B**: H-phase delivery record and implementation status.
- **Appendix C**: Per-invariant adoption status (added 2026-02-25 docs sync).
- Filesystem only (ecosystem root is not a git repo).

---

## Interop Milestones (bolt-daemon)

### INTEROP-4 — Minimal Post-HELLO Message Set (2026-02-25)

Prove session + envelope path works E2E with real messages: ping/pong
heartbeat and app_message echo. All sends through `encode_envelope`.

- **Tag**: `daemon-v0.2.4-interop-4-min-msgset` (`d7a79c4`)
- **Status**: Merged to main.
- **Tests**: 210 total.

### INTEROP-3 — Session Context + Profile Envelope v1 (2026-02-25)

Persist HELLO outcome in SessionContext, implement Profile Envelope v1
encrypt/decrypt for DataChannel, post-HELLO recv loop, no-downgrade enforcement.

- **Tag**: `daemon-v0.2.3-interop-3-session-envelope` (`a39fefc`)
- **Status**: Merged to main.
- **Tests**: 201 total.

### INTEROP-2 — Web HELLO Handshake (2026-02-25)

NaCl-box encrypted JSON HELLO exchange over DataChannel matching
bolt-transport-web wire format. Capability negotiation. Exactly-once guard.

- **Tag**: `daemon-v0.2.2-interop-2-web-hello` (`dd82669`)
- **Status**: Merged to main.
- **Tests**: 181 total.

### INTEROP-1 — Web Signaling Payloads (2026-02-25)

Web-compatible `{type, data, from, to}` inner signaling schema.

- **Tag**: `daemon-v0.2.1-interop-1-web-signal-payload` (`14c7448`)
- **Status**: Merged to main.
- **Tests**: 157 total.
