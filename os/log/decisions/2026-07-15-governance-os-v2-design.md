# Decision: Governance OS v2 (Minimal-Delta)

> **Date:** 2026-07-15
> **Status:** Design accepted (Minimal-Delta). Execution PENDING — Phase 1 requires
> explicit human authorization before any file moves or tracker edits.
> **Scope repo:** bolt-ecosystem (root / governance layer only).
> **Supersedes:** nothing. Extends Governance OS v1 (the 2026-07-03 phases:
> `os/DASHBOARD.md` sensor, `os/NOW.md`, `os/log/`, `os/rules/`). v1 is kept; v2 is a delta.
> **Origin:** UltraCode read-only design workflow, 2026-07-15 (6 read-only readers →
> 3 independent designs → adversarial judging → synthesis). The full 47 KB working
> deliverable was produced in a session scratchpad (ephemeral); THIS ADR is the durable
> record and is self-contained enough to guide execution on its own.

This is a decision / proposal record, NOT an implementation. No evidence has been moved
and no tracker edits have been made by this ADR.

---

## Context

Governance OS v1 shipped 2026-07-03 as a "Health OS"-style system so state stays current
by construction. Its *design* is sound. Its *state* has since drifted, and — critically —
the entire EA-series security audit + Track B remediation (items 1-6, 2026-07-13..15) ran
**outside every governance home**: red-team reports and a remediation plan accumulated on
`~/Desktop` (iCloud, untracked, single-machine), the append-only journal never absorbed the
work, and `docs/AUDIT_TRACKER.md` became a role-overloaded essay registry with a stale,
false header count. A future ByteBolt SOC 2 effort would inherit a non-reproducible, un-homed
evidence base.

The design workflow verified the following first-hand (not inferred):

- `os/DASHBOARD.md` generated stamp = `2026-07-03 12:53 CDT` → **12 days stale**; wrong on ≥5
  repo rows; blind to `bolt-core-sdk @ spike/spake2-wasm`.
- `os/NOW.md` says "nothing in flight" (false); its review-by `2026-07-17` is not yet overdue,
  so the date-only boot check does not fire despite the contradiction.
- `os/log/journal.md` newest line is `2026-07-03` with **zero** EA entries; `os/log/decisions/`
  had exactly **one** ADR before this one.
