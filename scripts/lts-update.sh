#!/bin/bash
# scripts/lts-update.sh
# Interactive LTS kernel version bump for ouya_dev
# Usage: bash scripts/lts-update.sh

set -e

LINUX_DIR="$(cd "$(dirname "$0")/.." && pwd)/linux"
REMOTE="origin"
KERNEL_RELEASES_URL="https://www.kernel.org/releases.json"

# ─── helpers ────────────────────────────────────────────────────────────────

die() { echo "ERROR: $*" >&2; exit 1; }

require() {
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || die "'$cmd' not found, please install it"
    done
}

# Compare two version strings (e.g. 6.12.91 vs 6.12.93)
# Returns 0 if equal, 1 if v1 > v2, 2 if v1 < v2
verlte() { [ "$1" = "$(printf '%s\n%s' "$1" "$2" | sort -V | head -n1)" ]; }
verlt()  { [ "$1" != "$2" ] && verlte "$1" "$2"; }

# ─── check deps ─────────────────────────────────────────────────────────────

require git curl jq

# ─── current version ────────────────────────────────────────────────────────

[ -d "$LINUX_DIR" ] || die "linux submodule not found at $LINUX_DIR"
[ -e "$LINUX_DIR/.git" ] || die "linux submodule not initialized — run: make submodule-linux"

CURRENT_TAG=$(git -C "$LINUX_DIR" describe --tags --exact-match 2>/dev/null || echo "unknown")
[ "$CURRENT_TAG" = "unknown" ] && die "linux submodule is not on a tagged commit"

CURRENT_VER="${CURRENT_TAG#v}"                          # e.g. 6.12.91
CURRENT_MAJOR=$(echo "$CURRENT_VER" | cut -d. -f1)     # e.g. 6
CURRENT_MINOR=$(echo "$CURRENT_VER" | cut -d. -f2)     # e.g. 12
CURRENT_SERIES="${CURRENT_MAJOR}.${CURRENT_MINOR}"      # e.g. 6.12

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║           ouya_dev — LTS kernel updater          ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "  Current kernel : v${CURRENT_VER} (series ${CURRENT_SERIES}.y)"
echo ""

# ─── fetch LTS info from kernel.org ─────────────────────────────────────────

echo "  Fetching release info from endoflife.date..."
EOL_URL="https://endoflife.date/api/linux.json"
EOL_JSON=$(curl -sf "$EOL_URL") || die "Failed to fetch $EOL_URL"

