#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for new Debian servers
# Idempotent where possible, opinionated for self-hosting

# ─────────────────────────────────────────────────────────────────────────────
# Config
# ─────────────────────────────────────────────────────────────────────────────

USER="${USER:-$(whoami)}"
HOME="${HOME:-/home/$USER}"
DOTFILES_REPO="ssh://git@git.2027a.net/mathieu/dotfiles_serveurs.git"
DOTFILES_DIR="$HOME/dotfiles"

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

info() { echo -e "\n\033[1;34m▸\033[0m $*"; }
ok() { echo -e "\033[1;32m✓\033[0m $*"; }
warn() { echo -e "\033[1;33m!\033[0m $*" >&2; }
fail() {
    echo -e "\033[1;31m✗\033[0m $*" >&2
    exit 1
}

cmd_exists() { command -v "$1" &>/dev/null; }

symlink() {
    local src="$1" dest="$2"
    if [[ -L "$dest" ]]; then
        ok "Symlink exists: $dest"
    else
        mkdir -p "$(dirname "$dest")"
        ln -sf "$src" "$dest"
        ok "Linked: $dest → $src"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Preflight
# ─────────────────────────────────────────────────────────────────────────────

[[ "$(id -u)" -eq 0 ]] && fail "Do not run as root. Script will sudo when needed."
[[ -f /etc/debian_version ]] || fail "Not a Debian-based system."

info "Bootstrapping Debian server for user: $USER"

# ─────────────────────────────────────────────────────────────────────────────
# System packages
# ─────────────────────────────────────────────────────────────────────────────

info "Installing base packages"
sudo apt-get update -qq
sudo apt-get install -y \
    eza tmux zsh fzf git build-essential neovim \
    zsh-syntax-highlighting zsh-autosuggestions \
    ca-certificates curl gnupg lazygit

ok "Base packages installed"

# ─────────────────────────────────────────────────────────────────────────────
# SSH setup
# ─────────────────────────────────────────────────────────────────────────────

info "Setting up SSH"
if [[ ! -d "$HOME/.ssh" ]]; then
    mkdir -m 700 "$HOME/.ssh"
    ok "Created ~/.ssh"
else
    ok "~/.ssh already exists"
fi

if [[ ! -f "$HOME/.ssh/config" ]]; then
    cat >"$HOME/.ssh/config" <<'EOF'
Host git.2027a.net
    HostName git.2027a.net
    User git
    Port 222
    IdentityFile ~/.ssh/id_nk

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_nk
EOF
    chmod 600 "$HOME/.ssh/config"
    ok "Created ~/.ssh/config"
else
    ok "~/.ssh/config already exists"
fi

if [[ ! -f "$HOME/.ssh/id_nk" ]]; then
    warn "SSH key missing: ~/.ssh/id_nk"
    warn "Run on your local machine:"
    echo "    rsync -Paz ~/.ssh/id_nk $USER@$(hostname):.ssh/"
else
    ok "SSH key present"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Dotfiles
# ─────────────────────────────────────────────────────────────────────────────

info "Setting up dotfiles"
if [[ ! -d "$DOTFILES_DIR" ]]; then
    if [[ -f "$HOME/.ssh/id_nk" ]]; then
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        ok "Cloned dotfiles"
    else
        warn "Skipping dotfiles clone (SSH key not present)"
    fi
else
    ok "Dotfiles already cloned"
fi

if [[ -d "$DOTFILES_DIR" ]]; then
    mkdir -p "$HOME/.config/tmux"
    symlink "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
    symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    symlink "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Change default shell
# ─────────────────────────────────────────────────────────────────────────────

if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "Changing default shell to zsh"
    sudo chsh -s "$(which zsh)" "$USER"
    ok "Shell changed to zsh (effective on next login)"
else
    ok "Shell already zsh"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Docker Engine (official)
# ─────────────────────────────────────────────────────────────────────────────

if cmd_exists docker && docker --version | grep -q "Docker version"; then
    ok "Docker already installed"
else
    info "Installing Docker Engine"

    # Remove conflicting packages
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y "$pkg" 2>/dev/null || true
    done

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
        sudo curl -fsSL https://download.docker.com/linux/debian/gpg \
            -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
    fi

    # Add Docker repository
    if [[ ! -f /etc/apt/sources.list.d/docker.sources ]]; then
        . /etc/os-release
        sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $VERSION_CODENAME
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    fi

    # Install Docker
    sudo apt-get update -qq
    sudo apt-get install -y \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    sudo groupadd -f docker
    sudo usermod -aG docker "$USER"

    # Enable services
    sudo systemctl enable --now docker.service
    sudo systemctl enable --now containerd.service

    ok "Docker installed"
    warn "You must log out and back in for docker group membership to take effect"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────────────

echo
info "Bootstrap complete"
echo
echo "Next steps:"
echo "  1. Log out and back in (for zsh + docker group)"
echo "  2. Verify: docker run hello-world"
echo "  3. Deploy your services"
echo
