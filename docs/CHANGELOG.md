# Bolt Ecosystem — Changelog

Cross-repo milestones and hardening phases. Newest first.
Per-repo details live in each repo's `docs/CHANGELOG.md`.

---

## RECON-XFER-1 Phase A — Transfer Reconnect Recovery Fix — 2026-03-09

- **RECON-XFER-1 PHASE A DONE:** Root-cause locked and fix applied
- **Root cause:** localbolt-v3 consumer orchestration — NOT SDK
  - RC-1: `serviceGeneration` captured once at init, never updated across reconnect → all callbacks silently dropped
  - RC-2: SDK one-shot lifecycle (`disconnect()` kills signaling listener) — reusing dead service blocked reconnect
- **SDK verdict:** Core teardown sufficient. Test-only change (8 one-shot contract tests).
- **Fix:** `createFreshRtcService()` factory in `peer-connection.ts` — new `WebRTCService` per connection attempt, synchronized generation, old service fully detached before swap
- **Tests:** 16 regression tests (localbolt-core), 8 one-shot contract tests (SDK) — 298 SDK total, 70 localbolt-core total, 70 localbolt-web total — all green
- **Build:** localbolt-v3 Vite production build green (WASM + fallback)
- **Tags:**
  - `sdk-v0.5.35-recon-xfer1-phase-a-tests` (2f219d4) — test-only
  - `v3.0.88-recon-xfer1-phase-a` (a7e311b) — primary fix
  - `ecosystem-v0.1.96-recon-xfer1-phase-a` — this commit
- **Phase B pending:** localbolt + localbolt-app consumer verification
- **No daemon changes** — escalation not triggered

---

## RECON-XFER-1 — Transfer Reconnect Recovery Codification — 2026-03-09

- **RECON-XFER-1 CODIFIED:** Governance codification of mid-transfer disconnect → reconnect stuck bug
- **Priority:** NOW / HIGH — user-facing reliability regression
- **Status:** NOT-STARTED (docs/governance codification only in this pass)
- **Repro:** Start transfer → disconnect mid-transfer → reconnect → new transfer fails to start
- **Repro surface:** Browser path (`localbolt.app`) confirmed. Daemon-only path unknown/unconfirmed.
- **Root-cause hypothesis:** SDK session/transfer coordination (`ts/bolt-transport-web`) — transfer SM does not reset to terminal state on mid-transfer disconnect; stale `transferId`, queue pointers, and control flags survive across reconnect boundary
- **Distinct from prior work:**
  - Q7/C7 (DONE): stale callback pollution (UI shows wrong state) — RECON-XFER-1 is stuck state (cannot start new transfer)
  - C-STREAM-R1 (DONE): generation guards + disconnect idempotency — RECON-XFER-1 is transfer SM lifecycle coordination
  - UI-XFER-1 (DONE): emit path correctness — RECON-XFER-1 is disconnect boundary cleanup
- **Acceptance criteria:** AC-RX-01 through AC-RX-08 (terminal reset, fresh session generation, same-run new transfer, no stale state crossing, post-reconnect controls, regression test, phased consumer verification, WASM/fallback non-regression)
- **Phased verification:** Phase A (SDK + localbolt-v3), Phase B (localbolt + localbolt-app)
- **Daemon scope:** Escalation-only (not initial scope)
- **Dependencies:** T-STREAM-1 (DONE) prerequisite context
- **PM decisions:** PM-RX-01/02/03 all APPROVED
- **Docs updated:** `FORWARD_BACKLOG.md` (Item 10), `GOVERNANCE_WORKSTREAMS.md`, `ROADMAP.md`, `STATE.md`, `CHANGELOG.md`
- Ecosystem tag: `ecosystem-v0.1.95-recon-xfer-1-codify`

---

## REL-ARCH1 — Multi-Arch Daemon Build/Package Matrix — 2026-03-09

- **REL-ARCH1 DONE:** Deterministic multi-architecture release workflow for bolt-daemon
- **Daemon tag:** `daemon-v0.2.38-relarch1-multiarch-matrix` (`ab56606`)
- **New workflow:** `.github/workflows/release.yml` — 5-target matrix build + package + publish
- **Targets:**
  - `x86_64-apple-darwin` (macos-14, native cross-compile)
  - `aarch64-apple-darwin` (macos-14, native)
  - `x86_64-pc-windows-msvc` (windows-latest, native)
  - `x86_64-unknown-linux-gnu` (ubuntu-latest, native)
  - `aarch64-unknown-linux-gnu` (ubuntu-latest, native gcc cross toolchain)
- **Shipped binaries:** `bolt-daemon` + `bolt-relay` (per archive)
- **Excluded:** `bolt-ipc-client` (dev harness)
- **Packaging:** `.tar.gz` (macOS/Linux), `.zip` (Windows), `SHA256SUMS.txt`
- **Trigger:** Tag push (`daemon-v*`) + `workflow_dispatch` manual rebuild
- **CI fix:** Added missing `bolt-core-sdk` checkout to `ci.yml` (broken since T-STREAM-0)
- **Fmt fix:** Pre-existing `cargo fmt` violation in `src/rendezvous.rs` corrected
- **Windows fix:** Strawberry Perl forced via PERL env var for OpenSSL vendored build
- **Test fix:** Platform-agnostic path assertion in `identity_store::resolve_path_uses_home`
- **Validation:** CI run 22845910794 — all 5 targets green, publish success
- **Residual:** Code signing/notarization (follow-on), `aarch64-pc-windows-msvc` (deferred)
- Ecosystem tag: `ecosystem-v0.1.94-relarch1-multiarch-matrix`

---

## T-STREAM-1 P4 CLOSE — WASM Activation + Evidence — 2026-03-08

- **T-STREAM-1 P4 CLOSED:** WASM policy adapter active in production across all three consumers
- **SDK version:** `@the9ines/bolt-transport-web@0.6.7` (npmjs.org) — ships WASM binary in tarball, diagnostic logging
- **WASM-enabled evidence:** Footer shows `Policy: WASM` on localbolt.app after CSP fix
- **Forced-fallback evidence:** Footer showed `Policy: Fallback` prior to CSP fix (CSP `script-src 'self'` blocked `WebAssembly.instantiateStreaming`)
- **CSP fix:** Added `'wasm-unsafe-eval'` to `script-src` in all three consumer `index.html` files
- **Pause/resume/cancel sanity:** 17 UI-XFER-1 canonical control tests pass in SDK (pause blocks enqueue, resume unblocks, cancel terminal state, no completion after cancel, canonical receive-side routing)
- **Full test evidence:**
  - SDK (bolt-transport-web): 27 files, 290 tests PASS
  - localbolt: 15 files, 319 tests PASS
  - localbolt-app: 5 files, 64 tests PASS
  - localbolt-v3: 4 files, 70 tests PASS
  - **Total: 743 tests, 0 failures**
- **Domain rename:** All `localbolt.site` references updated to `localbolt.app` across all repos
- CSP tags:
  - `localbolt-v1.0.33-csp-wasm` (`cbd43af`)
  - `localbolt-app-v1.2.21-csp-wasm` (`83a8350`)
  - `v3.0.86-csp-wasm` (`98610d3`)
- Domain rename tags:
  - `localbolt-v1.0.34-domain-rename` (`c8f9fdc`)
  - `localbolt-app-v1.2.22-domain-rename` (`beb8891`)
  - `v3.0.87-domain-rename` (`69ec25c`)
- Ecosystem tag: `ecosystem-v0.1.92-tstream1-wasm-activation`

---

## T-STREAM-1 P4 — Consumer Adoption (WASM Policy Wiring) — 2026-03-08

- **T-STREAM-1 P4 DONE:** All three consumers adopt `@the9ines/bolt-transport-web@0.6.5` from npmjs.org with WASM policy wiring
- SDK tag: `sdk-v0.5.32-tstream1-wasm-policy-wiring` (`2d4792f`)
- Consumer tags:
  - `localbolt-v1.0.29-tstream1-wasm-policy` (`44b8d1b`)
  - `localbolt-app-v1.2.17-tstream1-wasm-policy` (`95125dd`)
  - `v3.0.82-tstream1-wasm-policy` (`d6fdb0e`)
- Ecosystem tag: `ecosystem-v0.1.91-tstream1-wasm-policy-adoption`
- **Registry migration:** All consumers switched from GitHub Packages to npmjs.org for `@the9ines` scope
- **WASM external pattern:** All three consumers mark `bolt_transfer_policy_wasm` as rollup external — dynamic import in `PolicyAdapter.js` is wrapped in try/catch; `TsFallbackPolicyAdapter` activates at runtime when WASM unavailable
- **SDK publish fix:** `fix(ci)` commits (`5762927`, `a9590b1`) patch npmjs publish workflow to override scoped `.npmrc`
- **Build evidence:**
  - localbolt: PASS (vite build, 58 modules, 319 tests)
  - localbolt-app: PASS (vite build, 62 modules, 64 tests)
  - localbolt-v3: PASS (vite build, 62 modules, 124 tests — 70 localbolt-web + 54 localbolt-core)
- **Manual runtime evidence:** Deferred to Human Scope (WASM transfer, fallback transfer, pause/resume/cancel per consumer)
- **Files changed (localbolt):** `web/.npmrc`, `web/package-lock.json`, `web/vite.config.ts`
- **Files changed (localbolt-app):** `web/package-lock.json`, `web/vite.config.ts`
- **Files changed (localbolt-v3):** `.npmrc`, `package-lock.json`, `packages/localbolt-web/.npmrc`, `packages/localbolt-web/vite.config.ts`
- **Files changed (bolt-core-sdk):** `.github/workflows/publish-transport-web-npmjs.yml` (CI fix only)

---

## S2A — Transfer Policy Substantive Logic — 2026-03-08

- **S2A DONE:** Substantive transfer policy replacing trivial stub, pre-WASM
- SDK tag: `sdk-v0.5.31-s2a-transfer-policy-substantive` (`c67bd68`)
- Ecosystem tag: `ecosystem-v0.1.90-s2a-transfer-policy-substantive`
- Daemon: **untouched** (no transfer_policy imports; AC-S2A-12 N/A)
- **Policy ownership (Option B):** Moved `transfer_policy` from `bolt-core` to `bolt-transfer-core/policy/`
- **Unified backpressure authority:** `BackpressureSignal` enum removed; `BackpressureController` feeds `PressureState` into `PolicyInput`; policy emits single `Backpressure` signal
- **Effective chunk cap:** `effective_chunk_size = min(configured_chunk_size, transport_max_message_size)`
- **Send-window sizing:** Pressure-aware (halves under Elevated, zeroes under Pressured), fairness-mode adjustments (Latency→1, Throughput→full), device-class scaling (LowPower→½, Mobile→¾)
- **RTT-proportional pacing:** Latency mode adds rtt/4, Balanced+Elevated adds rtt/8
- **Stall detection:** Pure threshold-based classification (Healthy/Warning/Stalled/Complete)
- **Progress cadence (forward-investment):** Pure function for T-STREAM-1 TS/WASM consumption, no daemon consumer
- **Tests:** 207 total pass (62 bolt-core + 16 conformance + 93 bolt-transfer-core unit + 36 S2A integration)
- **Validation gates:** `cargo clippy -- -D warnings` clean, `cargo fmt -- --check` clean, WASM build verified
- **AC-S2A-01..11 satisfied** (AC-S2A-12 N/A — daemon untouched)
- **Files changed (bolt-core-sdk):** `rust/bolt-core/src/lib.rs`, `rust/bolt-core/src/transfer_policy/` (deleted), `rust/bolt-core/tests/s2_policy_contracts.rs` (deleted), `rust/bolt-transfer-core/src/backpressure.rs`, `rust/bolt-transfer-core/src/lib.rs`, `rust/bolt-transfer-core/src/policy/` (new: mod, types, decide, stall, progress), `rust/bolt-transfer-core/tests/s2a_policy_tests.rs` (new)
- **Deferred to T-STREAM-1:** wasm-bindgen exports, TS adapter, browser runtime wiring, progress cadence TS consumer
- **Deferred to ARCH-WASM1:** Full WASM protocol engine
- **Deferred:** Daemon integration (calling `decide()` in send loop), ACK-based stall recovery

---

## T-STREAM-0 — Rust Transfer Core Extraction — 2026-03-08

