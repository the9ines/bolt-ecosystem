> **ARCHIVED** — historical artifact, not active governance. Moved to docs/archive/ during DOC-GOV-1 (2026-02-26).

S2 EXECUTION PROMPT — Transfer Performance Program (Policy Core + WASM Consumption Path)

You are operating inside the Bolt Protocol ecosystem.

This phase is NOT feature development.
This phase is performance + correctness infrastructure work with strict scope control.

Authoritative execution spine:
- H0–H6: DONE-MERGED
- S0: DONE-MERGED
- S1: DONE-MERGED
- You are now executing: S2 (NOT-STARTED -> IN-PROGRESS)

Primary objective (S2):
Create a Rust "transfer policy core" that can be consumed by the existing TypeScript transfer runtime (bolt-transport-web / WebRTCService) via a future WASM build. This is GREENFIELD policy infrastructure: bolt-core-sdk Rust does not currently contain transfer runtime or chunk scheduling. Do not imply otherwise.

Hard constraints (non-negotiable):
- Scope: bolt-core-sdk is primary. TypeScript changes are allowed ONLY to add a minimal adapter harness (no behavior change by default).
- Do NOT touch localbolt, localbolt-app, localbolt-v3, bolt-rendezvous, bolt-protocol.
- Do NOT change protocol wire format. No new message types. No changes to encryption, handshake, SAS, or error codes.
- Do NOT add networking, WebRTC IO, transport-layer logic, or device detection logic in Rust.
- No default behavior changes. Any integration must be opt-in behind an explicit flag and default OFF.
- Fail-closed: if the "policy core + WASM consumption" path is not viable, STOP and report.

Prerequisites to verify (Stop 0):
A) Tag verification (origin):
- bolt-core-sdk: sdk-v0.5.4-s1-conformance-harness (cced058)
- bolt-daemon: daemon-v0.2.10-h3-h6-mainline (0b16392)

B) Preflight gates (bolt-core-sdk on main, clean tree):
- cargo fmt --check
- cargo clippy -- -D warnings
- cargo test
- cargo test --features vectors
- npm test
- npm run build
- npm run typecheck

C) Architecture viability check (CRITICAL):

You must explicitly verify whether any Rust→WASM infrastructure already exists in bolt-core-sdk or related TS packages.

Concrete artifacts to look for:

Rust side:
- `crate-type = ["cdylib"]` in rust/bolt-core/Cargo.toml
- `wasm-bindgen` dependency in Cargo.toml
- `wasm-pack` configuration or related scripts
- Any existing `#[wasm_bindgen]` usage
- Any build target for `wasm32-unknown-unknown`

TypeScript side:
- Any `.wasm` imports
- Any wasm loader configuration
- Any build scripts referencing wasm-pack or wasm artifacts
- Any existing Rust artifact consumed from TS

Decision rule:

- If NONE of the above artifacts exist:
  - Report explicitly: "No WASM infrastructure present."
  - Proceed with Stops 1–2 only (policy core + contract tests).
  - Stop 3 becomes NO-OP.
  - Do NOT introduce wasm tooling in this run.

- If minimal infrastructure exists and integration is trivial:
  - Document what exists.
  - Proceed carefully with a minimal, opt-in harness only.

If adding WASM plumbing would require new build systems, cross-package changes, or non-trivial tooling work: STOP and propose S2A (policy core) / S2B (WASM integration) split before proceeding.

If any preflight fails: STOP and report exact failure output.

------------------------------------------------------------------------------

Decision draft (B-minimal interface, adjustable with STOP):

This is a draft interface intended to be WASM-friendly and callable from TS later. If during implementation these shapes are misaligned with existing bolt-core-sdk architecture, STOP before tagging and propose the smallest adjustment.

Types (greenfield, minimal, no transfer runtime implied):
- ChunkId: u32 (opaque identifier, caller-owned)
- LinkStats:
  - rtt_ms: u32
  - loss_ppm: u32
  - in_flight_bytes: u32
- DeviceClass:
  - desktop | mobile | low_power | unknown

  Note:
  DeviceClass is a performance-tier classification independent of
  bolt-rendezvous-protocol's DeviceType (Phone | Tablet | Laptop | Desktop).
  The TypeScript caller is responsible for mapping any existing DeviceType
  (or other runtime signal) into DeviceClass.
  Rust does not derive or inspect device type.

- TransferConstraints:
  - max_parallel_chunks: u16
  - max_in_flight_bytes: u32
  - priority: u8
  - fairness_mode: enum (e.g., balanced | throughput | latency)

