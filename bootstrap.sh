#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Platform
# ---------------------------------------------------------------------------

OS="$(uname -s)"

case "$OS" in
    Darwin)
        PLATFORM="macos"
        ;;
    Linux)
        PLATFORM="ubuntu"
        ;;
    *)
        abort "Unsupported operating system: $OS"
        ;;
esac

log "Checking platform"

if [[ "$PLATFORM" == "ubuntu" ]]; then
    [[ -f /etc/os-release ]] || abort "Cannot determine Linux distribution."

    # shellcheck disable=SC1091
    source /etc/os-release

    [[ "${ID:-}" == "ubuntu" ]] || \
        abort "Unsupported Linux distribution: ${ID:-unknown}."

    success "Ubuntu detected"
else
    success "macOS detected"
fi

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Linking comes first so a failing package install never leaves the machine
# half configured. Every link is checked before the first one is created: on a
# conflict nothing is changed.

LINKS=()

add_link() {
    LINKS+=("$1|$2")
}

add_link "$DOTFILES_DIR/config/zsh/zshenv" "$HOME/.zshenv"
add_link "$DOTFILES_DIR/config/zsh/zprofile" "$HOME/.zprofile"
add_link "$DOTFILES_DIR/config/zsh/zshrc" "$HOME/.zshrc"
add_link "$DOTFILES_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
add_link "$DOTFILES_DIR/config/tmux/tmux.conf" "$HOME/.tmux.conf"
add_link "$DOTFILES_DIR/config/git/config" "$HOME/.config/git/config"
add_link "$DOTFILES_DIR/config/vim/vimrc" "$HOME/.vimrc"
add_link "$DOTFILES_DIR/config/vim/ide.vim" "$HOME/.vim/ide.vim"

if [[ "$PLATFORM" == "macos" ]]; then
    add_link "$DOTFILES_DIR/config/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
    add_link "$DOTFILES_DIR/config/zed/settings.json" "$HOME/.config/zed/settings.json"
    add_link "$DOTFILES_DIR/config/zed/keymap.json" "$HOME/.config/zed/keymap.json"
fi

preflight_links() {
    local entry source destination target
    local problems=0

    for entry in "${LINKS[@]}"; do
        source="${entry%%|*}"
        destination="${entry#*|}"

        if [[ ! -e "$source" ]]; then
            error "Missing source file: $source"
            problems=1
        elif [[ -L "$destination" ]]; then
            target="$(readlink "$destination")"

            if [[ "$target" != "$source" ]]; then
                error "$destination already points to: $target"
                problems=1
            fi
        elif [[ -e "$destination" ]]; then
            error "$destination already exists and is not managed by dotfiles"
            problems=1
        fi
    done

    if (( problems != 0 )); then
        abort "Nothing was changed. Resolve the conflicts above and run again."
    fi
}

link_config() {
    local source="$1"
    local destination="$2"

    if [[ -L "$destination" ]]; then
        success "$destination"
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        printf '· Would link %s → %s\n' "$destination" "$source"
        return
    fi

    mkdir -p "$(dirname "$destination")"
    ln -s "$source" "$destination"

    success "$destination"
}

log "Linking configuration"

preflight_links

for entry in "${LINKS[@]}"; do
    link_config "${entry%%|*}" "${entry#*|}"
done

# ---------------------------------------------------------------------------
# Homebrew
# ---------------------------------------------------------------------------

if [[ "$PLATFORM" == "macos" ]]; then
    BREW=""

    if command -v brew >/dev/null 2>&1; then
        BREW="$(command -v brew)"
    elif [[ -x /opt/homebrew/bin/brew ]]; then
        BREW="/opt/homebrew/bin/brew"
    elif [[ -x /usr/local/bin/brew ]]; then
        BREW="/usr/local/bin/brew"
    fi

    if [[ -z "$BREW" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            printf '· Would install Homebrew\n'
        else
            log "Installing Homebrew"

            /bin/bash -c \
                "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            if [[ -x /opt/homebrew/bin/brew ]]; then
                BREW="/opt/homebrew/bin/brew"
            elif [[ -x /usr/local/bin/brew ]]; then
                BREW="/usr/local/bin/brew"
            else
                abort "Homebrew installation completed, but brew was not found."
            fi
        fi
    fi

    if [[ -n "$BREW" ]]; then
        eval "$("$BREW" shellenv)"
        success "Homebrew available"
    fi
fi

# ---------------------------------------------------------------------------
# Packages
# ---------------------------------------------------------------------------

install_macos_packages() {
    log "Installing Homebrew packages"

    if [[ "$DRY_RUN" == true ]]; then
        printf '· Would run: brew bundle --no-upgrade --file="%s"\n' "$DOTFILES_DIR/Brewfile"
        return
    fi

    brew trust --formula hashicorp/tap/terraform

    # --no-upgrade: install what is missing, never bump terraform, kubectl or
    # helm behind your back. Upgrade on purpose with `brew upgrade`.
    "$BREW" bundle --no-upgrade --file="$DOTFILES_DIR/Brewfile"

    success "Homebrew bundle complete"
}

# Language servers that Homebrew doesn't package. Pinned, like the Vim plugins:
# bump the version here on purpose.
INTELEPHENSE_VERSION="1.18.5"

install_macos_language_servers() {
    log "Installing language servers"

    if [[ "$DRY_RUN" == true ]]; then
        printf '· Would run: npm install --global intelephense@%s\n' "$INTELEPHENSE_VERSION"
        return
    fi

    if ! command -v npm >/dev/null 2>&1; then
        error "npm not found, skipping intelephense"
        return
    fi

    npm install --global "intelephense@$INTELEPHENSE_VERSION"

    success "intelephense $INTELEPHENSE_VERSION installed"
}

install_ubuntu_packages() {
    # No starship (not packaged for current LTS releases: servers keep the
    # plain zsh prompt) and no yq (apt ships a different tool than Homebrew).
    local packages=(
        zsh
        fzf
        zoxide
        direnv
        ripgrep
        fd-find
        bat
        jq
        git
        tmux
        vim
        universal-ctags
    )

    log "Installing Ubuntu packages"

    if [[ "$DRY_RUN" == true ]]; then
        printf '· Would install: %s\n' "${packages[*]}"
        return
    fi

    sudo apt-get update
    sudo apt-get install -y "${packages[@]}"

    success "Ubuntu packages installed"
}

if [[ "$PLATFORM" == "macos" ]]; then
    install_macos_packages
    install_macos_language_servers
else
    install_ubuntu_packages
fi

# ---------------------------------------------------------------------------
# Vim plugins
# ---------------------------------------------------------------------------

if [[ "$DRY_RUN" == true ]]; then
    "$DOTFILES_DIR/config/vim/install-plugins.sh" --dry-run
else
    "$DOTFILES_DIR/config/vim/install-plugins.sh"
fi

# ---------------------------------------------------------------------------
# Default shell
# ---------------------------------------------------------------------------

if [[ "$PLATFORM" == "ubuntu" ]]; then
    ZSH_BIN="$(command -v zsh || true)"

    if [[ -n "$ZSH_BIN" && "${SHELL:-}" != "$ZSH_BIN" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            printf '· Would set default shell to %s\n' "$ZSH_BIN"
        else
            log "Setting default shell to zsh"
            chsh -s "$ZSH_BIN"
            success "Default shell set to $ZSH_BIN"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

if [[ "$DRY_RUN" == true ]]; then
    log "Dry run complete"
else
    log "Done"

    cat <<'EOF'

Your dotfiles are installed.

Restart your shell with:

    exec zsh

EOF
fi