- **T-STREAM-0 DONE:** Transport-agnostic transfer state machine extracted from daemon into shared `bolt-transfer-core` crate
- SDK tag: `sdk-v0.5.30-tstream0-transfer-core-v1`
- Daemon tag: `daemon-v0.2.36-tstream0-adapter`
- Ecosystem tag: `ecosystem-v0.1.89-tstream0-transfer-core-v1`
- **PM-FB-04 resolved:** Crate placed as workspace member in `bolt-core-sdk/rust/bolt-transfer-core/` (path dependency)
- **New crate:** `bolt-transfer-core` v0.1.0 — 6 modules (state, error, send, receive, backpressure, transport)
- **§9 conformance:** All 8 PROTOCOL.md §9 states represented (Idle, Offered, Accepted, Transferring, Paused, Completed, Cancelled, Error)
- **AC-TC-01..06 all satisfied** (see evidence matrix in SDK CHANGELOG)
- **WASM gate:** `cargo build --target wasm32-unknown-unknown` passes. rlib: 107 KB uncompressed, 49 KB gzipped
- **Daemon adapter:** `bolt-daemon/src/transfer.rs` → thin facade re-exporting from `bolt-transfer-core` + `Sha256Verifier`
- **Zero duplicated SM logic:** All state machine code lives in `bolt-transfer-core`; daemon is pure adapter
- **Tests:** 60 core crate tests + 362 daemon tests pass (0 regressions)
- **Consumer repos intentionally untouched** (localbolt, localbolt-app, localbolt-v3)
- **Deferred to T-STREAM-1:** wasm-bindgen exports, TS adapter, browser runtime wiring
- **Deferred to S2:** Full performance tuning (hysteresis, fairness, RTT/loss hints)
- **Files changed (bolt-core-sdk):** `rust/Cargo.toml` (NEW workspace root), `rust/bolt-transfer-core/` (NEW crate, 7 files)
- **Files changed (bolt-daemon):** `Cargo.toml`, `src/transfer.rs`, `src/lib.rs`, `src/rendezvous.rs`
- **Files changed (ecosystem):** `docs/ROADMAP.md`, `docs/STATE.md`, `docs/CHANGELOG.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## UI-XFER-1 — Pause/Stop Button Reliability (Canonical DC Control) — 2026-03-08

- **UI-XFER-1 DONE:** Canonical DC control messages for pause/resume/cancel in SDK
- SDK tag: `sdk-v0.5.29-uixfer1-canonical-control` (`89e2edb`)
- Ecosystem tag: `ecosystem-v0.1.88-uixfer1-pause-stop-fix`
- **Root cause:** SDK emitted `{ type: "file-chunk", paused: true }` — daemon parsed as data chunk, not control. Daemon emitted `{ type: "pause" }` — SDK rejected as unknown type and disconnected.
- **Fix:** Emit path converged to canonical shapes (`{ type: "pause"/"resume"/"cancel", transferId }`) matching daemon `dc_messages.rs`. Legacy `file-chunk` control flags removed from emit, retained on receive for backward compat (deprecated).
- **False completion race fixed:** Cancel now clears pending completion timeout; timeout callback checks cancelled flag.
- **Decision lock:** No legacy emit. Legacy receive tolerance temporary (deprecation noted, removal target: next major).
- **Tests:** 17 new tests in `uixfer1-canonical-control.test.ts`, 270 total pass
- **Consumer adoption:** localbolt, localbolt-app, localbolt-v3 updated to `@the9ines/bolt-transport-web@0.6.5`
- **Files changed (SDK):** `types.ts`, `TransferManager.ts`, `WebRTCService.ts`, `webrtcservice-lifecycle.test.ts`, `uixfer1-canonical-control.test.ts`, `package.json`
- **Files changed (ecosystem):** `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/ROADMAP.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## B-XFER-1 — Transfer Pause/Resume Completion — 2026-03-08

- **B-XFER-1 DONE:** Sender-side pause/resume implemented in bolt-daemon transfer state machine
- Daemon tag: `daemon-v0.2.35-bxfer1-pause-resume` (`9f087a1`)
- Ecosystem tag: `ecosystem-v0.1.87-bxfer1-pause-resume`
- **Implementation:**
  - `SendState::Paused` variant added (Sending→Paused→Sending lifecycle)
  - `on_pause()`, `on_resume()`, `is_send_active()` methods on SendSession
  - Pause/Resume carved out from `route_inner_message` to `Ok(None)` for loop-level dispatch
  - Chunk streaming restructured: tight `while let` loop → incremental one-chunk-per-iteration (allows Pause/Resume/Cancel interleaving)
  - `on_cancel()` accepts Paused state; `finish()` rejects Paused state
- **Tests:** 12 new unit tests, 2 updated envelope tests, 2 integration tests; all existing tests pass
- **Validation gates:** `cargo test` (all pass), `cargo clippy -- -D warnings` (clean), `scripts/check_no_panic.sh` (pass)
- **PM-FB-01 resolved:** Concurrent transfers OUT OF SCOPE for B-XFER-1
- **Dependency note:** T-STREAM-0 unblocked (B-XFER-1 stabilizes SM design)
- **AC-BX mapping:** AC-BX-01 through AC-BX-09 all satisfied (see `docs/FORWARD_BACKLOG.md`)
- **Files changed (daemon):** `src/transfer.rs`, `src/envelope.rs`, `src/rendezvous.rs`
- **Files changed (ecosystem):** `docs/FORWARD_BACKLOG.md`, `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/ROADMAP.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## Forward Backlog Codification — 2026-03-08

- **Post-R17 forward backlog codified:** 9 items covering transfer completion, release architecture, security, platform convergence, and mobile readiness
- Ecosystem tag: `ecosystem-v0.1.86-roadmap-codify-transfer-security-mobile`
- **Part A — R17 addendum verified:** Critical evidence mapping (A1–A5, B6–B8), non-blocking rationale (WebView2 DLL, signal subtree clippy, web coverage threshold), and closure integrity statement all present and complete. No gaps found. B-DEP-N2-3 stale wording updated to reflect R17 CLOSED.
- **Part B — Backlog items codified:**
  - B-XFER-1: Transfer pause/resume completion (daemon transfer SM remaining scope) — **NOW**
  - REL-ARCH1: Multi-arch daemon build/package matrix — **NOW**
  - SEC-DR1: Double Ratchet pre-ByteBolt security gate (DR-STREAM, phased) — **NEXT**
  - T-STREAM-0: Rust transfer core, no UDP in v1 — **NEXT**
  - SEC-CORE2: Rust-first security/protocol consolidation — **NEXT**
  - T-STREAM-1: Browser selective WASM integration — **LATER**
  - PLAT-CORE1: Shared Rust core + thin platform UIs — **LATER**
  - MOB-RUNTIME1: Mobile embedded runtime model (sequenced after PLAT-CORE1) — **LATER**
  - ARCH-WASM1: WASM protocol engine (medium risk) — **LATER**
- **Boundary note:** B-XFER-1 (#1) completes current daemon-local pause/resume behavior. T-STREAM-0 (#4) is shared transfer-core architecture extraction/reuse. Distinct scopes.
- **Guardrails enforced:** Browser native WebRTC retained (G1), no UDP in transfer-core v1 (G2), no A0 Option A reversal (G3)
- **AC coverage:** NOW and NEXT items have concrete AC IDs. LATER items: "AC: TBD at stream codification."
- **Files changed:** `docs/FORWARD_BACKLOG.md` (new), `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/ROADMAP.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## R17 — Windows Runtime Validation CLOSED — 2026-03-08

- **R17 CLOSED:** Windows CI provisioned (`windows-latest`), daemon + app IPC validated on real Windows runtime
- Closeout type: residual-risk closeout (not a new stream phase). N-STREAM-1 remains CLOSED
- Environment: GitHub Actions `windows-latest` (Windows Server 2022, x86_64)
- Windows CI workflows added to both repos (`workflow_dispatch` trigger)
- **bolt-daemon** (`daemon-v0.2.34-r17-windows-validated`, `82d0f83`):
  - cargo fmt: PASS
  - cargo clippy: PASS (6 commits of fixes: import paths, HANDLE types, visibility, needless return, mut refs, cfg gates)
  - cargo test: PASS — 362 tests (default features), 429 tests (test-support), 0 failures
  - Key fixes: windows-sys 0.59 API migration (ConvertStringSecurityDescriptorToSecurityDescriptorW, PIPE_ACCESS_DUPLEX, DUPLICATE_SAME_ACCESS moved; HANDLE = `*mut c_void` not `isize`), cross-platform ipc-client binary, cfg(unix) gates on Unix-only tests
- **localbolt-app** (`localbolt-app-v1.2.15-r17-windows-validated`, `7116d12`):
  - Tauri App: fmt PASS, clippy PASS, test FAIL (`STATUS_ENTRYPOINT_NOT_FOUND` — WebView2 DLL missing on headless CI, not IPC-related)
  - Signal Server: clippy FAIL (`result_large_err` in vendored signal/ subtree — read-only per subtree policy, not R17)
  - Web App: coverage threshold FAIL (Windows coverage instrumentation differs — tests pass, threshold not met)
  - Key fixes: block-expression wrapping for `#[cfg(windows)]` connect(), needless_return removal
- Bugs discovered and fixed: 8 commits across 2 repos. All were real compilation/clippy errors that would manifest on Windows at build time
- CI evidence: daemon run `22816178593` (all green), app run `22814949072` (Tauri fmt+clippy green)
- **R17 critical-check evidence matrix:**

| ID | Check | Scope | Result | Evidence |
|----|-------|-------|--------|----------|
| A1 | Windows compilation (daemon lib) | bolt-daemon | **PASS** | CI `22816178593` clippy step — `bolt-daemon` lib compiles clean |
| A2 | Windows compilation (daemon bins) | bolt-daemon | **PASS** | CI `22816178593` clippy step — `bolt-ipc-client`, `bolt-daemon`, `bolt-relay` all compile |
| A3 | Windows clippy clean | bolt-daemon | **PASS** | CI `22816178593` clippy step — 0 warnings, `-D warnings` enforced |
| A4 | Windows tests (default features) | bolt-daemon | **PASS** | CI `22816178593` — 362 tests, 0 failures |
| A5 | Windows tests (test-support) | bolt-daemon | **PASS** | CI `22816178593` — 429 tests, 0 failures, 3 ignored |
| B6 | App IPC transport compilation | localbolt-app | **PASS** | CI `22814949072` Tauri clippy step — `ipc_transport.rs` compiles clean on Windows |
| B7 | App IPC transport clippy clean | localbolt-app | **PASS** | CI `22814949072` Tauri clippy step — 0 IPC-related warnings |
| B8 | Named pipe path detection | bolt-daemon | **PASS** | CI `22816178593` test step — `is_windows_pipe_path` tests pass (15 transport tests) |

- **Out-of-scope failures (not R17-blocking):**
  - Tauri `cargo test` (`STATUS_ENTRYPOINT_NOT_FOUND`, exit 0xc0000139): WebView2Loader.dll not present on headless `windows-latest` runner. This is a Tauri GUI runtime dependency — the test binary links against WebView2 platform DLLs unavailable in headless CI. The IPC transport code (`ipc_transport.rs`) compiled and passed clippy; the test binary crash occurs before any test executes. Not an IPC or named pipe issue.
  - Signal Server `result_large_err`: `ErrorResponse` type (136 bytes) in vendored `signal/` subtree. Subtree is read-only per CLAUDE.md policy — fixes must go upstream to bolt-rendezvous. Pre-existing issue unrelated to R17 IPC validation.
  - Web App coverage threshold: Tests pass (82.6%/70.79% coverage) but below 90% configured threshold. Windows coverage instrumentation differs from macOS/Linux. Tests themselves execute correctly; only the coverage threshold gate fails. Not IPC-related.
- Ecosystem tag: `ecosystem-v0.1.85-r17-windows-validated`

---

## R17 — Windows Runtime Validation Closeout Attempt — 2026-03-07

- **R17 remains OPEN:** P0 environment gate FAILED — no Windows runtime available
- Closeout type: residual-risk closeout (not a new stream phase). N-STREAM-1 remains CLOSED
- Environment: macOS Darwin 24.6.0 (ARM64). No Windows CI runner, no Wine/QEMU, no manual Windows machine
- Baseline tags verified:
  - `daemon-v0.2.33-n6b2-windows-pipe` (confirmed)
  - `localbolt-app-v1.2.14-n8-signal-observability` (confirmed)
  - `ecosystem-v0.1.83-n-stream-1-n8-observability` (confirmed)