ScheduleDecision:
- next_chunk_ids: Vec<ChunkId>
- pacing_delay_ms: u32
- window_suggestion_chunks: u16
- backpressure: Pause | Resume | NoChange

Invariants:
- Deterministic for identical inputs.
- Pure policy: no IO, no clocks, no global state.
- Default policy may be a stub, but must satisfy all contracts.

------------------------------------------------------------------------------

STOP 1 — Add Policy Core Skeleton (bolt-core-sdk)

Goal:
Add the minimal policy module and types with a deterministic stub implementation. No integration into TS runtime paths in this stop.

Required work:
- Add a new Rust module under rust/bolt-core/src/transfer_policy/
  - mod.rs
  - types.rs
  - policy.rs
- Canonical entrypoint:
  fn decide(input: PolicyInput) -> ScheduleDecision
- Provide a deterministic stub (example allowed):
  - returns empty next_chunk_ids
  - pacing_delay_ms = 0
  - window_suggestion_chunks = 0
  - backpressure = NoChange

Rules:
- Export only what's necessary.
- No callers wired yet.

Gates:
- cargo fmt --check
- cargo clippy -- -D warnings
- cargo test
- cargo test --features vectors

Commit + Tag:
- One commit: "S2 policy core skeleton (greenfield), no behavior change"
- Tag: sdk-v0.5.X-s2-policy-skeleton (next available X; forward-only)

Report Stop 1 output:
- Files changed (full paths)
- New exported symbols
- Test counts before/after (default + vectors)
- Commit SHA and tag

------------------------------------------------------------------------------

STOP 2 — Contract Tests (Determinism + Bounds)

Goal:
Validate CONTRACTS, not scheduling quality. The stub policy is acceptable if it satisfies the contracts.

Required tests:
- Determinism:
  - same inputs -> identical decision (including ordering)
- Bounds:
  - next_chunk_ids.len() <= max_parallel_chunks
  - sum(chunk_sizes) is NOT testable here (no runtime); instead enforce:
    - window_suggestion_chunks <= max_parallel_chunks
    - if in_flight_bytes > max_in_flight_bytes then backpressure must be Pause OR NoChange (choose one contract and document)
- Sanity:
  - pacing_delay_ms within a documented max constant

No property-test dependency additions unless already present.

Gates:
- cargo fmt --check
- cargo clippy -- -D warnings
- cargo test
- cargo test --features vectors

Commit + Tag:
- One commit: "S2 policy core contract tests"
- Tag: sdk-v0.5.X-s2-policy-contract-tests (next available X)

Report Stop 2 output:
- Tests added (names + intent)
- Test totals before/after
- Commit SHA and tag

------------------------------------------------------------------------------

STOP 3 — TS Adapter Harness (only if minimal and no behavior change)

Goal:
Only if necessary to prove future consumption viability, add a MINIMAL TS harness that can call a placeholder interface (no wasm yet), or prepare a call site behind a feature flag default OFF.
If this requires real wasm tooling changes, STOP (out of scope).

Rules:
- No production behavior changes by default.
- No new transfer logic.

Gates:
- npm test
- npm run build
- npm run typecheck

Commit + Tag (if TS touched):
- transport-web-v0.6.X-s2-policy-harness (or the repo's correct tag scheme; forward-only)

Report Stop 3:
- Why it was needed
- Exact flag name + default
- Proof no default behavior change

------------------------------------------------------------------------------

STOP 4 — Governance Updates (bolt-ecosystem/docs filesystem-only)

Update:
- docs/STATE.md:
  - S2 -> IN-PROGRESS
  - Record tags + SHAs
  - Explicit note: "Policy core is greenfield; transfer runtime remains TS; WASM consumption planned."
- ROADMAP.md:
  - S2 remains NEXT active execution phase
  - Clarify S2A (policy core + contract tests) vs S2B (integration + measurement) if needed

Output:
- Diff-style summary per file
- Updated S2 sections verbatim
- Consistency checklist (tags/SHAs/status)

------------------------------------------------------------------------------

Final Deliverable

AAR with Stop 0–4:
- Tag + SHA evidence
- Test totals (default + vectors + TS)
- Explicit statement: "No runtime integration in this run unless Stop 3 executed; default behavior unchanged."
- Remaining S2 work to reach DONE-MERGED:
  - WASM build/plumbing (if not already present)
  - TS runtime opt-in integration
  - Measurement harness + baselines
  - Rollback proof (flag OFF)

If any STOP triggers:
- Stop immediately and report minimal fix.
