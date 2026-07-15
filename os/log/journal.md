# Journal — Bolt Ecosystem

Append-only, newest first. One dated line per thing shipped or decided.
Entries are never edited or deleted; corrections get their own entry.

- 2026-07-15 — **Governance OS v2 Phase 2: audit-evidence routing law + finding status
  vocabulary codified.** `os/rules/doc-routing.md` gained the *Audit Evidence & Records* section
  (one home each for immutable audit reports, evidence, red-teams, tech-evals, proposal snapshots,
  workstream-ADRs, and living finding status), the closed 6-token status vocabulary
  (`OPEN`/`IN-PROGRESS`/`DONE-VERIFIED`/`DONE-BY-DESIGN`/`DEFERRED`/`SUPERSEDED-BY`) with the
  DONE-VERIFIED evidence gate + contradiction rule, and the immutable-vs-living / thin-index /
  Desktop-scratchpad rules. `os/rules/security-model.md` identity-key label corrected
  Ed25519→X25519 with an EA1 pointer note (no crypto redesign). Root `19598d2`. No push, no tag.

- 2026-07-15 — **Governance OS v2 Phase 1: EA evidence homed, tracker chain of custody
  repaired.** Moved the six loose `~/Desktop` EA artifacts into tracked homes: the 42 KB security
  audit → `docs/AUDITS/2026-07-13-localbolt-security-audit.md`; the EA1/EA3/EA4 red-teams →
  `docs/evidence/{EA1,EA3,EA4}_REDTEAM.md`; the PAKE library eval → `docs/evidence/PAKE_EVAL.md`;
  the 270 KB remediation plan → `docs/evidence/EA_REMEDIATION_PROPOSAL_2026-07-14.json` + a
  `.provenance.md` sidecar marking it a dated superseded proposal, NOT a status source. Repointed
  the five dangling `~/Desktop` citations in `docs/AUDIT_TRACKER.md` to repo-relative paths, added
  first-ever citations for the two orphaned artifacts (PAKE eval + remediation JSON), and removed
  the stale numeric SUMMARY (it claimed Total 112 / OPEN 1 while dozens of rows carry OPEN) →
  non-numeric derivation pointer. Authority: ADR
  `os/log/decisions/2026-07-15-governance-os-v2-design.md`. Phases 2+ (routing rule, vocabulary,
  reconciliation, thin-index, sensor) NOT started; no push, no tag.

- 2026-07-15 — **Governance OS v2 design committed as an ADR.** An UltraCode read-only design
  workflow (14 agents; claims verified first-hand) produced the Minimal-Delta plan — evolve v1:
  home the loose EA evidence, repair the tracker chain of custody, add a routing rule + owner.
  Preserved as `os/log/decisions/2026-07-15-governance-os-v2-design.md` (root `61fc874`),
  self-contained with the v2 file tree, kind rules, migration phases, and a Phase 1 execution
  spec. Design/decision record only — no execution.

- 2026-07-15 — **EA-series security audit + Track B remediation landed.** After the ecosystem
  security audit (homed in `docs/AUDITS/` + `docs/evidence/`; EA-series registered in
  `docs/AUDIT_TRACKER.md`), six near-term authorization-hardening items shipped 2026-07-13..15,
  each mutation-verified and committed separately: (1) async IPC decision channel; (2) fail-closed
  daemon `trust_config`; (3) WebTransport trust gate (+ code red-team + hardened deny/deny-policy
  tests); (4) legacy-WS bypass closure; (5) native default `--pairing-policy allow`→`ask` + EA8
  keydir move to the platform data dir; (6) no false "verified" / persistent-pin pre-EA1 (EA29,
  across bolt-daemon + localbolt-app macOS Swift + localbolt-v3 web SDK). Authorization gating
  only — real device verification stays blocked on EA1 (see the adopt-PAKE ADR). Local commits
  across bolt-daemon, localbolt-app, localbolt-v3, and the ecosystem root; no push.