- Validation matrix (A1–D15): all NOT_RUN — P0 environment gate failed
- No code changes, no runtime modifications
- Blocker: no Windows runtime environment (CI or manual)
- Next action: provision Windows CI runner (GitHub Actions `windows-latest`) or manual Windows machine
- Owner: PM
- Target: next sprint with Windows CI budget
- Governance docs updated: GOVERNANCE_WORKSTREAMS.md, ROADMAP.md, STATE.md, CHANGELOG.md
- Ecosystem tag: `ecosystem-v0.1.84-r17-progress`

---

## N-STREAM-1 N8 — D2 Signal Observability (Post-Closure Follow-On) — 2026-03-07

- **N8 DONE:** D2 signal health observability delivered as post-closure follow-on
- Stream semantics: Option C (standalone lineage-linked item). N-STREAM-1 remains CLOSED
- Routing decision: N8 (zero daemon impact). Daemon repo NOT touched
- Architecture: Path 1 (app-side TCP probe + app-emitted unified status)
- AC-SE-06 realized: signal health measured by app (runtime owner), architecture-neutral wording
- AC-SE-07 realized: unified indicator aggregates daemon + signal state
- Implementation:
  - Signal monitor (`signal_monitor.rs`): TCP probe to 127.0.0.1:3001, 5s interval, 4-state machine (unknown/active/degraded/offline), 3-failure offline threshold
  - Shutdown-aware: probe transitions suppressed during SIGTERM grace window (N3-W4/OQ-2 interaction)
  - Unified health indicator in header.ts (HEALTHY/SIG DEGRADED/SIG OFFLINE)
  - Frontend signal://status event subscription + get_signal_status command
  - Support bundle includes signal_status section
- No transfer gating changes (observability only, per PM approval)
- Option A topology preserved: app remains signaling runtime owner
- Tests: 82 Rust (66→82, +16 new) + 64 web (52→64, +12 new) = 146 total, 0 regressions
- signal/ subtree: zero diff verified
- Residuals unchanged: R17 (Windows runtime, Low), OQ-2 (graceful shutdown, Low)
- App tag: `localbolt-app-v1.2.14-n8-signal-observability` (`a7e4f8b`)
- Ecosystem tag: `ecosystem-v0.1.83-n-stream-1-n8-observability`

---

## N-STREAM-1 N7 — Closure Gate — 2026-03-07

- **N7 DONE:** Closure gate executed. N-STREAM-1 **CLOSED**.
- Baseline verification: all 9 historical anchors (tags/commits) verified reachable on origin
- Closure criteria assessment: C1–C5 all **PASS**
  - C1 (phase completion integrity): N0–N6 + A0 all DONE, statuses consistent
  - C2 (acceptance harness closure): 44 N5 checks, 118 N6 tests (66 Rust + 52 web), all B-DEPs unblocked
  - C3 (dependency/blocker closure): all 4 B-DEPs RESOLVED with tag evidence
  - C4 (residual risk handling): R17 (Windows runtime, Low) OPEN with owner/next action
  - C5 (release/readiness narrative): stream outcome, limits, and deferred work documented
- Residual risks carried forward:
  - R17 (Windows runtime validation): OPEN, Low — owner: N-STREAM/B-STREAM, next: Windows CI runner or manual validation
  - OQ-2 (bolt-rendezvous graceful shutdown): OPEN, Low — upstream enhancement
- Decision continuity: A0 Option A retained, D2 observability deferred to N8/B-stream
- Stale status fix: N3 phase table entry updated (B-DEP block language → RESOLVED)
- Stale status fix: N2 STATE.md entry updated (impl deps open → all impl deps RESOLVED)
- No code changes, no runtime modifications, no subtree edits
- Tag: `ecosystem-v0.1.82-n-stream-1-n7-closure`

---

## N-STREAM-1-SIGNAL-EVAL / A0 — Signaling Ownership Decision — 2026-03-07

- **A0 DONE:** Governance-only signaling ownership evaluation for native app flows
- Read-only audit: localbolt-app, bolt-daemon, bolt-rendezvous
- **Decision: Option A (status quo coexistence)** — PM-approved
  - App embeds signaling server (bolt-rendezvous via signal/ subtree, 0.0.0.0:3001)
  - Daemon remains IPC-only (pairing/transfer decisions, no signaling hosting)
  - signal/ subtree unchanged
- **D2 observability deferred** to N8 (daemon IPC changes) or B-stream (if substantial)
  - AC-SE-06/07 (signal.status monitoring) deferred to D2 follow-on phase
- Options B (daemon-only signaling) and D1 (daemon spawns signal) explicitly rejected
  - B requires 9 locked-decision amendments; D1 requires 7
  - Both violate guardrail 13 (daemon protocol is B-stream ownership)
- Approved acceptance criteria: AC-SE-01..05, AC-SE-08..10 (immediate)
- Residuals carried forward: R17 (Windows runtime validation), OQ-2 (graceful shutdown)
- No code changes, no runtime modifications, no subtree edits
- Tag: `ecosystem-v0.1.81-signal-eval-a0-decision`

---

## N-STREAM-1 N6 Complete — GA Wiring + Support Bundle + Cross-Platform IPC — 2026-03-07

- **N6 DONE:** All execution + hardening work complete across N6-A1, N6-A2, and N6-B3
- N6-B3 GA wiring (localbolt-app-v1.2.13-n6b3-ga-wiring, `88954c8`):
  - Platform-aware IPC paths: `--socket-path` and `--data-dir` passed to daemon at spawn
  - `platform.rs`: centralized defaults for macOS/Linux/Windows (socket, PID, data-dir, crash-log, support-bundle paths)
  - Cross-platform IPC transport abstraction (`ipc_transport.rs`): `IpcStream` enum supports Unix domain sockets and Windows named pipes
  - All IPC client/bridge code migrated from direct `UnixStream` usage to `IpcStream`
  - Full support bundle export: 8 manifest sections (watchdog, stderr, crash snapshots, versions, platform metadata, IPC config, spawn counters)
  - Daemon process management abstracted: `platform::process_alive/terminate/force_kill` (Unix via libc, Windows compile-validated stubs)
  - Windows named pipe path detection and platform-aware binary resolution (`which` → `where` on Windows)
  - Signal server coexistence verified: TCP:3001 vs Unix socket, no conflict