- `docs/AUDIT_TRACKER.md` header claims `Total findings: 112` / `OPEN: 1` (a "last reconciled
  ~2026-03-13" block) while **54 `OPEN` tokens** sit in the rows below; 11 distinct status
  tokens are in use where 6 suffice.
- **5 dangling `~/Desktop/…` citations** in the tracker (near lines 639/649/651/652/698, 4
  distinct files); **2 reports** (`pake-library-eval.md`, the 270 KB `localbolt-remediation-plans.json`)
  are cited by nothing anywhere under `docs/`.
- `os/rules/security-model.md:126` asserts `Identity keypair (Ed25519)` — a **timeless rule that
  is false**: the shipping identity key is X25519, never signs (EA1; ROADMAP rejected the
  Ed25519 migration). A boot-consulted rule contradicts its own audit.
- Contradictory finding statuses coexist (`SA11 DONE-BY-DESIGN` while EA1 says "Reopens SA11";
  `SA10` vs `EA2`).

**What is CLEAN and must be preserved untouched:** the generated-vs-declared split
(`os/DASHBOARD.md` is gitignored, written only by `status.sh` via tmp+`mv`, `.git`-metadata-only);
the timeless `os/rules/` kernel; the existing evidence homes (`docs/evidence/` ~69 files,
`docs/AUDITS/` 5 files, `os/log/decisions/`, append-only journal, per-repo `docs/CHANGELOG.md`).

---

## Decision

**Adopt Minimal-Delta: evolve v1, do not rebuild.** The root cause is operational
(the audit bypassed the homes), not structural. The delta is: **home the loose evidence,
repair the tracker's chain of custody, de-lie its header, add the missing decisions/journal
lines, and add a routing rule + owner so it cannot recur.** Zero new top-level folders; no
child-repo code touched; the PAKE spike is read `.git`-only, never checked out.

Three ideas are grafted onto the Minimal-Delta spine (each stripped of the fragility the
adversarial judges flagged):

1. A **controlled 6-token status vocabulary** and the **DONE-VERIFIED evidence gate** (from the
   Evidence-Lineage design).
2. An explicit **`SUPERSEDED-BY:<ID>`** link to resolve contradictory finding statuses — never
   two live rows silently asserting opposite states (from the Generation-Purist design).
3. A **derived finding count via token-keyed `grep -c`** (counts controlled token *strings*, not
   table columns, so the messy multi-schema rows can't break it) — NOT a positional parser, NOT a
   new `FINDINGS.md` generator.

**Rejected** (over-engineering the judges and prior "keep it simple / don't touch unrelated
systems" guidance both penalize): new generators, event logs, `programs/` dirs, evidence
subfolders, and a 1285-line decomposition of the remediation JSON.

**Fatal-flaw corrections baked in:**
- The 270 KB remediation JSON is re-classified as a **dated, superseded PROPOSAL/INPUT** artifact
  (never a status source), with a one-file provenance sidecar; the tracker remains the single owner
  of current status. No decomposition project.
- The stale numeric SUMMARY (`Total 112 / OPEN 1`) is **deleted**, not relabeled "derived".
- Boot stays strictly `.git`-only plus one **bounded, non-recursive Desktop name-glob** (lists
  dirents, never reads content — iCloud-safe). Any in-tree untracked scan is opt-in (`--hygiene`),
  never at boot.

---

## Assessment: NEEDS-WORK (evolve, do not rebuild)

Top reasons, most severe first:
1. The EA-series bypassed every home (6 loose Desktop files; 4 cited by non-portable paths, 2
   orphaned).
2. `docs/AUDIT_TRACKER.md` is role-overloaded (EA1's single cell carries ~6 fact-types).
3. The hand-written surfaces never absorbed the biggest workstream (empty journal, "nothing in
   flight" NOW, one ADR).
4. No routing home exists for red-teams, tech/dependency evals, machine plan/proposal exports, or
   post-freeze workstreams (they squat as bare strings in the tracker's "Proposed workstream" column).
5. The sensor + agent manifest have gaps (spike-blind sensor, no freshness/loose-file signal, a
   zombie `context-keeper`, and no agent owns evidence routing — the exact mechanism that produced
   the sprawl).

Live stale-doc / duplicate-truth risks (all verified above): stale generated + declared state;
false current count; triplicated "what shipped" with the canonical journal empty; a false timeless
rule (`security-model.md:126`); status-token sprawl; contradictory coexisting statuses.

---

## Proposed v2 file tree

Legend — kind: `[GEN]` generated/untracked · `[HW]` hand-written living · `[AP]` append-only ·
`[IE]` immutable-evidence · `[RULE]` timeless · `[FROZEN]` consult-never-update.
Change: **NEW** · **EDIT** · **MOVE-IN** (from `~/Desktop`) · **DEL** (cruft) · *KEEP*.

```
bolt-ecosystem/                      (root, iCloud-synced; .claude/, CLAUDE.md, AGENTS.md gitignored)
├── CLAUDE.md                [RULE]  EDIT: drop stale "from/until Phase 2" doc-table refs;
│                                    evidence-tier pointer → os/rules/validation-protocol.md
├── ARCHITECTURE.md · PRD.md [RULE core] KEEP normative; embedded "current state" stays historical
│                                    under the existing trust-map banner (full reconciliation OUT of scope)
├── =                        DEL cruft (764 B pip-stderr redirect; gitignored) — sensor flags, human deletes
├── AUDIT-2026-02-26.md      DEL cruft (16 KB dup of docs/AUDITS/2026-02-26-*; gitignored) — flag, human deletes
├── os/
│   ├── DASHBOARD.md         [GEN]   KEEP — gitignored artifact, status.sh only, never hand-edited
│   ├── NOW.md               [HW]    EDIT: real in-flight EA/PAKE items; ByteBolt line → POINTER to its ADR;
│   │                                demote history-flavored W2-RUNTIME line to journal; new review-by
│   ├── bin/status.sh        [GEN tool] EDIT: +4 Signals + opt-in --hygiene + --check (still .git-only at boot)
│   ├── log/
│   │   ├── journal.md       [AP]    APPEND ~13 EA ship-lines (backfill; never rewrite existing lines)
│   │   └── decisions/
│   │       ├── 2026-07-03-transport-session-unification.md   [IE] KEEP
│   │       ├── 2026-07-15-governance-os-v2-design.md         [IE] THIS FILE
│   │       ├── 2026-07-13-ea1-adopt-pake-external-cryptographer.md   [IE] NEW (Phase 3)
│   │       ├── 2026-07-14-ea4-complete-trust-gate-fix.md            [IE] NEW (Phase 3)
│   │       ├── 2026-07-15-ea29-honest-no-verified.md               [IE] NEW (Phase 3)
│   │       ├── 2026-07-15-pake-spake2-spike.md                     [IE] NEW (Phase 3)
│   │       ├── 2026-07-15-bytebolt-relay-trust-boundary.md         [IE] NEW (Phase 3, SOC2-fwd invariant)
│   │       ├── 2026-07-14-ws-PAIRING-COMMIT-1.md                   [IE] NEW workstream-ADR
│   │       ├── 2026-07-14-ws-TRUST-GATE-CENTRALIZE-1.md            [IE] NEW workstream-ADR (EA2/EA3/EA4)
│   │       └── 2026-07-14-ws-SESSION-REGISTRY-1.md                 [IE] NEW workstream-ADR (EA27/EA28)
│   └── rules/               [RULE]  7 files today
│       ├── doc-routing.md   [RULE]  EDIT (keystone, Phase 2): +rows for red-teams / tech-evals /
│       │                            plan-proposal exports; +immutable-vs-living meta-rule;
│       │                            +"workstreams live as ADRs"; +"tracker cites repo-relative only";
│       │                            +6-token status vocabulary
│       ├── security-model.md [RULE] EDIT (Phase 3, scoped, human-gated): line 126 — strike the
│       │                            unqualified "Ed25519" identity claim → point to EA1 + adopt-PAKE ADR
│       └── README · phase-discipline · validation-protocol · btr-vector-policy ·
│           localbolt-core-drift-runbook  [RULE] KEEP
└── docs/
    ├── AUDIT_TRACKER.md     [AP registry] EDIT: repoint 5 citations repo-relative; add 2 orphan citations;
    │                                DELETE numeric SUMMARY (→ derivation pointer); (Phase 4) demote essay
    │                                cells to one-line finding + evidence link; apply 6-token vocab + SUPERSEDED-BY
    ├── AUDITS/
    │   ├── 2026-02-26-*.md … 2026-03-03-*.md         [IE] KEEP (5 immutable reports)
    │   └── 2026-07-13-localbolt-security-audit.md    [IE] MOVE-IN ← ~/Desktop/localbolt-security-audit.md (42 KB)
    ├── evidence/
    │   ├── <69 existing>_EVIDENCE.md                 [IE] KEEP
    │   ├── EA1_REDTEAM.md                            [IE] MOVE-IN ← ~/Desktop/ea1-pairing-redteam.md (7 KB)
    │   ├── EA3_REDTEAM.md                            [IE] MOVE-IN ← ~/Desktop/wt-trustgate-code-redteam.md (12 KB; also cited by EA27)
    │   ├── EA4_REDTEAM.md                            [IE] MOVE-IN ← ~/Desktop/trustgate-design-redteam.md (9 KB)
    │   ├── PAKE_EVAL.md                              [IE] MOVE-IN ← ~/Desktop/pake-library-eval.md (6 KB; cited by adopt-PAKE ADR)
    │   ├── EA_REMEDIATION_PROPOSAL_2026-07-14.json   [IE input] MOVE-IN ← ~/Desktop/localbolt-remediation-plans.json (270 KB)
    │   └── EA_REMEDIATION_PROPOSAL_2026-07-14.provenance.md  [IE] NEW sidecar (source/date/disposition; "NOT a status source")
    ├── GOVERNANCE_WORKSTREAMS.md · SECURITY_MODEL.md · DOC_ROUTING.md · STATE · ROADMAP · …  [FROZEN]
    └── archive/                                      [IE] KEEP

.claude/agents/              (gitignored — untracked policy layer; changes human-gated)
    ├── AGENTS.md            EDIT (Phase 5): retire zombie context-keeper; extend docs-keeper charter
    ├── docs-keeper.md       EDIT (Phase 5): owns tracker-index writes + evidence routing + journal line
    └── auditor · coder · test-runner · deployer · ops-monitor · reporter · security-auditor  KEEP
```

Net delta: 6 moves-in + 1 sidecar + ~9 small ADRs + ~7 in-place edits. Zero new folders.

---

## Desktop artifact routing table

`~/Desktop` is a scratchpad, never a home. No audit/red-team/eval/plan artifact is "done" until it
lives at a tracked, repo-relative path AND the tracker cites it repo-relative.

| Source (`~/Desktop/`) | Size | Destination | Class |
|---|---|---|---|
| `localbolt-security-audit.md` | 42 KB | `docs/AUDITS/2026-07-13-localbolt-security-audit.md` | immutable audit |
| `ea1-pairing-redteam.md` | 7 KB | `docs/evidence/EA1_REDTEAM.md` | immutable evidence |
| `wt-trustgate-code-redteam.md` | 12 KB | `docs/evidence/EA3_REDTEAM.md` | immutable (cited by EA3 AND EA27) |
| `trustgate-design-redteam.md` | 9 KB | `docs/evidence/EA4_REDTEAM.md` | immutable evidence |
| `pake-library-eval.md` | 6 KB | `docs/evidence/PAKE_EVAL.md` | immutable tech-eval (cited by adopt-PAKE ADR) |
| `localbolt-remediation-plans.json` | 270 KB | `docs/evidence/EA_REMEDIATION_PROPOSAL_2026-07-14.json` | **dated SUPERSEDED PROPOSAL — not a status source** |
| *(new)* | — | `docs/evidence/EA_REMEDIATION_PROPOSAL_2026-07-14.provenance.md` | immutable sidecar (provenance + disposition) |

Naming convention (reuses the flat `docs/evidence/<ID>_*.md` pattern — no subfolders): red-teams
`<ID>_REDTEAM.md`; tech-evals `<TOPIC>_EVAL.md`; machine exports `<TOPIC>_<YYYY-MM-DD>.json` +
`.provenance.md`. A `docs/evidence/redteams/` subfolder is explicitly declined as non-minimal.

Standing rule: an agent that produces an audit artifact homes it + cites it repo-relative BEFORE the
finding is marked touched; never left on `~/Desktop`. NOTE: an unrelated `02_Website_SEO_Audit.md`
lives on the same Desktop and is a known false-positive for any name-glob — do not move it.

---

## Content-kind rules

Decision procedure before writing anything: *Is it DERIVED from git/records? → generated.
TIMELESS law or small intent? → hand-written. A LEDGER that only grows? → append-only. A dated
PROOF/RECORD of something that happened? → immutable evidence.*

- **GENERATED** — `os/DASHBOARD.md` only. Written exclusively by `status.sh` (tmp+`mv`), gitignored,
  never committed, never hand-edited. No second generator; a derived finding count is a `grep -c`
  over controlled tokens appended to the dashboard Signals, not a new artifact.
- **HAND-WRITTEN** — `os/NOW.md` (intent, ≤60 lines, review-dated); `os/rules/*` + `CLAUDE.md`
  (timeless law, zero state). Rule-file changes require explicit human approval (Self-Governance Lock).
- **APPEND-ONLY** — `os/log/journal.md`; per-repo `docs/CHANGELOG.md`; `docs/AUDIT_TRACKER.md`.
  Newest entry wins; never rewrite an old line; a status change is a new dated token that names what it
  supersedes. The one permitted structured tracker edit: repointing a row's Evidence cell to its
  evidence file, plus the one-time removal of the stale numeric SUMMARY.
  - **Controlled status vocabulary (replaces the 11 observed tokens):** `OPEN` · `IN-PROGRESS` ·
    `DONE-VERIFIED` · `DONE-BY-DESIGN` · `DEFERRED` · `SUPERSEDED-BY:<ID>`. Bare
    `DONE`/`CODIFIED`/`CLOSED`/`CLOSED-NO-BUG` are deprecated.
  - **DONE-VERIFIED gate:** a finding may be `DONE-VERIFIED` only if it links, by repo-relative path,
    to immutable evidence meeting its severity minimum (HIGH: interop + ≥1 adversarial; MEDIUM: unit +
    ≥1 adversarial/interop; LOW: unit or documented rationale).
  - **Contradiction rule:** reopening a finding is `SUPERSEDED-BY:<ID>` on the old row + a new row —
    never two live rows silently asserting opposite states.
- **IMMUTABLE EVIDENCE** — `os/log/decisions/*.md` (ADRs incl. workstream-ADRs); `docs/AUDITS/*`;
  `docs/evidence/*` (incl. new `*_REDTEAM.md`, `PAKE_EVAL.md`, the frozen proposal JSON + sidecar).
  Written once, dated, never mutated; a change of mind is a NEW dated file naming what it supersedes.
  These + git history are the SOC 2 chain-of-custody objects.

**Immutable-vs-living meta-rule (the thing v1 never modeled — why all 6 files went un-homed):** on
landing, ask "will this file's claims change next week?" No → evidence (freeze as-is). Yes → decompose
into the living home AND freeze the raw file as a dated proposal snapshot so lineage survives.

**Separation model (one fact, one home):** intent → `os/NOW.md`; ecosystem history → `os/log/journal.md`;
decisions + workstreams → `os/log/decisions/*.md`; evidence → `docs/evidence/` + `docs/AUDITS/`; findings
ledger → `docs/AUDIT_TRACKER.md` (thin index `ID │ finding │ severity │ status-token │ evidence-link`,
not essays); release notes → per-repo `docs/CHANGELOG.md`. Finding STATUS has exactly one owner (the
tracker); WHAT SHIPPED has exactly one owner (the journal); they cross-reference by ID/tag. Journal vs
CHANGELOG is scope (cross-repo event vs repo release), not duplication. Post-freeze workstreams live as
ADRs (`GOVERNANCE_WORKSTREAMS.md` is frozen).

---

## Boot sequence (Claude / Codex — identical)

1. Regenerate + read state: run `os/bin/status.sh`; read `os/DASHBOARD.md`; heed Signals (untagged/
   unpushed work, off-release-branch = the spike, missing CHANGELOG, REPOS-vs-disk, un-homed Desktop
   artifacts). Never hand-edit the dashboard; never trust a hand-written "current state" elsewhere.
2. Read intent + contradiction-check: read `os/NOW.md`. Flag to the human before starting work if
   EITHER its review-by date passed OR the dashboard contradicts it (v1 checked only the date — that
   gap let "nothing in flight" survive).
3. History + records on demand: `os/log/journal.md` + per-repo `docs/CHANGELOG.md` for what shipped;
   `os/log/decisions/` for why; `docs/AUDIT_TRACKER.md` as a THIN INDEX — follow each row's evidence
   link into `docs/evidence/` or `docs/AUDITS/` rather than reading status from prose. Other `docs/`
   monoliths are frozen — consult, never update.

The "give me my read" ritual gains one v2 step: also report any un-homed-Desktop / untracked-docs
Signal as an "un-homed evidence" alert and propose the home + tracker citation.

## Agents never edit

Generated dashboard; immutable evidence/ADRs/audits; append-only history (journal / CHANGELOG /
historical tracker rows); frozen `docs/` monoliths; the governance layer (`.claude/agents/*`,
`AGENTS.md`, root `CLAUDE.md`, `os/rules/*`) without explicit human approval; vendored `signal/`
subtrees; spec-stub pointers (e.g. `bolt-core-sdk/PROTOCOL.md`); **the PAKE spike (read `.git` only,
never check out)**; immutable tags / shared history (no move/delete/reuse; no `--force`/`reset --hard`/
`rebase` on shared history; No-Push without authorization). Positive duty: docs-keeper homes + cites
any audit artifact before a finding is marked touched (retire the zombie context-keeper).

## SOC 2-forward (cheap readiness, zero SOC 2 started)

Do NOT start SOC 2 — no control matrix, TSC mapping, policy set, risk/vendor register, or auditor.
Just make the evidence v2 already produces tracked, dated, immutable so a future audit is a query over
an auditable corpus, not a retrofit. The one action that earns its keep (Phase 3): a single ADR
`2026-07-15-bytebolt-relay-trust-boundary.md` capturing the future relay's scope as an immutable
commitment ("forwards opaque ciphertext only, stores zero plaintext, SHELVED"), with NOW.md and the
transport ADR pointing to it. Optional zero-cost reserve: an empty `scope` column in the tracker so
ByteBolt-relevant findings are later a `grep` filter. Honest flagged gap (not fixed now): the gitignored
policy layer (`.claude/`, `CLAUDE.md`, `AGENTS.md`) has no tracked change-history.

---

## Migration phases (ordered; each independently shippable + reversible; No-Push)

- **Phase 1 — Home the evidence + repair custody + de-lie the tracker header** (smallest high-value;
  see the dedicated scope below). Pure relocation + link/meta edits; no rules, tooling, or schema.
- **Phase 2 — Codify the routing law + vocabulary** (human-approval-gated rule change to
  `os/rules/doc-routing.md` + `CLAUDE.md` mirror).
- **Phase 3 — Reconcile the hand-written surfaces + resolve contradictions** (refresh `NOW.md`;
  backfill ~13 journal lines; write the missing ADRs incl. the ByteBolt-boundary ADR; apply the tokens +
  `SUPERSEDED-BY`; scoped human-gated `security-model.md:126` correction).
- **Phase 4 — Demote the tracker to a thin index + optional derived `grep -c` count.**
- **Phase 5 — Sensor + owner** (extend `status.sh` with the 4 Signals + `--check`/`--hygiene`; update
  boot sequence; extend docs-keeper; retire context-keeper — human-gated).

Dependency order: 1 stands alone (do first). 2 stands alone. 4 depends on 1 + 2. 5 depends on 2.
Deferred (SOC 2-time or explicitly out of scope): PRD/ARCH reconciliation; REPOS auto-discovery + an
independent bolt-cli row; full JSON decomposition; tracking the gitignored policy layer.

**Smallest high-value migration = Phase 1 alone.** It converts the entire EA evidence base — 6
single-machine, iCloud-only, untracked files (incl. the 2 fully-orphaned, largest artifacts) — into
version-controlled, dated, immutable evidence with an intact chain of custody, and repairs the
registry's broken pointers and its one false count. If only one thing ships, ship this.

---

## Phase 1 execution scope (self-contained; PENDING human authorization)

Repo root: `/Users/oberfelder/Desktop/the9ines.com/bolt-ecosystem`. Execution, not design.

**Step 0 — Boot + read.** Run `os/bin/status.sh`, read `os/DASHBOARD.md` and `os/NOW.md`; read
`docs/AUDIT_TRACKER.md`, `os/rules/doc-routing.md`, `CLAUDE.md` (SRE + Documentation). Confirm the 7
source files exist; if any is an iCloud placeholder (`.icloud`/0 bytes), `brctl download` it first; if it
won't materialize, STOP and report.

**Step 1 — Move the 5 immutable artifacts** (`git mv`, per file, verify each with
`git ls-files --error-unmatch <dst>` + `test ! -e <src>`; if iCloud restores the source, remove the
restored copy by explicit path and re-verify):
1. `~/Desktop/localbolt-security-audit.md` → `docs/AUDITS/2026-07-13-localbolt-security-audit.md`
2. `~/Desktop/ea1-pairing-redteam.md` → `docs/evidence/EA1_REDTEAM.md`
3. `~/Desktop/wt-trustgate-code-redteam.md` → `docs/evidence/EA3_REDTEAM.md`
4. `~/Desktop/trustgate-design-redteam.md` → `docs/evidence/EA4_REDTEAM.md`
5. `~/Desktop/pake-library-eval.md` → `docs/evidence/PAKE_EVAL.md`

**Step 2 — Home the proposal JSON as a superseded input + sidecar.**
`git mv ~/Desktop/localbolt-remediation-plans.json docs/evidence/EA_REMEDIATION_PROPOSAL_2026-07-14.json`
(verify). Create `docs/evidence/EA_REMEDIATION_PROPOSAL_2026-07-14.provenance.md` — one short paragraph:
source, date `2026-07-14`, and that it is a machine-readable remediation PROPOSAL snapshot, NOT a status
source; current finding status lives only in `docs/AUDIT_TRACKER.md` (tracker wins on any disagreement).
Do not restate the plan contents.

**Step 3 — Repair the 5 tracker citations** (anchor on the `~/Desktop/<filename>` string, not the line
number): repoint `localbolt-security-audit.md` (near 639), `ea1-pairing-redteam.md` (near 649),
`wt-trustgate-code-redteam.md` (BOTH occurrences, near 651 and 698), `trustgate-design-redteam.md`
(near 652) to their repo-relative destinations. Add first-ever citations: `docs/evidence/PAKE_EVAL.md`
in EA1's cell; the proposal JSON in the method note near line 639 (marked "superseded — current status
is in the rows below").

**Step 4 — Delete the false current count.** Remove the numeric SUMMARY block that presents a *current*
tally (`Total findings: 112` ~line 127; `OPEN: 1` ~line 134; adjacent current-claiming lines). Replace
with a derivation pointer: open findings = rows whose Status is `OPEN`/`IN-PROGRESS`; counts are not
maintained here (they rot). Leave dated "Arithmetic reconciled in ecosystem-vX …" lines untouched
(historical). Do not rewrite any finding row.

**Step 5 — Journal line (same commit).** Append one dated newest-first line to `os/log/journal.md`:
the EA evidence base (audit + 3 red-teams + PAKE eval + remediation proposal) was homed into
`docs/AUDITS/` + `docs/evidence/`, 5 dangling `~/Desktop` citations repointed, 2 orphans gained
citations, stale numeric SUMMARY removed. Never edit existing journal lines.

**Acceptance checks (all must pass; paste outputs into the report):**
1. `git ls-files` lists all 7 destinations as tracked.
2. `grep -n "Desktop\|~/" docs/AUDIT_TRACKER.md` → no `~/Desktop` citations remain (the only allowed
   match is the prose heading `EGUI-NATIVE-1 … Desktop UI` ~line 587).
3. `grep -c` for the JSON + `PAKE_EVAL.md` paths in the tracker → ≥ 2.
4. `grep -n "Total findings:\|\*\*OPEN:\*\* 1"` → no current-count match.
5. `ls ~/Desktop/{the 6 sources}` → all absent.
6. journal line + all moves staged; working tree otherwise clean.

The full copy-paste-ready Phase 1 prompt (with exact commands and STOP conditions) is preserved in the
2026-07-15 UltraCode workflow output; this section reproduces its load-bearing scope so the ADR stands
alone.

---

## Explicitly out of scope / do not start here

- **Do NOT start SOC 2 or ByteBolt work.** The relay trust-boundary is captured as a design-forward ADR
  recommendation only (Phase 3) — no relay, no control matrix, no code.
- **Do NOT touch the PAKE spike** (`bolt-core-sdk @ spike/spake2-wasm`) — read `.git` (branch/HEAD) only,
  never check out or modify.
- **Do NOT reconcile PRD.md / ARCHITECTURE.md embedded state** — left historical under the trust-map
  banner; a full pass risks the "don't touch unrelated normative systems" failure mode. Named residual.
- **Do NOT touch child-repo code**, frozen `docs/` monoliths, or `os/rules/*` during Phase 1 (rules are
  Phase 2, human-gated).
- **Do NOT execute any phase from this ADR.** Phase 1 begins only on explicit human authorization.

## Execution discipline (all phases)

- **No-Push.** Pushes require explicit human authorization, after local review.
- **No `git add <dir>/`** — add every file by explicit path (a broad add once re-committed
  iCloud-restored duplicates). **No working-tree scans** (`git status`/`git add -A`) — verify tracking
  with `git ls-files <path>`. iCloud: prefer `git mv`, verify the source deletion survived, `brctl
  download` any cloud-only file first.
- Commit discipline: imperative subject < 72 chars; body with a `Files changed:` section; NO
  `Co-Authored-By` trailer; NO `--no-verify`; record short+full hash after commit.
- No tag unless the human authorizes one (`ecosystem-v0.1.199-governance-os-v2-phase1` per Tag Discipline).

---

## Source

Produced by the UltraCode read-only design workflow, 2026-07-15 (14 agents; all claims verified
first-hand against the real repo). The full 47 KB working deliverable existed only in a session
scratchpad (`scratchpad/governance-os-v2-design.md`, ephemeral) — this ADR is the durable, self-contained
record. Designs considered: Minimal-Delta (selected, judge 78/100), Generation-Purist (73), Evidence-Lineage
(70); the winner's spine was grafted with the vocabulary/gate, `SUPERSEDED-BY` link, and token-keyed count
from the runners-up, with every judged fatal flaw corrected.