- 2026-07-03 — **Steam Deck de-risked: daemon cross-compiles for x86_64 Linux; dropped
  native-tls/OpenSSL.** Checked whether `bolt-daemon` builds for the Deck (Linux x86_64): no
  macOS-specific code, and ring/quinn/wtransport/tokio/rustls all cross-compile. The one snag
  was a vestigial `native-tls` (OpenSSL) dep pulled via a `tungstenite` feature — the WS
  transport only ever speaks plain `ws://` (Bolt's envelope layer does the NaCl encryption;
  QUIC/WT carry their own rustls/ring TLS). Removed it (daemon `668b19a`, tag
  `daemon-v0.2.57-drop-native-tls`): crypto is now pure-ring, `openssl`/`openssl-sys`/`native-tls`
  gone from the tree, 380 tests green, fmt+clippy clean. Verified via `cargo-zigbuild` → a real
  ELF x86-64 GNU/Linux daemon binary. De-risks the Steam Deck (no OpenSSL in the Flatpak) and
  Windows tracks. Multi-platform release plan lives in `localbolt-app/native/RELEASE_PLAN.md`.

- 2026-07-03 — **Transport-unification workstream CLOSED at Phases 1+2 (+ WT test + cleanup).**
  Assessed Phases 3 and 4 and decided against both, with evidence:
  • **Phase 3 (handshake unify)** — fails the decision doc's own "small / reviewable /
    behavior-preserving" gate. There are 5 handshake sites (WS/QUIC client + WS/QUIC/WT server),
    not 3, and the differences are *intentional*, not duplication: the WS server has a legacy
    no-identity path; WT deliberately skips identity-pinning because browser↔daemon trust is
    SAS-based (`BoltBridge.swift:774` uses `.unverified(sas:)`), and browsers are ephemeral so
    TOFU pinning would reject every reconnection. "Unifying" would be a behavior-changing,
    security-critical refactor. Skipped.
  • **Phase 4 (de-race ACTIVE_SESSION)** — only payoff is running the IPC test without
    `--test-threads=1`; production is single-session so the global is already correct, and
    "injectable" threads through the just-fixed send path. Not worth the risk. Skipped.
  • **WT handshake "drift" is NOT a bug**: the missing `session.sas`/`session.connected` IPC is
    already handled by the app polling the daemon's `[SAS]` stderr for WT sessions
    (`BoltBridge.swift:70`, `[DAEMON-POLL] WT SAS extracted`) — which is why App↔Browser
    validation passed; and the missing trust enforcement is by design (SAS not pinning). No fix.
  Net: all three transports share one session loop (the high-value 80%), shipped and running in
  production. Remaining phases are intentionally not done; the decision doc's Phase 3/4 stand as
  "considered and declined" with the reasons above.

