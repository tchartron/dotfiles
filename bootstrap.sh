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

skip() {
    printf '· %s\n' "$1"
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

if [[ $# -gt 1 ]]; then
    abort "Usage: $0 [--dry-run]"
fi

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# ---------------------------------------------------------------------------
# Platform
# ---------------------------------------------------------------------------

OS="$(uname -s)"

case "$OS" in
    Darwin)
        PLATFORM="macos"
        ;;
    Linux)
        PLATFORM="linux"
        ;;
    *)
        abort "Unsupported operating system: $OS"
        ;;
esac

log "Checking platform"
success "$PLATFORM detected"

# ---------------------------------------------------------------------------
# Homebrew - macOS only
# ---------------------------------------------------------------------------

if [[ "$PLATFORM" == "macos" ]]; then
    if command -v brew >/dev/null 2>&1; then
        success "Homebrew available"
    elif [[ "$DRY_RUN" == true ]]; then
        printf '· Would install Homebrew\n'
    else
        log "Installing Homebrew"

        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        if [[ -x /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -x /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        else
            abort "Homebrew installation completed, but brew was not found."
        fi

        success "Homebrew installed"
    fi
fi

# ---------------------------------------------------------------------------
# Ubuntu / apt
# ---------------------------------------------------------------------------

if [[ "$PLATFORM" == "linux" ]]; then
    if ! command -v apt-get >/dev/null 2>&1; then
        abort "apt-get is required on Linux. This bootstrap currently supports Ubuntu only."
    fi

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release

        if [[ "${ID:-}" != "ubuntu" ]]; then
            abort "Unsupported Linux distribution: ${ID:-unknown}. Ubuntu is currently supported."
        fi
    else
        abort "Cannot determine Linux distribution."
    fi

    success "Ubuntu detected"
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

    brew bundle --file="$DOTFILES_DIR/Brewfile"

    success "Homebrew bundle complete"
}

install_ubuntu_packages() {
    local packages=(
        fzf
        zoxide
        direnv
        ripgrep
        fd-find
        bat
        jq
        tmux
        vim
        git
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

case "$PLATFORM" in
    macos)
        install_macos_packages
        ;;
    linux)
        install_ubuntu_packages
        ;;
esac

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

link_config() {
    local source="$1"
    local destination="$2"

    if [[ ! -e "$source" ]]; then
        abort "Missing source file: $source"
    fi

    if [[ -L "$destination" ]]; then
        local target
        target="$(readlink "$destination")"

        if [[ "$target" == "$source" ]]; then
            success "$destination"
            return
        fi

        abort "$destination is already a symlink pointing to: $target"
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
