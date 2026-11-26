#!/usr/bin/env bash
#
# Install the Vim plugins listed in plugins.txt as native Vim packages.
#
# Usage: install-plugins.sh [--dry-run]
#
# Safe to re-run: existing clones are moved to the pinned commit.
# macOS installs groups "core" and "ide"; anything else installs "core" only.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_LIST="$SCRIPT_DIR/plugins.txt"
PACK_DIR="$HOME/.vim/pack/plugins/start"
DRY_RUN=false

log() {
    printf '\n→ %s\n' "$1"
}

success() {
    printf '✓ %s\n' "$1"
}

error() {
    printf '✗ %s\n' "$1" >&2
}

abort() {
    error "$1"
    exit 1
}

case "${1:-}" in
    "")
        ;;
    --dry-run)
        DRY_RUN=true
        ;;
    *)
        abort "Usage: $0 [--dry-run]"
        ;;
esac

[[ -f "$PLUGIN_LIST" ]] || abort "Missing plugin list: $PLUGIN_LIST"
command -v git >/dev/null 2>&1 || abort "git is required"

if [[ "$(uname -s)" == "Darwin" ]]; then
    ENABLED_GROUPS=" core ide "
else
    ENABLED_GROUPS=" core "
fi

generate_helptags() {
    local plugin_dir="$1"

    [[ -d "$plugin_dir/doc" ]] || return 0
    command -v vim >/dev/null 2>&1 || return 0

    vim -u NONE -i NONE -N -es \
        -c "helptags $plugin_dir/doc" \
        -c "qa!" >/dev/null 2>&1 || true
}

install_plugin() {
    local repo="$1"
    local ref="$2"
    local name="${repo##*/}"
    local dest="$PACK_DIR/$name"

    if [[ ! -d "$dest/.git" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            printf '· Would clone %s at %s\n' "$repo" "${ref:0:7}"
            return
        fi

        git clone --quiet "https://github.com/$repo.git" "$dest"
        git -C "$dest" checkout --quiet --detach "$ref"
        generate_helptags "$dest"
        success "$name installed (${ref:0:7})"
        return
    fi

    if [[ "$(git -C "$dest" rev-parse HEAD)" == "$ref" ]]; then
        success "$name (${ref:0:7})"
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        printf '· Would update %s to %s\n' "$name" "${ref:0:7}"
        return
    fi

    git -C "$dest" fetch --quiet origin
    git -C "$dest" checkout --quiet --detach "$ref"
    generate_helptags "$dest"
    success "$name updated (${ref:0:7})"
}

log "Installing Vim plugins"

if [[ "$DRY_RUN" != true ]]; then
    mkdir -p "$PACK_DIR"
fi

while read -r group repo ref _ <&3; do
    [[ -z "${group:-}" || "$group" == \#* ]] && continue

    [[ -n "${repo:-}" && -n "${ref:-}" ]] || abort "Malformed line in plugins.txt: $group"

    if [[ "$ENABLED_GROUPS" != *" $group "* ]]; then
        continue
    fi

    install_plugin "$repo" "$ref"
done 3< "$PLUGIN_LIST"
