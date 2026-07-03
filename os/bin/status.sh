#!/usr/bin/env bash
# os/bin/status.sh — Bolt Ecosystem sensor.
# Generates os/DASHBOARD.md from git facts. The dashboard is DERIVED STATE:
# never hand-edit it, never hand-write "current state" anywhere else.
#
# Reads only .git metadata by default, so it is safe on iCloud-synced trees
# (working-tree scans can hang on cloud-only files).
#
# Usage:
#   os/bin/status.sh            # safe default (.git reads only)
#   os/bin/status.sh --dirty    # adds working-tree dirty counts (may hang on
#                               # cloud-only files; run brctl download first)

set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/os/DASHBOARD.md"
TMP="$OUT.tmp"

DIRTY=0
if [ "${1:-}" = "--dirty" ]; then DIRTY=1; fi

# Root repo first (it also contains bolt-cli/), then every sub-repo on disk.
REPOS=". bolt-protocol bolt-core-sdk bolt-rendezvous bolt-daemon localbolt localbolt-app localbolt-v3 localbolt-web bytebolt-app bytebolt-relay"

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
    # (Creation-date ordering lies when annotated and lightweight tags mix.)
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
  done

  echo
  echo "## Signals"
  echo
  if [ -n "$signals" ]; then
    echo "$signals" | sed '/^$/d'
  else
    echo "None. Every repo is pushed and tagged at HEAD."
  fi
  echo
  echo "## How to read this"
  echo
  echo "- This file is regenerated on demand; if the Generated stamp looks old, run \`os/bin/status.sh\`."
  echo "- Intent (what we're doing next) lives in \`os/NOW.md\`. History lives in \`os/log/journal.md\`."
  echo "- Dirty counts are off by default (iCloud-synced tree; scans can hang). Use \`--dirty\` when needed."
} > "$TMP"

mv "$TMP" "$OUT"
echo "Wrote $OUT"
