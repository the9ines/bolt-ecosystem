#!/usr/bin/env bash
# os/bin/status.sh — Bolt Ecosystem sensor.
# Generates os/DASHBOARD.md from git facts. The dashboard is DERIVED STATE:
# never hand-edit it, never hand-write "current state" anywhere else.
#
# Reads only .git metadata + name-level stats by default (dirent listings and
# `[ -f ]` checks), so it is safe on iCloud-synced trees. It never reads file
# CONTENT at boot (content scans can hang on cloud-only files).
#
# Usage:
#   os/bin/status.sh            # safe default: regenerate the dashboard
#                               # (.git reads + name-level stats only)
#   os/bin/status.sh --dirty    # + working-tree dirty counts (may hang on
#                               # cloud-only files; run `brctl download` first)
#   os/bin/status.sh --hygiene  # + an OPT-IN in-tree scan for un-homed docs
#                               # (`git status -uall -- docs/`) + root cruft.
#                               # The only working-tree scan; never runs at boot.
#   os/bin/status.sh --check    # do NOT regenerate; read the dashboard's Generated
#                               # stamp and exit non-zero if older than N days
#                               # (STALE_DAYS, default 2). For between-session hooks.
#   os/bin/status.sh --help
#
# Boot Signals (all name-level / .git only): unpushed & untagged work · dirty
# (--dirty) · off-release-branch (e.g. a spike checkout) · missing per-repo
# docs/CHANGELOG.md · REPOS-vs-disk drift · un-homed bolt audit artifacts on
# ~/Desktop (top-level name glob only, never reads content).

set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/os/DASHBOARD.md"
TMP="$OUT.tmp"
STALE_DAYS="${STALE_DAYS:-2}"

DIRTY=0; HYGIENE=0; CHECK=0
for arg in "$@"; do
  case "$arg" in
    --dirty)   DIRTY=1 ;;
    --hygiene) HYGIENE=1 ;;
    --check)   CHECK=1 ;;
    -h|--help) grep '^#' "$0" | sed '1d;s/^# \{0,1\}//'; exit 0 ;;
    *) echo "status.sh: unknown flag '$arg' (try --help)" >&2; exit 2 ;;
  esac
done

# --check: freshness gate. Reads ONLY the dashboard's Generated stamp (one line);
# never regenerates, never touches git or the working tree. Exit 1 if stale/missing.
if [ "$CHECK" = "1" ]; then
  if [ ! -f "$OUT" ]; then
    echo "check: no dashboard at $OUT — run os/bin/status.sh" >&2; exit 1
  fi
  gen_date=$(grep -m1 'Generated:' "$OUT" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
  if [ -z "$gen_date" ]; then
    echo "check: cannot read Generated stamp from $OUT" >&2; exit 1
  fi
  gen_epoch=$(date -j -f "%Y-%m-%d" "$gen_date" +%s 2>/dev/null || echo 0)
  age_days=$(( ( $(date +%s) - gen_epoch ) / 86400 ))
  if [ "$age_days" -gt "$STALE_DAYS" ]; then
    echo "check: DASHBOARD is ${age_days}d old (> ${STALE_DAYS}d) — regenerate with os/bin/status.sh" >&2
    exit 1
  fi
  echo "check: DASHBOARD is fresh (${age_days}d old, <= ${STALE_DAYS}d)"
  exit 0
fi

# Root repo first (it also contains bolt-cli/), then every sub-repo on disk.
REPOS=". bolt-protocol bolt-core-sdk bolt-rendezvous bolt-daemon localbolt localbolt-app localbolt-v3 localbolt-web bytebolt-app bytebolt-relay"

# Release line per repo. Default is `main`; add overrides here if one ever releases
# from another branch. A repo checked out off its release line surfaces as a Signal.
release_branch_for() {
  case "$1" in
    *) echo "main" ;;
  esac
}
# CHANGELOG presence is not expected for the root or the intentional placeholders.
CHANGELOG_SUPPRESS=". bytebolt-app bytebolt-relay"