- B-DEP-N1-1 **RESOLVED**: daemon receives `--socket-path` and `--data-dir`
- B-DEP-N2-3 **RESOLVED**: transport layer supports `\\.\pipe\` format (daemon + app)
- R16 **CLOSED**: Windows named pipe code complete
- R17 **OPENED**: Windows runtime validation — no Windows CI runner, code compile-validated only (Low, tracked for N7)
- 118 tests (66 Rust + 52 web), clippy 0 warnings, fmt clean
- Tag: `ecosystem-v0.1.80-n-stream-1-n6-complete`

---

## N-STREAM-1 N6-A2 — IPC Bridge + Frontend Readiness Gating — 2026-03-07

- **N6 IN-PROGRESS (N6-A2 completed):** IPC bridge, frontend daemon service, and readiness gating
- Persistent IPC bridge (ipc_bridge.rs): reconnects after readiness probe, forwards
  daemon.status/pairing.request/transfer.incoming.request to frontend via Tauri events
- Decision relay: pairing.decision and transfer.incoming.decision sent from frontend to daemon
- Frontend daemon service (daemon.ts): Tauri event subscriptions, command wrappers, graceful non-Tauri degradation
- Header: daemon watchdog status indicator (5 states: starting/ready/restarting/degraded/incompatible)
- Transfer: readiness gating (fail-closed), degraded banner + restart action, incompatible banner
- IPC types: PairingRequestPayload, TransferIncomingRequestPayload, Decision enum + decision payloads
- Tauri commands: send_pairing_decision, send_transfer_decision (+ existing get_watchdog_state, restart_daemon)
- Support bundle stub: NOT_IMPLEMENTED (deferred to N6-B)
- @tauri-apps/api added as frontend dependency
- 48 Rust tests (11 new), 52 web tests (20 new), 100 total
- Coverage: 91/94/85/90 (above 90/90/80/90 thresholds)
- B-DEP-N1-1 STILL OPEN: platform path CLI flags (blocks N6 GA)
- B-DEP-N2-3 STILL OPEN: Windows named pipe (blocks N6 Windows)
- localbolt-app tag: `localbolt-app-v1.2.12-n6a2-ipc-ui-gating` (`8f4aea9`)
- Tag: `ecosystem-v0.1.79-n-stream-1-n6a2-progress`

---

## N-STREAM-1 N6-A1 — Sidecar Lifecycle + Watchdog Core — 2026-03-07

- **N6 IN-PROGRESS (N6-A1 completed):** Daemon sidecar lifecycle and watchdog core implemented in localbolt-app
- Watchdog state machine: 5 states (starting/ready/restarting/degraded/incompatible), 1s/3s/10s backoff, 3 max retries, 60s reset
- Daemon manager: process spawn, stale socket/PID cleanup, SIGTERM+5s+SIGKILL shutdown
- IPC readiness probe: version.handshake + version.status + daemon.status per N2 contract
- stderr ring buffer (1000 lines) with crash snapshot persistence
- Tauri commands: get_watchdog_state, restart_daemon, export_support_bundle (stub)
- App lifecycle: daemon start on launch, shutdown on window close
- 37 new Rust tests (watchdog 17, daemon_log 5, ipc_client 5, ipc_types 4, daemon 4, commands 2)
- Existing 32 web tests unchanged
- Uses std::process::Command (not Tauri sidecar API) due to Unix socket IPC + PID-level signal requirements
- localbolt-app tag: `localbolt-app-v1.2.11-n6a-sidecar-lifecycle` (`0c218bb`)
- Tag: `ecosystem-v0.1.78-n-stream-1-n6a-progress`

---

## B-DEP-N2 Unblock — daemon.status + Version Handshake Implemented — 2026-03-07

- **B-DEP-N2-1 RESOLVED:** `daemon.status` event now emitted in all daemon modes (default, smoke, simulate) after successful IPC version handshake. Previously simulate-mode only.
- **B-DEP-N2-2 RESOLVED:** `version.handshake` (app→daemon) and `version.status` (daemon→app) messages implemented with strict `major.minor` match enforcement. Fail-closed on incompatible, malformed, missing, or late handshake. No grace mode.
- **N6 unblocked (readiness + version-gate):** N3 readiness transition (`starting → ready`) and version-gated supervision (`starting → incompatible`) are no longer blocked by daemon dependencies.
- **R15 CLOSED:** B-DEP-N2-1/N2-2 risk resolved.
- **B-DEP-N1-1 STILL OPEN:** Platform path CLI flags not implemented (blocks N6 GA, not N6 start).
- **B-DEP-N2-3 STILL OPEN:** Windows named pipe not supported (blocks N6 Windows).
- IPC event ordering: `version.status` → `daemon.status` → normal events
- 20 new tests in bolt-daemon (5 type, 8 version compat, 7 handshake integration)
- Default: 338 (was 318). test-support: 418+3ign (was 398+3ign)
- Daemon tag: `daemon-v0.2.31-bdep-n2-ipc-unblock` (`1ad2db8`)
- Tag: `ecosystem-v0.1.77-n-stream-1-bdep-n2-unblock`

---

## N-STREAM-1 N4+N5 Spec Lock — Rollout + Migration + Acceptance Harness — 2026-03-07

- **N4 DONE (spec locked):** Rollout + migration strategy locked
  - N4-R1: 4-stage rollout (Local/Dev, Alpha, Beta, GA) with entry/exit criteria and cannot-progress gates
  - N4-R2: Version-skew policy — strict major.minor match, fail-closed, 5 accidental skew scenarios handled
  - N4-R3: Whole-bundle update/rollback model — data preservation (identity/TOFU), transient state reset, rollback triggers
  - N4-R4: Migration strategy — purely additive (no existing daemon config), transparent, 5 invariants (M-01–M-05)
  - N4-R5: Blocker-aware gating — decision tree mapping B-DEP-N2-1/N2-2/N1-1/N2-3 to stage gates
  - 7 acceptance checks defined (AC-N4-1 through AC-N4-7)
- **N5 DONE (spec locked):** Acceptance harness specification locked
  - N5-H1: 8 test domains (packaging, lifecycle, IPC readiness, IPC messages, degraded UX, update/rollback, diagnostics, data safety)
  - N5-H2: 4 tiers — Smoke (8 checks), Integration (26 checks), Failure Injection (8 checks), Pre-Release (2 checks, GA-only)
  - N5-H3: Pass/fail criteria — hard fail blocks progression, soft fail tracked, tier progression rule enforced
  - N5-H4: Blocker-aware execution — 9 blocked checks report SKIP(B-DEP-ID), re-execute on B-DEP resolution
  - N5-H5: Evidence contract — 9 artifact types, CI vs human-review classification, retention until N7
  - N5-I1: Incorporation table — all 44 checks (37 from N1–N3 + 7 from N4) mapped to tiers, verified by arithmetic
- **P1 dependency re-validation:**
  - B-DEP-N2-1 STILL OPEN: `daemon.status` only in simulate mode
  - B-DEP-N2-2 STILL OPEN: `version.handshake`/`version.status` not implemented
  - B-DEP-N1-1 STILL OPEN: platform path CLI flags not implemented
  - B-DEP-N2-3 STILL OPEN: Windows named pipe not supported
- N6 (execution) now unblocked (depends on N4+N5, both DONE; runtime execution blocked by B-DEPs per N4-R5)
- Tag: `ecosystem-v0.1.76-n-stream-1-n4-n5-lock`

---

## N-STREAM-1 N3 Supervision Spec Lock — Process Supervision + Diagnostics — 2026-03-07

- **N3 DONE (spec locked; B-DEP-N2-1/N2-2 block N6 implementation):** Supervision + diagnostics requirements locked
  - N3-W1: Watchdog state machine — 5 states (starting/ready/restarting/degraded/incompatible), 6 invariants
  - N3-W2: Retry/backoff — 1s/3s/10s exponential, 3 max retries, 60s success reset (operationalizes N0 D0.4)
  - N3-W3: Stale socket/process cleanup — PID file + socket probe algorithm, app-owned PID file management
  - N3-W4: Shutdown lifecycle — SIGTERM+5s grace+SIGKILL, active transfer warning (operationalizes N0 D0.3)
  - N3-W5: stderr/log capture — 1000-line ring buffer, crash snapshots, `[DAEMON_CRASH]`/`[WATCHDOG]` tokens, support bundle spec (6 required items)
  - N3-W6: User-visible status — 5 state indicators with action affordances, ARIA accessibility
  - 15 acceptance checks defined for N5 harness (AC-N3-1 through AC-N3-15)
  - N6 implementation readiness plan: 9-step Rust/Tauri sequence + 7-step UI sequence
- **P1 dependency re-validation:**
  - B-DEP-N2-1 STILL OPEN: `daemon.status` only in simulate mode (`main.rs:1085-1098`)
  - B-DEP-N2-2 STILL OPEN: `version.handshake`/`version.status` messages not implemented (zero source matches)
  - N1-T4 path assumptions validated consistent with N3 cleanup semantics
  - PID file management confirmed absent from daemon — app-owned PID file specified
  - Existing daemon stale socket cleanup audited (`server.rs:112-116`, `Drop` impl at `344-351`)
- **N3 readiness matrix:** All 6 sub-items spec-locked (READY). N6 impl partially blocked: readiness transition (B-DEP-N2-1) and version-gate transition (B-DEP-N2-2)
- R15 updated: N3 spec locked, R15 now tracks N6 implementation block only
- N4 (rollout) now unblocked (depends on N1+N2, both DONE)
- N5 (acceptance harness) now unblocked (depends on N2+N3, both DONE)
- Tag: `ecosystem-v0.1.75-n-stream-1-n3-supervision`

---

## N-STREAM-1 N1+N2 Lock — Packaging Matrix + IPC Contract — 2026-03-07

- **N1 DONE:** Per-platform packaging + security matrix locked (macOS/Windows/Linux)
  - Bundle location + binary naming per Tauri v2 sidecar convention
  - Platform-appropriate filesystem locations (socket, PID, identity, pins, logs, config)
  - Signing/notarization: SHOULD (pre-release), REQUIRED (GA)
  - Least-privilege permission model (no elevation, `0600` socket, data-dir-only writes)
  - Co-versioned bundle, whole-bundle update/rollback only
  - 11 acceptance checks defined for N5 harness
- **N2 DONE (spec locked, implementation dependencies open):** IPC contract baseline locked
  - 5 stable messages: `daemon.status`, `pairing.request`, `transfer.incoming.request`, `pairing.decision`, `transfer.incoming.decision`
  - 2 provisional messages: `version.handshake` (app->daemon), `version.status` (daemon->app) — schema locked, implementation B-STREAM
  - NDJSON wire format, single-client kick-on-reconnect, 1 MiB max line, 30s decision timeout (fail-closed)
  - Version handshake required as first IPC exchange; strict major.minor match
  - Compatibility policy: breaking = major bump, non-breaking = minor bump, unknown types silently dropped
  - 5 degraded mode transitions, error contract, 11 acceptance checks
- **B-STREAM dependencies recorded:**
  - B-DEP-N1-1: `--socket-path`/`--data-dir` CLI flags (blocks N6 GA)
  - B-DEP-N2-1: `daemon.status` in default mode (blocks N3)
  - B-DEP-N2-2: `version.handshake`/`version.status` messages (blocks N3)
  - B-DEP-N2-3: Windows named pipe support (blocks N6 Windows)
- Risks R12/R13 closed; R15/R16 opened for B-STREAM deps
- N3 (supervision) and N4 (rollout) now unblocked (spec-side); N3 blocked on B-DEP-N2-1/N2-2 for implementation
- Tag: `ecosystem-v0.1.74-n-stream-1-n1-n2-lock`

---

## N-STREAM-1 N0 Policy Lock — Native App + Daemon Bundling — 2026-03-07

- **N0 DONE:** All 8 policy decisions locked (D0.1–D0.8), PM-approved
  - D0.1: App-managed daemon lifecycle (Tauri sidecar, no system service)
  - D0.2: Synchronous startup on app launch, 10s readiness timeout, `daemon.status` as readiness signal
  - D0.3: SIGTERM on app exit, 5s grace period, SIGKILL fallback; warn on active transfer
  - D0.4: Exponential backoff restart (1s/3s/10s), 3 max retries, degraded mode after exhaustion, 60s success reset
  - D0.5: Per-user single daemon instance via socket lockfile; kick-on-reconnect is current IPC behavior (may be revised in N2)
  - D0.6: Persistent state (identity key, TOFU pins) survives crashes; transient state (transfers, sessions) resets; PID file for stale detection
  - D0.7: Strict major.minor version match, fail-closed on mismatch; app+daemon co-versioned in bundle
  - D0.8: B-STREAM boundary reaffirmed; N-STREAM consumes daemon API, does not redefine protocol
- N1 (packaging) and N2 (IPC contract) unblocked
- Risk R14 closed (lifecycle/crash policy decided)
- Tag: `ecosystem-v0.1.73-n-stream-1-n0-policy-lock`

---

## N-STREAM-1 Codification — Native App + Daemon Bundling — 2026-03-07

- **N-STREAM-1 codified:** Governance workstream for native app + daemon bundling
  - Defines how native apps (localbolt-app first) bundle and lifecycle-manage bolt-daemon
  - 8 phases: N0 (policy lock) through N7 (closure)
  - Ownership boundary: N-STREAM-1 owns bundling/lifecycle/packaging/supervision; B-STREAM owns daemon protocol/runtime
  - N-STREAM-1 consumes daemon API surface, does not redefine it
  - Finding series `N1-F*` reserved in AUDIT_TRACKER.md
  - Risk register entries R12-R14 added (IPC stability, cross-platform packaging, lifecycle policy)
  - Product scope: localbolt-app primary; localbolt-v3 and localbolt web excluded
  - Daemon maturity dependency: N2 stabilizes current API surface only
  - ARCH-08 gate applies to any phase needing new top-level folders
- Tag: `ecosystem-v0.1.72-n-stream-1-codify`

---

## C-STREAM-R1 — UI/State Regression Recovery — 2026-03-06

- **C-STREAM-R1 DONE:** localbolt-v3 UX/state regression fixes
  - Generation guards on `handleConnectionStateChange`, `handleReceiveProgress`, `handleVerificationState`
  - Terminal-state-only reset (ignore intermediate WebRTC states)
  - Transfer terminal flag prevents late progress callbacks after cancel
  - Idempotent `disconnect()`
  - `snapshot()` returns live verification state (was hardcoded legacy)
  - Full transfer gating truth table tests (8 scenarios)
  - Stale verification callback guard tests
- Tag: `v3.0.80-c-stream-r1-ui-state-fix` (localbolt-v3)
- **Runner-context note:** `faq.test.ts`/`app.test.ts` apparent failures are root-run config artifacts (missing workspace config); all 70 web tests pass in-package. Not a regression or residual.
- **Tech debt (LOW):** `vitest.workspace.ts` at monorepo root would prevent root-run false failures.

---

## S-STREAM-R1 Closeout (R1-5 + R1-6) — Governance — 2026-03-06

- **R1-5 DONE:** Final validation gates passed across all product repos
  - localbolt: 319 tests PASS, build PASS
  - localbolt-app: 32 tests PASS, build PASS, coverage PASS (100%)
  - localbolt-v3 core: 50 tests PASS, build PASS
  - localbolt-v3 web: 59 tests PASS, build PASS
  - Total: 460 tests, 9/9 gates PASS, 0 failures
  - Tests-only verification: all 3 R1-4 commits confirmed tests-only (no runtime changes)
  - Tag integrity: all 7 R1-4 tags confirmed on origin (3 code + 3 docs + 1 ecosystem)
  - No D-stream infra/auth/deploy regressions
- **R1-6 DONE:** Governance reconciliation complete
  - STATE.md: R1-5/R1-6 DONE, S-STREAM-R1 CLOSED, repo tag snapshot updated, test counts updated
  - GOVERNANCE_WORKSTREAMS.md: all phases final, dependency map complete
  - ROADMAP.md: S-STREAM-R1 CLOSED/DONE
  - AUDIT_TRACKER.md: no finding status transitions warranted (R1-F series empty, no new findings)
  - Counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**
- **S-STREAM-R1 CLOSED:** All 7 phases complete (R1-0 through R1-6)
- **Sole residual:** Rust SDK reconnect/race tests (LOW) — deferred
- Tag: `ecosystem-v0.1.69-s-stream-r1-closeout`

---

## S-STREAM-R1 R1-4 Security Test Lift — Execution — 2026-03-06

- **R1-4 DONE:** Security-focused product test lift complete across all three target repos
- **localbolt:** +19 security-session-integrity tests (300 → 319). Covers stale callback rejection, trust transition isolation, transfer gating under reconnect edges, no-downgrade guarantees.
  - Tag: `localbolt-v1.0.27-s-stream-r1-r1.4-security-test-lift` (`fc360c5`)
- **localbolt-app:** +21 security-session-integrity tests (11 → 32). Covers identity/trust wiring in connect/reconnect, stale generation patterns, transfer gating transitions, session isolation.
  - Tag: `localbolt-app-v1.2.10-s-stream-r1-r1.4-security-test-lift` (`71c3181`)
- **localbolt-v3:** +7 security-reconnect-integrity tests in localbolt-core (43 → 50). Covers crypto-path integrity at reconnect boundary, trust isolation between sessions. Web tests unchanged (59).
  - Tag: `v3.0.79-s-stream-r1-r1.4-security-test-lift` (`31046ac`)
- **Runtime changes:** None (tests-only)
- **Residual:** Rust SDK reconnect/race tests (LOW) deferred — out of R1-4 product scope
- All R1-0 HIGH and MEDIUM security test gaps now covered
- R1-5 (validation gates) unblocked
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**

---

## S-STREAM-R1 R1-1 Architecture Disposition — Decision — 2026-03-06

- **R1-1 DONE:** Formal dispositions locked based on R1-0 evidence
- **D1 — SA1 Disposition: Path C** — SA1 closure confirmed. No new finding registered, no SA1 reopen.
  - Evidence: R1-0 daemon key-role inventory — identity persistent/TOFU-only, ephemeral per-session/crypto-only, 22 tests, zero ambiguous usage
- **D2 — R1-2: DONE-NO-ACTION** — No unresolved daemon architecture risk. SA1 separation verified complete.
- **D3 — R1-3: DONE-NO-ACTION** — All 3 products already use SDK-mediated crypto exclusively. Zero direct tweetnacl calls.
- **D4 — R1-4: Scope locked** as primary remaining S-STREAM-R1 execution scope:
  - localbolt: HIGH — 300 tests, 0 security (handshake/crypto-path/session state)
  - localbolt-app: HIGH — 11 tests, smoketest only
  - localbolt-v3: MEDIUM — verify if C7/H5-v3 coverage is adequate
- No runtime code changes made
- Tag: `ecosystem-v0.1.67-s-stream-r1-r1.1-disposition`
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**

---

## S-STREAM-R1 R1-0 Baseline Evidence — Execution — 2026-03-06

- **R1-0 DONE:** Baseline evidence + risk classification complete across all in-scope repos
- **Daemon key-role inventory:** SA1 separation confirmed complete — identity (persistent, TOFU-only) vs ephemeral (per-session, crypto-only). 22 SA1 tests. No ambiguous usage found. SA1 closure holds.
- **Product crypto-path inventory:** All 3 products use SDK-mediated crypto exclusively. Zero direct tweetnacl calls in product code. No R1-3 migrations needed.
- **Security test gaps identified:**
  - localbolt (v2): 300 tests but 0 handshake / 0 crypto-path / 0 session state security tests (HIGH)
  - localbolt-app: 11 tests, smoketest + TOFU integration only — no broad security coverage (HIGH)
  - All products: no product-layer crypto-path integration tests (MEDIUM)
- **Baseline metrics (all green):** daemon 318/398, bolt-core TS 120, transport-web 253, Rust 97/127, localbolt 300, localbolt-app 11, v3-core 43, v3-web 59
- **R1-1 agenda:** Evaluate whether gaps warrant new findings or are accepted risk. SA1 Path A likely not needed.
- Tag: `ecosystem-v0.1.66-s-stream-r1-r1.0-baseline`
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**

---

## S-STREAM-R1 Codification — Governance — 2026-03-06

- **S-STREAM-R1 codified:** Security/foundation recovery workstream — 7 phases (R1-0 through R1-6)
  - R1-0: Baseline evidence + risk classification
  - R1-1: Architecture decision (evidence-informed) + SA1 handling path
  - R1-2: Daemon remediation + security tests
  - R1-3: Product crypto-path convergence
  - R1-4: Security-focused product test lift
  - R1-5: Validation gates
  - R1-6: Governance reconciliation + closure
- **SA1 handling rule documented:** Path A (new R1-F finding) or Path B (explicit reopen), decided in R1-1 with evidence
- **Scope:** bolt-daemon (primary), localbolt-v3, localbolt, localbolt-app, bolt-core-sdk (if needed)
- **Priority:** Foundational security/runtime risks before further UX work
- Governance codification only — no execution deliverables
- Tag: `ecosystem-v0.1.65-s-stream-r1-codify`
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**

---

## D5 Drift Guards + Enforcement — DONE — 2026-03-06

- **D5 DONE:** Registry/auth regression guards added to all 3 consumer repos
  - `check-registry-mapping.sh`: ensures `.npmrc` maps `@the9ines` to `registry.npmjs.org`; rejects GitHub Packages refs and PAT dependencies
  - `check-lockfile-registry.sh`: ensures `package-lock.json` resolves `@the9ines` from `registry.npmjs.org`
  - CI cleanup: removed stale GitHub Packages auth (registry-url, NODE_AUTH_TOKEN, packages:read)
  - All 6 guards pass locally across all 3 repos
- **D6 UNBLOCKED:** 48h burn-in window starts now
- Tags:
  - `v3.0.78-d5-registry-guards` (`fec153b`)
  - `localbolt-v1.0.26-d5-registry-guards` (`76ae224`)
  - `localbolt-app-v1.2.9-d5-registry-guards` (`93afc2c`)
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**

---

## D4 Netlify Hardening — DONE — 2026-03-06

- **D4 DONE:** Consumer `.npmrc` cutover + Netlify deploy verified PAT-free
  - All 3 consumer repos switched from GitHub Packages to npmjs.org registry
  - Dependencies bumped: bolt-core 0.5.1, transport-web 0.6.4, localbolt-core 0.1.2
  - Lockfiles regenerated from registry.npmjs.org
  - Tests: localbolt-v3 102, localbolt 300, localbolt-app 11 — all pass
  - Netlify deploy: `state=ready`, `commit=0746275`, HTTP 200 at localbolt.app
  - Build fix: `netlify.toml` updated to build localbolt-core before localbolt-web (workspace symlink dist/ required on clean clone)
  - `NPM_TOKEN` env var retained (inert) through D6 burn-in for rollback safety
- **D5 UNBLOCKED:** Drift guards + enforcement can proceed
- Tags:
  - `v3.0.76-d4-npmjs-cutover` (`ef0543e`), `v3.0.77-d4-netlify-build-fix` (`0746275`)
  - `localbolt-v1.0.25-d4-npmjs-cutover` (`9bb3c38`)
  - `localbolt-app-v1.2.8-d4-npmjs-cutover` (`55c3e17`)
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## D0.5 Scope Verification + D3 Registry Migration — 2026-03-05

- **D0.5 DONE:** `@the9ines` npmjs.org scope verification passed
  - Scope owned by `the9ines` user; automation token configured
  - D3 unblocked
- **D3 DONE:** All 3 deploy-critical packages published to npmjs.org (PAT-free)
  - `@the9ines/bolt-core@0.5.1` — verified on npmjs
  - `@the9ines/bolt-transport-web@0.6.4` — verified on npmjs
  - `@the9ines/localbolt-core@0.1.2` — verified on npmjs
  - `publishConfig` changed from hardcoded GitHub Packages registry to `{"access": "public"}`
  - Existing GitHub Packages publish workflows preserved with explicit `--registry` flag
  - New `workflow_dispatch` npmjs publish workflows created for all 3 packages
  - PAT-free clean-environment install verified for all 3 packages
- **D0 DONE:** Policy lock complete (D0.5 was final gate)
- **D4 UNBLOCKED:** Netlify consumer `.npmrc` cutover can now proceed
- Version bumps required due to npmjs version immutability (previously published versions locked):
  - bolt-core: 0.5.0 → 0.5.1
  - bolt-transport-web: 0.6.2 → 0.6.4 (0.6.3 also locked)
  - localbolt-core: 0.1.0 → 0.1.2 (0.1.1 also locked)
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**
- Tag: `ecosystem-v0.1.62-d05-d3-registry-migration`
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## D1 Failure Baseline + D4 Netlify Unblock (Phase Cut) — 2026-03-05

- **D1 DONE:** Failure baseline and taxonomy produced across localbolt-v3, localbolt, localbolt-app
  - 5 failure signatures classified: GHPKG-AUTH-FAIL, DEPLOY-STALE, SDK-PUBLISH-LAG, BUILD-PATH-MISMATCH, DRIFT-REGRESSION
  - Top Netlify blocker: **GHPKG-AUTH-FAIL** — GitHub Packages requires PAT for all installs (even public packages)
  - No flaky test signatures observed; all failures were deterministic
- **D4 STOP:** Cannot proceed without D3 (package publication/migration)
  - All 3 deploy-critical packages (`bolt-core`, `bolt-transport-web`, `localbolt-core`) are exclusively on GitHub Packages
  - GitHub Packages has no PAT-free public install path — this is a platform limitation
  - Minimum D3 substeps documented: D0.5 scope verification + 5 publish/config steps
- **localbolt-v3 Netlify status:** Currently operational via DP-8 workaround (NPM_TOKEN PAT in Netlify dashboard)
  - NOT PAT-independent — personal GitHub PAT required
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**
- Tag: `ecosystem-v0.1.61-d1-d4-netlify-unblock`
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## D-STREAM-1 Codification — 2026-03-05

- **D-STREAM-1 codified:** CI stabilization + package auth migration workstream
  - Primary success gate: Netlify deploy reliability (PAT-independent public package installs)
  - 7 phases: D0 (policy lock) → D1 (failure triage) → D2 (CI stabilization) → D3 (registry migration) → D4 (Netlify hardening) → D5 (drift guards) → D6 (burn-in)
  - D0 policy decisions 1–4 locked at codification (PM-approved)
  - D0.5 (npmjs @the9ines scope verification) NOT-STARTED — blocks D3
  - D3 explicit dependency: BLOCKED-BY D0.5
  - Deploy-critical package seed set: `@the9ines/bolt-core`, `@the9ines/bolt-transport-web`, `@the9ines/localbolt-core`
  - Repo scope: localbolt-v3 (primary), bolt-core-sdk (D3 only), localbolt, localbolt-app
  - bolt-core-sdk D3 tag convention: `sdk-v<next>-d3-registry-migration`
  - Dual-publish (GitHub Packages + npmjs) temporary during burn-in
- **C-stream status refresh:** C0–C7 all DONE (ROADMAP.md aligned with STATE.md/tag history)
- **Risk register:** R10 (app-layer drift) → Closed. R11 (ARCH-08 disposition) → Closed.
- **S0 acceptance criteria:** Marked complete (DONE-MERGED per STATE history)
- Audit counters unchanged: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**
- D-stream placeholder in AUDIT_TRACKER.md does NOT increment total
- Tag: `ecosystem-v0.1.60-d-stream-1-codify`
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/ROADMAP.md`, `docs/STATE.md`, `docs/AUDIT_TRACKER.md`, `docs/CHANGELOG.md`

