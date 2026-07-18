# Journal — Bolt Ecosystem

Append-only, newest first. One dated line per thing shipped or decided.
Entries are never edited or deleted; corrections get their own entry.

- 2026-07-18 — **EA1 PAKE v7 profile draft created (design-only); corrects fork A to re-seed the BTR
  ratchet, not flatten it.** Revised the PAKE profile to fix the sole v6 MEDIUM: fork A **re-seeds**
  the existing BTR ratchet rather than replacing it — `session_root` seeds the generation-0 BTR
  `session_root_key = HKDF(ikm=session_root, info="bolt-btr-session-root-v1")`, replacing the current
  `PROTOCOL.md §16.3` `salt=EMPTY`/`ikm=ee` seed; the BTR key hierarchy, inter-transfer DH ratchet
  (`session_root_key → transfer_root_key → chain/message keys`), BTR-INV-01..11, and per-transfer
  forward secrecy are RETAINED; only the gen-0 seed changes `ee`→authenticated `session_root`. `K_session`
  (the §5-Expand flat orphan) stays retired, distinct from `session_root_key`. Also lands the four v6
  LOW cleanups: rate-limiter honesty (no unsatisfiable "never sheds a valid connection" absolute;
  pre-DH availability-DoS disclosed; budget→CD2a; post-DH contact-sticky rule kept verbatim); es/se
  WIRE-ROLE negative ("swap initiator↔responder ⇒ es/se transpose ⇒ PRK MUST differ"); clamped-X25519
  on `ee/es/se/ss` + clamping named in obligation #3; and the exporter/tier-select pin restored into
  `capabilities[]`/TT (non-forceable). §AV + fork A retained; obligation #6 targets the proposed
  two-level schedule; honest non-"verified" states. Retracts the falsified v6 §5/§6/L332 flat-schedule
  claim (v6's `K_session`-retired stays). Draft:
  `os/log/decisions/2026-07-18-ea1-pake-v7-profile-draft.md` (v6 retained verbatim). EA1 stays OPEN.
  NOT wire-frozen, NOT implementation-authorized. No code, no `PROTOCOL.md`/spec edits, spike inert.
  Root-repo governance only.

- 2026-07-18 — **EA1 PAKE v6 draft red-teamed (2026-07-17 pass); verdict NEEDS-REVISION,
  cryptographer-ready No (one localized text fix away).** The sixth UltraCode adversarial pass
  (read-only, 12 focus areas) returned NEEDS-REVISION with no blocker. **§AV worked** — the class-level
  Adverse-Verdict Invariant holds on all paths, and removing the hostile `key_mismatch` alert is a net
  security improvement (a keyless-summonable forgeable tripwire replaced by an honest neutral
  `tamper_unreachable` state), NOT a regression; fork A stays not-shipped + shadow-free. The ONLY
  handoff-gating defect is one CONFIRMED MEDIUM: the v6 §5 "K_session retirement" over-reached and
  falsely denies the canonical ratcheting `session_root_key` (contradicts `PROTOCOL.md §16.3` + the
  draft's own delta; a literal reading collapses per-transfer forward secrecy). Fix = a two-level
  correction (`session_root` SEEDS the gen-0 BTR `session_root_key`; the ratchet + BTR-INV-01..11 are
  retained; only the gen-0 seed changes `ee`→`session_root`). Plus 3 LOW editorial cleanups + 7
  cryptographer decisions. Trajectory v1(blocker)→v2(blocker)→v3(9 edits)→v4(2)→v5(2)→v6(1 MEDIUM, a
  factual BTR-schedule spec-consistency fix) — §AV closed the recurring KEY_MISMATCH class for good.
  Immutable evidence: `docs/evidence/EA1_PAKE_V6_REDTEAM.md`; v6 ADR marked PROPOSED — NEEDS REVISION;
  EA1 tracker row updated (stays OPEN). No code, no spec, no wire-freeze, spike inert. Root-repo
  governance only.

- 2026-07-17 — **EA1 PAKE v6 profile draft created (design-only); adds the class-level adverse-verdict
  invariant.** Revised the PAKE profile to state a §AV invariant ONCE — no keyless/SECRET-less party
  (including an untrusted rendezvous) may cause any adverse user-visible security verdict, pin mutation,
  contact-key-changed warning, re-pair prompt, or contact-sticky throttle against an honest
  possession_proven contact on ANY path — replacing the path-by-path patching that let the same class
  recur across v4/v5. §9 is now a consequence of §AV: a redirected locally-initiated reconnect →
  neutral TAMPER/UNREACHABLE (not KEY_MISMATCH/contact-key-changed/re-pair); unauthenticated inbound →
  silent rate-limited discard; a key-change verdict requires prior-key possession proof (CD1b); never
  mutate the pin on a keyless failure. The hostile product-facing key_mismatch alert is removed →
  neutral `tamper_unreachable` state. Fixes the two v5 MEDIUMs (FIX-2 neutral wording via §AV;
  rate-limiter scope — contact budget only post-identity-DH, garbage DH consumes no contact-sticky
  budget) + 6 LOW cleanups (K_session retired/naming resolved; both es>se AND es<se vectors; single-code
  split pinned to the SDK/harness layer; ROUTING fresh-per-refresh §1 MUST + "confidential transport"
  defined; CD1a contingency echoed inline; "proves possession of the prior key" defined). Fork A
  retained as a future PROTOCOL.md delta; carries the 8 cryptographer decisions + formal-model (§AV as
  obligation #0) and test obligations; honest non-"verified" states. Draft:
  `os/log/decisions/2026-07-17-ea1-pake-v6-profile-draft.md` (v5 retained verbatim). EA1 stays OPEN.
  NOT wire-frozen, NOT implementation-authorized. No code, no PROTOCOL.md/spec edits, spike inert.
  Root-repo governance only.

- 2026-07-17 — **EA1 PAKE v5 draft red-teamed; verdict NEEDS-REVISION, cryptographer-ready No (two
  author-text edits away).** The fifth UltraCode adversarial pass (read-only, 10 focus areas) returned
  NEEDS-REVISION with no blocker. **Fork A worked** — it legitimately closes the v4 HIGH (`session_root`
  is now consumed by obligation #6, no shadow value; the required `PROTOCOL.md` delta is a clearly
  flagged proposed future change, not asserted as shipped). The only blockers are 2 MEDIUM draft-defects
  on the `KEY_MISMATCH` surface: (CONFIRMED) `[FIX 2]`'s "the reconnect_handle cannot summon a forged
  alert about the honest contact" is false as written — the untrusted rendezvous can redirect a
  locally-initiated reconnect to fire a hostile contact-key-changed verdict about an honest
  possession_proven contact (fix = narrow the claim to inbound-only or commit strict-KK + a formal
  no-forged-alert-on-any-path obligation); (PLAUSIBLE) FIX-1's rate-limiter scope is unpinned →
  reconnect-DoS (fix = a §9 no-throttle-handshake-completing-reconnect invariant). Plus 5 LOW cleanups
  + 8 cryptographer decisions. Trajectory v1(blocker)→v2(blocker)→v3(9 edits)→v4(2 blocking)→v5(2 MEDIUM
  text edits) is converging hard; the KEY_MISMATCH/adverse-state class keeps resurfacing on new paths
  (recommend a class-level invariant, not path-by-path patches). Immutable evidence:
  `docs/evidence/EA1_PAKE_V5_REDTEAM.md`; v5 ADR marked PROPOSED — NEEDS REVISION; EA1 tracker row
  updated (stays OPEN). No code, no spec, no wire-freeze, spike inert. Root-repo governance only.

- 2026-07-17 — **EA1 PAKE v5 profile draft created (design-only); chooses §6 fork A.** Revised the
  PAKE profile to adopt §6 fork A — post-handshake data/BTR keys derive from the authenticated
  `session_root = HKDF(salt = PRK, ikm = ephemeral_shared_secret, info = TT/domain labels)`, not bare
  `ee`. This is a deliberate change to the FUTURE EA1 wire schedule, captured as a prominent "Required
  future PROTOCOL.md delta" section: `PROTOCOL.md` is NOT edited in this gate; it currently keys from
  `ee`, and the cryptographer/formal model must review the PROPOSED session_root-rooted schedule, not
  the old wire. Also incorporates the ten v4-review required edits: KEY_MISMATCH split by initiator
  (locally-initiated = hostile alert; unauthenticated inbound resolve-then-differ = silent
  rate-limited discard, no alert, no pin mutation); FIX-8/FIX-9 reconciled; code-burning DoS
  re-characterized honestly (no device penalty from consumed-code count); formal-model byte-layer
  clause struck; RFC 7748 citation fixed; reconnect confidentiality chain added; SECRET-off-server
  narrowed to conforming reference clients + harness; §5 L/R basis pinned unsigned byte-wise + ≥0x80
  vector; sort-discriminating es/se vectors; `reconnect_handle` invariants pinned + linkability → CD1c.
  Retracts the falsified v1/v2/v3/v4 claims; carries the 8 cryptographer decisions + formal-model and
  test obligations; honest non-"verified" states. Draft:
  `os/log/decisions/2026-07-17-ea1-pake-v5-profile-draft.md` (v4 retained verbatim). EA1 stays OPEN.
  NOT wire-frozen, NOT implementation-authorized. No code, no PROTOCOL.md/spec edits, spike inert.
  Root-repo governance only.

- 2026-07-17 — **EA1 PAKE v4 draft red-teamed; verdict NEEDS-REVISION, cryptographer-ready No (two
  fixes away).** The fourth UltraCode adversarial pass (read-only, 10 focus areas) returned
  NEEDS-REVISION with no blocker and 7 of 9 v3 edits landed cleanly. Two confirmed draft-defects block
  cryptographer handoff: (HIGH) §6's PRK-salted `session_root` is computed-but-unused — the normative
  (unedited) PROTOCOL.md keys the data channel from `ee` alone, so §6's data-keying + browser "secret
  PRK salt" claims are false for the wire (fix = pick fork A re-root the schedule via a future
  PROTOCOL.md delta, or B re-attribute §6 to ee-authentication); (MEDIUM) §9 inbound KEY_MISMATCH is
  attacker-summonable via the stable rendezvous-visible `reconnect_handle` (fix = split by initiator).
  Plus 8 LOW cleanups + 6 cryptographer decisions. Trajectory v1(blocker)→v2(blocker)→v3(9 edits)→v4(2
  blocking) is converging. Immutable evidence: `docs/evidence/EA1_PAKE_V4_REDTEAM.md`; v4 ADR marked
  PROPOSED — NEEDS REVISION; EA1 tracker row updated (stays OPEN). No code, no spec, no wire-freeze,
  spike inert. Root-repo governance only.

- 2026-07-17 — **EA1 PAKE v4 profile draft created (design-only).** Revised the PAKE profile to
  incorporate the v3 review's nine required draft edits: §8 cleanly decouples consume-the-displayed-code
  (one-guess bound) from device-wide backoff — backoff never escalates from anonymous inbound, only
  from the typer's local value-keyed attempts (fixes the v3 HIGH); `session_root = HKDF(salt = PRK,
  ikm = ephemeral_shared_secret)` with TT only in `info` (no public salt); `ephemeral_shared_secret`
  defined exactly as `ee` with a well-typed pubkey==pubkey binding; structural separate ROUTING/SECRET
  API inputs so no string containing SECRET reaches the mailbox layer (legacy-parser claim removed);
  joint anti-reflection (equality reject + TT binding + load-bearing direction-separated confirmation)
  + a negative vector; canonical X25519 ingress rejection + high-bit-flip vector; differential CSPRNG
  KAT + negative shared-seed case; reconnect `contact_id` resolution before the identity compare with
  precise KEY_MISMATCH semantics; and rotation-overwrite gated behind CD1b (no human-confirm-only
  overwrite). Retracts the falsified v1/v2/v3 claims; carries the 8 cryptographer decisions + widened
  formal-model and test obligations; honest non-"verified" states. Draft:
  `os/log/decisions/2026-07-17-ea1-pake-v4-profile-draft.md` (v3 retained verbatim). EA1 stays OPEN.
  NOT wire-frozen, NOT implementation-authorized. No code, no spec, spike inert. Root-repo governance
  only.

- 2026-07-16 — **EA1 PAKE v3 draft red-teamed; verdict NEEDS-REVISION (converging).** The third
  UltraCode adversarial pass (read-only, 10 surfaces) returned NEEDS-REVISION: NO confirmed blocker —
  the new §0 low-order/all-zero-DH rule genuinely closes the v2 rank-1 BLOCKER, and the reconnect
  downgrade floor holds. Driven by 1 confirmed HIGH + 4 confirmed MEDIUM, all author-fixable
  draft-defects: §8 escalates device-wide backoff on a garbage `PAIR_CONFIRM` (relocates the v2
  probe-DoS); §6 `session_root` salt `(or TT)` permits a public salt + `ephemeral_shared_secret` is
  undefined/type-confused; §1's "legacy parser rejects `bolt2:`" is code-verified false (deployed
  `normalizePeerCode` forwards verbatim); §4's "reflection resistance independent of confirmation" is
  false. 9 required draft edits before wire-freeze; 11 items correctly deferred to the cryptographer.
  Trajectory v1(no-PoP)→v2(low-order)→v3(no blocker) is the intended convergence; expected
  ACCEPTABLE-FOR-CRYPTOGRAPHER-REVIEW after the edits (v4). Immutable evidence:
  `docs/evidence/EA1_PAKE_V3_REDTEAM.md`; v3 ADR marked PROPOSED — NEEDS REVISION; EA1 tracker row
  updated (stays OPEN). No code, no spec, no wire-freeze, spike inert. Root-repo governance only.

- 2026-07-16 — **EA1 PAKE v3 profile draft created (design-only).** Revised the PAKE profile to
  incorporate the v2 red-team's eight required changes: a new §0 key-validity rule (reject small-order
  Curve25519 u-coordinates + abort all-zero X25519 DH per RFC 7748, identity+ephemeral,
  pairing+reconnect — fixes the low-order-point BLOCKER); conforming-client routing/secret split with
  separate artifacts + a version container legacy parsers reject; `session_root` bound to the
  authenticated transcript with `ephemeral==BTR-root` a fail-closed MUST; a primitive-independent
  anti-reflection reject; white-box CSPRNG independence (KAT, not a statistical test); a mandatory
  non-overridable reconnect downgrade floor from `possession_proven` pins; CSPRNG `contact_id` +
  human-confirmed key rotation; and authenticated-only code consumption (no consume/backoff on
  unauthenticated probes). Retracts the falsified v1/v2 claims; carries the 10 cryptographer decisions
  + widened formal-model and test obligations; honest non-"verified" states. Draft:
  `os/log/decisions/2026-07-16-ea1-pake-v3-profile-draft.md` (v2 draft retained verbatim). EA1 stays
  OPEN. NOT wire-frozen, NOT implementation-authorized. No code, no spec, spike inert. Root-repo
  governance only.

- 2026-07-16 — **EA1 PAKE v2 draft red-teamed; verdict HAS-BLOCKERS (direction validated).** An
  UltraCode adversarial review (read-only, 11 surfaces) returned HAS-BLOCKERS: 1 BLOCKER (a low-order
  X25519 point makes the identity DH return all-zero → forges the §1 possession proof → reopens the
  reconnect MITM; needs a normative RFC 7748 point/all-zero-DH abort), 2 confirmed HIGH (routing/secret
  "server can't receive SECRET" overclaim; the ephemeral==session_root binding is prose-only outside
  the §8 model gate) + 4 confirmed MEDIUM — but the design direction is validated (all four v1
  blockers moved right; three falsified v1 claims retracted) and 13 items were correctly deferred to
  the external cryptographer. 8 required changes before wire-freeze. Immutable evidence:
  `docs/evidence/EA1_PAKE_V2_REDTEAM.md`; the v2 ADR is marked PROPOSED — REVISION REQUIRED; EA1
  tracker row updated (stays OPEN). A v3 revision incorporating the 8 changes is the next design step.
  No code, no spec, no wire-freeze, spike inert. Root-repo governance only.

- 2026-07-15 — **EA1 PAKE v2 profile draft created (design-only).** Revised the PAKE profile to
  address the v1 red-team's nine required changes — identity proof-of-possession via a Noise-style
  DH key schedule + a reconnect static-DH rule (the top blocker fix; reconnect no longer relies on a
  public-key match), one-time-code consumption / single-flight / lockout, a ceremony-bound
  unstrippable downgrade floor, a structural routing/secret split, an injective transcript codec, a
  CPace-vs-SPAKE2 primitive decision point, fold-locally channel binding, a widened formal-model
  scope, and a contact_id pin model with honest non-"verified" product states. Draft:
  `os/log/decisions/2026-07-15-ea1-pake-v2-profile-draft.md`; supersedes-in-specifics the v1
  proposal; EA1 stays OPEN. NOT wire-frozen, NOT implementation-authorized; unresolved cryptographer
  decisions marked. No code, no spec, spike inert. Root-repo governance only.

- 2026-07-15 — **EA1 PAKE v1 profile proposal recorded; red-team returned HAS-BLOCKERS.** The
  type-a-secret PAKE design was preserved as a proposal ADR
  (`os/log/decisions/2026-07-15-ea1-pake-v1-profile-proposal.md`) and adversarially reviewed
  (UltraCode, 15 surfaces): verdict HAS-BLOCKERS (1 BLOCKER = no identity proof-of-possession →
  zero-guess reconnect MITM; 3 HIGH / 3 MEDIUM / 3 LOW; 9 required changes before wire-freeze).
  Immutable evidence: `docs/evidence/EA1_PAKE_PROFILE_REDTEAM.md`; ADR marked REVISION REQUIRED;
  EA1 tracker row updated (stays OPEN). Implementation and wire-freeze remain BLOCKED pending
  revision, external cryptographer sign-off, and a formal model. Design/spec-drafting only; no code,
  no spec impl, spike stays inert. Root-repo governance only.

- 2026-07-15 — **Tag reconciliation closed: four repos pushed + milestone-tagged.** Pushed `main`
  to origin for the root, bolt-daemon, localbolt-app, and localbolt-v3 (branches now level with
  origin), then created, pushed, and postflight-verified one annotated milestone tag per completed
  workstream — each present locally and on origin, peeling to the exact HEAD commit:
  `ecosystem-v0.1.199-governance-os-v2` (root `0ccfca9`, Governance OS v2 Phases 1-5),
  `daemon-v0.2.58-ea-trust-gate` (`5022961`), `localbolt-app-v2.0.2-ea-honest-verify` (`c28dcb8`),
  and `v3.0.109-ea29-honest-verify` (`14db116`) — the latter three carrying the EA / Track B
  remediation. bolt-core-sdk spike, bytebolt, localbolt, and rendezvous not tagged this pass.
  Closes the tag-reconciliation checkpoint. Root-repo governance only; no code, no further push.

- 2026-07-15 — **Tag policy codified: milestone/release checkpoints, not every commit.** Governance
  now tags completed workstream checkpoints + releases, not routine commits (the journal + per-repo
  CHANGELOGs carry detailed history; immutable-tag discipline stands). Recorded in
  `os/log/decisions/2026-07-15-tag-policy-milestones-not-commits.md`; `CLAUDE.md` Tag Discipline
  updated. In the same pass, reconciled `os/NOW.md` (Governance OS v2 Phases 1-5 complete → removed
  from Now, EA1/PAKE promoted) and backfilled the Phase 3/4/5 lines below. Root-repo governance only;
  no push, no tag.

- 2026-07-15 — **Governance OS v2 Phase 5: sensor Signals + opt-in hygiene checks.**
  `os/bin/status.sh` gained four boot Signals (off-release-branch/spike, per-repo CHANGELOG
  presence, REPOS-vs-disk drift, un-homed `~/Desktop` top-level glob) plus opt-in `--check`
  (dashboard freshness) and `--hygiene` (un-homed-docs scan + root cruft) and `--help`; all
  name-level/`.git`-only at boot (~1.8s, iCloud-safe). The generated `os/DASHBOARD.md` stays
  untracked. `CLAUDE.md` read-ritual updated. Root `8f2b302`.

- 2026-07-15 — **Governance OS v2 Phase 4: thin-index the active EA-series tracker rows.** Collapsed
  the overloaded EA1/EA2/EA3/EA4/EA29 essay cells in `docs/AUDIT_TRACKER.md` to thin-index rows
  (finding | category | workstream | 6-token status + evidence/ADR links); the detail lives in the
  evidence files + Phase 3 ADRs. SA11 got `SUPERSEDED-BY:EA1` + a reopen pointer, SA10 a
  "completed by EA2" pointer (frozen history retained, no findings deleted). Root `77c8c97`.

- 2026-07-15 — **Governance OS v2 Phase 3: reconcile NOW / journal / decisions.** Refreshed
  `os/NOW.md` (replaced the false "nothing in flight"), backfilled the Track B + design-ADR + Phase 2
  journal lines, and added three ADRs (ByteBolt relay trust boundary; EA1 adopt-PAKE direction;
  trust-gate + honest verification). Tiny `CLAUDE.md` Phase-2 wording tidy-up. Root `480d229`.

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