now_epoch=$(date +%s)
stamp="$(date '+%Y-%m-%d %H:%M %Z')"
signals=""

{
  echo "# Bolt Ecosystem — Dashboard"
  echo
  echo "> **GENERATED FILE — do not edit.** Regenerate with \`os/bin/status.sh\`."
  echo "> Generated: **$stamp**"
  echo "> Facts are read from the local clones. \"Ahead\" counts commits not on the"
  echo "> last-fetched \`origin/<branch>\` ref; run \`git fetch\` per repo for exact remote truth."
  echo
  if [ "$DIRTY" = "1" ]; then
    echo "| Repo | Latest tag | HEAD | Branch | Last commit | Age | Ahead | Dirty |"
    echo "|---|---|---|---|---|---|---|---|"
  else
    echo "| Repo | Latest tag | HEAD | Branch | Last commit | Age | Ahead |"
    echo "|---|---|---|---|---|---|---|"
  fi

  for r in $REPOS; do
    d="$ROOT/$r"
    if [ "$r" = "." ]; then name="bolt-ecosystem (root, incl. bolt-cli)"; else name="$r"; fi

    if ! git -C "$d" rev-parse --git-dir >/dev/null 2>&1; then
      if [ "$DIRTY" = "1" ]; then
        echo "| $name | — | — | — | (not a git repo) | — | — | — |"
      else
        echo "| $name | — | — | — | (not a git repo) | — | — |"
      fi
      continue
    fi

    # Nearest tag reachable from HEAD — "the tag this HEAD grew from".
    tag=$(git -C "$d" describe --tags --abbrev=0 HEAD 2>/dev/null)
    if [ -z "$tag" ]; then tag="(none)"; fi
    past=0
    if [ "$tag" != "(none)" ]; then
      past=$(git -C "$d" rev-list --count "$tag..HEAD" 2>/dev/null || echo 0)
    fi

    head_sha=$(git -C "$d" rev-parse --short HEAD 2>/dev/null || echo "?")
    branch=$(git -C "$d" branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then branch="(detached)"; fi

    subj=$(git -C "$d" log -1 --format='%s' 2>/dev/null | tr -d '\n' | tr '|' '-' | cut -c1-56)
    cdate=$(git -C "$d" log -1 --format='%ad' --date=short 2>/dev/null)
    cepoch=$(git -C "$d" log -1 --format='%ct' 2>/dev/null || echo "$now_epoch")
    age="$(( (now_epoch - cepoch) / 86400 ))d"

    ahead="n/a"
    if [ "$branch" != "(detached)" ] && git -C "$d" rev-parse --verify -q "origin/$branch" >/dev/null 2>&1; then
      ahead=$(git -C "$d" rev-list --count "origin/$branch..HEAD" 2>/dev/null || echo "n/a")
    fi

    if [ "$DIRTY" = "1" ]; then
      dirty_n=$(git -C "$d" status --porcelain -uno 2>/dev/null | wc -l | tr -d ' ')
      echo "| $name | \`$tag\` | \`$head_sha\` | $branch | $cdate — $subj | $age | $ahead | $dirty_n |"
      if [ "$dirty_n" != "0" ]; then
        signals="$signals
- **$name**: $dirty_n tracked file(s) modified but not committed"
      fi
    else
      echo "| $name | \`$tag\` | \`$head_sha\` | $branch | $cdate — $subj | $age | $ahead |"
    fi

    if [ "$ahead" != "0" ] && [ "$ahead" != "n/a" ]; then
      signals="$signals
- **$name**: $ahead commit(s) on $branch not pushed to origin/$branch"
    fi
    if [ "$past" != "0" ] && [ "$tag" != "(none)" ]; then
      signals="$signals
- **$name**: $past commit(s) past \`$tag\` — untagged work at HEAD"
    fi

    # Off-release-branch (surfaces a spike/feature checkout, e.g. bolt-core-sdk on spike).
    rel=$(release_branch_for "$r")
    if [ "$branch" != "(detached)" ] && [ "$branch" != "$rel" ]; then
      signals="$signals
- **$name**: on branch \`$branch\` — not its release line (\`$rel\`)"
    fi

    # Per-repo CHANGELOG presence (single name-level stat; suppress root + placeholders).
    case " $CHANGELOG_SUPPRESS " in
      *" $r "*) : ;;
      *)
        if [ ! -f "$d/docs/CHANGELOG.md" ]; then
          signals="$signals
- **$name**: no \`docs/CHANGELOG.md\` (per-repo release-history home missing)"
        fi ;;
    esac
  done

  # REPOS-vs-disk drift: child repos with a .git on disk vs the REPOS list (excluding root).
  expected=$(( $(echo $REPOS | wc -w) - 1 ))
  disk=$(find "$ROOT" -mindepth 2 -maxdepth 2 -name .git 2>/dev/null | grep -viE '/(node_modules|target|dist|\.build)/|legacy' | wc -l | tr -d ' ')
  if [ "$disk" != "$expected" ]; then
    signals="$signals
- **repo inventory**: $disk child repo(s) with .git on disk vs $expected in the REPOS list (status.sh) — reconcile"
  fi

  # Un-homed audit artifacts on ~/Desktop (TOP-LEVEL name glob only — never reads content).
  desk="$HOME/Desktop"
  if [ -d "$desk" ]; then
    desk_list=$(find "$desk" -maxdepth 1 \( -name 'localbolt*' -o -name '*trustgate*' -o -name '*pairing*' -o -name '*redteam*' -o -name '*remediation*' -o -name '*pake*' -o -name 'bolt-*audit*' \) 2>/dev/null)
    if [ -n "$desk_list" ]; then desk_n=$(printf '%s\n' "$desk_list" | grep -c .); else desk_n=0; fi
    if [ "$desk_n" -gt 0 ]; then
      names=$(printf '%s\n' "$desk_list" | xargs -n1 basename 2>/dev/null | tr '\n' ',' | sed 's/,$//')
      signals="$signals
- **un-homed evidence**: $desk_n bolt audit artifact(s) on ~/Desktop ($names) — home + cite them per \`os/rules/doc-routing.md\` before marking the finding touched"
    fi
  fi

  echo
  echo "## Signals"
  echo
  if [ -n "$signals" ]; then
    echo "$signals" | sed '/^$/d'
  else
    echo "None. Every repo is pushed, tagged at HEAD, on its release line, with a CHANGELOG, and no un-homed evidence."
  fi

  if [ "$HYGIENE" = "1" ]; then
    echo
    echo "## Hygiene (--hygiene; opt-in working-tree scan under \`docs/\`)"
    echo
    untracked=$(git -C "$ROOT" status --porcelain -uall -- docs/ 2>/dev/null)
    if [ -n "$untracked" ]; then
      echo "Untracked / modified under \`docs/\` (home per \`os/rules/doc-routing.md\`):"
      echo '```'
      echo "$untracked"
      echo '```'
    else
      echo "- \`docs/\` clean — no untracked or modified files."
    fi
    for cruft in "=" "AUDIT-2026-02-26.md"; do
      [ -e "$ROOT/$cruft" ] && echo "- root cruft: \`$cruft\` (gitignored artifact — safe to delete)"
    done
  fi

  echo
  echo "## How to read this"
  echo
  echo "- Regenerated on demand; if the Generated stamp looks old, run \`os/bin/status.sh\` (or \`--check\` in a hook to gate on staleness)."
  echo "- Intent lives in \`os/NOW.md\`, history in \`os/log/journal.md\`, decisions in \`os/log/decisions/\`."
  echo "- Evidence homing: audit / red-team / eval artifacts belong in \`docs/AUDITS/\` or \`docs/evidence/\`, cited repo-relative — never left on \`~/Desktop\`. docs-keeper owns this; rules in \`os/rules/doc-routing.md\`."
  echo "- Opt-in scans (never at boot): \`--dirty\` (tracked dirty counts) and \`--hygiene\` (un-homed docs) may touch the working tree; the default run is \`.git\` / name-level only."
} > "$TMP"

mv "$TMP" "$OUT"
echo "Wrote $OUT"