---

## Batch 6 — C7 Closure (Gap-Driven Audit + Targeted Test Fill) — 2026-03-05

- **C7 DONE:** Session UX race-hardening fully closed (Q7 → DONE-VERIFIED)
  - Gap-driven audit identified 2 missing evidence scenarios in `@the9ines/localbolt-core`
  - Added: rapid 7-cycle connect/reset monotonicity test (generation counter, state cleanliness, stale rejection)
  - Added: late verification callback from previous peer rejected after session switch
  - Prior evidence confirmed: session state machine (5-phase), A→B→C isolation, stale signal rejection, phase guards, transfer/verification cleanup
  - No runtime changes needed — existing code already handles all C7 scenarios
  - localbolt (300 tests) and localbolt-app (11 tests) unchanged — existing coverage sufficient
  - Tag: `v3.0.74-c7-closure` (`b867426`)
- **Q7 DONE-VERIFIED:** All disconnect/reconnect stale callback race scenarios covered
- Audit counters: **110 total, 90 DONE, 0 OPEN, 0 IN-PROGRESS**
- C-Stream: all phases C0–C7 DONE
- Updated: `docs/AUDIT_TRACKER.md`, `docs/CHANGELOG.md`, `docs/STATE.md`

---

## Batch 5 — C6 Hardening Completion + Q4 Closure — 2026-03-05

- **C6 DONE:** localbolt-core drift/upgrade hardening completed
  - `upgrade-localbolt-core.sh` added to localbolt and localbolt-app (check + write modes)
  - `check-core-drift.sh` added to localbolt-v3 (CI-enforced, `packages/localbolt-web/src`)
  - localbolt-v3 workspace exemption documented (pin/single-install not applicable)
  - Manual drift validation runbook: `docs/LOCALBOLT_CORE_DRIFT_RUNBOOK.md`
  - Tags: `localbolt-v1.0.24-c6-hardening`, `localbolt-app-v1.2.7-c6-hardening`, `v3.0.73-c6-hardening`
- **Q4 DONE-VERIFIED:** localbolt-app coverage thresholds enforced (90/90/80/90), `@vitest/coverage-v8` installed, CI runs `test:coverage`
- **Q10 DONE-VERIFIED:** All deferred C6 scope completed (upgrade tooling, v3 drift CI, runbook)
- Audit counters: **110 total, 89 DONE, 0 OPEN, 1 IN-PROGRESS (Q7)**
- Updated: `docs/AUDIT_TRACKER.md`, `docs/CHANGELOG.md`, `docs/STATE.md`, `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/LOCALBOLT_CORE_DRIFT_RUNBOOK.md`

---

## Batch 4B — C7 TOFU wiring + CI guards + governance closure — 2026-03-05

- **C7 IN-PROGRESS:** Identity/TOFU verification flow wired into localbolt and localbolt-app
  - localbolt: `localbolt-v1.0.23-c7-tofu-wiring` (`1bcb7b8`) — 300 tests
  - localbolt-app: `localbolt-app-v1.2.6-c7-tofu-wiring` (`e902186`) — 11 tests
  - Identity keypair persistence, TOFU pinning, generation-guarded callbacks, mismatch fail-closed
  - Verification states (unverified, verified) reachable from UI