LTS_SERIES=$(echo "$EOL_JSON" | jq -r '
    .[]
    | select(.lts == true)
    | select(.eol != false)
    | "\(.cycle) \(.eol)"
' 2>/dev/null) || die "Failed to parse endoflife.date JSON"

# ─── fetch latest tags per series from git remote ───────────────────────────

echo "  Fetching available tags from remote (this may take a moment)..."
LINUX_REMOTE_URL="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
ALL_TAGS=$(git ls-remote --tags "$LINUX_REMOTE_URL" 2>/dev/null | \
    grep -oP 'refs/tags/v\K[0-9]+\.[0-9]+\.[0-9]+$' | \
    sort -V)

[ -n "$ALL_TAGS" ] || die "Failed to fetch tags from remote $REMOTE"

# ─── build summary table ─────────────────────────────────────────────────────

echo ""
echo "  Available LTS series:"
echo ""
printf "  %-10s %-18s %-12s %s\n" "Series" "Latest patch" "EOL" "Status"
printf "  %-10s %-18s %-12s %s\n" "──────" "────────────" "───" "──────"

LTS_OPTIONS=()

while IFS=' ' read -r series_ver eol; do
    series_major=$(echo "$series_ver" | cut -d. -f1)
    series_minor=$(echo "$series_ver" | cut -d. -f2)
    series="${series_major}.${series_minor}"

    latest=$(echo "$ALL_TAGS" | grep "^${series}\." | tail -1)
    [ -z "$latest" ] && continue

    if [ "$series" = "$CURRENT_SERIES" ]; then
        if [ "$latest" = "$CURRENT_VER" ]; then
            status="✓ current, up to date"
        else
            status="↑ update available → v${latest}"
        fi
        marker="*"
    else
        status=""
        marker=" "
        LTS_OPTIONS+=("$series:$latest:$eol")
    fi

    printf "  %s %-9s %-18s %-14s %s\n" "$marker" "${series}.y" "v${latest}" "$eol" "$status"
done <<< "$LTS_SERIES"

echo ""

# ─── check if current series needs update ────────────────────────────────────

LATEST_CURRENT=$(echo "$ALL_TAGS" | grep "^${CURRENT_SERIES}\." | tail -1)

if verlt "$CURRENT_VER" "$LATEST_CURRENT"; then
    echo "  → Patch update available for current series: v${CURRENT_VER} → v${LATEST_CURRENT}"
    echo ""
    printf "  Update current series to v%s? [y/N] " "$LATEST_CURRENT"
    read -r answer
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        TARGET_TAG="v${LATEST_CURRENT}"
        TARGET_VER="$LATEST_CURRENT"
        TARGET_SERIES="$CURRENT_SERIES"
    else
        TARGET_TAG=""
    fi
else
    echo "  Current series ${CURRENT_SERIES}.y is up to date (v${CURRENT_VER})."
    echo ""
    TARGET_TAG=""
fi

# ─── offer series jump if no patch update chosen ─────────────────────────────

if [ -z "$TARGET_TAG" ] && [ ${#LTS_OPTIONS[@]} -gt 0 ]; then
    echo "  Jump to a different LTS series?"
    echo ""
    i=1
    for opt in "${LTS_OPTIONS[@]}"; do
        s=$(echo "$opt" | cut -d: -f1)
        v=$(echo "$opt" | cut -d: -f2)
        e=$(echo "$opt" | cut -d: -f3)
        printf "    %d) %s.y  →  v%s  (EOL: %s)\n" "$i" "$s" "$v" "$e"
        i=$((i+1))
    done
    echo "    0) Exit — no changes"
    echo ""
    printf "  Choice [0-%d]: " "$((i-1))"
    read -r choice

    if [ "$choice" = "0" ] || [ -z "$choice" ]; then
        echo ""
        echo "  No changes made."
        exit 0
    fi

    selected="${LTS_OPTIONS[$((choice-1))]}"
    TARGET_SERIES=$(echo "$selected" | cut -d: -f1)
    TARGET_VER=$(echo "$selected" | cut -d: -f2)
    TARGET_TAG="v${TARGET_VER}"
fi

[ -z "$TARGET_TAG" ] && { echo "  No changes made."; exit 0; }

# ─── confirm and apply ────────────────────────────────────────────────────────

echo ""
echo "  ┌─────────────────────────────────────────────┐"
printf "  │  v%-10s  →  v%-10s                  │\n" "$CURRENT_VER" "$TARGET_VER"
echo "  └─────────────────────────────────────────────┘"
echo ""
printf "  Proceed? [y/N] "
read -r confirm
[ "$confirm" = "y" ] || [ "$confirm" = "Y" ] || { echo "  Aborted."; exit 0; }

echo ""
echo "  Fetching $TARGET_TAG..."
git -C "$LINUX_DIR" fetch --depth 1 "$REMOTE" tag "$TARGET_TAG"
git -C "$LINUX_DIR" checkout "$TARGET_TAG"

# Update branch tracking in .gitmodules if series changed
if [ "$TARGET_SERIES" != "$CURRENT_SERIES" ]; then
    git config -f .gitmodules submodule.linux.branch "linux-${TARGET_SERIES}.y"
    git add .gitmodules
fi

git add linux
git commit -m "linux: update to ${TARGET_TAG} LTS"

echo ""
echo "  ✓ Done — linux submodule updated to ${TARGET_TAG}"
echo "  Run 'git push' to push the changes."
echo ""