- 2026-07-03 — **App↔App transfer CONFIRMED working both directions on real hardware** (Evan,
  Studio↔M5). Closes the whole app↔app thread. Two distinct issues, both resolved: (1) the
  connect hang → the QUIC 5s-timeout dial fix (`daemon-v0.2.55-app-dial-fix`), now confirmed
  in the real app — the two machines connect; (2) the "send file → session disconnected" report
  → NOT a code bug: the installed app was a **stale May 17 daemon build** (~2 months old,
  predating this session's work and the recovered May code). The current daemon transfers fine
  — verified locally multi-chunk over WS and QUIC up to 10MB, byte-identical. Fix: rebuilt the
  macOS app with the current daemon (`build-app.sh release arm64`) and deployed to both machines
  (`/Applications/LocalBolt.app` on the Studio, `~/Applications` on the M5; old Apr 11 / May 17 /
  Jul 3-early builds moved to Trash). Lesson: check the *installed binary's build date* before
  deep-diving a "bug" — I chased multi-chunk/QUIC/network theories for a while before finding the
  app was simply ancient. Also: the earlier "LAN data black-hole" call was wrong — plain 2KB TCP
  and large-DF ICMP flow fine between the machines; that stall was a manual-daemon harness artifact.

- 2026-07-03 — **Transport-unify cleanup DONE + app↔app fix reconfirmed cross-machine.**
  (1) Log tags + rename (daemon `d6515ae`, tag `daemon-v0.2.56-session-loop-cleanup`, local):
  the shared session loop, outbound send path, and pause/resume/disconnect controls now log
  transport-neutral `[SESSION]`/`[TRANSFER]` (WS-specific accept/HELLO paths keep `[WS_*]`);
  `ws_endpoint.rs` renamed to `session_loop.rs` (`session` was taken by the bolt_core re-export
  shim), refs across 10 files updated. Runtime-confirmed: a WebTransport session logs only
  `[SESSION]`/`[TRANSFER]`. 380 tests, fmt+clippy clean. Finishes TRANSPORT-UNIFY-1's cosmetic
  tail; only the low-value Phase 3/4 remain.
  (2) 2-machine reconfirm (Studio↔M5): the QUIC-timeout fix is confirmed cross-machine — the
  handshake to the M5 times out at 5s (was ~30s) then falls back to WS. Could not complete a
  full cross-machine session that run: an environmental LAN issue black-holed sustained data
  (TCP handshakes succeed both ways via `nc`, but a raw HTTP probe to the M5 daemon returned 0
  bytes and both dial directions stalled) — a middlebox/VPN/MTU problem, not the daemon or fix.

- 2026-07-03 — **Fixed the app↔app connect hang (daemon-side QUIC dial timing).** (daemon
  `3404cac`, tag `daemon-v0.2.55-app-dial-fix`, local.) Diagnosed by reading the localbolt-app
  signaling flow + the daemon connect watcher, then reproduced same-machine with two manual
  daemons fed a QUIC-complete `connect_remote` signal (the exact shape the app's FFI writes:
  wsUrl + quicAddr + quicCertHash). Root cause CORRECTS the morning's note: the app's Swift
  wiring is correct (it does dial, with a WS fallback URL); the daemon's QUIC handshake
  (`connect_with_config`) had no short timeout, so a stalled/unreachable QUIC peer blocked ~30s
  on the idle timeout before the working WS fallback fired — the "hang." Fix: a 5s
  `QUIC_CONNECT_TIMEOUT`. Verified: repro fallback dropped ~35s→~6s (log: `handshake timed out
  after 5s → WS connected → session established`, SAS matched); regression test
  `connect_handshake_fails_fast_for_unreachable_peer` (5.01s); 380 tests green; healthy QUIC
  unaffected. Lesson: this morning's "zero TCP connections" check missed QUIC (UDP) and didn't
  wait out the 30s fallback — the app was connecting, just ~30s slow.

- 2026-07-03 — **Transport unification pushed to origin (PM-authorized).** Verified clean first
  (0 divergence, doc/code-scoped diffs, 0 secret hits). Pushed: bolt-daemon `a45b76b..2777357`
  main + tags `daemon-v0.2.49`…`0.2.54` (P1/P2/WT-test + three that predated the session), and
  bolt-ecosystem `fb8341d..cc25ab2` main (App↔App root-cause + unification decision + P1/P2/test
  records). All three transport-unification tags are now immutable. Both repos level with origin.

- 2026-07-03 — **WT session-path test DONE — Phase 2 coverage gap closed** (daemon `2777357`,
  tag `daemon-v0.2.54-wt-session-test`, local/unpushed). `wt_session_emits_ipc_transfer_events_on_receive`
  stands up a real wtransport client+server, drives `handle_incoming_session` through the HELLO
  handshake, sends one NaCl-sealed file chunk, and asserts the daemon emits `transfer.started`
  + `transfer.complete` via the threaded `ipc_tx` and saves the exact bytes. Runtime-proves the
  Phase 2 WT→shared-loop fold + the `ipc_tx` threading (the one real risk) — the log shows
  `[WT_SESSION] entering shared session loop → [BTR] engine initialized → [WS_TRANSFER] saved`.
  The WT post-HELLO session path had never been executed by any test before this. 379 tests green.

- 2026-07-03 — **Transport unification Phase 2 DONE** (daemon `8248390`, tag
  `daemon-v0.2.53-transport-unify-p2`, local/unpushed). WebTransport folded onto the shared
  session loop via `session_frame::{WtFrameSink, wt_message_stream}` (mirroring the QUIC
  adapters); deleted `wt_endpoint.rs`'s `run_message_loop` (~280 lines, the recovered-May-code
  copy); WT inherits BTR + `transfer.*` IPC + disconnect from the shared loop. All 3 transports
  now share ONE session loop. `wt_endpoint.rs` 855→478. Run as ultracode: a 3-agent recon
  workflow mapped the code + designed the adapter + adversarially enumerated 6 risks; I
  implemented (threading `ipc_tx` end-to-end — the one real regression risk — and lifting
  `create_dir_all` into the shared loop); a 3-agent adversarial review of the diff returned
  CLEAN (all 6 risks handled/benign; IPC delivery identical to the old path — same channel).
  378 tests green, fmt+clippy clean, WS-only+QUIC-only builds compile. Open follow-up (filed
  NOW): the WT post-HELLO session path has no execution test (pre-existing gap); runtime
  browser-over-WT check was blocked by an environmental Chrome WT cert-handshake issue.