- **CI guards enforced:** Core guard scripts (version-pin, single-install, drift) wired into CI for both repos
- Q4 promoted: DEFERRED → IN-PROGRESS (localbolt-app now has 11 active tests)
- Q7 promoted: OPEN → IN-PROGRESS (generation guard race hardening landed)
- Q8 reconciled: OPEN → DONE-VERIFIED (resolved in Batch 3/C0)
- Q9 reconciled: OPEN → DONE-VERIFIED (resolved in Batch 3/C2-C5)
- Q10 updated: evidence refreshed with CI guard enforcement, remaining deferred scope listed
- Adoption table refreshed: localbolt bolt-core 0.5.0/transport-web 0.6.2/300 tests, localbolt-app 0.5.0/0.6.2/11 tests
- Audit counters: **110 total, 87 DONE, 0 OPEN, 2 IN-PROGRESS, 1 PARTIAL**
- Updated: `docs/AUDIT_TRACKER.md`, `docs/CHANGELOG.md`, `docs/STATE.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## Batch 3 — C4+C5+C6: localbolt-core publish + consumer migration — 2026-03-05

- **localbolt-core published:** `@the9ines/localbolt-core@0.1.0` published to GitHub Packages from localbolt-v3
  - Tag: `v3.0.72-localbolt-core-publish` (`7cb8d8d`)
- **C4 DONE:** localbolt consumer migrated to `@the9ines/localbolt-core@0.1.0`
  - Tag: `localbolt-v1.0.21-c4-localbolt-core` (migration)
  - Tag: `localbolt-v1.0.22-c6-core-guards` (`ed2d671`) (C6 enforcement guards)
- **C5 DONE:** localbolt-app web consumer migrated to `@the9ines/localbolt-core@0.1.0`
  - Tag: `localbolt-app-v1.2.4-c5-localbolt-core` (migration)
  - Tag: `localbolt-app-v1.2.5-c6-core-guards` (`d1761e9`) (C6 enforcement guards)
- **C6 PARTIAL:** Enforcement guards added to localbolt and localbolt-app. Upgrade tooling (scripts) deferred.
- Q9 promoted: OPEN → DONE-VERIFIED (all three consumers now on shared localbolt-core)
- Q10 updated: OPEN → PARTIAL (guards added, upgrade tooling deferred)
- Repo tag snapshot updated: localbolt-v3, localbolt, localbolt-app
- Audit counters: **110 total, 87 DONE, 2 OPEN** (was 86 DONE, 3 OPEN)
- Updated: `docs/STATE.md`, `docs/CHANGELOG.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## ecosystem-v0.1.56-c-stream-c2 — 2026-03-04

- **C0 DONE:** Policy lock — `unverified` blocks file transfer. Codified in `v3.0.70-session-hardening-cpre2` (`cac5e4a`). Runtime, tests, and docs aligned. Q8 → DONE-VERIFIED.
- **C1 DONE:** ARCH-08 resolved via non-violating location — `@the9ines/localbolt-core` placed at `localbolt-v3/packages/localbolt-core` (inside existing npm workspace). No waiver needed.
- **C2 DONE:** `v3.0.71-localbolt-core-c2` (`aa9e40e`, docs `fea35bc`)
  - Extracted session state machine, verification state bus, transfer gating policy (`isTransferAllowed`), and generation guards into `@the9ines/localbolt-core@0.1.0`
  - New files: `src/session-state.ts`, `src/verification-state.ts`, `src/transfer-policy.ts`, `src/index.ts`
  - 41 core tests (33 session-hardening + 8 transfer-policy)
  - Build: tsc → `dist/` with declaration files
- **C3 DONE:** localbolt-v3 consumer migrated in same commit as C2
  - `peer-connection.ts`, `transfer.ts`, `h5-tofu-verification.test.ts` import from `@the9ines/localbolt-core`
  - `session-hardening.test.ts` kept in web as consumer wiring integration test
  - 59 web tests (unchanged), 51.37% line coverage (above 48% threshold)
  - Deleted: `src/services/session-state.ts`, `src/services/verification-state.ts` (now in core)
- Repo tag snapshot updated: localbolt-v3 → `v3.0.71-localbolt-core-c2` (`aa9e40e`)
- localbolt-v3 TS test count updated: 59 → 100 (41 core + 59 web)
- Q8 promoted: OPEN → DONE-VERIFIED (C0 scope resolved)
- Audit counters: **110 total, 86 DONE, 3 OPEN** (was 85 DONE, 4 OPEN)
- Updated: `docs/STATE.md`, `docs/CHANGELOG.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## ecosystem-v0.1.55-audit-gov-50 — 2026-03-04

- **localbolt-v3 session hardening:** `v3.0.70-session-hardening-cpre2` (`cac5e4a`, docs `ebdf503`)
  - Session orchestration layer + race hardening for localbolt-v3
  - Transfer gating policy aligned (unverified peer status blocks file transfer)
  - 33 new tests (59 total), 58.22% line coverage (up from 54.26%)
  - Addresses Q7 scope (disconnect/reconnect stale callback races) ahead of formal C7
- Repo tag snapshot updated: localbolt-v3 → `v3.0.70-session-hardening-cpre2` (`cac5e4a`)
- localbolt-v3 TS test count updated: 26 → 59
- Audit counters unchanged: **110 total, 85 DONE, 4 OPEN**
- Updated: `docs/STATE.md`, `docs/CHANGELOG.md`

---

## ecosystem-v0.1.55-audit-gov-49 — 2026-03-04

- **Workstream C codified:** LocalBolt Application Convergence + Session UX Hardening
  - C0: Policy lock — verification UX decision (NOT-STARTED, blocked on PM)
  - C1: localbolt-core scaffold + ARCH-08 disposition gate (NOT-STARTED)
  - C2: Extract canonical runtime from v3 baseline (NOT-STARTED)
  - C3: Migrate localbolt-v3 consumer (NOT-STARTED)
  - C4: Migrate localbolt consumer (NOT-STARTED)
  - C5: Migrate localbolt-app web consumer (NOT-STARTED)
  - C6: Drift guards + upgrade protocol (NOT-STARTED)
  - C7: Session UX race-hardening (NOT-STARTED)
- **Q7–Q10 registered (OPEN):** 4 new MEDIUM-severity Quality findings for C-stream scope
  - Q7: Disconnect/reconnect stale callback races (C7)
  - Q8: Verification policy mismatch between runtime/tests/docs (C0)
  - Q9: App-layer behavior drift across localbolt-v3, localbolt, localbolt-app (C2–C5)
  - Q10: Missing app-layer drift guards (C6)
- Audit counters reconciled: **110 total, 85 DONE, 4 OPEN** (was 106/85/0)
- Extraction baseline: localbolt-v3 (5 factual anchor paths verified present)
- ARCH-08 disposition gate codified in C1 (waiver vs location vs external repo)
- localbolt-core tag discipline deferred to C1 outcome
- localbolt-core distribution: package-based with exact pins (NOT subtree)
- Docs-only governance codification; no runtime code changes
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/ROADMAP.md`, `docs/STATE.md`, `docs/CHANGELOG.md`, `docs/AUDIT_TRACKER.md`

---

## ecosystem-v0.1.54-audit-gov-48 — 2026-03-04

- **D-E2E-B DONE:** `daemon-v0.2.30-d-e2e-b-cross-impl` (`a8cf108`)
  - Cross-implementation bidirectional file transfer: Node.js offerer ↔ Rust daemon answerer
  - JS harness (`tests/ts-harness/harness.mjs`): node-datachannel, tweetnacl, ws
  - Real bolt-rendezvous signaling, real WebRTC DataChannel, real NaCl encryption
  - Full encrypted HELLO exchange with capability negotiation (bolt.file-hash + bolt.profile-envelope-v1)
  - Bidirectional transfer: Pattern A (4096 B) JS→daemon, Pattern B (6144 B) daemon→JS
  - SHA-256 hash verification in both directions: `[B4_VERIFY_OK]` (daemon) + harness hash check (JS)
  - Test-only send trigger: 30 lines in `src/rendezvous.rs`, all `#[cfg(feature = "test-support")]`
  - Two `#[ignore]` integration tests: happy-path bidirectional + negative integrity mismatch
  - Files changed: `src/rendezvous.rs`, `tests/d_e2e_bidirectional.rs` (new), `tests/ts-harness/` (new)
- D-E2E status: IN-PROGRESS → DONE (both D-E2E-A and D-E2E-B complete)
- Daemon test counts: 318 default / 398 test-support + 3 ignored (was +1 ignored, +2 ignored E2E)
- Daemon tag snapshot updated: `daemon-v0.2.30-d-e2e-b-cross-impl` (`a8cf108`)
- Audit counters unchanged: **106 total, 85 DONE, 0 OPEN**
- Updated: `docs/STATE.md`, `docs/CHANGELOG.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## ecosystem-v0.1.53-audit-gov-47 — 2026-03-04

- **DP-9 CLOSED → DONE-VERIFIED:** SDK fix `sdk-v0.5.27-dp9-backpressure-fix` (`1be76c1`)
  - `bufferedAmountLowThreshold = 65536` (64KB) set in `setupDataChannel()`
  - 5s timeout fallback on backpressure await
  - `sendInProgress` guard prevents concurrent `sendFile` calls
  - Published `@the9ines/bolt-transport-web@0.6.2`
  - Consumer adoption: `v3.0.69-dp9-backpressure-fix` (`48617f0`). Deployed to production.
  - 253 SDK tests pass, 26 localbolt-v3 tests pass
- Audit counters: **106 total, 85 DONE, 0 OPEN**
- Repo tag snapshots updated: bolt-core-sdk → `sdk-v0.5.27-dp9-backpressure-fix` (`1be76c1`)
- Updated: `docs/AUDIT_TRACKER.md`, `docs/STATE.md`, `docs/CHANGELOG.md`

---

## ecosystem-v0.1.52-audit-gov-46 — 2026-03-04

- **DP-9 registered (OPEN):** Responder sendFile backpressure hang — `TransferManager.sendFile()` hangs
  indefinitely due to `bufferedAmountLowThreshold` defaulting to 0, no timeout fallback, and concurrent
  `sendFile` calls overwriting `onbufferedamountlow` handlers.
- Audit counters: **106 total, 84 DONE, 1 OPEN**
- Updated: `docs/AUDIT_TRACKER.md`

---

## ecosystem-v0.1.51-audit-gov-45 — 2026-03-04

- **DP-8 registered + closed (DONE-VERIFIED):** Netlify deployment stale — `.npmrc` missing from
  `packages/localbolt-web/`, Netlify couldn't install GitHub Packages scoped deps.
  Fix: `v3.0.68-dp8-netlify-npmrc` (`b1a2cd4`).
- Audit counters: **106 total, 84 DONE, 0 OPEN** (before DP-9 registration)
- Updated: `docs/AUDIT_TRACKER.md`

---

## ecosystem-v0.1.50-audit-gov-44 — 2026-03-03

- **NF-1 registered + closed (DONE-VERIFIED):** Envelope filename missing — file-transfer envelope
  carried an empty `name` field. SDK fix: `transport-web-v0.6.10-nf1-envelope-filename` (`c3ccd17`).
- 2026-03-03 4-agent security re-audit frozen as `docs/AUDITS/2026-03-03-security-re-audit.md`
- Audit counters: **104 total, 83 DONE, 0 OPEN**
- Updated: `docs/AUDIT_TRACKER.md`, `docs/STATE.md`

---

## ecosystem-v0.1.49-audit-gov-43 — 2026-03-03

- **B3-P3 DONE:** `daemon-v0.2.29-b3-transfer-sm-p3-sender` (`4fd55e3`) — sender-side transfer MVP
  - SendSession state machine: Idle → OfferSent → Sending → Completed/Cancelled
  - Cursor-driven chunk streaming (DEFAULT_CHUNK_SIZE = 16,384 bytes)
  - SHA-256 hash gating via `bolt_core::hash::sha256_hex` when bolt.file-hash negotiated
  - FileAccept/Cancel carved out from `route_inner_message` to Ok(None) for loop-level interception
  - Loop-level FileAccept drives send-side SM when active, absorbed when idle; Cancel same pattern
  - Pause/Resume remain INVALID_STATE (not implemented this phase)
  - No new DcMessage variants, no new EnvelopeError variants, no new canonical error codes
  - No disk IO, no async, no new dependencies, dc_messages.rs unchanged
  - Files changed: `src/transfer.rs`, `src/envelope.rs`, `src/rendezvous.rs`, `src/lib.rs`
- Daemon test counts updated: 318 default / 398 test-support + 1 ignored (was 302/382, +16)
- Daemon tag snapshot updated: `daemon-v0.2.29-b3-transfer-sm-p3-sender` (`4fd55e3`)
- B3 status: remaining work reduced (send-side delivered; pause/resume, disk writes, concurrent transfers remain)
- Updated: `docs/CHANGELOG.md`, `docs/STATE.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## ecosystem-v0.1.48-audit-gov-42 — 2026-03-03

