# Journal — Bolt Ecosystem

Append-only, newest first. One dated line per thing shipped or decided.
Entries are never edited or deleted; corrections get their own entry.

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