- 2026-07-03 — **Transport unification Phase 1 DONE** (daemon `4ca6192`, tag
  `daemon-v0.2.52-transport-unify-p1`, local/unpushed). Unified WS+QUIC onto one session
  loop via a new `session_frame` seam (`FrameSink` + WS/QUIC adapters); deleted the
  duplicate `run_quic_session_with_outbound` + `run_quic_read_loop` (~390 lines);
  `ws_endpoint.rs` 3188→2801. Behavior-preserving: 378 tests green (incl. every
  btr-over-transport + QUIC e2e), fmt + clippy clean, WS-only default build compiles.
  Executed in two verified stages (WS first, then QUIC) with the suite as oracle. Known
  cosmetic follow-up: QUIC sessions log under the shared loop's `[WS_*]` tags. Phase 2
  (fold WebTransport onto the same seam, delete `wt_endpoint.rs`'s loop) is next.

- 2026-07-03 — **Decided: transport session unification (frame-trait); ByteBolt shelved.**
  After the architecture audit, chose to unify the 3 duplicated transport session loops
  (WS/WT/QUIC) onto one transport-neutral frame trait rather than drop a transport, and
  to keep ACTIVE_SESSION single-session (centralize + de-race, no registry — multi-session
  is out of scope). Serves the "one protocol, any transport" vision; the future relay is
  just another transport plugged into the same seam. Phased, behavior-preserving,
  protocol/wire untouched, each phase gated by its own prompt. Decision + scope:
  `os/log/decisions/2026-07-03-transport-session-unification.md`. ByteBolt explicitly
  shelved (NOW.md "Shelved"). No code moved.

- 2026-07-03 — **App↔App validation run cross-machine → found a real app-layer bug.**
  M5 MacBook came online (same LAN); deployed the arm64 app and ran the checklist.
  GUI app↔app HANGS: discovery + accept work but neither daemon dials the other (zero
  TCP connections between them), so both apps stick at "waiting for encrypted channel."
  Root-caused with a headless daemon↔daemon pass over the same LAN: full session
  established (SAS `BE0FBF` matched both sides, BTR negotiated) and bidirectional file
  transfer checksum-verified (cc26e2cf… Studio→M5, c03ecac6… M5→Studio). So transport,
  crypto, HELLO, SAS, BTR, and transfer are all sound cross-machine — the bug is purely
  native-app wiring (initiator never issues the dial after accept). Filed to NOW.md;
  fix belongs in localbolt-app. En route, diagnosed + fixed a stuck-Tailscale issue on
  the Studio (backend wedged in "Starting" after an IP change; not the network).
  Evidence: `docs/evidence/MANUAL_VALIDATION_2026-07-03.md` (UPDATE section).

- 2026-07-03 — **Recovered May code kept + App↔Browser validation PASSED.** Assessed
  the uncommitted May working-tree code: it's coherent, tested progress, so kept per PM
  direction. daemon `a45b76b` (WT BTR receive path + transfer.* IPC events; `cargo test
  --features native-full -- --test-threads=1` = 378 passed, fmt+clippy clean) and app
  `90ff3a7` (order-aware WT lifecycle parse + initiator session handling; `swift build`
  clean). Then ran the App↔Browser manual checklist on a fresh arm64 build: all 8 steps
  CONFIRMED over WebTransport+cert-hash-pinning+full-BTR, both file directions verified
  by sha256 parity, SAS `4F548A` matched on both endpoints (step-8 browser-initiated
  disconnect had an automation-only renderer stall — native disconnect clean; see
  evidence). This is the first runtime confirmation of **W2-RUNTIME-VALIDATION-1**.
  App↔App checklist **BLOCKED** — both MacBooks offline on Tailscale. Evidence:
  `docs/evidence/MANUAL_VALIDATION_2026-07-03.md`. Recovered-code commits local-only.

- 2026-07-03 — **Governance OS pushed to origin (PM-authorized).** Verified clean
  first: zero divergence after fetch, outgoing diffs scoped to governance/doc files
  only, zero secret-pattern hits. Verification caught and fixed one defect before
  push: iCloud restored the two git-mv'd rule files to docs/ and a broad git add
  re-committed them — duplicates removed in f08dac0 (os/rules/ is canonical). Pushed:
  root main + tags ecosystem-v0.1.197/198, and main in bolt-core-sdk, bolt-daemon,
  bolt-rendezvous, localbolt, localbolt-app (remote still named localbolt-native),
  localbolt-v3. Both tags are now immutable.

- 2026-07-03 — **Governance OS Phases 2+3 complete.** Phase 2 (root): timeless rules
  extracted to `os/rules/` — security-model (verbatim from SECURITY_MODEL §1–8+§10),
  validation-protocol, phase-discipline, doc-routing (supersedes docs/DOC_ROUTING.md),
  btr-vector-policy + localbolt-core-drift-runbook (moved); docs/ monoliths
  banner-frozen; AUDIT_TRACKER marked append-only registry; ARCHITECTURE.md + PRD.md
  given trust-map banners; README + ROADMAP rewritten; stale QUIC handoff (was a loose
  untracked file) archived to docs/archive/; docs-keeper agent switched to the journal
  model. Phase 3 (sub-repos): docs/STATE.md retired to stubs and docs/README routing
  updated in bolt-core-sdk (7e824c8), bolt-daemon (c598727), bolt-rendezvous (35fb5ed),
  localbolt (f60e18c), localbolt-app (429502c), localbolt-v3 (36df64b — also CLAUDE.md
  aligned with root: Co-Authored-By mandate, tag-push instruction, and docs-sync
  ceremony removed). All commits local-only per No-Push Policy.
  (Root tag: ecosystem-v0.1.198-governance-os-phase2-3)

- 2026-07-03 — **Governance OS Phase 1 live.** Created `os/`: DASHBOARD.md (generated
  by `os/bin/status.sh`, never hand-edited), NOW.md (single intent file), this journal.
  Root CLAUDE.md slimmed to timeless rules with a boot sequence pointing here.
  Retired going forward: `-docs` suffix tags, separate docs-sync commits, and
  hand-written "current state" tables. The docs/ monoliths are frozen history
  (banners land in Phase 2). First dashboard run surfaced untagged work at HEAD
  in 7 repos, including 96 untagged commits in this root repo.
  (Tag: ecosystem-v0.1.197-governance-os-phase1)
