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
        printf '· Would run: brew bundle --file="%s"\n' "$DOTFILES_DIR/Brewfile"
        return
    fi

    "$BREW" bundle --file="$DOTFILES_DIR/Brewfile"

    success "Homebrew bundle complete"
}

install_ubuntu_packages() {
    local packages=(
        zsh
        starship
        fzf
        zoxide
        direnv
        ripgrep
        fd-find
        bat
        jq
        yq
        git
        tmux
        vim
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
else
    install_ubuntu_packages
fi

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

link_config() {
    local source="$1"
    local destination="$2"

    [[ -e "$source" ]] || abort "Missing source file: $source"

    if [[ -L "$destination" ]]; then
        local target
        target="$(readlink "$destination")"

        if [[ "$target" == "$source" ]]; then
            success "$destination"
            return
        fi

        abort "$destination already points to: $target"
    fi

    if [[ -e "$destination" ]]; then
        abort "$destination already exists and is not managed by dotfiles"
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

link_config \
    "$DOTFILES_DIR/config/zsh/zshenv" \
    "$HOME/.zshenv"

link_config \
    "$DOTFILES_DIR/config/zsh/zprofile" \
    "$HOME/.zprofile"

link_config \
    "$DOTFILES_DIR/config/zsh/zshrc" \
    "$HOME/.zshrc"

link_config \
    "$DOTFILES_DIR/config/starship/starship.toml" \
    "$HOME/.config/starship.toml"

link_config \
    "$DOTFILES_DIR/config/tmux/tmux.conf" \
    "$HOME/.tmux.conf"

link_config \
    "$DOTFILES_DIR/config/vim/vimrc" \
    "$HOME/.vimrc"

if [[ "$PLATFORM" == "macos" ]]; then
    link_config \
        "$DOTFILES_DIR/config/ghostty/config" \
        "$HOME/.config/ghostty/config"

    link_config \
        "$DOTFILES_DIR/config/zed/settings.json" \
        "$HOME/.config/zed/settings.json"

    link_config \
        "$DOTFILES_DIR/config/zed/keymap.json" \
        "$HOME/.config/zed/keymap.json"

    link_config \
        "$DOTFILES_DIR/config/zed/themes/zed_dark.json" \
        "$HOME/.config/zed/themes/zed_dark.json"
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