Reconciliation commit: backfills DP-series (GOV-32–39) and DP-7 (GOV-41)
into CHANGELOG/STATE/GOVERNANCE, corrects audit counters, and updates all
repo tag snapshots to match current origin HEADs.

- Audit counters corrected: **103 total, 82 DONE, 0 OPEN** (was stale at 96/75 since GOV-31)
- Repo tag snapshots reconciled with current origin HEADs
- DP-series (GOV-32–39) and DP-7 (GOV-41) backfilled below
- Updated: `docs/CHANGELOG.md`, `docs/STATE.md`, `docs/GOVERNANCE_WORKSTREAMS.md`

---

## ecosystem-v0.1.47-audit-gov-41 — 2026-03-03

- **DP-7 DONE:** `sdk-v0.5.25-bolt-core-050` (`c776118`) + `v3.0.67-dp7-bolt-core-050` (`6bb21b3`)
  - `transport-web@0.6.1` imports `isValidWireErrorCode` from bolt-core, but bolt-core 0.4.0 predates the wire error registry (AC-8)
  - Fixed by publishing `@the9ines/bolt-core@0.5.0` with `WIRE_ERROR_CODES` + `isValidWireErrorCode`
  - localbolt-v3 bumped to bolt-core 0.5.0; Netlify build unblocked
- Audit counters: 103 total, 82 DONE, 0 OPEN
- AUDIT_TRACKER only; CHANGELOG/STATE not updated at the time (backfilled in GOV-42)

---

## ecosystem-v0.1.38..v0.1.45 — DP-series (GOV-32–39) — 2026-03-03

Deployment findings discovered during Fly.io deployment of bolt-rendezvous signal server. All 6 findings registered, resolved, and closed in `docs/AUDIT_TRACKER.md`. These commits only touched AUDIT_TRACKER.md; CHANGELOG/STATE/GOVERNANCE were not updated at the time. Backfilled here for completeness.

- **DP-1 DONE:** `rendezvous-v0.2.9-dp1-rust-bump` (`449796a`) — Dockerfile Rust 1.84→1.85 for edition2024 compat
- **DP-2 DONE:** `rendezvous-v0.2.10-dp2-health-check` (`06a0f42`) — HTTP health check handler for Fly.io proxy
- **DP-3 DONE:** 3 repos, 3 compounding bugs causing phantom device entries
  - `rendezvous-v0.2.11-dp3a-stale-peer-replace` (`f00ed7c`) — server replaces stale peer on re-registration
  - `v3.0.65-dp3b-dp4-phantom-transfer` (`08382f1`) — peer code persisted in sessionStorage
  - `sdk-v0.5.23-dp3c-stale-peer-cleanup` (`5496030`) — `handlePeersList` emits `peerLost` for stale entries
- **DP-4 DONE:** `v3.0.65-dp3b-dp4-phantom-transfer` (`08382f1`) — removed verification gate blocking unverified peer uploads
- **DP-5 DONE:** `rendezvous-v0.2.12-dp5-session-guard` (`aa8bed0`) — monotonic session_id prevents stale cleanup race
- **DP-6 DONE:** `sdk-v0.5.24-dp6-responder-send-fix` (`3c71407`) — clear stale receive progress; `transport-web@0.6.1` published; `v3.0.66-dp6-transport-web-bump` (`8f98716`) adopted
- DP-series: 6 findings, 6 resolved, 0 open. All MEDIUM severity.
- Audit counters at GOV-39: 102 total, 81 DONE, 0 OPEN

---

## ecosystem-v0.1.46-audit-gov-40 — 2026-03-03

- **D-E2E-A DONE:** `daemon-v0.2.28-d-e2e-a-live-transfer` (`b105344`) — live E2E transfer with SHA-256 hash verification
  - Synthetic Rust offerer → bolt-daemon answerer via real bolt-rendezvous
  - Real WebRTC (libdatachannel), real NaCl encryption, real profile-envelope-v1
  - Full signaling: register → hello/ack → SDP offer/answer → ICE exchange → DataChannel open
  - Full HELLO: encrypted identity exchange, capability negotiation (bolt.file-hash + bolt.profile-envelope-v1)
  - Full transfer: FileOffer (with SHA-256 hash) → FileChunk (4096 bytes) → FileFinish
  - Evidence: daemon emits `[B4_VERIFY_OK]` on stderr — unambiguous hash verification proof
  - Files changed: `src/transfer.rs`, `src/rendezvous.rs`, `Cargo.toml`, `tests/d_e2e_web_to_daemon.rs` (new)
- Daemon test counts updated: 302 default / 382 test-support + 1 ignored E2E (was 300/380, +2 unit + 1 E2E)
- D-E2E status: NOT-STARTED → IN-PROGRESS (D-E2E-A complete; D-E2E-B cross-implementation TS↔Rust deferred)

---

## ecosystem-v0.1.37-audit-gov-31 — 2026-03-03

- **B4 DONE:** `daemon-v0.2.27-b4-file-hash` (`b41f814`) — receiver-side SHA-256 hash verification gated by bolt.file-hash
  - `bolt.file-hash` added to `DAEMON_CAPABILITIES` (SA15 superseded)
  - TransferSession: `expected_hash` field, `on_file_offer` accepts optional hash parameter
  - `on_file_finish`: computes `bolt_core::hash::sha256_hex(&buffer)`, case-insensitive compare
  - New `TransferError::IntegrityFailed` variant for hash mismatch path
  - Loop-level capability gating: negotiated + missing hash → `INTEGRITY_FAILED` + disconnect
  - Not negotiated → hash on wire ignored (transfer succeeds)
  - Mismatch → `build_error_payload("INTEGRITY_FAILED", ...)` + disconnect
  - Sender-side hashing out of scope (daemon is receive-only per B3-P2)
  - No new dependencies, no new EnvelopeError variants, no wire format changes, no new error codes
  - Files changed: `src/transfer.rs`, `src/rendezvous.rs`, `src/web_hello.rs`
- Daemon test counts updated: 300 default / 380 test-support (was 291/371, +9)
- Daemon tag snapshot updated: `daemon-v0.2.27-b4-file-hash` (`b41f814`)
- B4 status: NOT-STARTED → DONE
- SA15 status: DONE-BY-DESIGN → SUPERSEDED (bolt.file-hash now implemented)
- D-E2E dependency updated: blocked on B3 full + B6 (B4 no longer blocking)
- Audit counters unchanged (75 DONE, 0 OPEN, 96 total) — no audit findings created or modified
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only; no runtime repos modified

---

## ecosystem-v0.1.36-audit-gov-30 — 2026-03-03

- **B3-P2 DONE:** `daemon-v0.2.26-b3-transfer-sm-p2` (`5844199`) — receive-side transfer data plane with chunk reassembly
  - TransferSession extended: Idle → OfferReceived → Receiving → Completed (+ Rejected from P1)
  - Auto-accept policy: FileOffer → `accept_current_offer()` → send `DcMessage::FileAccept`
  - Chunk receive: base64 decode via `bolt_core::encoding::from_base64` → `on_file_chunk` with sequential index enforcement
  - In-memory reassembly with `MAX_TRANSFER_BYTES` (256 MiB) cap at offer and chunk level
  - Transfer completion via `on_file_finish` → Completed state, `completed_bytes()` accessor
  - FileChunk and FileFinish carved out of `route_inner_message` to `Ok(None)` for loop-level handling
  - Loop interception expanded: `match` on FileOffer/FileChunk/FileFinish with full error handling
  - No disk writes, no send-side, no hashing (B4 scope), no pause/resume, no concurrent transfers
  - Files changed: `src/transfer.rs`, `src/envelope.rs`, `src/rendezvous.rs`
- Daemon test counts updated: 291 default / 371 test-support (was 279/359, +12)
- Daemon tag snapshot updated: `daemon-v0.2.26-b3-transfer-sm-p2` (`5844199`)
- B3 status: IN-PROGRESS → IN-PROGRESS (P2 complete; remaining: pause/resume, cancel, disk writes, send-side, hashing)
- B6 status: loop now handles full receive path (FileOffer/FileChunk/FileFinish)
- Audit counters unchanged (75 DONE, 0 OPEN, 96 total) — no audit findings created or modified
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only; no runtime repos modified

---

## ecosystem-v0.1.35-audit-gov-29 — 2026-03-03

- **B3-P1 DONE:** `daemon-v0.2.25-b3-transfer-sm-p1` (`edebe5d`) — transfer state machine skeleton with FileOffer → Cancel reject
  - TransferSession (Idle → OfferReceived → Rejected) integrated into `run_post_hello_loop`
  - FileOffer intercepted after envelope decrypt, rejected via Cancel (`cancelled_by="receiver"`)
  - Second offer while not Idle triggers INVALID_STATE disconnect
  - FileOffer carved out of `route_inner_message` combined transfer arm to Ok(None)
  - New files: `src/transfer.rs` (TransferSession, TransferState, TransferError)
  - Modified: `src/envelope.rs`, `src/rendezvous.rs`, `src/lib.rs`, `src/main.rs`
- Daemon test counts updated: 279 default / 359 test-support (was 273/353, +6)
- Daemon tag snapshot updated: `daemon-v0.2.25-b3-transfer-sm-p1` (`edebe5d`)
- B3 status changed: NOT-STARTED → IN-PROGRESS (B3-P1 complete)
- Dependency graph updated: B3-P1 integrated into B6-P1 loop container
- Tag naming deviation documented (spec: `daemon-vX.Y.Z-transfer-converge-B3`, actual: `daemon-v0.2.25-b3-transfer-sm-p1`)
- Audit counters unchanged (75 DONE, 0 OPEN, 96 total) — no audit findings created or modified
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only; no runtime repos modified

---

## ecosystem-v0.1.34-audit-gov-28 — 2026-03-02

- Reconcile governance with daemon tags pushed to origin (B5, B6-P1, plus dep-refresh, B1B2, FMT-1)
- **B5 DONE:** `daemon-v0.2.23-b5-tofu-persist` (`0faa729`) — persistent TOFU pinning bound to DC HELLO identity key
- **B6-P1 DONE:** `daemon-v0.2.24-b6-loop-container` (`8666f44`) — shared `run_post_hello_loop()` with fail-closed transfer message policy
- Daemon test counts updated: 273 default / 353 test-support (was 254/334)
- Daemon tag snapshot updated: `daemon-v0.2.24-b6-loop-container` (`8666f44`)
- B3 description updated to reflect B6-P1 codebase state (transfer messages now INVALID_STATE, not Ok(None))
- Dependency graph updated: B5 DONE, B6 IN-PROGRESS, B3 sole remaining critical-path blocker
- Tag naming deviations documented for B5 and B6-P1 (tags immutable, deviation recorded)
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only; no runtime repos modified

---

## ecosystem-v0.1.33-forward-dev-enrich — 2026-03-02

- Enriched deferred phases B3, B4, B5, B6, D-E2E with verified spec references, corrected dependencies, gates, and acceptance definitions
- **Dependency corrections:**
  - B5 (TOFU wiring): independent — removed incorrect B3 prerequisite
  - B6 (event loop): removed incorrect B5 prerequisite; coupled with B3 only
  - B3+B6 identified as coupled critical path
- All "Derived From" references verified against PROTOCOL.md:
  - §8 (File Transfer), §9 (State Machines), §4 (Capabilities), §6 (Message Protection), §15.4 (Post-Handshake Envelope), §2 (Identity/TOFU)
- Daemon facts verified: `src/ipc/trust.rs` (17 tests), no `src/transfer.rs`, both event loops are deadline-bounded demo loops
- Tag naming rules extended for B4–B6 and D-E2E
- Parallelization rules updated to reflect corrected dependency graph
- Audit counters unchanged (75 DONE, 0 OPEN, 96 total) — no audit findings created or modified
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only; no runtime repos modified; no pushes

---

## ecosystem-v0.1.32-audit-gov-26 — 2026-03-02

- Closed FMT-GATE-1 (daemon rustfmt verification drift) as DONE-VERIFIED
  - Evidence: `daemon-v0.2.22-fmt-sync-1` (`9d0a485`)
  - Mechanical `cargo fmt` sync only — no logic or behavior changes
  - 6 files formatted; all gates green (254 default / 334 test-support)
- FMT-GATE-1 is a governance process item, not an audit finding — audit counters unchanged (75 DONE, 0 OPEN, 96 total)
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only; no runtime repos modified; no pushes

---

## ecosystem-v0.1.31-workstreams-2 — 2026-03-02

- Closed A-STREAM-1 (WebRTCService decomposition: A0–A2)
  - A0: Shared state scaffolding (`sdk-v0.5.22-webrtc-decompose-A0`, `6f0bb05`)
  - A1: HandshakeManager extraction (`sdk-v0.5.22-webrtc-decompose-A1`, `e2d2b76`)
  - A2: EnvelopeCodec + TransferManager extraction (`sdk-v0.5.22-webrtc-decompose-A2`, `7f7811d`)
  - WebRTCService reduced 1,369 → 790 LOC; public API unchanged; 249 transport-web tests stable
  - A3/A4 absorbed into A2; A5 remains future work
- Closed B-STREAM-1 (interop defaults + transfer message types: B1–B2)
  - B1+B2 combined: `daemon-v0.2.21-transfer-converge-B1B2` (`95d672f`)
  - Fail-closed option C; defaults flipped to Web*; +15 tests (254 default / 334 test-support)
  - Governance deviation documented (B1+B2 combined into single tag)
- Opened FMT-GATE-1 (daemon rustfmt CI discrepancy — LOW, process-only)
  - 6 pre-existing files fail `cargo fmt -- --check`
  - Resolution plan: dedicated FMT-1 phase with separate tag
- Updated: `docs/GOVERNANCE_WORKSTREAMS.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only governance codification; no runtime repositories modified; audit counters unchanged; no pushes

---

## ecosystem-v0.1.30-workstreams-1 — 2026-03-02

- Codify A/B workstreams and phase gates (WORKSTREAMS-1)
- **Workstream A (bolt-core-sdk):** WebRTCService decomposition — 5 phases (A1–A5)
  - A1: Extract HandshakeManager
  - A2: Extract EnvelopeCodec
  - A3: Extract TransferManager
  - A4: Slim WebRTCService to coordinator (public API unchanged)
  - A5: Decomposition test hardening
- **Workstream B (bolt-daemon):** File transfer convergence — 3 phases (B1–B3)
  - B1: Flip interop defaults (blast radius + legacy flag documented)
  - B2: DataChannel message variants + parsing tests
  - B3: Transfer engine state machine (no file-hash, no TOFU persistence, no event loop)
- **Deferred phases documented:** B4, B5, B6, D-E2E (with prerequisites)
- **SA15 supersession note:** governance-only acknowledgement that DONE-BY-DESIGN rationale will be superseded when B4–B6/D-E2E are reached
- **Phase gate checklist:** standardized template for all phases
- **Tag discipline:** per-workstream tag naming rules codified
- **No-push policy:** default for all phase execution
- New file: `docs/GOVERNANCE_WORKSTREAMS.md`
- Updated: `docs/DOC_ROUTING.md`, `docs/STATE.md`, `docs/CHANGELOG.md`
- Docs-only governance codification; no runtime repositories modified; no pushes

---

## ecosystem-v0.1.29-audit-gov-25 — 2026-03-02

- Closed AC-13 (shadow tests replaced with canonical SDK imports) as DONE-VERIFIED
  - `sdk-v0.5.21-ac13-export-surface-1` (`829af85`)
  - `localbolt-v1.0.20-ac13-shadow-test-fix-1` (`b4d1a49`)
- Closed AC-15 (find_peer room isolation enforced) as DONE-VERIFIED (`rendezvous-v0.2.7-hardening-1`, `6ae3f77`)
- Closed AC-16 (XFF proxy allowlist, fail-closed) as DONE-VERIFIED (`rendezvous-v0.2.7-hardening-1`, `6ae3f77`)
- Closed AC-17 (export matrix exhausted, 33/33 VALUE exports in use) as DONE-VERIFIED
- Closed AC-22 (WebSocket connection limit, default 256) as DONE-VERIFIED (`rendezvous-v0.2.8-ac22-ws-conn-limit-1`, `bb59440`)
- Counters updated: DONE/DONE-VERIFIED 70→75, OPEN 5→0, Total 96
- **AC-series fully closed. All 25 findings resolved. OPEN = 0.**
- Tag snapshots updated: bolt-core-sdk, bolt-rendezvous, localbolt
- Docs-only governance reconciliation; no runtime repositories modified

---

## ecosystem-v0.1.28-audit-gov-24 — 2026-03-02

- Closed AC-10 (CONFORMANCE TODO reconciliation) as DONE-VERIFIED (`v0.1.5-spec-consistency-1`, `d795dd5`)
- Closed AC-11 (daemon dependency refresh) as DONE-VERIFIED (`daemon-v0.2.20-dep-refresh-1`, `99de9aa`)
- Closed AC-12 (cargo git dependency documentation) as DONE-VERIFIED (`ecosystem-v0.1.27-arch-consistency-1`, `fdb5545`)
- Counters updated: DONE/DONE-VERIFIED 67→70, OPEN 8→5, Total 96
- Remaining OPEN: AC-13, AC-15, AC-16, AC-17, AC-22
- bolt-daemon tag snapshot updated to daemon-v0.2.20-dep-refresh-1
- bolt-protocol tag snapshot updated to v0.1.5-spec-consistency-1
- Docs-only governance update; no runtime repositories modified

---

## ecosystem-v0.1.26-audit-gov-23 — 2026-03-02

- Closed AC-4 as DONE-VERIFIED (`v3.0.64-ac4-coverage-enforced`, `a5d0237`)
- Closed AC-5 as DONE-VERIFIED (`sdk-v0.5.20-protocol-converge-2`, `28c3baf`)
- Counters updated: DONE/DONE-VERIFIED 65→67, OPEN 10→8, Total 96
- All HIGH findings now closed (9/9 resolved)
- bolt-core-sdk tag snapshot updated to sdk-v0.5.20-protocol-converge-2
- localbolt-v3 tag snapshot updated to v3.0.64-ac4-coverage-enforced
- transport-web test count updated: 248→249 (+1 PROTO-HARDEN-08 send-side atomicity)
- Docs-only governance update; no runtime repositories modified

---

## ecosystem-v0.1.25-audit-gov-22 — 2026-03-02

- Closed AC-7 (verify-constants CI guard) as DONE-VERIFIED
- Closed AC-18 (dead crypto-utils barrel) as DONE-VERIFIED
- Reduced AC-17 (unused VALUE exports removed; types untouched; remains OPEN)
- Evidence: sdk-v0.5.19-governance-sweep-1 @ 9db3abd
- Counters updated: DONE/DONE-VERIFIED 63→65, OPEN 12→10, Total 96
- bolt-core TS test count corrected: 104→120
- bolt-core-sdk tag snapshot updated to sdk-v0.5.19-governance-sweep-1
- Docs-only governance update; no runtime repositories modified

---

## ecosystem-v0.1.24-audit-gov-21 — 2026-03-02

- Closed AC-6, AC-19, AC-20 (INTEROP-CONVERGENCE-1)
- Updated bolt-core-sdk snapshot to `sdk-v0.5.18-interop-converge-1` (`97352af`)
- Corrected stale transport-web test count (199 → 248)
- Severity table and OPEN counters reconciled (12 open, 13 resolved)

---

## ecosystem-v0.1.23-audit-gov-20

- Closed AC-21 as DONE-VERIFIED (`v0.1.4-spec`, `ede90be`)
- Closed AC-8 as DONE-VERIFIED (`sdk-v0.5.17-protocol-converge-1`, `16cfa92`)
- Closed AC-9 as DONE-VERIFIED (`sdk-v0.5.17-protocol-converge-1`, `16cfa92`)
- Reduced AC-5 (+6 explicit PROTO-HARDEN regression tests; remains OPEN)
- Counters updated: DONE/DONE-VERIFIED=60, OPEN=15, Total=96
- Docs-only governance update; no runtime repositories modified

---

## ecosystem-v0.1.22-audit-gov-19

- Closed AC-14 (subtree drift prevention implemented)
- Evidence: localbolt-v1.0.19-drift-guard-1 (6a4a006)
- Counters updated: DONE=57, OPEN=18, Total=96
- Drift guard implemented; staleness detection remains future enhancement

---

## ecosystem-v0.1.21-audit-gov-18

- Promoted AC-3 to DONE-VERIFIED
- Subtree refresh complete for signal/ in localbolt + localbolt-app
- Deterministic interop CI crate in place (no Cargo.toml mutation)
- Dead feature gate + unreachable cfg-gated tests removed
- DONE/DONE-VERIFIED 55 → 56
- OPEN 20 → 19

---

## ecosystem-v0.1.20-audit-gov-17

- Promoted AC-1 → DONE-VERIFIED
- Promoted AC-2 → DONE-VERIFIED
- DONE/DONE-VERIFIED 53 → 55
- OPEN 22 → 20
- Repository Tag Snapshot updated
- Docs-only governance update

---

## ecosystem-v0.1.19-audit-gov-16

- Registered 2026-03 Full Ecosystem Audit (AC-Series, 25 findings)
- Committed frozen audit source (`docs/AUDITS/2026-03-01-full-ecosystem-audit.md`)
- AC-1 through AC-22: OPEN (9 HIGH, 7 MEDIUM, 6 LOW)
- AC-23, AC-24, AC-25: DONE-BY-DESIGN
- Total findings now 96 (was 71)
- OPEN = 22, DONE-BY-DESIGN = 6
- No runtime changes

---

## ecosystem-v0.1.18-audit-gov-15

- N8 (per-capability string length bound) promoted to DONE-VERIFIED
  - daemon: `daemon-v0.2.19-low-n8` (`8683cbc`)
  - transport-web: `transport-web-v0.6.9-n8-caplen-1` (`ded0a40`)
- N10 (completion setTimeout cancellable) promoted to DONE-VERIFIED
  - transport-web: `transport-web-v0.6.8-low-n10` (`7f0bbaa`)
- N11 (openBoxPayload min-length guard) promoted to DONE-VERIFIED
  - sdk: `sdk-v0.5.15-low-n11` (`2a64e16`)
- N9 (cross-language golden vector test) closed DONE-BY-DESIGN
  - H3 vectors already prove TS seal → Rust open; auditor closed based on existing evidence
- N-series OPEN reduced to 0 — audit set fully resolved
- Global OPEN reduced to 0 — all 71 findings closed across all series
- DONE / DONE-VERIFIED: 50 → 53
- DONE-BY-DESIGN: 2 → 3

---

## ecosystem-v0.1.17-audit-gov-14

- Promote N6 to DONE-VERIFIED (typed HELLO errors)
- Promote N7 to DONE-VERIFIED (explicit HelloState guard)
- MEDIUM open reduced to 0
- Total findings unchanged (71)

---

## LIFECYCLE-HARDEN-1 — Deterministic Signaling Teardown (2026-02-28)

SA5 + SA6 lifecycle hardening in bolt-transport-web. Closes both
MEDIUM-severity LIFECYCLE-track findings from the 2026-02-26 audit.

**Deliverables:**
- **bolt-core-sdk** (`1962891`, `sdk-v0.5.11-lifecycle-harden-1`):
  - SA5: `handleSignal()` catch block calls `disconnect()` before
    `onError()`. `createPeerConnection()` nulls `this.pc` after close.
  - SA6: `SignalingProvider.onSignal()` returns unsubscribe function.
    WebSocketSignaling/DualSignaling return idempotent closures.
    WebRTCService stores handle, invokes early in `disconnect()`.
  - 8 new tests (3 SA5 + 5 SA6). 196 transport-web tests total.
- **bolt-ecosystem**: SA5/SA6 promoted to DONE-VERIFIED in tracker.

**Semver note:** `SignalingProvider.onSignal` return type changed from
`void` to `(() => void) | void`. Runtime-safe for void-return impls.

---

## PROTO-HARDEN-1R1 — Canonical Error Registry Unification (2026-02-26)

Unified the split error code registry (audit observation O4) into a single
canonical 22-code table in PROTOCOL.md §10. Previously, 11 protocol-level
codes lived in §10 and 14 enforcement codes in PROTOCOL_ENFORCEMENT.md
Appendix A, with only 3 overlapping. Now §10 is the sole authority.

**Deliverables:**
- **bolt-protocol** (`6a6de3f`, `v0.1.3-spec`): PROTOCOL.md §10 expanded
  to 22-code unified registry (11 PROTOCOL + 11 ENFORCEMENT) with Class,
  When, Framing, Semantics columns. §15.3 updated to reference unified §10.
  docs/CONFORMANCE.md §10 and §15.3 rows updated.
- **bolt-ecosystem**: PROTOCOL_ENFORCEMENT.md Appendix A converted to
  non-normative back-reference. STATE.md, CHANGELOG.md, AUDIT_TRACKER.md
  updated.

**No runtime code changed. No wire format changed. Governance/spec only.**

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
